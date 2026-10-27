import { OUTLET } from '../../config/outlet';

const OSRM_BASE_URL = 'https://router.project-osrm.org/route/v1/driving';
const OSRM_TIMEOUT_MS = 4000;
const ROAD_FACTOR = 1.3;
const CACHE_TTL_MS = 10 * 60 * 1000;
const CACHE_MAX_ENTRIES = 200;

export interface RouteDistance {
  km: number;
  source: 'osrm' | 'haversine';
}

const cache = new Map<string, { value: RouteDistance; expiresAt: number }>();

export function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const earthRadiusKm = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * earthRadiusKm * Math.asin(Math.min(1, Math.sqrt(a)));
}

async function fetchOsrmKm(lat: number, lng: number): Promise<number | null> {
  try {
    const url =
      `${OSRM_BASE_URL}/${OUTLET.lng},${OUTLET.lat};${lng},${lat}` +
      '?overview=false&alternatives=false&steps=false';
    const res = await fetch(url, {
      signal: AbortSignal.timeout(OSRM_TIMEOUT_MS),
      headers: { 'User-Agent': 'rijiki-backend/1.0' },
    });
    if (!res.ok) {
      console.error('shipping: OSRM membalas status', res.status);
      return null;
    }
    const body = (await res.json()) as {
      code?: string;
      routes?: Array<{ distance?: number }>;
    };
    const meters = body.routes?.[0]?.distance;
    if (body.code !== 'Ok' || typeof meters !== 'number' || !Number.isFinite(meters)) {
      return null;
    }
    return meters / 1000;
  } catch (err) {
    console.error('shipping: OSRM gagal, pakai fallback', err instanceof Error ? err.message : err);
    return null;
  }
}

export async function routeDistanceKm(lat: number, lng: number): Promise<RouteDistance> {
  const key = `${lat.toFixed(4)},${lng.toFixed(4)}`;
  const hit = cache.get(key);
  if (hit && hit.expiresAt > Date.now()) return hit.value;

  const osrmKm = await fetchOsrmKm(lat, lng);
  const value: RouteDistance =
    osrmKm !== null
      ? { km: osrmKm, source: 'osrm' }
      : { km: haversineKm(OUTLET.lat, OUTLET.lng, lat, lng) * ROAD_FACTOR, source: 'haversine' };
  if (value.source === 'osrm') {
    if (cache.size >= CACHE_MAX_ENTRIES) cache.clear();
    cache.set(key, { value, expiresAt: Date.now() + CACHE_TTL_MS });
  }
  return value;
}

export function calculateShippingFee(distanceKm: number, ratePerKm: number): number {
  const billableKm = Math.ceil(Math.round(distanceKm * 1000) / 1000);
  return Math.max(0, Math.round(billableKm * ratePerKm));
}
