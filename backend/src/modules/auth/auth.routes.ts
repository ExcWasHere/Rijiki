import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import { AppError } from '../../shared/errors';
import type { AppEnv } from '../../shared/types/env';
import { parseInput } from '../../shared/utils/validate';
import {
  googleLoginSchema,
  loginSchema,
  refreshSchema,
  registerSchema,
  resendVerificationSchema,
  verifyEmailSchema,
} from './auth.schema';
import * as authService from './auth.service';

export const authRoutes = new Hono<AppEnv>();

authRoutes.post('/register', async (c) => {
  const input = parseInput(registerSchema, await c.req.json().catch(() => null));
  const result = await authService.register(c.env, input);
  return c.json(
    { email: result.email, message: 'Kode verifikasi 6 digit sudah dikirim ke email kamu' },
    201,
  );
});

authRoutes.post('/verify-email', async (c) => {
  const input = parseInput(verifyEmailSchema, await c.req.json().catch(() => null));
  return c.json(await authService.verifyEmail(c.env, input));
});

authRoutes.post('/resend-verification', async (c) => {
  const input = parseInput(resendVerificationSchema, await c.req.json().catch(() => null));
  await authService.resendVerification(c.env, input);
  return c.json({ message: 'Kode verifikasi baru sudah dikirim' });
});

authRoutes.post('/login', async (c) => {
  const input = parseInput(loginSchema, await c.req.json().catch(() => null));
  return c.json(await authService.login(c.env, input));
});

authRoutes.post('/google', async (c) => {
  const input = parseInput(googleLoginSchema, await c.req.json().catch(() => null));
  return c.json(await authService.loginWithGoogle(c.env, input));
});

authRoutes.post('/refresh', async (c) => {
  const input = parseInput(refreshSchema, await c.req.json().catch(() => null));
  return c.json(await authService.refresh(c.env, input));
});

authRoutes.get('/me', authMiddleware, (c) => {
  const { user, permissions, ownerBypass } = c.get('user');
  return c.json({ user, permissions, owner_bypass: ownerBypass });
});

authRoutes.post('/logout', authMiddleware, async (c) => {
  const token = c.req.header('Authorization')?.slice(7);
  if (!token) throw new AppError(401, 'unauthorized', 'Token tidak ditemukan');
  await authService.logout(c.env, token);
  return c.json({ message: 'Berhasil keluar' });
});
