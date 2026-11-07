import { z } from 'zod';
import type { AppPermission } from '../../shared/types/user';

const dateOnly = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'Tanggal bergabung harus berformat YYYY-MM-DD')
  .refine((value) => {
    const parsed = new Date(`${value}T00:00:00Z`);
    return !Number.isNaN(parsed.getTime()) && parsed.toISOString().slice(0, 10) === value;
  }, 'Tanggal bergabung tidak valid');

/**
 * Tanpa default/transform pada field opsional: bentuk yang sama dipakai untuk
 * PATCH (semua field opsional), dan default akan menimpa nilai yang tidak dikirim.
 */
const workerShape = {
  full_name: z.string().trim().min(1, 'Nama wajib diisi').max(80, 'Nama maksimal 80 karakter'),
  email: z.string().trim().toLowerCase().email('Email tidak valid').max(120, 'Email terlalu panjang'),
  phone_number: z
    .string()
    .trim()
    .regex(/^\+?[0-9][0-9\s-]{6,17}$/, 'Nomor HP tidak valid'),
  employee_code: z
    .string()
    .trim()
    .min(2, 'Kode pegawai minimal 2 karakter')
    .max(20, 'Kode pegawai maksimal 20 karakter'),
  division: z.string().trim().min(1, 'Divisi wajib diisi').max(40, 'Divisi maksimal 40 karakter'),
  join_date: dateOnly,
  password: z.string().min(8, 'Password minimal 8 karakter').max(72, 'Password maksimal 72 karakter'),
};

export const createWorkerSchema = z.object(workerShape);

export const updateWorkerSchema = z
  .object({ ...workerShape, is_active: z.boolean() })
  .partial()
  .superRefine((value, ctx) => {
    if (Object.keys(value).length === 0) {
      ctx.addIssue({ code: 'custom', message: 'Tidak ada perubahan yang dikirim.' });
    }
  });

export const APP_PERMISSIONS = [
  'manage_orders_all',
  'manage_cms_services',
  'manage_cms_events',
  'manage_cms_promos',
  'manage_cms_merchandise',
  'manage_testimonials',
  'manage_finance',
  'manage_workers',
  'manage_points',
  'view_analytics',
] as const satisfies readonly AppPermission[];

/** Daftar lengkap izin yang diinginkan; backend menghitung selisih pemberian dan pencabutan. */
export const setPermissionsSchema = z.object({
  permissions: z.array(z.enum(APP_PERMISSIONS)).max(APP_PERMISSIONS.length),
});

export type CreateWorkerInput = z.infer<typeof createWorkerSchema>;
export type UpdateWorkerInput = z.infer<typeof updateWorkerSchema>;
