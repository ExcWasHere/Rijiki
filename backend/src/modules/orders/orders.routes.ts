import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import type { AppEnv } from '../../shared/types/env';
import {
  assignOrderHandler,
  claimOrderHandler,
  createOrderHandler,
  deleteDocumentationHandler,
  getOrderHandler,
  getTrackingHandler,
  listOrdersHandler,
  quoteOrderHandler,
  recordTrackingHandler,
  updateStatusHandler,
  uploadDocumentationHandler,
} from './orders.controller';

export const ordersRoutes = new Hono<AppEnv>();

ordersRoutes.use('*', authMiddleware);

// Customer
ordersRoutes.post('/quote', quoteOrderHandler);
ordersRoutes.post('/', createOrderHandler);

// Semua peran (hasilnya dibatasi per peran di service)
ordersRoutes.get('/', listOrdersHandler);
ordersRoutes.get('/:id', getOrderHandler);

// Worker / owner
ordersRoutes.post('/:id/claim', claimOrderHandler);
ordersRoutes.patch('/:id/assign', assignOrderHandler);
ordersRoutes.patch('/:id/status', updateStatusHandler);
ordersRoutes.post('/:id/documentations', uploadDocumentationHandler);
ordersRoutes.delete('/:id/documentations/:docId', deleteDocumentationHandler);

ordersRoutes.post('/:id/tracking', recordTrackingHandler);
ordersRoutes.get('/:id/tracking', getTrackingHandler);
