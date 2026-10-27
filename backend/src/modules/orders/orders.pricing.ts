import { AppError } from '../../shared/errors';
import { toNumber } from '../../shared/utils/number';
import type { PromoRow } from './orders.types';

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

export function evaluatePromo(
  promo: PromoRow | null,
  base: { subtotal: number; shipping: number },
): PromoEvaluation {
  if (!promo || !promo.is_active) {
    throw promoInvalid('Kode promo tidak ditemukan atau sudah tidak berlaku.');
  }

  const today = todayWib();
  if (today < promo.start_date) throw promoInvalid('Promo ini belum dimulai.');
  if (today > promo.end_date) throw promoInvalid('Promo ini sudah berakhir.');

  const value = toNumber(promo.discount_value);
  const target = promo.applies_to === 'shipping' ? base.shipping : base.subtotal;

  const raw =
    promo.discount_type === 'percentage' ? Math.round((target * value) / 100) : Math.round(value);
  const discount = Math.min(Math.max(raw, 0), target);

  const valueLabel =
    promo.discount_type === 'percentage'
      ? `Diskon ${Number(value.toFixed(2))}%`
      : `Potongan ${formatRupiah(value)}`;

  return {
    code: promo.code,
    discount,
    description: `${promo.title} · ${valueLabel}`,
  };
}

export function computeTotals(subtotal: number, discount: number, shipping: number): PriceTotals {
  return { subtotal, discount, shipping, total: subtotal - discount + shipping };
}
