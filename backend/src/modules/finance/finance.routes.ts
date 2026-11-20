import { Hono } from 'hono';
import { authMiddleware } from '../../middleware/auth';
import { requirePermission } from '../../middleware/permission';
import type { AppEnv } from '../../shared/types/env';
import {
  aiParseHandler,
  confirmDraftHandler,
  createIncomeHandler,
  discardDraftHandler,
  exportHandler,
  summaryHandler,
  transactionsHandler,
} from './finance.controller';

/**
 * Keuangan: Owner atau worker berizin `manage_finance` (PRD 15, 29.7).
 * Pemasukan order dicatat sistem lewat pembayaran, bukan dari sini.
 */
export const financeRoutes = new Hono<AppEnv>();
financeRoutes.use('*', authMiddleware, requirePermission('manage_finance'));

financeRoutes.get('/summary', summaryHandler);
financeRoutes.get('/transactions', transactionsHandler);
financeRoutes.post('/transactions', createIncomeHandler);

financeRoutes.post('/expenses/ai-parse', aiParseHandler);
financeRoutes.post('/expenses/ai-parse/:id/confirm', confirmDraftHandler);
financeRoutes.delete('/expenses/ai-parse/:id', discardDraftHandler);

financeRoutes.get('/export', exportHandler);
