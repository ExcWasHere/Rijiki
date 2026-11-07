import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { logActivity } from '../../shared/utils/activity-log';
import { toNumberOrNull } from '../../shared/utils/number';
import { findCustomerProfileByUserId } from '../orders/orders.repo';
import {
  awardPointsRpc,
  getBalance,
  getRuleRow,
  listLedgerRows,
  listRuleRows,
  updateRuleRow,
} from './points.repo';
import type { LedgerQuery, UpdatePointRuleInput } from './points.schema';
import type { LedgerEntryView, PointBalanceView, PointRuleView } from './points.types';

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
