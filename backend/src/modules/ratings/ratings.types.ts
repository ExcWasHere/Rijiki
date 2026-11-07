/** Testimoni pilihan yang tampil di home customer (publik di dalam aplikasi). */
export interface FeaturedTestimonialView {
  id: string;
  /** Disamarkan: nama depan + inisial belakang, mis. "Rina A.". */
  customer_name: string;
  rating_value: number;
  service_name: string | null;
  comment: string | null;
  /** URL publik salinan featured; null bila rating tanpa foto. */
  photo_url: string | null;
  created_at: string;
}

/** Rating untuk staf (owner atau pemegang izin manage_testimonials). */
export interface ManagedRatingView {
  id: string;
  order_id: string;
  order_number: string | null;
  customer_name: string | null;
  worker_name: string | null;
  service_names: string[];
  rating_value: number;
  comment: string | null;
  /** Key objek di bucket privat; dimuat lewat /api/media/private/*key. */
  photo_key: string | null;
  is_featured: boolean;
  created_at: string;
}

export interface RatingSummaryView {
  total: number;
  average: number | null;
  featured: number;
}

export interface RatingCreatedView {
  id: string;
  order_id: string;
  rating_value: number;
  comment: string | null;
  photo_key: string | null;
  created_at: string;
  /** Poin yang baru diberikan karena rating ini (0 bila aturan nonaktif). */
  points_awarded: number;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type RatingRow = Record<string, any>;
