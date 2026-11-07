import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import { requirePermission } from '../../middleware/permission';
import type { AppEnv } from '../../shared/types/env';
import {
  exportRecapHandler,
  featuredHandler,
  listManagedHandler,
  setFeaturedHandler,
} from './ratings.controller';

/** Testimoni pilihan untuk home customer. Dipasang di /api/testimonials. */
export const testimonialsRoutes = new Hono<AppEnv>();
testimonialsRoutes.use('*', authMiddleware);
testimonialsRoutes.get('/featured', featuredHandler);

/**
 * Owner / pemegang izin manage_testimonials. Dipasang di
 * /api/management/testimonials. `/export` didaftarkan sebelum rute ber-parameter.
 */
export const managementTestimonialsRoutes = new Hono<AppEnv>();
managementTestimonialsRoutes.use('*', authMiddleware);
managementTestimonialsRoutes.use('*', requirePermission('manage_testimonials'));
managementTestimonialsRoutes.get('/export', exportRecapHandler);
managementTestimonialsRoutes.get('/', listManagedHandler);
managementTestimonialsRoutes.patch('/:id/featured', setFeaturedHandler);
