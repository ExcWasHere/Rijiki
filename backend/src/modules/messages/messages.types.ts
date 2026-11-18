export type MessageSenderRole = 'customer' | 'worker' | 'owner';

export interface MessageRow {
  id: string;
  order_id: string;
  sender_id: string;
  sender_role: MessageSenderRole;
  body: string;
  created_at: string;
}

/** Satu pesan seperti yang dikirim ke Flutter; `mine` dihitung per pemanggil. */
export interface MessageView {
  id: string;
  order_id: string;
  sender_id: string;
  sender_role: MessageSenderRole;
  body: string;
  created_at: string;
  mine: boolean;
}

export interface ThreadView {
  items: MessageView[];
  /** Pesan dari lawan bicara yang belum dibaca pemanggil. */
  unread: number;
}
