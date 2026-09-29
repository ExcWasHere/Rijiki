import { z } from 'zod';

export const RegisterSchema = z.object({
  email: z.string().email('Format email tidak valid'),
  password: z.string().min(8, 'Kata sandi minimal 8 karakter'),
});
export type RegisterInput = z.infer<typeof RegisterSchema>;

export const LoginSchema = z.object({
  email: z.string().email('Format email tidak valid'),
  password: z.string().min(1, 'Kata sandi wajib diisi'),
});
export type LoginInput = z.infer<typeof LoginSchema>;

export const RefreshSchema = z.object({
  refresh_token: z.string().min(1),
});
export type RefreshInput = z.infer<typeof RefreshSchema>;

export const UpdateMeSchema = z.object({
  full_name: z.string().min(1).optional(),
  phone_number: z.string().min(8).optional(),
  avatar_url: z.string().url().optional(),
});
export type UpdateMeInput = z.infer<typeof UpdateMeSchema>;