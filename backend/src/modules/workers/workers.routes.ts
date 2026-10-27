import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import { AppError } from '../../shared/errors';
import type { AppEnv } from '../../shared/types/env';
import { listActiveWorkers } from './workers.repo';

export const workersRoutes = new Hono<AppEnv>();

workersRoutes.use('*', authMiddleware);

// Daftar worker aktif untuk memilih worker saat meng-assign order.
// Hanya owner atau worker berizin manage_orders_all / manage_workers.
// Endpoint manajemen worker lengkap (CRUD, KPI) menyusul di modul worker management.
workersRoutes.get('/', async (c) => {
  const ctx = c.get('user');
  const allowed =
    ctx.ownerBypass ||
    (ctx.user.role === 'worker' &&
      (ctx.permissions.includes('manage_orders_all') || ctx.permissions.includes('manage_workers')));

  if (!allowed) {
    throw new AppError(403, 'forbidden', 'Tidak punya izin melihat daftar worker');
  }

  return c.json({ items: await listActiveWorkers(c.env) });
});
