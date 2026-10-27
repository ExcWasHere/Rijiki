export const ORDER_STATUSES = [
  'order',
  'pickup',
  'waiting',
  'cleaning',
  'delivery',
  'completed',
  'cancelled',
] as const;

export type OrderStatus = (typeof ORDER_STATUSES)[number];
export type OrderPaymentStatus = 'unpaid' | 'paid';
export type OrderScope =
  | { kind: 'all' }
  | { kind: 'customer'; customerProfileId: string }
  | { kind: 'worker'; workerProfileId: string }
  | { kind: 'none' };

export interface CustomerProfileRow {
  id: string;
  default_address: string | null;
  default_lat: number | null;
  default_lng: number | null;
}

export interface ServicePriceRow {
  id: string;
  name: string;
  base_price: number;
  is_active: boolean;
}

export interface PromoRow {
  id: string;
  code: string;
  title: string;
  discount_type: 'percentage' | 'fixed';
  discount_value: number | string;
  start_date: string;
  end_date: string;
  is_active: boolean;
  applies_to: 'subtotal' | 'shipping' | null;
}

export interface PriceQuoteView {
  subtotal: number;
  discount_amount: number;
  shipping_fee: number;
  total_price: number;
  promo_code: string | null;
  promo_description: string | null;
  distance_km: number;
}

export interface OrderItemView {
  id: string;
  item_code: string;
  shoe_name: string;
  service_name: string;
  price: number;
  quantity: number;
  notes: string | null;
}

export interface OrderStatusHistoryView {
  status: string;
  changed_at: string;
  note: string | null;
}

export interface OrderDocumentationView {
  id: string;
  type: string;
  order_item_id: string;
  /** Bucket privat: berisi key objek, bukan URL (PRD Bagian 22). */
  image_url: string;
}

export interface OrderView {
  id: string;
  order_number: string;
  status: string;
  payment_status: string;
  channel: string;
  subtotal: number;
  discount_amount: number;
  shipping_fee: number;
  total_price: number;
  promo_code: string | null;
  pickup_address: string | null;
  delivery_address: string | null;
  customer_name: string | null;
  customer_phone: string | null;
  worker_name: string | null;
  scheduled_pickup_at: string | null;
  completed_at: string | null;
  created_at: string;
  is_rated: boolean;
  items: OrderItemView[];
  status_history: OrderStatusHistoryView[];
  documentation: OrderDocumentationView[];
}

/** Baris mentah hasil select bersarang PostgREST (lihat orders.repo.ts). */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type OrderRow = Record<string, any>;
