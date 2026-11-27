import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { toNumber } from '../../shared/utils/number';
import type { ServiceView, ServiceWrite } from './services.types';

const SERVICE_COLUMNS =
  'id, name, description, category, base_price, estimated_duration_minutes, is_active';

function failed(label: string, message: string): AppError {
  console.error(`services: gagal ${label}`, message);
  return new AppError(500, 'services_failed', `Gagal ${label}. Coba lagi ya.`);
}

function toView(row: Record<string, unknown>): ServiceView {
  return {
    id: row['id'] as string,
    name: row['name'] as string,
    description: (row['description'] as string | null) ?? null,
    category: (row['category'] as string | null) ?? null,
    base_price: toNumber(row['base_price']),
    estimated_duration_minutes:
      row['estimated_duration_minutes'] === null || row['estimated_duration_minutes'] === undefined
        ? null
        : toNumber(row['estimated_duration_minutes']),
    is_active: Boolean(row['is_active']),
  };
}

export async function listActiveServices(env: Bindings): Promise<ServiceView[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('services')
    .select(SERVICE_COLUMNS)
    .eq('is_active', true)
    .order('category', { ascending: true })
    .order('base_price', { ascending: true })
    .order('name', { ascending: true });

  if (error) throw failed('memuat daftar layanan', error.message);
  return ((data ?? []) as Array<Record<string, unknown>>).map(toView);
}

/** Semua layanan, termasuk yang nonaktif, untuk halaman CMS. */
export async function listAllServices(env: Bindings): Promise<ServiceView[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('services')
    .select(SERVICE_COLUMNS)
    .order('category', { ascending: true })
    .order('name', { ascending: true })
    .limit(500);

  if (error) throw failed('memuat daftar layanan', error.message);
  return ((data ?? []) as Array<Record<string, unknown>>).map(toView);
}

export async function findServiceById(env: Bindings, id: string): Promise<ServiceView | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('services')
    .select(SERVICE_COLUMNS)
    .eq('id', id)
    .maybeSingle();

  if (error) throw failed('memuat layanan', error.message);
  return data ? toView(data as Record<string, unknown>) : null;
}

/**
 * Nama layanan harus unik tanpa peduli huruf besar/kecil. Tabel `services`
 * tidak punya constraint unik, jadi pemeriksaan dilakukan di sini; [excludeId]
 * dipakai saat mengubah layanan yang sama.
 */
export async function findServiceByName(
  env: Bindings,
  name: string,
  excludeId?: string,
): Promise<ServiceView | null> {
  const admin = getSupabaseAdmin(env);
  let builder = admin
    .from('services')
    .select(SERVICE_COLUMNS)
    .ilike('name', name.trim())
    .limit(1);

  if (excludeId) builder = builder.neq('id', excludeId);

  const { data, error } = await builder.maybeSingle();
  if (error) throw failed('memeriksa nama layanan', error.message);
  return data ? toView(data as Record<string, unknown>) : null;
}

export async function insertServiceRow(
  env: Bindings,
  write: ServiceWrite,
): Promise<ServiceView> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('services')
    .insert({ ...write, updated_at: new Date().toISOString() })
    .select(SERVICE_COLUMNS)
    .single();

  if (error) throw failed('menyimpan layanan', error.message);
  return toView(data as Record<string, unknown>);
}

export async function updateServiceRow(
  env: Bindings,
  id: string,
  patch: Record<string, unknown>,
): Promise<ServiceView> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('services')
    .update(patch)
    .eq('id', id)
    .select(SERVICE_COLUMNS)
    .single();

  if (error) throw failed('menyimpan layanan', error.message);
  return toView(data as Record<string, unknown>);
}
