import { z } from 'zod';
import type { Bindings } from '../shared/types/env';

const envSchema = z.object({
  SUPABASE_URL: z.string().url(),
  SUPABASE_ANON_KEY: z.string().min(1),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  PUBLIC_ASSET_BASE_URL: z.string().url(),
  DUITKU_MERCHANT_CODE: z.string().optional(),
  DUITKU_API_KEY: z.string().optional(),
  ENVIRONMENT: z.string().optional(),
});

export function validateEnv(env: Bindings): Bindings {
  const result = envSchema.safeParse(env);
  if (!result.success) {
    throw new Error(
      `Konfigurasi env tidak valid: ${result.error.issues.map((i) => i.path.join('.')).join(', ')}`,
    );
  }
  return env;
}