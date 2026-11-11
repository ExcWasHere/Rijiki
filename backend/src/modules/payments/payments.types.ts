export type PaymentStatusValue = 'pending' | 'paid' | 'failed' | 'expired';

export interface PaymentRow {
  id: string;
  order_id: string;
  provider_order_id: string;
  amount: number;
  status: PaymentStatusValue;
  qris_payload: string | null;
  qris_image_url: string | null;
  external_reference_id: string | null;
  expires_at: string | null;
  paid_at: string | null;
  provider_checked_at: string | null;
  created_at: string;
}

export interface PaymentOrderRow {
  id: string;
  order_number: string;
  customer_id: string | null;
  status: string;
  payment_status: string;
  total_price: number;
}

export interface PaymentView {
  id: string;
  order_id: string;
  order_number: string;
  amount: number;
  qr_payload: string;
  qr_image_url: string | null;
  status: PaymentStatusValue;
  created_at: string;
  expires_at: string;
}
