import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { logActivity } from '../../shared/utils/activity-log';
import {
  findServiceById,
  findServiceByName,
  insertServiceRow,
  listActiveServices,
  listAllServices,
  updateServiceRow,
} from './services.repo';
import type { CreateServiceInput, UpdateServiceInput } from './services.schema';
import type { ServiceView, ServiceWrite } from './services.types';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function notFound(): AppError {
  return new AppError(404, 'not_found', 'Layanan tidak ditemukan');
}

function duplicateName(): AppError {
  return new AppError(409, 'service_name_taken', 'Nama layanan ini sudah dipakai.');
}

function cleanText(value: string | null | undefined): string | null {
  const trimmed = value?.trim();
  return trimmed ? trimmed : null;
}

export async function getActiveServices(env: Bindings): Promise<{ items: ServiceView[] }> {
  const items = await listActiveServices(env);
  return { items };
}

export async function getServicesForCms(env: Bindings): Promise<{ items: ServiceView[] }> {
  return { items: await listAllServices(env) };
}

export async function createService(
  env: Bindings,
  userId: string,
  input: CreateServiceInput,
): Promise<ServiceView> {
  if (await findServiceByName(env, input.name)) throw duplicateName();

  const write: ServiceWrite = {
    name: input.name,
    category: input.category,
    base_price: input.base_price,
    description: cleanText(input.description),
    estimated_duration_minutes: input.estimated_duration_minutes ?? null,
    is_active: input.is_active ?? true,
  };
  const created = await insertServiceRow(env, write);

  await logActivity(env, {
    userId,
    action: 'service_create',
    entity: 'service',
    entityId: created.id,
    metadata: { name: created.name, base_price: created.base_price },
  });
  return created;
}

export async function updateService(
  env: Bindings,
  userId: string,
  serviceId: string,
  input: UpdateServiceInput,
): Promise<ServiceView> {
  if (!UUID_RE.test(serviceId)) throw notFound();
  const row = await findServiceById(env, serviceId);
  if (!row) throw notFound();

  if (input.name !== undefined && input.name !== row.name) {
    if (await findServiceByName(env, input.name, serviceId)) throw duplicateName();
  }

  const patch: Record<string, unknown> = {};
  if (input.name !== undefined) patch['name'] = input.name;
  if (input.category !== undefined) patch['category'] = input.category;
  if (input.base_price !== undefined) patch['base_price'] = input.base_price;
  if (input.description !== undefined) patch['description'] = cleanText(input.description);
  if (input.estimated_duration_minutes !== undefined) {
    patch['estimated_duration_minutes'] = input.estimated_duration_minutes;
  }
  if (input.is_active !== undefined) patch['is_active'] = input.is_active;

  const changed = Object.keys(patch);
  patch['updated_at'] = new Date().toISOString();
  const updated = await updateServiceRow(env, serviceId, patch);

  const onlyToggle = changed.length === 1 && changed[0] === 'is_active';
  await logActivity(env, {
    userId,
    action: onlyToggle
      ? input.is_active
        ? 'service_activate'
        : 'service_deactivate'
      : 'service_update',
    entity: 'service',
    entityId: serviceId,
    metadata: { fields: changed },
  });
  return updated;
}
