import { getSupabaseAdmin } from '../../config/supabase';
import type { Bindings } from '../../shared/types/env';
import type { AuthContextUser } from '../../shared/types/user';

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * documentations/<order_id>/<uuid>.<ext>
 * Boleh dibaca: customer pemilik order, worker yang di-assign (atau berizin
 * manage_orders_all), dan owner (owner sudah lolos di canReadPrivate).
 */
async function canReadDocumentation(
  env: Bindings,
  ctx: AuthContextUser,
  orderId: string,
): Promise<boolean> {
  if (!UUID_PATTERN.test(orderId)) return false;

  const admin = getSupabaseAdmin(env);
  const { data: order, error } = await admin
    .from('orders')
    .select('customer_id, assigned_worker_id')
    .eq('id', orderId)
    .maybeSingle();

  if (error) {
    console.error('media.policy: gagal memuat order', error.message);
    return false;
  }
  if (!order) return false;

  if (ctx.user.role === 'customer') {
    if (!order.customer_id) return false;
    const { data: profile } = await admin
      .from('customer_profiles')
      .select('id')
      .eq('user_id', ctx.user.id)
      .maybeSingle();
    return profile?.id === order.customer_id;
  }

  if (ctx.user.role === 'worker') {
    if (ctx.permissions.includes('manage_orders_all')) return true;
    if (!order.assigned_worker_id) return false;
    const { data: worker } = await admin
      .from('worker_profiles')
      .select('id')
      .eq('user_id', ctx.user.id)
      .maybeSingle();
    return worker?.id === order.assigned_worker_id;
  }

  return false;
}

// TODO saat modul ratings jadi:
//   - 'testimonials': pemilik rating + pemegang izin manage_testimonials
//
// Async karena sebagian aturan butuh query database. Defaultnya MENOLAK:
// folder baru wajib didaftarkan eksplisit di sini.
export async function canReadPrivate(
  env: Bindings,
  ctx: AuthContextUser,
  key: string,
): Promise<boolean> {
  if (ctx.ownerBypass) return true;

  const [folder, ownerId] = key.split('/');

  switch (folder) {
    case 'scans':
      return ownerId === ctx.user.id;
    case 'receipts':
      return ctx.user.role === 'worker' && ctx.permissions.includes('manage_finance');
    case 'documentations':
      return canReadDocumentation(env, ctx, ownerId ?? '');
    default:
      return false;
  }
}
