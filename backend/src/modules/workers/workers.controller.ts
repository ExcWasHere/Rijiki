import type { Context } from 'hono';
import type { AppEnv } from '../../shared/types/env';
import { parseInput } from '../../shared/utils/validate';
import { listActiveWorkers } from './workers.repo';
import { getKpiOverview, getWorkerKpi, listWorkerReviews, saveAssessment } from './workers.kpi.service';
import {
  createWorkerSchema,
  kpiQuerySchema,
  saveAssessmentSchema,
  setPermissionsSchema,
  updateWorkerSchema,
} from './workers.schema';
import {
  createWorker,
  getWorkerPermissions,
  listWorkersForManagement,
  setWorkerPermissions,
  updateWorker,
} from './workers.service';
import { AppError } from '../../shared/errors';

/**
 * GET /api/workers: worker aktif untuk memilih worker saat assign order.
 * Hanya owner atau worker berizin manage_orders_all / manage_workers.
 */
export async function listAssignableHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const allowed =
    ctx.ownerBypass ||
    (ctx.user.role === 'worker' &&
      (ctx.permissions.includes('manage_orders_all') || ctx.permissions.includes('manage_workers')));

  if (!allowed) {
    throw new AppError(403, 'forbidden', 'Tidak punya izin melihat daftar worker');
  }
  return c.json({ items: await listActiveWorkers(c.env) });
}

/** GET /api/workers/manage */
export async function listManagedHandler(c: Context<AppEnv>) {
  c.header('Cache-Control', 'no-store');
  return c.json(await listWorkersForManagement(c.env));
}

/** POST /api/workers */
export async function createWorkerHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const input = parseInput(createWorkerSchema, await c.req.json().catch(() => null));
  return c.json(await createWorker(c.env, ctx.user.id, input), 201);
}

/** PATCH /api/workers/:id */
export async function updateWorkerHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const input = parseInput(updateWorkerSchema, await c.req.json().catch(() => null));
  return c.json(await updateWorker(c.env, ctx.user.id, c.req.param('id') ?? '', input));
}

/** GET /api/owner/workers/:id/permissions */
export async function getPermissionsHandler(c: Context<AppEnv>) {
  c.header('Cache-Control', 'no-store');
  return c.json(await getWorkerPermissions(c.env, c.req.param('id') ?? ''));
}

/** PUT /api/owner/workers/:id/permissions */
export async function setPermissionsHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const input = parseInput(setPermissionsSchema, await c.req.json().catch(() => null));
  return c.json(
    await setWorkerPermissions(c.env, ctx.user.id, c.req.param('id') ?? '', input.permissions),
  );
}

/** GET /api/workers/:id/reviews */
export async function reviewsHandler(c: Context<AppEnv>) {
  c.header('Cache-Control', 'no-store');
  return c.json(await listWorkerReviews(c.env, c.req.param('id') ?? ''));
}

/** GET /api/workers/:id/kpi?month=&year= */
export async function getKpiHandler(c: Context<AppEnv>) {
  const query = parseInput(kpiQuerySchema, c.req.query());
  c.header('Cache-Control', 'no-store');
  return c.json(await getWorkerKpi(c.env, c.req.param('id') ?? '', query));
}

/** GET /api/workers/kpi-overview?month=&year= */
export async function kpiOverviewHandler(c: Context<AppEnv>) {
  const query = parseInput(kpiQuerySchema, c.req.query());
  c.header('Cache-Control', 'no-store');
  return c.json(await getKpiOverview(c.env, query));
}

/** PUT /api/workers/:id/kpi: penilaian owner untuk bulan berjalan. */
export async function saveAssessmentHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const input = parseInput(saveAssessmentSchema, await c.req.json().catch(() => null));
  return c.json(await saveAssessment(c.env, ctx.user.id, c.req.param('id') ?? '', input));
}
