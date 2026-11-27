import { z } from 'zod';

const dateOnly = (label: string) =>
  z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, `${label} harus berformat YYYY-MM-DD`)
    .refine((value) => {
      const parsed = new Date(`${value}T00:00:00Z`);
      return !Number.isNaN(parsed.getTime()) && parsed.toISOString().slice(0, 10) === value;
    }, `${label} tidak valid`);

/** Field teks multipart `POST /api/orders/:id/rating` (foto ada di field `photo`). */
export const createRatingSchema = z.object({
  rating_value: z.coerce
    .number()
    .int('Rating harus bilangan bulat')
    .min(1, 'Pilih minimal 1 bintang')
    .max(5, 'Maksimal 5 bintang'),
  comment: z.string().trim().max(500, 'Komentar maksimal 500 karakter').optional(),
});

export const listRatingsQuerySchema = z.object({
  featured: z.enum(['true', 'false']).optional(),
  has_photo: z.enum(['true', 'false']).optional(),
  start_date: dateOnly('Tanggal mulai').optional(),
  end_date: dateOnly('Tanggal selesai').optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

export const setFeaturedSchema = z.object({
  is_featured: z.boolean(),
});

export const exportQuerySchema = z
  .object({
    source: z.enum(['testimonials', 'before_after']),
    start_date: dateOnly('Tanggal mulai').optional(),
    end_date: dateOnly('Tanggal selesai').optional(),
  })
  .superRefine((value, ctx) => {
    if (value.start_date && value.end_date && value.end_date < value.start_date) {
      ctx.addIssue({
        code: 'custom',
        message: 'Tanggal selesai tidak boleh sebelum tanggal mulai.',
      });
    }
  });

export type CreateRatingInput = z.infer<typeof createRatingSchema>;
export type ListRatingsQuery = z.infer<typeof listRatingsQuerySchema>;
export type ExportQuery = z.infer<typeof exportQuerySchema>;
