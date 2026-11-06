import { AppError } from '../errors';

const KEY_PATTERN = /^[A-Za-z0-9_-]{8,64}$/;

/**
 * Membaca header `Idempotency-Key`. Header opsional: tanpa header, request
 * diproses seperti biasa (tanpa perlindungan duplikat).
 */
export function parseIdempotencyKey(header: string | null | undefined): string | null {
  if (header === undefined || header === null) return null;
  const key = header.trim();
  if (key.length === 0) return null;
  if (!KEY_PATTERN.test(key)) {
    throw new AppError(
      400,
      'validation_error',
      'Idempotency-Key tidak valid. Pakai 8-64 karakter: huruf, angka, "-" atau "_".',
    );
  }
  return key;
}

async function sha256Hex(text: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

/** Sidik jari isi request: dipakai mendeteksi kunci yang sama dengan isi berbeda. */
export async function fingerprintOf(value: unknown): Promise<string> {
  return sha256Hex(JSON.stringify(value));
}

export function idempotencyConflict(): AppError {
  return new AppError(
    409,
    'idempotency_conflict',
    'Permintaan ini memakai kunci yang sama dengan permintaan sebelumnya yang isinya berbeda.',
  );
}
