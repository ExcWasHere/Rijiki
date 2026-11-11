import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { toNumber } from '../../shared/utils/number';
import type { PaymentOrderRow, PaymentRow, PaymentStatusValue } from './payments.types';

const PAYMENT_COLUMNS =
  'id, order_id, provider_order_id, amount, status, qris_payload, qris_image_url, external_reference_id, expires_at, paid_at, provider_checked_at, created_at';

function failed(label: string, message: string): AppError {
  console.error(`payments: gagal ${label}`, message);
  return new AppError(500, 'payment_failed', 'Gagal memproses pembayaran. Coba lagi ya.');
}

function toPaymentRow(raw: unknown): PaymentRow {
  const data = raw as Record<string, unknown>;
  return {
    id: data['id'] as string,
    order_id: data['order_id'] as string,
    provider_order_id: data['provider_order_id'] as string,
    amount: toNumber(data['amount']),
    status: data['status'] as PaymentStatusValue,
    qris_payload: (data['qris_payload'] as string | null) ?? null,
    qris_image_url: (data['qris_image_url'] as string | null) ?? null,
    external_reference_id: (data['external_reference_id'] as string | null) ?? null,
    expires_at: (data['expires_at'] as string | null) ?? null,
    paid_at: (data['paid_at'] as string | null) ?? null,
    provider_checked_at: (data['provider_checked_at'] as string | null) ?? null,
    created_at: data['created_at'] as string,
  };
}

export async function findOrderForPayment(
  env: Bindings,
  orderId: string,
): Promise<PaymentOrderRow | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('orders')
    .select('id, order_number, customer_id, status, payment_status, total_price')
    .eq('id', orderId)
    .maybeSingle();

  if (error) throw failed('memuat order', error.message);
  if (!data) return null;
  const row = data as unknown as Record<string, unknown>;
  return {
    id: row['id'] as string,
    order_number: String(row['order_number']),
    customer_id: (row['customer_id'] as string | null) ?? null,
    status: String(row['status']),
    payment_status: String(row['payment_status']),
    total_price: toNumber(row['total_price']),
  };
}

/** Semua percobaan bayar untuk satu order, terbaru dulu. */
export async function listPaymentsForOrder(env: Bindings, orderId: string): Promise<PaymentRow[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('payments')
    .select(PAYMENT_COLUMNS)
    .eq('order_id', orderId)
    .order('created_at', { ascending: false });

  if (error) throw failed('memuat pembayaran', error.message);
  return ((data ?? []) as unknown[]).map(toPaymentRow);
}

export async function findPaymentById(env: Bindings, id: string): Promise<PaymentRow | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('payments')
    .select(PAYMENT_COLUMNS)
    .eq('id', id)
    .maybeSingle();

  if (error) throw failed('memuat pembayaran', error.message);
  return data ? toPaymentRow(data) : null;
}

export async function findPaymentByProviderOrderId(
  env: Bindings,
  providerOrderId: string,
): Promise<PaymentRow | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('payments')
    .select(PAYMENT_COLUMNS)
    .eq('provider_order_id', providerOrderId)
    .maybeSingle();

  if (error) throw failed('memuat pembayaran', error.message);
  return data ? toPaymentRow(data) : null;
}

/**
 * Mencadangkan provider_order_id sebelum memanggil Midtrans. Mengembalikan null
 * bila id itu sudah dipakai (dua request membuat QR bersamaan).
 */
export async function insertPendingPayment(
  env: Bindings,
  params: { orderId: string; providerOrderId: string; amount: number; expiresAt: Date },
): Promise<PaymentRow | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('payments')
    .insert({
      order_id: params.orderId,
      provider: 'midtrans',
      provider_order_id: params.providerOrderId,
      method: 'qris',
      amount: params.amount,
      status: 'pending',
      expires_at: params.expiresAt.toISOString(),
    })
    .select(PAYMENT_COLUMNS)
    .single();

  if (error) {
    if (error.code === '23505') return null;
    throw failed('menyimpan pembayaran', error.message);
  }
  return toPaymentRow(data);
}

export async function saveChargeResult(
  env: Bindings,
  paymentId: string,
  params: {
    qrisPayload: string;
    qrisImageUrl: string | null;
    externalReferenceId: string;
    expiresAt: Date;
  },
): Promise<PaymentRow> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('payments')
    .update({
      qris_payload: params.qrisPayload,
      qris_image_url: params.qrisImageUrl,
      external_reference_id: params.externalReferenceId,
      expires_at: params.expiresAt.toISOString(),
    })
    .eq('id', paymentId)
    .select(PAYMENT_COLUMNS)
    .single();

  if (error) throw failed('menyimpan QR', error.message);
  return toPaymentRow(data);
}

export async function touchProviderChecked(env: Bindings, paymentId: string): Promise<void> {
  const admin = getSupabaseAdmin(env);
  const { error } = await admin
    .from('payments')
    .update({ provider_checked_at: new Date().toISOString() })
    .eq('id', paymentId);
  if (error) console.error('payments: gagal mencatat waktu cek status', error.message);
}

export interface ApplyOutcome {
  /** true bila request ini yang mengubah data (bukan pengulangan). */
  applied: boolean;
  /** Status payment setelah fungsi dijalankan. */
  status: PaymentStatusValue;
}

/**
 * Atomik dan idempoten di database (fungsi apply_payment_result): `paid` mengubah
 * payments + orders.payment_status dan mencatat pemasukan sekaligus.
 */
export async function applyPaymentResultRpc(
  env: Bindings,
  params: {
    providerOrderId: string;
    newStatus: Exclude<PaymentStatusValue, 'pending'>;
    providerRef: string | null;
    paidAt: Date | null;
  },
): Promise<ApplyOutcome> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin.rpc('apply_payment_result', {
    p_provider_order_id: params.providerOrderId,
    p_new_status: params.newStatus,
    p_provider_ref: params.providerRef,
    p_paid_at: params.paidAt ? params.paidAt.toISOString() : null,
  });

  if (error) throw failed('menerapkan hasil pembayaran', error.message);

  const result = data as { applied?: boolean; status?: string } | null;
  return {
    applied: result?.applied === true,
    status: (result?.status as PaymentStatusValue | undefined) ?? params.newStatus,
  };
}
