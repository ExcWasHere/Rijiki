import type { Context, Next } from 'hono';
import { HTTPException } from 'hono/http-exception';
import type { AppEnv } from '../shared/types/env';
import type { AppPermission, AuthContextUser } from '../shared/types/user';
import { getSupabaseAdmin, getSupabaseAnon } from '../config/supabase';

/**
 * Cache konteks auth per token, TTL pendek.
 *
 * Setiap request terautentikasi sebelumnya melakukan tiga round-trip berurutan
 * (verifikasi token, profil, izin worker). Cache ini memangkasnya tanpa
 * menyimpan apa pun ke disk: isinya hanya objek kecil di memori isolate, dan
 * umurnya 30 detik sehingga pencabutan izin atau penonaktifan akun tetap
 * berlaku hampir seketika.
 */
const AUTH_CACHE_TTL_MS = 30_000;
const AUTH_CACHE_MAX_ENTRIES = 500;

interface CacheEntry {
  context: AuthContextUser;
  expiresAt: number;
}

const cache = new Map<string, CacheEntry>();

/** Sidik jari token: cache tidak menyimpan token mentah. */
async function tokenKey(token: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(token));
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

function readCache(key: string): AuthContextUser | null {
  const entry = cache.get(key);
  if (!entry) return null;
  if (entry.expiresAt <= Date.now()) {
    cache.delete(key);
    return null;
  }
  return entry.context;
}

function writeCache(key: string, context: AuthContextUser): void {
  if (cache.size >= AUTH_CACHE_MAX_ENTRIES) {
    const now = Date.now();
    for (const [entryKey, entry] of cache) {
      if (entry.expiresAt <= now) cache.delete(entryKey);
    }
    // Masih penuh: buang yang paling tua (Map menjaga urutan insert).
    if (cache.size >= AUTH_CACHE_MAX_ENTRIES) {
      const oldest = cache.keys().next();
      if (!oldest.done) cache.delete(oldest.value);
    }
  }
  cache.set(key, { context, expiresAt: Date.now() + AUTH_CACHE_TTL_MS });
}

/** Dipakai saat logout agar token yang dicabut tidak menempel di cache. */
export async function invalidateAuthCache(token: string): Promise<void> {
  cache.delete(await tokenKey(token));
}

async function loadAuthContext(env: AppEnv['Bindings'], token: string): Promise<AuthContextUser> {
  const anon = getSupabaseAnon(env);
  const { data: authData, error: authError } = await anon.auth.getUser(token);

  if (authError || !authData.user) {
    throw new HTTPException(401, { message: 'Token tidak valid atau kadaluarsa' });
  }

  const admin = getSupabaseAdmin(env);
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

  return { user: profile, permissions, ownerBypass };
}

export async function authMiddleware(c: Context<AppEnv>, next: Next) {
  const authHeader = c.req.header('Authorization');
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null;

  if (!token) {
    throw new HTTPException(401, { message: 'Token tidak ditemukan' });
  }

  const key = await tokenKey(token);
  const contextUser = readCache(key) ?? (await loadAuthContext(c.env, token));
  writeCache(key, contextUser);

  c.set('user', contextUser);
  await next();
}
