import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import { requirePermission } from '../../middleware/permission';
import type { AppEnv } from '../../shared/types/env';
import { createPromoHandler, listPromosHandler, updatePromoHandler } from './promos.controller';

export const promosRoutes = new Hono<AppEnv>();

promosRoutes.use('*', authMiddleware);
promosRoutes.use('*', requirePermission('manage_cms_promos'));

promosRoutes.get('/', listPromosHandler);
promosRoutes.post('/', createPromoHandler);
promosRoutes.patch('/:id', updatePromoHandler);
