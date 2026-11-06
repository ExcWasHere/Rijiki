import { z } from 'zod';

const dateOnly = (label: string) =>
  z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, `${label} harus berformat YYYY-MM-DD`)
    .refine((value) => {
      const parsed = new Date(`${value}T00:00:00Z`);
      return !Number.isNaN(parsed.getTime()) && parsed.toISOString().slice(0, 10) === value;
    }, `${label} tidak valid`);

/**
 * Sengaja tanpa `.default()` dan tanpa transform pada field opsional: skema yang
 * sama dipakai untuk PATCH (semua field opsional), dan default/transform akan
 * ikut menimpa nilai yang tidak dikirim. Default diterapkan di service.
 */
const promoShape = {
  code: z
    .string()
    .trim()
    .min(3, 'Kode minimal 3 karakter')
    .max(20, 'Kode maksimal 20 karakter')
    .regex(/^[A-Za-z0-9]+$/, 'Kode hanya boleh huruf dan angka')
    .transform((v) => v.toUpperCase()),
  title: z.string().trim().min(1, 'Judul wajib diisi').max(60, 'Judul maksimal 60 karakter'),
  description: z.string().trim().max(200, 'Deskripsi maksimal 200 karakter').nullable().optional(),
  discount_type: z.enum(['percentage', 'fixed']),
  discount_value: z
    .number()
    .int('Nilai diskon harus bilangan bulat')
    .min(1, 'Nilai diskon minimal 1')
    .max(100_000_000, 'Nilai diskon terlalu besar'),
  start_date: dateOnly('Tanggal mulai'),
  end_date: dateOnly('Tanggal selesai'),
  is_active: z.boolean().optional(),
  applies_to: z.enum(['subtotal', 'shipping']).optional(),
  min_subtotal: z
    .number()
    .int('Minimal belanja harus bilangan bulat')
    .min(0, 'Minimal belanja tidak valid')
    .max(100_000_000)
    .nullable()
    .optional(),
  max_discount_amount: z
    .number()
    .int('Batas potongan harus bilangan bulat')
    .min(1, 'Batas potongan minimal 1')
    .max(100_000_000)
    .nullable()
    .optional(),
  usage_limit: z
    .number()
    .int('Kuota harus bilangan bulat')
    .min(1, 'Kuota minimal 1')
    .max(1_000_000)
    .nullable()
    .optional(),
  usage_limit_per_customer: z
    .number()
    .int('Kuota per customer harus bilangan bulat')
    .min(1, 'Kuota per customer minimal 1')
    .max(1_000)
    .nullable()
    .optional(),
  first_order_only: z.boolean().optional(),
  service_ids: z.array(z.string().uuid('Layanan tidak valid')).max(50, 'Terlalu banyak layanan').optional(),
};

export interface PromoShapeCheck {
  discount_type?: string;
  discount_value?: number;
  start_date?: string;
  end_date?: string;
  applies_to?: string;
  service_ids?: string[];
}

/** Aturan antar-field. Mengembalikan pesan galat pertama, atau null bila lolos. */
export function validatePromoShape(shape: PromoShapeCheck): string | null {
  if (
    shape.discount_type === 'percentage' &&
    shape.discount_value !== undefined &&
    shape.discount_value > 100
  ) {
    return 'Diskon persen maksimal 100%.';
  }
  if (shape.start_date && shape.end_date && shape.end_date < shape.start_date) {
    return 'Tanggal selesai tidak boleh sebelum tanggal mulai.';
  }
  if (shape.applies_to === 'shipping' && (shape.service_ids?.length ?? 0) > 0) {
    return 'Pembatasan layanan hanya untuk promo potongan layanan, bukan ongkir.';
  }
  return null;
}

export const createPromoSchema = z.object(promoShape).superRefine((value, ctx) => {
  const message = validatePromoShape(value);
  if (message) ctx.addIssue({ code: 'custom', message });
});

export const updatePromoSchema = z
  .object(promoShape)
  .partial()
  .superRefine((value, ctx) => {
    if (Object.keys(value).length === 0) {
      ctx.addIssue({ code: 'custom', message: 'Tidak ada perubahan yang dikirim.' });
      return;
    }
    // Aturan yang melibatkan field di database digabung ulang di service.
    const message = validatePromoShape(value);
    if (message) ctx.addIssue({ code: 'custom', message });
  });

export type CreatePromoInput = z.infer<typeof createPromoSchema>;
export type UpdatePromoInput = z.infer<typeof updatePromoSchema>;
