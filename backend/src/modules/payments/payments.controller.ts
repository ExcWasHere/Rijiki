import type { Context } from 'hono';
import type { AppEnv } from '../../shared/types/env';
import { createPayment, getPaymentStatus } from './payments.service';

export async function createPaymentHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  c.header('Cache-Control', 'no-store');
  const result = await createPayment(c.env, ctx, c.req.param('id') ?? '');
  return c.json(result.payment, result.created ? 201 : 200);
}

export async function getPaymentHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  c.header('Cache-Control', 'no-store');
  return c.json(await getPaymentStatus(c.env, ctx, c.req.param('id') ?? ''));
}
