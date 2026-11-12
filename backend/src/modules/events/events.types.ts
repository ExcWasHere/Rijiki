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

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type EventRow = Record<string, any>;
