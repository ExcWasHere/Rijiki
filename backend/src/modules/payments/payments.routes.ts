import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import type { AppEnv } from '../../shared/types/env';
import { getPaymentHandler } from './payments.controller';

export const paymentsRoutes = new Hono<AppEnv>();

paymentsRoutes.use('*', authMiddleware);

paymentsRoutes.get('/:id', getPaymentHandler);
