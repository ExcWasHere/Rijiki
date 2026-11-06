import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { toNumber, toNumberOrNull } from '../../shared/utils/number';
import type { PromoDbRow, PromoView, PromoWrite } from './promos.types';

const PROMO_SELECT = [
  'id',
  'code',
  'title',
  'description',
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
  'created_at',
  'promo_services(service_id)',
].join(', ');

const UNIQUE_VIOLATION = '23505';

function failed(label: string, message: string): AppError {
  console.error(`promos: gagal ${label}`, message);
  return new AppError(500, 'promo_failed', `Gagal ${label}. Coba lagi ya.`);
}

export function mapPromo(row: PromoDbRow, usageCount: number): PromoView {
  const services: Array<{ service_id: string }> = Array.isArray(row.promo_services)
    ? row.promo_services
    : [];
  return {
    id: row.id as string,
    code: row.code as string,
    title: row.title as string,
    description: (row.description as string | null) ?? null,
    discount_type: row.discount_type,
    discount_value: toNumber(row.discount_value),
    start_date: row.start_date as string,
    end_date: row.end_date as string,
    is_active: Boolean(row.is_active),
    applies_to: (row.applies_to as 'subtotal' | 'shipping' | null) ?? 'subtotal',
    min_subtotal: toNumberOrNull(row.min_subtotal),
    max_discount_amount: toNumberOrNull(row.max_discount_amount),
    usage_limit: toNumberOrNull(row.usage_limit),
    usage_limit_per_customer: toNumberOrNull(row.usage_limit_per_customer),
    first_order_only: Boolean(row.first_order_only),
    service_ids: services.map((s) => s.service_id),
    usage_count: usageCount,
    created_at: row.created_at as string,
  };
}

async function usageCounts(env: Bindings, ids: string[]): Promise<Map<string, number>> {
  const result = new Map<string, number>();
  if (ids.length === 0) return result;

  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin.rpc('promo_usage_counts', { p_promo_ids: ids });
  if (error) throw failed('memuat riwayat pemakaian promo', error.message);

  for (const row of (data ?? []) as Array<{ promo_id: string; used: number | string }>) {
    result.set(row.promo_id, toNumber(row.used));
  }
  return result;
}

export async function listPromoViews(env: Bindings): Promise<PromoView[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('promos')
    .select(PROMO_SELECT)
    .order('created_at', { ascending: false });
  if (error) throw failed('memuat daftar promo', error.message);

  const rows = (data ?? []) as unknown as PromoDbRow[];
  const counts = await usageCounts(
    env,
    rows.map((r) => r.id as string),
  );
  return rows.map((row) => mapPromo(row, counts.get(row.id as string) ?? 0));
}

export async function getPromoRow(env: Bindings, id: string): Promise<PromoDbRow | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin.from('promos').select(PROMO_SELECT).eq('id', id).maybeSingle();
  if (error) throw failed('memuat promo', error.message);
  return (data as unknown as PromoDbRow | null) ?? null;
}

export async function getPromoView(env: Bindings, id: string): Promise<PromoView | null> {
  const row = await getPromoRow(env, id);
  if (!row) return null;
  const counts = await usageCounts(env, [id]);
  return mapPromo(row, counts.get(id) ?? 0);
}

export async function getPromoUsageCount(env: Bindings, id: string): Promise<number> {
  const counts = await usageCounts(env, [id]);
  return counts.get(id) ?? 0;
}

/** Promo lain yang kodenya sama (tanpa membedakan huruf besar/kecil). */
export async function findPromoIdByCode(env: Bindings, code: string): Promise<string | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin.from('promos').select('id, code').ilike('code', code).limit(5);
  if (error) throw failed('memeriksa kode promo', error.message);
  const hit = (data ?? []).find(
    (r) => String((r as { code: string }).code).toUpperCase() === code.toUpperCase(),
  );
  return hit ? ((hit as { id: string }).id) : null;
}

export async function findPromoByIdempotencyKey(
  env: Bindings,
  key: string,
): Promise<{ id: string; fingerprint: string | null } | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('promos')
    .select('id, idempotency_fingerprint')
    .eq('idempotency_key', key)
    .maybeSingle();
  if (error) throw failed('memeriksa promo', error.message);
  if (!data) return null;
  return {
    id: data.id as string,
    fingerprint: (data.idempotency_fingerprint as string | null) ?? null,
  };
}

export async function countExistingServices(env: Bindings, ids: string[]): Promise<number> {
  if (ids.length === 0) return 0;
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin.from('services').select('id').in('id', ids);
  if (error) throw failed('memeriksa layanan', error.message);
  return data?.length ?? 0;
}

export type InsertPromoResult = { ok: true; id: string } | { ok: false; reason: 'duplicate' };

export async function insertPromoRow(
  env: Bindings,
  write: PromoWrite,
  idempotency: { key: string | null; fingerprint: string | null },
): Promise<InsertPromoResult> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('promos')
    .insert({
      ...write,
      idempotency_key: idempotency.key,
      idempotency_fingerprint: idempotency.fingerprint,
    })
    .select('id')
    .single();

  if (error) {
    if (error.code === UNIQUE_VIOLATION) return { ok: false, reason: 'duplicate' };
    throw failed('menyimpan promo', error.message);
  }
  return { ok: true, id: (data as { id: string }).id };
}

export async function updatePromoRow(
  env: Bindings,
  id: string,
  patch: Record<string, unknown>,
): Promise<void> {
  const admin = getSupabaseAdmin(env);
  const { error } = await admin.from('promos').update(patch).eq('id', id);
  if (error) {
    if (error.code === UNIQUE_VIOLATION) {
      throw new AppError(409, 'promo_code_taken', 'Kode promo ini sudah dipakai promo lain.');
    }
    throw failed('menyimpan perubahan promo', error.message);
  }
}

export async function replacePromoServices(
  env: Bindings,
  promoId: string,
  serviceIds: string[],
): Promise<void> {
  const admin = getSupabaseAdmin(env);
  const { error } = await admin.rpc('save_promo_services', {
    p_promo_id: promoId,
    p_service_ids: serviceIds,
  });
  if (error) throw failed('menyimpan layanan promo', error.message);
}

/** Hanya untuk membatalkan promo yang baru dibuat bila langkah lanjutannya gagal. */
export async function deleteNewPromoRow(env: Bindings, id: string): Promise<void> {
  const admin = getSupabaseAdmin(env);
  const { error } = await admin.from('promos').delete().eq('id', id);
  if (error) console.error('promos: gagal membersihkan promo yang setengah jadi', error.message);
}
