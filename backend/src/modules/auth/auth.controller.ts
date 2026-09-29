import type { Context } from 'hono';
import type { AppEnv } from '../../shared/types/env';
import { ok } from '../../shared/utils/response';
import * as authService from './auth.service';
import type { LoginInput, RefreshInput, RegisterInput, UpdateMeInput } from './auth.schema';

export async function registerHandler(c: Context<AppEnv>) {
  const input = c.get('validatedBody') as RegisterInput;
  const session = await authService.register(c.env, input);
  return c.json(ok(session), 201);
}

export async function loginHandler(c: Context<AppEnv>) {
  const input = c.get('validatedBody') as LoginInput;
  const session = await authService.login(c.env, input);
  return c.json(ok(session));
}

export async function refreshHandler(c: Context<AppEnv>) {
  const input = c.get('validatedBody') as RefreshInput;
  const session = await authService.refresh(c.env, input);
  return c.json(ok(session));
}

export async function logoutHandler(c: Context<AppEnv>) {
  const authHeader = c.req.header('Authorization');
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : '';
  await authService.logout(c.env, token);
  return c.json(ok({ message: 'Berhasil logout' }));
}

export async function getMeHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const result = await authService.getMe(c.env, ctx.user.id, ctx.user.role);
  return c.json(ok(result));
}

export async function updateMeHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const input = c.get('validatedBody') as UpdateMeInput;
  const user = await authService.updateMe(c.env, ctx.user.id, input);
  return c.json(ok({ user }));
}