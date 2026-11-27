export interface RepeatCustomerView {
  /** Kunci kelompok: `c:<customer_profile_id>` untuk akun, `p:<nomor HP>` untuk pelanggan offline. */
  id: string;
  name: string;
  phone: string | null;
  avatar_url: string | null;
  completed_orders: number;
  total_spent: number;
  last_order_at: string | null;
  /** false = pelanggan offline yang belum punya akun. */
  has_account: boolean;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type CustomerRow = Record<string, any>;
