import type { Context } from 'hono';
import { AppError } from '../../shared/errors';
import type { AppEnv } from '../../shared/types/env';
import { parseInput } from '../../shared/utils/validate';
import { buildRecap } from './ratings.export';
import {
  exportQuerySchema,
  listRatingsQuerySchema,
  setFeaturedSchema,
} from './ratings.schema';
import {
  RATING_PHOTO_MAX_BYTES,
  createRating,
  listFeaturedTestimonials,
  listManagedRatings,
  setRatingFeatured,
} from './ratings.service';

const MAX_RATING_REQUEST_BYTES = RATING_PHOTO_MAX_BYTES + 64 * 1024;

/** POST /api/orders/:id/rating (multipart: rating_value, comment?, photo?). */
export async function createRatingHandler(c: Context<AppEnv>) {
  const declaredLength = Number(c.req.header('Content-Length') ?? 0);
  if (declaredLength > MAX_RATING_REQUEST_BYTES) {
    throw new AppError(413, 'file_too_large', 'Ukuran gambar maksimal 5 MB');
  }

  const ctx = c.get('user');
  const body = await c.req.parseBody().catch(() => ({}) as Record<string, unknown>);
  const result = await createRating(c.env, ctx, c.req.param('id') ?? '', body);
  return c.json(result, 201);
}

/** GET /api/testimonials/featured */
export async function featuredHandler(c: Context<AppEnv>) {
  c.header('Cache-Control', 'private, max-age=60');
  return c.json(await listFeaturedTestimonials(c.env));
}

/** GET /api/management/testimonials */
export async function listManagedHandler(c: Context<AppEnv>) {
  const query = parseInput(listRatingsQuerySchema, c.req.query());
  c.header('Cache-Control', 'no-store');
  return c.json(await listManagedRatings(c.env, query));
}

/** PATCH /api/management/testimonials/:id/featured */
export async function setFeaturedHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const input = parseInput(setFeaturedSchema, await c.req.json().catch(() => null));
  return c.json(await setRatingFeatured(c.env, ctx.user.id, c.req.param('id') ?? '', input.is_featured));
}

/** GET /api/management/testimonials/export?source=testimonials|before_after&start_date&end_date */
export async function exportRecapHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const query = parseInput(exportQuerySchema, c.req.query());
  const recap = await buildRecap(c.env, ctx.user.id, query);

  return new Response(recap.stream, {
    status: 200,
    headers: {
      'Content-Type': 'application/zip',
      'Content-Disposition': `attachment; filename="${recap.filename}"`,
      'Cache-Control': 'no-store',
      'X-Export-Total': String(recap.total),
      'X-Export-Included': String(recap.included),
      'X-Export-Truncated': recap.truncated ? 'true' : 'false',
      'Access-Control-Expose-Headers': 'Content-Disposition, X-Export-Total, X-Export-Included, X-Export-Truncated',
    },
  });
}
