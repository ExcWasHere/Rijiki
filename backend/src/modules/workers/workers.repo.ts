import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';

export interface AssignableWorkerView {
  /** worker_profiles.id (dipakai di PATCH /api/orders/:id/assign). */
  id: string;
  full_name: string;
  employee_code: string;
  division: string;
  avatar_url: string | null;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function one(value: any): any {
  if (Array.isArray(value)) return value[0] ?? null;
  return value ?? null;
}

export async function listActiveWorkers(env: Bindings): Promise<AssignableWorkerView[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('worker_profiles')
    .select('id, employee_code, division, users(full_name, avatar_url, is_active)')
    .eq('status', 'active');

  if (error) {
    console.error('workers: gagal memuat daftar worker', error.message);
    throw new AppError(500, 'workers_load_failed', 'Gagal memuat daftar worker');
  }

  return (data ?? [])
    .map((row) => ({ row, user: one(row.users) }))
    .filter(({ user }) => user && user.is_active !== false)
    .map(({ row, user }) => ({
      id: row.id as string,
      full_name: (user.full_name as string | null) ?? '-',
      employee_code: row.employee_code as string,
      division: row.division as string,
      avatar_url: (user.avatar_url as string | null) ?? null,
    }))
    .sort((a, b) => a.full_name.localeCompare(b.full_name, 'id'));
}
