import type { Context } from 'hono';
import type { AppEnv } from '../../shared/types/env';
import { parseInput } from '../../shared/utils/validate';
import { repeatQuerySchema } from './customers.schema';
import { listRepeatCustomers } from './customers.service';

export async function repeatCustomersHandler(c: Context<AppEnv>) {
  const query = parseInput(repeatQuerySchema, c.req.query());
  c.header('Cache-Control', 'no-store');
  return c.json(await listRepeatCustomers(c.env, query));
}
