import { getSupabaseAdmin } from '../../config/supabase';
import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import { toNumberOrNull } from '../../shared/utils/number';

export interface TrackingOrderMeta {
  id: string;
  status: string;
  customer_id: string | null;
  assigned_worker_id: string | null;
  delivery_lat: number | null;
  delivery_lng: number | null;
}

export interface TrackingPointRow {
  latitude: number;
  longitude: number;
  recorded_at: string;
}

/** Order yang sedang diantar oleh satu kurir, beserta kapan masuk status delivery. */
export interface DeliveryQueueEntry {
  id: string;
  delivery_lat: number | null;
  delivery_lng: number | null;
  /** Waktu "Mulai antar" ditekan (epoch ms). Menentukan urutan antrean. */
  entered_at: number;
}

function fail(label: string, message: string): AppError {
  console.error(`tracking: gagal ${label}`, message);
  return new AppError(500, 'tracking_failed', 'Gagal memproses data pelacakan');
}

export async function getTrackingOrderMeta(
  env: Bindings,
  orderId: string,
): Promise<TrackingOrderMeta | null> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('orders')
    .select('id, status, customer_id, assigned_worker_id, delivery_lat, delivery_lng')
    .eq('id', orderId)
    .maybeSingle();

  if (error) throw fail('memuat order', error.message);
  if (!data) return null;

  return {
    id: data.id as string,
    status: String(data.status),
    customer_id: (data.customer_id as string | null) ?? null,
    assigned_worker_id: (data.assigned_worker_id as string | null) ?? null,
    delivery_lat: toNumberOrNull(data.delivery_lat),
    delivery_lng: toNumberOrNull(data.delivery_lng),
  };
}

export async function getLatestPoints(
  env: Bindings,
  orderId: string,
  limit: number,
): Promise<TrackingPointRow[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('delivery_trackings')
    .select('latitude, longitude, recorded_at')
    .eq('order_id', orderId)
    .order('recorded_at', { ascending: false })
    .limit(limit);

  if (error) throw fail('memuat titik lokasi', error.message);

  return (data ?? []).map((row) => ({
    latitude: Number(row.latitude),
    longitude: Number(row.longitude),
    recorded_at: String(row.recorded_at),
  }));
}

export async function insertTrackingPoint(
  env: Bindings,
  params: { orderId: string; workerId: string; latitude: number; longitude: number },
): Promise<TrackingPointRow> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('delivery_trackings')
    .insert({
      order_id: params.orderId,
      worker_id: params.workerId,
      latitude: params.latitude,
      longitude: params.longitude,
    })
    .select('latitude, longitude, recorded_at')
    .single();

  if (error || !data) throw fail('menyimpan titik lokasi', error?.message ?? 'tanpa data');

  return {
    latitude: Number(data.latitude),
    longitude: Number(data.longitude),
    recorded_at: String(data.recorded_at),
  };
}

/** Lokasi terakhir worker (worker_profiles.current_lat/lng). Best-effort: tidak melempar error. */
export async function touchWorkerLocation(
  env: Bindings,
  workerId: string,
  latitude: number,
  longitude: number,
): Promise<void> {
  try {
    const admin = getSupabaseAdmin(env);
    const { error } = await admin
      .from('worker_profiles')
      .update({
        current_lat: latitude,
        current_lng: longitude,
        updated_at: new Date().toISOString(),
      })
      .eq('id', workerId);
    if (error) console.error('tracking: gagal memperbarui lokasi worker', error.message);
  } catch (err) {
    console.error('tracking: error memperbarui lokasi worker', err);
  }
}

type Row = Record<string, any>;

export async function listDeliveryQueue(
  env: Bindings,
  workerId: string,
): Promise<DeliveryQueueEntry[]> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('orders')
    .select('id, delivery_lat, delivery_lng, order_status_histories(new_status, changed_at)')
    .eq('assigned_worker_id', workerId)
    .eq('status', 'delivery');

  if (error) throw fail('memuat antrean pengantaran', error.message);

  return ((data ?? []) as Row[]).map((row) => {
    const histories: Row[] = Array.isArray(row.order_status_histories)
      ? row.order_status_histories
      : [];
    const entered = histories
      .filter((h) => h.new_status === 'delivery')
      .map((h) => Date.parse(String(h.changed_at)))
      .filter((t) => Number.isFinite(t));

    return {
      id: row.id as string,
      delivery_lat: toNumberOrNull(row.delivery_lat),
      delivery_lng: toNumberOrNull(row.delivery_lng),
      entered_at: entered.length > 0 ? Math.max(...entered) : 0,
    };
  });
}
