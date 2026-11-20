import type { Context } from 'hono';
import type { AppEnv } from '../../shared/types/env';
import { parseInput } from '../../shared/utils/validate';
import {
  aiParseSchema,
  confirmDraftSchema,
  exportQuerySchema,
  manualIncomeSchema,
  periodQuerySchema,
  transactionQuerySchema,
} from './finance.schema';
import {
  addManualIncome,
  confirmExpenseDraft,
  discardExpenseDraft,
  exportTransactions,
  getFinanceSummary,
  getTransactions,
  parseExpense,
} from './finance.service';

export async function summaryHandler(c: Context<AppEnv>) {
  const query = parseInput(periodQuerySchema, c.req.query());
  c.header('Cache-Control', 'no-store');
  return c.json(await getFinanceSummary(c.env, query));
}

export async function transactionsHandler(c: Context<AppEnv>) {
  const query = parseInput(transactionQuerySchema, c.req.query());
  c.header('Cache-Control', 'no-store');
  return c.json(await getTransactions(c.env, query));
}

export async function createIncomeHandler(c: Context<AppEnv>) {
  const input = parseInput(manualIncomeSchema, await c.req.json().catch(() => null));
  return c.json(await addManualIncome(c.env, c.get('user'), input), 201);
}

/**
 * multipart/form-data: field `input_text` dan/atau berkas `image`.
 * Keduanya boleh kosong di form, tetapi service menolak bila dua-duanya kosong.
 */
export async function aiParseHandler(c: Context<AppEnv>) {
  const form = await c.req.formData().catch(() => null);
  if (!form) {
    return c.json({ error: { code: 'invalid_json', message: 'Body harus multipart/form-data' } }, 400);
  }

  const fields: Record<string, string> = {};
  for (const [key, value] of form.entries()) {
    if (typeof value === 'string') fields[key] = value;
  }
  const input = parseInput(aiParseSchema, fields);

  return c.json(
    await parseExpense(c.env, c.get('user'), {
      text: input.input_text?.trim() ? input.input_text.trim() : null,
      transactionDate: input.transaction_date ?? new Date().toISOString().slice(0, 10),
      receipt: form.get('image'),
    }),
  );
}

export async function confirmDraftHandler(c: Context<AppEnv>) {
  const input = parseInput(confirmDraftSchema, await c.req.json().catch(() => null));
  const items = await confirmExpenseDraft(c.env, c.get('user'), c.req.param('id') ?? '', input);
  return c.json({ items }, 201);
}

export async function discardDraftHandler(c: Context<AppEnv>) {
  await discardExpenseDraft(c.env, c.get('user'), c.req.param('id') ?? '');
  return c.json({ message: 'Draft dibatalkan' });
}

export async function exportHandler(c: Context<AppEnv>) {
  const query = parseInput(exportQuerySchema, c.req.query());
  const file = await exportTransactions(c.env, query);
  return new Response(file.bytes, {
    headers: {
      'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'Content-Disposition': `attachment; filename="${file.fileName}"`,
      'X-Transaction-Count': String(file.transactionCount),
      'Cache-Control': 'no-store',
    },
  });
}
