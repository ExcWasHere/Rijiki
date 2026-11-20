import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import { requirePermission } from '../../middleware/permission';
import type { AppEnv } from '../../shared/types/env';
import { dashboardSummaryHandler, recentOrdersHandler } from './analytics.controller';

/**
 * Analitik dashboard owner (PRD 20, 29.9): Owner atau worker berizin
 * `view_analytics`.
 */
export const managementAnalyticsRoutes = new Hono<AppEnv>();
managementAnalyticsRoutes.use('*', authMiddleware, requirePermission('view_analytics'));

managementAnalyticsRoutes.get('/dashboard', dashboardSummaryHandler);
managementAnalyticsRoutes.get('/recent-orders', recentOrdersHandler);
