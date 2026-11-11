import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { EMPTY_USAGE } from './orders.pricing';
import type { PromoRow, PromoUsage } from './orders.types';

function loadFailed(label: string, message: string, publicMessage: string): AppError {
  console.error(`orders.offline: gagal memuat ${label}`, message);
  return new AppError(500, 'order_load_failed', publicMessage);
}

/** Order offline yang sudah dibuat pemanggil dengan kunci idempotency ini (untuk request ulang). */
export async function findOfflineOrderByIdempotencyKey(
  env: Bindings,
  createdBy: string,
  key: string,
): Promise<{ id: string; fingerprint: string | null } | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('orders')
    .select('id, idempotency_fingerprint')
    .eq('created_by', createdBy)
    .eq('channel', 'staff_manual')
    .eq('idempotency_key', key)
    .limit(1)
    .maybeSingle();

  if (error) throw loadFailed('idempotency order offline', error.message, 'Gagal memeriksa order');
  if (!data) return null;
  return {
    id: data.id as string,
    fingerprint: (data.idempotency_fingerprint as string | null) ?? null,
  };
}

async function countOrders(
  env: Bindings,
  filters: { promoId?: string; walkInPhone?: string },
): Promise<number> {
  const admin = getSupabaseAdmin(env);
  let builder = admin
    .from('orders')
    .select('id', { count: 'exact', head: true })
    .neq('status', 'cancelled');
  if (filters.promoId) builder = builder.eq('promo_id', filters.promoId);
  if (filters.walkInPhone) {
    builder = builder.eq('channel', 'staff_manual').eq('walk_in_customer_phone', filters.walkInPhone);
  }

  const { count, error } = await builder;
  if (error) throw loadFailed('pemakaian promo', error.message, 'Gagal memeriksa kuota promo');
  return count ?? 0;
}

/**
 * Pemakaian promo untuk customer offline. Customer tanpa akun dikenali dari
 * nomor HP. Pengecekan yang mengikat (atomik) ada di create_offline_order.
 */
export async function getWalkInPromoUsage(
  env: Bindings,
  promo: PromoRow,
  walkInPhone: string,
): Promise<PromoUsage> {
  const needsTotal = promo.usage_limit !== null && promo.usage_limit !== undefined;
  const needsPerCustomer =
    promo.usage_limit_per_customer !== null && promo.usage_limit_per_customer !== undefined;
  const needsFirstOrder = Boolean(promo.first_order_only);

  if (!needsTotal && !needsPerCustomer && !needsFirstOrder) return EMPTY_USAGE;

  const [total, perCustomer, customerOrders] = await Promise.all([
    needsTotal ? countOrders(env, { promoId: promo.id }) : Promise.resolve(0),
    needsPerCustomer ? countOrders(env, { promoId: promo.id, walkInPhone }) : Promise.resolve(0),
    needsFirstOrder ? countOrders(env, { walkInPhone }) : Promise.resolve(0),
  ]);

  return { total, perCustomer, customerOrders };
}

export interface CreateOfflineOrderRpcParams {
  userId: string;
  items: Array<{ service_id: string; shoe_brand: string; quantity: number; notes: string | null }>;
  walkInName: string;
  walkInPhone: string;
  promoId: string | null;
  discountAmount: number;
  expectedSubtotal: number;
  paymentMethod: 'cash' | 'qris';
  deliveryMethod: 'self_pickup' | 'delivery';
  assignedWorkerId: string | null;
  idempotencyKey: string | null;
  requestFingerprint: string | null;
}

const PROMO_RPC_ERRORS: Array<[string, string]> = [
  ['promo_inactive', 'Kode promo tidak ditemukan atau sudah tidak berlaku.'],
  ['promo_min_subtotal', 'Belanja belum memenuhi syarat minimal promo ini.'],
  ['promo_first_order_only', 'Promo ini hanya berlaku untuk order pertama.'],
  ['promo_customer_quota_exceeded', 'Customer ini sudah mencapai batas pemakaian promo.'],
  ['promo_quota_exceeded', 'Kuota promo ini sudah habis.'],
];

export async function createOfflineOrderViaRpc(
  env: Bindings,
  params: CreateOfflineOrderRpcParams,
): Promise<string> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin.rpc('create_offline_order', {
    p_user_id: params.userId,
    p_items: params.items,
    p_walk_in_name: params.walkInName,
    p_walk_in_phone: params.walkInPhone,
    p_promo_id: params.promoId,
    p_discount_amount: params.discountAmount,
    p_expected_subtotal: params.expectedSubtotal,
    p_payment_method: params.paymentMethod,
    p_delivery_method: params.deliveryMethod,
    p_assigned_worker_id: params.assignedWorkerId,
    p_idempotency_key: params.idempotencyKey,
    p_request_fingerprint: params.requestFingerprint,
  });

  if (error) {
    const message = error.message ?? '';
    if (message.includes('price_changed')) {
      throw new AppError(409, 'price_changed', 'Harga layanan baru saja berubah. Coba simpan lagi.');
    }
    if (message.includes('service_unavailable')) {
      throw new AppError(400, 'service_unavailable', 'Salah satu layanan sudah tidak tersedia.');
    }
    if (message.includes('idempotency_conflict')) {
      throw new AppError(
        409,
        'idempotency_conflict',
        'Permintaan ini memakai kunci yang sama dengan permintaan sebelumnya yang isinya berbeda.',
      );
    }
    for (const [marker, publicMessage] of PROMO_RPC_ERRORS) {
      if (message.includes(marker)) throw new AppError(400, 'promo_invalid', publicMessage);
    }
    console.error('orders.offline: create_offline_order gagal', message);
    throw new AppError(500, 'order_create_failed', 'Order gagal disimpan. Coba lagi ya.');
  }

  if (typeof data !== 'string') {
    console.error('orders.offline: create_offline_order tidak mengembalikan id', data);
    throw new AppError(500, 'order_create_failed', 'Order gagal disimpan. Coba lagi ya.');
  }
  return data;
}
