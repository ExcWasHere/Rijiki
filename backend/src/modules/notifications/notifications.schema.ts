import { z } from 'zod';

export const listNotificationsQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

export type ListNotificationsQuery = z.infer<typeof listNotificationsQuerySchema>;

export const deviceTokenSchema = z.object({
  token: z.string().trim().min(20, 'Token perangkat tidak valid').max(4096),
  platform: z.enum(['android', 'ios']),
});

export type DeviceTokenInput = z.infer<typeof deviceTokenSchema>;

export const deleteDeviceTokenSchema = z.object({
  token: z.string().trim().min(1, 'Token perangkat wajib diisi').max(4096),
});

export type DeleteDeviceTokenInput = z.infer<typeof deleteDeviceTokenSchema>;
