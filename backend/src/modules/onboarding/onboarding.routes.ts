import { Hono } from 'hono';
import type { AppEnv } from '../../shared/types/env';
import { authMiddleware } from '../../middleware/auth';
import { validateBody } from '../../middleware/validate';
import { CompleteOnboardingSchema } from './onboarding.schema';
import { completeOnboardingHandler } from './onboarding.controller';

export const onboardingRoutes = new Hono<AppEnv>();

onboardingRoutes.patch(
  '/',
  authMiddleware,
  validateBody(CompleteOnboardingSchema),
  completeOnboardingHandler,
);