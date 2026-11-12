import { AppError } from '../../shared/errors';
import { deleteObject, keyFromPublicUrl } from '../../shared/storage/r2';
import type { Bindings } from '../../shared/types/env';
import { logActivity } from '../../shared/utils/activity-log';
import {
  getMerchandiseRow,
  insertMerchandiseRow,
  listMerchandiseRows,
  updateMerchandiseRow,
} from './merchandise.repo';
import type { CreateMerchandiseInput, UpdateMerchandiseInput } from './merchandise.schema';
import type { MerchandiseView, MerchandiseWrite } from './merchandise.types';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const IMAGE_FOLDER = 'merchandise/';

function notFound(): AppError {
  return new AppError(404, 'not_found', 'Merchandise tidak ditemukan');
}

function cleanText(value: string | null | undefined): string | null {
  const trimmed = value?.trim();
  return trimmed ? trimmed : null;
}

/**
 * Gambar hanya boleh berupa URL hasil unggahan lewat /api/media/merchandise-image
 * (bucket publik, folder merchandise/). Mencegah URL luar disimpan.
 * undefined = tidak diubah, null = dihapus.
 */
function normalizeImage(env: Bindings, url: string | null | undefined): string | null | undefined {
  if (url === undefined) return undefined;
  const trimmed = url?.trim() ?? '';
  if (trimmed === '') return null;

  const key = keyFromPublicUrl(env, trimmed);
  if (!key || !key.startsWith(IMAGE_FOLDER)) {
    throw new AppError(400, 'validation_error', 'Foto harus diunggah lewat aplikasi.');
  }
  return trimmed;
}

export async function listMerchandise(env: Bindings): Promise<{ items: MerchandiseView[] }> {
  return { items: await listMerchandiseRows(env) };
}

export async function createMerchandise(
  env: Bindings,
  userId: string,
  input: CreateMerchandiseInput,
): Promise<MerchandiseView> {
  const write: MerchandiseWrite = {
    name: input.name,
    description: cleanText(input.description),
    price: input.price,
    points_cost: input.points_cost ?? null,
    stock_quantity: input.stock_quantity ?? null,
    image_url: normalizeImage(env, input.image_url) ?? null,
    is_active: input.is_active ?? true,
  };
  const created = await insertMerchandiseRow(env, write);

  await logActivity(env, {
    userId,
    action: 'merchandise_create',
    entity: 'merchandise',
    entityId: created.id,
    metadata: { name: created.name, points_cost: created.points_cost },
  });
  return created;
}

export async function updateMerchandise(
  env: Bindings,
  userId: string,
  merchandiseId: string,
  input: UpdateMerchandiseInput,
): Promise<MerchandiseView> {
  if (!UUID_RE.test(merchandiseId)) throw notFound();
  const row = await getMerchandiseRow(env, merchandiseId);
  if (!row) throw notFound();

  const image = normalizeImage(env, input.image_url);

  const patch: Record<string, unknown> = {};
  if (input.name !== undefined) patch['name'] = input.name;
  if (input.description !== undefined) patch['description'] = cleanText(input.description);
  if (input.price !== undefined) patch['price'] = input.price;
  if (input.points_cost !== undefined) patch['points_cost'] = input.points_cost;
  if (input.stock_quantity !== undefined) patch['stock_quantity'] = input.stock_quantity;
  if (image !== undefined) patch['image_url'] = image;
  if (input.is_active !== undefined) patch['is_active'] = input.is_active;

  const changed = Object.keys(patch);
  patch['updated_at'] = new Date().toISOString();
  const updated = await updateMerchandiseRow(env, merchandiseId, patch);

  // Gambar lama dibersihkan dari R2 setelah data berhasil tersimpan.
  if (image !== undefined && image !== row.image_url) {
    const oldKey = keyFromPublicUrl(env, row.image_url as string | null);
    if (oldKey && oldKey.startsWith(IMAGE_FOLDER)) {
      await deleteObject(env, 'public', oldKey).catch((e) =>
        console.error('merchandise: gagal menghapus gambar lama', e),
      );
    }
  }

  const onlyToggle = changed.length === 1 && changed[0] === 'is_active';
  await logActivity(env, {
    userId,
    action: onlyToggle
      ? input.is_active
        ? 'merchandise_activate'
        : 'merchandise_deactivate'
      : 'merchandise_update',
    entity: 'merchandise',
    entityId: merchandiseId,
    metadata: { fields: changed },
  });
  return updated;
}
