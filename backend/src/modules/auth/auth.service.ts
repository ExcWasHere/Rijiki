import type { AuthError } from '@supabase/supabase-js';
import { getSupabaseAdmin, getSupabaseAnon } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import type { AppPermission, AppUser } from '../../shared/types/user';
import type {
  GoogleLoginInput,
  LoginInput,
  RefreshInput,
  RegisterInput,
  ResendVerificationInput,
  VerifyEmailInput,
} from './auth.schema';

const PROFILE_COLUMNS =
  'id, email, role, full_name, phone_number, avatar_url, profile_completed, is_active';

export interface AuthContextPayload {
  user: AppUser;
  permissions: AppPermission[];
  owner_bypass: boolean;
}

export interface AuthSessionPayload extends AuthContextPayload {
  access_token: string;
  refresh_token: string;
}

function rateLimited(): AppError {
  return new AppError(429, 'rate_limited', 'Terlalu banyak percobaan. Coba lagi sebentar lagi');
}

function mapAuthError(error: AuthError): AppError {
  switch (error.code) {
    case 'invalid_credentials':
      return new AppError(401, 'invalid_credentials', 'Email atau password salah');
    case 'email_not_confirmed':
      return new AppError(403, 'email_not_verified', 'Email belum diverifikasi');
    case 'over_email_send_rate_limit':
    case 'over_request_rate_limit':
      return rateLimited();
    case 'user_already_exists':
    case 'email_exists':
      return new AppError(409, 'email_already_registered', 'Email sudah terdaftar. Silakan masuk');
    case 'weak_password':
      return new AppError(400, 'validation_error', 'Password terlalu lemah');
    case 'refresh_token_not_found':
    case 'refresh_token_already_used':
    case 'session_not_found':
    case 'session_expired':
    case 'bad_jwt':
      return new AppError(401, 'unauthorized', 'Sesi tidak valid, silakan masuk lagi');
    default:
      break;
  }
  if (error.status === 429) return rateLimited();
  if (error.status !== undefined && error.status >= 500) {
    return new AppError(502, 'auth_provider_error', 'Layanan autentikasi sedang bermasalah');
  }
  return new AppError(400, 'auth_error', error.message);
}

export async function loadAuthContext(env: Bindings, userId: string): Promise<AuthContextPayload> {
  const admin = getSupabaseAdmin(env);

  const { data: profile, error } = await admin
    .from('users')
    .select(PROFILE_COLUMNS)
    .eq('id', userId)
    .single();

  if (error || !profile) {
    throw new AppError(404, 'profile_not_found', 'Profil pengguna tidak ditemukan');
  }

  const user = profile as AppUser;
  let permissions: AppPermission[] = [];

  if (user.role === 'worker') {
    const { data: permRows } = await admin
      .from('worker_permissions')
      .select('permission, worker_profiles!inner(user_id)')
      .eq('worker_profiles.user_id', user.id)
      .is('revoked_at', null);

    permissions = (permRows ?? []).map((row) => row.permission as AppPermission);
  }

  return { user, permissions, owner_bypass: user.role === 'owner' };
}

async function buildSession(
  env: Bindings,
  userId: string,
  accessToken: string,
  refreshToken: string,
): Promise<AuthSessionPayload> {
  const context = await loadAuthContext(env, userId);
  if (!context.user.is_active) {
    throw new AppError(403, 'account_disabled', 'Akun dinonaktifkan');
  }
  return { ...context, access_token: accessToken, refresh_token: refreshToken };
}

export async function register(env: Bindings, input: RegisterInput): Promise<{ email: string }> {
  const anon = getSupabaseAnon(env);
  const { data, error } = await anon.auth.signUp({
    email: input.email,
    password: input.password,
  });

  if (error) throw mapAuthError(error);
  if (data.session) {
    throw new AppError(
      500,
      'config_error',
      'Konfirmasi email belum diaktifkan di pengaturan Supabase Auth',
    );
  }

  if (data.user && (data.user.identities?.length ?? 0) === 0) {
    throw new AppError(409, 'email_already_registered', 'Email sudah terdaftar. Silakan masuk');
  }

  return { email: input.email };
}

export async function verifyEmail(
  env: Bindings,
  input: VerifyEmailInput,
): Promise<AuthSessionPayload> {
  const anon = getSupabaseAnon(env);
  const { data, error } = await anon.auth.verifyOtp({
    email: input.email,
    token: input.code,
    type: 'email',
  });

  if (error) {
    const mapped = mapAuthError(error);
    if (mapped.code === 'rate_limited') throw mapped;
    throw new AppError(400, 'invalid_otp', 'Kode salah atau sudah kedaluwarsa');
  }
  if (!data.session || !data.user) {
    throw new AppError(400, 'invalid_otp', 'Kode salah atau sudah kedaluwarsa');
  }

  return buildSession(env, data.user.id, data.session.access_token, data.session.refresh_token);
}

export async function resendVerification(
  env: Bindings,
  input: ResendVerificationInput,
): Promise<void> {
  const anon = getSupabaseAnon(env);
  const { error } = await anon.auth.resend({ type: 'signup', email: input.email });
  if (error) throw mapAuthError(error);
}

export async function login(env: Bindings, input: LoginInput): Promise<AuthSessionPayload> {
  const anon = getSupabaseAnon(env);
  const { data, error } = await anon.auth.signInWithPassword({
    email: input.email,
    password: input.password,
  });

  if (error) throw mapAuthError(error);

  return buildSession(env, data.user.id, data.session.access_token, data.session.refresh_token);
}

export async function loginWithGoogle(
  env: Bindings,
  input: GoogleLoginInput,
): Promise<AuthSessionPayload> {
  const anon = getSupabaseAnon(env);
  const { data, error } = await anon.auth.signInWithIdToken({
    provider: 'google',
    token: input.id_token,
  });

  if (error) {
    if (error.code === 'provider_disabled') {
      throw new AppError(500, 'config_error', 'Login Google belum diaktifkan di Supabase');
    }
    const mapped = mapAuthError(error);
    if (mapped.status === 429 || mapped.status === 502) throw mapped;
    // Token salah / kedaluwarsa / audience (Client ID) tidak terdaftar di Supabase.
    throw new AppError(401, 'invalid_google_token', 'Login Google gagal. Coba lagi');
  }
  if (!data.session || !data.user) {
    throw new AppError(401, 'invalid_google_token', 'Login Google gagal. Coba lagi');
  }

  return buildSession(env, data.user.id, data.session.access_token, data.session.refresh_token);
}

export async function refresh(
  env: Bindings,
  input: RefreshInput,
): Promise<{ access_token: string; refresh_token: string }> {
  const anon = getSupabaseAnon(env);
  const { data, error } = await anon.auth.refreshSession({ refresh_token: input.refresh_token });

  if (error || !data.session) {
    throw error
      ? mapAuthError(error)
      : new AppError(401, 'unauthorized', 'Sesi tidak valid, silakan masuk lagi');
  }

  return {
    access_token: data.session.access_token,
    refresh_token: data.session.refresh_token,
  };
}

export async function logout(env: Bindings, accessToken: string): Promise<void> {
  const admin = getSupabaseAdmin(env);
  const { error } = await admin.auth.admin.signOut(accessToken, 'local');
  if (error) console.error('logout: gagal mencabut sesi', error.message);
}
