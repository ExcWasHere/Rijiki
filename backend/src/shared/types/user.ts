export type UserRole = 'customer' | 'worker' | 'owner';

export type AppPermission =
  | 'manage_orders_all'
  | 'manage_cms_services'
  | 'manage_cms_events'
  | 'manage_cms_promos'
  | 'manage_cms_merchandise'
  | 'manage_testimonials'
  | 'manage_finance'
  | 'manage_workers'
  | 'manage_points'
  | 'view_analytics';

export interface AppUser {
  id: string;
  email: string;
  role: UserRole;
  full_name: string | null;
  phone_number: string | null;
  avatar_url: string | null;
  profile_completed: boolean;
  is_active: boolean;
}

export interface AuthContextUser {
  user: AppUser;
  permissions: AppPermission[];
  ownerBypass: boolean;
}