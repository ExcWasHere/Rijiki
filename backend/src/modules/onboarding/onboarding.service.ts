import { HTTPException } from 'hono/http-exception';
import type { Bindings } from '../../shared/types/env';
import type { AppUser } from '../../shared/types/user';
import { getSupabaseAdmin } from '../../config/supabase';
import type { CompleteOnboardingInput } from './onboarding.schema';

export async function completeOnboarding(
  env: Bindings,
  userId: string,
  input: CompleteOnboardingInput,
): Promise<AppUser> {
  const admin = getSupabaseAdmin(env);

  const { data: existing, error: fetchError } = await admin
    .from('users')
    .select('role')
    .eq('id', userId)
    .single();

  if (fetchError || !existing) {
    throw new HTTPException(404, { message: 'Pengguna tidak ditemukan' });
  }
  if (existing.role !== 'customer') {
    throw new HTTPException(403, { message: 'Onboarding hanya berlaku untuk customer' });
  }

  const { data, error } = await admin
    .from('users')
    .update({
      full_name: input.full_name,
      phone_number: input.phone_number,
      profile_completed: true,
    })
    .eq('id', userId)
    .select('id, email, role, full_name, phone_number, avatar_url, profile_completed, is_active')
    .single();

  if (error || !data) {
    throw new HTTPException(400, { message: 'Gagal menyimpan onboarding' });
  }

  return data as AppUser;
}