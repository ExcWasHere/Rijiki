import type { Context } from 'hono';
import { ok } from './response';

export function notImplemented(feature: string) {
  return (c: Context) => c.json(ok({ message: `TODO: ${feature} belum diimplementasi` }), 200);
}