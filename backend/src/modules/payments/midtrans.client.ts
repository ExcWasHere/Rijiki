import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import type { PaymentStatusValue } from './payments.types';

const BASE_URLS = {
  sandbox: 'https://api.sandbox.midtrans.com',
  production: 'https://api.midtrans.com',
} as const;

/** Masa berlaku QR (keputusan: 15 menit). Dikirim sebagai custom_expiry saat charge. */
export const PAYMENT_EXPIRY_MINUTES = 15;

/** Acquirer QRIS; dikonfirmasi saat registrasi merchant (PRD Open Questions #55). */
const QRIS_ACQUIRER = 'gopay';

const REQUEST_TIMEOUT_MS = 12_000;

export function getProviderConfig(env: Bindings): { serverKey: string; baseUrl: string } {
  const serverKey = env.MIDTRANS_SERVER_KEY?.trim();
  if (!serverKey) {
    console.error('midtrans: MIDTRANS_SERVER_KEY belum diset');
    throw new AppError(500, 'payment_not_configured', 'Pembayaran belum dikonfigurasi di server.');
  }
  const mode = env.MIDTRANS_ENV === 'production' ? 'production' : 'sandbox';
  return { serverKey, baseUrl: BASE_URLS[mode] };
}

function providerError(label: string, detail: unknown): AppError {
  console.error(`midtrans: ${label}`, detail);
  return new AppError(
    502,
    'payment_provider_error',
    'Layanan pembayaran sedang bermasalah. Coba lagi sebentar ya.',
  );
}

async function callMidtrans(
  env: Bindings,
  method: 'GET' | 'POST',
  path: string,
  body?: unknown,
): Promise<Record<string, unknown>> {
  const { serverKey, baseUrl } = getProviderConfig(env);

  let response: Response;
  try {
    response = await fetch(`${baseUrl}${path}`, {
      method,
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        Authorization: `Basic ${btoa(`${serverKey}:`)}`,
      },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
    });
  } catch (err) {
    throw providerError(`${method} ${path} gagal dihubungi`, err);
  }

  const json = (await response.json().catch(() => null)) as Record<string, unknown> | null;
  if (!json || typeof json !== 'object') {
    throw providerError(`${method} ${path} balasan bukan JSON`, response.status);
  }
  return json;
}

/** Midtrans memakai format "YYYY-MM-DD HH:mm:ss" dalam WIB (GMT+7). */
export function parseMidtransTime(value: unknown): Date | null {
  if (typeof value !== 'string') return null;
  const match = /^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2})$/.exec(value.trim());
  if (!match) return null;
  const date = new Date(`${match[1]}T${match[2]}+07:00`);
  return Number.isNaN(date.getTime()) ? null : date;
}

export interface QrisCharge {
  transactionId: string;
  qrString: string;
  qrImageUrl: string | null;
  expiresAt: Date | null;
}

/** POST /v2/charge, payment_type qris (QRIS dinamis). */
export async function chargeQris(
  env: Bindings,
  params: { providerOrderId: string; amount: number },
): Promise<QrisCharge> {
  const json = await callMidtrans(env, 'POST', '/v2/charge', {
    payment_type: 'qris',
    transaction_details: {
      order_id: params.providerOrderId,
      gross_amount: params.amount,
    },
    qris: { acquirer: QRIS_ACQUIRER },
    custom_expiry: { expiry_duration: PAYMENT_EXPIRY_MINUTES, unit: 'minute' },
  });

  const statusCode = String(json['status_code'] ?? '');
  const qrString = typeof json['qr_string'] === 'string' ? json['qr_string'] : '';
  const transactionId = typeof json['transaction_id'] === 'string' ? json['transaction_id'] : '';

  if ((statusCode !== '200' && statusCode !== '201') || !qrString || !transactionId) {
    throw providerError('charge QRIS ditolak', {
      status_code: statusCode,
      status_message: json['status_message'],
      validation_messages: json['validation_messages'],
    });
  }

  const actions = Array.isArray(json['actions']) ? (json['actions'] as unknown[]) : [];
  let qrImageUrl: string | null = null;
  for (const action of actions) {
    if (action && typeof action === 'object') {
      const record = action as Record<string, unknown>;
      if (record['name'] === 'generate-qr-code' && typeof record['url'] === 'string') {
        qrImageUrl = record['url'];
        break;
      }
    }
  }

  return {
    transactionId,
    qrString,
    qrImageUrl,
    expiresAt: parseMidtransTime(json['expiry_time']),
  };
}

export interface ProviderStatus {
  transactionStatus: string;
  fraudStatus: string | null;
  transactionId: string | null;
  grossAmount: string;
  settlementTime: Date | null;
}

/** GET /v2/{order_id}/status. Mengembalikan null bila transaksinya tidak ada di Midtrans. */
export async function fetchTransactionStatus(
  env: Bindings,
  providerOrderId: string,
): Promise<ProviderStatus | null> {
  const json = await callMidtrans(env, 'GET', `/v2/${encodeURIComponent(providerOrderId)}/status`);

  if (String(json['status_code'] ?? '') === '404') return null;
  const transactionStatus = json['transaction_status'];
  if (typeof transactionStatus !== 'string') {
    throw providerError('status transaksi tidak terbaca', {
      status_code: json['status_code'],
      status_message: json['status_message'],
    });
  }

  return {
    transactionStatus,
    fraudStatus: typeof json['fraud_status'] === 'string' ? json['fraud_status'] : null,
    transactionId: typeof json['transaction_id'] === 'string' ? json['transaction_id'] : null,
    grossAmount: String(json['gross_amount'] ?? ''),
    settlementTime: parseMidtransTime(json['settlement_time']),
  };
}

/**
 * settlement -> paid, pending -> pending, expire -> expired,
 * cancel/deny/failure -> failed. refund/chargeback dan status asing -> null (diabaikan).
 */
export function mapTransactionStatus(
  transactionStatus: string,
  fraudStatus: string | null,
): PaymentStatusValue | null {
  switch (transactionStatus) {
    case 'settlement':
      return 'paid';
    case 'capture':
      return fraudStatus === null || fraudStatus === 'accept' ? 'paid' : 'pending';
    case 'pending':
      return 'pending';
    case 'expire':
      return 'expired';
    case 'cancel':
    case 'deny':
    case 'failure':
      return 'failed';
    default:
      return null;
  }
}

/** gross_amount dari Midtrans berupa string seperti "10000.00". */
export function grossAmountMatches(expected: number, gross: string): boolean {
  const value = Number.parseFloat(gross);
  return Number.isFinite(value) && Math.abs(value - expected) < 0.5;
}
