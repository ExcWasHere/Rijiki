import { Hono } from 'hono';
import { AppError } from '../../shared/errors';
import type { AppEnv } from '../../shared/types/env';
import { handleMidtransNotification } from './webhooks.service';

export const webhooksRoutes = new Hono<AppEnv>();

/** Notifikasi Midtrans hanya berisi belasan field; 8 KB sudah sangat longgar. */
const MAX_WEBHOOK_BYTES = 8 * 1024;

// URL ini diisi di dashboard Midtrans sebagai Payment Notification URL.
webhooksRoutes.post('/midtrans', async (c) => {
  const declared = Number(c.req.header('Content-Length') ?? 0);
  if (Number.isFinite(declared) && declared > MAX_WEBHOOK_BYTES) {
    throw new AppError(413, 'payload_too_large', 'Body notifikasi terlalu besar');
  }

  // Content-Length bisa tidak dikirim: baca sebagai teks dan periksa panjangnya
  // sebelum di-parse, supaya body raksasa tidak masuk ke JSON.parse.
  const raw = await c.req.text();
  if (raw.length > MAX_WEBHOOK_BYTES) {
    throw new AppError(413, 'payload_too_large', 'Body notifikasi terlalu besar');
  }

  let body: unknown = null;
  try {
    body = JSON.parse(raw);
  } catch {
    body = null;
  }

  await handleMidtransNotification(c.env, body);
  return c.json({ ok: true });
});
