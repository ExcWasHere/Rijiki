import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { toNumber, toNumberOrNull } from '../../shared/utils/number';
import type { ListOrdersQuery } from './orders.schema';
import type {
  CustomerProfileRow,
  OrderRow,
  OrderScope,
  PromoRow,
  ServicePriceRow,
} from './orders.types';

const DEFAULT_RATE_PER_KM = 2000;

const PROMO_COLUMNS =
  'id, code, title, discount_type, discount_value, start_date, end_date, is_active, applies_to';

const ORDER_SELECT: string = [
  'id',
  'order_number',
  'status',
  'payment_status',
  'channel',
  'customer_id',
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
  'order_items(id, item_code, shoe_brand, quantity, price, notes, created_at, services(name), order_documentations(id, type, image_url))',
  'order_status_histories(new_status, notes, changed_at)',
].join(', ');

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

  if (error) {
    console.error('orders: gagal memuat customer_profiles', error.message);
    throw new AppError(500, 'order_load_failed', 'Gagal memuat profil customer');
  }
  if (!data) return null;

  return {
    id: data.id as string,
    default_address: (data.default_address as string | null) ?? null,
    default_lat: toNumberOrNull(data.default_lat),
    default_lng: toNumberOrNull(data.default_lng),
  };
}

export async function findWorkerProfileId(env: Bindings, userId: string): Promise<string | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('worker_profiles')
    .select('id')
    .eq('user_id', userId)
    .maybeSingle();

  if (error) {
    console.error('orders: gagal memuat worker_profiles', error.message);
    throw new AppError(500, 'order_load_failed', 'Gagal memuat profil worker');
  }
  return data ? (data.id as string) : null;
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

  if (error) {
    console.error('orders: gagal memuat services', error.message);
    throw new AppError(500, 'order_load_failed', 'Gagal memuat data layanan');
  }

  return (data ?? []).map((row) => ({
    id: row.id as string,
    name: row.name as string,
    base_price: toNumber(row.base_price),
    is_active: Boolean(row.is_active),
  }));
}

export async function findPromoByCode(env: Bindings, code: string): Promise<PromoRow | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin.from('promos').select(PROMO_COLUMNS).ilike('code', code).limit(5);

  if (error) {
    console.error('orders: gagal memuat promo', error.message);
    throw new AppError(500, 'order_load_failed', 'Gagal memeriksa kode promo');
  }

  const row = (data ?? []).find((r) => String(r.code).toUpperCase() === code.toUpperCase());
  return row ? (row as unknown as PromoRow) : null;
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
}

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
    console.error('orders: create_customer_order gagal', message);
    throw new AppError(500, 'order_create_failed', 'Order gagal dibuat. Coba lagi ya.');
  }

  if (typeof data !== 'string') {
    console.error('orders: create_customer_order tidak mengembalikan id', data);
    throw new AppError(500, 'order_create_failed', 'Order gagal dibuat. Coba lagi ya.');
  }
  return data;
}

export async function getOrderRow(env: Bindings, id: string): Promise<OrderRow | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('orders')
    .select(ORDER_SELECT)
    .eq('id', id)
    .maybeSingle();

  if (error) {
    console.error('orders: gagal memuat order', error.message);
    throw new AppError(500, 'order_load_failed', 'Gagal memuat order');
  }
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

  if (scope.kind === 'customer') builder = builder.eq('customer_id', scope.customerProfileId);
  if (scope.kind === 'worker') builder = builder.eq('assigned_worker_id', scope.workerProfileId);

  if (query.status) builder = builder.eq('status', query.status);
  if (query.active === 'true') builder = builder.not('status', 'in', '(completed,cancelled)');
  if (query.active === 'false') builder = builder.in('status', ['completed', 'cancelled']);

  const { data, error, count } = await builder
    .order('created_at', { ascending: false })
    .range(from, to);

  if (error) {
    console.error('orders: gagal memuat daftar order', error.message);
    throw new AppError(500, 'order_load_failed', 'Gagal memuat daftar order');
  }

  return { rows: (data ?? []) as unknown as OrderRow[], total: count ?? 0 };
}
