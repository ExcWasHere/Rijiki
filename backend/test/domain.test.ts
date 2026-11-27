import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { verifyMidtransSignature } from '../src/modules/webhooks/midtrans-signature.util.ts';
import { mapTransactionStatus, grossAmountMatches } from '../src/modules/payments/midtrans.client.ts';
import {
  evaluatePromo,
  evaluatePromos,
  computeTotals,
  EMPTY_USAGE,
} from '../src/modules/orders/orders.pricing.ts';
import type { PromoRow } from '../src/modules/orders/orders.types.ts';
import {
  isClaimable,
  nextStatusOf,
  flowFor,
  isFinalStatus,
  canUploadDocumentation,
} from '../src/modules/orders/orders.transitions.ts';
import { canViewOrder } from '../src/modules/orders/orders.access.ts';
import { parseIdempotencyKey } from '../src/shared/utils/idempotency.ts';
import { AppError } from '../src/shared/errors.ts';

const SERVER_KEY = 'SB-Mid-server-test';

function promo(overrides: Partial<PromoRow> = {}): PromoRow {
  return {
    id: 'promo-1',
    code: 'HEMAT',
    title: 'Hemat',
    discount_type: 'percentage',
    discount_value: 10,
    start_date: '2020-01-01',
    end_date: '2099-12-31',
    is_active: true,
    applies_to: 'subtotal',
    min_subtotal: null,
    max_discount_amount: null,
    usage_limit: null,
    usage_limit_per_customer: null,
    first_order_only: false,
    promo_services: null,
    ...overrides,
  };
}

const base = { subtotal: 100_000, shipping: 10_000, lines: [] };

describe('signature webhook Midtrans', () => {
  it('menerima signature yang benar', async () => {
    const payload = { order_id: 'RJK-1-P1', status_code: '200', gross_amount: '50000.00' };
    const signature_key = await computeSignature(payload);
    assert.equal(await verifyMidtransSignature(SERVER_KEY, { ...payload, signature_key }), true);
  });

  it('menolak signature dengan server key lain', async () => {
    const payload = { order_id: 'RJK-1-P1', status_code: '200', gross_amount: '50000.00' };
    const signature_key = await computeSignature(payload, 'SB-Mid-server-lain');
    assert.equal(await verifyMidtransSignature(SERVER_KEY, { ...payload, signature_key }), false);
  });

  it('menolak signature yang diubah sebagian', async () => {
    const payload = { order_id: 'RJK-1-P1', status_code: '200', gross_amount: '50000.00' };
    const signature_key = await computeSignature(payload);
    const tampered = signature_key.slice(0, -1) + (signature_key.endsWith('a') ? 'b' : 'a');
    assert.equal(await verifyMidtransSignature(SERVER_KEY, { ...payload, signature_key: tampered }), false);
  });

  it('menolak signature dengan panjang berbeda', async () => {
    const payload = { order_id: 'RJK-1-P1', status_code: '200', gross_amount: '50000.00' };
    assert.equal(await verifyMidtransSignature(SERVER_KEY, { ...payload, signature_key: 'abc' }), false);
  });

  async function computeSignature(
    payload: { order_id: string; status_code: string; gross_amount: string },
    key = SERVER_KEY,
  ): Promise<string> {
    const data = new TextEncoder().encode(
      `${payload.order_id}${payload.status_code}${payload.gross_amount}${key}`,
    );
    const digest = await crypto.subtle.digest('SHA-512', data);
    return Array.from(new Uint8Array(digest))
      .map((b) => b.toString(16).padStart(2, '0'))
      .join('');
  }
});

describe('pemetaan status Midtrans', () => {
  it('settlement menjadi paid, expire menjadi expired', () => {
    assert.equal(mapTransactionStatus('settlement', null), 'paid');
    assert.equal(mapTransactionStatus('expire', null), 'expired');
    assert.equal(mapTransactionStatus('cancel', null), 'failed');
    assert.equal(mapTransactionStatus('pending', null), 'pending');
  });

  it('capture hanya paid bila fraud accept', () => {
    assert.equal(mapTransactionStatus('capture', 'accept'), 'paid');
    assert.equal(mapTransactionStatus('capture', 'challenge'), 'pending');
    assert.equal(mapTransactionStatus('capture', 'deny'), 'pending');
  });

  it('status asing diabaikan', () => {
    assert.equal(mapTransactionStatus('refund', null), null);
  });

  it('nominal harus cocok dalam toleransi setengah rupiah', () => {
    assert.equal(grossAmountMatches(50_000, '50000.00'), true);
    assert.equal(grossAmountMatches(50_000, '50001.00'), false);
    assert.equal(grossAmountMatches(50_000, 'tidak-angka'), false);
  });
});

describe('harga dan promo', () => {
  it('diskon persen tidak pernah melebihi subtotal', () => {
    const result = evaluatePromo(promo({ discount_value: 150 }), { ...base, usage: EMPTY_USAGE });
    assert.equal(result.discount, 100_000);
  });

  it('max_discount_amount membatasi diskon persen', () => {
    const result = evaluatePromo(promo({ discount_value: 50, max_discount_amount: 15_000 }), {
      ...base,
      usage: EMPTY_USAGE,
    });
    assert.equal(result.discount, 15_000);
  });

  it('promo ongkir hanya sebesar ongkir', () => {
    const result = evaluatePromo(
      promo({ applies_to: 'shipping', discount_type: 'fixed', discount_value: 99_000 }),
      { ...base, usage: EMPTY_USAGE },
    );
    assert.equal(result.discount, 10_000);
  });

  it('promo ongkir ditolak bila order tanpa ongkir', () => {
    assert.throws(
      () =>
        evaluatePromo(promo({ applies_to: 'shipping', discount_type: 'fixed', discount_value: 1000 }), {
          ...base,
          shipping: 0,
          usage: EMPTY_USAGE,
        }),
      AppError,
    );
  });

  it('promo nonaktif dan kuota habis ditolak', () => {
    assert.throws(() => evaluatePromo(promo({ is_active: false }), { ...base, usage: EMPTY_USAGE }), AppError);
    assert.throws(
      () => evaluatePromo(promo({ usage_limit: 5 }), { ...base, usage: { total: 5, perCustomer: 0, customerOrders: 0 } }),
      AppError,
    );
    assert.throws(
      () =>
        evaluatePromo(promo({ usage_limit_per_customer: 1 }), {
          ...base,
          usage: { total: 1, perCustomer: 1, customerOrders: 1 },
        }),
      AppError,
    );
  });

  it('promo first_order_only ditolak untuk customer yang sudah pernah order', () => {
    assert.throws(
      () =>
        evaluatePromo(promo({ first_order_only: true }), {
          ...base,
          usage: { total: 0, perCustomer: 0, customerOrders: 1 },
        }),
      AppError,
    );
  });

  it('satu promo layanan + satu promo ongkir boleh berdampingan', () => {
    const result = evaluatePromos(
      [
        { code: 'HEMAT', promo: promo(), usage: EMPTY_USAGE },
        {
          code: 'ONGKIR',
          promo: promo({ id: 'promo-2', applies_to: 'shipping', discount_type: 'fixed', discount_value: 5_000 }),
          usage: EMPTY_USAGE,
        },
      ],
      base,
    );
    assert.equal(result.length, 2);
  });

  it('dua promo untuk bagian harga yang sama ditolak', () => {
    assert.throws(
      () =>
        evaluatePromos(
          [
            { code: 'A', promo: promo(), usage: EMPTY_USAGE },
            { code: 'B', promo: promo({ id: 'promo-2' }), usage: EMPTY_USAGE },
          ],
          base,
        ),
      AppError,
    );
  });

  it('promo ditolak saat keranjang belum berisi layanan', () => {
    // Tanpa item, potongan selalu 0; dulu kode tetap "diterima" sehingga
    // customer tidak tahu kenapa harga tidak berubah.
    assert.throws(
      () => evaluatePromo(promo(), { subtotal: 0, shipping: 10_000, lines: [], usage: EMPTY_USAGE }),
      (err: unknown) => err instanceof AppError && /Pilih layanan dulu/.test(err.message),
    );
  });

  it('promo yang potongannya membulat jadi nol ditolak', () => {
    assert.throws(
      () =>
        evaluatePromo(promo({ discount_value: 1 }), {
          subtotal: 40,
          shipping: 0,
          lines: [{ service_id: 'svc-1', amount: 40 }],
          usage: EMPTY_USAGE,
        }),
      (err: unknown) => err instanceof AppError && /tidak memberi potongan/.test(err.message),
    );
  });

  it('promo khusus layanan ditolak bila layanan itu tidak ada di keranjang', () => {
    assert.throws(
      () =>
        evaluatePromo(promo({ promo_services: [{ service_id: 'svc-lain' }] }), {
          subtotal: 40_000,
          shipping: 0,
          lines: [{ service_id: 'svc-dipilih', amount: 40_000 }],
          usage: EMPTY_USAGE,
        }),
      (err: unknown) => err instanceof AppError && /tidak berlaku untuk layanan/.test(err.message),
    );
  });

  it('promo khusus layanan hanya memotong layanan yang dipilih', () => {
    const result = evaluatePromo(promo({ promo_services: [{ service_id: 'svc-a' }] }), {
      subtotal: 90_000,
      shipping: 0,
      lines: [
        { service_id: 'svc-a', amount: 40_000 },
        { service_id: 'svc-b', amount: 50_000 },
      ],
      usage: EMPTY_USAGE,
    });
    assert.equal(result.discount, 4_000);
  });

  it('total = subtotal - diskon + ongkir', () => {
    assert.deepEqual(computeTotals(100_000, 15_000, 10_000), {
      subtotal: 100_000,
      discount: 15_000,
      shipping: 10_000,
      total: 95_000,
    });
  });
});

describe('alur status order', () => {
  const online = {
    status: 'order' as const,
    channel: 'customer_app',
    delivery_method: 'delivery' as const,
    payment_status: 'unpaid',
    assigned_worker_id: null,
  };

  it('order aplikasi berjalan order -> pickup -> ... -> completed', () => {
    assert.equal(nextStatusOf(online), 'pickup');
    assert.equal(nextStatusOf({ ...online, status: 'pickup' }), 'waiting');
    assert.equal(nextStatusOf({ ...online, status: 'delivery' }), 'completed');
  });

  it('status akhir tidak punya langkah berikutnya', () => {
    assert.equal(nextStatusOf({ ...online, status: 'completed' }), null);
    assert.equal(nextStatusOf({ ...online, status: 'cancelled' }), null);
    assert.equal(isFinalStatus('completed'), true);
    assert.equal(isFinalStatus('cleaning'), false);
  });

  it('order offline pickup tidak melewati tahap delivery', () => {
    const offlinePickup = {
      ...online,
      channel: 'staff_manual',
      delivery_method: 'self_pickup' as const,
      status: 'cleaning' as const,
    };
    assert.deepEqual(flowFor(offlinePickup), ['waiting', 'cleaning', 'completed']);
    assert.equal(nextStatusOf(offlinePickup), 'completed');
  });

  it('hanya order aplikasi tanpa worker pada status order yang bisa diambil', () => {
    assert.equal(isClaimable(online), true);
    assert.equal(isClaimable({ ...online, status: 'pickup' }), false);
    assert.equal(isClaimable({ ...online, assigned_worker_id: 'w1' }), false);
    assert.equal(isClaimable({ ...online, channel: 'staff_manual' }), false);
  });

  it('foto hanya bisa diunggah worker penangan pada jendela statusnya', () => {
    const viewer = { role: 'worker' as const, manageAll: false, workerProfileId: 'w1' };
    assert.equal(
      canUploadDocumentation({ ...online, status: 'cleaning', assigned_worker_id: 'w1' }, viewer, 'after'),
      true,
    );
    assert.equal(
      canUploadDocumentation({ ...online, status: 'cleaning', assigned_worker_id: 'w2' }, viewer, 'after'),
      false,
    );
  });
});

describe('cakupan order per peran', () => {
  const row = {
    id: 'o1',
    status: 'order',
    channel: 'customer_app',
    delivery_method: 'delivery',
    payment_status: 'unpaid',
    assigned_worker_id: null,
    customer_id: 'c1',
  } as never;

  it('customer hanya melihat order miliknya', () => {
    const own = { scope: { kind: 'customer', customerProfileId: 'c1' }, viewer: {} } as never;
    const other = { scope: { kind: 'customer', customerProfileId: 'c2' }, viewer: {} } as never;
    assert.equal(canViewOrder(row, own), true);
    assert.equal(canViewOrder(row, other), false);
  });

  it('worker boleh melihat order yang masih bisa diambil, tetapi bukan order customer lain yang sudah jalan', () => {
    const worker = {
      scope: { kind: 'worker', workerProfileId: 'w1' },
      viewer: { role: 'worker', manageAll: false, workerProfileId: 'w1' },
    } as never;
    assert.equal(canViewOrder(row, worker), true);
    assert.equal(canViewOrder({ ...row, status: 'pickup' } as never, worker), false);
  });

  it('pemegang manage_orders_all dan owner melihat semua', () => {
    const all = { scope: { kind: 'all' }, viewer: {} } as never;
    assert.equal(canViewOrder(row, all), true);
  });
});

describe('kunci idempotensi', () => {
  it('menerima 8-64 karakter aman', () => {
    assert.equal(parseIdempotencyKey('abcd1234'), 'abcd1234');
    assert.equal(parseIdempotencyKey('A_b-1234567890'), 'A_b-1234567890');
  });

  it('null/kosong berarti tanpa kunci', () => {
    assert.equal(parseIdempotencyKey(null), null);
    assert.equal(parseIdempotencyKey('   '), null);
  });

  it('menolak kunci terlalu pendek atau berisi karakter aneh', () => {
    assert.throws(() => parseIdempotencyKey('short'), AppError);
    assert.throws(() => parseIdempotencyKey('has space in it'), AppError);
    assert.throws(() => parseIdempotencyKey('x'.repeat(65)), AppError);
  });
});
