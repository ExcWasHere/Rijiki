import { AppError } from '../../shared/errors';
import { getObject } from '../../shared/storage/r2';
import type { Bindings } from '../../shared/types/env';
import { logActivity } from '../../shared/utils/activity-log';
import { toCsv, zipStream } from '../../shared/utils/zip';
import type { ZipEntryInput } from '../../shared/utils/zip';
import { listExportDocumentations, listExportRatings } from './ratings.repo';
import type { ExportQuery } from './ratings.schema';
import { one, serviceNamesOf } from './ratings.service';
import type { RatingRow } from './ratings.types';

/**
 * Batas foto per rekap. ZIP ditulis streaming (satu foto dalam memori pada satu
 * waktu), jadi batas ini menjaga lama proses, bukan memori. Selebihnya tetap
 * tercantum di ringkasan.csv dengan status "melebihi batas".
 */
export const MAX_RECAP_PHOTOS = 200;
const DEFAULT_BEFORE_AFTER_DAYS = 30;

export interface RecapExport {
  stream: ReadableStream<Uint8Array>;
  filename: string;
  /** Jumlah foto yang seharusnya masuk rekap. */
  total: number;
  /** Jumlah foto yang benar-benar dimasukkan (maksimal MAX_RECAP_PHOTOS). */
  included: number;
  truncated: boolean;
}

const encoder = new TextEncoder();

function safeSegment(value: unknown, fallback: string): string {
  const text = String(value ?? '').replace(/[^A-Za-z0-9._-]+/g, '_').replace(/^_+|_+$/g, '');
  return text.length > 0 ? text : fallback;
}

function extOf(key: string): string {
  const ext = key.split('.').pop()?.toLowerCase() ?? '';
  return /^[a-z0-9]{2,5}$/.test(ext) ? ext : 'jpg';
}

/** Tanggal (YYYY-MM-DD) dalam WIB untuk sebuah waktu ISO. */
function wibDay(value: Date | string): string {
  return new Date(new Date(value).getTime() + 7 * 60 * 60 * 1000).toISOString().slice(0, 10);
}

function todayWib(offsetDays = 0): string {
  return wibDay(new Date(Date.now() + offsetDays * 24 * 60 * 60 * 1000));
}

async function readPhoto(env: Bindings, key: string): Promise<Uint8Array | null> {
  try {
    const object = await getObject(env, 'private', key);
    if (!object) return null;
    return new Uint8Array(await object.arrayBuffer());
  } catch (err) {
    console.error('ratings.export: gagal membaca foto', key, err);
    return null;
  }
}

function textOf(row: RatingRow): string {
  return String(row['order']?.order_number ?? '');
}

// ---------------------------------------------------------------------------
// Rekap testimoni customer: foto testimoni + ringkasan.csv
// ---------------------------------------------------------------------------

async function testimonialRecap(env: Bindings, query: ExportQuery): Promise<RecapExport> {
  const rows = await listExportRatings(env, query.start_date, query.end_date);
  if (rows.length === 0) {
    throw new AppError(404, 'export_empty', 'Belum ada rating pada rentang tanggal itu.');
  }

  const withPhoto = rows.filter((row) => row.photo_url).length;
  const included = Math.min(withPhoto, MAX_RECAP_PHOTOS);

  async function* entries(): AsyncGenerator<ZipEntryInput> {
    const files = new Map<string, { file: string; status: string }>();
    let photoNumber = 0;

    for (const row of rows) {
      const key = (row.photo_url as string | null) ?? null;
      if (!key) {
        files.set(row.id, { file: '', status: 'tanpa foto' });
        continue;
      }
      if (photoNumber >= MAX_RECAP_PHOTOS) {
        files.set(row.id, { file: '', status: 'melebihi batas rekap' });
        continue;
      }
      photoNumber += 1;

      const bytes = await readPhoto(env, key);
      if (!bytes) {
        files.set(row.id, { file: '', status: 'foto tidak ditemukan' });
        continue;
      }
      const name = `foto/${String(photoNumber).padStart(3, '0')}_${safeSegment(
        one(row.order)?.order_number,
        'order',
      )}_${row.rating_value}bintang.${extOf(key)}`;
      files.set(row.id, { file: name, status: 'disertakan' });
      yield { name, data: bytes, modified: new Date(row.created_at) };
    }

    const table: Array<Array<string | number>> = [
      ['no', 'tanggal', 'nomor_order', 'customer', 'rating', 'komentar', 'layanan', 'worker', 'file_foto', 'status_foto'],
    ];
    rows.forEach((row, index) => {
      const state = files.get(row.id) ?? { file: '', status: '' };
      table.push([
        index + 1,
        wibDay(row.created_at),
        String(one(row.order)?.order_number ?? ''),
        String(one(one(row.customer)?.users)?.full_name ?? ''),
        Number(row.rating_value),
        String(row.comment ?? ''),
        serviceNamesOf(one(row.order)).join(' + '),
        String(one(one(row.worker)?.users)?.full_name ?? ''),
        state.file,
        state.status,
      ]);
    });
    yield { name: 'ringkasan.csv', data: encoder.encode(toCsv(table)) };
  }

  return {
    stream: zipStream(entries()),
    filename: `rekap-testimoni-${todayWib()}.zip`,
    total: withPhoto,
    included,
    truncated: withPhoto > MAX_RECAP_PHOTOS,
  };
}

// ---------------------------------------------------------------------------
// Rekap foto before/after: foto per order + ringkasan.csv
// Foto before/after dihapus otomatis 1 bulan setelah diunggah (retensi R2),
// jadi rekap harus dibuat sebelum itu.
// ---------------------------------------------------------------------------

async function beforeAfterRecap(env: Bindings, query: ExportQuery): Promise<RecapExport> {
  // Tanpa rentang tanggal: 30 hari terakhir (sesuai masa simpan foto).
  const start =
    query.start_date ?? (query.end_date ? undefined : todayWib(-DEFAULT_BEFORE_AFTER_DAYS));

  const raw = await listExportDocumentations(env, start, query.end_date);
  if (raw.length === 0) {
    throw new AppError(
      404,
      'export_empty',
      'Tidak ada foto before/after pada rentang tanggal itu. Foto dihapus otomatis 1 bulan setelah diunggah.',
    );
  }

  const rows = [...raw].sort((a, b) => {
    const byOrder = textOf(a).localeCompare(textOf(b));
    if (byOrder !== 0) return byOrder;
    const byItem = String(one(a.item)?.item_code ?? '').localeCompare(
      String(one(b.item)?.item_code ?? ''),
    );
    if (byItem !== 0) return byItem;
    return (a.type === 'before' ? 0 : 1) - (b.type === 'before' ? 0 : 1);
  });
  const included = Math.min(rows.length, MAX_RECAP_PHOTOS);

  async function* entries(): AsyncGenerator<ZipEntryInput> {
    const table: Array<Array<string | number>> = [
      ['nomor_order', 'kode_item', 'merk_sepatu', 'layanan', 'jenis_foto', 'tanggal_unggah', 'file_foto', 'status_foto'],
    ];

    let photoNumber = 0;
    for (const row of rows) {
      const order = one(row.order);
      const item = one(row.item);
      const itemCode = String(item?.item_code ?? '');
      const type = String(row.type);
      const key = String(row.image_url ?? '');
      const base = [
        String(order?.order_number ?? ''),
        itemCode,
        String(item?.shoe_brand ?? ''),
        String(one(item?.services)?.name ?? ''),
        type === 'before' ? 'sebelum' : 'sesudah',
        wibDay(row.created_at),
      ];

      if (photoNumber >= MAX_RECAP_PHOTOS) {
        table.push([...base, '', 'melebihi batas rekap']);
        continue;
      }
      photoNumber += 1;

      const bytes = key ? await readPhoto(env, key) : null;
      if (!bytes) {
        table.push([...base, '', 'foto sudah dihapus atau tidak ditemukan']);
        continue;
      }
      const name = `${safeSegment(order?.order_number, 'order')}/${safeSegment(
        itemCode,
        'item',
      )}_${type}.${extOf(key)}`;
      table.push([...base, name, 'disertakan']);
      yield { name, data: bytes, modified: new Date(row.created_at) };
    }

    yield { name: 'ringkasan.csv', data: encoder.encode(toCsv(table)) };
  }

  return {
    stream: zipStream(entries()),
    filename: `rekap-before-after-${todayWib()}.zip`,
    total: rows.length,
    included,
    truncated: rows.length > MAX_RECAP_PHOTOS,
  };
}

export async function buildRecap(
  env: Bindings,
  userId: string,
  query: ExportQuery,
): Promise<RecapExport> {
  const recap =
    query.source === 'testimonials'
      ? await testimonialRecap(env, query)
      : await beforeAfterRecap(env, query);

  await logActivity(env, {
    userId,
    action: 'testimonial_export',
    entity: 'rating',
    metadata: {
      source: query.source,
      start_date: query.start_date ?? null,
      end_date: query.end_date ?? null,
      total: recap.total,
      included: recap.included,
    },
  });
  return recap;
}
