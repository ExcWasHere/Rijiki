import { z } from 'zod';
import { OUT_OF_AREA_MESSAGE, isInServiceArea } from '../../config/service-area';

function normalizePhone(raw: string): string {
  const digits = raw.replace(/\D/g, '');
  if (digits.startsWith('62')) return digits;
  if (digits.startsWith('0')) return `62${digits.slice(1)}`;
  if (digits.startsWith('8')) return `62${digits}`;
  return digits;
}

const phoneNumber = z
  .string()
  .trim()
  .refine((v) => /^\+?[\d\s\-()]+$/.test(v), 'Nomor HP tidak valid')
  .transform(normalizePhone)
  .refine((v) => /^628\d{8,11}$/.test(v), 'Nomor HP tidak valid');

const coordinate = (label: string) =>
  z.custom<number>(
    (v) => typeof v === 'number' && Number.isFinite(v),
    `${label} harus berupa angka`,
  );

/**
 * Nama dan nomor HP berlaku untuk semua role. Alamat default hanya untuk
 * customer dan bersifat opsional saat edit: bila salah satu dari alamat/titik
 * dikirim, ketiganya wajib ada agar titik dan teks tidak pernah terpisah.
 */
export const updateProfileSchema = z
  .object({
    full_name: z
      .string()
      .trim()
      .min(1, 'Nama lengkap wajib diisi')
      .max(100, 'Nama maksimal 100 karakter'),
    phone_number: phoneNumber,
    default_address: z
      .string()
      .trim()
      .min(5, 'Alamat terlalu pendek')
      .max(300, 'Alamat maksimal 300 karakter')
      .optional(),
    default_lat: coordinate('Latitude').optional(),
    default_lng: coordinate('Longitude').optional(),
  })
  .superRefine((value, ctx) => {
    const provided = [
      value.default_address,
      value.default_lat,
      value.default_lng,
    ].filter((item) => item !== undefined);

    if (provided.length === 0) return;

    if (provided.length !== 3) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['default_address'],
        message: 'Alamat dan titik lokasi harus dikirim bersama',
      });
      return;
    }

    if (!isInServiceArea(value.default_lat!, value.default_lng!)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['default_lat'],
        message: OUT_OF_AREA_MESSAGE,
      });
    }
  });

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;

/** Paginasi riwayat profil (sepatu, rating). */
export const historyQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

export type HistoryQuery = z.infer<typeof historyQuerySchema>;
