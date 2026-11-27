import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import type { Bindings } from '../shared/types/env';

/**
 * Client di-cache per isolate. `createClient` menyiapkan instance GoTrue +
 * PostgREST setiap kali dipanggil; membuatnya ulang di tiap request (2–3 kali
 * per request) hanya membuang waktu karena konfigurasinya tidak berubah.
 * Kuncinya memuat URL + key supaya rotasi key tidak memakai client lama.
 */
const clients = new Map<string, SupabaseClient>();

function cached(key: string, build: () => SupabaseClient): SupabaseClient {
  const existing = clients.get(key);
  if (existing) return existing;

  const client = build();
  // Rotasi key jarang, tetapi jangan biarkan Map tumbuh tanpa batas.
  if (clients.size > 8) clients.clear();
  clients.set(key, client);
  return client;
}

export function getSupabaseAdmin(env: Bindings): SupabaseClient {
  return cached(`admin:${env.SUPABASE_URL}:${env.SUPABASE_SERVICE_ROLE_KEY}`, () =>
    createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
      auth: { autoRefreshToken: false, persistSession: false },
    }),
  );
}

export function getSupabaseAnon(env: Bindings): SupabaseClient {
  return cached(`anon:${env.SUPABASE_URL}:${env.SUPABASE_ANON_KEY}`, () =>
    createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, {
      auth: { autoRefreshToken: false, persistSession: false },
    }),
  );
}
