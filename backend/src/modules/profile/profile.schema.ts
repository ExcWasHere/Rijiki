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
      .max(300, 'Alamat maksimal 300 karakter'),
    default_lat: coordinate('Latitude'),
    default_lng: coordinate('Longitude'),
  })
  .refine((v) => isInServiceArea(v.default_lat, v.default_lng), {
    message: OUT_OF_AREA_MESSAGE,
    path: ['default_lat'],
  });

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;
