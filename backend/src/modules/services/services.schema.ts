import { z } from 'zod';

/**
 * Kategori mengikuti enum `ServiceCategory` di Flutter; nilai lain akan membuat
 * aplikasi gagal memetakan layanan, jadi ditolak di sini.
 */
export const SERVICE_CATEGORIES = ['cuci_sepatu', 'reparasi'] as const;

/**
 * Tanpa `.default()` supaya skema yang sama aman dipakai untuk PATCH (field yang
 * tidak dikirim tidak ikut menimpa). Default diterapkan di service.
 */
const serviceShape = {
  name: z.string().trim().min(1, 'Nama wajib diisi').max(60, 'Nama maksimal 60 karakter'),
  category: z.enum(SERVICE_CATEGORIES),
  base_price: z
    .number()
    .int('Harga harus bilangan bulat')
    .min(1, 'Harga harus lebih dari 0')
    .max(100_000_000, 'Harga terlalu besar'),
  description: z
    .string()
    .trim()
    .max(200, 'Deskripsi maksimal 200 karakter')
    .nullable()
    .optional(),
  estimated_duration_minutes: z
    .number()
    .int('Estimasi harus bilangan bulat')
    .min(1, 'Estimasi harus lebih dari 0')
    .max(600_000, 'Estimasi terlalu besar')
    .nullable()
    .optional(),
  is_active: z.boolean().optional(),
};

export const createServiceSchema = z.object(serviceShape);

export const updateServiceSchema = z
  .object(serviceShape)
  .partial()
  .superRefine((value, ctx) => {
    if (Object.keys(value).length === 0) {
      ctx.addIssue({ code: 'custom', message: 'Tidak ada perubahan yang dikirim.' });
    }
  });

export type CreateServiceInput = z.infer<typeof createServiceSchema>;
export type UpdateServiceInput = z.infer<typeof updateServiceSchema>;
