import { Hono } from 'hono';
import type { AppEnv } from '../../shared/types/env';
import { listServicesHandler } from './services.controller';

export const servicesRoutes = new Hono<AppEnv>();
servicesRoutes.get('/', listServicesHandler);
