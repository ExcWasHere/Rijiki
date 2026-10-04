import { z } from 'zod';
const email = z.string().trim().toLowerCase().email('Format email tidak valid');

const newPassword = z
  .string()
  .min(8, 'Password minimal 8 karakter')
  .max(72, 'Password maksimal 72 karakter');

export const registerSchema = z.object({ email, password: newPassword });

export const loginSchema = z.object({
  email,
  password: z.string().min(1, 'Password wajib diisi'),
});

export const verifyEmailSchema = z.object({
  email,
  code: z.string().regex(/^\d{6}$/, 'Kode verifikasi harus 6 digit angka'),
});

export const resendVerificationSchema = z.object({ email });

export const googleLoginSchema = z.object({
  id_token: z.string().min(20, 'Token Google tidak valid'),
});

export const refreshSchema = z.object({
  refresh_token: z.string().min(1, 'refresh_token wajib diisi'),
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type VerifyEmailInput = z.infer<typeof verifyEmailSchema>;
export type ResendVerificationInput = z.infer<typeof resendVerificationSchema>;
export type GoogleLoginInput = z.infer<typeof googleLoginSchema>;
export type RefreshInput = z.infer<typeof refreshSchema>;
