import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { AppErrorStatus } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { toNumber, toNumberOrNull } from '../../shared/utils/number';
import type {
  LedgerEntryView,
  PointCustomerView,
  PointRow,
  PointRuleView,
  RedemptionStatus,
  RedemptionView,
  RewardView,
} from './points.types';

const RULE_SELECT =
  'id, source, calculation_type, points_value, amount_unit, is_active, updated_at';

const LEDGER_SELECT =
  'id, type, points_amount, description, created_at, source_order:orders!points_ledger_source_order_id_fkey(order_number)';

const REDEMPTION_SELECT = [
  'id',
  'customer_id',
  'merchandise_id',
  'reward_name',
  'points_used',
  'status',
  'notes',
  'requested_at',
  'processed_at',
  'customer:customer_profiles(points_balance, users(full_name, phone_number))',
  'processor:users!point_redemptions_processed_by_fkey(full_name)',
].join(', ');

function failed(label: string, message: string): AppError {
  console.error(`points: gagal ${label}`, message);
  return new AppError(500, 'points_failed', `Gagal ${label}. Coba lagi ya.`);
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function one(value: any): any {
  if (Array.isArray(value)) return value[0] ?? null;
  return value ?? null;
}

/** Pesan `raise exception` dari fungsi SQL poin -> galat yang ramah. */
const RPC_ERRORS: Array<[string, AppErrorStatus, string, string]> = [
  ['insufficient_points', 409, 'insufficient_points', 'Saldo poin tidak cukup.'],
  ['out_of_stock', 409, 'out_of_stock', 'Stok merchandise habis.'],
  ['merchandise_unavailable', 409, 'merchandise_unavailable', 'Merchandise sudah tidak tersedia.'],
  [
    'reward_not_redeemable',
    409,
    'reward_not_redeemable',
    'Merchandise ini belum bisa ditukar dengan poin.',
  ],
  [
    'invalid_status_transition',
    409,
    'invalid_status_transition',
    'Status pengajuan sudah berubah. Muat ulang lalu coba lagi.',
  ],
  ['redemption_not_found', 404, 'not_found', 'Pengajuan tidak ditemukan.'],
  ['customer_not_found', 404, 'customer_not_found', 'Customer tidak ditemukan.'],
  ['invalid_points', 400, 'validation_error', 'Jumlah poin tidak boleh 0.'],
];

function rpcFailure(label: string, message: string | undefined): AppError {
  const text = message ?? '';
  for (const [marker, status, code, publicMessage] of RPC_ERRORS) {
    if (text.includes(marker)) return new AppError(status, code, publicMessage);
  }
  return failed(label, text);
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

export function mapRedemption(row: PointRow): RedemptionView {
  const customer = one(row.customer);
  const user = one(customer?.users);
  return {
    id: row.id as string,
    customer_id: row.customer_id as string,
    customer_name: (user?.full_name as string | null) ?? null,
    customer_phone: (user?.phone_number as string | null) ?? null,
    customer_balance: toNumber(customer?.points_balance),
    reward_name: row.reward_name as string,
    merchandise_id: (row.merchandise_id as string | null) ?? null,
    points_used: toNumber(row.points_used),
    status: row.status as RedemptionStatus,
    notes: (row.notes as string | null) ?? null,
    requested_at: row.requested_at as string,
    processed_at: (row.processed_at as string | null) ?? null,
    processed_by_name: (one(row.processor)?.full_name as string | null) ?? null,
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

// ---------------------------------------------------------------------------
// Penukaran poin
// ---------------------------------------------------------------------------

export async function listRewardRows(env: Bindings): Promise<RewardView[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('merchandise')
    .select('id, name, description, image_url, points_cost, stock_quantity')
    .eq('is_active', true)
    .not('points_cost', 'is', null)
    .order('points_cost', { ascending: true });
  if (error) throw failed('memuat daftar hadiah', error.message);

  return ((data ?? []) as unknown as PointRow[]).map((row) => {
    const stock = toNumberOrNull(row.stock_quantity);
    return {
      id: row.id as string,
      name: row.name as string,
      description: (row.description as string | null) ?? null,
      image_url: (row.image_url as string | null) ?? null,
      points_cost: toNumber(row.points_cost),
      in_stock: stock === null || stock > 0,
    };
  });
}

export async function listRedemptionRows(
  env: Bindings,
  filters: { customerId?: string; status?: RedemptionStatus; page: number; limit: number },
): Promise<{ rows: RedemptionView[]; total: number }> {
  const admin = getSupabaseAdmin(env);
  const from = (filters.page - 1) * filters.limit;

  let builder = admin.from('point_redemptions').select(REDEMPTION_SELECT, { count: 'exact' });
  if (filters.customerId) builder = builder.eq('customer_id', filters.customerId);
  if (filters.status) builder = builder.eq('status', filters.status);

  const { data, error, count } = await builder
    .order('requested_at', { ascending: false })
    .range(from, from + filters.limit - 1);
  if (error) throw failed('memuat pengajuan tukar poin', error.message);

  return {
    rows: ((data ?? []) as unknown as PointRow[]).map(mapRedemption),
    total: count ?? 0,
  };
}

export async function countPendingRedemptions(env: Bindings): Promise<number> {
  const admin = getSupabaseAdmin(env);
  const { count, error } = await admin
    .from('point_redemptions')
    .select('id', { count: 'exact', head: true })
    .eq('status', 'pending');
  if (error) throw failed('memuat jumlah pengajuan', error.message);
  return count ?? 0;
}

export async function getRedemptionRow(env: Bindings, id: string): Promise<RedemptionView | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('point_redemptions')
    .select(REDEMPTION_SELECT)
    .eq('id', id)
    .maybeSingle();
  if (error) throw failed('memuat pengajuan tukar poin', error.message);
  return data ? mapRedemption(data as unknown as PointRow) : null;
}

export async function requestRedemptionRpc(
  env: Bindings,
  customerId: string,
  merchandiseId: string,
): Promise<string> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin.rpc('request_point_redemption', {
    p_customer_id: customerId,
    p_merchandise_id: merchandiseId,
  });
  if (error) throw rpcFailure('mengajukan tukar poin', error.message);
  if (typeof data !== 'string') throw failed('mengajukan tukar poin', 'fungsi tidak mengembalikan id');
  return data;
}

export async function processRedemptionRpc(
  env: Bindings,
  params: {
    redemptionId: string;
    status: 'approved' | 'rejected' | 'fulfilled';
    notes: string | null;
    processedBy: string;
  },
): Promise<void> {
  const admin = getSupabaseAdmin(env);
  const { error } = await admin.rpc('process_point_redemption', {
    p_redemption_id: params.redemptionId,
    p_status: params.status,
    p_notes: params.notes ?? '',
    p_processed_by: params.processedBy,
  });
  if (error) throw rpcFailure('memproses pengajuan tukar poin', error.message);
}

// ---------------------------------------------------------------------------
// Penyesuaian poin
// ---------------------------------------------------------------------------

export async function searchCustomerRows(
  env: Bindings,
  query: string,
): Promise<PointCustomerView[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin.rpc('search_customers_for_points', {
    p_query: query,
    p_limit: 20,
  });
  if (error) throw failed('mencari customer', error.message);

  return ((data ?? []) as PointRow[]).map((row) => ({
    id: row.profile_id as string,
    name: (row.full_name as string | null) ?? null,
    email: row.email as string,
    phone: (row.phone as string | null) ?? null,
    avatar_url: (row.avatar_url as string | null) ?? null,
    points_balance: toNumber(row.balance),
  }));
}

export async function adjustPointsRpc(
  env: Bindings,
  customerId: string,
  points: number,
  description: string,
): Promise<number> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin.rpc('adjust_points', {
    p_customer_id: customerId,
    p_points: points,
    p_description: description,
  });
  if (error) throw rpcFailure('menyesuaikan poin', error.message);
  return toNumber(data);
}
