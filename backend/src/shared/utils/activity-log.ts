import { getSupabaseAdmin } from '../../config/supabase';
import type { Bindings } from '../types/env';

export interface ActivityLogInput {
  userId: string | null;
  /** Contoh: order_claim, order_assign, order_status_change, documentation_upload. */
  action: string;
  /** Nama entitas yang diubah, mis. 'order'. */
  entity: string;
  entityId?: string | null;
  metadata?: Record<string, unknown>;
}

/**
 * Mencatat aktivitas ke activity_logs. Sengaja tidak pernah melempar error:
 * kegagalan log tidak boleh menggagalkan aksi utama yang sudah berhasil.
 */
export async function logActivity(env: Bindings, input: ActivityLogInput): Promise<void> {
  try {
    const { error } = await getSupabaseAdmin(env)
      .from('activity_logs')
      .insert({
        user_id: input.userId,
        action: input.action,
        entity: input.entity,
        entity_id: input.entityId ?? null,
        metadata: input.metadata ?? null,
      });
    if (error) console.error('activity-log: gagal menyimpan', input.action, error.message);
  } catch (err) {
    console.error('activity-log: error tak terduga', input.action, err);
  }
}
