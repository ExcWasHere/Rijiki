import { z } from 'zod';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { parseInput } from '../../shared/utils/validate';
import {
  fetchTransactionStatus,
  getProviderConfig,
  grossAmountMatches,
  mapTransactionStatus,
  parseMidtransTime,
} from '../payments/midtrans.client';
import { findPaymentByProviderOrderId } from '../payments/payments.repo';
import { applyProviderResult } from '../payments/payments.service';
import type { ProviderResult } from '../payments/payments.service';
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

  const result: ProviderResult = {
    transactionStatus: payload.transaction_status,
    fraudStatus: payload.fraud_status ?? null,
    transactionId: payload.transaction_id ?? null,
    settlementTime: parseMidtransTime(payload.settlement_time),
  };

  // Signature Midtrans hanya menandatangani order_id + status_code +
  // gross_amount, jadi transaction_status/fraud_status tidak ikut
  // terautentikasi. Untuk transisi lunas, konfirmasi ulang ke API status
  // Midtrans supaya notifikasi yang diputar ulang dengan status diubah tidak
  // bisa menandai order lunas.
  const mapped = mapTransactionStatus(result.transactionStatus, result.fraudStatus);
  if (mapped === 'paid') {
    const remote = await fetchTransactionStatus(env, payment.provider_order_id).catch((err) => {
      console.error('webhook midtrans: gagal konfirmasi status lunas', err);
      return undefined;
    });
    if (remote === undefined) {
      // Provider tidak bisa dihubungi: minta Midtrans mengirim ulang nanti
      // daripada menerapkan status yang belum terkonfirmasi.
      throw new AppError(502, 'provider_unavailable', 'Gagal mengonfirmasi status pembayaran');
    }
    if (!remote || !grossAmountMatches(payment.amount, remote.grossAmount)) {
      console.error('webhook midtrans: transaksi tidak ditemukan saat konfirmasi', payload.order_id);
      return;
    }
    if (mapTransactionStatus(remote.transactionStatus, remote.fraudStatus) !== 'paid') {
      console.error(
        `webhook midtrans: klaim lunas tidak cocok dengan status provider (${remote.transactionStatus}) untuk ${payload.order_id}`,
      );
      return;
    }
    result.transactionStatus = remote.transactionStatus;
    result.fraudStatus = remote.fraudStatus;
    result.transactionId = remote.transactionId ?? result.transactionId;
    result.settlementTime = remote.settlementTime ?? result.settlementTime;
  }

  await applyProviderResult(env, payment, result);
}
