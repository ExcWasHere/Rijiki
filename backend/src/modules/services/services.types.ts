export interface ServiceView {
  id: string;
  name: string;
  description: string | null;
  category: string | null;
  base_price: number;
  estimated_duration_minutes: number | null;
  is_active: boolean;
}

/** Bentuk baris untuk INSERT/UPDATE; hanya field yang dikirim yang dipakai. */
export interface ServiceWrite {
  name?: string;
  description?: string | null;
  category?: string;
  base_price?: number;
  estimated_duration_minutes?: number | null;
  is_active?: boolean;
}
