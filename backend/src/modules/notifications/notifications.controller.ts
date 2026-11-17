import type { Context } from 'hono';
import type { AppEnv } from '../../shared/types/env';
import { parseInput } from '../../shared/utils/validate';
import {
  deleteDeviceTokenSchema,
  deviceTokenSchema,
  listNotificationsQuerySchema,
} from './notifications.schema';
import {
  listNotifications,
  readAllNotifications,
  readNotification,
  registerDeviceToken,
  unreadNotificationCount,
  unregisterDeviceToken,
} from './notifications.service';

function currentUserId(c: Context<AppEnv>): string {
  return c.get('user').user.id;
}

export async function listNotificationsHandler(c: Context<AppEnv>) {
  const query = parseInput(listNotificationsQuerySchema, c.req.query());
  c.header('Cache-Control', 'no-store');
  return c.json(await listNotifications(c.env, currentUserId(c), query));
}

export async function unreadCountHandler(c: Context<AppEnv>) {
  c.header('Cache-Control', 'no-store');
  return c.json(await unreadNotificationCount(c.env, currentUserId(c)));
}

export async function readNotificationHandler(c: Context<AppEnv>) {
  return c.json(
    await readNotification(c.env, currentUserId(c), c.req.param('id') ?? ''),
  );
}

export async function readAllNotificationsHandler(c: Context<AppEnv>) {
  return c.json(await readAllNotifications(c.env, currentUserId(c)));
}

export async function registerDeviceHandler(c: Context<AppEnv>) {
  const input = parseInput(deviceTokenSchema, await c.req.json().catch(() => null));
  await registerDeviceToken(c.env, currentUserId(c), input.token, input.platform);
  return c.json({ message: 'Perangkat terdaftar' });
}

export async function unregisterDeviceHandler(c: Context<AppEnv>) {
  const input = parseInput(deleteDeviceTokenSchema, await c.req.json().catch(() => null));
  await unregisterDeviceToken(c.env, currentUserId(c), input.token);
  return c.json({ message: 'Perangkat dihapus' });
}
