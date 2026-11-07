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

export type UpdatePointRuleInput = z.infer<typeof updatePointRuleSchema>;
export type LedgerQuery = z.infer<typeof ledgerQuerySchema>;
