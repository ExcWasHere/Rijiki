import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import type { ListNotificationsQuery } from './notifications.schema';
import type { NotificationRow, NotificationView } from './notifications.types';

const NOTIFICATION_COLUMNS = 'id, type, title, body, data, read_at, created_at';

function failed(label: string, message: string): AppError {
  console.error(`notifications: gagal ${label}`, message);
  return new AppError(500, 'notifications_failed', `Gagal ${label}. Coba lagi ya.`);
}

function toView(row: NotificationRow): NotificationView {
  return {
    id: row.id,
    type: row.type,
    title: row.title,
    body: row.body,
    data: row.data ?? null,
    read: row.read_at !== null,
    created_at: row.created_at,
  };
}

export async function insertNotificationRow(
  env: Bindings,
  row: {
    userId: string;
    type: string;
    title: string;
    body: string;
    data?: Record<string, unknown> | null;
  },
): Promise<string | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('notifications')
    .insert({
      user_id: row.userId,
      type: row.type,
      title: row.title,
      body: row.body,
      data: row.data ?? null,
    })
    .select('id')
    .maybeSingle();

  if (error) throw failed('menyimpan notifikasi', error.message);
  return (data?.id as string | undefined) ?? null;
}

export async function listNotificationRows(
  env: Bindings,
  userId: string,
  query: ListNotificationsQuery,
): Promise<{ items: NotificationView[]; total: number; unread: number }> {
  const admin = getSupabaseAdmin(env);
  const from = (query.page - 1) * query.limit;

  const [{ data, error, count }, { count: unread, error: unreadError }] = await Promise.all([
    admin
      .from('notifications')
      .select(NOTIFICATION_COLUMNS, { count: 'exact' })
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .range(from, from + query.limit - 1),
    admin
      .from('notifications')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', userId)
      .is('read_at', null),
  ]);

  if (error) throw failed('memuat notifikasi', error.message);
  if (unreadError) throw failed('menghitung notifikasi', unreadError.message);

  return {
    items: ((data ?? []) as NotificationRow[]).map(toView),
    total: count ?? 0,
    unread: unread ?? 0,
  };
}

export async function countUnreadRows(env: Bindings, userId: string): Promise<number> {
  const admin = getSupabaseAdmin(env);
  const { count, error } = await admin
    .from('notifications')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .is('read_at', null);

  if (error) throw failed('menghitung notifikasi', error.message);
  return count ?? 0;
}

/** Menandai satu notifikasi milik [userId] sebagai dibaca. false = bukan miliknya. */
export async function markReadRow(
  env: Bindings,
  userId: string,
  notificationId: string,
): Promise<boolean> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('notifications')
    .update({ read_at: new Date().toISOString() })
    .eq('id', notificationId)
    .eq('user_id', userId)
    .is('read_at', null)
    .select('id');

  if (error) throw failed('menandai notifikasi', error.message);

  // Sudah dibaca sebelumnya juga dianggap berhasil; pastikan barisnya memang ada.
  if ((data ?? []).length > 0) return true;
  const { data: existing, error: existingError } = await admin
    .from('notifications')
    .select('id')
    .eq('id', notificationId)
    .eq('user_id', userId)
    .maybeSingle();
  if (existingError) throw failed('memeriksa notifikasi', existingError.message);
  return existing !== null;
}

export async function markAllReadRows(env: Bindings, userId: string): Promise<number> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('notifications')
    .update({ read_at: new Date().toISOString() })
    .eq('user_id', userId)
    .is('read_at', null)
    .select('id');

  if (error) throw failed('menandai semua notifikasi', error.message);
  return (data ?? []).length;
}

// ---------------------------------------------------------------------------
// Token perangkat FCM
// ---------------------------------------------------------------------------

export async function registerDeviceTokenRow(
  env: Bindings,
  userId: string,
  token: string,
  platform: 'android' | 'ios',
): Promise<void> {
  const admin = getSupabaseAdmin(env);
  // Token unik lintas pengguna: perangkat yang berganti akun ikut pindah tangan.
  const { error } = await admin.from('device_tokens').upsert(
    {
      user_id: userId,
      token,
      platform,
      updated_at: new Date().toISOString(),
    },
    { onConflict: 'token' },
  );

  if (error) throw failed('mendaftarkan perangkat', error.message);
}

export async function deleteDeviceTokenRow(
  env: Bindings,
  token: string,
  userId?: string,
): Promise<void> {
  const admin = getSupabaseAdmin(env);
  let query = admin.from('device_tokens').delete().eq('token', token);
  if (userId) query = query.eq('user_id', userId);

  const { error } = await query;
  if (error) throw failed('menghapus perangkat', error.message);
}

export async function listDeviceTokensForUser(
  env: Bindings,
  userId: string,
): Promise<string[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('device_tokens')
    .select('token')
    .eq('user_id', userId);

  if (error) throw failed('memuat perangkat', error.message);
  return ((data ?? []) as Array<{ token: string }>).map((row) => row.token);
}

// ---------------------------------------------------------------------------
// Pemetaan pemilik order -> users.id (untuk penerima notifikasi)
// ---------------------------------------------------------------------------

export async function findUserIdByCustomerProfile(
  env: Bindings,
  customerProfileId: string | null,
): Promise<string | null> {
  if (!customerProfileId) return null;
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('customer_profiles')
    .select('user_id')
    .eq('id', customerProfileId)
    .maybeSingle();

  if (error) {
    console.error('notifications: gagal memuat customer_profiles', error.message);
    return null;
  }
  return (data?.user_id as string | undefined) ?? null;
}

export async function findUserIdByWorkerProfile(
  env: Bindings,
  workerProfileId: string | null,
): Promise<string | null> {
  if (!workerProfileId) return null;
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('worker_profiles')
    .select('user_id')
    .eq('id', workerProfileId)
    .maybeSingle();

  if (error) {
    console.error('notifications: gagal memuat worker_profiles', error.message);
    return null;
  }
  return (data?.user_id as string | undefined) ?? null;
}

export async function listActiveOwnerUserIds(env: Bindings): Promise<string[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('users')
    .select('id')
    .eq('role', 'owner')
    .eq('is_active', true);

  if (error) {
    console.error('notifications: gagal memuat owner', error.message);
    return [];
  }
  return ((data ?? []) as Array<{ id: string }>).map((row) => row.id);
}
