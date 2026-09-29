import type { Context, Next } from 'hono';
import { HTTPException } from 'hono/http-exception';
import type { AppEnv } from '../shared/types/env';
import type { AppPermission, AuthContextUser } from '../shared/types/user';
import { getSupabaseAdmin, getSupabaseAnon } from '../config/supabase';

export async function authMiddleware(c: Context<AppEnv>, next: Next) {
  const authHeader = c.req.header('Authorization');
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null;

  if (!token) {
    throw new HTTPException(401, { message: 'Token tidak ditemukan' });
  }

  const anon = getSupabaseAnon(c.env);
  const { data: authData, error: authError } = await anon.auth.getUser(token);

  if (authError || !authData.user) {
    throw new HTTPException(401, { message: 'Token tidak valid atau kadaluarsa' });
  }

  const admin = getSupabaseAdmin(c.env);
  const { data: profile, error: profileError } = await admin
    .from('users')
    .select(
      'id, email, role, full_name, phone_number, avatar_url, profile_completed, is_active',
    )
    .eq('id', authData.user.id)
    .single();

  if (profileError || !profile) {
    throw new HTTPException(401, { message: 'Profil pengguna tidak ditemukan' });
  }

  if (!profile.is_active) {
    throw new HTTPException(403, { message: 'Akun dinonaktifkan' });
  }

  let permissions: AppPermission[] = [];
  const ownerBypass = profile.role === 'owner';

  if (profile.role === 'worker' && !ownerBypass) {
    const { data: permRows } = await admin
      .from('worker_permissions')
      .select('permission, worker_profiles!inner(user_id)')
      .eq('worker_profiles.user_id', profile.id)
      .is('revoked_at', null);

    permissions = (permRows ?? []).map((row) => row.permission as AppPermission);
  }

  const contextUser: AuthContextUser = {
    user: profile,
    permissions,
    ownerBypass,
  };

  c.set('user', contextUser);
  await next();
}