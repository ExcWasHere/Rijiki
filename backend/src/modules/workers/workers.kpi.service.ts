import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { logActivity } from '../../shared/utils/activity-log';
import { maskName, one, serviceNamesOf } from '../ratings/ratings.service';
import {
  listReviewRows,
  loadAssessments,
  loadMetrics,
  upsertAssessment,
} from './workers.kpi.repo';
import type { AssessmentRow, MetricsRow } from './workers.kpi.repo';
import { getWorkerUserId, listManagedWorkers } from './workers.repo';
import { KPI_ASPECTS } from './workers.schema';
import type { KpiQuery, SaveAssessmentInput } from './workers.schema';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export interface WorkerKpiView {
  /** worker_profiles.id */
  worker_id: string;
  period_month: number;
  period_year: number;
  total_orders_handled: number;
  avg_rating: number | null;
  /**
   * Selalu null: definisi "tepat waktu" belum ditetapkan (PRD: formula KPI
   * masih TBD dengan Rijiki). Diisi setelah definisinya diputuskan.
   */
  on_time_completion_pct: number | null;
  assessment: {
    scores: Record<string, number>;
    note: string | null;
    updated_at: string;
  } | null;
}

export interface WorkerReviewView {
  id: string;
  customer_name: string;
  rating_value: number;
  created_at: string;
  order_number: string;
  comment: string | null;
  service_name: string | null;
}

/** Bulan dan tahun berjalan dalam WIB (UTC+7). */
export function currentPeriodWib(now: Date = new Date()): { month: number; year: number } {
  const shifted = new Date(now.getTime() + 7 * 60 * 60 * 1000);
  return { month: shifted.getUTCMonth() + 1, year: shifted.getUTCFullYear() };
}

function resolvePeriod(query: KpiQuery): { month: number; year: number } {
  const current = currentPeriodWib();
  return { month: query.month ?? current.month, year: query.year ?? current.year };
}

function round2(value: number): number {
  return Math.round(value * 100) / 100;
}

function toView(
  workerId: string,
  period: { month: number; year: number },
  metrics: MetricsRow | undefined,
  assessment: AssessmentRow | undefined,
): WorkerKpiView {
  return {
    worker_id: workerId,
    period_month: period.month,
    period_year: period.year,
    total_orders_handled: metrics?.orders ?? 0,
    avg_rating: metrics?.avgRating ?? null,
    on_time_completion_pct: null,
    assessment: assessment
      ? { scores: assessment.scores, note: assessment.note, updated_at: assessment.updatedAt }
      : null,
  };
}

async function requireWorker(env: Bindings, workerId: string): Promise<void> {
  if (!UUID_RE.test(workerId) || !(await getWorkerUserId(env, workerId))) {
    throw new AppError(404, 'not_found', 'Karyawan tidak ditemukan');
  }
}

export async function getWorkerKpi(
  env: Bindings,
  workerId: string,
  query: KpiQuery,
): Promise<WorkerKpiView> {
  await requireWorker(env, workerId);
  const period = resolvePeriod(query);
  const [metrics, assessments] = await Promise.all([
    loadMetrics(env, period.month, period.year),
    loadAssessments(env, period.month, period.year),
  ]);
  return toView(workerId, period, metrics.get(workerId), assessments.get(workerId));
}

export async function getKpiOverview(
  env: Bindings,
  query: KpiQuery,
): Promise<{ items: WorkerKpiView[] }> {
  const period = resolvePeriod(query);
  const [workers, metrics, assessments] = await Promise.all([
    listManagedWorkers(env),
    loadMetrics(env, period.month, period.year),
    loadAssessments(env, period.month, period.year),
  ]);
  return {
    items: workers.map((w) => toView(w.id, period, metrics.get(w.id), assessments.get(w.id))),
  };
}

/**
 * Penilaian diisi Owner untuk bulan berjalan saja (riwayat bulan lalu dikunci).
 * operational_score = rata-rata skor aspek dalam skala 100; composite_score =
 * 60% operational + 40% rating customer (dinormalisasi ke skala 100), sesuai PRD.
 */
export async function saveAssessment(
  env: Bindings,
  ownerUserId: string,
  workerId: string,
  input: SaveAssessmentInput,
): Promise<WorkerKpiView> {
  await requireWorker(env, workerId);

  const current = currentPeriodWib();
  if (input.month !== current.month || input.year !== current.year) {
    throw new AppError(409, 'period_closed', 'Penilaian hanya bisa diubah pada bulan berjalan.');
  }

  const scores: Record<string, number> = {};
  for (const aspect of KPI_ASPECTS) scores[aspect] = input.scores[aspect];
  const total = KPI_ASPECTS.reduce((sum, aspect) => sum + input.scores[aspect], 0);
  const operational = round2((total / (KPI_ASPECTS.length * 5)) * 100);

  const metrics = (await loadMetrics(env, input.month, input.year)).get(workerId);
  const avgRating = metrics?.avgRating ?? null;
  const composite =
    avgRating === null ? operational : round2(0.6 * operational + 0.4 * (avgRating / 5) * 100);

  const note = input.note?.trim() ? input.note.trim() : null;
  await upsertAssessment(env, {
    workerId,
    month: input.month,
    year: input.year,
    scores,
    note,
    operationalScore: operational,
    compositeScore: composite,
    totalOrders: metrics?.orders ?? 0,
    avgRating,
  });

  await logActivity(env, {
    userId: ownerUserId,
    action: 'worker_kpi_assess',
    entity: 'worker',
    entityId: workerId,
    metadata: { month: input.month, year: input.year, operational_score: operational },
  });

  return getWorkerKpi(env, workerId, { month: input.month, year: input.year });
}

export async function listWorkerReviews(
  env: Bindings,
  workerId: string,
): Promise<{ items: WorkerReviewView[] }> {
  await requireWorker(env, workerId);
  const rows = await listReviewRows(env, workerId);
  return {
    items: rows.map((row) => {
      const order = one(row.order);
      return {
        id: row.id as string,
        // Nama disamarkan: yang melihat ulasan belum tentu perlu nama lengkap customer.
        customer_name: maskName(one(one(row.customer)?.users)?.full_name as string | null),
        rating_value: Number(row.rating_value),
        created_at: row.created_at as string,
        order_number: (order?.order_number as string | undefined) ?? '-',
        comment: (row.comment as string | null) ?? null,
        service_name: serviceNamesOf(order)[0] ?? null,
      };
    }),
  };
}
