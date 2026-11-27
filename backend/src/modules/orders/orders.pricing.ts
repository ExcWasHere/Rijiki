import { AppError } from '../../shared/errors';
import { toNumber, toNumberOrNull } from '../../shared/utils/number';
import type { PricedLine, PromoRow, PromoUsage } from './orders.types';

export interface PromoEvaluation {
  promoId: string;
  code: string;
  appliesTo: 'subtotal' | 'shipping';
  discount: number;
  description: string;
}

export interface PriceTotals {
  subtotal: number;
  discount: number;
  shipping: number;
  total: number;
}

export interface PromoBase {
  subtotal: number;
  shipping: number;
  lines: PricedLine[];
  usage: PromoUsage;
}

export const EMPTY_USAGE: PromoUsage = { total: 0, perCustomer: 0, customerOrders: 0 };

export function todayWib(now: Date = new Date()): string {
  return new Date(now.getTime() + 7 * 60 * 60 * 1000).toISOString().slice(0, 10);
}

export function formatRupiah(value: number): string {
  return `Rp${Math.round(value)
    .toString()
    .replace(/\B(?=(\d{3})+(?!\d))/g, '.')}`;
}

function promoInvalid(message: string): AppError {
  return new AppError(400, 'promo_invalid', message);
}

export function evaluatePromo(promo: PromoRow | null, base: PromoBase): PromoEvaluation {
  if (!promo || !promo.is_active) {
    throw promoInvalid('Kode promo tidak ditemukan atau sudah tidak berlaku.');
  }

  const today = todayWib();
  if (today < promo.start_date) throw promoInvalid('Promo ini belum dimulai.');
  if (today > promo.end_date) throw promoInvalid('Promo ini sudah berakhir.');

  const minSubtotal = toNumberOrNull(promo.min_subtotal);
  if (minSubtotal !== null && base.subtotal < minSubtotal) {
    throw promoInvalid(`Minimal belanja ${formatRupiah(minSubtotal)} untuk memakai promo ini.`);
  }

  if (promo.first_order_only && base.usage.customerOrders > 0) {
    throw promoInvalid('Promo ini hanya berlaku untuk order pertama.');
  }

  const usageLimit = toNumberOrNull(promo.usage_limit);
  if (usageLimit !== null && base.usage.total >= usageLimit) {
    throw promoInvalid('Kuota promo ini sudah habis.');
  }

  const perCustomerLimit = toNumberOrNull(promo.usage_limit_per_customer);
  if (perCustomerLimit !== null && base.usage.perCustomer >= perCustomerLimit) {
    throw promoInvalid('Kamu sudah mencapai batas pemakaian promo ini.');
  }

  let target: number;
  if (promo.applies_to === 'shipping') {
    if (base.shipping <= 0) throw promoInvalid('Promo ongkir tidak berlaku untuk order tanpa ongkir.');
    target = base.shipping;
  } else {
    // Keranjang kosong: dulu promo tetap "berhasil" dengan potongan 0, jadi
    // customer mengira kodenya sah padahal harga tidak berubah.
    if (base.subtotal <= 0) {
      throw promoInvalid('Pilih layanan dulu sebelum memakai kode promo.');
    }
    const allowed = new Set((promo.promo_services ?? []).map((row) => row.service_id));
    if (allowed.size > 0 && base.lines.length > 0) {
      target = base.lines
        .filter((line) => allowed.has(line.service_id))
        .reduce((sum, line) => sum + line.amount, 0);
      if (target <= 0) {
        throw promoInvalid('Promo ini tidak berlaku untuk layanan yang kamu pilih.');
      }
    } else {
      target = base.subtotal;
    }
  }

  const value = toNumber(promo.discount_value);
  let raw =
    promo.discount_type === 'percentage' ? Math.round((target * value) / 100) : Math.round(value);

  const maxDiscount = toNumberOrNull(promo.max_discount_amount);
  const capped = maxDiscount !== null && maxDiscount > 0 && raw > maxDiscount;
  if (capped) raw = Math.round(maxDiscount);

  const discount = Math.min(Math.max(raw, 0), target);
  // Persentase kecil pada pesanan murah bisa membulat jadi 0. Tolak supaya
  // customer tidak memakai kuota promo untuk potongan nol.
  if (discount <= 0) throw promoInvalid('Promo ini tidak memberi potongan untuk pesanan ini.');

  let valueLabel =
    promo.discount_type === 'percentage'
      ? `Diskon ${Number(value.toFixed(2))}%`
      : `Potongan ${formatRupiah(value)}`;
  if (promo.discount_type === 'percentage' && maxDiscount !== null && maxDiscount > 0) {
    valueLabel += ` (maks ${formatRupiah(maxDiscount)})`;
  }
  if (promo.applies_to === 'shipping') valueLabel += ' ongkir';

  return {
    promoId: promo.id,
    code: promo.code,
    appliesTo: promo.applies_to === 'shipping' ? 'shipping' : 'subtotal',
    discount,
    description: `${promo.title} · ${valueLabel}`,
  };
}

/** Batas gabung promo: satu promo per bagian harga (layanan dan ongkir). */
export const MAX_PROMOS_PER_ORDER = 2;

/**
 * Menilai beberapa promo untuk satu order. Maksimal 1 promo layanan + 1 promo
 * ongkir; tiap promo dihitung dari harga awal bagiannya sendiri, jadi urutan
 * kode tidak memengaruhi hasil. Galat diberi awalan kode bila lebih dari satu
 * kode dikirim, supaya jelas promo mana yang ditolak.
 */
export function evaluatePromos(
  entries: Array<{ code: string; promo: PromoRow | null; usage: PromoUsage }>,
  base: Omit<PromoBase, 'usage'>,
): PromoEvaluation[] {
  if (entries.length > MAX_PROMOS_PER_ORDER) throw promoConflict();

  const seenCodes = new Set<string>();
  const seenKinds = new Set<PromoEvaluation['appliesTo']>();
  const result: PromoEvaluation[] = [];

  for (const entry of entries) {
    const code = entry.code.toUpperCase();
    if (seenCodes.has(code)) throw promoInvalid(`Kode promo ${code} sudah dipakai di order ini.`);
    seenCodes.add(code);

    let evaluation: PromoEvaluation;
    try {
      evaluation = evaluatePromo(entry.promo, { ...base, usage: entry.usage });
    } catch (err) {
      if (entries.length > 1 && err instanceof AppError) {
        throw promoInvalid(`${code}: ${err.message}`);
      }
      throw err;
    }

    if (seenKinds.has(evaluation.appliesTo)) throw promoConflict();
    seenKinds.add(evaluation.appliesTo);
    result.push(evaluation);
  }
  return result;
}

function promoConflict(): AppError {
  return promoInvalid('Hanya bisa memakai 1 promo layanan dan 1 promo ongkir dalam satu order.');
}

export function totalDiscount(evaluations: PromoEvaluation[]): number {
  return evaluations.reduce((sum, item) => sum + item.discount, 0);
}

/** Bentuk yang dikirim ke fungsi SQL pembuat order (p_promos). */
export function toRpcPromos(
  evaluations: PromoEvaluation[],
): Array<{ promo_id: string; discount_amount: number }> {
  return evaluations.map((item) => ({ promo_id: item.promoId, discount_amount: item.discount }));
}

export function computeTotals(subtotal: number, discount: number, shipping: number): PriceTotals {
  return { subtotal, discount, shipping, total: subtotal - discount + shipping };
}
