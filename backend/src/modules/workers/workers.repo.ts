import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import type { AppPermission } from '../../shared/types/user';
import { toNumber, toNumberOrNull } from '../../shared/utils/number';

export interface AssignableWorkerView {
  /** worker_profiles.id (dipakai di PATCH /api/orders/:id/assign). */
  id: string;
  full_name: string;
  employee_code: string;
  division: string;
  avatar_url: string | null;
}

export interface ManagedWorkerView {
  /** worker_profiles.id. */
  id: string;
  user_id: string;
  full_name: string;
  email: string;
  phone_number: string;
  employee_code: string;
  division: string;
  join_date: string;
  avatar_url: string | null;
  is_active: boolean;
  avg_rating: number | null;
  rating_count: number;
}

const UNIQUE_VIOLATION = '23505';

const MANAGED_SELECT =
  'id, user_id, employee_code, division, join_date, status, users(full_name, email, phone_number, avatar_url, is_active)';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function one(value: any): any {
  if (Array.isArray(value)) return value[0] ?? null;
  return value ?? null;
}

function failed(label: string, message: string): AppError {
  console.error(`workers: gagal ${label}`, message);
  return new AppError(500, 'workers_failed', `Gagal ${label}. Coba lagi ya.`);
}

// ---------------------------------------------------------------------------
// Daftar untuk assign order (tidak berubah)
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Manajemen worker
// ---------------------------------------------------------------------------

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function mapManaged(row: any, stats: Map<string, { avg: number | null; count: number }>): ManagedWorkerView {
  const user = one(row.users);
  const stat = stats.get(row.id as string);
  return {
    id: row.id as string,
    user_id: row.user_id as string,
    full_name: (user?.full_name as string | null) ?? '-',
    email: (user?.email as string | null) ?? '',
    phone_number: (user?.phone_number as string | null) ?? '',
    employee_code: row.employee_code as string,
    division: row.division as string,
    join_date: row.join_date as string,
    avatar_url: (user?.avatar_url as string | null) ?? null,
    is_active: user?.is_active !== false,
    avg_rating: stat?.avg ?? null,
    rating_count: stat?.count ?? 0,
  };
}

async function ratingStats(env: Bindings): Promise<Map<string, { avg: number | null; count: number }>> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin.rpc('worker_rating_stats');
  if (error) throw failed('memuat rating worker', error.message);

  const result = new Map<string, { avg: number | null; count: number }>();
  for (const row of (data ?? []) as Array<{
    worker_id: string;
    avg_rating: number | string | null;
    rating_count: number | string;
  }>) {
    result.set(row.worker_id, {
      avg: toNumberOrNull(row.avg_rating),
      count: toNumber(row.rating_count),
    });
  }
  return result;
}

export async function listManagedWorkers(env: Bindings): Promise<ManagedWorkerView[]> {
  const admin = getSupabaseAdmin(env);
  const [{ data, error }, stats] = await Promise.all([
    admin.from('worker_profiles').select(MANAGED_SELECT).order('employee_code', { ascending: true }),
    ratingStats(env),
  ]);
  if (error) throw failed('memuat daftar karyawan', error.message);
  return (data ?? []).map((row) => mapManaged(row, stats));
}

export async function getManagedWorker(
  env: Bindings,
  workerId: string,
): Promise<ManagedWorkerView | null> {
  const admin = getSupabaseAdmin(env);
  const [{ data, error }, stats] = await Promise.all([
    admin.from('worker_profiles').select(MANAGED_SELECT).eq('id', workerId).maybeSingle(),
    ratingStats(env),
  ]);
  if (error) throw failed('memuat karyawan', error.message);
  return data ? mapManaged(data, stats) : null;
}

export async function employeeCodeOwner(env: Bindings, code: string): Promise<string | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('worker_profiles')
    .select('id, employee_code')
    .ilike('employee_code', code)
    .limit(5);
  if (error) throw failed('memeriksa kode pegawai', error.message);
  const hit = (data ?? []).find(
    (r) => String(r.employee_code).toUpperCase() === code.toUpperCase(),
  );
  return hit ? (hit.id as string) : null;
}

export interface CreateAccountParams {
  email: string;
  password: string;
  fullName: string;
  phoneNumber: string;
  employeeCode: string;
  division: string;
  joinDate: string;
}

export type CreateAccountResult =
  | { ok: true; workerId: string }
  | { ok: false; reason: 'email_taken' | 'weak_password' | 'employee_code_taken' };

/**
 * Akun worker dibuat lewat Supabase admin API dengan email langsung terverifikasi
 * dan app_metadata.role = 'worker' (PRD 5/29); trigger handle_new_user membuat
 * baris users. Tanpa transaksi lintas Auth dan database, jadi bila langkah
 * berikutnya gagal, yang sudah dibuat dibatalkan.
 */
export async function createWorkerAccount(
  env: Bindings,
  params: CreateAccountParams,
): Promise<CreateAccountResult> {
  const admin = getSupabaseAdmin(env);

  const created = await admin.auth.admin.createUser({
    email: params.email,
    password: params.password,
    email_confirm: true,
    app_metadata: { role: 'worker' },
    user_metadata: { full_name: params.fullName },
  });

  if (created.error || !created.data.user) {
    const message = created.error?.message ?? '';
    const code = (created.error as { code?: string } | null)?.code ?? '';
    if (code === 'email_exists' || /already|registered|exists/i.test(message)) {
      return { ok: false, reason: 'email_taken' };
    }
    if (code === 'weak_password' || /password/i.test(message)) {
      return { ok: false, reason: 'weak_password' };
    }
    throw failed('membuat akun worker', message);
  }
  const userId = created.data.user.id;

  const rollback = async (): Promise<void> => {
    await admin.from('worker_profiles').delete().eq('user_id', userId);
    await admin.from('users').delete().eq('id', userId);
    const { error } = await admin.auth.admin.deleteUser(userId);
    if (error) console.error('workers: gagal membatalkan akun auth', userId, error.message);
  };

  // upsert: trigger biasanya sudah membuat baris ini; bila belum, dibuat di sini.
  const profile = await admin.from('users').upsert(
    {
      id: userId,
      email: params.email,
      role: 'worker',
      full_name: params.fullName,
      phone_number: params.phoneNumber,
      profile_completed: true,
      is_active: true,
    },
    { onConflict: 'id' },
  );
  if (profile.error) {
    await rollback();
    throw failed('menyimpan data worker', profile.error.message);
  }

  const inserted = await admin
    .from('worker_profiles')
    .insert({
      user_id: userId,
      employee_code: params.employeeCode,
      division: params.division,
      join_date: params.joinDate,
      status: 'active',
    })
    .select('id')
    .single();
  if (inserted.error || !inserted.data) {
    await rollback();
    if (inserted.error?.code === UNIQUE_VIOLATION) {
      return { ok: false, reason: 'employee_code_taken' };
    }
    throw failed('menyimpan profil worker', inserted.error?.message ?? 'tidak ada data');
  }
  return { ok: true, workerId: inserted.data.id as string };
}

export async function getWorkerUserId(env: Bindings, workerId: string): Promise<string | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('worker_profiles')
    .select('user_id')
    .eq('id', workerId)
    .maybeSingle();
  if (error) throw failed('memuat worker', error.message);
  return (data?.user_id as string | undefined) ?? null;
}

export async function updateWorkerProfileRow(
  env: Bindings,
  workerId: string,
  patch: Record<string, unknown>,
): Promise<'ok' | 'employee_code_taken'> {
  const admin = getSupabaseAdmin(env);
  const { error } = await admin
    .from('worker_profiles')
    .update({ ...patch, updated_at: new Date().toISOString() })
    .eq('id', workerId);
  if (error) {
    if (error.code === UNIQUE_VIOLATION) return 'employee_code_taken';
    throw failed('menyimpan data karyawan', error.message);
  }
  return 'ok';
}

export async function updateUserRow(
  env: Bindings,
  userId: string,
  patch: Record<string, unknown>,
): Promise<void> {
  const admin = getSupabaseAdmin(env);
  const { error } = await admin
    .from('users')
    .update({ ...patch, updated_at: new Date().toISOString() })
    .eq('id', userId);
  if (error) throw failed('menyimpan data akun', error.message);
}

export async function updateAuthUser(
  env: Bindings,
  userId: string,
  attributes: { email?: string; password?: string },
): Promise<'ok' | 'email_taken' | 'weak_password'> {
  const admin = getSupabaseAdmin(env);
  const { error } = await admin.auth.admin.updateUserById(userId, {
    ...attributes,
    ...(attributes.email ? { email_confirm: true } : {}),
  });
  if (!error) return 'ok';

  const code = (error as { code?: string }).code ?? '';
  if (code === 'email_exists' || /already|registered|exists/i.test(error.message)) {
    return 'email_taken';
  }
  if (code === 'weak_password' || /password/i.test(error.message)) return 'weak_password';
  throw failed('mengubah akun login', error.message);
}

// ---------------------------------------------------------------------------
// Izin delegasi (hanya owner yang menulis)
// ---------------------------------------------------------------------------

export async function listActivePermissions(
  env: Bindings,
  workerId: string,
): Promise<AppPermission[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('worker_permissions')
    .select('permission')
    .eq('worker_id', workerId)
    .is('revoked_at', null);
  if (error) throw failed('memuat izin worker', error.message);
  return [...new Set((data ?? []).map((row) => row.permission as AppPermission))];
}

export async function grantPermissions(
  env: Bindings,
  workerId: string,
  permissions: AppPermission[],
  grantedBy: string,
): Promise<void> {
  if (permissions.length === 0) return;
  const admin = getSupabaseAdmin(env);
  const { error } = await admin.from('worker_permissions').insert(
    permissions.map((permission) => ({
      worker_id: workerId,
      permission,
      granted_by: grantedBy,
    })),
  );
  if (error) throw failed('memberi izin worker', error.message);
}

export async function revokePermissions(
  env: Bindings,
  workerId: string,
  permissions: AppPermission[],
): Promise<void> {
  if (permissions.length === 0) return;
  const admin = getSupabaseAdmin(env);
  const { error } = await admin
    .from('worker_permissions')
    .update({ revoked_at: new Date().toISOString() })
    .eq('worker_id', workerId)
    .in('permission', permissions)
    .is('revoked_at', null);
  if (error) throw failed('mencabut izin worker', error.message);
}

export interface PermissionGrantView {
  permission: AppPermission;
  granted_at: string;
  granted_by_name: string | null;
}

/** Izin aktif beserta waktu pemberian dan nama pemberinya (satu baris per izin). */
export async function listActiveGrants(
  env: Bindings,
  workerId: string,
): Promise<PermissionGrantView[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('worker_permissions')
    .select('permission, granted_at, granter:users!worker_permissions_granted_by_fkey(full_name)')
    .eq('worker_id', workerId)
    .is('revoked_at', null)
    .order('granted_at', { ascending: true });
  if (error) throw failed('memuat izin worker', error.message);

  const seen = new Set<string>();
  const result: PermissionGrantView[] = [];
  for (const row of data ?? []) {
    const permission = row.permission as AppPermission;
    if (seen.has(permission)) continue;
    seen.add(permission);
    result.push({
      permission,
      granted_at: row.granted_at as string,
      granted_by_name: (one(row.granter)?.full_name as string | null) ?? null,
    });
  }
  return result;
}
