export type PointRuleSource =
  | 'order_completed'
  | 'give_rating'
  | 'referral'
  | 'promo_bonus'
  | 'manual';

export type PointCalculationType = 'fixed' | 'per_amount';

export interface PointRuleView {
  id: string;
  source: PointRuleSource;
  calculation_type: PointCalculationType;
  points_value: number;
  /** Rupiah per satuan; hanya terisi bila calculation_type = per_amount. */
  amount_unit: number | null;
  is_active: boolean;
  updated_at: string;
}

export type LedgerType = 'earn' | 'redeem' | 'adjustment' | 'expire';

export interface LedgerEntryView {
  id: string;
  type: LedgerType;
  points_amount: number;
  description: string | null;
  order_number: string | null;
  created_at: string;
}

export interface PointBalanceView {
  points_balance: number;
  recent: LedgerEntryView[];
}

export type RedemptionStatus = 'pending' | 'approved' | 'rejected' | 'fulfilled';

export interface RedemptionView {
  id: string;
  customer_id: string;
  customer_name: string | null;
  customer_phone: string | null;
  /** Saldo customer saat ini (bukan saat diajukan). */
  customer_balance: number;
  reward_name: string;
  merchandise_id: string | null;
  points_used: number;
  status: RedemptionStatus;
  notes: string | null;
  requested_at: string;
  processed_at: string | null;
  processed_by_name: string | null;
}

export interface RewardView {
  id: string;
  name: string;
  description: string | null;
  image_url: string | null;
  points_cost: number;
  in_stock: boolean;
}

export interface PointCustomerView {
  /** customer_profiles.id */
  id: string;
  name: string | null;
  email: string;
  phone: string | null;
  avatar_url: string | null;
  points_balance: number;
}

export interface AdjustResultView {
  customer_id: string;
  points_amount: number;
  points_balance: number;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type PointRow = Record<string, any>;
