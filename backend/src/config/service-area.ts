export const SERVICE_AREA = {
  minLat: -8.5,
  maxLat: -7.7,
  minLng: 112.25,
  maxLng: 113.0,
} as const;

export const OUT_OF_AREA_MESSAGE =
  'Lokasi kamu berada di luar area layanan Rijiki (Kota Malang, Kabupaten Malang, dan Kota Batu), maaf yah :(';

export function isInServiceArea(lat: number, lng: number): boolean {
  return (
    Number.isFinite(lat) &&
    Number.isFinite(lng) &&
    lat >= SERVICE_AREA.minLat &&
    lat <= SERVICE_AREA.maxLat &&
    lng >= SERVICE_AREA.minLng &&
    lng <= SERVICE_AREA.maxLng
  );
}
