import type {
  DeliveryMethod,
  DocumentationType,
  OrderRow,
  OrderStatus,
  StaffActionsView,
} from './orders.types';

/** Siapa yang sedang melihat/mengubah order. */
export interface Viewer {
  role: 'customer' | 'worker' | 'owner';
  /** Owner, atau worker berizin manage_orders_all. */
  manageAll: boolean;
  /** worker_profiles.id pemanggil (null untuk owner/customer). */
  workerProfileId: string | null;
}

/** Bagian order yang dibutuhkan aturan alur status. */
export interface FlowInfo {
  status: OrderStatus;
  channel: string;
  delivery_method: DeliveryMethod;
  payment_status: string;
  assigned_worker_id: string | null;
}

export function flowInfoFromRow(row: OrderRow): FlowInfo {
  return {
    status: row.status as OrderStatus,
    channel: String(row.channel),
    delivery_method: (row.delivery_method as DeliveryMethod | undefined) ?? 'delivery',
    payment_status: String(row.payment_status),
    assigned_worker_id: (row.assigned_worker_id as string | null | undefined) ?? null,
  };
}

const ONLINE_FLOW: OrderStatus[] = [
  'order',
  'pickup',
  'waiting',
  'cleaning',
  'delivery',
  'completed',
];
// Order offline: sepatu diserahkan langsung di outlet, jadi mulai dari waiting (PRD 10.1).
const OFFLINE_DELIVERY_FLOW: OrderStatus[] = ['waiting', 'cleaning', 'delivery', 'completed'];
const OFFLINE_PICKUP_FLOW: OrderStatus[] = ['waiting', 'cleaning', 'completed'];

export function flowFor(order: FlowInfo): OrderStatus[] {
  if (order.channel !== 'staff_manual') return ONLINE_FLOW;
  return order.delivery_method === 'self_pickup' ? OFFLINE_PICKUP_FLOW : OFFLINE_DELIVERY_FLOW;
}

export function isFinalStatus(status: OrderStatus): boolean {
  return status === 'completed' || status === 'cancelled';
}

export function nextStatusOf(order: FlowInfo): OrderStatus | null {
  if (isFinalStatus(order.status)) return null;
  const flow = flowFor(order);
  const index = flow.indexOf(order.status);
  if (index < 0 || index >= flow.length - 1) return null;
  return flow[index + 1] ?? null;
}

export function isAssignedToViewer(order: FlowInfo, viewer: Viewer): boolean {
  return viewer.workerProfileId !== null && order.assigned_worker_id === viewer.workerProfileId;
}

/** Order dari aplikasi yang belum punya worker dan belum dijemput: boleh diambil worker mana pun. */
export function isClaimable(order: FlowInfo): boolean {
  return (
    order.assigned_worker_id === null &&
    order.status === 'order' &&
    order.channel === 'customer_app'
  );
}

/** Jendela status tempat tiap jenis foto boleh diunggah/dihapus oleh worker yang menangani. */
const UPLOAD_WINDOWS: Record<DocumentationType, OrderStatus[]> = {
  before: ['order', 'pickup', 'waiting'],
  after: ['cleaning'],
  proof_of_delivery: ['delivery'],
};

export function canUploadDocumentation(
  order: FlowInfo,
  viewer: Viewer,
  type: DocumentationType,
): boolean {
  if (viewer.role === 'customer') return false;
  if (isFinalStatus(order.status)) return false;
  // Ambil sendiri di outlet tidak punya bukti pengiriman.
  if (type === 'proof_of_delivery' && order.delivery_method === 'self_pickup') return false;
  // Owner/manage_orders_all boleh mengoreksi kapan saja selama order belum final.
  if (viewer.manageAll) return true;
  return isAssignedToViewer(order, viewer) && UPLOAD_WINDOWS[type].includes(order.status);
}

/** Foto apa yang wajib ada sebelum maju satu langkah ke `target`. */
export function requiredDocumentation(
  order: FlowInfo,
  target: OrderStatus,
): DocumentationType | null {
  if (target === 'cleaning') return 'before';
  if (order.status === 'cleaning') return 'after';
  if (order.status === 'delivery' && target === 'completed') return 'proof_of_delivery';
  return null;
}

export function staffActionsFor(order: FlowInfo, viewer: Viewer): StaffActionsView | null {
  if (viewer.role === 'customer') return null;

  const final = isFinalStatus(order.status);
  const next = nextStatusOf(order);
  const mine = isAssignedToViewer(order, viewer);

  return {
    next_status: next,
    can_claim: viewer.role === 'worker' && isClaimable(order),
    can_advance: !final && next !== null && (viewer.manageAll || mine),
    can_assign: !final && viewer.manageAll,
    can_cancel: !final && viewer.manageAll && order.payment_status === 'unpaid',
    can_correct: !final && viewer.manageAll,
    can_upload: {
      before: canUploadDocumentation(order, viewer, 'before'),
      after: canUploadDocumentation(order, viewer, 'after'),
      proof_of_delivery: canUploadDocumentation(order, viewer, 'proof_of_delivery'),
    },
  };
}
