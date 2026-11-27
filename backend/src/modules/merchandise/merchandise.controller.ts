import type { Context } from 'hono';
import type { AppEnv } from '../../shared/types/env';
import { parseInput } from '../../shared/utils/validate';
import { createMerchandiseSchema, updateMerchandiseSchema } from './merchandise.schema';
import { createMerchandise, listMerchandise, updateMerchandise } from './merchandise.service';

export async function listMerchandiseHandler(c: Context<AppEnv>) {
  c.header('Cache-Control', 'no-store');
  return c.json(await listMerchandise(c.env));
}

export async function createMerchandiseHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const input = parseInput(createMerchandiseSchema, await c.req.json().catch(() => null));
  return c.json(await createMerchandise(c.env, ctx.user.id, input), 201);
}

export async function updateMerchandiseHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const input = parseInput(updateMerchandiseSchema, await c.req.json().catch(() => null));
  return c.json(await updateMerchandise(c.env, ctx.user.id, c.req.param('id') ?? '', input));
}
