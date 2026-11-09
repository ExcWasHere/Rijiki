import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { logActivity } from '../../shared/utils/activity-log';
import { toNumberOrNull } from '../../shared/utils/number';
import { findCustomerProfileByUserId } from '../orders/orders.repo';
import {
  adjustPointsRpc,
  awardPointsRpc,
  countPendingRedemptions,
  getBalance,
  getRedemptionRow,
  getRuleRow,
  listLedgerRows,
  listRedemptionRows,
  listRewardRows,
  listRuleRows,
  processRedemptionRpc,
  requestRedemptionRpc,
  searchCustomerRows,
  updateRuleRow,
} from './points.repo';
import type {
  AdjustPointsInput,
  CreateRedemptionInput,
  CustomerSearchQuery,
  LedgerQuery,
  ListRedemptionsQuery,
  ProcessRedemptionInput,
  UpdatePointRuleInput,
} from './points.schema';
import type {
  AdjustResultView,
  LedgerEntryView,
  PointBalanceView,
  PointCustomerView,
  PointRuleView,
  RedemptionView,
  RewardView,
} from './points.types';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// ---------------------------------------------------------------------------
// Aturan poin (owner / worker berizin manage_points)
// ---------------------------------------------------------------------------

export async function listPointRules(env: Bindings): Promise<{ items: PointRuleView[] }> {
  return { items: await listRuleRows(env) };
}

export async function updatePointRule(
  env: Bindings,
  userId: string,
  ruleId: string,
  input: UpdatePointRuleInput,
): Promise<PointRuleView> {
  if (!UUID_RE.test(ruleId)) throw new AppError(404, 'not_found', 'Aturan poin tidak ditemukan');
  const row = await getRuleRow(env, ruleId);
  if (!row) throw new AppError(404, 'not_found', 'Aturan poin tidak ditemukan');

  const patch: Record<string, unknown> = {};
  if (input.points_value !== undefined) patch['points_value'] = input.points_value;
  if (input.is_active !== undefined) patch['is_active'] = input.is_active;

  if (row.calculation_type === 'per_amount') {
    // Poin per kelipatan Rupiah: satuan nominal wajib ada dan positif.
    const unit =
      input.amount_unit !== undefined ? input.amount_unit : toNumberOrNull(row.amount_unit);
    if (unit === null || unit <= 0) {
      throw new AppError(400, 'validation_error', 'Satuan nominal wajib diisi untuk aturan per nominal.');
    }
    if (input.amount_unit !== undefined) patch['amount_unit'] = input.amount_unit;
  } else if (input.amount_unit !== undefined && input.amount_unit !== null) {
    throw new AppError(400, 'validation_error', 'Aturan poin tetap tidak memakai satuan nominal.');
  }

  patch['updated_at'] = new Date().toISOString();
  const updated = await updateRuleRow(env, ruleId, patch);

  await logActivity(env, {
    userId,
    action: 'point_rule_update',
    entity: 'point_rule',
    entityId: ruleId,
    metadata: {
      source: row.source,
      from: { points_value: row.points_value, is_active: row.is_active },
      to: { points_value: updated.points_value, is_active: updated.is_active },
    },
  });
  return updated;
}

// ---------------------------------------------------------------------------
// Saldo dan riwayat (customer)
// ---------------------------------------------------------------------------

async function requireCustomerProfileId(env: Bindings, userId: string): Promise<string> {
  const profile = await findCustomerProfileByUserId(env, userId);
  if (!profile) throw new AppError(404, 'profile_not_found', 'Profil customer tidak ditemukan');
  return profile.id;
}

export async function getPointBalance(env: Bindings, userId: string): Promise<PointBalanceView> {
  const customerId = await requireCustomerProfileId(env, userId);
  const [points_balance, ledger] = await Promise.all([
    getBalance(env, customerId),
    listLedgerRows(env, customerId, 1, 5),
  ]);
  return { points_balance, recent: ledger.rows };
}

export async function getPointLedger(
  env: Bindings,
  userId: string,
  query: LedgerQuery,
): Promise<{ items: LedgerEntryView[]; page: number; limit: number; total: number }> {
  const customerId = await requireCustomerProfileId(env, userId);
  const { rows, total } = await listLedgerRows(env, customerId, query.page, query.limit);
  return { items: rows, page: query.page, limit: query.limit, total };
}

// ---------------------------------------------------------------------------
// Tukar poin: sisi customer
// ---------------------------------------------------------------------------

export async function listRewards(env: Bindings): Promise<{ items: RewardView[] }> {
  return { items: await listRewardRows(env) };
}

export async function requestRedemption(
  env: Bindings,
  userId: string,
  input: CreateRedemptionInput,
): Promise<RedemptionView> {
  const customerId = await requireCustomerProfileId(env, userId);
  const redemptionId = await requestRedemptionRpc(env, customerId, input.merchandise_id);

  const view = await getRedemptionRow(env, redemptionId);
  if (!view) throw new AppError(500, 'points_failed', 'Pengajuan tersimpan, tetapi gagal dimuat. Cek riwayat penukaran.');

  await logActivity(env, {
    userId,
    action: 'point_redemption_request',
    entity: 'point_redemption',
    entityId: redemptionId,
    metadata: { merchandise_id: input.merchandise_id, points_used: view.points_used },
  });
  return view;
}

export async function listMyRedemptions(
  env: Bindings,
  userId: string,
  query: ListRedemptionsQuery,
): Promise<{ items: RedemptionView[]; page: number; limit: number; total: number }> {
  const customerId = await requireCustomerProfileId(env, userId);
  const { rows, total } = await listRedemptionRows(env, {
    customerId,
    status: query.status,
    page: query.page,
    limit: query.limit,
  });
  return { items: rows, page: query.page, limit: query.limit, total };
}

// ---------------------------------------------------------------------------
// Tukar poin: sisi owner / worker berizin manage_points
// ---------------------------------------------------------------------------

export async function listManagedRedemptions(
  env: Bindings,
  query: ListRedemptionsQuery,
): Promise<{
  items: RedemptionView[];
  page: number;
  limit: number;
  total: number;
  summary: { pending: number };
}> {
  const [{ rows, total }, pending] = await Promise.all([
    listRedemptionRows(env, { status: query.status, page: query.page, limit: query.limit }),
    countPendingRedemptions(env),
  ]);
  return { items: rows, page: query.page, limit: query.limit, total, summary: { pending } };
}

export async function processRedemption(
  env: Bindings,
  userId: string,
  redemptionId: string,
  input: ProcessRedemptionInput,
): Promise<RedemptionView> {
  if (!UUID_RE.test(redemptionId)) throw new AppError(404, 'not_found', 'Pengajuan tidak ditemukan');

  const before = await getRedemptionRow(env, redemptionId);
  if (!before) throw new AppError(404, 'not_found', 'Pengajuan tidak ditemukan');

  const notes = input.notes?.trim() ? input.notes.trim() : null;
  if (input.status === 'rejected' && !notes) {
    throw new AppError(400, 'validation_error', 'Alasan penolakan wajib diisi.');
  }

  // Semua pengecekan yang mengikat (status, saldo, stok) ada di fungsi SQL
  // dan berjalan atomik; pengecekan di atas hanya agar galatnya lebih jelas.
  await processRedemptionRpc(env, {
    redemptionId,
    status: input.status,
    notes,
    processedBy: userId,
  });

  const after = await getRedemptionRow(env, redemptionId);
  if (!after) throw new AppError(404, 'not_found', 'Pengajuan tidak ditemukan');

  await logActivity(env, {
    userId,
    action: `point_redemption_${input.status}`,
    entity: 'point_redemption',
    entityId: redemptionId,
    metadata: {
      from: before.status,
      to: after.status,
      customer_id: before.customer_id,
      reward_name: before.reward_name,
      points_used: before.points_used,
      notes,
    },
  });
  return after;
}

export async function searchPointCustomers(
  env: Bindings,
  query: CustomerSearchQuery,
): Promise<{ items: PointCustomerView[] }> {
  return { items: await searchCustomerRows(env, query.q) };
}

export async function adjustCustomerPoints(
  env: Bindings,
  userId: string,
  input: AdjustPointsInput,
): Promise<AdjustResultView> {
  const balance = await adjustPointsRpc(
    env,
    input.customer_id,
    input.points_amount,
    input.description,
  );

  await logActivity(env, {
    userId,
    action: 'point_adjust',
    entity: 'customer_profile',
    entityId: input.customer_id,
    metadata: {
      points_amount: input.points_amount,
      description: input.description,
      balance_after: balance,
    },
  });
  return {
    customer_id: input.customer_id,
    points_amount: input.points_amount,
    points_balance: balance,
  };
}

// ---------------------------------------------------------------------------
// Pemberian poin otomatis (dipanggil modul lain)
// ---------------------------------------------------------------------------

/**
 * Poin tidak boleh menggagalkan aksi utama yang sudah tersimpan (order sudah
 * selesai, rating sudah masuk), jadi galat hanya dicatat. Fungsi SQL-nya
 * idempoten: memanggil ulang untuk order yang sama tidak memberi poin dua kali.
 */
async function awardSafely(
  env: Bindings,
  orderId: string,
  source: 'order_completed' | 'give_rating',
): Promise<number> {
  try {
    return await awardPointsRpc(env, orderId, source);
  } catch (err) {
    console.error(`points: gagal memberi poin ${source} untuk order ${orderId}`, err);
    return 0;
  }
}

export function awardOrderCompletedPoints(env: Bindings, orderId: string): Promise<number> {
  return awardSafely(env, orderId, 'order_completed');
}

/** Dipakai modul ratings (Segmen 3). */
export function awardRatingPoints(env: Bindings, orderId: string): Promise<number> {
  return awardSafely(env, orderId, 'give_rating');
}
