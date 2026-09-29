import { Hono } from 'hono';
import type { AppEnv } from '../../shared/types/env';
import { authMiddleware } from '../../middleware/auth';
import { notImplemented } from '../../shared/utils/stub';

export const scanRoutes = new Hono<AppEnv>();

scanRoutes.use('*', authMiddleware);
// TODO: proxy ke FastAPI (Azure Container Apps) — Bagian 22 System Architecture
scanRoutes.post('/', notImplemented('POST /api/scans (upload foto -> FastAPI)'));
scanRoutes.get('/:id', notImplemented('GET /api/scans/:id'));