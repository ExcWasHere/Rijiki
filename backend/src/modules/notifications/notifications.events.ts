import { getSupabaseAdmin } from '../../config/supabase';
import type { Bindings } from '../../shared/types/env';
import type { OrderStatus } from '../orders/orders.types';
import {
  notifyCustomerProfile,
  notifyUser,
  notifyWorkerProfile,
} from './notifications.service';

const STATUS_TITLE: Record<OrderStatus, string> = {
  order: 'Pesanan diterima',
  pickup: 'Sepatu sedang dijemput',
  waiting: 'Sepatu sudah di outlet',
  cleaning: 'Sepatu sedang dibersihkan',
  delivery: 'Sepatu sedang diantar',
  completed: 'Order selesai',
  cancelled: 'Order dibatalkan',
};

const STATUS_BODY: Record<OrderStatus, string> = {
  order: 'Pesananmu sudah kami terima. Kurir akan segera menjemput sepatumu.',
  pickup: 'Kurir sedang menuju alamatmu untuk menjemput sepatu.',
  waiting: 'Sepatu sudah tiba di outlet dan menunggu giliran dibersihkan.',
  cleaning: 'Sepatu sedang dalam proses pembersihan oleh tim Rijiki.',
  delivery: 'Sepatu yang sudah bersih sedang diantar kembali ke alamatmu.',
  completed: 'Sepatu sudah kembali bersih. Terima kasih sudah memakai Rijiki!',
  cancelled: 'Order dibatalkan. Hubungi CS Rijiki bila kamu butuh bantuan.',
};

export interface OrderNotificationTarget {
  id: string;
  order_number: string;
  customer_id: string | null;
  assigned_worker_id: string | null;
}

/** Customer diberi tahu setiap kali status ordernya berubah. */
export async function notifyOrderStatus(
  env: Bindings,
  order: OrderNotificationTarget,
  status: OrderStatus,
): Promise<void> {
  await notifyCustomerProfile(env, order.customer_id, {
    type: 'order_status',
    title: `${STATUS_TITLE[status]} · ${order.order_number}`,
    body: STATUS_BODY[status],
    data: { order_id: order.id, status },
  });
}

/** Worker diberi tahu saat order di-assign atau ia mengambil order dari antrean. */
export async function notifyOrderAssigned(
  env: Bindings,
  order: OrderNotificationTarget,
): Promise<void> {
  await notifyWorkerProfile(env, order.assigned_worker_id, {
    type: 'order_assigned',
    title: `Order baru untukmu · ${order.order_number}`,
    body: 'Order ini sudah ditugaskan ke kamu. Buka detail untuk melihat jadwal jemput.',
    data: { order_id: order.id },
  });
}

/** Customer diberi tahu saat pembayaran QRIS-nya lunas. */
export async function notifyPaymentPaid(
  env: Bindings,
  order: { id: string; order_number: string; customer_id: string | null },
): Promise<void> {
  await notifyCustomerProfile(env, order.customer_id, {
    type: 'payment_paid',
    title: `Pembayaran berhasil · ${order.order_number}`,
    body: 'Pembayaranmu sudah kami terima. Kurir akan menjemput sepatu sesuai jadwal.',
    data: { order_id: order.id },
  });
}

/** Customer diberi tahu saat pengajuan tukar poinnya diproses. */
export async function notifyRedemptionProcessed(
  env: Bindings,
  params: {
    customerProfileId: string;
    status: 'approved' | 'rejected' | 'fulfilled';
    rewardName: string;
    notes: string | null;
  },
): Promise<void> {
  const title =
    params.status === 'rejected'
      ? `Tukar poin ditolak · ${params.rewardName}`
      : params.status === 'fulfilled'
        ? `Hadiah siap · ${params.rewardName}`
        : `Tukar poin disetujui · ${params.rewardName}`;

  const body =
    params.status === 'rejected'
      ? (params.notes?.trim() || 'Pengajuan tukar poinmu belum bisa kami proses.')
      : params.status === 'fulfilled'
        ? 'Hadiah bisa diambil di outlet atau dibawa bersama order berikutnya.'
        : 'Poin sudah dipotong. Hadiah akan disiapkan oleh tim Rijiki.';

  await notifyCustomerProfile(env, params.customerProfileId, {
    type: 'point_redemption',
    title,
    body,
    data: { status: params.status },
  });
}

/** Antrean order baru: semua worker aktif diberi tahu agar bisa mengambilnya. */
export async function notifyNewOrder(
  env: Bindings,
  order: { id: string; order_number: string },
): Promise<void> {
  const admin = getSupabaseAdmin(env);
  const { data, error } = await admin
    .from('worker_profiles')
    .select('user_id')
    .eq('status', 'active');

  if (error) {
    console.error('notifications: gagal memuat worker aktif', error.message);
    return;
  }

  const userIds = ((data ?? []) as Array<{ user_id: string }>).map((row) => row.user_id);
  await Promise.all(
    userIds.map((userId) =>
      notifyUser(env, {
        userId,
        type: 'order_new',
        title: `Order baru masuk · ${order.order_number}`,
        body: 'Ada order baru di antrean. Ambil order bila kamu siap menjemput.',
        data: { order_id: order.id },
      }),
    ),
  );
}

/** QR pembayaran kedaluwarsa: customer perlu membuat QR baru. */
export async function notifyPaymentExpired(
  env: Bindings,
  order: { id: string; order_number: string; customer_id: string | null },
): Promise<void> {
  await notifyCustomerProfile(env, order.customer_id, {
    type: 'payment_expired',
    title: `QR kedaluwarsa · ${order.order_number}`,
    body: 'Waktu pembayaran habis. Buka detail order untuk membuat QR baru.',
    data: { order_id: order.id },
  });
}
