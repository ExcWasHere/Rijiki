import { Hono } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { validateEnv } from './config/env';
import { authRoutes } from './modules/auth/auth.routes';
import { mediaRoutes } from './modules/media/media.routes';
import { ordersRoutes } from './modules/orders/orders.routes';
import { profileRoutes } from './modules/profile/profile.routes';
import { servicesRoutes } from './modules/services/services.routes';
import { AppError } from './shared/errors';
import type { AppEnv } from './shared/types/env';

function codeFromStatus(status: number): string {
  if (status === 401) return 'unauthorized';
  if (status === 403) return 'forbidden';
  return 'http_error';
}

export function createApp() {
  const app = new Hono<AppEnv>();

  app.use('*', async (c, next) => {
    validateEnv(c.env);
    await next();
  });

  app.get('/', (c) => c.json({ name: 'rijiki-backend', status: 'ok' }));

  app.route('/api/auth', authRoutes);
  app.route('/api/media', mediaRoutes);
  app.route('/api/profile', profileRoutes);
  app.route('/api/services', servicesRoutes);
  app.route('/api/orders', ordersRoutes);

  app.notFound((c) =>
    c.json({ error: { code: 'not_found', message: 'Endpoint tidak ditemukan' } }, 404),
  );

  app.onError((err, c) => {
    if (err instanceof AppError) {
      return c.json({ error: { code: err.code, message: err.message } }, err.status);
    }
    if (err instanceof HTTPException) {
      return c.json(
        { error: { code: codeFromStatus(err.status), message: err.message } },
        err.status,
      );
    }
    console.error(err);
    return c.json(
      { error: { code: 'internal_error', message: 'Terjadi kesalahan pada server' } },
      500,
    );
  });

  return app;
}
