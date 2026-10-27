import { AppError } from '../../shared/errors';
import type { Bindings } from '../../shared/types/env';
import type { AuthContextUser } from '../../shared/types/user';
import { toOrderView } from './orders.mapper';
import { computeTotals, evaluatePromo } from './orders.pricing';
import type { PromoEvaluation } from './orders.pricing';
import {
  createOrderViaRpc,
  findCustomerProfileByUserId,
  findPromoByCode,
  findServicesByIds,
  findWorkerProfileId,
  getOrderRow,
  getRatePerKm,
  listOrderRows,
} from './orders.repo';
import type { CreateOrderInput, ListOrdersQuery, QuoteOrderInput } from './orders.schema';
import { calculateShippingFee, routeDistanceKm } from './orders.shipping';
import type {
  CustomerProfileRow,
  OrderScope,
  OrderView,
  PriceQuoteView,
} from './orders.types';

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

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

async function loadPromo(
  env: Bindings,
  code: string | null | undefined,
  base: { subtotal: number; shipping: number },
): Promise<{ evaluation: PromoEvaluation | null; promoId: string | null }> {
  if (!code) return { evaluation: null, promoId: null };
  const promo = await findPromoByCode(env, code);
  const evaluation = evaluatePromo(promo, base);
  return { evaluation, promoId: promo?.id ?? null };
}

export async function quoteOrder(
  env: Bindings,
  userId: string,
  input: QuoteOrderInput,
): Promise<PriceQuoteView> {
  const profile = await findCustomerProfileByUserId(env, userId);
  const coords = requireCoordinates(profile);
  const shipping = await loadShipping(env, coords);

  const { evaluation } = await loadPromo(env, input.promo_code, {
    subtotal: input.subtotal,
    shipping: shipping.fee,
  });

  const totals = computeTotals(input.subtotal, evaluation?.discount ?? 0, shipping.fee);
  return {
    subtotal: totals.subtotal,
    discount_amount: totals.discount,
    shipping_fee: totals.shipping,
    total_price: totals.total,
    promo_code: evaluation?.code ?? null,
    promo_description: evaluation?.description ?? null,
    distance_km: Math.round(shipping.distanceKm * 100) / 100,
  };
}

export async function createOrder(
  env: Bindings,
  userId: string,
  input: CreateOrderInput,
): Promise<OrderView> {
  const profile = await findCustomerProfileByUserId(env, userId);
  const coords = requireCoordinates(profile);
  const serviceIds = [...new Set(input.items.map((item) => item.service_id))];
  const services = await findServicesByIds(env, serviceIds);
  const priceById = new Map(services.map((s) => [s.id, s]));

  let subtotal = 0;
  for (const item of input.items) {
    const service = priceById.get(item.service_id);
    if (!service || !service.is_active) {
      throw new AppError(400, 'service_unavailable', 'Salah satu layanan sudah tidak tersedia.');
    }
    subtotal += service.base_price * item.quantity;
  }

  const shipping = await loadShipping(env, coords);
  const { evaluation, promoId } = await loadPromo(env, input.promo_code, {
    subtotal,
    shipping: shipping.fee,
  });

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
    promoId,
    discountAmount: evaluation?.discount ?? 0,
    shippingFee: shipping.fee,
    expectedSubtotal: subtotal,
  });

  const row = await getOrderRow(env, orderId);
  if (!row) {
    console.error('orders: order baru tidak ditemukan setelah dibuat', orderId);
    throw new AppError(500, 'order_create_failed', 'Order dibuat, tetapi gagal dimuat. Cek daftar order.');
  }
  return toOrderView(row);
}

async function resolveScope(env: Bindings, ctx: AuthContextUser): Promise<OrderScope> {
  const { user, permissions, ownerBypass } = ctx;

  if (ownerBypass) return { kind: 'all' };

  if (user.role === 'worker') {
    if (permissions.includes('manage_orders_all')) return { kind: 'all' };
    const workerProfileId = await findWorkerProfileId(env, user.id);
    return workerProfileId ? { kind: 'worker', workerProfileId } : { kind: 'none' };
  }

  if (user.role === 'customer') {
    const profile = await findCustomerProfileByUserId(env, user.id);
    return profile ? { kind: 'customer', customerProfileId: profile.id } : { kind: 'none' };
  }

  return { kind: 'none' };
}

export async function listOrders(
  env: Bindings,
  ctx: AuthContextUser,
  query: ListOrdersQuery,
): Promise<{ items: OrderView[]; page: number; limit: number; total: number }> {
  const scope = await resolveScope(env, ctx);
  if (scope.kind === 'none') {
    return { items: [], page: query.page, limit: query.limit, total: 0 };
  }

  const { rows, total } = await listOrderRows(env, scope, query);
  return {
    items: rows.map(toOrderView),
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
  const notFound = new AppError(404, 'order_not_found', 'Order tidak ditemukan');
  if (!UUID_PATTERN.test(orderId)) throw notFound;

  const scope = await resolveScope(env, ctx);
  if (scope.kind === 'none') throw notFound;

  const row = await getOrderRow(env, orderId);
  if (!row) throw notFound;
  if (scope.kind === 'customer' && row.customer_id !== scope.customerProfileId) throw notFound;
  if (scope.kind === 'worker' && row.assigned_worker_id !== scope.workerProfileId) throw notFound;

  return toOrderView(row);
}
