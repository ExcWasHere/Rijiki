import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import { AppError } from '../../shared/errors';
import type { AppEnv } from '../../shared/types/env';
import { parseInput } from '../../shared/utils/validate';
import { loadAuthContext } from '../auth/auth.service';
import { listMyRatings, listMyShoes } from './profile.history.repo';
import { historyQuerySchema, updateProfileSchema } from './profile.schema';
import { updateProfile } from './profile.service';

export const profileRoutes = new Hono<AppEnv>();

function requireCustomer(c: { get: (key: 'user') => AppEnv['Variables']['user'] }): string {
  const { user } = c.get('user');
  if (user.role !== 'customer') {
    throw new AppError(403, 'forbidden', 'Halaman ini hanya untuk customer');
  }
  return user.id;
}

/**
 * Simpan profil. Customer mengirim alamat + titik (wajib saat onboarding),
 * owner/worker hanya nama dan nomor HP. Respons memuat konteks auth terbaru
 * supaya Flutter bisa langsung memperbarui sesi.
 */
profileRoutes.patch('/', authMiddleware, async (c) => {
  const { user } = c.get('user');
  const input = parseInput(updateProfileSchema, await c.req.json().catch(() => null));

  await updateProfile(c.env, user, input);

  return c.json(await loadAuthContext(c.env, user.id));
});

/** Sepatu yang pernah dicuci customer, diambil dari riwayat order. */
profileRoutes.get('/shoes', authMiddleware, async (c) => {
  const query = parseInput(historyQuerySchema, c.req.query());
  c.header('Cache-Control', 'no-store');
  return c.json(await listMyShoes(c.env, requireCustomer(c), query));
});

/** Rating & testimoni yang pernah diberikan customer. */
profileRoutes.get('/ratings', authMiddleware, async (c) => {
  const query = parseInput(historyQuerySchema, c.req.query());
  c.header('Cache-Control', 'no-store');
  return c.json(await listMyRatings(c.env, requireCustomer(c), query));
});
