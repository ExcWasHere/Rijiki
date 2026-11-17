import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { sendPush } from './fcm.client';
import {
  countUnreadRows,
  deleteDeviceTokenRow,
  findUserIdByCustomerProfile,
  findUserIdByWorkerProfile,
  insertNotificationRow,
  listDeviceTokensForUser,
  listNotificationRows,
  markAllReadRows,
  markReadRow,
  registerDeviceTokenRow,
} from './notifications.repo';
import type { ListNotificationsQuery } from './notifications.schema';
import type { NotificationListPage } from './notifications.types';

export interface NotifyInput {
  userId: string | null | undefined;
  type: string;
  title: string;
  body: string;
  data?: Record<string, unknown> | null;
}

/**
 * Menyimpan notifikasi ke inbox lalu mengirim push FCM. Notifikasi bersifat
 * pelengkap (PRD 29.12): kegagalan di sini tidak boleh menggagalkan aksi utama,
 * jadi galatnya hanya dicatat.
 */
export async function notifyUser(env: Bindings, input: NotifyInput): Promise<void> {
  if (!input.userId) return;

  try {
    await insertNotificationRow(env, {
      userId: input.userId,
      type: input.type,
      title: input.title,
      body: input.body,
      data: input.data ?? null,
    });
  } catch (err) {
    console.error('notifications: gagal menyimpan inbox', err instanceof Error ? err.message : err);
    return;
  }

  try {
    const tokens = await listDeviceTokensForUser(env, input.userId);
    if (tokens.length === 0) return;

    const stale = await sendPush(env, tokens, {
      title: input.title,
      body: input.body,
      data: input.data
        ? Object.fromEntries(
            Object.entries(input.data)
              .filter(([, value]) => value !== null && value !== undefined)
              .map(([key, value]) => [key, String(value)]),
          )
        : undefined,
    });

    // Dihapus dengan await: promise yang menggantung dibatalkan Worker setelah
    // respons terkirim.
    await Promise.all(
      stale.map((token) =>
        deleteDeviceTokenRow(env, token).catch((err) =>
          console.error('notifications: gagal menghapus token basi', err),
        ),
      ),
    );
  } catch (err) {
    console.error('notifications: push gagal', err instanceof Error ? err.message : err);
  }
}

export async function listNotifications(
  env: Bindings,
  userId: string,
  query: ListNotificationsQuery,
): Promise<NotificationListPage> {
  const { items, total, unread } = await listNotificationRows(env, userId, query);
  return { items, page: query.page, limit: query.limit, total, unread };
}

export async function unreadNotificationCount(
  env: Bindings,
  userId: string,
): Promise<{ unread: number }> {
  return { unread: await countUnreadRows(env, userId) };
}

export async function readNotification(
  env: Bindings,
  userId: string,
  notificationId: string,
): Promise<{ unread: number }> {
  const found = await markReadRow(env, userId, notificationId);
  if (!found) throw new AppError(404, 'not_found', 'Notifikasi tidak ditemukan');
  return { unread: await countUnreadRows(env, userId) };
}

export async function readAllNotifications(
  env: Bindings,
  userId: string,
): Promise<{ updated: number; unread: number }> {
  const updated = await markAllReadRows(env, userId);
  return { updated, unread: 0 };
}

export async function registerDeviceToken(
  env: Bindings,
  userId: string,
  token: string,
  platform: 'android' | 'ios',
): Promise<void> {
  await registerDeviceTokenRow(env, userId, token, platform);
}

export async function unregisterDeviceToken(
  env: Bindings,
  userId: string,
  token: string,
): Promise<void> {
  await deleteDeviceTokenRow(env, token, userId);
}

/** Dipakai juga oleh modul lain (mis. log keluar) untuk membersihkan token. */
export async function removeDevicesOfUser(env: Bindings, userId: string): Promise<void> {
  const admin = getSupabaseAdmin(env);
  const { error } = await admin.from('device_tokens').delete().eq('user_id', userId);
  if (error) console.error('notifications: gagal menghapus token pengguna', error.message);
}

// ---------------------------------------------------------------------------
// Pembantu peristiwa: penerima ditentukan dari id profil, bukan users.id.
// ---------------------------------------------------------------------------

/** Notifikasi untuk customer pemilik order. */
export async function notifyCustomerProfile(
  env: Bindings,
  customerProfileId: string | null,
  input: Omit<NotifyInput, 'userId'>,
): Promise<void> {
  const userId = await findUserIdByCustomerProfile(env, customerProfileId);
  await notifyUser(env, { ...input, userId });
}

/** Notifikasi untuk worker pemilik profil. */
export async function notifyWorkerProfile(
  env: Bindings,
  workerProfileId: string | null,
  input: Omit<NotifyInput, 'userId'>,
): Promise<void> {
  const userId = await findUserIdByWorkerProfile(env, workerProfileId);
  await notifyUser(env, { ...input, userId });
}
