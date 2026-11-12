import { z } from 'zod';

const dateOnly = (label: string) =>
  z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, `${label} harus berformat YYYY-MM-DD`)
    .refine((value) => {
      const parsed = new Date(`${value}T00:00:00Z`);
      return !Number.isNaN(parsed.getTime()) && parsed.toISOString().slice(0, 10) === value;
    }, `${label} tidak valid`);

const EVENT_TYPES = ['promo', 'collaboration', 'announcement'] as const;

/**
 * Tanpa `.default()` supaya skema yang sama aman dipakai untuk PATCH
 * (field yang tidak dikirim tidak ikut menimpa). Default diterapkan di service.
 */
const eventShape = {
  title: z.string().trim().min(1, 'Judul wajib diisi').max(80, 'Judul maksimal 80 karakter'),
  event_type: z.enum(EVENT_TYPES),
  description: z.string().trim().max(300, 'Deskripsi maksimal 300 karakter').nullable().optional(),
  banner_image_url: z.string().trim().url('URL banner tidak valid').max(500).nullable().optional(),
  related_promo_id: z.string().uuid('Promo tidak valid').nullable().optional(),
  start_date: dateOnly('Tanggal mulai').nullable().optional(),
  end_date: dateOnly('Tanggal selesai').nullable().optional(),
  is_published: z.boolean().optional(),
};

export function validateEventDates(
  start: string | null | undefined,
  end: string | null | undefined,
): string | null {
  if (start && end && end < start) return 'Tanggal selesai tidak boleh sebelum tanggal mulai.';
  return null;
}

export const createEventSchema = z.object(eventShape).superRefine((value, ctx) => {
  const message = validateEventDates(value.start_date, value.end_date);
  if (message) ctx.addIssue({ code: 'custom', message });
});

export const updateEventSchema = z
  .object(eventShape)
  .partial()
  .superRefine((value, ctx) => {
    if (Object.keys(value).length === 0) {
      ctx.addIssue({ code: 'custom', message: 'Tidak ada perubahan yang dikirim.' });
      return;
    }
    const message = validateEventDates(value.start_date, value.end_date);
    if (message) ctx.addIssue({ code: 'custom', message });
  });

export const listEventsQuerySchema = z.object({
  event_type: z.enum(EVENT_TYPES).optional(),
});

export type CreateEventInput = z.infer<typeof createEventSchema>;
export type UpdateEventInput = z.infer<typeof updateEventSchema>;
export type ListEventsQuery = z.infer<typeof listEventsQuerySchema>;
