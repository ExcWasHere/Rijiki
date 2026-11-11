import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';

export interface OrderStaffInfo {
  channel: string;
  created_by: string | null;
  assigned_worker_id: string | null;
}

/** Data order yang dibutuhkan untuk menilai akses worker/owner ke pembayaran order offline. */
export async function findOrderStaffInfo(
  env: Bindings,
  orderId: string,
): Promise<OrderStaffInfo | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('orders')
    .select('channel, created_by, assigned_worker_id')
    .eq('id', orderId)
    .maybeSingle();

  if (error) {
    console.error('payments: gagal memuat info order offline', error.message);
    throw new AppError(500, 'payment_failed', 'Gagal memproses pembayaran. Coba lagi ya.');
  }
  if (!data) return null;
  const row = data as unknown as Record<string, unknown>;
  return {
    channel: String(row['channel']),
    created_by: (row['created_by'] as string | null) ?? null,
    assigned_worker_id: (row['assigned_worker_id'] as string | null) ?? null,
  };
}
