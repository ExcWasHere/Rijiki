import { z } from 'zod';

export const repeatQuerySchema = z.object({
  /** Minimal order selesai; lantainya 2 karena "repeat" berarti lebih dari sekali. */
  min_orders: z.coerce.number().int().min(2).max(100).default(2),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

export type RepeatQuery = z.infer<typeof repeatQuerySchema>;
