import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import { requirePermission } from '../../middleware/permission';
import type { AppEnv } from '../../shared/types/env';
import { repeatCustomersHandler } from './customers.controller';

/** Dipasang di /api/management/customers (owner / worker berizin view_analytics). */
export const managementCustomersRoutes = new Hono<AppEnv>();
managementCustomersRoutes.use('*', authMiddleware);
managementCustomersRoutes.use('*', requirePermission('view_analytics'));
managementCustomersRoutes.get('/repeat', repeatCustomersHandler);
