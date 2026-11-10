import type { Bindings } from '../../shared/types/env';
import { listRepeatCustomerRows } from './customers.repo';
import type { RepeatQuery } from './customers.schema';
import type { RepeatCustomerView } from './customers.types';

/**
 * Pelanggan dengan lebih dari satu order `completed`. Order offline ikut
 * dihitung per nomor HP, dan digabung ke akun bila nomornya sama.
 */
export async function listRepeatCustomers(
  env: Bindings,
  query: RepeatQuery,
): Promise<{ items: RepeatCustomerView[]; page: number; limit: number; total: number }> {
  const { rows, total } = await listRepeatCustomerRows(env, query);
  return { items: rows, page: query.page, limit: query.limit, total };
}
