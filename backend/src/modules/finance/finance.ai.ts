import { z } from 'zod';
import type { Bindings } from '../../shared/types/env';
import { toNumber, toNumberOrNull } from '../../shared/utils/number';
import type { ExpenseType } from './finance.types';

/**
 * Satu antarmuka untuk penyedia AI: apa pun yang kompatibel [OI]
 * `/v1/chat/completions` (InferHub, [OI], Groq, ...) dipakai lewat
 * `AI_BASE_URL` + `AI_MODEL`, jadi penyedia bisa diganti tanpa menyentuh
 * modul finance (PRD Open Questions #23).
 */

/** Ambang keyakinan: di bawah ini item wajib diperiksa pengguna (PRD 15.1). */
export const CONFIDENCE_THRESHOLD = 0.7;

/** Batas waktu satu panggilan AI; PRD meminta hasil di bawah sekitar 15 detik. */
const AI_TIMEOUT_MS = 20_000;

const DEFAULT_BASE_URL = 'https://api.inferhub.dev';
const DEFAULT_MODEL = 'cb/deepseek-v4.1-flash';

export interface AiConfig {
  apiKey: string;
  baseUrl: string;
  model: string;
}

export function getAiConfig(env: Bindings): AiConfig | null {
  const apiKey = env.AI_API_KEY?.trim();
  if (!apiKey) return null;
  return {
    apiKey,
    baseUrl: (env.AI_BASE_URL?.trim() || DEFAULT_BASE_URL).replace(/\/+$/, ''),
    model: env.AI_MODEL?.trim() || DEFAULT_MODEL,
  };
}

const EXPENSE_TYPES = ['material', 'equipment', 'external_service', 'other'] as const;

const itemSchema = z.object({
  expense_type: z.enum(EXPENSE_TYPES).catch('other'),
  item_name: z.string().catch(''),
  quantity: z.number().nullable().catch(null),
  unit: z.string().nullable().catch(null),
  amount: z.number().catch(0),
  vendor_name: z.string().nullable().catch(null),
  confidence: z.number().catch(0),
});

const responseSchema = z.object({
  items: z.array(itemSchema).catch([]),
  receipt_total: z.number().nullable().catch(null),
  transaction_date: z.string().nullable().catch(null),
});

export interface ParsedExpenseItem {
  expenseType: ExpenseType;
  itemName: string;
  amount: number;
  quantity: number | null;
  unit: string | null;
  vendorName: string | null;
  confidence: number;
  needsReview: boolean;
}

export interface ParsedExpense {
  items: ParsedExpenseItem[];
  receiptTotal: number | null;
  transactionDate: string | null;
}

const SYSTEM_PROMPT = [
  'Kamu asisten pencatatan keuangan untuk jasa cuci sepatu Rijiki.',
  'Tugasmu memecah teks dan/atau foto nota pengeluaran menjadi item pengeluaran terstruktur.',
  'Aturan:',
  '- Kelompokkan setiap barang/jasa menjadi satu item. Satu nota berisi barang berbeda tipe dipecah jadi beberapa item.',
  '- expense_type hanya salah satu: material (bahan habis pakai: sabun, cairan pembersih, pewangi, kain lap),',
  '  equipment (alat dipakai berulang: sikat, mesin, rak, perlengkapan kurir),',
  '  external_service (jasa pihak lain: servis alat, tukang),',
  '  other (listrik, sewa, gaji, ongkir/BBM, atau yang tidak jelas).',
  '- amount adalah total rupiah untuk item itu sebagai angka utuh tanpa titik/koma (contoh "45rb" -> 45000, "2,5 juta" -> 2500000).',
  '- quantity angka (boleh null), unit satuan singkat (botol, pcs, biji, kg, ...).',
  '- vendor_name nama toko/penyedia bila disebut atau terlihat di nota.',
  '- confidence 0..1 seberapa yakin klasifikasi dan nominalmu.',
  '- transaction_date tanggal nota dalam format YYYY-MM-DD; null bila tidak ada di input.',
  '- receipt_total total yang tertulis di nota (angka utuh), null bila tidak ada.',
  'Balas HANYA JSON valid dengan bentuk:',
  '{"items":[{"expense_type":"material","item_name":"Sabun","quantity":2,"unit":"botol","amount":45000,"vendor_name":"Toko Maju","confidence":0.9}],"receipt_total":45000,"transaction_date":"2026-11-18"}',
  'Tanpa penjelasan, tanpa blok kode.',
].join('\n');

function isDateString(value: string): boolean {
  return /^\d{4}-\d{2}-\d{2}$/.test(value) && !Number.isNaN(Date.parse(`${value}T00:00:00Z`));
}

/** Ambil objek JSON dari balasan model walau dibungkus teks atau blok kode. */
function extractJson(content: string): unknown {
  const fenced = /```(?:json)?\s*([\s\S]*?)```/i.exec(content);
  const candidate = fenced?.[1] ?? content;
  const start = candidate.indexOf('{');
  const end = candidate.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  try {
    return JSON.parse(candidate.slice(start, end + 1));
  } catch {
    return null;
  }
}

type ContentPart =
  | { type: 'text'; text: string }
  | { type: 'image_url'; image_url: { url: string } };

/**
 * Memanggil model dan mengubah balasannya menjadi item draft. Galat apa pun
 * (jaringan, timeout, JSON rusak) dilempar ke pemanggil; service yang memutuskan
 * fallback "tercatat tanpa klasifikasi" (PRD 15.1).
 */
export async function parseExpenseWithAi(
  config: AiConfig,
  params: { text: string | null; imageBase64: string | null; imageMime: string | null },
): Promise<ParsedExpense> {
  const today = new Date(Date.now() + 7 * 60 * 60 * 1000).toISOString().slice(0, 10);

  const parts: ContentPart[] = [];
  const intro = [
    `Tanggal hari ini: ${today} (WIB).`,
    params.text ? `Input teks dari pengguna: ${params.text}` : 'Tidak ada teks, baca dari foto nota.',
  ].join('\n');
  parts.push({ type: 'text', text: intro });
  if (params.imageBase64 && params.imageMime) {
    parts.push({
      type: 'image_url',
      image_url: { url: `data:${params.imageMime};base64,${params.imageBase64}` },
    });
  }

  const response = await fetch(`${config.baseUrl}/v1/chat/completions`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${config.apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: config.model,
      temperature: 0,
      max_tokens: 1500,
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: parts },
      ],
    }),
    signal: AbortSignal.timeout(AI_TIMEOUT_MS),
  });

  if (!response.ok) {
    const detail = await response.text().catch(() => '');
    throw new Error(`AI menolak permintaan (${response.status}): ${detail.slice(0, 200)}`);
  }

  const payload = (await response.json()) as {
    choices?: Array<{ message?: { content?: unknown } }>;
  };
  const content = payload.choices?.[0]?.message?.content;
  if (typeof content !== 'string') throw new Error('AI tidak mengembalikan konten');

  const parsed = responseSchema.safeParse(extractJson(content));
  if (!parsed.success) throw new Error('Balasan AI bukan JSON yang diharapkan');

  const items: ParsedExpenseItem[] = parsed.data.items.map((item) => {
    const confidence = Math.min(Math.max(toNumber(item.confidence, 0), 0), 1);
    return {
      expenseType: item.expense_type,
      itemName: item.item_name.trim() || 'Pengeluaran',
      amount: Math.max(0, Math.round(toNumber(item.amount, 0))),
      quantity: toNumberOrNull(item.quantity),
      unit: item.unit?.trim() || null,
      vendorName: item.vendor_name?.trim() || null,
      confidence,
      needsReview: confidence < CONFIDENCE_THRESHOLD,
    };
  });

  const receiptTotal = toNumberOrNull(parsed.data.receipt_total);
  const transactionDate = parsed.data.transaction_date;
  return {
    items,
    receiptTotal,
    transactionDate: transactionDate && isDateString(transactionDate) ? transactionDate : null,
  };
}
