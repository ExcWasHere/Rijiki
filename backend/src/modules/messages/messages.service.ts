import type { Bindings } from '../../shared/types/env';
import type { AuthContextUser } from '../../shared/types/user';
import { notifyNewMessage } from '../notifications/notifications.events';
import { loadVisibleOrder, resolveAccess } from '../orders/orders.access';
import type { OrderRow } from '../orders/orders.types';
import {
  countUnreadMessages,
  findLastReadAt,
  insertMessageRow,
  listMessageRows,
  upsertLastRead,
} from './messages.repo';
import type { MessageRow, MessageSenderRole, MessageView, ThreadView } from './messages.types';

/** Batas panjang pesan; sama dengan constraint di tabel order_messages. */
export const MESSAGE_MAX_LENGTH = 1000;

/**
 * Siapa pun yang boleh melihat order boleh ikut chat order itu: customer
 * pemilik, worker penangan (atau berizin manage_orders_all), dan owner.
 * Pemeriksaan akses memakai aturan order yang sudah ada supaya tidak berbeda.
 */
async function loadThreadOrder(
  env: Bindings,
  ctx: AuthContextUser,
  orderId: string,
): Promise<{ order: OrderRow; senderRole: MessageSenderRole }> {
  const access = await resolveAccess(env, ctx);
  const order = await loadVisibleOrder(env, access, orderId);
  return { order, senderRole: ctx.user.role };
}

function toView(row: MessageRow, viewerId: string): MessageView {
  return {
    id: row.id,
    order_id: row.order_id,
    sender_id: row.sender_id,
    sender_role: row.sender_role,
    body: row.body,
    created_at: row.created_at,
    mine: row.sender_id === viewerId,
  };
}

export async function getThread(
  env: Bindings,
  ctx: AuthContextUser,
  orderId: string,
): Promise<ThreadView> {
  const { order } = await loadThreadOrder(env, ctx, orderId);
  const [rows, lastReadAt] = await Promise.all([
    listMessageRows(env, order.id),
    findLastReadAt(env, order.id, ctx.user.id),
  ]);

  const unread = await countUnreadMessages(env, {
    orderId: order.id,
    userId: ctx.user.id,
    since: lastReadAt,
  });

  return { items: rows.map((row) => toView(row, ctx.user.id)), unread };
}

export async function sendMessage(
  env: Bindings,
  ctx: AuthContextUser,
  orderId: string,
  rawBody: string,
): Promise<MessageView> {
  const body = rawBody.trim();
  const { order, senderRole } = await loadThreadOrder(env, ctx, orderId);

  const saved = await insertMessageRow(env, {
    orderId: order.id,
    senderId: ctx.user.id,
    senderRole,
    body,
  });

  // Pengirim otomatis dianggap sudah membaca sampai pesannya sendiri.
  await upsertLastRead(env, {
    orderId: order.id,
    userId: ctx.user.id,
    at: saved.created_at,
  }).catch((err) => console.error('messages: gagal menandai baca pengirim', err));

  await notifyNewMessage(
    env,
    {
      id: String(order.id),
      order_number: String(order.order_number),
      customer_id: (order.customer_id as string | null) ?? null,
      assigned_worker_id: (order.assigned_worker_id as string | null) ?? null,
    },
    {
      senderId: ctx.user.id,
      senderRole,
      preview: body,
    },
  );

  return toView(saved, ctx.user.id);
}

/** Menandai seluruh pesan order ini sudah dibaca pemanggil. */
export async function markThreadRead(
  env: Bindings,
  ctx: AuthContextUser,
  orderId: string,
): Promise<{ unread: number }> {
  const { order } = await loadThreadOrder(env, ctx, orderId);
  await upsertLastRead(env, {
    orderId: order.id,
    userId: ctx.user.id,
    at: new Date().toISOString(),
  });
  return { unread: 0 };
}
