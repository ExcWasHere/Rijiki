import type { Context } from 'hono';
import { z } from 'zod';
import type { AppEnv } from '../../shared/types/env';
import { parseInput } from '../../shared/utils/validate';
import { getThread, markThreadRead, sendMessage } from './messages.service';

const sendSchema = z.object({
  body: z
    .string()
    .trim()
    .min(1, 'Tulis dulu pesannya.')
    .max(1000, 'Pesan maksimal 1000 karakter'),
});

export async function listMessagesHandler(c: Context<AppEnv>) {
  c.header('Cache-Control', 'no-store');
  return c.json(await getThread(c.env, c.get('user'), c.req.param('id') ?? ''));
}

export async function sendMessageHandler(c: Context<AppEnv>) {
  const input = parseInput(sendSchema, await c.req.json().catch(() => null));
  return c.json(
    await sendMessage(c.env, c.get('user'), c.req.param('id') ?? '', input.body),
    201,
  );
}

export async function markMessagesReadHandler(c: Context<AppEnv>) {
  return c.json(await markThreadRead(c.env, c.get('user'), c.req.param('id') ?? ''));
}
