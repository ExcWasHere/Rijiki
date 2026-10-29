import type { Context } from 'hono';
import { AppError } from '../../shared/errors';
import type { AppEnv } from '../../shared/types/env';
import type { AuthContextUser } from '../../shared/types/user';
import { parseInput } from '../../shared/utils/validate';
import {
  assignOrderSchema,
  createOrderSchema,
  listOrdersQuerySchema,
  quoteOrderSchema,
  updateStatusSchema,
} from './orders.schema';
import { createOrder, getOrder, listOrders, quoteOrder } from './orders.service';
import { trackingPointSchema } from './orders.tracking.schema';
import { getTracking, recordTrackingPoint } from './orders.tracking.service';
import {
  DOCUMENTATION_MAX_BYTES,
  assignOrder,
  changeOrderStatus,
  claimOrder,
  deleteDocumentation,
  uploadDocumentation,
} from './orders.staff.service';

const MAX_DOCUMENTATION_REQUEST_BYTES = DOCUMENTATION_MAX_BYTES + 64 * 1024;

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

export async function claimOrderHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  return c.json(await claimOrder(c.env, ctx, c.req.param('id') ?? ''));
}

export async function assignOrderHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const input = parseInput(assignOrderSchema, await c.req.json().catch(() => null));
  return c.json(await assignOrder(c.env, ctx, c.req.param('id') ?? '', input.worker_id));
}

export async function updateStatusHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const input = parseInput(updateStatusSchema, await c.req.json().catch(() => null));
  return c.json(await changeOrderStatus(c.env, ctx, c.req.param('id') ?? '', input));
}

export async function uploadDocumentationHandler(c: Context<AppEnv>) {
  const declaredLength = Number(c.req.header('Content-Length') ?? 0);
  if (declaredLength > MAX_DOCUMENTATION_REQUEST_BYTES) {
    throw new AppError(413, 'file_too_large', 'Ukuran gambar maksimal 5 MB');
  }

  const ctx = c.get('user');
  const body = await c.req.parseBody().catch(() => ({}) as Record<string, unknown>);
  const result = await uploadDocumentation(c.env, ctx, c.req.param('id') ?? '', body);
  return c.json(result, 201);
}

export async function deleteDocumentationHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  await deleteDocumentation(c.env, ctx, c.req.param('id') ?? '', c.req.param('docId') ?? '');
  return c.body(null, 204);
}

export async function recordTrackingHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const input = parseInput(trackingPointSchema, await c.req.json().catch(() => null));
  return c.json(await recordTrackingPoint(c.env, ctx, c.req.param('id') ?? '', input), 201);
}

export async function getTrackingHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  c.header('Cache-Control', 'no-store');
  return c.json(await getTracking(c.env, ctx, c.req.param('id') ?? ''));
}
