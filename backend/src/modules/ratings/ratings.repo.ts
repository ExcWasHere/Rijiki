import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { toNumber } from '../../shared/utils/number';
import type { ListRatingsQuery } from './ratings.schema';
import type { RatingRow, RatingSummaryView } from './ratings.types';

const UNIQUE_VIOLATION = '23505';

const RATING_SELECT = [
  'id',
  'order_id',
  'rating_value',
  'comment',
  'photo_url',
  'is_featured',
  'created_at',
  'order:orders(order_number, order_items(services(name)))',
  'customer:customer_profiles(users(full_name))',
  'worker:worker_profiles(users(full_name))',
].join(', ');

const DOCUMENTATION_SELECT = [
  'id',
  'type',
  'image_url',
  'created_at',
  'order:orders(order_number)',
  'item:order_items(item_code, shoe_brand, services(name))',
].join(', ');

function failed(label: string, message: string): AppError {
  console.error(`ratings: gagal ${label}`, message);
  return new AppError(500, 'ratings_failed', `Gagal ${label}. Coba lagi ya.`);
}

/** Batas rentang tanggal dalam WIB (UTC+7) sebagai ISO string. */
export function rangeBounds(
  start?: string,
  end?: string,
): { from: string | null; to: string | null } {
  return {
    from: start ? new Date(`${start}T00:00:00+07:00`).toISOString() : null,
    to: end ? new Date(`${end}T23:59:59.999+07:00`).toISOString() : null,
  };
}

// ---------------------------------------------------------------------------
// Customer
// ---------------------------------------------------------------------------

export async function getOrderForRating(
  env: Bindings,
  orderId: string,
): Promise<{
  id: string;
  order_number: string;
  status: string;
  customer_id: string | null;
  assigned_worker_id: string | null;
} | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('orders')
    .select('id, order_number, status, customer_id, assigned_worker_id')
    .eq('id', orderId)
    .maybeSingle();
  if (error) throw failed('memuat order', error.message);
  return data
    ? {
        id: data.id as string,
        order_number: data.order_number as string,
        status: String(data.status),
        customer_id: (data.customer_id as string | null) ?? null,
        assigned_worker_id: (data.assigned_worker_id as string | null) ?? null,
      }
    : null;
}

export async function ratingExistsForOrder(env: Bindings, orderId: string): Promise<boolean> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('ratings')
    .select('id')
    .eq('order_id', orderId)
    .maybeSingle();
  if (error) throw failed('memeriksa rating', error.message);
  return data !== null;
}

export type InsertRatingResult =
  | { ok: true; id: string; created_at: string }
  | { ok: false; reason: 'duplicate' };

export async function insertRatingRow(
  env: Bindings,
  params: {
    orderId: string;
    customerId: string;
    workerId: string | null;
    ratingValue: number;
    comment: string | null;
    photoKey: string | null;
  },
): Promise<InsertRatingResult> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('ratings')
    .insert({
      order_id: params.orderId,
      customer_id: params.customerId,
      worker_id: params.workerId,
      rating_value: params.ratingValue,
      comment: params.comment,
      photo_url: params.photoKey,
    })
    .select('id, created_at')
    .single();

  if (error) {
    if (error.code === UNIQUE_VIOLATION) return { ok: false, reason: 'duplicate' };
    throw failed('menyimpan rating', error.message);
  }
  return {
    ok: true,
    id: (data as { id: string }).id,
    created_at: (data as { created_at: string }).created_at,
  };
}

export async function listFeaturedRows(env: Bindings, limit: number): Promise<RatingRow[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('ratings')
    .select(RATING_SELECT)
    .eq('is_featured', true)
    .order('created_at', { ascending: false })
    .limit(limit);
  if (error) throw failed('memuat testimoni', error.message);
  return (data ?? []) as unknown as RatingRow[];
}

// ---------------------------------------------------------------------------
// Staf
// ---------------------------------------------------------------------------

export async function listManagedRows(
  env: Bindings,
  query: ListRatingsQuery,
): Promise<{ rows: RatingRow[]; total: number }> {
  const admin = getSupabaseAdmin(env);
  const from = (query.page - 1) * query.limit;

  let builder = admin.from('ratings').select(RATING_SELECT, { count: 'exact' });
  if (query.featured) builder = builder.eq('is_featured', query.featured === 'true');
  if (query.has_photo === 'true') builder = builder.not('photo_url', 'is', null);
  if (query.has_photo === 'false') builder = builder.is('photo_url', null);

  const { from: gte, to: lte } = rangeBounds(query.start_date, query.end_date);
  if (gte) builder = builder.gte('created_at', gte);
  if (lte) builder = builder.lte('created_at', lte);

  const { data, error, count } = await builder
    .order('created_at', { ascending: false })
    .range(from, from + query.limit - 1);
  if (error) throw failed('memuat daftar rating', error.message);
  return { rows: (data ?? []) as unknown as RatingRow[], total: count ?? 0 };
}

export async function getRatingRow(env: Bindings, id: string): Promise<RatingRow | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('ratings')
    .select(RATING_SELECT)
    .eq('id', id)
    .maybeSingle();
  if (error) throw failed('memuat rating', error.message);
  return (data as unknown as RatingRow | null) ?? null;
}

export async function updateFeatured(env: Bindings, id: string, value: boolean): Promise<void> {
  const admin = getSupabaseAdmin(env);
  const { error } = await admin.from('ratings').update({ is_featured: value }).eq('id', id);
  if (error) throw failed('mengubah testimoni pilihan', error.message);
}

export async function getRatingsSummary(env: Bindings): Promise<RatingSummaryView> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin.rpc('ratings_summary');
  if (error) throw failed('memuat ringkasan rating', error.message);

  const row = (Array.isArray(data) ? data[0] : data) as
    | { total: number | string; average: number | string | null; featured: number | string }
    | undefined;
  return {
    total: toNumber(row?.total),
    average: row?.average === null || row?.average === undefined ? null : toNumber(row.average),
    featured: toNumber(row?.featured),
  };
}

// ---------------------------------------------------------------------------
// Rekap (export)
// ---------------------------------------------------------------------------

const EXPORT_ROW_CAP = 1000;

export async function listExportRatings(
  env: Bindings,
  start?: string,
  end?: string,
): Promise<RatingRow[]> {
  const admin = getSupabaseAdmin(env);
  let builder = admin.from('ratings').select(RATING_SELECT);
  const { from, to } = rangeBounds(start, end);
  if (from) builder = builder.gte('created_at', from);
  if (to) builder = builder.lte('created_at', to);

  const { data, error } = await builder
    .order('created_at', { ascending: true })
    .range(0, EXPORT_ROW_CAP - 1);
  if (error) throw failed('menyiapkan rekap testimoni', error.message);
  return (data ?? []) as unknown as RatingRow[];
}

export async function listExportDocumentations(
  env: Bindings,
  start?: string,
  end?: string,
): Promise<RatingRow[]> {
  const admin = getSupabaseAdmin(env);
  let builder = admin
    .from('order_documentations')
    .select(DOCUMENTATION_SELECT)
    .in('type', ['before', 'after']);
  const { from, to } = rangeBounds(start, end);
  if (from) builder = builder.gte('created_at', from);
  if (to) builder = builder.lte('created_at', to);

  const { data, error } = await builder
    .order('created_at', { ascending: true })
    .range(0, EXPORT_ROW_CAP - 1);
  if (error) throw failed('menyiapkan rekap foto before/after', error.message);
  return (data ?? []) as unknown as RatingRow[];
}
