import type { Context } from 'hono';
import type { AppEnv } from '../../shared/types/env';
import { parseIdempotencyKey } from '../../shared/utils/idempotency';
import { parseInput } from '../../shared/utils/validate';
import { createPromoSchema, updatePromoSchema } from './promos.schema';
import { createPromo, listPromos, updatePromo } from './promos.service';

export async function listPromosHandler(c: Context<AppEnv>) {
  c.header('Cache-Control', 'no-store');
  return c.json(await listPromos(c.env));
}

export async function createPromoHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const input = parseInput(createPromoSchema, await c.req.json().catch(() => null));
  const key = parseIdempotencyKey(c.req.header('Idempotency-Key'));

  const result = await createPromo(c.env, ctx.user.id, input, key);
  if (result.replayed) {
    c.header('Idempotent-Replayed', 'true');
    return c.json(result.promo, 200);
  }
  return c.json(result.promo, 201);
}

export async function updatePromoHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const input = parseInput(updatePromoSchema, await c.req.json().catch(() => null));
  return c.json(await updatePromo(c.env, ctx.user.id, c.req.param('id') ?? '', input));
}
