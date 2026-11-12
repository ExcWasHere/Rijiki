import { AppError } from '../../shared/errors';
import { deleteObject, keyFromPublicUrl } from '../../shared/storage/r2';
import type { Bindings } from '../../shared/types/env';
import { logActivity } from '../../shared/utils/activity-log';
import {
  getEventRow,
  getEventView,
  insertEventRow,
  listAllEvents,
  listPromoOptionRows,
  listPublishedEvents,
  promoExists,
  updateEventRow,
} from './events.repo';
import { validateEventDates } from './events.schema';
import type { CreateEventInput, ListEventsQuery, UpdateEventInput } from './events.schema';
import type { EventView, EventWrite, PromoOptionView } from './events.types';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const BANNER_FOLDER = 'events/';

function notFound(): AppError {
  return new AppError(404, 'not_found', 'Event tidak ditemukan');
}

/** Tanggal hari ini di WIB (UTC+7) sebagai YYYY-MM-DD. */
function todayWib(): string {
  return new Date(Date.now() + 7 * 60 * 60 * 1000).toISOString().slice(0, 10);
}

function cleanText(value: string | null | undefined): string | null {
  const trimmed = value?.trim();
  return trimmed ? trimmed : null;
}

/**
 * Banner hanya boleh berupa URL hasil unggahan lewat /api/media/event-banner
 * (bucket publik, folder events/). Mencegah URL luar disimpan.
 * undefined = tidak diubah, null = dihapus.
 */
function normalizeBanner(env: Bindings, url: string | null | undefined): string | null | undefined {
  if (url === undefined) return undefined;
  const trimmed = url?.trim() ?? '';
  if (trimmed === '') return null;

  const key = keyFromPublicUrl(env, trimmed);
  if (!key || !key.startsWith(BANNER_FOLDER)) {
    throw new AppError(400, 'validation_error', 'Banner harus diunggah lewat aplikasi.');
  }
  return trimmed;
}

async function assertPromoExists(env: Bindings, promoId: string): Promise<void> {
  if (!(await promoExists(env, promoId))) {
    throw new AppError(400, 'validation_error', 'Promo yang dipilih tidak ditemukan.');
  }
}

// ---------------------------------------------------------------------------
// Customer
// ---------------------------------------------------------------------------

/**
 * Event yang tampil ke customer: published, belum lewat end_date, dan bila
 * terhubung ke promo maka promonya harus tersedia (aktif, dalam periode, kuota
 * belum habis). Event dengan promo yang tidak tersedia disembunyikan.
 */
export async function listCustomerEvents(
  env: Bindings,
  query: ListEventsQuery,
): Promise<{ items: EventView[] }> {
  const views = await listPublishedEvents(env, todayWib(), query.event_type);
  return {
    items: views.filter((event) => !event.related_promo_id || event.promo?.available === true),
  };
}

// ---------------------------------------------------------------------------
// Owner / worker berizin manage_cms_events
// ---------------------------------------------------------------------------

export async function listManagedEvents(env: Bindings): Promise<{ items: EventView[] }> {
  return { items: await listAllEvents(env, todayWib()) };
}

export async function listPromoOptions(env: Bindings): Promise<{ items: PromoOptionView[] }> {
  return { items: await listPromoOptionRows(env) };
}

export async function createEvent(
  env: Bindings,
  userId: string,
  input: CreateEventInput,
): Promise<EventView> {
  const banner = normalizeBanner(env, input.banner_image_url) ?? null;
  const promoId = input.related_promo_id ?? null;
  if (promoId) await assertPromoExists(env, promoId);

  const write: EventWrite = {
    title: input.title,
    event_type: input.event_type,
    description: cleanText(input.description),
    banner_image_url: banner,
    related_promo_id: promoId,
    start_date: input.start_date ?? null,
    end_date: input.end_date ?? null,
    is_published: input.is_published ?? true,
  };
  const id = await insertEventRow(env, write);

  await logActivity(env, {
    userId,
    action: 'event_create',
    entity: 'event',
    entityId: id,
    metadata: { title: write.title, event_type: write.event_type },
  });

  const view = await getEventView(env, id, todayWib());
  if (!view) throw notFound();
  return view;
}

export async function updateEvent(
  env: Bindings,
  userId: string,
  eventId: string,
  input: UpdateEventInput,
): Promise<EventView> {
  if (!UUID_RE.test(eventId)) throw notFound();
  const row = await getEventRow(env, eventId);
  if (!row) throw notFound();

  // Validasi tanggal memakai nilai gabungan (yang dikirim + yang tersimpan).
  const start = input.start_date !== undefined ? input.start_date : (row.start_date as string | null);
  const end = input.end_date !== undefined ? input.end_date : (row.end_date as string | null);
  const dateMessage = validateEventDates(start, end);
  if (dateMessage) throw new AppError(400, 'validation_error', dateMessage);

  const banner = normalizeBanner(env, input.banner_image_url);
  if (input.related_promo_id) await assertPromoExists(env, input.related_promo_id);

  const patch: Record<string, unknown> = {};
  if (input.title !== undefined) patch['title'] = input.title;
  if (input.event_type !== undefined) patch['event_type'] = input.event_type;
  if (input.description !== undefined) patch['description'] = cleanText(input.description);
  if (banner !== undefined) patch['banner_image_url'] = banner;
  if (input.related_promo_id !== undefined) patch['related_promo_id'] = input.related_promo_id;
  if (input.start_date !== undefined) patch['start_date'] = input.start_date;
  if (input.end_date !== undefined) patch['end_date'] = input.end_date;
  if (input.is_published !== undefined) patch['is_published'] = input.is_published;

  const changed = Object.keys(patch);
  await updateEventRow(env, eventId, patch);

  // Banner lama dibersihkan dari R2 setelah data berhasil tersimpan.
  if (banner !== undefined && banner !== row.banner_image_url) {
    const oldKey = keyFromPublicUrl(env, row.banner_image_url as string | null);
    if (oldKey && oldKey.startsWith(BANNER_FOLDER)) {
      await deleteObject(env, 'public', oldKey).catch((e) =>
        console.error('events: gagal menghapus banner lama', e),
      );
    }
  }

  const onlyToggle = changed.length === 1 && changed[0] === 'is_published';
  await logActivity(env, {
    userId,
    action: onlyToggle ? (input.is_published ? 'event_publish' : 'event_unpublish') : 'event_update',
    entity: 'event',
    entityId: eventId,
    metadata: { fields: changed },
  });

  const view = await getEventView(env, eventId, todayWib());
  if (!view) throw notFound();
  return view;
}
