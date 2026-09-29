import type { Context } from 'hono';
import type { AppEnv } from '../../shared/types/env';
import { ok } from '../../shared/utils/response';
import { completeOnboarding } from './onboarding.service';
import type { CompleteOnboardingInput } from './onboarding.schema';

export async function completeOnboardingHandler(c: Context<AppEnv>) {
  const ctx = c.get('user');
  const input = c.get('validatedBody') as CompleteOnboardingInput;
  const user = await completeOnboarding(c.env, ctx.user.id, input);
  return c.json(ok({ user }));
}