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
  is_active: boolean;
  applies_to: PromoAppliesTo;
  min_subtotal: number | null;
  max_discount_amount: number | null;
  usage_limit: number | null;
  usage_limit_per_customer: number | null;
  first_order_only: boolean;
  service_ids: string[];
  usage_count: number;
  created_at: string;
}

export type PromoDbRow = Record<string, any>;

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
