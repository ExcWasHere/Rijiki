import { AppError } from '../errors';

export const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

export type ImageMime = 'image/jpeg' | 'image/png' | 'image/webp';
export type ImageExt = 'jpg' | 'png' | 'webp';

export interface ValidatedImage {
  bytes: ArrayBuffer;
  mime: ImageMime;
  ext: ImageExt;
}

const PNG_SIGNATURE = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

function matches(bytes: Uint8Array, signature: number[], offset = 0): boolean {
  if (bytes.length < offset + signature.length) return false;
  return signature.every((value, i) => bytes[offset + i] === value);
}

function sniffImage(bytes: Uint8Array): { mime: ImageMime; ext: ImageExt } | null {
  if (matches(bytes, [0xff, 0xd8, 0xff])) return { mime: 'image/jpeg', ext: 'jpg' };
  if (matches(bytes, PNG_SIGNATURE)) return { mime: 'image/png', ext: 'png' };
  if (matches(bytes, [0x52, 0x49, 0x46, 0x46]) && matches(bytes, [0x57, 0x45, 0x42, 0x50], 8)) {
    return { mime: 'image/webp', ext: 'webp' };
  }
  return null;
}

export async function readImageFile(
  value: unknown,
  maxBytes: number = MAX_IMAGE_BYTES,
): Promise<ValidatedImage> {
  if (!(value instanceof File)) {
    throw new AppError(400, 'validation_error', 'File gambar wajib diunggah');
  }
  if (value.size === 0) {
    throw new AppError(400, 'validation_error', 'File gambar kosong');
  }
  if (value.size > maxBytes) {
    const mb = Math.floor(maxBytes / 1024 / 1024);
    throw new AppError(413, 'file_too_large', `Ukuran gambar maksimal ${mb} MB`);
  }

  const bytes = await value.arrayBuffer();
  const kind = sniffImage(new Uint8Array(bytes, 0, Math.min(12, bytes.byteLength)));
  if (!kind) {
    throw new AppError(415, 'unsupported_media_type', 'Format gambar harus JPG, PNG, atau WebP');
  }

  return { bytes, ...kind };
}