import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { toNumber, toNumberOrNull } from '../../shared/utils/number';
import { EMPTY_USAGE } from './orders.pricing';
import type { ListOrdersQuery } from './orders.schema';
import type {
  CustomerProfileRow,
  DocumentationType,
  OrderRow,
  OrderScope,
  OrderStatus,
  PromoRow,
  PromoUsage,
  ServicePriceRow,
  WorkerProfileRow,
} from './orders.types';

const DEFAULT_RATE_PER_KM = 2000;

const PROMO_COLUMNS = [
  'id',
  'code',
  'title',
  'discount_type',
  'discount_value',
  'start_date',
  'end_date',
  'is_active',
  'applies_to',
  'min_subtotal',
  'max_discount_amount',
  'usage_limit',
  'usage_limit_per_customer',
  'first_order_only',
  'promo_services(service_id)',
].join(', ');

const ORDER_SELECT: string = [
  'id',
  'order_number',
  'status',
  'payment_status',
  'channel',
  'delivery_method',
  'customer_id',
  'walk_in_customer_name',
  'walk_in_customer_phone',
  'assigned_worker_id',
  'subtotal',
  'discount_amount',
  'shipping_fee',
  'total_price',
  'pickup_address',
  'delivery_address',
  'scheduled_pickup_at',
  'completed_at',
  'created_at',
  'promos(code)',
  'customer:customer_profiles(users(full_name, phone_number))',
  'worker:worker_profiles(users(full_name))',
  'ratings(id)',
  'order_items(id, item_code, shoe_brand, quantity, price, notes, services(name))',
  'order_status_histories(new_status, notes, changed_at)',
  'order_documentations(id, type, image_url, order_item_id)',
].join(', ');

function loadFailed(label: string, message: string, publicMessage: string): AppError {
  console.error(`orders: gagal memuat ${label}`, message);
  return new AppError(500, 'order_load_failed', publicMessage);
}

export async function findCustomerProfileByUserId(
  env: Bindings,
  userId: string,
): Promise<CustomerProfileRow | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('customer_profiles')
    .select('id, default_address, default_lat, default_lng')
    .eq('user_id', userId)
    .maybeSingle();

  if (error) throw loadFailed('customer_profiles', error.message, 'Gagal memuat profil customer');
  if (!data) return null;

  return {
    id: data.id as string,
    default_address: (data.default_address as string | null) ?? null,
    default_lat: toNumberOrNull(data.default_lat),
    default_lng: toNumberOrNull(data.default_lng),
  };
}

export async function findWorkerProfile(
  env: Bindings,
  userId: string,
): Promise<WorkerProfileRow | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('worker_profiles')
    .select('id, status')
    .eq('user_id', userId)
    .maybeSingle();

  if (error) throw loadFailed('worker_profiles', error.message, 'Gagal memuat profil worker');
  return data ? { id: data.id as string, status: String(data.status) } : null;
}

export async function findWorkerProfileById(
  env: Bindings,
  workerId: string,
): Promise<WorkerProfileRow | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('worker_profiles')
    .select('id, status')
    .eq('id', workerId)
    .maybeSingle();

  if (error) throw loadFailed('worker_profiles', error.message, 'Gagal memuat data worker');
  return data ? { id: data.id as string, status: String(data.status) } : null;
}

export async function getRatePerKm(env: Bindings): Promise<number> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('shipping_settings')
    .select('rate_per_km')
    .order('updated_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error) {
    console.error('orders: gagal membaca shipping_settings, pakai tarif bawaan', error.message);
    return DEFAULT_RATE_PER_KM;
  }
  const rate = toNumber(data?.rate_per_km, DEFAULT_RATE_PER_KM);
  return rate > 0 ? rate : DEFAULT_RATE_PER_KM;
}

export async function findServicesByIds(env: Bindings, ids: string[]): Promise<ServicePriceRow[]> {
  if (ids.length === 0) return [];
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('services')
    .select('id, name, base_price, is_active')
    .in('id', ids);

  if (error) throw loadFailed('services', error.message, 'Gagal memuat data layanan');

  return (data ?? []).map((row) => ({
    id: row.id as string,
    name: row.name as string,
    base_price: toNumber(row.base_price),
    is_active: Boolean(row.is_active),
  }));
}

export async function findPromoByCode(env: Bindings, code: string): Promise<PromoRow | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('promos')
    .select(PROMO_COLUMNS)
    .ilike('code', code)
    .limit(5);

  if (error) throw loadFailed('promo', error.message, 'Gagal memeriksa kode promo');

  const row = (data ?? []).find(
    (r) => String((r as unknown as { code: string }).code).toUpperCase() === code.toUpperCase(),
  );
  return row ? (row as unknown as PromoRow) : null;
}

async function countOrders(
  env: Bindings,
  filters: { promoId?: string; customerId?: string },
): Promise<number> {
  const admin = getSupabaseAdmin(env);
  let builder = admin
    .from('orders')
    .select('id', { count: 'exact', head: true })
    .neq('status', 'cancelled');
  if (filters.promoId) builder = builder.eq('promo_id', filters.promoId);
  if (filters.customerId) builder = builder.eq('customer_id', filters.customerId);

  const { count, error } = await builder;
  if (error) throw loadFailed('pemakaian promo', error.message, 'Gagal memeriksa kuota promo');
  return count ?? 0;
}

/**
 * Pemakaian promo untuk pengecekan ramah di quote/checkout. Hanya menghitung
 * yang dibutuhkan promo itu. Pengecekan yang mengikat (atomik) ada di
 * create_customer_order.
 */
export async function getPromoUsage(
  env: Bindings,
  promo: PromoRow,
  customerId: string | null,
): Promise<PromoUsage> {
  const needsTotal = promo.usage_limit !== null && promo.usage_limit !== undefined;
  const needsPerCustomer =
    promo.usage_limit_per_customer !== null && promo.usage_limit_per_customer !== undefined;
  const needsFirstOrder = Boolean(promo.first_order_only);

  if (!needsTotal && !needsPerCustomer && !needsFirstOrder) return EMPTY_USAGE;

  const [total, perCustomer, customerOrders] = await Promise.all([
    needsTotal ? countOrders(env, { promoId: promo.id }) : Promise.resolve(0),
    needsPerCustomer && customerId
      ? countOrders(env, { promoId: promo.id, customerId })
      : Promise.resolve(0),
    needsFirstOrder && customerId ? countOrders(env, { customerId }) : Promise.resolve(0),
  ]);

  return { total, perCustomer, customerOrders };
}

export interface CreateOrderRpcParams {
  userId: string;
  items: Array<{ service_id: string; shoe_brand: string; quantity: number; notes: string | null }>;
  pickupAddress: string;
  pickupLat: number;
  pickupLng: number;
  deliveryAddress: string;
  promoId: string | null;
  discountAmount: number;
  shippingFee: number;
  expectedSubtotal: number;
  idempotencyKey: string | null;
  requestFingerprint: string | null;
}

const PROMO_RPC_ERRORS: Array<[string, string]> = [
  ['promo_inactive', 'Kode promo tidak ditemukan atau sudah tidak berlaku.'],
  ['promo_min_subtotal', 'Belanja kamu belum memenuhi syarat minimal promo ini.'],
  ['promo_first_order_only', 'Promo ini hanya berlaku untuk order pertama.'],
  ['promo_customer_quota_exceeded', 'Kamu sudah mencapai batas pemakaian promo ini.'],
  ['promo_quota_exceeded', 'Kuota promo ini sudah habis.'],
];

export async function createOrderViaRpc(
  env: Bindings,
  params: CreateOrderRpcParams,
): Promise<string> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin.rpc('create_customer_order', {
    p_user_id: params.userId,
    p_items: params.items,
    p_pickup_address: params.pickupAddress,
    p_pickup_lat: params.pickupLat,
    p_pickup_lng: params.pickupLng,
    p_delivery_address: params.deliveryAddress,
    p_promo_id: params.promoId,
    p_discount_amount: params.discountAmount,
    p_shipping_fee: params.shippingFee,
    p_expected_subtotal: params.expectedSubtotal,
    p_idempotency_key: params.idempotencyKey,
    p_request_fingerprint: params.requestFingerprint,
  });

  if (error) {
    const message = error.message ?? '';
    if (message.includes('price_changed')) {
      throw new AppError(409, 'price_changed', 'Harga layanan baru saja berubah. Periksa ringkasan lagi.');
    }
    if (message.includes('service_unavailable')) {
      throw new AppError(400, 'service_unavailable', 'Salah satu layanan sudah tidak tersedia.');
    }
    if (message.includes('customer_not_found')) {
      throw new AppError(400, 'profile_incomplete', 'Lengkapi profil dulu sebelum membuat order.');
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
    console.error('orders: create_customer_order gagal', message);
    throw new AppError(500, 'order_create_failed', 'Order gagal dibuat. Coba lagi ya.');
  }

  if (typeof data !== 'string') {
    console.error('orders: create_customer_order tidak mengembalikan id', data);
    throw new AppError(500, 'order_create_failed', 'Order gagal dibuat. Coba lagi ya.');
  }
  return data;
}

/** Order yang sudah dibuat dengan kunci idempotency ini (untuk request ulang). */
export async function findOrderByIdempotencyKey(
  env: Bindings,
  customerId: string,
  key: string,
): Promise<{ id: string; fingerprint: string | null } | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('orders')
    .select('id, idempotency_fingerprint')
    .eq('customer_id', customerId)
    .eq('idempotency_key', key)
    .maybeSingle();

  if (error) throw loadFailed('idempotency order', error.message, 'Gagal memeriksa order');
  if (!data) return null;
  return {
    id: data.id as string,
    fingerprint: (data.idempotency_fingerprint as string | null) ?? null,
  };
}

export async function getOrderRow(env: Bindings, id: string): Promise<OrderRow | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('orders')
    .select(ORDER_SELECT)
    .eq('id', id)
    .maybeSingle();

  if (error) throw loadFailed('order', error.message, 'Gagal memuat order');
  return (data as OrderRow | null) ?? null;
}

export async function listOrderRows(
  env: Bindings,
  scope: Exclude<OrderScope, { kind: 'none' }>,
  query: ListOrdersQuery,
): Promise<{ rows: OrderRow[]; total: number }> {
  const admin = getSupabaseAdmin(env);
  const from = (query.page - 1) * query.limit;
  const to = from + query.limit - 1;

  let builder = admin.from('orders').select(ORDER_SELECT, { count: 'exact' });

  if (query.unassigned === 'true') {
    builder = builder
      .is('assigned_worker_id', null)
      .not('status', 'in', '(completed,cancelled)');
    if (scope.kind === 'worker') {
      builder = builder.eq('status', 'order').eq('channel', 'customer_app');
    }
    if (scope.kind === 'customer') builder = builder.eq('customer_id', scope.customerProfileId);
  } else {
    if (scope.kind === 'customer') builder = builder.eq('customer_id', scope.customerProfileId);
    if (scope.kind === 'worker') builder = builder.eq('assigned_worker_id', scope.workerProfileId);
  }

  if (query.status) builder = builder.eq('status', query.status);
  if (query.active === 'true') builder = builder.not('status', 'in', '(completed,cancelled)');
  if (query.active === 'false') builder = builder.in('status', ['completed', 'cancelled']);

  const { data, error, count } = await builder
    .order('created_at', { ascending: false })
    .range(from, to);

  if (error) throw loadFailed('daftar order', error.message, 'Gagal memuat daftar order');

  return { rows: (data ?? []) as unknown as OrderRow[], total: count ?? 0 };
}

/** Atomik: hanya berhasil bila order masih belum punya worker dan berstatus `order`. */
export async function claimOrderRow(
  env: Bindings,
  orderId: string,
  workerProfileId: string,
): Promise<boolean> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('orders')
    .update({ assigned_worker_id: workerProfileId, updated_at: new Date().toISOString() })
    .eq('id', orderId)
    .is('assigned_worker_id', null)
    .eq('status', 'order')
    .eq('channel', 'customer_app')
    .select('id');

  if (error) {
    console.error('orders: gagal mengambil order', error.message);
    throw new AppError(500, 'order_update_failed', 'Gagal mengambil order. Coba lagi ya.');
  }
  return (data?.length ?? 0) > 0;
}

export async function assignOrderRow(
  env: Bindings,
  orderId: string,
  workerProfileId: string | null,
): Promise<void> {
  const admin = getSupabaseAdmin(env);
  const { error } = await admin
    .from('orders')
    .update({ assigned_worker_id: workerProfileId, updated_at: new Date().toISOString() })
    .eq('id', orderId);

  if (error) {
    console.error('orders: gagal assign worker', error.message);
    throw new AppError(500, 'order_update_failed', 'Gagal menyimpan assign worker. Coba lagi ya.');
  }
}

export async function changeOrderStatusRpc(
  env: Bindings,
  params: {
    orderId: string;
    expectedStatus: OrderStatus;
    newStatus: OrderStatus;
    changedBy: string;
    notes: string | null;
  },
): Promise<void> {
  const admin = getSupabaseAdmin(env);
  const { error } = await admin.rpc('change_order_status', {
    p_order_id: params.orderId,
    p_expected_status: params.expectedStatus,
    p_new_status: params.newStatus,
    p_changed_by: params.changedBy,
    p_notes: params.notes ?? '',
  });

  if (error) {
    if ((error.message ?? '').includes('status_conflict')) {
      throw new AppError(409, 'status_conflict', 'Status order baru saja berubah. Muat ulang lalu coba lagi.');
    }
    console.error('orders: change_order_status gagal', error.message);
    throw new AppError(500, 'order_update_failed', 'Gagal mengubah status. Coba lagi ya.');
  }
}

export interface DocumentationRow {
  id: string;
  order_id: string;
  order_item_id: string | null;
  type: DocumentationType;
  image_url: string;
}

export async function getDocumentationRow(
  env: Bindings,
  docId: string,
): Promise<DocumentationRow | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('order_documentations')
    .select('id, order_id, order_item_id, type, image_url')
    .eq('id', docId)
    .maybeSingle();

  if (error) throw loadFailed('dokumentasi', error.message, 'Gagal memuat dokumentasi');
  return (data as DocumentationRow | null) ?? null;
}

export async function insertDocumentationRow(
  env: Bindings,
  params: {
    orderId: string;
    orderItemId: string | null;
    type: DocumentationType;
    imageKey: string;
    uploadedBy: string;
  },
): Promise<DocumentationRow> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('order_documentations')
    .insert({
      order_id: params.orderId,
      order_item_id: params.orderItemId,
      type: params.type,
      image_url: params.imageKey,
      uploaded_by: params.uploadedBy,
    })
    .select('id, order_id, order_item_id, type, image_url')
    .single();

  if (error || !data) {
    console.error('orders: gagal menyimpan dokumentasi', error?.message);
    throw new AppError(500, 'documentation_save_failed', 'Gagal menyimpan foto. Coba lagi ya.');
  }
  return data as DocumentationRow;
}

export async function deleteDocumentationRows(env: Bindings, ids: string[]): Promise<void> {
  if (ids.length === 0) return;
  const admin = getSupabaseAdmin(env);
  const { error } = await admin.from('order_documentations').delete().in('id', ids);
  if (error) {
    console.error('orders: gagal menghapus dokumentasi', error.message);
    throw new AppError(500, 'documentation_delete_failed', 'Gagal menghapus foto. Coba lagi ya.');
  }
}
