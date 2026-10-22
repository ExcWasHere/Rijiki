import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import { AppError } from '../../shared/errors';
import type { AppEnv } from '../../shared/types/env';
import { parseInput } from '../../shared/utils/validate';
import { loadAuthContext } from '../auth/auth.service';
import { updateProfileSchema } from './profile.schema';
import { updateCustomerProfile } from './profile.service';

export const profileRoutes = new Hono<AppEnv>();
profileRoutes.patch('/', authMiddleware, async (c) => {
  const { user } = c.get('user');
  if (user.role !== 'customer') {
    throw new AppError(403, 'forbidden', 'Profil ini hanya berlaku untuk customer');
  }

  const input = parseInput(updateProfileSchema, await c.req.json().catch(() => null));
  await updateCustomerProfile(c.env, user.id, input);

  return c.json(await loadAuthContext(c.env, user.id));
});
