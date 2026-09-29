import { Hono } from 'hono';
import type { AppEnv } from '../../shared/types/env';
import { authMiddleware } from '../../middleware/auth';
import { validateBody } from '../../middleware/validate';
import {
  LoginSchema,
  RefreshSchema,
  RegisterSchema,
  UpdateMeSchema,
} from './auth.schema';
import {
  getMeHandler,
  loginHandler,
  logoutHandler,
  refreshHandler,
  registerHandler,
  updateMeHandler,
} from './auth.controller';

export const authRoutes = new Hono<AppEnv>();

authRoutes.post('/register', validateBody(RegisterSchema), registerHandler);
authRoutes.post('/login', validateBody(LoginSchema), loginHandler);
authRoutes.post('/refresh', validateBody(RefreshSchema), refreshHandler);
authRoutes.post('/logout', authMiddleware, logoutHandler);
authRoutes.get('/me', authMiddleware, getMeHandler);
authRoutes.patch('/me', authMiddleware, validateBody(UpdateMeSchema), updateMeHandler);