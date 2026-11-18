import type { Context } from 'hono';
import type { AppEnv } from '../../shared/types/env';
import { parseInput } from '../../shared/utils/validate';
import { createServiceSchema, updateServiceSchema } from './services.schema';
import { createService, getActiveServices, getServicesForCms, updateService } from './services.service';

export async function listServicesHandler(c: Context<AppEnv>) {
  const result = await getActiveServices(c.env);
  c.header('Cache-Control', 'public, max-age=60');
  return c.json(result);
}

/** CMS: semua layanan termasuk yang nonaktif. */
export async function listManagedServicesHandler(c: Context<AppEnv>) {
  c.header('Cache-Control', 'no-store');
  return c.json(await getServicesForCms(c.env));
}

export async function createServiceHandler(c: Context<AppEnv>) {
  const input = parseInput(createServiceSchema, await c.req.json().catch(() => null));
  return c.json(await createService(c.env, c.get('user').user.id, input), 201);
}

export async function updateServiceHandler(c: Context<AppEnv>) {
  const input = parseInput(updateServiceSchema, await c.req.json().catch(() => null));
  return c.json(
    await updateService(c.env, c.get('user').user.id, c.req.param('id') ?? '', input),
  );
}
