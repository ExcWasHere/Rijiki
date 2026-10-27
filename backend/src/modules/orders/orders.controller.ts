import type { Context } from 'hono';
import { AppError } from '../../shared/errors';
import type { AppEnv } from '../../shared/types/env';
import type { AuthContextUser } from '../../shared/types/user';
import { parseInput } from '../../shared/utils/validate';
import { createOrderSchema, listOrdersQuerySchema, quoteOrderSchema } from './orders.schema';
import { createOrder, getOrder, listOrders, quoteOrder } from './orders.service';

function requireCustomer(ctx: AuthContextUser): void {
  if (ctx.user.role !== 'customer') {
    throw new AppError(403, 'forbidden', 'Hanya customer yang dapat membuat order dari aplikasi');
  }
}

export async function quoteOrderHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  requireCustomer(ctx);

  const input = parseInput(quoteOrderSchema, await c.req.json().catch(() => null));
  return c.json(await quoteOrder(c.env, ctx.user.id, input));
}

export async function createOrderHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  requireCustomer(ctx);

  const input = parseInput(createOrderSchema, await c.req.json().catch(() => null));
  return c.json(await createOrder(c.env, ctx.user.id, input), 201);
}

export async function listOrdersHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const query = parseInput(listOrdersQuerySchema, c.req.query());
  return c.json(await listOrders(c.env, ctx, query));
}

export async function getOrderHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  return c.json(await getOrder(c.env, ctx, c.req.param('id') ?? ''));
}
