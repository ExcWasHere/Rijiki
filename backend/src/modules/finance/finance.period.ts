import type { FinancePeriod, SeriesPoint, TransactionRow } from './finance.types';

/**
 * Semua perhitungan periode memakai tanggal WIB (UTC+7), bukan UTC: transaksi
 * yang dicatat pukul 06.00 WIB tanggal 18 tidak boleh jatuh ke tanggal 17.
 */
const WIB_OFFSET_MS = 7 * 60 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;
const WEEKDAY_LABELS = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

export interface DateRange {
  /** YYYY-MM-DD, inklusif. */
  from: string;
  /** YYYY-MM-DD, inklusif. */
  to: string;
}

export type SeriesBucket =
  | { label: string; kind: 'date'; from: string; to: string }
  | { label: string; kind: 'hour'; fromHour: number; toHour: number };

export interface PeriodPlan {
  current: DateRange;
  previous: DateRange;
  buckets: SeriesBucket[];
}

/** Bagian tanggal WIB dari sebuah instant, ditulis YYYY-MM-DD. */
export function wibDateOf(instant: Date): string {
  return new Date(instant.getTime() + WIB_OFFSET_MS).toISOString().slice(0, 10);
}

/** Jam WIB (0-23) dari sebuah instant. */
function wibHourOf(instant: Date): number {
  return new Date(instant.getTime() + WIB_OFFSET_MS).getUTCHours();
}

/** Nomor hari (epoch day) dari YYYY-MM-DD; dipakai untuk aritmetika tanggal. */
function dayNumber(day: string): number {
  const parts = day.split('-').map(Number);
  return Date.UTC(parts[0] ?? 1970, (parts[1] ?? 1) - 1, parts[2] ?? 1) / DAY_MS;
}

function dayFromNumber(value: number): string {
  return new Date(value * DAY_MS).toISOString().slice(0, 10);
}

export function addDays(day: string, days: number): string {
  return dayFromNumber(dayNumber(day) + days);
}

/** Senin sebagai awal minggu. */
function startOfWeek(day: string): string {
  const weekday = new Date(dayNumber(day) * DAY_MS).getUTCDay(); // 0 = Minggu
  const offset = weekday === 0 ? 6 : weekday - 1;
  return addDays(day, -offset);
}

function endOfMonth(year: number, month: number): string {
  return new Date(Date.UTC(year, month, 0)).toISOString().slice(0, 10);
}

function monthRange(year: number, month: number): DateRange {
  const from = `${year}-${String(month).padStart(2, '0')}-01`;
  return { from, to: endOfMonth(year, month) };
}

function hourBuckets(): SeriesBucket[] {
  const buckets: SeriesBucket[] = [];
  for (let hour = 0; hour < 24; hour += 3) {
    buckets.push({
      label: String(hour).padStart(2, '0'),
      kind: 'hour',
      fromHour: hour,
      toHour: hour + 3,
    });
  }
  return buckets;
}

function weekBuckets(from: string): SeriesBucket[] {
  return WEEKDAY_LABELS.map((label, index) => {
    const day = addDays(from, index);
    return { label, kind: 'date', from: day, to: day };
  });
}

function monthBuckets(range: DateRange): SeriesBucket[] {
  const lastDay = Number(range.to.slice(8, 10));
  const buckets: SeriesBucket[] = [];
  for (let index = 0; index * 7 < lastDay; index += 1) {
    const startDay = index * 7 + 1;
    const endDay = Math.min(startDay + 6, lastDay);
    const pad = (value: number) => String(value).padStart(2, '0');
    buckets.push({
      label: `Mg ${index + 1}`,
      kind: 'date',
      from: `${range.from.slice(0, 7)}-${pad(startDay)}`,
      to: `${range.from.slice(0, 7)}-${pad(endDay)}`,
    });
  }
  return buckets;
}

/** Rentang periode berjalan, pembandingnya, dan pembagian grafiknya. */
export function planPeriod(period: FinancePeriod, now: Date = new Date()): PeriodPlan {
  const today = wibDateOf(now);

  if (period === 'today') {
    return {
      current: { from: today, to: today },
      previous: { from: addDays(today, -1), to: addDays(today, -1) },
      buckets: hourBuckets(),
    };
  }

  if (period === 'week') {
    const from = startOfWeek(today);
    const to = addDays(from, 6);
    return {
      current: { from, to },
      previous: { from: addDays(from, -7), to: addDays(from, -1) },
      buckets: weekBuckets(from),
    };
  }

  const parts = today.split('-').map(Number);
  const year = parts[0] ?? 1970;
  const month = parts[1] ?? 1;
  const current = monthRange(year, month);
  const previousMonth = month === 1 ? { year: year - 1, month: 12 } : { year, month: month - 1 };
  return {
    current,
    previous: monthRange(previousMonth.year, previousMonth.month),
    buckets: monthBuckets(current),
  };
}

/**
 * Satu titik grafik per bucket; bucket kosong tetap muncul dengan nilai 0.
 * Bucket jam hanya dipakai periode "Hari ini", jadi tanggalnya dibandingkan
 * dengan [range] (tanggal WIB hari ini), bukan dengan baris lain.
 */
export function buildSeries(
  rows: TransactionRow[],
  buckets: SeriesBucket[],
  range: DateRange,
): SeriesPoint[] {
  const income = rows.filter((row) => row.type === 'income');

  return buckets.map((bucket) => {
    const amount = income
      .filter((row) => {
        if (row.transaction_date < range.from || row.transaction_date > range.to) return false;
        if (bucket.kind === 'date') {
          return row.transaction_date >= bucket.from && row.transaction_date <= bucket.to;
        }
        const hour = wibHourOf(new Date(row.created_at));
        return hour >= bucket.fromHour && hour < bucket.toHour;
      })
      .reduce((sum, row) => sum + row.amount, 0);
    return { label: bucket.label, amount };
  });
}

export function sumByType(rows: TransactionRow[]): { income: number; expense: number } {
  let income = 0;
  let expense = 0;
  for (const row of rows) {
    if (row.type === 'income') income += row.amount;
    else expense += row.amount;
  }
  return { income, expense };
}

export function expenseByType(rows: TransactionRow[]): Record<string, number> {
  const totals: Record<string, number> = {
    material: 0,
    equipment: 0,
    external_service: 0,
    other: 0,
  };
  for (const row of rows) {
    if (row.type !== 'expense') continue;
    const key = row.expense_type ?? 'other';
    totals[key] = (totals[key] ?? 0) + row.amount;
  }
  return totals;
}

export { wibHourOf };
