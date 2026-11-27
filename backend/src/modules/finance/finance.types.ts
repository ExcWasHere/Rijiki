export type FinancePeriod = 'today' | 'week' | 'month';

export type ExpenseType = 'material' | 'equipment' | 'external_service' | 'other';
export type TransactionType = 'income' | 'expense';
export type InputSource = 'manual' | 'ai';
export type PaymentMethod = 'qris' | 'cash';

export const EXPENSE_TYPES: ExpenseType[] = [
  'material',
  'equipment',
  'external_service',
  'other',
];

export interface TransactionRow {
  id: string;
  type: TransactionType;
  expense_type: ExpenseType | null;
  category: string | null;
  amount: number;
  description: string | null;
  related_order_id: string | null;
  transaction_date: string;
  created_at: string;
  item_name: string | null;
  quantity: number | null;
  unit: string | null;
  vendor_name: string | null;
  input_source: InputSource;
  receipt_image_url: string | null;
  payment_method: PaymentMethod | null;
}

/** Satu baris transaksi seperti yang dikirim ke Flutter. */
export interface TransactionView {
  id: string;
  type: TransactionType;
  expense_type: ExpenseType | null;
  category: string | null;
  amount: number;
  description: string | null;
  related_order_id: string | null;
  transaction_date: string;
  item_name: string | null;
  quantity: number | null;
  unit: string | null;
  vendor_name: string | null;
  input_source: InputSource;
  receipt_image_url: string | null;
  payment_method: PaymentMethod | null;
}

export interface SeriesPoint {
  label: string;
  amount: number;
}

export interface FinanceSummaryView {
  period: FinancePeriod;
  income: number;
  expense: number;
  previous_income: number;
  series: SeriesPoint[];
  expense_by_type: Record<ExpenseType, number>;
}

export interface TransactionTotals {
  income: number;
  expense: number;
}

export interface TransactionListPage {
  items: TransactionView[];
  total: number;
  income: number;
  expense: number;
}

export interface ExpenseDraftItemView {
  id: string;
  expense_type: ExpenseType;
  item_name: string;
  amount: number;
  transaction_date: string;
  quantity: number | null;
  unit: string | null;
  vendor_name: string | null;
  confidence: number;
  needs_review: boolean;
}

export type ExpenseDraftStatus = 'draft' | 'failed';
export type ExpenseDraftWarning = 'ai_unavailable' | 'receipt_total_mismatch';

export interface ExpenseDraftView {
  input_id: string;
  status: ExpenseDraftStatus;
  items: ExpenseDraftItemView[];
  warnings: ExpenseDraftWarning[];
}

export interface ExpenseAiInputRow {
  id: string;
  created_by: string;
  input_text: string | null;
  image_url: string | null;
  parsed_result: unknown;
  model_name: string | null;
  status: string;
  error_message: string | null;
  confirmed_at: string | null;
  created_at: string;
}

export interface DashboardSummaryView {
  period: FinancePeriod;
  income: number;
  expense: number;
  previous_income: number;
  active_orders: number;
  series: SeriesPoint[];
}

export interface RecentOrderView {
  id: string;
  order_number: string;
  customer_name: string;
  item_count: number;
  total: number;
  status: string;
  created_at: string;
}
