import type { Context } from 'hono';
import { AppError } from '../../shared/errors';
import type { AppEnv } from '../../shared/types/env';
import { parseInput } from '../../shared/utils/validate';
import {
  adjustPointsSchema,
  createRedemptionSchema,
  customerSearchQuerySchema,
  ledgerQuerySchema,
  listRedemptionsQuerySchema,
  processRedemptionSchema,
  updatePointRuleSchema,
} from './points.schema';
import {
  adjustCustomerPoints,
  getPointBalance,
  getPointLedger,
  listManagedRedemptions,
  listMyRedemptions,
  listPointRules,
  listRewards,
  processRedemption,
  requestRedemption,
  searchPointCustomers,
  updatePointRule,
} from './points.service';

function requireCustomer(c: Context<AppEnv>): string {
  const ctx = c.get('user');
  if (ctx.user.role !== 'customer') {
    throw new AppError(403, 'forbidden', 'Fitur poin ini hanya untuk customer');
  }
  return ctx.user.id;
}

// --- Customer ---------------------------------------------------------------

export async function balanceHandler(c: Context<AppEnv>) {
  const userId = requireCustomer(c);
  c.header('Cache-Control', 'no-store');
  return c.json(await getPointBalance(c.env, userId));
}

export async function ledgerHandler(c: Context<AppEnv>) {
  const userId = requireCustomer(c);
  const query = parseInput(ledgerQuerySchema, c.req.query());
  c.header('Cache-Control', 'no-store');
  return c.json(await getPointLedger(c.env, userId, query));
}

export async function listRewardsHandler(c: Context<AppEnv>) {
  requireCustomer(c);
  c.header('Cache-Control', 'no-store');
  return c.json(await listRewards(c.env));
}

export async function listMyRedemptionsHandler(c: Context<AppEnv>) {
  const userId = requireCustomer(c);
  const query = parseInput(listRedemptionsQuerySchema, c.req.query());
  c.header('Cache-Control', 'no-store');
  return c.json(await listMyRedemptions(c.env, userId, query));
}

export async function createRedemptionHandler(c: Context<AppEnv>) {
  const userId = requireCustomer(c);
  const input = parseInput(createRedemptionSchema, await c.req.json().catch(() => null));
  return c.json(await requestRedemption(c.env, userId, input), 201);
}

// --- Owner / worker berizin manage_points -------------------------------------

export async function listRulesHandler(c: Context<AppEnv>) {
  c.header('Cache-Control', 'no-store');
  return c.json(await listPointRules(c.env));
}

export async function updateRuleHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const input = parseInput(updatePointRuleSchema, await c.req.json().catch(() => null));
  return c.json(await updatePointRule(c.env, ctx.user.id, c.req.param('id') ?? '', input));
}

export async function listManagedRedemptionsHandler(c: Context<AppEnv>) {
  const query = parseInput(listRedemptionsQuerySchema, c.req.query());
  c.header('Cache-Control', 'no-store');
  return c.json(await listManagedRedemptions(c.env, query));
}

export async function processRedemptionHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const input = parseInput(processRedemptionSchema, await c.req.json().catch(() => null));
  return c.json(await processRedemption(c.env, ctx.user.id, c.req.param('id') ?? '', input));
}

export async function searchCustomersHandler(c: Context<AppEnv>) {
  const query = parseInput(customerSearchQuerySchema, c.req.query());
  c.header('Cache-Control', 'no-store');
  return c.json(await searchPointCustomers(c.env, query));
}

export async function adjustPointsHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const input = parseInput(adjustPointsSchema, await c.req.json().catch(() => null));
  return c.json(await adjustCustomerPoints(c.env, ctx.user.id, input));
}
