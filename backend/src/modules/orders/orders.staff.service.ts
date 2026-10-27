import { AppError } from '../../shared/errors';
import { readImageFile } from '../../shared/storage/image';
import { buildKey, deleteObject, putImage } from '../../shared/storage/r2';
import type { Bindings } from '../../shared/types/env';
import type { AuthContextUser } from '../../shared/types/user';
import { logActivity } from '../../shared/utils/activity-log';
import { parseInput } from '../../shared/utils/validate';
import { isUuid, loadVisibleOrder, orderNotFound, resolveAccess } from './orders.access';
import type { OrderAccess } from './orders.access';
import { toOrderView } from './orders.mapper';
import {
  assignOrderRow,
  changeOrderStatusRpc,
  claimOrderRow,
  deleteDocumentationRows,
  findWorkerProfile,
  findWorkerProfileById,
  getDocumentationRow,
  getOrderRow,
  insertDocumentationRow,
} from './orders.repo';
import { documentationFieldsSchema } from './orders.schema';
import type { UpdateStatusInput } from './orders.schema';
import {
  canUploadDocumentation,
  flowFor,
  flowInfoFromRow,
  isAssignedToViewer,
  isClaimable,
  isFinalStatus,
  nextStatusOf,
  requiredDocumentation,
} from './orders.transitions';
import type { FlowInfo } from './orders.transitions';
import type {
  DocumentationType,
  OrderDocumentationView,
  OrderRow,
  OrderStatus,
  OrderView,
} from './orders.types';

export const DOCUMENTATION_MAX_BYTES = 5 * 1024 * 1024;

const DOCUMENTATION_LABEL: Record<DocumentationType, string> = {
  before: 'foto sebelum',
  after: 'foto sesudah',
  proof_of_delivery: 'bukti pengiriman',
};

function requireStaff(access: OrderAccess): void {
  if (access.viewer.role === 'customer') {
    throw new AppError(403, 'forbidden', 'Aksi ini hanya untuk worker atau owner');
  }
}

async function freshView(env: Bindings, access: OrderAccess, orderId: string): Promise<OrderView> {
  const row = await getOrderRow(env, orderId);
  if (!row) throw orderNotFound();
  return toOrderView(row, access.viewer);
}

// ---------------------------------------------------------------------------
// Ambil order (claim)
// ---------------------------------------------------------------------------

export async function claimOrder(
  env: Bindings,
  ctx: AuthContextUser,
  orderId: string,
): Promise<OrderView> {
  if (ctx.user.role !== 'worker') {
    throw new AppError(403, 'forbidden', 'Hanya worker yang dapat mengambil order. Owner memakai assign.');
  }

  const worker = await findWorkerProfile(env, ctx.user.id);
  if (!worker || worker.status !== 'active') {
    throw new AppError(403, 'worker_inactive', 'Akun worker kamu tidak aktif.');
  }

  const access = await resolveAccess(env, ctx);
  const row = await loadVisibleOrder(env, access, orderId);
  const info = flowInfoFromRow(row);

  if (!isClaimable(info)) {
    if (info.assigned_worker_id !== null) {
      throw new AppError(409, 'already_claimed', 'Order ini sudah diambil worker lain.');
    }
    throw new AppError(409, 'not_claimable', 'Order ini tidak bisa diambil.');
  }

  const claimed = await claimOrderRow(env, orderId, worker.id);
  if (!claimed) {
    // Kalah cepat dari worker lain di antara pengecekan dan update.
    throw new AppError(409, 'already_claimed', 'Order ini sudah diambil worker lain.');
  }

  await logActivity(env, {
    userId: ctx.user.id,
    action: 'order_claim',
    entity: 'order',
    entityId: orderId,
    metadata: { worker_id: worker.id },
  });
  return freshView(env, access, orderId);
}

// ---------------------------------------------------------------------------
// Assign / lepas assign (owner atau manage_orders_all)
// ---------------------------------------------------------------------------

export async function assignOrder(
  env: Bindings,
  ctx: AuthContextUser,
  orderId: string,
  workerId: string | null,
): Promise<OrderView> {
  const access = await resolveAccess(env, ctx);
  requireStaff(access);
  if (!access.viewer.manageAll) {
    throw new AppError(403, 'forbidden', "Tidak punya izin 'manage_orders_all'");
  }

  const row = await loadVisibleOrder(env, access, orderId);
  const info = flowInfoFromRow(row);
  if (isFinalStatus(info.status)) {
    throw new AppError(409, 'order_final', 'Order sudah selesai atau dibatalkan.');
  }

  if (workerId !== null) {
    const worker = await findWorkerProfileById(env, workerId);
    if (!worker || worker.status !== 'active') {
      throw new AppError(400, 'worker_unavailable', 'Worker tidak ditemukan atau tidak aktif.');
    }
  }

  await assignOrderRow(env, orderId, workerId);
  await logActivity(env, {
    userId: ctx.user.id,
    action: workerId ? 'order_assign' : 'order_unassign',
    entity: 'order',
    entityId: orderId,
    metadata: { from: info.assigned_worker_id, to: workerId },
  });
  return freshView(env, access, orderId);
}

// ---------------------------------------------------------------------------
// Ubah status
// ---------------------------------------------------------------------------

function itemIdsOf(row: OrderRow): string[] {
  const items: OrderRow[] = Array.isArray(row.order_items) ? row.order_items : [];
  return items.map((item) => item.id as string);
}

function documentsOf(row: OrderRow): OrderRow[] {
  return Array.isArray(row.order_documentations) ? row.order_documentations : [];
}

/** Foto yang diwajibkan sebelum maju ke status berikutnya (PRD 12, keputusan tahap D). */
function assertDocumentationComplete(row: OrderRow, info: FlowInfo, target: OrderStatus): void {
  const required = requiredDocumentation(info, target);
  if (!required) return;

  const docs = documentsOf(row).filter((doc) => doc.type === required);

  if (required === 'proof_of_delivery') {
    if (docs.length === 0) {
      throw new AppError(
        400,
        'documentation_required',
        'Unggah bukti pengiriman dulu sebelum menyelesaikan order.',
      );
    }
    return;
  }

  const covered = new Set(docs.map((doc) => doc.order_item_id as string | null));
  const missing = itemIdsOf(row).filter((id) => !covered.has(id));
  if (missing.length > 0) {
    throw new AppError(
      400,
      'documentation_required',
      `Lengkapi ${DOCUMENTATION_LABEL[required]} untuk semua sepatu dulu (${missing.length} sepatu belum ada fotonya).`,
    );
  }
}

export async function changeOrderStatus(
  env: Bindings,
  ctx: AuthContextUser,
  orderId: string,
  input: UpdateStatusInput,
): Promise<OrderView> {
  const access = await resolveAccess(env, ctx);
  requireStaff(access);

  const row = await loadVisibleOrder(env, access, orderId);
  const info = flowInfoFromRow(row);
  const { viewer } = access;
  const target = input.new_status;
  const notes = input.notes?.trim() ? input.notes.trim() : null;

  if (isFinalStatus(info.status)) {
    throw new AppError(
      409,
      'order_final',
      'Order sudah selesai atau dibatalkan dan tidak bisa diubah lagi.',
    );
  }
  if (target === info.status) {
    throw new AppError(400, 'validation_error', 'Order sudah berada di status ini.');
  }

  let kind: 'forward' | 'correction' | 'cancel';
  if (target === 'cancelled') {
    if (!viewer.manageAll) {
      throw new AppError(403, 'forbidden', 'Hanya owner atau worker berizin yang dapat membatalkan order.');
    }
    if (info.payment_status === 'paid') {
      throw new AppError(
        409,
        'order_paid',
        'Order yang sudah dibayar tidak bisa dibatalkan lewat aplikasi. Hubungi CS Rijiki untuk pembatalan/refund.',
      );
    }
    kind = 'cancel';
  } else if (target === nextStatusOf(info)) {
    if (!viewer.manageAll && !isAssignedToViewer(info, viewer)) {
      throw new AppError(
        403,
        'not_assigned',
        'Order ini bukan tugasmu. Ambil order dulu atau minta owner meng-assign.',
      );
    }
    kind = 'forward';
  } else {
    if (!viewer.manageAll) {
      throw new AppError(403, 'forbidden', 'Worker hanya dapat memajukan status satu langkah.');
    }
    if (!flowFor(info).includes(target)) {
      throw new AppError(400, 'invalid_transition', 'Status tujuan tidak berlaku untuk order ini.');
    }
    if (!notes) {
      throw new AppError(400, 'validation_error', 'Catatan wajib diisi untuk koreksi status.');
    }
    kind = 'correction';
  }

  // Koreksi owner sengaja tidak memeriksa foto: catatannya sudah menjadi jejak audit.
  if (kind === 'forward') assertDocumentationComplete(row, info, target);

  // TODO(tahap-B): setelah QRIS Duitku asli, wajibkan payment_status = 'paid'
  // sebelum order boleh pindah dari `order` ke `pickup`.

  await changeOrderStatusRpc(env, {
    orderId,
    expectedStatus: info.status,
    newStatus: target,
    changedBy: ctx.user.id,
    notes,
  });

  await logActivity(env, {
    userId: ctx.user.id,
    action: kind === 'cancel' ? 'order_cancel' : 'order_status_change',
    entity: 'order',
    entityId: orderId,
    metadata: { from: info.status, to: target, kind, notes },
  });
  return freshView(env, access, orderId);
}

// ---------------------------------------------------------------------------
// Dokumentasi foto (before / after / proof of delivery)
// ---------------------------------------------------------------------------

function uploadDenied(info: FlowInfo, access: OrderAccess, type: DocumentationType): AppError {
  if (isFinalStatus(info.status)) {
    return new AppError(409, 'order_final', 'Order sudah selesai atau dibatalkan.');
  }
  if (type === 'proof_of_delivery' && info.delivery_method === 'self_pickup') {
    return new AppError(
      400,
      'validation_error',
      'Order ambil sendiri di outlet tidak memerlukan bukti pengiriman.',
    );
  }
  if (!access.viewer.manageAll && !isAssignedToViewer(info, access.viewer)) {
    return new AppError(403, 'not_assigned', 'Order ini bukan tugasmu.');
  }
  return new AppError(
    409,
    'documentation_window_closed',
    `${DOCUMENTATION_LABEL[type][0]?.toUpperCase()}${DOCUMENTATION_LABEL[type].slice(1)} tidak bisa lagi diubah pada status ini.`,
  );
}

export async function uploadDocumentation(
  env: Bindings,
  ctx: AuthContextUser,
  orderId: string,
  body: Record<string, unknown>,
): Promise<OrderDocumentationView> {
  const access = await resolveAccess(env, ctx);
  requireStaff(access);

  const fields = parseInput(documentationFieldsSchema, {
    type: body['type'],
    order_item_id: body['order_item_id'] === '' ? undefined : body['order_item_id'],
  });

  const row = await loadVisibleOrder(env, access, orderId);
  const info = flowInfoFromRow(row);

  if (!canUploadDocumentation(info, access.viewer, fields.type)) {
    throw uploadDenied(info, access, fields.type);
  }

  let orderItemId: string | null = null;
  if (fields.type === 'proof_of_delivery') {
    if (fields.order_item_id) {
      throw new AppError(400, 'validation_error', 'Bukti pengiriman berlaku untuk satu order, bukan per sepatu.');
    }
  } else {
    if (!fields.order_item_id) {
      throw new AppError(400, 'validation_error', 'Pilih sepatu yang difoto.');
    }
    if (!itemIdsOf(row).includes(fields.order_item_id)) {
      throw new AppError(400, 'validation_error', 'Sepatu tidak ada di order ini.');
    }
    orderItemId = fields.order_item_id;
  }

  const image = await readImageFile(body['image'], DOCUMENTATION_MAX_BYTES);

  // Satu foto per (sepatu, jenis); mengunggah ulang berarti mengganti.
  const previous = documentsOf(row).filter(
    (doc) =>
      doc.type === fields.type && ((doc.order_item_id as string | null) ?? null) === orderItemId,
  );

  // Folder documentations/ memakai order_id sebagai pemilik key (PRD Bagian 22).
  const key = buildKey('documentations', orderId, image.ext);
  await putImage(env, 'private', key, image);

  let created;
  try {
    created = await insertDocumentationRow(env, {
      orderId,
      orderItemId,
      type: fields.type,
      imageKey: key,
      uploadedBy: ctx.user.id,
    });
  } catch (err) {
    await deleteObject(env, 'private', key).catch(() => undefined);
    throw err;
  }

  if (previous.length > 0) {
    // Gagal membersihkan foto lama tidak boleh menggagalkan unggahan baru.
    try {
      await deleteDocumentationRows(
        env,
        previous.map((doc) => doc.id as string),
      );
      for (const doc of previous) {
        await deleteObject(env, 'private', doc.image_url as string).catch(() => undefined);
      }
    } catch (err) {
      console.error('orders: gagal membersihkan foto lama', err);
    }
  }

  await logActivity(env, {
    userId: ctx.user.id,
    action: 'documentation_upload',
    entity: 'order',
    entityId: orderId,
    metadata: { type: fields.type, order_item_id: orderItemId, replaced: previous.length },
  });

  return {
    id: created.id,
    type: created.type,
    order_item_id: created.order_item_id,
    image_url: created.image_url,
  };
}

export async function deleteDocumentation(
  env: Bindings,
  ctx: AuthContextUser,
  orderId: string,
  docId: string,
): Promise<void> {
  const access = await resolveAccess(env, ctx);
  requireStaff(access);

  const row = await loadVisibleOrder(env, access, orderId);
  if (!isUuid(docId)) throw new AppError(404, 'not_found', 'Foto tidak ditemukan');

  const doc = await getDocumentationRow(env, docId);
  if (!doc || doc.order_id !== orderId) {
    throw new AppError(404, 'not_found', 'Foto tidak ditemukan');
  }

  const info = flowInfoFromRow(row);
  // Aturan hapus sama dengan aturan unggah: jendela status dan hak akses yang sama.
  if (!canUploadDocumentation(info, access.viewer, doc.type)) {
    throw uploadDenied(info, access, doc.type);
  }

  await deleteDocumentationRows(env, [doc.id]);
  await deleteObject(env, 'private', doc.image_url).catch((err) =>
    console.error('orders: gagal menghapus objek foto', err),
  );

  await logActivity(env, {
    userId: ctx.user.id,
    action: 'documentation_delete',
    entity: 'order',
    entityId: orderId,
    metadata: { type: doc.type, order_item_id: doc.order_item_id },
  });
}
