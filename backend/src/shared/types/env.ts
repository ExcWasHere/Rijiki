import type { AuthContextUser } from './user';

export interface Bindings {
  SUPABASE_URL: string;
  SUPABASE_ANON_KEY: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
  DUITKU_MERCHANT_CODE?: string;
  DUITKU_API_KEY?: string;
  ENVIRONMENT?: string;
}

export interface Variables {
  user: AuthContextUser;
}

export interface AppEnv {
  Bindings: Bindings;
  Variables: Variables;
}