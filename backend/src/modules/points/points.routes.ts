import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import { requirePermission } from '../../middleware/permission';
import type { AppEnv } from '../../shared/types/env';
import {
  adjustPointsHandler,
  balanceHandler,
  createRedemptionHandler,
  ledgerHandler,
  listManagedRedemptionsHandler,
  listMyRedemptionsHandler,
  listRewardsHandler,
  listRulesHandler,
  processRedemptionHandler,
  searchCustomersHandler,
  updateRuleHandler,
} from './points.controller';

export const pointsRoutes = new Hono<AppEnv>();
pointsRoutes.use('*', authMiddleware);
pointsRoutes.get('/balance', balanceHandler);
pointsRoutes.get('/ledger', ledgerHandler);
pointsRoutes.get('/rewards', listRewardsHandler);
pointsRoutes.get('/redemptions', listMyRedemptionsHandler);
pointsRoutes.post('/redemptions', createRedemptionHandler);

/**
 * Owner / worker berizin manage_points: aturan perolehan poin. Dipasang di
 * /api/management/point-rules. Hanya baca dan ubah nilai; aturan tidak dibuat
 * atau dihapus lewat aplikasi.
 */
export const pointRulesRoutes = new Hono<AppEnv>();
pointRulesRoutes.use('*', authMiddleware);
pointRulesRoutes.use('*', requirePermission('manage_points'));
pointRulesRoutes.get('/', listRulesHandler);
pointRulesRoutes.patch('/:id', updateRuleHandler);

/**
 * Owner / worker berizin manage_points: penukaran dan penyesuaian poin.
 * Dipasang di /api/management/points.
 */
export const managementPointsRoutes = new Hono<AppEnv>();
managementPointsRoutes.use('*', authMiddleware);
managementPointsRoutes.use('*', requirePermission('manage_points'));
managementPointsRoutes.get('/redemptions', listManagedRedemptionsHandler);
managementPointsRoutes.patch('/redemptions/:id', processRedemptionHandler);
managementPointsRoutes.get('/customers', searchCustomersHandler);
managementPointsRoutes.post('/adjust', adjustPointsHandler);
