import { z } from 'zod';

export const EXPENSE_TYPE_VALUES = ['material', 'equipment', 'external_service', 'other'] as const;

const dateString = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'Tanggal harus berformat YYYY-MM-DD');

export const periodQuerySchema = z.object({
  period: z.enum(['today', 'week', 'month']).default('month'),
});

export const transactionQuerySchema = z.object({
  type: z.enum(['income', 'expense']).optional(),
  expense_type: z.enum(EXPENSE_TYPE_VALUES).optional(),
  start_date: dateString.optional(),
  end_date: dateString.optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(200).default(50),
});

export const manualIncomeSchema = z
  .object({
    type: z.literal('income').default('income'),
    amount: z.number().positive('Nominal harus lebih dari 0'),
    transaction_date: dateString,
    item_name: z.string().trim().max(120).optional(),
    category: z.string().trim().max(60).optional(),
    description: z.string().trim().max(500).optional(),
  })
  .strict();

export const aiParseSchema = z
  .object({
    input_text: z.string().trim().max(2000).optional(),
    transaction_date: dateString.optional(),
  })
  .strict();

export const draftItemSchema = z.object({
  expense_type: z.enum(EXPENSE_TYPE_VALUES),
  item_name: z.string().trim().min(1, 'Nama item wajib diisi').max(120),
  amount: z.number().min(0, 'Nominal tidak boleh negatif'),
  transaction_date: dateString,
  quantity: z.number().nullable().optional(),
  unit: z.string().trim().max(20).nullable().optional(),
  vendor_name: z.string().trim().max(120).nullable().optional(),
});

export const confirmDraftSchema = z.object({
  items: z.array(draftItemSchema).min(1, 'Minimal satu item pengeluaran'),
});

export const exportQuerySchema = z.object({
  start_date: dateString,
  end_date: dateString,
  expense_type: z.enum(EXPENSE_TYPE_VALUES).optional(),
});

export type PeriodQuery = z.infer<typeof periodQuerySchema>;
export type TransactionQuery = z.infer<typeof transactionQuerySchema>;
export type ManualIncomeInput = z.infer<typeof manualIncomeSchema>;
export type AiParseInput = z.infer<typeof aiParseSchema>;
export type ConfirmDraftInput = z.infer<typeof confirmDraftSchema>;
export type ExportQuery = z.infer<typeof exportQuerySchema>;
