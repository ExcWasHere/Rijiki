import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import type { AppEnv } from '../../shared/types/env';
import {
  listNotificationsHandler,
  readAllNotificationsHandler,
  readNotificationHandler,
  registerDeviceHandler,
  unreadCountHandler,
  unregisterDeviceHandler,
} from './notifications.controller';

/** Inbox notifikasi semua role. Dipasang di /api/notifications. */
export const notificationsRoutes = new Hono<AppEnv>();
notificationsRoutes.use('*', authMiddleware);
notificationsRoutes.get('/', listNotificationsHandler);
notificationsRoutes.get('/unread-count', unreadCountHandler);
notificationsRoutes.post('/read-all', readAllNotificationsHandler);
notificationsRoutes.post('/:id/read', readNotificationHandler);

/** Registrasi token FCM. Dipasang di /api/devices (PRD 29.12). */
export const devicesRoutes = new Hono<AppEnv>();
devicesRoutes.use('*', authMiddleware);
devicesRoutes.post('/', registerDeviceHandler);
devicesRoutes.delete('/', unregisterDeviceHandler);
