/** SHA512(order_id + status_code + gross_amount + ServerKey), hex huruf kecil. */
export async function computeMidtransSignature(
  serverKey: string,
  payload: { order_id: string; status_code: string; gross_amount: string },
): Promise<string> {
  const data = new TextEncoder().encode(
    `${payload.order_id}${payload.status_code}${payload.gross_amount}${serverKey}`,
  );
  const digest = await crypto.subtle.digest('SHA-512', data);
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

export async function verifyMidtransSignature(
  serverKey: string,
  payload: { order_id: string; status_code: string; gross_amount: string; signature_key: string },
): Promise<boolean> {
  const expected = await computeMidtransSignature(serverKey, payload);
  return timingSafeEqual(expected, payload.signature_key.toLowerCase());
}
