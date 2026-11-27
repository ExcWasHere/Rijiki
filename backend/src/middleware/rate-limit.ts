import type { Context, Next } from 'hono';
import { HTTPException } from 'hono/http-exception';
import type { AppEnv } from '../shared/types/env';

/**
 * Pembatas laju sederhana untuk endpoint tanpa autentikasi (login, OTP,
 * webhook). Memakai Rate Limiting binding Cloudflare bila tersedia; kalau
 * binding belum dipasang, jatuh ke penghitung per-isolate supaya tetap ada
 * batas minimum (bukan pengganti konfigurasi yang benar).
 */

interface RateLimitOutcome {
  success: boolean;
}

interface RateLimitBinding {
  limit(options: { key: string }): Promise<RateLimitOutcome>;
}

const WINDOW_MS = 60_000;

/** Penghitung cadangan: satu Map per isolate, direset tiap jendela. */
const counters = new Map<string, { count: number; resetAt: number }>();

function memoryLimit(key: string, limit: number): boolean {
  const now = Date.now();
  const entry = counters.get(key);
  if (!entry || entry.resetAt <= now) {
    counters.set(key, { count: 1, resetAt: now + WINDOW_MS });
    return true;
  }
  entry.count += 1;
  if (entry.count > limit) return false;
  return true;
}

/** Jaga Map tetap kecil: buang entri yang jendelanya sudah lewat. */
function pruneCounters(now: number): void {
  if (counters.size < 5_000) return;
  for (const [key, entry] of counters) {
    if (entry.resetAt <= now) counters.delete(key);
  }
}

function clientKey(c: Context<AppEnv>): string {
  return (
    c.req.header('CF-Connecting-IP') ??
    c.req.header('X-Forwarded-For')?.split(',')[0]?.trim() ??
    'unknown'
  );
}

export interface RateLimitOptions {
  /** Nama binding di wrangler.toml. */
  binding: 'AUTH_RATE_LIMITER' | 'WEBHOOK_RATE_LIMITER';
  /** Batas per menit saat binding tidak tersedia. */
  fallbackLimit: number;
}

export function rateLimit(options: RateLimitOptions) {
  return async (c: Context<AppEnv>, next: Next) => {
    const key = `${options.binding}:${clientKey(c)}`;
    const limiter = c.env[options.binding] as RateLimitBinding | undefined;

    let allowed: boolean;
    if (limiter && typeof limiter.limit === 'function') {
      const outcome = await limiter.limit({ key });
      allowed = outcome.success;
    } else {
      const now = Date.now();
      pruneCounters(now);
      allowed = memoryLimit(key, options.fallbackLimit);
    }

    if (!allowed) {
      throw new HTTPException(429, { message: 'Terlalu banyak permintaan. Coba lagi sebentar lagi' });
    }

    await next();
  };
}
