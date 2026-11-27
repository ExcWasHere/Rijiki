export interface MerchandiseView {
  id: string;
  name: string;
  description: string | null;
  /** Harga referensi (merchandise tidak dijual lewat pemesanan). */
  price: number;
  /** Harga dalam poin; null = belum bisa ditukar. */
  points_cost: number | null;
  /** Stok; null = tidak dikelola. */
  stock_quantity: number | null;
  image_url: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface MerchandiseWrite {
  name: string;
  description: string | null;
  price: number;
  points_cost: number | null;
  stock_quantity: number | null;
  image_url: string | null;
  is_active: boolean;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type MerchandiseRow = Record<string, any>;
