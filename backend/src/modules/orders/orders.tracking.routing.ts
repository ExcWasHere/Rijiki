import { haversineKm } from './orders.shipping';
const OSRM_BASE_URL = 'https://router.project-osrm.org/route/v1/driving';
const OSRM_TIMEOUT_MS = 4000;
const ROAD_FACTOR = 1.3;
const FALLBACK_SPEED_KMH = 20;
const CACHE_TTL_MS = 20 * 1000;
const CACHE_MAX_ENTRIES = 300;

export interface Waypoint {
  lat: number;
  lng: number;
}

export interface RouteResult {
  points: Array<[number, number]> | null;
  distanceKm: number;
  durationMin: number;
  source: 'osrm' | 'estimate';
}

const cache = new Map<string, { value: RouteResult; expiresAt: number }>();

function keyOf(waypoints: Waypoint[]): string {
  return waypoints.map((w) => `${w.lat.toFixed(4)},${w.lng.toFixed(4)}`).join(';');
}

function estimate(waypoints: Waypoint[]): RouteResult {
  let km = 0;
  for (let i = 1; i < waypoints.length; i++) {
    const a = waypoints[i - 1]!;
    const b = waypoints[i]!;
    km += haversineKm(a.lat, a.lng, b.lat, b.lng) * ROAD_FACTOR;
  }
  return {
    points: null,
    distanceKm: km,
    durationMin: (km / FALLBACK_SPEED_KMH) * 60,
    source: 'estimate',
  };
}

async function fetchOsrm(waypoints: Waypoint[]): Promise<RouteResult | null> {
  try {
    const coords = waypoints.map((w) => `${w.lng},${w.lat}`).join(';');
    const url =
      `${OSRM_BASE_URL}/${coords}` +
      '?overview=simplified&geometries=geojson&alternatives=false&steps=false';
    const res = await fetch(url, {
      signal: AbortSignal.timeout(OSRM_TIMEOUT_MS),
      headers: { 'User-Agent': 'rijiki-backend/1.0' },
    });
    if (!res.ok) {
      console.error('tracking: OSRM membalas status', res.status);
      return null;
    }
    const body = (await res.json()) as {
      code?: string;
      routes?: Array<{
        distance?: number;
        duration?: number;
        geometry?: { coordinates?: Array<[number, number]> };
      }>;
    };
    const route = body.routes?.[0];
    const coordinates = route?.geometry?.coordinates;
    if (
      body.code !== 'Ok' ||
      !route ||
      !coordinates ||
      typeof route.distance !== 'number' ||
      typeof route.duration !== 'number'
    ) {
      return null;
    }
    return {
      points: coordinates.map(([lng, lat]) => [lat, lng] as [number, number]),
      distanceKm: route.distance / 1000,
      durationMin: route.duration / 60,
      source: 'osrm',
    };
  } catch (err) {
    console.error('tracking: OSRM gagal, pakai estimasi', err instanceof Error ? err.message : err);
    return null;
  }
}

/** Waypoint pertama = posisi kurir, terakhir = tujuan. Minimal dua titik. */
export async function routeVia(waypoints: Waypoint[]): Promise<RouteResult> {
  const key = keyOf(waypoints);
  const hit = cache.get(key);
  if (hit && hit.expiresAt > Date.now()) return hit.value;

  const osrm = await fetchOsrm(waypoints);
  if (osrm) {
    if (cache.size >= CACHE_MAX_ENTRIES) cache.clear();
    cache.set(key, { value: osrm, expiresAt: Date.now() + CACHE_TTL_MS });
    return osrm;
  }
  return estimate(waypoints);
}

/** Arah (derajat 0-360, 0 = utara) dari titik a ke b. */
export function bearingDegrees(a: Waypoint, b: Waypoint): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLng = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const y = Math.sin(dLng) * Math.cos(lat2);
  const x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLng);
  return ((Math.atan2(y, x) * 180) / Math.PI + 360) % 360;
}
