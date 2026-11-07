import type { Context } from 'hono';
import { AppError } from '../../shared/errors';
import type { AppEnv } from '../../shared/types/env';
import { parseInput } from '../../shared/utils/validate';
import { ledgerQuerySchema, updatePointRuleSchema } from './points.schema';
import {
  getPointBalance,
  getPointLedger,
  listPointRules,
  updatePointRule,
} from './points.service';

function requireCustomer(c: Context<AppEnv>): string {
  const ctx = c.get('user');
  if (ctx.user.role !== 'customer') {
    throw new AppError(403, 'forbidden', 'Saldo poin hanya untuk customer');
  }
  return ctx.user.id;
}

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

export async function listRulesHandler(c: Context<AppEnv>) {
  c.header('Cache-Control', 'no-store');
  return c.json(await listPointRules(c.env));
}

export async function updateRuleHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const input = parseInput(updatePointRuleSchema, await c.req.json().catch(() => null));
  return c.json(await updatePointRule(c.env, ctx.user.id, c.req.param('id') ?? '', input));
}
