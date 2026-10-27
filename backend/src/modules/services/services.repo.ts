import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { toNumber } from '../../shared/utils/number';
import type { ServiceView } from './services.types';

const SERVICE_COLUMNS =
  'id, name, description, category, base_price, estimated_duration_minutes, is_active';

export async function listActiveServices(env: Bindings): Promise<ServiceView[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('services')
    .select(SERVICE_COLUMNS)
    .eq('is_active', true)
    .order('category', { ascending: true })
    .order('base_price', { ascending: true })
    .order('name', { ascending: true });

  if (error) {
    console.error('services: gagal memuat daftar layanan', error.message);
    throw new AppError(500, 'services_load_failed', 'Gagal memuat daftar layanan');
  }

  return (data ?? []).map((row) => ({
    id: row.id as string,
    name: row.name as string,
    description: (row.description as string | null) ?? null,
    category: (row.category as string | null) ?? null,
    base_price: toNumber(row.base_price),
    estimated_duration_minutes:
      row.estimated_duration_minutes === null || row.estimated_duration_minutes === undefined
        ? null
        : toNumber(row.estimated_duration_minutes),
    is_active: Boolean(row.is_active),
  }));
}
