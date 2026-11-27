import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { toNumber } from '../../shared/utils/number';
import type { HistoryQuery } from './profile.schema';
import type { CustomerRatingView, MyShoeView } from './profile.types';

const SHOE_SELECT = [
  'id',
  'order_id',
  'shoe_brand',
  'quantity',
  'item_code',
  'notes',
  'order:orders!inner(order_number, customer_id, status, completed_at, created_at)',
  'service:services(name)',
].join(', ');

const RATING_SELECT = [
  'id',
  'order_id',
  'rating_value',
  'comment',
  'photo_url',
  'is_featured',
  'created_at',
  'order:orders(order_number)',
  'worker:worker_profiles(users(full_name))',
].join(', ');

function failed(label: string, message: string): AppError {
  console.error(`profile: gagal ${label}`, message);
  return new AppError(500, 'profile_history_failed', `Gagal ${label}. Coba lagi ya.`);
}

async function customerProfileIdOf(env: Bindings, userId: string): Promise<string | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('customer_profiles')
    .select('id')
    .eq('user_id', userId)
    .maybeSingle();

  if (error) throw failed('memuat profil customer', error.message);
  return (data?.id as string | undefined) ?? null;
}

/**
 * Sepatu yang pernah dicuci customer: diambil dari order_items pada order yang
 * sudah selesai (atau masih berjalan), terbaru dulu. Satu baris = satu pasang
 * pada satu order, jadi sepatu yang dicuci dua kali tampil dua kali.
 */
export async function listMyShoes(
  env: Bindings,
  userId: string,
  query: HistoryQuery,
): Promise<{ items: MyShoeView[]; page: number; limit: number; total: number }> {
  const customerId = await customerProfileIdOf(env, userId);
  if (!customerId) return { items: [], page: query.page, limit: query.limit, total: 0 };

  const admin = getSupabaseAdmin(env);
  const from = (query.page - 1) * query.limit;

  const { data, error, count } = await admin
    .from('order_items')
    .select(SHOE_SELECT, { count: 'exact' })
    .eq('order.customer_id', customerId)
    .neq('order.status', 'cancelled')
    // order_items tidak punya created_at; urutkan dari tanggal order-nya.
    .order('created_at', { referencedTable: 'orders', ascending: false })
    .order('item_code', { ascending: true })
    .range(from, from + query.limit - 1);

  if (error) throw failed('memuat sepatu', error.message);

  return {
    items: ((data ?? []) as unknown as Array<Record<string, unknown>>).map((row) => {
      const order = row['order'] as Record<string, unknown> | null;
      const service = row['service'] as { name?: string } | null;
      return {
        id: row['id'] as string,
        order_id: row['order_id'] as string,
        order_number: String(order?.['order_number'] ?? ''),
        order_status: String(order?.['status'] ?? ''),
        service_name: service?.name ?? null,
        shoe_brand: (row['shoe_brand'] as string | null) ?? null,
        quantity: toNumber(row['quantity'], 1),
        item_code: String(row['item_code'] ?? ''),
        notes: (row['notes'] as string | null) ?? null,
        order_date: String(order?.['completed_at'] ?? order?.['created_at'] ?? ''),
      };
    }),
    page: query.page,
    limit: query.limit,
    total: count ?? 0,
  };
}

/** Rating yang pernah diberikan customer, terbaru dulu. */
export async function listMyRatings(
  env: Bindings,
  userId: string,
  query: HistoryQuery,
): Promise<{
  items: CustomerRatingView[];
  page: number;
  limit: number;
  total: number;
  average: number | null;
}> {
  const customerId = await customerProfileIdOf(env, userId);
  if (!customerId) {
    return { items: [], page: query.page, limit: query.limit, total: 0, average: null };
  }

  const admin = getSupabaseAdmin(env);
  const from = (query.page - 1) * query.limit;

  const [{ data, error, count }, { data: allRows, error: allError }] = await Promise.all([
    admin
      .from('ratings')
      .select(RATING_SELECT, { count: 'exact' })
      .eq('customer_id', customerId)
      .order('created_at', { ascending: false })
      .range(from, from + query.limit - 1),
    admin.from('ratings').select('rating_value').eq('customer_id', customerId),
  ]);

  if (error) throw failed('memuat rating', error.message);
  if (allError) throw failed('menghitung rating', allError.message);

  const values = ((allRows ?? []) as Array<{ rating_value: number }>).map((row) =>
    toNumber(row.rating_value),
  );
  const average =
    values.length === 0 ? null : values.reduce((sum, value) => sum + value, 0) / values.length;

  return {
    items: ((data ?? []) as unknown as Array<Record<string, unknown>>).map((row) => {
      const order = row['order'] as Record<string, unknown> | null;
      const worker = row['worker'] as { users?: { full_name?: string | null } } | null;
      return {
        id: row['id'] as string,
        order_id: row['order_id'] as string,
        order_number: order ? String(order['order_number'] ?? '') : null,
        worker_name: worker?.users?.full_name ?? null,
        rating_value: toNumber(row['rating_value']),
        comment: (row['comment'] as string | null) ?? null,
        photo_key: (row['photo_url'] as string | null) ?? null,
        is_featured: row['is_featured'] === true,
        created_at: String(row['created_at'] ?? ''),
      };
    }),
    page: query.page,
    limit: query.limit,
    total: count ?? 0,
    average,
  };
}
