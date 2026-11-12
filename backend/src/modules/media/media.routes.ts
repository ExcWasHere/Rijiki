import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import { requirePermission } from '../../middleware/permission';
import { AppError } from '../../shared/errors';
import type { AppEnv } from '../../shared/types/env';
import * as mediaService from './media.service';

const MULTIPART_OVERHEAD = 64 * 1024;
const MAX_AVATAR_REQUEST_BYTES = mediaService.AVATAR_MAX_BYTES + MULTIPART_OVERHEAD;
const MAX_EVENT_BANNER_REQUEST_BYTES = mediaService.EVENT_BANNER_MAX_BYTES + MULTIPART_OVERHEAD;
const MAX_MERCHANDISE_IMAGE_REQUEST_BYTES =
  mediaService.MERCHANDISE_IMAGE_MAX_BYTES + MULTIPART_OVERHEAD;

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

mediaRoutes.post('/event-banner', requirePermission('manage_cms_events'), async (c) => {
  const declaredLength = Number(c.req.header('Content-Length') ?? 0);
  if (declaredLength > MAX_EVENT_BANNER_REQUEST_BYTES) {
    throw new AppError(413, 'file_too_large', 'Ukuran gambar terlalu besar');
  }

  const body = await c.req.parseBody().catch(() => ({}) as Record<string, unknown>);
  const { user } = c.get('user');

  return c.json(await mediaService.uploadEventBanner(c.env, user.id, body['image']), 201);
});

mediaRoutes.post('/merchandise-image', requirePermission('manage_cms_merchandise'), async (c) => {
  const declaredLength = Number(c.req.header('Content-Length') ?? 0);
  if (declaredLength > MAX_MERCHANDISE_IMAGE_REQUEST_BYTES) {
    throw new AppError(413, 'file_too_large', 'Ukuran gambar terlalu besar');
  }

  const body = await c.req.parseBody().catch(() => ({}) as Record<string, unknown>);
  const { user } = c.get('user');

  return c.json(await mediaService.uploadMerchandiseImage(c.env, user.id, body['image']), 201);
});

mediaRoutes.get('/private/:key{.+}', async (c) => {
  const object = await mediaService.getPrivateImage(c.env, c.get('user'), c.req.param('key'));

  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set('etag', object.httpEtag);
  headers.set('X-Content-Type-Options', 'nosniff');

  return new Response(object.body, { headers });
});
