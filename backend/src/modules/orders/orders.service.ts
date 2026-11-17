import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import type { AuthContextUser } from '../../shared/types/user';
import { fingerprintOf, idempotencyConflict } from '../../shared/utils/idempotency';
import { notifyNewOrder } from '../notifications/notifications.events';
import { loadVisibleOrder, resolveAccess } from './orders.access';
import { toOrderView } from './orders.mapper';
import {
  EMPTY_USAGE,
  computeTotals,
  evaluatePromos,
  toRpcPromos,
  totalDiscount,
} from './orders.pricing';
import type { PromoEvaluation } from './orders.pricing';
import {
  createOrderViaRpc,
  findCustomerProfileByUserId,
  findOrderByIdempotencyKey,
  findPromoByCode,
  findServicesByIds,
  getOrderRow,
  getPromoUsage,
  getRatePerKm,
  listOrderRows,
} from './orders.repo';
import type { CreateOrderInput, ListOrdersQuery, QuoteOrderInput } from './orders.schema';
import { calculateShippingFee, routeDistanceKm } from './orders.shipping';
import type {
  CustomerProfileRow,
  OrderView,
  PriceQuoteView,
  PricedLine,
} from './orders.types';

function profileIncomplete(): AppError {
  return new AppError(
    400,
    'profile_incomplete',
    'Lengkapi alamat di profil dulu sebelum membuat order.',
  );
}

interface Coordinates {
  lat: number;
  lng: number;
}

function requireCoordinates(profile: CustomerProfileRow | null): Coordinates {
  if (!profile || profile.default_lat === null || profile.default_lng === null) {
    throw profileIncomplete();
  }
  return { lat: profile.default_lat, lng: profile.default_lng };
}

async function loadShipping(
  env: Bindings,
  coords: Coordinates,
): Promise<{ fee: number; distanceKm: number }> {
  const [route, rate] = await Promise.all([
    routeDistanceKm(coords.lat, coords.lng),
    getRatePerKm(env),
  ]);
  return { fee: calculateShippingFee(route.km, rate), distanceKm: route.km };
}

export async function priceItems(
  env: Bindings,
  items: Array<{ service_id: string; quantity: number }>,
): Promise<{ subtotal: number; lines: PricedLine[] }> {
  const serviceIds = [...new Set(items.map((item) => item.service_id))];
  const services = await findServicesByIds(env, serviceIds);
  const byId = new Map(services.map((s) => [s.id, s]));

  let subtotal = 0;
  const lines: PricedLine[] = [];
  for (const item of items) {
    const service = byId.get(item.service_id);
    if (!service || !service.is_active) {
      throw new AppError(400, 'service_unavailable', 'Salah satu layanan sudah tidak tersedia.');
    }
    const amount = service.base_price * item.quantity;
    subtotal += amount;
    lines.push({ service_id: service.id, amount });
  }
  return { subtotal, lines };
}

async function loadPromos(
  env: Bindings,
  codes: string[],
  base: { subtotal: number; shipping: number; lines: PricedLine[] },
  customerId: string | null,
): Promise<PromoEvaluation[]> {
  if (codes.length === 0) return [];
  const entries = await Promise.all(
    codes.map(async (code) => {
      const promo = await findPromoByCode(env, code);
      const usage = promo ? await getPromoUsage(env, promo, customerId) : EMPTY_USAGE;
      return { code, promo, usage };
    }),
  );
  return evaluatePromos(entries, base);
}

/** Bentuk promo di respons kutipan harga. */
export function toQuotePromos(evaluations: PromoEvaluation[]): PriceQuoteView['promos'] {
  return evaluations.map((item) => ({
    code: item.code,
    applies_to: item.appliesTo,
    discount_amount: item.discount,
    description: item.description,
  }));
}

export async function quoteOrder(
  env: Bindings,
  userId: string,
  input: QuoteOrderInput,
): Promise<PriceQuoteView> {
  const profile = await findCustomerProfileByUserId(env, userId);
  const coords = requireCoordinates(profile);
  const shipping = await loadShipping(env, coords);

  const priced =
    input.items !== undefined
      ? await priceItems(env, input.items)
      : { subtotal: input.subtotal ?? 0, lines: [] as PricedLine[] };

  const evaluations = await loadPromos(
    env,
    input.promo_codes,
    { subtotal: priced.subtotal, shipping: shipping.fee, lines: priced.lines },
    profile?.id ?? null,
  );

  const totals = computeTotals(priced.subtotal, totalDiscount(evaluations), shipping.fee);
  return {
    subtotal: totals.subtotal,
    discount_amount: totals.discount,
    shipping_fee: totals.shipping,
    total_price: totals.total,
    promos: toQuotePromos(evaluations),
    distance_km: Math.round(shipping.distanceKm * 100) / 100,
  };
}

export interface CreateOrderResult {
  order: OrderView;
  /** true bila request ini hanya mengulang order yang sudah dibuat dengan kunci yang sama. */
  replayed: boolean;
}

/** Sidik jari isi order; urutan dan nilai harus sama persis agar dianggap request yang sama. */
function orderFingerprint(input: CreateOrderInput): Promise<string> {
  return fingerprintOf({
    items: input.items.map((item) => [
      item.service_id,
      item.shoe_brand,
      item.quantity,
      item.notes,
    ]),
    pickup: input.pickup_address,
    delivery: input.delivery_address,
    // Urutan kode tidak mengubah isi order.
    promos: [...input.promo_codes].sort(),
  });
}

export async function createOrder(
  env: Bindings,
  userId: string,
  input: CreateOrderInput,
  idempotencyKey: string | null,
): Promise<CreateOrderResult> {
  const profile = await findCustomerProfileByUserId(env, userId);
  const fingerprint = idempotencyKey ? await orderFingerprint(input) : null;

  if (idempotencyKey && profile) {
    const existing = await findOrderByIdempotencyKey(env, profile.id, idempotencyKey);
    if (existing) {
      if (existing.fingerprint !== fingerprint) throw idempotencyConflict();
      const row = await getOrderRow(env, existing.id);
      if (row) return { order: toOrderView(row, null), replayed: true };
    }
  }

  const coords = requireCoordinates(profile);
  const priced = await priceItems(env, input.items);
  const shipping = await loadShipping(env, coords);
  const evaluations = await loadPromos(
    env,
    input.promo_codes,
    { subtotal: priced.subtotal, shipping: shipping.fee, lines: priced.lines },
    profile?.id ?? null,
  );

  const orderId = await createOrderViaRpc(env, {
    userId,
    items: input.items.map((item) => ({
      service_id: item.service_id,
      shoe_brand: item.shoe_brand,
      quantity: item.quantity,
      notes: item.notes,
    })),
    pickupAddress: input.pickup_address,
    pickupLat: coords.lat,
    pickupLng: coords.lng,
    deliveryAddress: input.delivery_address,
    promos: toRpcPromos(evaluations),
    shippingFee: shipping.fee,
    expectedSubtotal: priced.subtotal,
    idempotencyKey,
    requestFingerprint: fingerprint,
  });

  const row = await getOrderRow(env, orderId);
  if (!row) {
    console.error('orders: order baru tidak ditemukan setelah dibuat', orderId);
    throw new AppError(500, 'order_create_failed', 'Order dibuat, tetapi gagal dimuat. Cek daftar order.');
  }

  // Order baru masuk antrean: kabari worker agar bisa diambil.
  await notifyNewOrder(env, { id: orderId, order_number: String(row.order_number) });

  return { order: toOrderView(row, null), replayed: false };
}

export async function listOrders(
  env: Bindings,
  ctx: AuthContextUser,
  query: ListOrdersQuery,
): Promise<{ items: OrderView[]; page: number; limit: number; total: number }> {
  const access = await resolveAccess(env, ctx);
  if (access.scope.kind === 'none') {
    return { items: [], page: query.page, limit: query.limit, total: 0 };
  }

  const { rows, total } = await listOrderRows(env, access.scope, query);
  return {
    items: rows.map((row) => toOrderView(row, access.viewer)),
    page: query.page,
    limit: query.limit,
    total,
  };
}

export async function getOrder(
  env: Bindings,
  ctx: AuthContextUser,
  orderId: string,
): Promise<OrderView> {
  const access = await resolveAccess(env, ctx);
  const row = await loadVisibleOrder(env, access, orderId);
  return toOrderView(row, access.viewer);
}
