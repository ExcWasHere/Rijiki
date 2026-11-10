import { Hono } from 'hono';
import type { AppEnv } from '../../shared/types/env';
import { handleMidtransNotification } from './webhooks.service';

export const webhooksRoutes = new Hono<AppEnv>();

// URL ini diisi di dashboard Midtrans sebagai Payment Notification URL.
webhooksRoutes.post('/midtrans', async (c) => {
  const body = await c.req.json().catch(() => null);
  await handleMidtransNotification(c.env, body);
  return c.json({ ok: true });
});
