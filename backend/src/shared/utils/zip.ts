/**
 * Penulis ZIP streaming tanpa dependensi (metode "stored", tanpa kompresi:
 * foto JPG/PNG/WebP sudah terkompresi). Tiap entri langsung ditulis ke stream
 * lalu dilepas dari memori, jadi memori yang dipakai kira-kira satu entri saja,
 * bukan seluruh arsip. Tanpa ZIP64: maksimum 65.535 entri dan 4 GB.
 */

export interface ZipEntryInput {
  /** Path di dalam arsip, pemisah "/". Boleh memuat huruf non-ASCII (UTF-8). */
  name: string;
  data: Uint8Array;
  modified?: Date;
}

interface CentralRecord {
  nameBytes: Uint8Array;
  crc: number;
  size: number;
  time: number;
  date: number;
  offset: number;
}

const encoder = new TextEncoder();

const CRC_TABLE: Uint32Array = (() => {
  const table = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    table[n] = c >>> 0;
  }
  return table;
})();

export function crc32(data: Uint8Array): number {
  let c = 0xffffffff;
  for (let i = 0; i < data.length; i++) {
    c = CRC_TABLE[(c ^ data[i]!) & 0xff]! ^ (c >>> 8);
  }
  return (c ^ 0xffffffff) >>> 0;
}

function dosDateTime(value: Date): { time: number; date: number } {
  const year = Math.max(value.getUTCFullYear(), 1980);
  return {
    time: (value.getUTCHours() << 11) | (value.getUTCMinutes() << 5) | (value.getUTCSeconds() >> 1),
    date: ((year - 1980) << 9) | ((value.getUTCMonth() + 1) << 5) | value.getUTCDate(),
  };
}

const UTF8_FLAG = 0x0800;

function localHeader(record: CentralRecord): Uint8Array {
  const out = new Uint8Array(30 + record.nameBytes.length);
  const view = new DataView(out.buffer);
  view.setUint32(0, 0x04034b50, true);
  view.setUint16(4, 20, true); // versi minimum
  view.setUint16(6, UTF8_FLAG, true);
  view.setUint16(8, 0, true); // stored
  view.setUint16(10, record.time, true);
  view.setUint16(12, record.date, true);
  view.setUint32(14, record.crc, true);
  view.setUint32(18, record.size, true);
  view.setUint32(22, record.size, true);
  view.setUint16(26, record.nameBytes.length, true);
  view.setUint16(28, 0, true);
  out.set(record.nameBytes, 30);
  return out;
}

function centralDirectory(records: CentralRecord[], directoryOffset: number): Uint8Array {
  let size = 22;
  for (const r of records) size += 46 + r.nameBytes.length;
  const out = new Uint8Array(size);
  const view = new DataView(out.buffer);

  let pos = 0;
  for (const r of records) {
    view.setUint32(pos, 0x02014b50, true);
    view.setUint16(pos + 4, 20, true); // dibuat dengan versi
    view.setUint16(pos + 6, 20, true); // versi minimum
    view.setUint16(pos + 8, UTF8_FLAG, true);
    view.setUint16(pos + 10, 0, true);
    view.setUint16(pos + 12, r.time, true);
    view.setUint16(pos + 14, r.date, true);
    view.setUint32(pos + 16, r.crc, true);
    view.setUint32(pos + 20, r.size, true);
    view.setUint32(pos + 24, r.size, true);
    view.setUint16(pos + 28, r.nameBytes.length, true);
    view.setUint16(pos + 30, 0, true); // extra
    view.setUint16(pos + 32, 0, true); // komentar
    view.setUint16(pos + 34, 0, true); // nomor disk
    view.setUint16(pos + 36, 0, true); // atribut internal
    view.setUint32(pos + 38, 0, true); // atribut eksternal
    view.setUint32(pos + 42, r.offset, true);
    out.set(r.nameBytes, pos + 46);
    pos += 46 + r.nameBytes.length;
  }

  const directorySize = pos;
  view.setUint32(pos, 0x06054b50, true);
  view.setUint16(pos + 4, 0, true);
  view.setUint16(pos + 6, 0, true);
  view.setUint16(pos + 8, records.length, true);
  view.setUint16(pos + 10, records.length, true);
  view.setUint32(pos + 12, directorySize, true);
  view.setUint32(pos + 16, directoryOffset, true);
  view.setUint16(pos + 20, 0, true);
  return out;
}

/**
 * Membuat ReadableStream ZIP dari urutan entri. Entri diambil satu per satu
 * hanya saat konsumen siap (backpressure), jadi sumber boleh generator async
 * yang mengunduh tiap foto saat dibutuhkan.
 */
export function zipStream(source: AsyncIterable<ZipEntryInput>): ReadableStream<Uint8Array> {
  const iterator = source[Symbol.asyncIterator]();
  const records: CentralRecord[] = [];
  let offset = 0;
  let finished = false;

  return new ReadableStream<Uint8Array>({
    async pull(controller) {
      if (finished) return;
      try {
        const next = await iterator.next();
        if (next.done) {
          finished = true;
          controller.enqueue(centralDirectory(records, offset));
          controller.close();
          return;
        }

        const entry = next.value;
        const stamp = dosDateTime(entry.modified ?? new Date());
        const record: CentralRecord = {
          nameBytes: encoder.encode(entry.name),
          crc: crc32(entry.data),
          size: entry.data.length,
          time: stamp.time,
          date: stamp.date,
          offset,
        };
        const header = localHeader(record);
        controller.enqueue(header);
        controller.enqueue(entry.data);
        records.push(record);
        offset += header.length + entry.data.length;
      } catch (err) {
        finished = true;
        controller.error(err);
      }
    },
    async cancel() {
      finished = true;
      await iterator.return?.();
    },
  });
}

/** CSV UTF-8 dengan BOM (agar Excel membaca huruf non-ASCII) dan CRLF. */
export function toCsv(rows: Array<Array<string | number | null | undefined>>): string {
  const cell = (value: string | number | null | undefined): string => {
    const text = value === null || value === undefined ? '' : String(value);
    return /[",\r\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
  };
  return `\uFEFF${rows.map((row) => row.map(cell).join(',')).join('\r\n')}\r\n`;
}
