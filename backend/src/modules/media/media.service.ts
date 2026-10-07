import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import { readImageFile } from '../../shared/storage/image';
import {
  buildKey,
  deleteObject,
  getObject,
  keyFromPublicUrl,
  publicUrl,
  putImage,
} from '../../shared/storage/r2';
import type { Bindings } from '../../shared/types/env';
import type { AuthContextUser } from '../../shared/types/user';
import { canReadPrivate } from './media.policy';

export const AVATAR_MAX_BYTES = 2 * 1024 * 1024;

export async function uploadAvatar(
  env: Bindings,
  userId: string,
  currentAvatarUrl: string | null | undefined,
  file: unknown,
): Promise<{ avatar_url: string }> {
  const image = await readImageFile(file, AVATAR_MAX_BYTES);

  const key = buildKey('avatars', userId, image.ext);
  await putImage(env, 'public', key, image);
  const url = publicUrl(env, key);

  const { error } = await getSupabaseAdmin(env)
    .from('users')
    .update({ avatar_url: url })
    .eq('id', userId);

  if (error) {
    await deleteObject(env, 'public', key).catch(() => undefined);
    console.error('uploadAvatar: gagal update users.avatar_url', error.message);
    throw new AppError(500, 'internal_error', 'Gagal menyimpan foto profil');
  }

  const oldKey = keyFromPublicUrl(env, currentAvatarUrl);
  if (oldKey && oldKey.startsWith(`avatars/${userId}/`)) {
    await deleteObject(env, 'public', oldKey).catch((e) =>
      console.error('uploadAvatar: gagal menghapus avatar lama', e),
    );
  }

  return { avatar_url: url };
}

export async function getPrivateImage(
  env: Bindings,
  ctx: AuthContextUser,
  key: string,
): Promise<R2ObjectBody> {
  if (!key || key.startsWith('/') || key.includes('..') || key.includes('//')) {
    throw new AppError(404, 'not_found', 'Gambar tidak ditemukan');
  }

  if (!canReadPrivate(ctx, key)) {
    throw new AppError(403, 'forbidden', 'Tidak punya akses ke gambar ini');
  }

  const object = await getObject(env, 'private', key);
  if (!object) {
    throw new AppError(404, 'not_found', 'Gambar tidak ditemukan');
  }
  return object;
}