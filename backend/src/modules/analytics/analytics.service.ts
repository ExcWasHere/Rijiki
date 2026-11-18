import type { Bindings } from '../../shared/types/env';
import { planPeriod, buildSeries, sumByType } from '../finance/finance.period';
import { listTransactionsInRange } from '../finance/finance.repo';
import type { DashboardSummaryView, FinancePeriod } from '../finance/finance.types';
import { countActiveOrders } from './analytics.repo';

/**
 * Ringkasan dashboard owner: pemasukan, pengeluaran, laba, order aktif, dan
 * grafik omzet per periode (PRD 20.0). Angka diambil dari tabel yang sama
 * dengan halaman Keuangan supaya kedua layar tidak pernah berbeda.
 */
export async function getDashboardSummary(
  env: Bindings,
  period: FinancePeriod,
): Promise<DashboardSummaryView> {
  const plan = planPeriod(period);
  const [currentRows, previousRows, activeOrders] = await Promise.all([
    listTransactionsInRange(env, plan.current),
    listTransactionsInRange(env, plan.previous),
    countActiveOrders(env),
  ]);

  const totals = sumByType(currentRows);
  return {
    period,
    income: totals.income,
    expense: totals.expense,
    previous_income: sumByType(previousRows).income,
    active_orders: activeOrders,
    series: buildSeries(currentRows, plan.buckets, plan.current),
  };
}
