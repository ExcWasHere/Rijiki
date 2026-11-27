import type { Context } from 'hono';
import type { AppEnv } from '../../shared/types/env';
import { parseInput } from '../../shared/utils/validate';
import { createEventSchema, listEventsQuerySchema, updateEventSchema } from './events.schema';
import {
  createEvent,
  listCustomerEvents,
  listManagedEvents,
  listPromoOptions,
  updateEvent,
} from './events.service';

export async function listCustomerEventsHandler(c: Context<AppEnv>) {
  const query = parseInput(listEventsQuerySchema, c.req.query());
  c.header('Cache-Control', 'no-store');
  return c.json(await listCustomerEvents(c.env, query));
}

export async function listManagedEventsHandler(c: Context<AppEnv>) {
  c.header('Cache-Control', 'no-store');
  return c.json(await listManagedEvents(c.env));
}

export async function listPromoOptionsHandler(c: Context<AppEnv>) {
  c.header('Cache-Control', 'no-store');
  return c.json(await listPromoOptions(c.env));
}

export async function createEventHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const input = parseInput(createEventSchema, await c.req.json().catch(() => null));
  return c.json(await createEvent(c.env, ctx.user.id, input), 201);
}

export async function updateEventHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const input = parseInput(updateEventSchema, await c.req.json().catch(() => null));
  return c.json(await updateEvent(c.env, ctx.user.id, c.req.param('id') ?? '', input));
}
