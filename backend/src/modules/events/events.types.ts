export type EventType = 'promo' | 'collaboration' | 'announcement';

/** Ringkasan promo yang menempel pada event. */
export interface EventPromoView {
  id: string;
  code: string;
  title: string;
  description: string | null;
  discount_type: 'percentage' | 'fixed';
  discount_value: number;
  applies_to: 'subtotal' | 'shipping';
  min_subtotal: number | null;
  max_discount_amount: number | null;
  first_order_only: boolean;
  start_date: string;
  end_date: string;
  is_active: boolean;
  /** Batas pemakaian per customer; null = tanpa batas. */
  usage_limit_per_customer: number | null;
  /** Layanan yang ikut dihitung; kosong = berlaku untuk semua layanan. */
  service_ids: string[];
  /** Nama layanan di atas, untuk ditampilkan di detail promo. */
  service_names: string[];
  /** Sisa kuota total; null = tanpa batas. */
  quota_left: number | null;
  /** Aktif, dalam periode (WIB), dan kuota belum habis. */
  available: boolean;
}

export interface EventView {
  id: string;
  title: string;
  description: string | null;
  banner_image_url: string | null;
  event_type: EventType;
  related_promo_id: string | null;
  start_date: string | null;
  end_date: string | null;
  is_published: boolean;
  created_at: string;
  promo: EventPromoView | null;
}

export interface PromoOptionView {
  id: string;
  code: string;
  title: string;
  is_active: boolean;
  start_date: string;
  end_date: string;
}

/**
 * Baris `promos` hasil join `promo:promos!(...)`. Angka dari PostgREST bisa
 * datang sebagai string (numeric), jadi tipe kolomnya longgar.
 */
export interface EventPromoRow {
  id: string;
  code: string;
  title: string;
  description: string | null;
  discount_type: 'percentage' | 'fixed';
  discount_value: number | string;
  applies_to: 'subtotal' | 'shipping' | null;
  min_subtotal: number | string | null;
  max_discount_amount: number | string | null;
  usage_limit: number | string | null;
  usage_limit_per_customer: number | string | null;
  first_order_only: boolean | null;
  start_date: string;
  end_date: string;
  is_active: boolean | null;
  created_at: string;
  promo_services?: Array<{
    service_id: string;
    services?: { name: string } | null;
  }> | null;
}

export interface EventWrite {
  title: string;
  event_type: EventType;
  description: string | null;
  banner_image_url: string | null;
  related_promo_id: string | null;
  start_date: string | null;
  end_date: string | null;
  is_published: boolean;
}

export type EventRow = Record<string, unknown>;
