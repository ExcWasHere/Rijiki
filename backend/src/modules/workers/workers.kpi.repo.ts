import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { toNumber, toNumberOrNull } from '../../shared/utils/number';

export interface MetricsRow {
  orders: number;
  avgRating: number | null;
}

export interface AssessmentRow {
  scores: Record<string, number>;
  note: string | null;
  updatedAt: string;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type ReviewRow = Record<string, any>;

function failed(label: string, message: string): AppError {
  console.error(`workers.kpi: gagal ${label}`, message);
  return new AppError(500, 'kpi_failed', `Gagal ${label}. Coba lagi ya.`);
}

/** Metrik semua worker pada satu bulan, dikunci oleh worker_profiles.id. */
export async function loadMetrics(
  env: Bindings,
  month: number,
  year: number,
): Promise<Map<string, MetricsRow>> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin.rpc('worker_kpi_metrics', {
    p_month: month,
    p_year: year,
  });
  if (error) throw failed('menghitung metrik KPI', error.message);

  const result = new Map<string, MetricsRow>();
  for (const row of (data ?? []) as Array<{
    worker_id: string;
    total_orders: number | string;
    avg_rating: number | string | null;
  }>) {
    result.set(row.worker_id, {
      orders: toNumber(row.total_orders),
      avgRating: toNumberOrNull(row.avg_rating),
    });
  }
  return result;
}

/** Penilaian owner yang tersimpan untuk satu periode, dikunci oleh worker_profiles.id. */
export async function loadAssessments(
  env: Bindings,
  month: number,
  year: number,
): Promise<Map<string, AssessmentRow>> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('worker_kpis')
    .select('worker_id, assessment_scores, assessment_note, assessment_updated_at')
    .eq('period_month', month)
    .eq('period_year', year)
    .not('assessment_scores', 'is', null);
  if (error) throw failed('memuat penilaian KPI', error.message);

  const result = new Map<string, AssessmentRow>();
  for (const row of data ?? []) {
    result.set(row.worker_id as string, {
      scores: (row.assessment_scores as Record<string, number>) ?? {},
      note: (row.assessment_note as string | null) ?? null,
      updatedAt: (row.assessment_updated_at as string | null) ?? new Date().toISOString(),
    });
  }
  return result;
}

export async function upsertAssessment(
  env: Bindings,
  params: {
    workerId: string;
    month: number;
    year: number;
    scores: Record<string, number>;
    note: string | null;
    operationalScore: number;
    compositeScore: number;
    totalOrders: number;
    avgRating: number | null;
  },
): Promise<void> {
  const admin = getSupabaseAdmin(env);
  const now = new Date().toISOString();
  const { error } = await admin.from('worker_kpis').upsert(
    {
      worker_id: params.workerId,
      period_month: params.month,
      period_year: params.year,
      total_orders_handled: params.totalOrders,
      avg_rating: params.avgRating,
      operational_score: params.operationalScore,
      composite_score: params.compositeScore,
      assessment_scores: params.scores,
      assessment_note: params.note,
      assessment_updated_at: now,
      updated_at: now,
    },
    { onConflict: 'worker_id,period_year,period_month' },
  );
  if (error) throw failed('menyimpan penilaian KPI', error.message);
}

const REVIEW_LIMIT = 200;

export async function listReviewRows(env: Bindings, workerId: string): Promise<ReviewRow[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('ratings')
    .select(
      'id, rating_value, comment, created_at, order:orders(order_number, order_items(services(name))), customer:customer_profiles(users(full_name))',
    )
    .eq('worker_id', workerId)
    .order('created_at', { ascending: false })
    .limit(REVIEW_LIMIT);
  if (error) throw failed('memuat ulasan worker', error.message);
  return (data ?? []) as unknown as ReviewRow[];
}
