import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { logActivity } from '../../shared/utils/activity-log';
import { fingerprintOf, idempotencyConflict } from '../../shared/utils/idempotency';
import { toNumber } from '../../shared/utils/number';
import {
  countExistingServices,
  deleteNewPromoRow,
  findPromoByIdempotencyKey,
  findPromoIdByCode,
  getPromoRow,
  getPromoUsageCount,
  getPromoView,
  insertPromoRow,
  listPromoViews,
  replacePromoServices,
  updatePromoRow,
} from './promos.repo';
import { validatePromoShape } from './promos.schema';
import type { CreatePromoInput, UpdatePromoInput } from './promos.schema';
import type { PromoView, PromoWrite } from './promos.types';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function notFound(): AppError {
  return new AppError(404, 'not_found', 'Promo tidak ditemukan');
}

function cleanText(value: string | null | undefined): string | null {
  const trimmed = value?.trim();
  return trimmed ? trimmed : null;
}

function uniqueIds(ids: string[] | undefined): string[] {
  return [...new Set(ids ?? [])];
}

async function assertServicesExist(env: Bindings, ids: string[]): Promise<void> {
  if (ids.length === 0) return;
  const found = await countExistingServices(env, ids);
  if (found !== ids.length) {
    throw new AppError(400, 'validation_error', 'Salah satu layanan promo tidak ditemukan.');
  }
}

export async function listPromos(env: Bindings): Promise<{ items: PromoView[] }> {
  return { items: await listPromoViews(env) };
}

export interface SavePromoResult {
  promo: PromoView;
  replayed: boolean;
}

async function replayFor(
  env: Bindings,
  existing: { id: string; fingerprint: string | null },
  fingerprint: string | null,
): Promise<SavePromoResult> {
  if (existing.fingerprint !== fingerprint) throw idempotencyConflict();
  const promo = await getPromoView(env, existing.id);
  if (!promo) throw notFound();
  return { promo, replayed: true };
}

export async function createPromo(
  env: Bindings,
  userId: string,
  input: CreatePromoInput,
  idempotencyKey: string | null,
): Promise<SavePromoResult> {
  const serviceIds = uniqueIds(input.service_ids);
  const write: PromoWrite = {
    code: input.code,
    title: input.title,
    description: cleanText(input.description),
    discount_type: input.discount_type,
    discount_value: input.discount_value,
    start_date: input.start_date,
    end_date: input.end_date,
    is_active: input.is_active ?? true,
    applies_to: input.applies_to ?? 'subtotal',
    min_subtotal: input.min_subtotal ?? null,
    max_discount_amount: input.max_discount_amount ?? null,
    usage_limit: input.usage_limit ?? null,
    usage_limit_per_customer: input.usage_limit_per_customer ?? null,
    first_order_only: input.first_order_only ?? false,
  };

  const fingerprint = idempotencyKey ? await fingerprintOf({ ...write, service_ids: [...serviceIds].sort() }) : null;

  if (idempotencyKey) {
    const existing = await findPromoByIdempotencyKey(env, idempotencyKey);
    if (existing) return replayFor(env, existing, fingerprint);
  }

  if (await findPromoIdByCode(env, write.code)) {
    throw new AppError(409, 'promo_code_taken', 'Kode promo ini sudah dipakai.');
  }
  await assertServicesExist(env, serviceIds);

  const inserted = await insertPromoRow(env, write, { key: idempotencyKey, fingerprint });
  if (!inserted.ok) {
    // Bentrok unik: bisa dari request ganda yang bersamaan (kunci sama) atau kode kembar.
    if (idempotencyKey) {
      const existing = await findPromoByIdempotencyKey(env, idempotencyKey);
      if (existing) return replayFor(env, existing, fingerprint);
    }
    throw new AppError(409, 'promo_code_taken', 'Kode promo ini sudah dipakai.');
  }

  try {
    if (serviceIds.length > 0) await replacePromoServices(env, inserted.id, serviceIds);
  } catch (err) {
    await deleteNewPromoRow(env, inserted.id);
    throw err;
  }

  await logActivity(env, {
    userId,
    action: 'promo_create',
    entity: 'promo',
    entityId: inserted.id,
    metadata: { code: write.code },
  });

  const promo = await getPromoView(env, inserted.id);
  if (!promo) throw notFound();
  return { promo, replayed: false };
}

export async function updatePromo(
  env: Bindings,
  userId: string,
  promoId: string,
  input: UpdatePromoInput,
): Promise<PromoView> {
  if (!UUID_RE.test(promoId)) throw notFound();

  const row = await getPromoRow(env, promoId);
  if (!row) throw notFound();

  const currentServiceIds: string[] = Array.isArray(row.promo_services)
    ? row.promo_services.map((s: { service_id: string }) => s.service_id)
    : [];

  // Validasi antar-field memakai nilai gabungan (yang dikirim + yang sudah tersimpan).
  const message = validatePromoShape({
    discount_type: input.discount_type ?? row.discount_type,
    discount_value: input.discount_value ?? toNumber(row.discount_value),
    start_date: input.start_date ?? row.start_date,
    end_date: input.end_date ?? row.end_date,
    applies_to: input.applies_to ?? row.applies_to ?? 'subtotal',
    service_ids: input.service_ids ?? currentServiceIds,
  });
  if (message) throw new AppError(400, 'validation_error', message);

  // Kode terkunci setelah promo pernah dipakai order, supaya riwayat tetap terbaca.
  if (input.code !== undefined && input.code.toLowerCase() !== String(row.code).toLowerCase()) {
    if ((await getPromoUsageCount(env, promoId)) > 0) {
      throw new AppError(
        409,
        'promo_code_locked',
        'Kode promo sudah pernah dipakai order, jadi tidak bisa diubah. Buat promo baru kalau butuh kode lain.',
      );
    }
    const other = await findPromoIdByCode(env, input.code);
    if (other && other !== promoId) {
      throw new AppError(409, 'promo_code_taken', 'Kode promo ini sudah dipakai promo lain.');
    }
  }

  const serviceIds = input.service_ids !== undefined ? uniqueIds(input.service_ids) : null;
  if (serviceIds) await assertServicesExist(env, serviceIds);

  const patch: Record<string, unknown> = {};
  if (input.code !== undefined) patch['code'] = input.code;
  if (input.title !== undefined) patch['title'] = input.title;
  if (input.description !== undefined) patch['description'] = cleanText(input.description);
  if (input.discount_type !== undefined) patch['discount_type'] = input.discount_type;
  if (input.discount_value !== undefined) patch['discount_value'] = input.discount_value;
  if (input.start_date !== undefined) patch['start_date'] = input.start_date;
  if (input.end_date !== undefined) patch['end_date'] = input.end_date;
  if (input.is_active !== undefined) patch['is_active'] = input.is_active;
  if (input.applies_to !== undefined) patch['applies_to'] = input.applies_to;
  if (input.min_subtotal !== undefined) patch['min_subtotal'] = input.min_subtotal;
  if (input.max_discount_amount !== undefined) patch['max_discount_amount'] = input.max_discount_amount;
  if (input.usage_limit !== undefined) patch['usage_limit'] = input.usage_limit;
  if (input.usage_limit_per_customer !== undefined) {
    patch['usage_limit_per_customer'] = input.usage_limit_per_customer;
  }
  if (input.first_order_only !== undefined) patch['first_order_only'] = input.first_order_only;

  const changed = Object.keys(patch);
  patch['updated_at'] = new Date().toISOString();

  await updatePromoRow(env, promoId, patch);
  if (serviceIds) await replacePromoServices(env, promoId, serviceIds);

  const onlyToggle = changed.length === 1 && changed[0] === 'is_active' && serviceIds === null;
  await logActivity(env, {
    userId,
    action: onlyToggle ? (input.is_active ? 'promo_activate' : 'promo_deactivate') : 'promo_update',
    entity: 'promo',
    entityId: promoId,
    metadata: { fields: serviceIds ? [...changed, 'service_ids'] : changed },
  });

  const promo = await getPromoView(env, promoId);
  if (!promo) throw notFound();
  return promo;
}
