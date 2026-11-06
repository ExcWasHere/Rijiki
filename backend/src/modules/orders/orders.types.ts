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
export type DeliveryMethod = 'delivery' | 'self_pickup';

export const DOCUMENTATION_TYPES = ['before', 'after', 'proof_of_delivery'] as const;
export type DocumentationType = (typeof DOCUMENTATION_TYPES)[number];

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

export interface WorkerProfileRow {
  id: string;
  status: string;
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
  min_subtotal: number | string | null;
  max_discount_amount: number | string | null;
  usage_limit: number | null;
  usage_limit_per_customer: number | null;
  first_order_only: boolean;
  /** Kosong/null = promo berlaku untuk semua layanan. */
  promo_services: Array<{ service_id: string }> | null;
}

/** Satu baris harga hasil hitung server (harga dari database x jumlah). */
export interface PricedLine {
  service_id: string;
  amount: number;
}

/** Pemakaian promo yang relevan untuk syarat dan kuota (order batal tidak dihitung). */
export interface PromoUsage {
  /** Seluruh pemakaian promo ini. */
  total: number;
  /** Pemakaian oleh customer yang sedang memesan. */
  perCustomer: number;
  /** Jumlah order (tidak batal) milik customer, untuk syarat order pertama. */
  customerOrders: number;
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
  /** Kosong untuk proof_of_delivery (bukti per order). */
  order_item_id: string | null;
  /** Bucket privat: berisi key objek, bukan URL (PRD Bagian 22). */
  image_url: string;
}

/**
 * Aksi yang boleh dilakukan pemanggil pada order ini. Dihitung server supaya
 * Flutter cukup menampilkan tombol sesuai hasil, bukan menebak aturannya.
 * Null untuk customer.
 */
export interface StaffActionsView {
  next_status: OrderStatus | null;
  can_claim: boolean;
  can_advance: boolean;
  can_assign: boolean;
  can_cancel: boolean;
  can_correct: boolean;
  can_upload: Record<DocumentationType, boolean>;
}

export interface OrderView {
  id: string;
  order_number: string;
  status: string;
  payment_status: string;
  channel: string;
  delivery_method: string;
  subtotal: number;
  discount_amount: number;
  shipping_fee: number;
  total_price: number;
  promo_code: string | null;
  pickup_address: string | null;
  delivery_address: string | null;
  customer_name: string | null;
  customer_phone: string | null;
  assigned_worker_id: string | null;
  assigned_to_me: boolean;
  worker_name: string | null;
  scheduled_pickup_at: string | null;
  completed_at: string | null;
  created_at: string;
  is_rated: boolean;
  items: OrderItemView[];
  status_history: OrderStatusHistoryView[];
  documentation: OrderDocumentationView[];
  staff: StaffActionsView | null;
}

export type OrderRow = Record<string, any>;