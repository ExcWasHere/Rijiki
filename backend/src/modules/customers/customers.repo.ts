import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { toNumber } from '../../shared/utils/number';
import type { RepeatQuery } from './customers.schema';
import type { CustomerRow, RepeatCustomerView } from './customers.types';

function mapRepeat(row: CustomerRow): RepeatCustomerView {
  return {
    id: row.customer_key as string,
    name: (row.name as string | null) ?? 'Pelanggan',
    phone: (row.phone as string | null) ?? null,
    avatar_url: (row.avatar_url as string | null) ?? null,
    completed_orders: toNumber(row.completed_orders),
    total_spent: toNumber(row.total_spent),
    last_order_at: (row.last_order_at as string | null) ?? null,
    has_account: row.customer_id !== null && row.customer_id !== undefined,
  };
}

export async function listRepeatCustomerRows(
  env: Bindings,
  query: RepeatQuery,
): Promise<{ rows: RepeatCustomerView[]; total: number }> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin.rpc('get_repeat_customers', {
    p_min_orders: query.min_orders,
    p_limit: query.limit,
    p_offset: (query.page - 1) * query.limit,
  });

  if (error) {
    console.error('customers: gagal memuat repeat customer', error.message);
    throw new AppError(500, 'customers_failed', 'Gagal memuat pelanggan setia. Coba lagi ya.');
  }

  const rows = (data ?? []) as CustomerRow[];
  return { rows: rows.map(mapRepeat), total: toNumber(rows[0]?.total_count) };
}
