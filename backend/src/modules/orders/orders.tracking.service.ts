import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import type { AuthContextUser } from '../../shared/types/user';
import { isUuid, orderNotFound, resolveAccess } from './orders.access';
import type { OrderAccess } from './orders.access';
import { findWorkerProfile } from './orders.repo';
import {
  getLatestPoints,
  getTrackingOrderMeta,
  insertTrackingPoint,
  listDeliveryQueue,
  touchWorkerLocation,
} from './orders.tracking.repo';
import type { TrackingOrderMeta } from './orders.tracking.repo';
import { bearingDegrees, routeVia } from './orders.tracking.routing';
import type { Waypoint } from './orders.tracking.routing';
import type { TrackingPointInput } from './orders.tracking.schema';

/** Titik yang datang lebih cepat dari ini dari kurir yang sama dianggap duplikat. */
const MIN_POINT_INTERVAL_MS = 2000;
/** Waktu serah-terima per order di depan dalam antrean, ditambahkan ke ETA. */
const STOP_BUFFER_MIN = 3;
/** Gerakan di bawah ini dianggap diam, jadi arah tidak dihitung ulang. */
const MIN_HEADING_MOVE_M = 5;

export interface TrackingView {
  /** false bila order tidak sedang dalam status delivery (aplikasi berhenti polling). */
  active: boolean;
  point: {
    latitude: number;
    longitude: number;
    heading: number;
    recorded_at: string;
  } | null;
  destination: { latitude: number; longitude: number } | null;
  /** Polyline [lat, lng]; null bila hanya estimasi (aplikasi menggambar garis lurus). */
  route: Array<[number, number]> | null;
  route_source: 'osrm' | 'estimate' | null;
  distance_km: number | null;
  eta_minutes: number | null;
  /** 1 = sedang diantar sekarang; 2 dst = menunggu order di depannya selesai. */
  queue_position: number;
  queue_size: number;
}

const INACTIVE: TrackingView = {
  active: false,
  point: null,
  destination: null,
  route: null,
  route_source: null,
  distance_km: null,
  eta_minutes: null,
  queue_position: 1,
  queue_size: 1,
};

async function loadMeta(env: Bindings, orderId: string): Promise<TrackingOrderMeta> {
  if (!isUuid(orderId)) throw orderNotFound();
  const meta = await getTrackingOrderMeta(env, orderId);
  if (!meta) throw orderNotFound();
  return meta;
}

/** Order milik orang lain dijawab 404 (bukan 403) agar id tidak bisa ditebak-tebak. */
function assertCanSeeTracking(meta: TrackingOrderMeta, access: OrderAccess): void {
  const { scope } = access;
  const allowed =
    scope.kind === 'all' ||
    (scope.kind === 'customer' && meta.customer_id === scope.customerProfileId) ||
    (scope.kind === 'worker' && meta.assigned_worker_id === scope.workerProfileId);
  if (!allowed) throw orderNotFound();
}

export async function recordTrackingPoint(
  env: Bindings,
  ctx: AuthContextUser,
  orderId: string,
  input: TrackingPointInput,
): Promise<{ recorded_at: string; skipped: boolean }> {
  if (ctx.user.role !== 'worker') {
    throw new AppError(403, 'forbidden', 'Hanya worker yang dapat mengirim lokasi pengantaran.');
  }

  const worker = await findWorkerProfile(env, ctx.user.id);
  if (!worker || worker.status !== 'active') {
    throw new AppError(403, 'worker_inactive', 'Akun worker kamu tidak aktif.');
  }

  const meta = await loadMeta(env, orderId);
  if (meta.assigned_worker_id !== worker.id) {
    throw new AppError(403, 'not_assigned', 'Order ini bukan tugasmu.');
  }
  if (meta.status !== 'delivery') {
    throw new AppError(
      409,
      'tracking_inactive',
      'Pelacakan hanya aktif saat order berstatus pengantaran.',
    );
  }

  const [latest] = await getLatestPoints(env, orderId, 1);
  if (latest && Date.now() - Date.parse(latest.recorded_at) < MIN_POINT_INTERVAL_MS) {
    return { recorded_at: latest.recorded_at, skipped: true };
  }

  const saved = await insertTrackingPoint(env, {
    orderId,
    workerId: worker.id,
    latitude: input.latitude,
    longitude: input.longitude,
  });
  await touchWorkerLocation(env, worker.id, input.latitude, input.longitude);

  return { recorded_at: saved.recorded_at, skipped: false };
}

export async function getTracking(
  env: Bindings,
  ctx: AuthContextUser,
  orderId: string,
): Promise<TrackingView> {
  const access = await resolveAccess(env, ctx);
  const meta = await loadMeta(env, orderId);
  assertCanSeeTracking(meta, access);

  if (meta.status !== 'delivery') return INACTIVE;

  const destination: Waypoint | null =
    meta.delivery_lat !== null && meta.delivery_lng !== null
      ? { lat: meta.delivery_lat, lng: meta.delivery_lng }
      : null;
  const destinationView = destination
    ? { latitude: destination.lat, longitude: destination.lng }
    : null;

  let position = 1;
  let queueSize = 1;
  let ahead: Waypoint[] = [];
  if (meta.assigned_worker_id) {
    const queue = (await listDeliveryQueue(env, meta.assigned_worker_id)).sort(
      (a, b) => a.entered_at - b.entered_at || a.id.localeCompare(b.id),
    );
    const index = queue.findIndex((entry) => entry.id === meta.id);
    queueSize = Math.max(queue.length, 1);
    position = index >= 0 ? index + 1 : 1;
    ahead = queue
      .slice(0, Math.max(index, 0))
      .filter((entry) => entry.delivery_lat !== null && entry.delivery_lng !== null)
      .map((entry) => ({ lat: entry.delivery_lat as number, lng: entry.delivery_lng as number }));
  }

  const [latest, previous] = await getLatestPoints(env, orderId, 2);
  if (!latest) {
    return {
      active: true,
      point: null,
      destination: destinationView,
      route: null,
      route_source: null,
      distance_km: null,
      eta_minutes: null,
      queue_position: position,
      queue_size: queueSize,
    };
  }

  const here: Waypoint = { lat: latest.latitude, lng: latest.longitude };

  let heading = 0;
  if (previous) {
    const before: Waypoint = { lat: previous.latitude, lng: previous.longitude };
    const movedMeters = Math.hypot(
      (here.lat - before.lat) * 111_320,
      (here.lng - before.lng) * 111_320 * Math.cos((here.lat * Math.PI) / 180),
    );
    if (movedMeters >= MIN_HEADING_MOVE_M) heading = bearingDegrees(before, here);
  }

  let route: Array<[number, number]> | null = null;
  let routeSource: 'osrm' | 'estimate' | null = null;
  let distanceKm: number | null = null;
  let etaMinutes: number | null = null;

  if (destination) {
    const result = await routeVia([here, ...ahead, destination]);
    route = result.points;
    routeSource = result.source;
    distanceKm = Math.round(result.distanceKm * 100) / 100;
    etaMinutes = Math.max(1, Math.ceil(result.durationMin + ahead.length * STOP_BUFFER_MIN));
  }

  return {
    active: true,
    point: {
      latitude: here.lat,
      longitude: here.lng,
      heading: Math.round(heading),
      recorded_at: latest.recorded_at,
    },
    destination: destinationView,
    route,
    route_source: routeSource,
    distance_km: distanceKm,
    eta_minutes: etaMinutes,
    queue_position: position,
    queue_size: queueSize,
  };
}
