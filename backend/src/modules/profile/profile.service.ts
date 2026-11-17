import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import type { AppUser, CustomerProfile } from '../../shared/types/user';
import type { UpdateProfileInput } from './profile.schema';

const CUSTOMER_PROFILE_COLUMNS = 'default_address, default_lat, default_lng';

function toNumber(value: unknown): number | null {
  if (value === null || value === undefined) return null;
  const n = typeof value === 'number' ? value : Number(value);
  return Number.isFinite(n) ? n : null;
}

export async function getCustomerProfile(
  env: Bindings,
  userId: string,
): Promise<CustomerProfile> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('customer_profiles')
    .select(CUSTOMER_PROFILE_COLUMNS)
    .eq('user_id', userId)
    .maybeSingle();

  if (error) {
    console.error('profile: gagal memuat customer_profiles', error.message);
    throw new AppError(500, 'profile_load_failed', 'Gagal memuat profil customer');
  }

  return {
    default_address: data?.default_address ?? null,
    default_lat: toNumber(data?.default_lat),
    default_lng: toNumber(data?.default_lng),
  };
}

/**
 * Menyimpan nama + nomor HP untuk semua role. Customer boleh sekaligus
 * mengirim alamat default beserta titiknya; bila alamat tidak dikirim, alamat
 * lama dibiarkan apa adanya.
 */
export async function updateProfile(
  env: Bindings,
  user: AppUser,
  input: UpdateProfileInput,
): Promise<void> {
  const admin = getSupabaseAdmin(env);
  const hasAddress = input.default_address !== undefined;

  if (hasAddress && user.role !== 'customer') {
    throw new AppError(400, 'validation_error', 'Alamat default hanya untuk customer');
  }

  // Profil dianggap lengkap bila nama, nomor HP, dan (untuk customer) alamat
  // sudah terisi. Owner/worker selalu lengkap sejak dibuat.
  let profileCompleted = user.profile_completed;
  if (user.role === 'customer') {
    const address = hasAddress
      ? input.default_address!
      : (await getCustomerProfile(env, user.id)).default_address;
    profileCompleted = (address ?? '').trim().length > 0;
  }

  if (hasAddress) {
    const { error: profileError } = await admin.from('customer_profiles').upsert(
      {
        user_id: user.id,
        default_address: input.default_address,
        default_lat: input.default_lat,
        default_lng: input.default_lng,
      },
      { onConflict: 'user_id' },
    );

    if (profileError) {
      console.error('profile: gagal menyimpan customer_profiles', profileError.message);
      throw new AppError(500, 'profile_save_failed', 'Gagal menyimpan alamat');
    }
  }

  const { error: userError } = await admin
    .from('users')
    .update({
      full_name: input.full_name,
      phone_number: input.phone_number,
      profile_completed: profileCompleted,
      updated_at: new Date().toISOString(),
    })
    .eq('id', user.id);

  if (userError) {
    console.error('profile: gagal menyimpan users', userError.message);
    throw new AppError(500, 'profile_save_failed', 'Gagal menyimpan profil');
  }
}
