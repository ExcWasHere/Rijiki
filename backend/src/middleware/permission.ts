import type { Context, Next } from 'hono';
import { HTTPException } from 'hono/http-exception';
import type { AppEnv } from '../shared/types/env';
import type { AppPermission } from '../shared/types/user';

export function requirePermission(permission: AppPermission) {
  return async (c: Context<AppEnv>, next: Next) => {
    const ctx = c.get('user');

    if (ctx.ownerBypass) {
      await next();
      return;
    }

    if (ctx.user.role !== 'worker' || !ctx.permissions.includes(permission)) {
      throw new HTTPException(403, {
        message: `Tidak punya izin '${permission}'`,
      });
    }

    await next();
  };
}

export function requireOwner() {
  return async (c: Context<AppEnv>, next: Next) => {
    const ctx = c.get('user');
    if (!ctx.ownerBypass) {
      throw new HTTPException(403, { message: 'Khusus Owner' });
    }
    await next();
  };
}