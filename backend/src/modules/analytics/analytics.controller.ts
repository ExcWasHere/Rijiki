import type { Context } from 'hono';
import type { AppEnv } from '../../shared/types/env';
import { parseInput } from '../../shared/utils/validate';
import { z } from 'zod';
import { getDashboardSummary } from './analytics.service';
import { listRecentOrders } from './analytics.repo';

const summaryQuerySchema = z.object({
  period: z.enum(['today', 'week', 'month']).default('today'),
});

const recentQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(20).default(5),
});

export async function dashboardSummaryHandler(c: Context<AppEnv>) {
  const query = parseInput(summaryQuerySchema, c.req.query());
  c.header('Cache-Control', 'no-store');
  return c.json(await getDashboardSummary(c.env, query.period));
}

export async function recentOrdersHandler(c: Context<AppEnv>) {
  const query = parseInput(recentQuerySchema, c.req.query());
  c.header('Cache-Control', 'no-store');
  return c.json({ items: await listRecentOrders(c.env, query.limit) });
}
