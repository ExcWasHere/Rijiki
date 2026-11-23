import type { AuthContextUser } from './user';

export interface Bindings {
  SUPABASE_URL: string;
  SUPABASE_ANON_KEY: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
  PUBLIC_ASSET_BASE_URL: string;
  PUBLIC_BUCKET: R2Bucket;
  PRIVATE_BUCKET: R2Bucket;
  MIDTRANS_SERVER_KEY?: string;
  MIDTRANS_ENV?: string;
  ENVIRONMENT?: string;
  // FCM HTTP v1 (service account Firebase). Opsional: bila kosong, notifikasi
  // tetap tersimpan di inbox dan hanya push yang dilewati.
  FIREBASE_PROJECT_ID?: string;
  FIREBASE_CLIENT_EMAIL?: string;
  FIREBASE_PRIVATE_KEY?: string;
  // Parser pengeluaran AI. Provider apa pun yang kompatibel [OI]
  // /v1/chat/completions (InferHub, [OI]); bila kosong, ai-parse membalas
  // status failed dan pengeluaran dicatat tanpa klasifikasi (PRD 15.1).
  AI_API_KEY?: string;
  AI_BASE_URL?: string;
  AI_MODEL?: string;
  // Rate Limiting binding Cloudflare (opsional; middleware punya cadangan
  // per-isolate bila belum dipasang).
  AUTH_RATE_LIMITER?: RateLimitBinding;
  WEBHOOK_RATE_LIMITER?: RateLimitBinding;
}

export interface RateLimitBinding {
  limit(options: { key: string }): Promise<{ success: boolean }>;
}

export interface Variables {
  user: AuthContextUser;
}

export interface AppEnv {
  Bindings: Bindings;
  Variables: Variables;
}
