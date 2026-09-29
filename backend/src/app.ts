import { Hono } from 'hono';
import { cors } from 'hono/cors';
import type { AppEnv } from './shared/types/env';
import { errorHandler } from './middleware/error';
import { authRoutes } from './modules/auth/auth.routes';
import { onboardingRoutes } from './modules/onboarding/onboarding.routes';
import { scanRoutes } from './modules/scans/scans.routes';
import { orderRoutes } from './modules/orders/orders.routes';
import { paymentRoutes } from './modules/payments/payments.routes';
import { webhookRoutes } from './modules/webhooks/webhooks.routes';
import { eventRoutes, managementEventRoutes } from './modules/events/events.routes';
import { pointRoutes, managementPointRoutes } from './modules/points/points.routes';
import { testimonialRoutes } from './modules/testimonials/testimonials.routes';
import { serviceRoutes } from './modules/services/services.routes';
import { promoRoutes } from './modules/promos/promos.routes';
import { merchandiseRoutes } from './modules/merchandise/merchandise.routes';
import { workerRoutes } from './modules/workers/workers.routes';
import { financeRoutes } from './modules/finance/finance.routes';
import { analyticsRoutes } from './modules/analytics/analytics.routes';
import { ownerRoutes } from './modules/owner/owner.routes';

export function createApp() {
  const app = new Hono<AppEnv>();

  app.use('*', cors());
  app.onError(errorHandler);

  app.get('/health', (c) => c.json({ status: 'ok' }));

  app.route('/api/auth', authRoutes);
  app.route('/api/onboarding', onboardingRoutes);

  app.route('/api/scans', scanRoutes);
  app.route('/api/orders', orderRoutes);
  app.route('/api/orders', paymentRoutes);
  app.route('/api/webhooks', webhookRoutes);
  app.route('/api/events', eventRoutes);
  app.route('/api/points', pointRoutes);
  app.route('/api/testimonials', testimonialRoutes);

  app.route('/api/services', serviceRoutes);
  app.route('/api/promos', promoRoutes);
  app.route('/api/workers', workerRoutes);
  app.route('/api/finance', financeRoutes);

  app.route('/api/management/events', managementEventRoutes);
  app.route('/api/management/merchandise', merchandiseRoutes);
  app.route('/api/management', managementPointRoutes);
  app.route('/api/management', analyticsRoutes);

  app.route('/api/owner', ownerRoutes);
  app.notFound((c) => c.json({ success: false, message: 'Route tidak ditemukan' }, 404));

  return app;
}