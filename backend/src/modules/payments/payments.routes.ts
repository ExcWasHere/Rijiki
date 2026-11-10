import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import type { AppEnv } from '../../shared/types/env';
import { getPaymentHandler } from './payments.controller';

export const paymentsRoutes = new Hono<AppEnv>();

paymentsRoutes.use('*', authMiddleware);

// Status pembayaran (polling dari app). Jika masih pending, backend ikut
// menanyakan ke Midtrans sebagai cadangan webhook.
paymentsRoutes.get('/:id', getPaymentHandler);
