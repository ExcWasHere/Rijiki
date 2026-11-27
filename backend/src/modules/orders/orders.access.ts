import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import type { AuthContextUser } from '../../shared/types/user';
import { findCustomerProfileByUserId, findWorkerProfile, getOrderRow } from './orders.repo';
import { flowInfoFromRow, isClaimable } from './orders.transitions';
import type { Viewer } from './orders.transitions';
import type { OrderRow, OrderScope } from './orders.types';

export interface OrderAccess {
  scope: OrderScope;
  viewer: Viewer;
}

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function isUuid(value: string): boolean {
  return UUID_PATTERN.test(value);
}

export function orderNotFound(): AppError {
  return new AppError(404, 'order_not_found', 'Order tidak ditemukan');
}

/** Menentukan order mana yang boleh dilihat pemanggil, dan siapa dia bagi aturan alur status. */
export async function resolveAccess(env: Bindings, ctx: AuthContextUser): Promise<OrderAccess> {
  const { user, permissions, ownerBypass } = ctx;

  if (user.role === 'customer') {
    const profile = await findCustomerProfileByUserId(env, user.id);
    return {
      scope: profile ? { kind: 'customer', customerProfileId: profile.id } : { kind: 'none' },
      viewer: { role: 'customer', manageAll: false, workerProfileId: null },
    };
  }

  if (user.role === 'worker') {
    const manageAll = ownerBypass || permissions.includes('manage_orders_all');
    const worker = await findWorkerProfile(env, user.id);
    const workerProfileId = worker?.id ?? null;
    const viewer: Viewer = { role: 'worker', manageAll, workerProfileId };

    if (manageAll) return { scope: { kind: 'all' }, viewer };
    return {
      scope: workerProfileId ? { kind: 'worker', workerProfileId } : { kind: 'none' },
      viewer,
    };
  }

  // owner
  return {
    scope: { kind: 'all' },
    viewer: { role: 'owner', manageAll: true, workerProfileId: null },
  };
}

export function canViewOrder(row: OrderRow, access: OrderAccess): boolean {
  const { scope } = access;
  if (scope.kind === 'all') return true;
  if (scope.kind === 'customer') return row.customer_id === scope.customerProfileId;
  if (scope.kind === 'worker') {
    // Selain order miliknya, worker boleh melihat order yang masih bisa diambil.
    return (
      row.assigned_worker_id === scope.workerProfileId || isClaimable(flowInfoFromRow(row))
    );
  }
  return false;
}

/** Memuat order dan menjawab 404 (bukan 403) bila tidak boleh dilihat, agar id tidak bisa ditebak. */
export async function loadVisibleOrder(
  env: Bindings,
  access: OrderAccess,
  orderId: string,
): Promise<OrderRow> {
  if (!isUuid(orderId)) throw orderNotFound();
  if (access.scope.kind === 'none') throw orderNotFound();

  const row = await getOrderRow(env, orderId);
  if (!row || !canViewOrder(row, access)) throw orderNotFound();
  return row;
}
