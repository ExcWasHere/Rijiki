import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import { AppError } from '../../shared/errors';
import type { AppEnv } from '../../shared/types/env';
import * as mediaService from './media.service';

const MAX_AVATAR_REQUEST_BYTES = mediaService.AVATAR_MAX_BYTES + 64 * 1024;

export const mediaRoutes = new Hono<AppEnv>();

mediaRoutes.use('*', authMiddleware);

mediaRoutes.post('/avatar', async (c) => {
  const declaredLength = Number(c.req.header('Content-Length') ?? 0);
  if (declaredLength > MAX_AVATAR_REQUEST_BYTES) {
    throw new AppError(413, 'file_too_large', 'Ukuran gambar terlalu besar');
  }

  const body = await c.req.parseBody().catch(() => ({}) as Record<string, unknown>);
  const { user } = c.get('user');

  const result = await mediaService.uploadAvatar(c.env, user.id, user.avatar_url, body['image']);
  return c.json(result, 201);
});

mediaRoutes.get('/private/:key{.+}', async (c) => {
  const object = await mediaService.getPrivateImage(c.env, c.get('user'), c.req.param('key'));

  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set('etag', object.httpEtag);
  headers.set('X-Content-Type-Options', 'nosniff');

  return new Response(object.body, { headers });
});