import type { Bindings } from '../types/env';
import type { ValidatedImage } from './image';

export type StorageVisibility = 'public' | 'private';

function bucketFor(env: Bindings, visibility: StorageVisibility): R2Bucket {
  return visibility === 'public' ? env.PUBLIC_BUCKET : env.PRIVATE_BUCKET;
}

function cacheControlFor(visibility: StorageVisibility): string {
  return visibility === 'public'
    ? 'public, max-age=31536000, immutable'
    : 'private, max-age=300';
}

export function buildKey(folder: string, ownerId: string, ext: string): string {
  return `${folder}/${ownerId}/${crypto.randomUUID()}.${ext}`;
}

export async function putImage(
  env: Bindings,
  visibility: StorageVisibility,
  key: string,
  image: Pick<ValidatedImage, 'bytes' | 'mime'>,
): Promise<void> {
  await bucketFor(env, visibility).put(key, image.bytes, {
    httpMetadata: {
      contentType: image.mime,
      cacheControl: cacheControlFor(visibility),
    },
  });
}

export function getObject(
  env: Bindings,
  visibility: StorageVisibility,
  key: string,
): Promise<R2ObjectBody | null> {
  return bucketFor(env, visibility).get(key);
}

export async function deleteObject(
  env: Bindings,
  visibility: StorageVisibility,
  key: string,
): Promise<void> {
  await bucketFor(env, visibility).delete(key);
}

/**
 * Menyalin objek ke bucket lain dengan key yang sama (dipakai untuk menyalin
 * foto testimoni featured ke bucket publik). Mengembalikan false bila objek
 * sumber tidak ada. Foto dibatasi 5 MB, jadi dibaca utuh ke memori.
 */
export async function copyObject(
  env: Bindings,
  from: StorageVisibility,
  to: StorageVisibility,
  key: string,
): Promise<boolean> {
  const source = await bucketFor(env, from).get(key);
  if (!source) return false;

  await bucketFor(env, to).put(key, await source.arrayBuffer(), {
    httpMetadata: {
      contentType: source.httpMetadata?.contentType ?? 'application/octet-stream',
      cacheControl: cacheControlFor(to),
    },
  });
  return true;
}

function publicBase(env: Bindings): string {
  return env.PUBLIC_ASSET_BASE_URL.replace(/\/+$/, '');
}

export function publicUrl(env: Bindings, key: string): string {
  return `${publicBase(env)}/${key}`;
}

export function keyFromPublicUrl(env: Bindings, url: string | null | undefined): string | null {
  if (!url) return null;
  const prefix = `${publicBase(env)}/`;
  return url.startsWith(prefix) ? url.slice(prefix.length) : null;
}
