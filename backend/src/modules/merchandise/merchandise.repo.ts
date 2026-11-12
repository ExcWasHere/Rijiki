import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { toNumber, toNumberOrNull } from '../../shared/utils/number';
import type { MerchandiseRow, MerchandiseView, MerchandiseWrite } from './merchandise.types';

const MERCHANDISE_SELECT =
  'id, name, description, price, points_cost, stock_quantity, image_url, is_active, created_at, updated_at';

function failed(label: string, message: string): AppError {
  console.error(`merchandise: gagal ${label}`, message);
  return new AppError(500, 'merchandise_failed', `Gagal ${label}. Coba lagi ya.`);
}

export function mapMerchandise(row: MerchandiseRow): MerchandiseView {
  return {
    id: row.id as string,
    name: row.name as string,
    description: (row.description as string | null) ?? null,
    price: toNumber(row.price),
    points_cost: toNumberOrNull(row.points_cost),
    stock_quantity: toNumberOrNull(row.stock_quantity),
    image_url: (row.image_url as string | null) ?? null,
    is_active: Boolean(row.is_active),
    created_at: row.created_at as string,
    updated_at: row.updated_at as string,
  };
}

export async function listMerchandiseRows(env: Bindings): Promise<MerchandiseView[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('merchandise')
    .select(MERCHANDISE_SELECT)
    .order('created_at', { ascending: false })
    .limit(500);
  if (error) throw failed('memuat daftar merchandise', error.message);
  return ((data ?? []) as unknown as MerchandiseRow[]).map(mapMerchandise);
}

export async function getMerchandiseRow(
  env: Bindings,
  id: string,
): Promise<MerchandiseRow | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('merchandise')
    .select(MERCHANDISE_SELECT)
    .eq('id', id)
    .maybeSingle();
  if (error) throw failed('memuat merchandise', error.message);
  return (data as unknown as MerchandiseRow | null) ?? null;
}

export async function insertMerchandiseRow(
  env: Bindings,
  write: MerchandiseWrite,
): Promise<MerchandiseView> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('merchandise')
    .insert(write)
    .select(MERCHANDISE_SELECT)
    .single();
  if (error || !data) throw failed('menyimpan merchandise', error?.message ?? 'tidak ada data');
  return mapMerchandise(data as unknown as MerchandiseRow);
}

export async function updateMerchandiseRow(
  env: Bindings,
  id: string,
  patch: Record<string, unknown>,
): Promise<MerchandiseView> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('merchandise')
    .update(patch)
    .eq('id', id)
    .select(MERCHANDISE_SELECT)
    .single();
  if (error || !data) {
    throw failed('menyimpan perubahan merchandise', error?.message ?? 'tidak ada data');
  }
  return mapMerchandise(data as unknown as MerchandiseRow);
}
