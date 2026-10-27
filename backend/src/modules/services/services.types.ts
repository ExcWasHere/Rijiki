export interface ServiceView {
  id: string;
  name: string;
  description: string | null;
  category: string | null;
  base_price: number;
  estimated_duration_minutes: number | null;
  is_active: boolean;
}
