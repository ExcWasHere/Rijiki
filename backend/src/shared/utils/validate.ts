import type { z } from 'zod';
import { AppError } from '../errors';

export function parseInput<T extends z.ZodTypeAny>(schema: T, raw: unknown): z.infer<T> {
  if (raw === null || typeof raw !== 'object') {
    throw new AppError(400, 'invalid_json', 'Body request harus berupa JSON');
  }
  const result = schema.safeParse(raw);
  if (!result.success) {
    throw new AppError(
      400,
      'validation_error',
      result.error.issues[0]?.message ?? 'Data tidak valid',
    );
  }
  return result.data;
}
