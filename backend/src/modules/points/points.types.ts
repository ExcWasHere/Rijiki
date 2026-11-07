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

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type PointRow = Record<string, any>;
