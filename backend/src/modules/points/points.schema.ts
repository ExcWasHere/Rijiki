import { z } from 'zod';

/**
 * Hanya nilai yang bisa diubah (keputusan Segmen 2): aturan baru atau
 * penghapusan aturan tidak ada. Semua field opsional dan tanpa default
 * supaya PATCH tidak menimpa field yang tidak dikirim.
 */
export const updatePointRuleSchema = z
  .object({
    points_value: z
      .number()
      .int('Jumlah poin harus bilangan bulat')
      .min(0, 'Jumlah poin tidak boleh negatif')
      .max(100_000, 'Jumlah poin terlalu besar')
      .optional(),
    amount_unit: z
      .number()
      .positive('Satuan nominal harus lebih dari 0')
      .max(100_000_000, 'Satuan nominal terlalu besar')
      .nullable()
      .optional(),
    is_active: z.boolean().optional(),
  })
  .superRefine((value, ctx) => {
    if (Object.keys(value).length === 0) {
      ctx.addIssue({ code: 'custom', message: 'Tidak ada perubahan yang dikirim.' });
    }
  });

export const ledgerQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

const REDEMPTION_STATUSES = ['pending', 'approved', 'rejected', 'fulfilled'] as const;

export const listRedemptionsQuerySchema = z.object({
  status: z.enum(REDEMPTION_STATUSES).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

/** Customer mengajukan tukar poin; harga poin diambil server dari merchandise. */
export const createRedemptionSchema = z.object({
  merchandise_id: z.string().uuid('Merchandise tidak valid'),
});

export const processRedemptionSchema = z.object({
  status: z.enum(['approved', 'rejected', 'fulfilled']),
  notes: z.string().trim().max(300, 'Catatan maksimal 300 karakter').nullish(),
});

export const customerSearchQuerySchema = z.object({
  q: z.string().trim().min(2, 'Ketik minimal 2 karakter').max(60, 'Kata kunci terlalu panjang'),
});

export const adjustPointsSchema = z.object({
  customer_id: z.string().uuid('Customer tidak valid'),
  points_amount: z
    .number()
    .int('Jumlah poin harus bilangan bulat')
    .min(-100_000, 'Jumlah poin terlalu besar')
    .max(100_000, 'Jumlah poin terlalu besar')
    .refine((n) => n !== 0, 'Jumlah poin tidak boleh 0'),
  description: z
    .string()
    .trim()
    .min(3, 'Keterangan wajib diisi (minimal 3 karakter)')
    .max(200, 'Keterangan maksimal 200 karakter'),
});

export type UpdatePointRuleInput = z.infer<typeof updatePointRuleSchema>;
export type LedgerQuery = z.infer<typeof ledgerQuerySchema>;
export type ListRedemptionsQuery = z.infer<typeof listRedemptionsQuerySchema>;
export type CreateRedemptionInput = z.infer<typeof createRedemptionSchema>;
export type ProcessRedemptionInput = z.infer<typeof processRedemptionSchema>;
export type CustomerSearchQuery = z.infer<typeof customerSearchQuerySchema>;
export type AdjustPointsInput = z.infer<typeof adjustPointsSchema>;
