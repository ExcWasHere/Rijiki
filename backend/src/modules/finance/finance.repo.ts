import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { toNumber, toNumberOrNull } from '../../shared/utils/number';
import type { DateRange } from './finance.period';
import type {
  ExpenseAiInputRow,
  ExpenseType,
  InputSource,
  PaymentMethod,
  TransactionRow,
  TransactionType,
} from './finance.types';

const TRANSACTION_COLUMNS = [
  'id',
  'type',
  'expense_type',
  'category',
  'amount',
  'description',
  'related_order_id',
  'transaction_date',
  'created_at',
  'item_name',
  'quantity',
  'unit',
  'vendor_name',
  'input_source',
  'receipt_image_url',
  'payment_method',
].join(', ');

const AI_INPUT_COLUMNS =
  'id, created_by, input_text, image_url, parsed_result, model_name, status, error_message, confirmed_at, created_at';

function failed(label: string, message: string): AppError {
  console.error(`finance: gagal ${label}`, message);
  return new AppError(500, 'finance_failed', 'Gagal memproses data keuangan. Coba lagi ya.');
}

function toTransactionRow(raw: unknown): TransactionRow {
  const data = raw as Record<string, unknown>;
  return {
    id: data['id'] as string,
    type: data['type'] as TransactionType,
    expense_type: (data['expense_type'] as ExpenseType | null) ?? null,
    category: (data['category'] as string | null) ?? null,
    amount: toNumber(data['amount']),
    description: (data['description'] as string | null) ?? null,
    related_order_id: (data['related_order_id'] as string | null) ?? null,
    transaction_date: String(data['transaction_date']).slice(0, 10),
    created_at: String(data['created_at']),
    item_name: (data['item_name'] as string | null) ?? null,
    quantity: toNumberOrNull(data['quantity']),
    unit: (data['unit'] as string | null) ?? null,
    vendor_name: (data['vendor_name'] as string | null) ?? null,
    input_source: (data['input_source'] as InputSource | null) ?? 'manual',
    receipt_image_url: (data['receipt_image_url'] as string | null) ?? null,
    payment_method: (data['payment_method'] as PaymentMethod | null) ?? null,
  };
}

function toAiInputRow(raw: unknown): ExpenseAiInputRow {
  const data = raw as Record<string, unknown>;
  return {
    id: data['id'] as string,
    created_by: String(data['created_by']),
    input_text: (data['input_text'] as string | null) ?? null,
    image_url: (data['image_url'] as string | null) ?? null,
    parsed_result: data['parsed_result'] ?? null,
    model_name: (data['model_name'] as string | null) ?? null,
    status: String(data['status']),
    error_message: (data['error_message'] as string | null) ?? null,
    confirmed_at: (data['confirmed_at'] as string | null) ?? null,
    created_at: String(data['created_at']),
  };
}

export interface TransactionQuery {
  type: TransactionType | null;
  expenseType: ExpenseType | null;
  range: DateRange | null;
}

export async function listTransactions(
  env: Bindings,
  query: TransactionQuery,
): Promise<TransactionRow[]> {
  const admin = getSupabaseAdmin(env);
  let builder = admin.from('financial_transactions').select(TRANSACTION_COLUMNS);

  if (query.type) builder = builder.eq('type', query.type);
  if (query.expenseType) builder = builder.eq('expense_type', query.expenseType);
  if (query.range) {
    builder = builder
      .gte('transaction_date', query.range.from)
      .lte('transaction_date', query.range.to);
  }

  const { data, error } = await builder
    .order('transaction_date', { ascending: false })
    .order('created_at', { ascending: false })
    .limit(2000);

  if (error) throw failed('memuat transaksi', error.message);
  return ((data ?? []) as unknown[]).map(toTransactionRow);
}

export async function listTransactionsInRange(
  env: Bindings,
  range: DateRange,
): Promise<TransactionRow[]> {
  return listTransactions(env, { type: null, expenseType: null, range });
}

/** Satu baris pemasukan manual (di luar order). */
export async function insertManualIncome(
  env: Bindings,
  params: {
    userId: string;
    amount: number;
    transactionDate: string;
    itemName: string | null;
    category: string | null;
    description: string | null;
  },
): Promise<TransactionRow> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('financial_transactions')
    .insert({
      type: 'income',
      amount: params.amount,
      transaction_date: params.transactionDate,
      item_name: params.itemName,
      category: params.category,
      description: params.description,
      created_by: params.userId,
      input_source: 'manual',
    })
    .select(TRANSACTION_COLUMNS)
    .single();

  if (error) throw failed('menyimpan pemasukan', error.message);
  return toTransactionRow(data);
}

/** Pemasukan tunai order offline: uang sudah diterima worker saat order dibuat. */
export async function insertCashOrderIncome(
  env: Bindings,
  params: {
    userId: string;
    orderId: string;
    orderNumber: string;
    amount: number;
    transactionDate: string;
  },
): Promise<void> {
  const admin = getSupabaseAdmin(env);
  const { error } = await admin.from('financial_transactions').insert({
    type: 'income',
    category: 'order_payment',
    amount: params.amount,
    related_order_id: params.orderId,
    item_name: `Pembayaran order ${params.orderNumber}`,
    transaction_date: params.transactionDate,
    created_by: params.userId,
    input_source: 'manual',
    payment_method: 'cash',
  });

  if (error) throw failed('mencatat pemasukan tunai', error.message);
}

export async function insertExpenseAiInput(
  env: Bindings,
  params: {
    userId: string;
    inputText: string | null;
    imageKey: string | null;
    modelName: string;
    status: 'draft' | 'failed';
    parsedResult: unknown;
    errorMessage: string | null;
  },
): Promise<ExpenseAiInputRow> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('expense_ai_inputs')
    .insert({
      created_by: params.userId,
      input_text: params.inputText,
      image_url: params.imageKey,
      model_name: params.modelName,
      status: params.status,
      parsed_result: params.parsedResult,
      error_message: params.errorMessage,
    })
    .select(AI_INPUT_COLUMNS)
    .single();

  if (error) throw failed('menyimpan input AI', error.message);
  return toAiInputRow(data);
}

export async function findExpenseAiInput(
  env: Bindings,
  id: string,
): Promise<ExpenseAiInputRow | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('expense_ai_inputs')
    .select(AI_INPUT_COLUMNS)
    .eq('id', id)
    .maybeSingle();

  if (error) throw failed('memuat input AI', error.message);
  return data ? toAiInputRow(data) : null;
}

export async function markExpenseAiInputDiscarded(env: Bindings, id: string): Promise<void> {
  const admin = getSupabaseAdmin(env);
  const { error } = await admin
    .from('expense_ai_inputs')
    .update({ status: 'discarded' })
    .eq('id', id)
    .eq('status', 'draft');

  if (error) throw failed('membatalkan draft', error.message);
}

export interface ConfirmedExpenseItem {
  expenseType: ExpenseType;
  itemName: string;
  amount: number;
  transactionDate: string;
  quantity: number | null;
  unit: string | null;
  vendorName: string | null;
}

/**
 * Menyimpan item draft sebagai transaksi lalu menutup input AI. Bila salah satu
 * insert gagal, transaksi yang sudah masuk dihapus lagi supaya tidak ada
 * pengeluaran setengah jadi (klien Supabase tidak punya transaksi DB).
 */
export async function confirmExpenseItems(
  env: Bindings,
  params: {
    userId: string;
    inputId: string;
    receiptKey: string | null;
    items: ConfirmedExpenseItem[];
  },
): Promise<TransactionRow[]> {
  const admin = getSupabaseAdmin(env);

  const { data, error } = await admin
    .from('financial_transactions')
    .insert(
      params.items.map((item) => ({
        type: 'expense',
        expense_type: item.expenseType,
        amount: item.amount,
        transaction_date: item.transactionDate,
        item_name: item.itemName,
        quantity: item.quantity,
        unit: item.unit,
        vendor_name: item.vendorName,
        input_source: 'ai',
        ai_input_id: params.inputId,
        receipt_image_url: params.receiptKey,
        created_by: params.userId,
      })),
    )
    .select(TRANSACTION_COLUMNS);

  if (error) throw failed('menyimpan pengeluaran', error.message);

  const { error: markError } = await admin
    .from('expense_ai_inputs')
    .update({ status: 'confirmed', confirmed_at: new Date().toISOString() })
    .eq('id', params.inputId);

  if (markError) {
    const ids = ((data ?? []) as unknown as Array<Record<string, unknown>>).map((row) => row['id']);
    if (ids.length > 0) {
      await admin
        .from('financial_transactions')
        .delete()
        .in('id', ids)
        .then(({ error: undoError }) => {
          if (undoError) console.error('finance: gagal membatalkan pengeluaran', undoError.message);
        });
    }
    throw failed('mengonfirmasi input AI', markError.message);
  }

  return ((data ?? []) as unknown[]).map(toTransactionRow);
}

