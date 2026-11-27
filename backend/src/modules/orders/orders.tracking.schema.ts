import { z } from 'zod';

export const trackingPointSchema = z.object({
  latitude: z.number().min(-90, 'Latitude tidak valid').max(90, 'Latitude tidak valid'),
  longitude: z.number().min(-180, 'Longitude tidak valid').max(180, 'Longitude tidak valid'),
});

export type TrackingPointInput = z.infer<typeof trackingPointSchema>;
