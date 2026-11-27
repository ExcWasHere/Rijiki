import { z } from 'zod';

/**
 * Tanpa `.default()` supaya skema yang sama aman dipakai untuk PATCH
 * (field yang tidak dikirim tidak ikut menimpa). Default diterapkan di service.
 * points_cost / stock_quantity bernilai null = dikosongkan.
 */
const merchandiseShape = {
  name: z.string().trim().min(1, 'Nama wajib diisi').max(60, 'Nama maksimal 60 karakter'),
  description: z.string().trim().max(200, 'Deskripsi maksimal 200 karakter').nullable().optional(),
  price: z
    .number()
    .int('Harga harus bilangan bulat')
    .min(1, 'Harga harus lebih dari 0')
    .max(100_000_000, 'Harga terlalu besar'),
  points_cost: z
    .number()
    .int('Poin harus bilangan bulat')
    .min(1, 'Poin harus lebih dari 0')
    .max(1_000_000, 'Poin terlalu besar')
    .nullable()
    .optional(),
  stock_quantity: z
    .number()
    .int('Stok harus bilangan bulat')
    .min(0, 'Stok tidak boleh negatif')
    .max(1_000_000, 'Stok terlalu besar')
    .nullable()
    .optional(),
  image_url: z.string().trim().url('URL gambar tidak valid').max(500).nullable().optional(),
  is_active: z.boolean().optional(),
};

export const createMerchandiseSchema = z.object(merchandiseShape);

export const updateMerchandiseSchema = z
  .object(merchandiseShape)
  .partial()
  .superRefine((value, ctx) => {
    if (Object.keys(value).length === 0) {
      ctx.addIssue({ code: 'custom', message: 'Tidak ada perubahan yang dikirim.' });
    }
  });

export type CreateMerchandiseInput = z.infer<typeof createMerchandiseSchema>;
export type UpdateMerchandiseInput = z.infer<typeof updateMerchandiseSchema>;
