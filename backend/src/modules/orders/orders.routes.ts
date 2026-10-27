import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import type { AppEnv } from '../../shared/types/env';
import {
  createOrderHandler,
  getOrderHandler,
  listOrdersHandler,
  quoteOrderHandler,
} from './orders.controller';

export const ordersRoutes = new Hono<AppEnv>();

ordersRoutes.use('*', authMiddleware);
ordersRoutes.post('/quote', quoteOrderHandler);
ordersRoutes.post('/', createOrderHandler);
ordersRoutes.get('/', listOrdersHandler);
ordersRoutes.get('/:id', getOrderHandler);
