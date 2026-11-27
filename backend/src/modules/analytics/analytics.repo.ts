import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { toNumber } from '../../shared/utils/number';
import type { RecentOrderView } from '../finance/finance.types';

function failed(label: string, message: string): AppError {
  console.error(`analytics: gagal ${label}`, message);
  return new AppError(500, 'analytics_failed', 'Gagal memuat data dashboard. Coba lagi ya.');
}

export async function countActiveOrders(env: Bindings): Promise<number> {
  const admin = getSupabaseAdmin(env);
  const { count, error } = await admin
    .from('orders')
    .select('id', { count: 'exact', head: true })
    .not('status', 'in', '("completed","cancelled")');

  if (error) throw failed('menghitung order aktif', error.message);
  return count ?? 0;
}

interface RawOrderRow {
  id: string;
  order_number: string;
  status: string;
  total_price: number;
  created_at: string;
  walk_in_customer_name: string | null;
  customer: { users: { full_name: string | null } | null } | null;
  order_items: Array<{ quantity: number | null }> | null;
}

/** Order terbaru untuk dashboard owner (PRD 20.0). */
export async function listRecentOrders(env: Bindings, limit: number): Promise<RecentOrderView[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('orders')
    .select(
      'id, order_number, status, total_price, created_at, walk_in_customer_name, ' +
        'customer:customer_profiles(users(full_name)), order_items(quantity)',
    )
    .order('created_at', { ascending: false })
    .limit(limit);

  if (error) throw failed('memuat order terbaru', error.message);

  return ((data ?? []) as unknown as RawOrderRow[]).map((row) => ({
    id: row.id,
    order_number: row.order_number,
    customer_name: row.customer?.users?.full_name ?? row.walk_in_customer_name ?? 'Pelanggan',
    item_count: (row.order_items ?? []).reduce(
      (sum, item) => sum + (item.quantity ?? 1),
      0,
    ),
    total: Math.round(toNumber(row.total_price)),
    status: row.status,
    created_at: row.created_at,
  }));
}
