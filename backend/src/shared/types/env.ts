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
}

export interface Variables {
  user: AuthContextUser;
}

export interface AppEnv {
  Bindings: Bindings;
  Variables: Variables;
}
