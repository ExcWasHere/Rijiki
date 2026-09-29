import { HTTPException } from 'hono/http-exception';
import type { Bindings } from '../../shared/types/env';
import type { AppPermission, AppUser } from '../../shared/types/user';
import { getSupabaseAdmin, getSupabaseAnon } from '../../config/supabase';
import type { LoginInput, RefreshInput, RegisterInput, UpdateMeInput } from './auth.schema';

interface AuthSession {
  access_token: string;
  refresh_token: string;
  user: AppUser;
}

async function fetchProfile(env: Bindings, id: string): Promise<AppUser> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('users')
    .select('id, email, role, full_name, phone_number, avatar_url, profile_completed, is_active')
    .eq('id', id)
    .single();

  if (error || !data) {
    throw new HTTPException(404, { message: 'Profil pengguna tidak ditemukan' });
  }
  return data as AppUser;
}

export async function register(env: Bindings, input: RegisterInput): Promise<AuthSession> {
  const anon = getSupabaseAnon(env);
  const { data, error } = await anon.auth.signUp({
    email: input.email,
    password: input.password,
  });

  if (error) throw new HTTPException(400, { message: error.message });
  if (!data.session || !data.user) {
    throw new HTTPException(202, {
      message: 'Registrasi berhasil, silakan cek email untuk verifikasi',
    });
  }

  const profile = await fetchProfile(env, data.user.id);

  return {
    access_token: data.session.access_token,
    refresh_token: data.session.refresh_token,
    user: profile,
  };
}

export async function login(env: Bindings, input: LoginInput): Promise<AuthSession> {
  const anon = getSupabaseAnon(env);
  const { data, error } = await anon.auth.signInWithPassword({
    email: input.email,
    password: input.password,
  });

  if (error || !data.session) {
    throw new HTTPException(401, { message: 'Email atau kata sandi salah' });
  }

  const profile = await fetchProfile(env, data.user.id);

  return {
    access_token: data.session.access_token,
    refresh_token: data.session.refresh_token,
    user: profile,
  };
}

export async function refresh(env: Bindings, input: RefreshInput): Promise<AuthSession> {
  const anon = getSupabaseAnon(env);
  const { data, error } = await anon.auth.refreshSession({
    refresh_token: input.refresh_token,
  });

  if (error || !data.session || !data.user) {
    throw new HTTPException(401, { message: 'Sesi tidak valid, silakan login ulang' });
  }

  const profile = await fetchProfile(env, data.user.id);

  return {
    access_token: data.session.access_token,
    refresh_token: data.session.refresh_token,
    user: profile,
  };
}

export async function logout(env: Bindings, accessToken: string): Promise<void> {
  const anon = getSupabaseAnon(env);
  await anon.auth.admin?.signOut?.(accessToken).catch(() => undefined);
}

export async function getMe(
  env: Bindings,
  userId: string,
  role: AppUser['role'],
): Promise<{ user: AppUser; permissions: AppPermission[] }> {
  const profile = await fetchProfile(env, userId);

  if (role === 'owner') {
    const allPermissions: AppPermission[] = [
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
    ];
    return { user: profile, permissions: allPermissions };
  }

  if (role !== 'worker') {
    return { user: profile, permissions: [] };
  }

  const admin = getSupabaseAdmin(env);
  const { data: permRows } = await admin
    .from('worker_permissions')
    .select('permission, worker_profiles!inner(user_id)')
    .eq('worker_profiles.user_id', userId)
    .is('revoked_at', null);

  return {
    user: profile,
    permissions: (permRows ?? []).map((r) => r.permission as AppPermission),
  };
}

export async function updateMe(
  env: Bindings,
  userId: string,
  input: UpdateMeInput,
): Promise<AppUser> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('users')
    .update(input)
    .eq('id', userId)
    .select('id, email, role, full_name, phone_number, avatar_url, profile_completed, is_active')
    .single();

  if (error || !data) {
    throw new HTTPException(400, { message: 'Gagal memperbarui profil' });
  }
  return data as AppUser;
}