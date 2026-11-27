import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import { requirePermission } from '../../middleware/permission';
import type { AppEnv } from '../../shared/types/env';
import {
  createEventHandler,
  listCustomerEventsHandler,
  listManagedEventsHandler,
  listPromoOptionsHandler,
  updateEventHandler,
} from './events.controller';

/** Customer: event/promo/kolaborasi yang sedang tayang. Dipasang di /api/events. */
export const eventsRoutes = new Hono<AppEnv>();
eventsRoutes.use('*', authMiddleware);
eventsRoutes.get('/', listCustomerEventsHandler);

/**
 * Owner / worker berizin manage_cms_events. Dipasang di /api/management/events.
 * Event tidak dihapus: sembunyikan lewat PATCH is_published.
 */
export const managementEventsRoutes = new Hono<AppEnv>();
managementEventsRoutes.use('*', authMiddleware);
managementEventsRoutes.use('*', requirePermission('manage_cms_events'));
managementEventsRoutes.get('/', listManagedEventsHandler);
managementEventsRoutes.get('/promo-options', listPromoOptionsHandler);
managementEventsRoutes.post('/', createEventHandler);
managementEventsRoutes.patch('/:id', updateEventHandler);
