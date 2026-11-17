export interface MyShoeView {
  /** order_items.id */
  id: string;
  order_id: string;
  order_number: string;
  order_status: string;
  service_name: string | null;
  shoe_brand: string | null;
  quantity: number;
  item_code: string;
  notes: string | null;
  /** Tanggal selesai order (atau tanggal order bila belum selesai). */
  order_date: string;
}

export interface CustomerRatingView {
  id: string;
  order_id: string;
  order_number: string | null;
  worker_name: string | null;
  rating_value: number;
  comment: string | null;
  /** Key objek di bucket privat; dimuat lewat /api/media/private/*key. */
  photo_key: string | null;
  is_featured: boolean;
  created_at: string;
}
