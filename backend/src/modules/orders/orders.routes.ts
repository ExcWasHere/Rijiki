import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import type { AppEnv } from '../../shared/types/env';
import {
  listMessagesHandler,
  markMessagesReadHandler,
  sendMessageHandler,
} from '../messages/messages.controller';
import { createPaymentHandler } from '../payments/payments.controller';
import { createRatingHandler } from '../ratings/ratings.controller';
import {
  assignOrderHandler,
  claimOrderHandler,
  createOfflineOrderHandler,
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
ordersRoutes.post('/:id/rating', createRatingHandler);

// Worker / owner: order offline (POS) di outlet
ordersRoutes.post('/offline', createOfflineOrderHandler);

// Customer pemilik order, atau worker/owner berwenang untuk order offline
ordersRoutes.post('/:id/payment', createPaymentHandler);

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

// Chat order: siapa pun yang boleh melihat order boleh ikut percakapannya.
ordersRoutes.get('/:id/messages', listMessagesHandler);
ordersRoutes.post('/:id/messages', sendMessageHandler);
ordersRoutes.post('/:id/messages/read', markMessagesReadHandler);
