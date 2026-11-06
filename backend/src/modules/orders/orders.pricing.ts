import { AppError } from '../../shared/errors';
import { toNumber, toNumberOrNull } from '../../shared/utils/number';
import type { PricedLine, PromoRow, PromoUsage } from './orders.types';

export interface PromoEvaluation {
  code: string;
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
    target = base.shipping;
  } else {
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

  let valueLabel =
    promo.discount_type === 'percentage'
      ? `Diskon ${Number(value.toFixed(2))}%`
      : `Potongan ${formatRupiah(value)}`;
  if (promo.discount_type === 'percentage' && maxDiscount !== null && maxDiscount > 0) {
    valueLabel += ` (maks ${formatRupiah(maxDiscount)})`;
  }
  if (promo.applies_to === 'shipping') valueLabel += ' ongkir';

  return {
    code: promo.code,
    discount,
    description: `${promo.title} · ${valueLabel}`,
  };
}

export function computeTotals(subtotal: number, discount: number, shipping: number): PriceTotals {
  return { subtotal, discount, shipping, total: subtotal - discount + shipping };
}
