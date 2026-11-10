import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import type { AuthContextUser } from '../../shared/types/user';
import { logActivity } from '../../shared/utils/activity-log';
import { isUuid, orderNotFound, resolveAccess } from '../orders/orders.access';
import type { OrderAccess } from '../orders/orders.access';
import {
  PAYMENT_EXPIRY_MINUTES,
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
import type {
  PaymentOrderRow,
  PaymentRow,
  PaymentStatusValue,
  PaymentView,
} from './payments.types';

const PAYMENT_LIFETIME_MS = PAYMENT_EXPIRY_MINUTES * 60_000;
/** Batas bawah jarak antar pengecekan ke Midtrans per payment (polling app tiap 3 dtk). */
const PROVIDER_CHECK_INTERVAL_MS = 10_000;
/** Percobaan tanpa QR yang lebih muda dari ini dianggap masih diproses request lain. */
const IN_FLIGHT_WINDOW_MS = 60_000;
const MAX_PROVIDER_ORDER_ID_LENGTH = 50;

export interface CreatePaymentResult {
  payment: PaymentView;
  /** false bila yang dikembalikan adalah QR aktif yang sudah ada. */
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

/** Saat ini hanya customer pemilik order. Order offline (QR di perangkat worker) menyusul. */
function assertOwnsOrder(access: OrderAccess, order: PaymentOrderRow): void {
  const scope = access.scope;
  if (
    access.viewer.role !== 'customer' ||
    scope.kind !== 'customer' ||
    scope.customerProfileId !== order.customer_id
  ) {
    throw orderNotFound();
  }
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

  const outcome = await applyPaymentResultRpc(env, {
    providerOrderId: payment.provider_order_id,
    newStatus: mapped,
    providerRef: result.transactionId,
    paidAt: result.settlementTime,
  });
  if (mapped === 'paid' && outcome.applied) {
    console.info(`payments: ${payment.provider_order_id} lunas`);
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
  await applyPaymentResultRpc(env, {
    providerOrderId: payment.provider_order_id,
    newStatus: 'expired',
    providerRef: null,
    paidAt: null,
  });
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
  assertOwnsOrder(access, order);

  if (order.status === 'cancelled') {
    throw new AppError(409, 'order_cancelled', 'Order ini sudah dibatalkan.');
  }
  if (order.payment_status === 'paid') {
    throw new AppError(409, 'already_paid', 'Order ini sudah dibayar.');
  }

  const amount = Math.round(order.total_price);
  if (amount < 1) {
    throw new AppError(400, 'amount_invalid', 'Total order tidak valid untuk dibayar.');
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
  try {
    assertOwnsOrder(access, order);
  } catch {
    throw paymentNotFound();
  }

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
