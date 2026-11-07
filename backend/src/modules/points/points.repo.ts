import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { toNumber, toNumberOrNull } from '../../shared/utils/number';
import type { LedgerEntryView, PointRow, PointRuleView } from './points.types';

const RULE_SELECT =
  'id, source, calculation_type, points_value, amount_unit, is_active, updated_at';

const LEDGER_SELECT =
  'id, type, points_amount, description, created_at, source_order:orders!points_ledger_source_order_id_fkey(order_number)';

function failed(label: string, message: string): AppError {
  console.error(`points: gagal ${label}`, message);
  return new AppError(500, 'points_failed', `Gagal ${label}. Coba lagi ya.`);
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function one(value: any): any {
  if (Array.isArray(value)) return value[0] ?? null;
  return value ?? null;
}

export function mapRule(row: PointRow): PointRuleView {
  return {
    id: row.id as string,
    source: row.source,
    calculation_type: row.calculation_type,
    points_value: toNumber(row.points_value),
    amount_unit: toNumberOrNull(row.amount_unit),
    is_active: Boolean(row.is_active),
    updated_at: row.updated_at as string,
  };
}

function mapLedger(row: PointRow): LedgerEntryView {
  const order = one(row.source_order);
  return {
    id: row.id as string,
    type: row.type,
    points_amount: toNumber(row.points_amount),
    description: (row.description as string | null) ?? null,
    order_number: (order?.order_number as string | null) ?? null,
    created_at: row.created_at as string,
  };
}

export async function listRuleRows(env: Bindings): Promise<PointRuleView[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('point_earning_rules')
    .select(RULE_SELECT)
    .order('created_at', { ascending: true });
  if (error) throw failed('memuat aturan poin', error.message);
  return ((data ?? []) as unknown as PointRow[]).map(mapRule);
}

export async function getRuleRow(env: Bindings, id: string): Promise<PointRow | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('point_earning_rules')
    .select(RULE_SELECT)
    .eq('id', id)
    .maybeSingle();
  if (error) throw failed('memuat aturan poin', error.message);
  return (data as unknown as PointRow | null) ?? null;
}

export async function updateRuleRow(
  env: Bindings,
  id: string,
  patch: Record<string, unknown>,
): Promise<PointRuleView> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('point_earning_rules')
    .update(patch)
    .eq('id', id)
    .select(RULE_SELECT)
    .single();
  if (error || !data) throw failed('menyimpan aturan poin', error?.message ?? 'tidak ada data');
  return mapRule(data as unknown as PointRow);
}

export async function getBalance(env: Bindings, customerId: string): Promise<number> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('customer_profiles')
    .select('points_balance')
    .eq('id', customerId)
    .maybeSingle();
  if (error) throw failed('memuat saldo poin', error.message);
  return toNumber(data?.points_balance);
}

export async function listLedgerRows(
  env: Bindings,
  customerId: string,
  page: number,
  limit: number,
): Promise<{ rows: LedgerEntryView[]; total: number }> {
  const admin = getSupabaseAdmin(env);
  const from = (page - 1) * limit;
  const { data, error, count } = await admin
    .from('points_ledger')
    .select(LEDGER_SELECT, { count: 'exact' })
    .eq('customer_id', customerId)
    .order('created_at', { ascending: false })
    .range(from, from + limit - 1);
  if (error) throw failed('memuat riwayat poin', error.message);
  return { rows: ((data ?? []) as unknown as PointRow[]).map(mapLedger), total: count ?? 0 };
}

/** Idempoten: memanggil ulang untuk order dan sumber yang sama mengembalikan 0. */
export async function awardPointsRpc(
  env: Bindings,
  orderId: string,
  source: 'order_completed' | 'give_rating',
): Promise<number> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin.rpc('award_points', {
    p_order_id: orderId,
    p_source: source,
  });
  if (error) throw failed('memberi poin', error.message);
  return toNumber(data);
}
