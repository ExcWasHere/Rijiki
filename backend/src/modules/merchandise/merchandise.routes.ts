import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import { requirePermission } from '../../middleware/permission';
import type { AppEnv } from '../../shared/types/env';
import {
  createMerchandiseHandler,
  listMerchandiseHandler,
  updateMerchandiseHandler,
} from './merchandise.controller';

/**
 * Owner / worker berizin manage_cms_merchandise. Dipasang di
 * /api/management/merchandise. Merchandise tidak dihapus (penukaran poin
 * mereferensikannya): nonaktifkan lewat PATCH is_active. Katalog yang dilihat
 * customer ada di GET /api/points/rewards.
 */
export const managementMerchandiseRoutes = new Hono<AppEnv>();
managementMerchandiseRoutes.use('*', authMiddleware);
managementMerchandiseRoutes.use('*', requirePermission('manage_cms_merchandise'));
managementMerchandiseRoutes.get('/', listMerchandiseHandler);
managementMerchandiseRoutes.post('/', createMerchandiseHandler);
managementMerchandiseRoutes.patch('/:id', updateMerchandiseHandler);
