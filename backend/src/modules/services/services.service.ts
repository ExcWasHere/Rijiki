import type { Bindings } from '../../shared/types/env';
import { listActiveServices } from './services.repo';
import type { ServiceView } from './services.types';

export async function getActiveServices(env: Bindings): Promise<{ items: ServiceView[] }> {
  const items = await listActiveServices(env);
  return { items };
}
