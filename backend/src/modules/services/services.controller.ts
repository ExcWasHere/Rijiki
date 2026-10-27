import type { Context } from 'hono';
import type { AppEnv } from '../../shared/types/env';
import { getActiveServices } from './services.service';

export async function listServicesHandler(c: Context<AppEnv>) {
  const result = await getActiveServices(c.env);
  c.header('Cache-Control', 'public, max-age=60');
  return c.json(result);
}
