import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import type { AuthContextUser } from '../../shared/types/user';
import { logActivity } from '../../shared/utils/activity-log';
import {
  notifyPaymentExpired,
  notifyPaymentPaid,
} from '../notifications/notifications.events';
import { isUuid, orderNotFound, resolveAccess } from '../orders/orders.access';
import type { OrderAccess } from '../orders/orders.access';
import {
  PAYMENT_EXPIRY_MINUTES,
  cancelTransaction,
  chargeQris,
  fetchTransactionStatus,
  grossAmountMatches,
  mapTransactionStatus,
} from './midtrans.client';
import {
  applyPaymentResultRpc,
  findOrderForPayment,
  findPaymentById,
  insertPendingPayment,
  listPaymentsForOrder,
  saveChargeResult,
  touchProviderChecked,
} from './payments.repo';
import { findOrderStaffInfo } from './payments.staff';
import type {
  PaymentOrderRow,
  PaymentRow,
  PaymentStatusValue,
  PaymentView,
} from './payments.types';

const PAYMENT_LIFETIME_MS = PAYMENT_EXPIRY_MINUTES * 60_000;
const PROVIDER_CHECK_INTERVAL_MS = 10_000;
const IN_FLIGHT_WINDOW_MS = 60_000;
const MAX_PROVIDER_ORDER_ID_LENGTH = 50;

export interface CreatePaymentResult {
  payment: PaymentView;
  created: boolean;
}

export interface ProviderResult {
  transactionStatus: string;
  fraudStatus: string | null;
  transactionId: string | null;
  settlementTime: Date | null;
}

function paymentNotFound(): AppError {
  return new AppError(404, 'not_found', 'Pembayaran tidak ditemukan');
}

/**
 * Siapa yang boleh membuat / memantau pembayaran sebuah order:
 * - customer: hanya pemilik order (order dari aplikasi);
 * - worker/owner: hanya order offline (channel staff_manual), yaitu owner,
 *   worker dengan izin manage_orders_all, pembuat order, atau worker penangan.
 */
async function canAccessPayment(
  env: Bindings,
  ctx: AuthContextUser,
  access: OrderAccess,
  order: PaymentOrderRow,
): Promise<boolean> {
  const { scope, viewer } = access;

  if (viewer.role === 'customer') {
    return scope.kind === 'customer' && scope.customerProfileId === order.customer_id;
  }

  const info = await findOrderStaffInfo(env, order.id);
  if (!info || info.channel !== 'staff_manual') return false;

  if (viewer.manageAll) return true;
  if (info.created_by === ctx.user.id) return true;
  return viewer.workerProfileId !== null && info.assigned_worker_id === viewer.workerProfileId;
}

function expiresAtOf(row: PaymentRow): Date {
  if (row.expires_at) return new Date(row.expires_at);
  return new Date(new Date(row.created_at).getTime() + PAYMENT_LIFETIME_MS);
}

export function toPaymentView(row: PaymentRow, orderNumber: string): PaymentView {
  return {
    id: row.id,
    order_id: row.order_id,
    order_number: orderNumber,
    amount: Math.round(row.amount),
    qr_payload: row.qris_payload ?? '',
    qr_image_url: row.qris_image_url,
    status: row.status,
    created_at: row.created_at,
    expires_at: expiresAtOf(row).toISOString(),
  };
}

function isActive(row: PaymentRow, now: number): boolean {
  return row.status === 'pending' && row.qris_payload !== null && expiresAtOf(row).getTime() > now;
}

/** order_id Midtrans: unik per percobaan, maks 50 karakter, hanya karakter yang diizinkan. */
function buildProviderOrderId(orderNumber: string, attempt: number): string {
  const suffix = `-P${attempt}`;
  const base = orderNumber.replace(/[^A-Za-z0-9_.~-]/g, '-');
  return `${base.slice(0, MAX_PROVIDER_ORDER_ID_LENGTH - suffix.length)}${suffix}`;
}

/** Menerapkan status dari Midtrans (webhook atau cek status) ke database. */
export async function applyProviderResult(
  env: Bindings,
  payment: PaymentRow,
  result: ProviderResult,
): Promise<PaymentStatusValue> {
  const mapped = mapTransactionStatus(result.transactionStatus, result.fraudStatus);
  if (mapped === null || mapped === 'pending') return payment.status;

  // Status pembayaran tidak boleh mundur. `expired`/`failed` yang datang
  // terlambat (webhook telat, atau RPC expire memakai data yang sudah basi)
  // tidak boleh menimpa `paid` yang sudah tercatat.
  if (mapped !== 'paid') {
    const fresh = await findPaymentById(env, payment.id);
    if (fresh?.status === 'paid') {
      console.warn(
        `payments: abaikan ${mapped} untuk ${payment.provider_order_id} — sudah paid`,
      );
      return 'paid';
    }
  }

  // Order yang sudah dibatalkan tidak boleh berubah jadi lunas lewat QR yang
  // sempat dibayar setelah pembatalan: uangnya sudah masuk di Midtrans, jadi
  // dicatat untuk rekonsiliasi manual (refund), bukan diterapkan ke order.
  if (mapped === 'paid') {
    const order = await findOrderForPayment(env, payment.order_id);
    if (order?.status === 'cancelled') {
      console.error(
        `payments: PEMBAYARAN MASUK UNTUK ORDER DIBATALKAN — perlu refund manual. order=${order.order_number} provider_order_id=${payment.provider_order_id} amount=${payment.amount}`,
      );
      return payment.status;
    }
  }

  const outcome = await applyPaymentResultRpc(env, {
    providerOrderId: payment.provider_order_id,
    newStatus: mapped,
    providerRef: result.transactionId,
    paidAt: result.settlementTime,
  });
  if (mapped === 'paid' && outcome.applied) {
    console.info(`payments: ${payment.provider_order_id} lunas`);

    // Hanya saat transisi benar-benar terjadi (outcome.applied) supaya
    // notifikasi tidak berulang ketika webhook datang lebih dari sekali.
    const order = await findOrderForPayment(env, payment.order_id);
    if (order) await notifyPaymentPaid(env, order);
  }
  return outcome.status;
}

/** Tanya Midtrans langsung lalu terapkan hasilnya; cadangan bila webhook telat. */
async function syncWithProvider(env: Bindings, payment: PaymentRow): Promise<PaymentStatusValue> {
  const remote = await fetchTransactionStatus(env, payment.provider_order_id);
  await touchProviderChecked(env, payment.id);
  if (!remote) return payment.status;

  if (!grossAmountMatches(payment.amount, remote.grossAmount)) {
    console.error(
      `payments: nominal ${payment.provider_order_id} tidak cocok (db ${payment.amount}, midtrans ${remote.grossAmount})`,
    );
    return payment.status;
  }
  return applyProviderResult(env, payment, remote);
}

async function expirePayment(env: Bindings, payment: PaymentRow): Promise<void> {
  // Baca ulang: settlement bisa masuk setelah baris ini dimuat pemanggil.
  const fresh = await findPaymentById(env, payment.id);
  if (!fresh || fresh.status !== 'pending') return;

  const outcome = await applyPaymentResultRpc(env, {
    providerOrderId: fresh.provider_order_id,
    newStatus: 'expired',
    providerRef: null,
    paidAt: null,
  });
  if (!outcome.applied) return;

  const order = await findOrderForPayment(env, fresh.order_id);
  if (order) await notifyPaymentExpired(env, order);
}

export type CancelOpenPaymentsResult = 'paid' | 'cleared';

/**
 * Menutup semua QR yang masih terbuka untuk sebuah order. Dipanggil sebelum
 * order dibatalkan supaya QR yang sudah ditampilkan ke customer tidak bisa
 * dibayar setelah pembatalan.
 *
 * Mengembalikan 'paid' bila ternyata ada QR yang sudah terlanjur dibayar
 * (pemanggil harus membatalkan pembatalan order).
 */
export async function cancelOpenPayments(
  env: Bindings,
  orderId: string,
): Promise<CancelOpenPaymentsResult> {
  const rows = await listPaymentsForOrder(env, orderId);
  const open = rows.filter((row) => row.status === 'pending');
  if (open.length === 0) return 'cleared';

  // Cek provider dulu: kalau sudah settle di antara klik cancel dan request ini,
  // order tidak boleh dibatalkan.
  for (const row of open) {
    const status = await syncWithProvider(env, row);
    if (status === 'paid') return 'paid';
  }

  for (const row of open) {
    // QR yang belum sempat dibuat di Midtrans tidak punya transaksi untuk dibatalkan.
    if (row.qris_payload !== null) {
      const outcome = await cancelTransaction(env, row.provider_order_id).catch((err) => {
        console.error('payments: gagal membatalkan transaksi Midtrans', err);
        return 'rejected' as const;
      });
      if (outcome === 'rejected') {
        // Bisa berarti sudah settle. Cek ulang supaya order tidak dibatalkan diam-diam.
        const status = await syncWithProvider(env, row).catch(() => row.status);
        if (status === 'paid') return 'paid';
      }
    }
    await expirePayment(env, row);
  }

  return 'cleared';
}

export async function createPayment(
  env: Bindings,
  ctx: AuthContextUser,
  orderId: string,
): Promise<CreatePaymentResult> {
  if (!isUuid(orderId)) throw orderNotFound();

  const access = await resolveAccess(env, ctx);
  const order = await findOrderForPayment(env, orderId);
  if (!order) throw orderNotFound();
  if (!(await canAccessPayment(env, ctx, access, order))) throw orderNotFound();

  if (order.status === 'cancelled') {
    throw new AppError(409, 'order_cancelled', 'Order ini sudah dibatalkan.');
  }
  if (order.status === 'completed') {
    throw new AppError(409, 'order_final', 'Order ini sudah selesai.');
  }
  if (order.payment_status === 'paid') {
    throw new AppError(409, 'already_paid', 'Order ini sudah dibayar.');
  }

  const amount = Math.round(order.total_price);
  if (amount < 1) {
    // Order gratis (promo menutup seluruh biaya) sudah ditandai lunas saat
    // dibuat; kalau masih sampai ke sini berarti tidak ada tagihan untuk QRIS.
    throw new AppError(409, 'nothing_to_pay', 'Order ini tidak perlu dibayar.');
  }

  const rows = await listPaymentsForOrder(env, order.id);
  const now = Date.now();

  // QR yang masih berlaku dipakai lagi, jadi membuka halaman bayar berulang tidak membuat charge baru.
  const active = rows.find((row) => isActive(row, now));
  if (active) return { payment: toPaymentView(active, order.order_number), created: false };

  const inFlight = rows.find(
    (row) =>
      row.status === 'pending' &&
      row.qris_payload === null &&
      now - new Date(row.created_at).getTime() < IN_FLIGHT_WINDOW_MS,
  );
  if (inFlight) {
    throw new AppError(409, 'payment_in_progress', 'QR sedang dibuat. Coba lagi sebentar ya.');
  }

  // Percobaan lama yang masih pending tapi sudah lewat waktu: pastikan tidak sempat dibayar.
  for (const stale of rows.filter((row) => row.status === 'pending')) {
    const status = await syncWithProvider(env, stale);
    if (status === 'paid') {
      throw new AppError(409, 'already_paid', 'Pembayaran untuk order ini sudah kami terima.');
    }
    if (status === 'pending') await expirePayment(env, stale);
  }

  const providerOrderId = buildProviderOrderId(order.order_number, rows.length + 1);
  const pending = await insertPendingPayment(env, {
    orderId: order.id,
    providerOrderId,
    amount,
    expiresAt: new Date(now + PAYMENT_LIFETIME_MS),
  });
  if (!pending) {
    throw new AppError(409, 'payment_in_progress', 'QR sedang dibuat. Coba lagi sebentar ya.');
  }

  let charge;
  try {
    charge = await chargeQris(env, { providerOrderId, amount });
  } catch (err) {
    await applyPaymentResultRpc(env, {
      providerOrderId,
      newStatus: 'failed',
      providerRef: null,
      paidAt: null,
    }).catch((rpcErr) => console.error('payments: gagal menandai charge gagal', rpcErr));
    throw err;
  }

  const saved = await saveChargeResult(env, pending.id, {
    qrisPayload: charge.qrString,
    qrisImageUrl: charge.qrImageUrl,
    externalReferenceId: charge.transactionId,
    expiresAt: charge.expiresAt ?? new Date(now + PAYMENT_LIFETIME_MS),
  });

  await logActivity(env, {
    userId: ctx.user.id,
    action: 'payment_create',
    entity: 'payment',
    entityId: saved.id,
    metadata: { order_id: order.id, provider_order_id: providerOrderId, amount },
  });

  return { payment: toPaymentView(saved, order.order_number), created: true };
}

export async function getPaymentStatus(
  env: Bindings,
  ctx: AuthContextUser,
  paymentId: string,
): Promise<PaymentView> {
  if (!isUuid(paymentId)) throw paymentNotFound();

  const access = await resolveAccess(env, ctx);
  let row = await findPaymentById(env, paymentId);
  if (!row) throw paymentNotFound();

  const order = await findOrderForPayment(env, row.order_id);
  if (!order) throw paymentNotFound();
  if (!(await canAccessPayment(env, ctx, access, order))) throw paymentNotFound();

  if (row.status === 'pending') {
    const now = Date.now();
    const checkedAt = row.provider_checked_at ? new Date(row.provider_checked_at).getTime() : 0;
    const due =
      now - checkedAt >= PROVIDER_CHECK_INTERVAL_MS || now >= expiresAtOf(row).getTime();

    if (due && row.qris_payload !== null) {
      try {
        await syncWithProvider(env, row);
      } catch (err) {
        // Midtrans sedang bermasalah: tetap jawab dari data kita, webhook masih bisa masuk.
        console.error('payments: cek status ke Midtrans gagal', err);
      }
      row = (await findPaymentById(env, paymentId)) ?? row;
    }

    if (row.status === 'pending' && Date.now() >= expiresAtOf(row).getTime()) {
      await expirePayment(env, row);
      row = (await findPaymentById(env, paymentId)) ?? row;
    }
  }

  return toPaymentView(row, order.order_number);
}
