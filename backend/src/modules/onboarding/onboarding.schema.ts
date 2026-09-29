import { z } from 'zod';

export const CompleteOnboardingSchema = z.object({
  full_name: z.string().min(1, 'Nama lengkap wajib diisi'),
  phone_number: z
    .string()
    .regex(/^08[0-9]{8,11}$/, 'Nomor HP tidak valid'),
});
export type CompleteOnboardingInput = z.infer<typeof CompleteOnboardingSchema>;