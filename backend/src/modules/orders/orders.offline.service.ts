import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import type { AuthContextUser } from '../../shared/types/user';
import { logActivity } from '../../shared/utils/activity-log';
import { fingerprintOf, idempotencyConflict } from '../../shared/utils/idempotency';
import { toNumber } from '../../shared/utils/number';
import { notifyOfflineOrder } from '../notifications/notifications.events';
import { resolveAccess } from './orders.access';
import { toOrderView } from './orders.mapper';
import { insertCashOrderIncome } from '../finance/finance.repo';
import { EMPTY_USAGE, evaluatePromos, toRpcPromos, todayWib } from './orders.pricing';
import { createOfflineOrderViaRpc, findOfflineOrderByIdempotencyKey, getWalkInPromoUsage } from './orders.offline.repo';
import {
  findPromoByCode,
  findWorkerProfile,
  findWorkerProfileById,
  getOrderRow,
  markOrderPaidIfFree,
} from './orders.repo';
import type { CreateOfflineOrderInput } from './orders.schema';
import { priceItems } from './orders.service';
import type { CreateOrderResult } from './orders.service';

/** Worker penangan: pilihan form, atau worker yang login (owner tidak punya profil worker). */
async function resolveAssignedWorker(
  env: Bindings,
  ctx: AuthContextUser,
  requestedId: string | null,
): Promise<string | null> {
  const own =
    ctx.user.role === 'worker' ? await findWorkerProfile(env, ctx.user.id) : null;

  if (requestedId) {
    const worker = await findWorkerProfileById(env, requestedId);
    if (!worker || worker.status !== 'active') {
      throw new AppError(400, 'worker_invalid', 'Worker yang dipilih tidak ditemukan atau tidak aktif.');
    }

    // Menugaskan order ke orang lain butuh wewenang atas semua order; kalau
    // tidak, worker bisa "menitipkan" order (dan pemasukan tunainya) ke rekan.
    const mayAssignOthers = ctx.ownerBypass || ctx.permissions.includes('manage_orders_all');
    if (worker.id !== own?.id && !mayAssignOthers) {
      throw new AppError(
        403,
        'forbidden',
        'Hanya owner atau worker berizin manage_orders_all yang dapat menugaskan order ke worker lain.',
      );
    }
    return worker.id;
  }

  if (ctx.user.role === 'worker') {
    if (!own) {
      throw new AppError(400, 'worker_profile_missing', 'Profil worker kamu belum ada. Hubungi owner.');
    }
    return own.id;
  }
  return null;
}

/**
 * Mencatat pemasukan tunai order offline. Dipanggil juga saat replay
 * idempoten, karena request pertama bisa sudah membuat order tetapi gagal
 * mencatat pendapatannya. Aman diulang: ada unique index per order.
 */
async function recordCashIncome(
  env: Bindings,
  ctx: AuthContextUser,
  orderId: string,
): Promise<void> {
  const cashRow = await getOrderRow(env, orderId);
  const cashAmount = Math.round(toNumber(cashRow?.total_price));
  if (!cashRow || cashAmount <= 0) return;

  try {
    await insertCashOrderIncome(env, {
      userId: ctx.user.id,
      orderId,
      orderNumber: String(cashRow.order_number ?? ''),
      amount: cashAmount,
      transactionDate: todayWib(),
    });
  } catch (err) {
    console.error('orders.offline: gagal mencatat pemasukan tunai', orderId, err);
    throw new AppError(
      500,
      'income_record_failed',
      'Order tersimpan, tetapi pemasukan tunai gagal dicatat. Ulangi dengan kunci yang sama.',
    );
  }
}

function offlineFingerprint(
  input: CreateOfflineOrderInput,
  assignedWorkerId: string | null,
): Promise<string> {
  return fingerprintOf({
    name: input.walk_in_customer_name,
    phone: input.walk_in_customer_phone,
    items: input.items.map((item) => [
      item.service_id,
      item.shoe_brand,
      item.quantity,
      item.notes,
    ]),
    promos: [...input.promo_codes].sort(),
    worker: assignedWorkerId,
    payment: input.payment_method,
    delivery: input.delivery_method,
  });
}

/**
 * Order offline di outlet (PRD 10.1): tanpa akun customer, status awal `waiting`,
 * tanpa ongkir. Tunai langsung `paid`; QRIS dibuat `unpaid` dan QR-nya dibuat
 * lewat POST /api/orders/:id/payment.
 */
export async function createOfflineOrder(
  env: Bindings,
  ctx: AuthContextUser,
  input: CreateOfflineOrderInput,
  idempotencyKey: string | null,
): Promise<CreateOrderResult> {
  if (ctx.user.role !== 'worker' && ctx.user.role !== 'owner') {
    throw new AppError(403, 'forbidden', 'Hanya worker atau owner yang dapat mencatat order offline');
  }

  if (input.delivery_method === 'delivery') {
    throw new AppError(
      400,
      'delivery_unavailable',
      'Pengantaran untuk order offline masih dalam maintenance. Pilih ambil sendiri dulu ya.',
    );
  }

  const access = await resolveAccess(env, ctx);
  const assignedWorkerId = await resolveAssignedWorker(env, ctx, input.assigned_worker_id ?? null);
  const fingerprint = idempotencyKey ? await offlineFingerprint(input, assignedWorkerId) : null;

  if (idempotencyKey) {
    const existing = await findOfflineOrderByIdempotencyKey(env, ctx.user.id, idempotencyKey);
    if (existing) {
      if (existing.fingerprint !== fingerprint) throw idempotencyConflict();
      const row = await getOrderRow(env, existing.id);
      if (row) {
        // Request sebelumnya bisa sudah membuat order tetapi gagal mencatat
        // pemasukan tunai; replay adalah kesempatan memperbaikinya.
        if (input.payment_method === 'cash') await recordCashIncome(env, ctx, existing.id);
        return { order: toOrderView(row, access.viewer), replayed: true };
      }
    }
  }

  const priced = await priceItems(env, input.items);

  const promoEntries = await Promise.all(
    input.promo_codes.map(async (code) => {
      const promo = await findPromoByCode(env, code);
      const usage = promo
        ? await getWalkInPromoUsage(env, promo, input.walk_in_customer_phone)
        : EMPTY_USAGE;
      return { code, promo, usage };
    }),
  );
  // Order offline tanpa ongkir: promo ongkir ditolak evaluatePromo.
  const evaluations = evaluatePromos(promoEntries, {
    subtotal: priced.subtotal,
    shipping: 0,
    lines: priced.lines,
  });

  let orderId: string;
  try {
    orderId = await createOfflineOrderViaRpc(env, {
      userId: ctx.user.id,
      items: input.items.map((item) => ({
        service_id: item.service_id,
        shoe_brand: item.shoe_brand,
        quantity: item.quantity,
        notes: item.notes,
      })),
      walkInName: input.walk_in_customer_name,
      walkInPhone: input.walk_in_customer_phone,
      promos: toRpcPromos(evaluations),
      expectedSubtotal: priced.subtotal,
      paymentMethod: input.payment_method,
      deliveryMethod: input.delivery_method,
      assignedWorkerId,
      idempotencyKey,
      requestFingerprint: fingerprint,
    });
  } catch (err) {
    // Kalah balapan dengan request yang sama: anggap replay bila isinya sama.
    if (idempotencyKey && err instanceof AppError && err.code === 'idempotency_conflict') {
      const existing = await findOfflineOrderByIdempotencyKey(env, ctx.user.id, idempotencyKey);
      if (existing && existing.fingerprint === fingerprint) {
        const row = await getOrderRow(env, existing.id);
        if (row) {
          if (input.payment_method === 'cash') await recordCashIncome(env, ctx, existing.id);
          return { order: toOrderView(row, access.viewer), replayed: true };
        }
      }
    }
    throw err;
  }

  // Pemasukan QRIS dicatat apply_payment_result saat lunas; tunai diterima
  // worker saat order dibuat, jadi dicatat sekarang (PRD 15.2). Gagal mencatat
  // tidak boleh ditelan: order sudah ada, jadi replay dengan kunci yang sama
  // akan menyelesaikannya (unique index menjaga tidak dobel).
  if (input.payment_method === 'cash') await recordCashIncome(env, ctx, orderId);

  await logActivity(env, {
    userId: ctx.user.id,
    action: 'order_create_offline',
    entity: 'order',
    entityId: orderId,
    metadata: {
      payment_method: input.payment_method,
      delivery_method: input.delivery_method,
      assigned_worker_id: assignedWorkerId,
    },
  });

  let row = await getOrderRow(env, orderId);
  if (!row) {
    console.error('orders.offline: order baru tidak ditemukan setelah dibuat', orderId);
    throw new AppError(500, 'order_create_failed', 'Order disimpan, tetapi gagal dimuat. Cek daftar order.');
  }

  // Total 0 (promo menutup seluruh biaya) tidak bisa dibayar lewat QRIS:
  // langsung lunas supaya order bisa langsung diproses.
  if (row.payment_status === 'unpaid' && toNumber(row.total_price) <= 0) {
    if (await markOrderPaidIfFree(env, orderId)) {
      await logActivity(env, {
        userId: ctx.user.id,
        action: 'order_free_paid',
        entity: 'order',
        entityId: orderId,
        metadata: { total_price: 0, channel: 'staff_manual' },
      });
      row = (await getOrderRow(env, orderId)) ?? row;
    }
  }

  await notifyOfflineOrder(
    env,
    {
      id: orderId,
      order_number: String(row.order_number),
      customer_name: input.walk_in_customer_name,
    },
    ctx.user.id,
  );

  return { order: toOrderView(row, access.viewer), replayed: false };
}
