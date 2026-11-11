import { z } from 'zod';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { parseInput } from '../../shared/utils/validate';
import {
  getProviderConfig,
  grossAmountMatches,
  parseMidtransTime,
} from '../payments/midtrans.client';
import { findPaymentByProviderOrderId } from '../payments/payments.repo';
import { applyProviderResult } from '../payments/payments.service';
import { verifyMidtransSignature } from './midtrans-signature.util';

const midtransNotificationSchema = z
  .object({
    order_id: z.string().min(1),
    status_code: z.coerce.string().min(1),
    gross_amount: z.coerce.string().min(1),
    signature_key: z.string().min(1),
    transaction_status: z.string().min(1),
    fraud_status: z.string().optional(),
    transaction_id: z.string().optional(),
    settlement_time: z.string().optional(),
  })
  .passthrough();

/**
 * Notifikasi pembayaran dari Midtrans. Signature yang salah ditolak; selain itu
 * (order tak dikenal, nominal beda) dicatat lalu diabaikan supaya Midtrans tidak
 * mengulang terus. Pemrosesan idempoten di database.
 */
export async function handleMidtransNotification(env: Bindings, rawBody: unknown): Promise<void> {
  const payload = parseInput(midtransNotificationSchema, rawBody);
  const { serverKey } = getProviderConfig(env);

  const valid = await verifyMidtransSignature(serverKey, payload);
  if (!valid) {
    console.error('webhook midtrans: signature tidak valid', payload.order_id);
    throw new AppError(403, 'invalid_signature', 'Signature tidak valid');
  }

  const payment = await findPaymentByProviderOrderId(env, payload.order_id);
  if (!payment) {
    // Termasuk tombol "Test notification" di dashboard Midtrans.
    console.warn('webhook midtrans: order_id tidak dikenal', payload.order_id);
    return;
  }

  if (!grossAmountMatches(payment.amount, payload.gross_amount)) {
    console.error(
      `webhook midtrans: nominal ${payload.order_id} tidak cocok (db ${payment.amount}, midtrans ${payload.gross_amount})`,
    );
    return;
  }

  await applyProviderResult(env, payment, {
    transactionStatus: payload.transaction_status,
    fraudStatus: payload.fraud_status ?? null,
    transactionId: payload.transaction_id ?? null,
    settlementTime: parseMidtransTime(payload.settlement_time),
  });
}
