export type PromoDiscountType = 'percentage' | 'fixed';
export type PromoAppliesTo = 'subtotal' | 'shipping';

export interface PromoView {
  id: string;
  code: string;
  title: string;
  description: string | null;
  discount_type: PromoDiscountType;
  discount_value: number;
  start_date: string;
  end_date: string;
  /** Saklar manual. Promo yang lewat periodenya tetap is_active = true tetapi tidak bisa dipakai. */
  is_active: boolean;
  applies_to: PromoAppliesTo;
  min_subtotal: number | null;
  max_discount_amount: number | null;
  usage_limit: number | null;
  usage_limit_per_customer: number | null;
  first_order_only: boolean;
  /** Kosong = berlaku untuk semua layanan. */
  service_ids: string[];
  /** Jumlah order (tidak batal) yang memakai promo ini: riwayat pemakaian. */
  usage_count: number;
  created_at: string;
}

/** Baris mentah promos + promo_services(service_id). */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type PromoDbRow = Record<string, any>;

/** Kolom promos yang ditulis backend. */
export interface PromoWrite {
  code: string;
  title: string;
  description: string | null;
  discount_type: PromoDiscountType;
  discount_value: number;
  start_date: string;
  end_date: string;
  is_active: boolean;
  applies_to: PromoAppliesTo;
  min_subtotal: number | null;
  max_discount_amount: number | null;
  usage_limit: number | null;
  usage_limit_per_customer: number | null;
  first_order_only: boolean;
}
