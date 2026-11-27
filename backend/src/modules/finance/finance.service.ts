import { AppError } from '../../shared/errors';
import { readImageFile } from '../../shared/storage/image';
import { buildKey, putImage } from '../../shared/storage/r2';
import type { Bindings } from '../../shared/types/env';
import type { AuthContextUser } from '../../shared/types/user';
import { logActivity } from '../../shared/utils/activity-log';
import { buildXlsx } from '../../shared/utils/xlsx';
import type { SheetValue } from '../../shared/utils/xlsx';
import { getAiConfig, parseExpenseWithAi } from './finance.ai';
import { buildSeries, expenseByType, planPeriod, sumByType } from './finance.period';
import type { DateRange } from './finance.period';
import {
  confirmExpenseItems,
  findExpenseAiInput,
  insertExpenseAiInput,
  insertManualIncome,
  listTransactionPage,
  listTransactions,
  markExpenseAiInputDiscarded,
} from './finance.repo';
import type {
  ConfirmDraftInput,
  ExportQuery,
  ManualIncomeInput,
  PeriodQuery,
  TransactionQuery,
} from './finance.schema';
import type {
  ExpenseDraftItemView,
  ExpenseDraftView,
  ExpenseDraftWarning,
  ExpenseType,
  FinanceSummaryView,
  TransactionRow,
  TransactionView,
} from './finance.types';

/** Bukti nota disimpan di bucket privat (PRD 22, folder `receipts/`). */
const RECEIPT_MAX_BYTES = 5 * 1024 * 1024;

const EXPENSE_TYPE_LABEL: Record<ExpenseType, string> = {
  material: 'Belanja Bahan',
  equipment: 'Alat',
  external_service: 'Jasa',
  other: 'Lain-lain',
};

function toView(row: TransactionRow): TransactionView {
  return {
    id: row.id,
    type: row.type,
    expense_type: row.expense_type,
    category: row.category,
    amount: row.amount,
    description: row.description,
    related_order_id: row.related_order_id,
    transaction_date: row.transaction_date,
    item_name: row.item_name,
    quantity: row.quantity,
    unit: row.unit,
    vendor_name: row.vendor_name,
    input_source: row.input_source,
    receipt_image_url: row.receipt_image_url,
    payment_method: row.payment_method,
  };
}

export async function getFinanceSummary(
  env: Bindings,
  query: PeriodQuery,
): Promise<FinanceSummaryView> {
  const plan = planPeriod(query.period);
  const [currentRows, previousRows] = await Promise.all([
    listTransactions(env, { type: null, expenseType: null, range: plan.current }),
    listTransactions(env, { type: null, expenseType: null, range: plan.previous }),
  ]);

  const totals = sumByType(currentRows);
  return {
    period: query.period,
    income: totals.income,
    expense: totals.expense,
    previous_income: sumByType(previousRows).income,
    series: buildSeries(currentRows, plan.buckets, plan.current),
    expense_by_type: expenseByType(currentRows) as Record<ExpenseType, number>,
  };
}

export async function getTransactions(
  env: Bindings,
  query: TransactionQuery,
): Promise<{
  items: TransactionView[];
  total: number;
  page: number;
  limit: number;
  income: number;
  expense: number;
}> {
  const range: DateRange | null =
    query.start_date && query.end_date
      ? { from: query.start_date, to: query.end_date }
      : null;
  if (range && range.from > range.to) {
    throw new AppError(400, 'validation_error', 'Tanggal awal tidak boleh setelah tanggal akhir');
  }

  const page = query.page ?? 1;
  const limit = query.limit ?? 50;

  const [paged, totalsRows] = await Promise.all([
    listTransactionPage(env, {
      type: query.type ?? null,
      expenseType: query.expense_type ?? null,
      range,
      page,
      limit,
    }),
    // Ringkasan pemasukan/pengeluaran mencakup seluruh rentang filter, bukan
    // hanya halaman yang sedang ditampilkan.
    listTransactions(env, {
      type: query.type ?? null,
      expenseType: query.expense_type ?? null,
      range,
    }),
  ]);
  const totals = sumByType(totalsRows);

  return {
    items: paged.rows.map(toView),
    total: paged.total,
    page,
    limit,
    income: totals.income,
    expense: totals.expense,
  };
}

export async function addManualIncome(
  env: Bindings,
  ctx: AuthContextUser,
  input: ManualIncomeInput,
): Promise<TransactionView> {
  const row = await insertManualIncome(env, {
    userId: ctx.user.id,
    amount: Math.round(input.amount),
    transactionDate: input.transaction_date,
    itemName: input.item_name?.trim() || null,
    category: input.category?.trim() || null,
    description: input.description?.trim() || null,
  });

  await logActivity(env, {
    userId: ctx.user.id,
    action: 'create_income',
    entity: 'financial_transaction',
    entityId: row.id,
    metadata: { amount: row.amount, input_source: 'manual' },
  });

  return toView(row);
}

function failedDraft(inputId: string): ExpenseDraftView {
  return {
    input_id: inputId,
    status: 'failed',
    items: [],
    warnings: ['ai_unavailable'],
  };
}

function draftItemView(item: {
  id: string;
  expenseType: ExpenseType;
  itemName: string;
  amount: number;
  transactionDate: string;
  quantity: number | null;
  unit: string | null;
  vendorName: string | null;
  confidence: number;
  needsReview: boolean;
}): ExpenseDraftItemView {
  return {
    id: item.id,
    expense_type: item.expenseType,
    item_name: item.itemName,
    amount: item.amount,
    transaction_date: item.transactionDate,
    quantity: item.quantity,
    unit: item.unit,
    vendor_name: item.vendorName,
    confidence: item.confidence,
    needs_review: item.needsReview,
  };
}

/**
 * Input AI: simpan input mentah + foto nota, panggil model, simpan hasilnya
 * sebagai draft. AI tidak pernah menulis ke financial_transactions; itu terjadi
 * hanya di [confirmExpenseDraft] setelah pengguna memeriksa (PRD 15.1).
 */
export async function parseExpense(
  env: Bindings,
  ctx: AuthContextUser,
  input: { text: string | null; transactionDate: string; receipt: unknown },
): Promise<ExpenseDraftView> {
  const hasReceipt = input.receipt !== null && input.receipt !== undefined && input.receipt !== '';
  if (!input.text && !hasReceipt) {
    throw new AppError(400, 'validation_error', 'Tulis pengeluarannya atau lampirkan foto nota.');
  }

  const image = hasReceipt ? await readImageFile(input.receipt, RECEIPT_MAX_BYTES) : null;
  const imageKey = image ? buildKey('receipts', ctx.user.id, image.ext) : null;
  if (image && imageKey) await putImage(env, 'private', imageKey, image);

  const config = getAiConfig(env);
  if (!config) {
    const row = await insertExpenseAiInput(env, {
      userId: ctx.user.id,
      inputText: input.text,
      imageKey,
      modelName: 'unconfigured',
      status: 'failed',
      parsedResult: null,
      errorMessage: 'AI_API_KEY belum diset',
    });
    console.error('finance: ai-parse tanpa AI_API_KEY, pengeluaran dicatat tanpa klasifikasi');
    return failedDraft(row.id);
  }

  try {
    const parsed = await parseExpenseWithAi(config, {
      text: input.text,
      imageBase64: image ? arrayBufferToBase64(image.bytes) : null,
      imageMime: image ? image.mime : null,
    });

    const row = await insertExpenseAiInput(env, {
      userId: ctx.user.id,
      inputText: input.text,
      imageKey,
      modelName: config.model,
      status: 'draft',
      parsedResult: parsed,
      errorMessage: null,
    });

    const transactionDate = parsed.transactionDate ?? input.transactionDate;
    const items = parsed.items.map((item, index) =>
      draftItemView({
        id: `${row.id}-${index + 1}`,
        ...item,
        transactionDate,
      }),
    );

    const warnings: ExpenseDraftWarning[] = [];
    const sum = items.reduce((total, item) => total + item.amount, 0);
    if (parsed.receiptTotal !== null && Math.abs(parsed.receiptTotal - sum) > 0) {
      warnings.push('receipt_total_mismatch');
    }

    return {
      input_id: row.id,
      status: items.length > 0 ? 'draft' : 'failed',
      items,
      warnings: items.length > 0 ? warnings : ['ai_unavailable'],
    };
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error('finance: ai-parse gagal,', message);
    const row = await insertExpenseAiInput(env, {
      userId: ctx.user.id,
      inputText: input.text,
      imageKey,
      modelName: config.model,
      status: 'failed',
      parsedResult: null,
      errorMessage: message.slice(0, 500),
    });
    return failedDraft(row.id);
  }
}

function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  const chunkSize = 0x8000;
  for (let i = 0; i < bytes.length; i += chunkSize) {
    binary += String.fromCharCode(...bytes.subarray(i, i + chunkSize));
  }
  return btoa(binary);
}

export async function confirmExpenseDraft(
  env: Bindings,
  ctx: AuthContextUser,
  inputId: string,
  input: ConfirmDraftInput,
): Promise<TransactionView[]> {
  const draft = await findExpenseAiInput(env, inputId);
  if (!draft) throw new AppError(404, 'not_found', 'Draft pengeluaran tidak ditemukan');
  if (draft.status === 'confirmed' || draft.status === 'discarded') {
    throw new AppError(409, 'draft_closed', 'Draft ini sudah diproses.');
  }
  if (draft.created_by !== ctx.user.id && !ctx.ownerBypass) {
    throw new AppError(403, 'forbidden', 'Draft ini milik pengguna lain.');
  }

  const rows = await confirmExpenseItems(env, {
    userId: ctx.user.id,
    inputId,
    receiptKey: draft.image_url,
    items: input.items.map((item) => ({
      expenseType: item.expense_type,
      itemName: item.item_name,
      amount: Math.round(item.amount),
      transactionDate: item.transaction_date,
      quantity: item.quantity ?? null,
      unit: item.unit ?? null,
      vendorName: item.vendor_name ?? null,
    })),
  });

  await logActivity(env, {
    userId: ctx.user.id,
    action: 'create_expense',
    entity: 'financial_transaction',
    entityId: rows[0]?.id ?? null,
    metadata: {
      input_source: 'ai',
      ai_input_id: inputId,
      item_count: rows.length,
      amount: rows.reduce((sum, row) => sum + row.amount, 0),
    },
  });

  return rows.map(toView);
}

export async function discardExpenseDraft(
  env: Bindings,
  ctx: AuthContextUser,
  inputId: string,
): Promise<void> {
  const draft = await findExpenseAiInput(env, inputId);
  if (!draft) throw new AppError(404, 'not_found', 'Draft pengeluaran tidak ditemukan');
  if (draft.created_by !== ctx.user.id && !ctx.ownerBypass) {
    throw new AppError(403, 'forbidden', 'Draft ini milik pengguna lain.');
  }
  await markExpenseAiInputDiscarded(env, inputId);
}

const PAYMENT_LABEL: Record<string, string> = {
  qris: 'QRIS',
  cash: 'Tunai',
};

function exportRow(row: TransactionRow): SheetValue[] {
  return [
    row.transaction_date,
    row.type === 'income' ? 'Pemasukan' : 'Pengeluaran',
    row.expense_type ? EXPENSE_TYPE_LABEL[row.expense_type] : '',
    row.item_name ?? row.description ?? '',
    row.vendor_name ?? '',
    row.quantity ?? '',
    row.unit ?? '',
    row.amount,
    row.payment_method ? (PAYMENT_LABEL[row.payment_method] ?? row.payment_method) : '',
    row.input_source === 'ai' ? 'Input AI' : 'Manual',
    row.category ?? '',
  ];
}

const EXPORT_HEADER: SheetValue[] = [
  'Tanggal',
  'Jenis',
  'Tipe pengeluaran',
  'Item',
  'Toko / penyedia',
  'Jumlah',
  'Satuan',
  'Nominal (Rp)',
  'Metode pembayaran',
  'Dicatat lewat',
  'Kategori',
];

export interface FinanceExportFile {
  fileName: string;
  bytes: Uint8Array;
  transactionCount: number;
}

/** Ekspor rekap keuangan sebagai .xlsx (PRD 15.3). */
export async function exportTransactions(
  env: Bindings,
  query: ExportQuery,
): Promise<FinanceExportFile> {
  if (query.start_date > query.end_date) {
    throw new AppError(400, 'validation_error', 'Tanggal awal tidak boleh setelah tanggal akhir');
  }

  const rows = await listTransactions(env, {
    type: query.expense_type ? 'expense' : null,
    expenseType: query.expense_type ?? null,
    range: { from: query.start_date, to: query.end_date },
  });

  const totals = sumByType(rows);
  const sheet: SheetValue[][] = [
    EXPORT_HEADER,
    ...rows.map(exportRow),
    [],
    ['Total pemasukan', '', '', '', '', '', '', totals.income],
    ['Total pengeluaran', '', '', '', '', '', '', totals.expense],
    ['Selisih', '', '', '', '', '', '', totals.income - totals.expense],
  ];

  const suffix = query.expense_type ? `_${query.expense_type}` : '';
  return {
    fileName: `keuangan-rijiki_${query.start_date}_${query.end_date}${suffix}.xlsx`,
    bytes: buildXlsx(sheet),
    transactionCount: rows.length,
  };
}
