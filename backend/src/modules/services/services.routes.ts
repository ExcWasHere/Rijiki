import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import { requirePermission } from '../../middleware/permission';
import type { AppEnv } from '../../shared/types/env';
import {
  createServiceHandler,
  listManagedServicesHandler,
  listServicesHandler,
  updateServiceHandler,
} from './services.controller';

/**
 * `GET /api/services` publik: katalog aktif untuk aplikasi customer.
 * Sisanya CMS (PRD 29.7) dan butuh izin `manage_cms_services`.
 */
export const servicesRoutes = new Hono<AppEnv>();

servicesRoutes.get('/', listServicesHandler);

servicesRoutes.get('/manage', authMiddleware, requirePermission('manage_cms_services'), listManagedServicesHandler);
servicesRoutes.post('/', authMiddleware, requirePermission('manage_cms_services'), createServiceHandler);
servicesRoutes.patch(
  '/:id',
  authMiddleware,
  requirePermission('manage_cms_services'),
  updateServiceHandler,
);
