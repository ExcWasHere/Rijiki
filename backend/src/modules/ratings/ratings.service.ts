import { AppError } from '../../shared/errors';
import { readImageFile } from '../../shared/storage/image';
import { buildKey, copyObject, deleteObject, publicUrl, putImage } from '../../shared/storage/r2';
import type { Bindings } from '../../shared/types/env';
import type { AuthContextUser } from '../../shared/types/user';
import { logActivity } from '../../shared/utils/activity-log';
import { parseInput } from '../../shared/utils/validate';
import { findCustomerProfileByUserId } from '../orders/orders.repo';
import { awardRatingPoints } from '../points/points.service';
import {
  getOrderForRating,
  getRatingRow,
  getRatingsSummary,
  insertRatingRow,
  listFeaturedRows,
  listManagedRows,
  ratingExistsForOrder,
  updateFeatured,
} from './ratings.repo';
import { createRatingSchema } from './ratings.schema';
import type { ListRatingsQuery } from './ratings.schema';
import type {
  FeaturedTestimonialView,
  ManagedRatingView,
  RatingCreatedView,
  RatingRow,
  RatingSummaryView,
} from './ratings.types';

export const RATING_PHOTO_MAX_BYTES = 5 * 1024 * 1024;
const FEATURED_LIMIT = 10;
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function one(value: any): any {
  if (Array.isArray(value)) return value[0] ?? null;
  return value ?? null;
}

/** Nama layanan unik pada order, urutan sesuai item. */
export function serviceNamesOf(order: RatingRow | null): string[] {
  const items: RatingRow[] = Array.isArray(order?.order_items) ? order.order_items : [];
  const names: string[] = [];
  for (const item of items) {
    const name = one(item.services)?.name as string | undefined;
    if (name && !names.includes(name)) names.push(name);
  }
  return names;
}

/** "Rina Anggraini" -> "Rina A."; satu kata dibiarkan. */
export function maskName(fullName: string | null | undefined): string {
  const parts = (fullName ?? '').trim().split(/\s+/).filter(Boolean);
  const first = parts[0];
  if (!first) return 'Pelanggan Rijiki';
  const last = parts.length > 1 ? parts[parts.length - 1] : null;
  return last ? `${first} ${last.charAt(0).toUpperCase()}.` : first;
}

export function mapManaged(row: RatingRow): ManagedRatingView {
  const order = one(row.order);
  return {
    id: row.id as string,
    order_id: row.order_id as string,
    order_number: (order?.order_number as string | null) ?? null,
    customer_name: (one(one(row.customer)?.users)?.full_name as string | null) ?? null,
    worker_name: (one(one(row.worker)?.users)?.full_name as string | null) ?? null,
    service_names: serviceNamesOf(order),
    rating_value: Number(row.rating_value),
    comment: (row.comment as string | null) ?? null,
    photo_key: (row.photo_url as string | null) ?? null,
    is_featured: Boolean(row.is_featured),
    created_at: row.created_at as string,
  };
}

// ---------------------------------------------------------------------------
// Customer memberi rating
// ---------------------------------------------------------------------------

export async function createRating(
  env: Bindings,
  ctx: AuthContextUser,
  orderId: string,
  body: Record<string, unknown>,
): Promise<RatingCreatedView> {
  if (ctx.user.role !== 'customer') {
    throw new AppError(403, 'forbidden', 'Hanya customer yang dapat memberi rating');
  }
  if (!UUID_RE.test(orderId)) throw new AppError(404, 'not_found', 'Order tidak ditemukan');

  const fields = parseInput(createRatingSchema, {
    rating_value: body['rating_value'],
    comment: typeof body['comment'] === 'string' && body['comment'] !== '' ? body['comment'] : undefined,
  });

  const profile = await findCustomerProfileByUserId(env, ctx.user.id);
  const order = await getOrderForRating(env, orderId);
  if (!profile || !order || order.customer_id !== profile.id) {
    throw new AppError(404, 'not_found', 'Order tidak ditemukan');
  }
  if (order.status !== 'completed') {
    throw new AppError(409, 'order_not_completed', 'Rating hanya bisa diberikan setelah order selesai.');
  }
  if (await ratingExistsForOrder(env, orderId)) {
    throw new AppError(409, 'already_rated', 'Order ini sudah kamu beri rating.');
  }

  // Foto opsional. File kosong dianggap tidak ada; file rusak/terlalu besar ditolak.
  const photo = body['photo'];
  let photoKey: string | null = null;
  if (photo instanceof File && photo.size > 0) {
    const image = await readImageFile(photo, RATING_PHOTO_MAX_BYTES);
    // testimonials/<user_id customer>/... : aturan baca di media.policy.
    photoKey = buildKey('testimonials', ctx.user.id, image.ext);
    await putImage(env, 'private', photoKey, image);
  }

  let inserted;
  try {
    inserted = await insertRatingRow(env, {
      orderId,
      customerId: profile.id,
      workerId: order.assigned_worker_id,
      ratingValue: fields.rating_value,
      comment: fields.comment && fields.comment.length > 0 ? fields.comment : null,
      photoKey,
    });
  } catch (err) {
    if (photoKey) await deleteObject(env, 'private', photoKey).catch(() => undefined);
    throw err;
  }

  if (!inserted.ok) {
    // Dua request bersamaan: yang kalah membuang fotonya dan mendapat galat yang sama.
    if (photoKey) await deleteObject(env, 'private', photoKey).catch(() => undefined);
    throw new AppError(409, 'already_rated', 'Order ini sudah kamu beri rating.');
  }

  // Poin rating: galatnya hanya dicatat; fungsi SQL-nya idempoten (1x per order).
  const pointsAwarded = await awardRatingPoints(env, orderId);

  await logActivity(env, {
    userId: ctx.user.id,
    action: 'rating_create',
    entity: 'rating',
    entityId: inserted.id,
    metadata: { order_id: orderId, rating_value: fields.rating_value, has_photo: photoKey !== null },
  });

  return {
    id: inserted.id,
    order_id: orderId,
    rating_value: fields.rating_value,
    comment: fields.comment && fields.comment.length > 0 ? fields.comment : null,
    photo_key: photoKey,
    created_at: inserted.created_at,
    points_awarded: pointsAwarded,
  };
}

// ---------------------------------------------------------------------------
// Testimoni pilihan (home customer)
// ---------------------------------------------------------------------------

export async function listFeaturedTestimonials(
  env: Bindings,
): Promise<{ items: FeaturedTestimonialView[] }> {
  const rows = await listFeaturedRows(env, FEATURED_LIMIT);
  return {
    items: rows.map((row) => {
      const key = (row.photo_url as string | null) ?? null;
      return {
        id: row.id as string,
        customer_name: maskName(one(one(row.customer)?.users)?.full_name as string | null),
        rating_value: Number(row.rating_value),
        service_name: serviceNamesOf(one(row.order))[0] ?? null,
        comment: (row.comment as string | null) ?? null,
        // Salinan publik dibuat saat featured diaktifkan (key sama).
        photo_url: key ? publicUrl(env, key) : null,
        created_at: row.created_at as string,
      };
    }),
  };
}

// ---------------------------------------------------------------------------
// Staf: daftar rating dan tandai featured
// ---------------------------------------------------------------------------

export async function listManagedRatings(
  env: Bindings,
  query: ListRatingsQuery,
): Promise<{
  items: ManagedRatingView[];
  page: number;
  limit: number;
  total: number;
  summary: RatingSummaryView;
}> {
  const [{ rows, total }, summary] = await Promise.all([
    listManagedRows(env, query),
    getRatingsSummary(env),
  ]);
  return { items: rows.map(mapManaged), page: query.page, limit: query.limit, total, summary };
}

export async function setRatingFeatured(
  env: Bindings,
  userId: string,
  ratingId: string,
  isFeatured: boolean,
): Promise<ManagedRatingView> {
  if (!UUID_RE.test(ratingId)) throw new AppError(404, 'not_found', 'Rating tidak ditemukan');
  const row = await getRatingRow(env, ratingId);
  if (!row) throw new AppError(404, 'not_found', 'Rating tidak ditemukan');

  // Idempoten: status yang sama tidak mengubah apa-apa.
  if (Boolean(row.is_featured) === isFeatured) return mapManaged(row);

  const key = (row.photo_url as string | null) ?? null;

  if (isFeatured) {
    // Salin foto ke bucket publik dulu; bila gagal, rating tidak jadi featured.
    let copied = false;
    if (key) {
      copied = await copyObject(env, 'private', 'public', key);
      if (!copied) {
        throw new AppError(
          409,
          'photo_missing',
          'Foto testimoni tidak ditemukan di penyimpanan, jadi belum bisa dijadikan testimoni pilihan.',
        );
      }
    }
    try {
      await updateFeatured(env, ratingId, true);
    } catch (err) {
      if (copied && key) await deleteObject(env, 'public', key).catch(() => undefined);
      throw err;
    }
  } else {
    await updateFeatured(env, ratingId, false);
    if (key) {
      await deleteObject(env, 'public', key).catch((err) =>
        console.error('ratings: gagal menghapus salinan publik', key, err),
      );
    }
  }

  await logActivity(env, {
    userId,
    action: isFeatured ? 'testimonial_feature' : 'testimonial_unfeature',
    entity: 'rating',
    entityId: ratingId,
    metadata: { has_photo: key !== null },
  });

  const fresh = await getRatingRow(env, ratingId);
  if (!fresh) throw new AppError(404, 'not_found', 'Rating tidak ditemukan');
  return mapManaged(fresh);
}
