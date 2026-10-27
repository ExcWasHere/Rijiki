import { z } from 'zod';
import { DOCUMENTATION_TYPES, ORDER_STATUSES } from './orders.types';

const promoCode = z
  .string()
  .trim()
  .min(1, 'Kode promo tidak boleh kosong')
  .max(32, 'Kode promo terlalu panjang')
  .regex(/^[A-Za-z0-9_-]+$/, 'Kode promo tidak valid')
  .transform((v) => v.toUpperCase());

const address = (label: string) =>
  z
    .string()
    .trim()
    .min(5, `${label} terlalu pendek`)
    .max(300, `${label} maksimal 300 karakter`);

/**
 * Quote bersifat informatif untuk layar ringkasan. Subtotal dari klien
 * hanya dipakai untuk menghitung diskon; harga final selalu dihitung ulang
 * dari database saat order dibuat.
 */
export const quoteOrderSchema = z.object({
  subtotal: z
    .number()
    .int('Subtotal harus bilangan bulat')
    .min(0, 'Subtotal tidak valid')
    .max(100_000_000, 'Subtotal terlalu besar'),
  promo_code: promoCode.nullish(),
});

const orderItemSchema = z.object({
  service_id: z.string().uuid('Layanan tidak valid'),
  shoe_brand: z
    .string()
    .trim()
    .min(1, 'Merk sepatu wajib diisi')
    .max(60, 'Merk sepatu maksimal 60 karakter'),
  quantity: z
    .number()
    .int('Jumlah harus bilangan bulat')
    .min(1, 'Jumlah minimal 1')
    .max(10, 'Jumlah maksimal 10 per item'),
  notes: z
    .string()
    .trim()
    .max(300, 'Catatan maksimal 300 karakter')
    .nullish()
    .transform((v) => (v && v.length > 0 ? v : null)),
});

/**
 * Nama dan nomor HP sengaja tidak ada di sini: order online selalu memakai
 * data dari profil akun (keputusan tahap A). Field tambahan dari klien
 * otomatis dibuang oleh zod.
 */
export const createOrderSchema = z.object({
  items: z
    .array(orderItemSchema)
    .min(1, 'Pilih minimal satu layanan')
    .max(5, 'Maksimal 5 item per order'),
  pickup_address: address('Alamat penjemputan'),
  delivery_address: address('Alamat pengantaran'),
  promo_code: promoCode.nullish(),
});

export const listOrdersQuerySchema = z.object({
  status: z.enum(ORDER_STATUSES).optional(),
  active: z.enum(['true', 'false']).optional(),
  /** true = order aktif yang belum punya worker (antrean untuk worker, daftar "belum di-assign" untuk owner). */
  unassigned: z.enum(['true', 'false']).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

export const updateStatusSchema = z.object({
  new_status: z.enum(ORDER_STATUSES),
  notes: z.string().trim().max(300, 'Catatan maksimal 300 karakter').nullish(),
});

export const assignOrderSchema = z.object({
  /** worker_profiles.id; null = lepas assign. */
  worker_id: z.string().uuid('Worker tidak valid').nullable(),
});

/** Field teks pada multipart upload dokumentasi (file ada di field `image`). */
export const documentationFieldsSchema = z.object({
  type: z.enum(DOCUMENTATION_TYPES),
  order_item_id: z.string().uuid('Item order tidak valid').optional(),
});

export type QuoteOrderInput = z.infer<typeof quoteOrderSchema>;
export type CreateOrderInput = z.infer<typeof createOrderSchema>;
export type ListOrdersQuery = z.infer<typeof listOrdersQuerySchema>;
export type UpdateStatusInput = z.infer<typeof updateStatusSchema>;
export type AssignOrderInput = z.infer<typeof assignOrderSchema>;
export type DocumentationFieldsInput = z.infer<typeof documentationFieldsSchema>;
