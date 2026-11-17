import type { AuthError } from '@supabase/supabase-js';
import { getSupabaseAdmin, getSupabaseAnon } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import type { AppPermission, AppUser, CustomerProfile } from '../../shared/types/user';
import { getCustomerProfile } from '../profile/profile.service';
import type {
  ChangePasswordInput,
  ConfirmEmailChangeInput,
  GoogleLoginInput,
  LoginInput,
  RefreshInput,
  RegisterInput,
  RequestEmailChangeInput,
  ResendVerificationInput,
  VerifyEmailInput,
} from './auth.schema';

const PROFILE_COLUMNS =
  'id, email, role, full_name, phone_number, avatar_url, profile_completed, is_active';

export interface AuthContextPayload {
  user: AppUser;
  permissions: AppPermission[];
  owner_bypass: boolean;
  customer_profile: CustomerProfile | null;
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
  let customerProfile: CustomerProfile | null = null;

  if (user.role === 'worker') {
    const { data: permRows } = await admin
      .from('worker_permissions')
      .select('permission, worker_profiles!inner(user_id)')
      .eq('worker_profiles.user_id', user.id)
      .is('revoked_at', null);

    permissions = (permRows ?? []).map((row) => row.permission as AppPermission);
  }

  if (user.role === 'customer') {
    customerProfile = await getCustomerProfile(env, user.id);
  }

  return {
    user,
    permissions,
    owner_bypass: user.role === 'owner',
    customer_profile: customerProfile,
  };
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

/**
 * Memastikan [password] benar untuk akun [email]. Supabase tidak punya endpoint
 * cek password, jadi dipakai signInWithPassword lalu sesinya dibuang.
 */
async function assertPassword(env: Bindings, email: string, password: string): Promise<void> {
  const anon = await signInForAction(env, email, password);
  await anon.auth.signOut({ scope: 'local' }).catch(() => undefined);
}

/**
 * Masuk dengan password dan mengembalikan klien anon yang memegang sesi itu,
 * untuk aksi yang wajib atas nama pengguna (mis. ganti email ber-OTP).
 * Pemanggil wajib signOut lokal setelah selesai.
 */
async function signInForAction(env: Bindings, email: string, password: string) {
  const anon = getSupabaseAnon(env);
  const { data, error } = await anon.auth.signInWithPassword({ email, password });

  if (error || !data.session) {
    const mapped = error ? mapAuthError(error) : null;
    if (mapped?.status === 429) throw mapped;
    throw new AppError(401, 'invalid_credentials', 'Password saat ini salah');
  }
  return anon;
}

export async function changePassword(
  env: Bindings,
  user: AppUser,
  input: ChangePasswordInput,
): Promise<void> {
  await assertPassword(env, user.email, input.current_password);

  const admin = getSupabaseAdmin(env);
  const { error } = await admin.auth.admin.updateUserById(user.id, {
    password: input.new_password,
  });
  if (error) throw mapAuthError(error);
}

/**
 * Langkah 1 ganti email: password diverifikasi, lalu Supabase Auth mengirim kode
 * OTP ke alamat baru. Email belum berubah sampai kode dikonfirmasi (langkah 2).
 *
 * Wajib lewat sesi pengguna (`auth.updateUser`), bukan admin API: admin API
 * langsung mengganti email tanpa verifikasi. Syarat di Supabase Auth: "Confirm
 * email" aktif, "Secure email change" mati (cukup satu kode dari alamat baru),
 * dan template "Change Email Address" memuat {{ .Token }}.
 */
export async function requestEmailChange(
  env: Bindings,
  user: AppUser,
  input: RequestEmailChangeInput,
): Promise<void> {
  const admin = getSupabaseAdmin(env);
  // Email acuan dari Supabase Auth, bukan mirror users.email, supaya tetap benar
  // setelah email pernah diganti.
  const authEmail =
    (await admin.auth.admin.getUserById(user.id)).data.user?.email ?? user.email;

  if (input.new_email.toLowerCase() === authEmail.toLowerCase()) {
    throw new AppError(400, 'validation_error', 'Email baru sama dengan email saat ini');
  }

  const anon = await signInForAction(env, authEmail, input.password);
  try {
    const { data, error } = await anon.auth.updateUser({ email: input.new_email });

    if (error) {
      console.error('change-email: gagal meminta perubahan email', error.code, error.message);
      const mapped = mapAuthError(error);
      if (mapped.status === 429 || mapped.status === 502) throw mapped;
      if (mapped.code === 'email_already_registered') throw mapped;
      throw new AppError(400, 'email_change_failed', 'Gagal mengirim kode ke email baru');
    }

    // Konfirmasi email mati di Supabase: alamat sudah terganti tanpa kode.
    // Mirror disamakan agar data tetap konsisten, lalu konfigurasi dilaporkan.
    if (data.user?.email?.toLowerCase() === input.new_email.toLowerCase()) {
      await syncMirrorEmail(env, user.id, input.new_email);
      console.error('change-email: konfirmasi email nonaktif di Supabase Auth');
      throw new AppError(
        500,
        'config_error',
        'Konfirmasi email belum diaktifkan di pengaturan Supabase Auth',
      );
    }
  } finally {
    await anon.auth.signOut({ scope: 'local' }).catch(() => undefined);
  }
}

/**
 * Menyamakan kolom mirror `users.email` dengan email akun di Supabase Auth.
 * `users` hanya diisi trigger saat signup, jadi perubahan email tidak otomatis
 * tercermin di sana.
 */
async function syncMirrorEmail(env: Bindings, userId: string, email: string): Promise<void> {
  const { error } = await getSupabaseAdmin(env)
    .from('users')
    .update({ email, updated_at: new Date().toISOString() })
    .eq('id', userId);
  if (error) console.error('change-email: gagal menyamakan users.email', error.message);
}

/** Langkah 2: kode dari email baru diverifikasi; email akun ikut berganti. */
export async function confirmEmailChange(
  env: Bindings,
  input: ConfirmEmailChangeInput,
): Promise<void> {
  const anon = getSupabaseAnon(env);
  const { data, error } = await anon.auth.verifyOtp({
    email: input.new_email,
    token: input.code,
    type: 'email_change',
  });

  if (error || !data.user) {
    const mapped = error ? mapAuthError(error) : null;
    if (mapped && (mapped.status === 429 || mapped.status === 502)) throw mapped;
    throw new AppError(400, 'invalid_otp', 'Kode salah atau sudah kedaluwarsa');
  }

  if (data.session) await anon.auth.signOut({ scope: 'local' }).catch(() => undefined);
  await syncMirrorEmail(env, data.user.id, input.new_email);
}
