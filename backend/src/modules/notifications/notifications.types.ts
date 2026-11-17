import type { ListNotificationsQuery } from './notifications.schema';

export interface NotificationView {
  id: string;
  type: string;
  title: string;
  body: string;
  /** Data tambahan untuk navigasi, mis. { order_id }. */
  data: Record<string, unknown> | null;
  read: boolean;
  created_at: string;
}

export interface NotificationListPage {
  items: NotificationView[];
  page: number;
  limit: number;
  total: number;
  unread: number;
}

export interface NotificationListResult {
  items: NotificationView[];
  total: number;
  unread: number;
}

export type NotificationQuery = ListNotificationsQuery;

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type NotificationRow = Record<string, any>;
