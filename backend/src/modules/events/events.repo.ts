import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { toNumber, toNumberOrNull } from '../../shared/utils/number';
import type {
  EventPromoView,
  EventRow,
  EventType,
  EventView,
  EventWrite,
  PromoOptionView,
} from './events.types';

const PROMO_FIELDS = [
  'id',
  'code',
  'title',
  'description',
  'discount_type',
  'discount_value',
  'applies_to',
  'min_subtotal',
  'max_discount_amount',
  'usage_limit',
  'first_order_only',
  'start_date',
  'end_date',
  'is_active',
].join(', ');

const EVENT_SELECT = [
  'id',
  'title',
  'description',
  'banner_image_url',
  'event_type',
  'related_promo_id',
  'start_date',
  'end_date',
  'is_published',
  'created_at',
  `promo:promos!events_related_promo_id_fkey(${PROMO_FIELDS})`,
].join(', ');

const LIST_LIMIT = 100;

function failed(label: string, message: string): AppError {
  console.error(`events: gagal ${label}`, message);
  return new AppError(500, 'event_failed', `Gagal ${label}. Coba lagi ya.`);
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function one(value: any): any {
  if (Array.isArray(value)) return value[0] ?? null;
  return value ?? null;
}

function mapPromo(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  promo: any,
  usage: number,
  today: string,
): EventPromoView {
  const limit = toNumberOrNull(promo.usage_limit);
  const quotaLeft = limit === null ? null : Math.max(0, limit - usage);
  const inPeriod = today >= (promo.start_date as string) && today <= (promo.end_date as string);
  return {
    id: promo.id as string,
    code: promo.code as string,
    title: promo.title as string,
    description: (promo.description as string | null) ?? null,
    discount_type: promo.discount_type,
    discount_value: toNumber(promo.discount_value),
    applies_to: (promo.applies_to as 'subtotal' | 'shipping' | null) ?? 'subtotal',
    min_subtotal: toNumberOrNull(promo.min_subtotal),
    max_discount_amount: toNumberOrNull(promo.max_discount_amount),
    first_order_only: Boolean(promo.first_order_only),
    start_date: promo.start_date as string,
    end_date: promo.end_date as string,
    is_active: Boolean(promo.is_active),
    quota_left: quotaLeft,
    available: Boolean(promo.is_active) && inPeriod && (quotaLeft === null || quotaLeft > 0),
  };
}

function mapEvent(row: EventRow, usage: Map<string, number>, today: string): EventView {
  const promo = one(row.promo);
  return {
    id: row.id as string,
    title: row.title as string,
    description: (row.description as string | null) ?? null,
    banner_image_url: (row.banner_image_url as string | null) ?? null,
    event_type: row.event_type as EventType,
    related_promo_id: (row.related_promo_id as string | null) ?? null,
    start_date: (row.start_date as string | null) ?? null,
    end_date: (row.end_date as string | null) ?? null,
    is_published: Boolean(row.is_published),
    created_at: row.created_at as string,
    promo: promo ? mapPromo(promo, usage.get(promo.id as string) ?? 0, today) : null,
  };
}

async function usageCounts(env: Bindings, ids: string[]): Promise<Map<string, number>> {
  const result = new Map<string, number>();
  if (ids.length === 0) return result;

  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin.rpc('promo_usage_counts', { p_promo_ids: ids });
  if (error) throw failed('memuat pemakaian promo', error.message);

  for (const row of (data ?? []) as Array<{ promo_id: string; used: number | string }>) {
    result.set(row.promo_id, toNumber(row.used));
  }
  return result;
}

async function toViews(env: Bindings, rows: EventRow[], today: string): Promise<EventView[]> {
  const promoIds = [
    ...new Set(rows.map((r) => r.related_promo_id as string | null).filter((id): id is string => !!id)),
  ];
  const usage = await usageCounts(env, promoIds);
  return rows.map((row) => mapEvent(row, usage, today));
}

/** Event tayang: published dan belum lewat tanggal selesainya. */
export async function listPublishedEvents(
  env: Bindings,
  today: string,
  eventType?: EventType,
): Promise<EventView[]> {
  const admin = getSupabaseAdmin(env);
  let builder = admin
    .from('events')
    .select(EVENT_SELECT)
    .eq('is_published', true)
    .or(`end_date.is.null,end_date.gte.${today}`);
  if (eventType) builder = builder.eq('event_type', eventType);

  const { data, error } = await builder
    .order('created_at', { ascending: false })
    .limit(LIST_LIMIT);
  if (error) throw failed('memuat daftar event', error.message);
  return toViews(env, (data ?? []) as unknown as EventRow[], today);
}

export async function listAllEvents(env: Bindings, today: string): Promise<EventView[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('events')
    .select(EVENT_SELECT)
    .order('created_at', { ascending: false })
    .limit(500);
  if (error) throw failed('memuat daftar event', error.message);
  return toViews(env, (data ?? []) as unknown as EventRow[], today);
}

export async function getEventRow(env: Bindings, id: string): Promise<EventRow | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin.from('events').select(EVENT_SELECT).eq('id', id).maybeSingle();
  if (error) throw failed('memuat event', error.message);
  return (data as unknown as EventRow | null) ?? null;
}

export async function getEventView(
  env: Bindings,
  id: string,
  today: string,
): Promise<EventView | null> {
  const row = await getEventRow(env, id);
  if (!row) return null;
  return (await toViews(env, [row], today))[0] ?? null;
}

export async function insertEventRow(env: Bindings, write: EventWrite): Promise<string> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin.from('events').insert(write).select('id').single();
  if (error || !data) throw failed('menyimpan event', error?.message ?? 'tidak ada data');
  return (data as { id: string }).id;
}

export async function updateEventRow(
  env: Bindings,
  id: string,
  patch: Record<string, unknown>,
): Promise<void> {
  const admin = getSupabaseAdmin(env);
  const { error } = await admin.from('events').update(patch).eq('id', id);
  if (error) throw failed('menyimpan perubahan event', error.message);
}

export async function promoExists(env: Bindings, id: string): Promise<boolean> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin.from('promos').select('id').eq('id', id).maybeSingle();
  if (error) throw failed('memeriksa promo', error.message);
  return Boolean(data);
}

export async function listPromoOptionRows(env: Bindings): Promise<PromoOptionView[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('promos')
    .select('id, code, title, is_active, start_date, end_date')
    .order('created_at', { ascending: false })
    .limit(200);
  if (error) throw failed('memuat pilihan promo', error.message);
  return ((data ?? []) as unknown as EventRow[]).map((row) => ({
    id: row.id as string,
    code: row.code as string,
    title: row.title as string,
    is_active: Boolean(row.is_active),
    start_date: row.start_date as string,
    end_date: row.end_date as string,
  }));
}
