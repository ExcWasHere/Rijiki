import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import { requireOwner, requirePermission } from '../../middleware/permission';
import type { AppEnv } from '../../shared/types/env';
import {
  createWorkerHandler,
  getPermissionsHandler,
  listAssignableHandler,
  listManagedHandler,
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

/** /api/owner/workers: izin delegasi, hanya owner yang boleh menulis (PRD 5.1). */
export const ownerWorkersRoutes = new Hono<AppEnv>();
ownerWorkersRoutes.use('*', authMiddleware);
ownerWorkersRoutes.use('*', requireOwner());
ownerWorkersRoutes.get('/:id/permissions', getPermissionsHandler);
ownerWorkersRoutes.put('/:id/permissions', setPermissionsHandler);
