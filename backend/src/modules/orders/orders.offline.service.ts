import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import type { AuthContextUser } from '../../shared/types/user';
import { logActivity } from '../../shared/utils/activity-log';
import { fingerprintOf, idempotencyConflict } from '../../shared/utils/idempotency';
import { resolveAccess } from './orders.access';
import { toOrderView } from './orders.mapper';
import { EMPTY_USAGE, evaluatePromo } from './orders.pricing';
import type { PromoEvaluation } from './orders.pricing';
import { createOfflineOrderViaRpc, findOfflineOrderByIdempotencyKey, getWalkInPromoUsage } from './orders.offline.repo';
import { findPromoByCode, findWorkerProfile, findWorkerProfileById, getOrderRow } from './orders.repo';
import type { CreateOfflineOrderInput } from './orders.schema';
import { priceItems } from './orders.service';
import type { CreateOrderResult } from './orders.service';

/** Worker penangan: pilihan form, atau worker yang login (owner tidak punya profil worker). */
async function resolveAssignedWorker(
  env: Bindings,
  ctx: AuthContextUser,
  requestedId: string | null,
): Promise<string | null> {
  if (requestedId) {
    const worker = await findWorkerProfileById(env, requestedId);
    if (!worker || worker.status !== 'active') {
      throw new AppError(400, 'worker_invalid', 'Worker yang dipilih tidak ditemukan atau tidak aktif.');
    }
    return worker.id;
  }

  if (ctx.user.role === 'worker') {
    const own = await findWorkerProfile(env, ctx.user.id);
    if (!own) {
      throw new AppError(400, 'worker_profile_missing', 'Profil worker kamu belum ada. Hubungi owner.');
    }
    return own.id;
  }
  return null;
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
    promo: input.promo_code ?? null,
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
      if (row) return { order: toOrderView(row, access.viewer), replayed: true };
    }
  }

  const priced = await priceItems(env, input.items);

  let evaluation: PromoEvaluation | null = null;
  let promoId: string | null = null;
  if (input.promo_code) {
    const promo = await findPromoByCode(env, input.promo_code);
    const usage = promo
      ? await getWalkInPromoUsage(env, promo, input.walk_in_customer_phone)
      : EMPTY_USAGE;
    evaluation = evaluatePromo(promo, {
      subtotal: priced.subtotal,
      shipping: 0,
      lines: priced.lines,
      usage,
    });
    promoId = promo?.id ?? null;
  }

  const orderId = await createOfflineOrderViaRpc(env, {
    userId: ctx.user.id,
    items: input.items.map((item) => ({
      service_id: item.service_id,
      shoe_brand: item.shoe_brand,
      quantity: item.quantity,
      notes: item.notes,
    })),
    walkInName: input.walk_in_customer_name,
    walkInPhone: input.walk_in_customer_phone,
    promoId,
    discountAmount: evaluation?.discount ?? 0,
    expectedSubtotal: priced.subtotal,
    paymentMethod: input.payment_method,
    deliveryMethod: input.delivery_method,
    assignedWorkerId,
    idempotencyKey,
    requestFingerprint: fingerprint,
  });

  // TODO(finance): pemasukan tunai belum dicatat ke financial_transactions
  // (modul finance belum dibuat). Pemasukan QRIS sudah dicatat apply_payment_result.

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

  const row = await getOrderRow(env, orderId);
  if (!row) {
    console.error('orders.offline: order baru tidak ditemukan setelah dibuat', orderId);
    throw new AppError(500, 'order_create_failed', 'Order disimpan, tetapi gagal dimuat. Cek daftar order.');
  }
  return { order: toOrderView(row, access.viewer), replayed: false };
}
