import type { Context } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { fail } from '../shared/utils/response';

export function errorHandler(err: Error, c: Context) {
  if (err instanceof HTTPException) {
    return c.json(fail(err.message), err.status);
  }

  console.error('Unhandled error:', err);
  return c.json(fail('Terjadi kesalahan pada server'), 500);
}