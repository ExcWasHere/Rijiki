import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import type { MessageRow, MessageSenderRole } from './messages.types';

const MESSAGE_COLUMNS = 'id, order_id, sender_id, sender_role, body, created_at';

/** Jumlah pesan terakhir yang dimuat; chat order tidak butuh riwayat penuh. */
const THREAD_PAGE_SIZE = 200;

function failed(label: string, message: string): AppError {
  console.error(`messages: gagal ${label}`, message);
  return new AppError(500, 'messages_failed', 'Gagal memproses chat. Coba lagi ya.');
}

function toRow(raw: unknown): MessageRow {
  const data = raw as Record<string, unknown>;
  return {
    id: data['id'] as string,
    order_id: data['order_id'] as string,
    sender_id: data['sender_id'] as string,
    sender_role: data['sender_role'] as MessageSenderRole,
    body: String(data['body']),
    created_at: String(data['created_at']),
  };
}

/**
 * Pesan terbaru [limit] buah, dikembalikan urut lama → baru supaya UI bisa
 * langsung menambahkan tanpa membalik urutan.
 */
export async function listMessageRows(
  env: Bindings,
  orderId: string,
  limit = THREAD_PAGE_SIZE,
): Promise<MessageRow[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('order_messages')
    .select(MESSAGE_COLUMNS)
    .eq('order_id', orderId)
    .order('created_at', { ascending: false })
    .limit(limit);

  if (error) throw failed('memuat chat', error.message);
  return ((data ?? []) as unknown[]).map(toRow).reverse();
}

export async function insertMessageRow(
  env: Bindings,
  params: {
    orderId: string;
    senderId: string;
    senderRole: MessageSenderRole;
    body: string;
  },
): Promise<MessageRow> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('order_messages')
    .insert({
      order_id: params.orderId,
      sender_id: params.senderId,
      sender_role: params.senderRole,
      body: params.body,
    })
    .select(MESSAGE_COLUMNS)
    .single();

  if (error) throw failed('menyimpan pesan', error.message);
  return toRow(data);
}

/** Waktu baca terakhir pemanggil untuk order ini; null = belum pernah membuka. */
export async function findLastReadAt(
  env: Bindings,
  orderId: string,
  userId: string,
): Promise<string | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('order_chat_reads')
    .select('last_read_at')
    .eq('order_id', orderId)
    .eq('user_id', userId)
    .maybeSingle();

  if (error) throw failed('memuat status baca', error.message);
  return data ? String((data as Record<string, unknown>)['last_read_at']) : null;
}

export async function upsertLastRead(
  env: Bindings,
  params: { orderId: string; userId: string; at: string },
): Promise<void> {
  const admin = getSupabaseAdmin(env);
  const { error } = await admin
    .from('order_chat_reads')
    .upsert(
      {
        order_id: params.orderId,
        user_id: params.userId,
        last_read_at: params.at,
      },
      { onConflict: 'order_id,user_id' },
    );

  if (error) throw failed('menyimpan status baca', error.message);
}

/** Jumlah pesan dari orang lain setelah [since]; 0 bila [since] null berarti semua. */
export async function countUnreadMessages(
  env: Bindings,
  params: { orderId: string; userId: string; since: string | null },
): Promise<number> {
  const admin = getSupabaseAdmin(env);
  let builder = admin
    .from('order_messages')
    .select('id', { count: 'exact', head: true })
    .eq('order_id', params.orderId)
    .neq('sender_id', params.userId);

  if (params.since) builder = builder.gt('created_at', params.since);

  const { count, error } = await builder;
  if (error) throw failed('menghitung pesan belum dibaca', error.message);
  return count ?? 0;
}
