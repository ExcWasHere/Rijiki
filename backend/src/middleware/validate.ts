import type { Context, Next } from 'hono';
import type { ZodSchema } from 'zod';
import { HTTPException } from 'hono/http-exception';

export function validateBody<T>(schema: ZodSchema<T>) {
  return async (c: Context, next: Next) => {
    const json = await c.req.json().catch(() => null);
    const result = schema.safeParse(json);

    if (!result.success) {
      throw new HTTPException(422, {
        message: result.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; '),
      });
    }

    c.set('validatedBody', result.data);
    await next();
  };
}