import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import { requirePermission } from '../../middleware/permission';
import type { AppEnv } from '../../shared/types/env';
import { createPromoHandler, listPromosHandler, updatePromoHandler } from './promos.controller';

/**
 * Promo tidak pernah dihapus (riwayat pemakaian tetap bisa dilacak):
 * nonaktifkan lewat PATCH is_active, atau perpanjang periodenya.
 */
export const promosRoutes = new Hono<AppEnv>();

promosRoutes.use('*', authMiddleware);
promosRoutes.use('*', requirePermission('manage_cms_promos'));

promosRoutes.get('/', listPromosHandler);
promosRoutes.post('/', createPromoHandler);
promosRoutes.patch('/:id', updatePromoHandler);
