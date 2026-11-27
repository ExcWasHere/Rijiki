import { toNumber } from '../../shared/utils/number';
import { flowInfoFromRow, isAssignedToViewer, staffActionsFor } from './orders.transitions';
import type { Viewer } from './orders.transitions';
import type {
  AppliedPromoView,
  OrderDocumentationView,
  OrderItemView,
  OrderRow,
  OrderStatusHistoryView,
  OrderView,
} from './orders.types';

function one(value: any): any {
  if (Array.isArray(value)) return value[0] ?? null;
  return value ?? null;
}

function itemSuffix(code: string): number {
  const n = Number.parseInt(code.split('-').pop() ?? '', 10);
  return Number.isFinite(n) ? n : 0;
}

function toAppliedPromos(raw: unknown): AppliedPromoView[] {
  const rows: OrderRow[] = Array.isArray(raw) ? raw : [];
  return rows
    .map((row) => ({
      code: (one(row.promos)?.code as string | undefined) ?? '-',
      applies_to: (row.applies_to === 'shipping' ? 'shipping' : 'subtotal') as AppliedPromoView['applies_to'],
      discount_amount: toNumber(row.discount_amount),
    }))
    // Promo layanan dulu, lalu ongkir: sama dengan urutan baris di struk.
    .sort((a, b) => (a.applies_to === b.applies_to ? 0 : a.applies_to === 'subtotal' ? -1 : 1));
}

export function toOrderView(row: OrderRow, viewer: Viewer | null): OrderView {
  const customer = one(row.customer);
  const customerUser = one(customer?.users);
  const worker = one(row.worker);
  const workerUser = one(worker?.users);
  const info = flowInfoFromRow(row);

  const rawItems: OrderRow[] = Array.isArray(row.order_items) ? [...row.order_items] : [];
  rawItems.sort((a, b) => itemSuffix(String(a.item_code)) - itemSuffix(String(b.item_code)));

  const items: OrderItemView[] = rawItems.map((item) => ({
    id: item.id as string,
    item_code: item.item_code as string,
    shoe_name: ((item.shoe_brand as string | null) ?? '').trim() || '-',
    service_name: (one(item.services)?.name as string | undefined) ?? '-',
    price: toNumber(item.price),
    quantity: toNumber(item.quantity, 1),
    notes: (item.notes as string | null) ?? null,
  }));

  const rawDocs: OrderRow[] = Array.isArray(row.order_documentations)
    ? row.order_documentations
    : [];
  const documentation: OrderDocumentationView[] = rawDocs.map((doc) => ({
    id: doc.id as string,
    type: doc.type as string,
    order_item_id: (doc.order_item_id as string | null) ?? null,
    image_url: doc.image_url as string,
  }));

  const rawHistory: OrderRow[] = Array.isArray(row.order_status_histories)
    ? row.order_status_histories
    : [];
  const status_history: OrderStatusHistoryView[] = rawHistory
    .map((h) => ({
      status: h.new_status as string,
      changed_at: h.changed_at as string,
      note: (h.notes as string | null) ?? null,
    }))
    .sort((a, b) => Date.parse(a.changed_at) - Date.parse(b.changed_at));

  const rating = row.ratings;
  const isRated = Array.isArray(rating) ? rating.length > 0 : Boolean(rating);

  // Worker yang belum memegang order hanya perlu tahu isi pekerjaannya untuk
  // memutuskan mengambilnya; nomor HP dan alamat customer baru dibuka setelah
  // order di-claim (atau untuk pemegang manage_orders_all).
  const contactVisible =
    !viewer ||
    viewer.role !== 'worker' ||
    viewer.manageAll ||
    isAssignedToViewer(info, viewer);

  return {
    id: row.id as string,
    order_number: row.order_number as string,
    status: row.status as string,
    payment_status: row.payment_status as string,
    channel: row.channel as string,
    delivery_method: info.delivery_method,
    subtotal: toNumber(row.subtotal),
    discount_amount: toNumber(row.discount_amount),
    shipping_fee: toNumber(row.shipping_fee),
    total_price: toNumber(row.total_price),
    promos: toAppliedPromos(row.order_promos),
    pickup_address: contactVisible ? ((row.pickup_address as string | null) ?? null) : null,
    delivery_address: contactVisible ? ((row.delivery_address as string | null) ?? null) : null,
    customer_name:
      (customerUser?.full_name as string | undefined) ??
      (row.walk_in_customer_name as string | null | undefined) ??
      null,
    customer_phone: contactVisible
      ? ((customerUser?.phone_number as string | undefined) ??
        (row.walk_in_customer_phone as string | null | undefined) ??
        null)
      : null,
    assigned_worker_id: info.assigned_worker_id,
    assigned_to_me: viewer ? isAssignedToViewer(info, viewer) : false,
    worker_name: (workerUser?.full_name as string | undefined) ?? null,
    scheduled_pickup_at: (row.scheduled_pickup_at as string | null) ?? null,
    completed_at: (row.completed_at as string | null) ?? null,
    created_at: row.created_at as string,
    is_rated: isRated,
    items,
    status_history,
    documentation,
    staff: viewer ? staffActionsFor(info, viewer) : null,
  };
}
