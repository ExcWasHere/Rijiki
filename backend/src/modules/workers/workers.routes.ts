import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import { requireOwner, requirePermission } from '../../middleware/permission';
import type { AppEnv } from '../../shared/types/env';
import {
  createWorkerHandler,
  getKpiHandler,
  getPermissionsHandler,
  kpiOverviewHandler,
  listAssignableHandler,
  listManagedHandler,
  reviewsHandler,
  saveAssessmentHandler,
  setPermissionsHandler,
  updateWorkerHandler,
} from './workers.controller';

/** /api/workers */
export const workersRoutes = new Hono<AppEnv>();
workersRoutes.use('*', authMiddleware);

// Daftar ringkas worker aktif untuk memilih worker saat assign (izin dicek di handler).
workersRoutes.get('/', listAssignableHandler);

// Manajemen karyawan: owner atau worker berizin manage_workers.
workersRoutes.get('/manage', requirePermission('manage_workers'), listManagedHandler);
workersRoutes.post('/', requirePermission('manage_workers'), createWorkerHandler);
workersRoutes.patch('/:id', requirePermission('manage_workers'), updateWorkerHandler);

// Ulasan dan KPI: dibaca owner atau pemegang manage_workers. Penilaian KPI hanya
// diisi owner (PRD: "diisi Owner"), supaya worker berizin tidak menilai dirinya sendiri.
workersRoutes.get('/kpi-overview', requirePermission('manage_workers'), kpiOverviewHandler);
workersRoutes.get('/:id/reviews', requirePermission('manage_workers'), reviewsHandler);
workersRoutes.get('/:id/kpi', requirePermission('manage_workers'), getKpiHandler);
workersRoutes.put('/:id/kpi', requireOwner(), saveAssessmentHandler);

/** /api/owner/workers: izin delegasi, hanya owner yang boleh menulis (PRD 5.1). */
export const ownerWorkersRoutes = new Hono<AppEnv>();
ownerWorkersRoutes.use('*', authMiddleware);
ownerWorkersRoutes.use('*', requireOwner());
ownerWorkersRoutes.get('/:id/permissions', getPermissionsHandler);
ownerWorkersRoutes.put('/:id/permissions', setPermissionsHandler);
