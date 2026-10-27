import { toNumber } from '../../shared/utils/number';
import type {
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

export function toOrderView(row: OrderRow): OrderView {
  const customer = one(row.customer);
  const customerUser = one(customer?.users);
  const worker = one(row.worker);
  const workerUser = one(worker?.users);
  const promo = one(row.promos);

  const rawItems: OrderRow[] = Array.isArray(row.order_items) ? row.order_items : [];
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

  const documentation: OrderDocumentationView[] = rawItems.flatMap((item) =>
    (Array.isArray(item.order_documentations) ? item.order_documentations : []).map(
      (doc: OrderRow) => ({
        id: doc.id as string,
        type: doc.type as string,
        order_item_id: item.id as string,
        image_url: doc.image_url as string,
      }),
    ),
  );

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

  return {
    id: row.id as string,
    order_number: row.order_number as string,
    status: row.status as string,
    payment_status: row.payment_status as string,
    channel: row.channel as string,
    subtotal: toNumber(row.subtotal),
    discount_amount: toNumber(row.discount_amount),
    shipping_fee: toNumber(row.shipping_fee),
    total_price: toNumber(row.total_price),
    promo_code: (promo?.code as string | undefined) ?? null,
    pickup_address: (row.pickup_address as string | null) ?? null,
    delivery_address: (row.delivery_address as string | null) ?? null,
    customer_name: (customerUser?.full_name as string | undefined) ?? null,
    customer_phone: (customerUser?.phone_number as string | undefined) ?? null,
    worker_name: (workerUser?.full_name as string | undefined) ?? null,
    scheduled_pickup_at: (row.scheduled_pickup_at as string | null) ?? null,
    completed_at: (row.completed_at as string | null) ?? null,
    created_at: row.created_at as string,
    is_rated: isRated,
    items,
    status_history,
    documentation,
  };
}
