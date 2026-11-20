import type { Bindings } from '../../shared/types/env';

/**
 * Klien FCM HTTP v1 minimal tanpa SDK Firebase: service account ditukar jadi
 * access token OAuth2 (JWT RS256), lalu satu request per pesan. Kredensial
 * hanya ada di backend (secret Cloudflare Workers), tidak pernah ke Flutter.
 */

interface FcmConfig {
  projectId: string;
  clientEmail: string;
  privateKey: string;
}

export interface PushMessage {
  title: string;
  body: string;
  data?: Record<string, string>;
}

interface CachedToken {
  key: string;
  value: string;
  expiresAt: number;
}

let tokenCache: CachedToken | null = null;

/** Sama dengan `PushService.channelId` di Flutter. */
const ANDROID_CHANNEL_ID = 'rijiki_default';

export function getFcmConfig(env: Bindings): FcmConfig | null {
  const projectId = env.FIREBASE_PROJECT_ID?.trim();
  const clientEmail = env.FIREBASE_CLIENT_EMAIL?.trim();
  // Secret di Cloudflare sering disimpan dengan \n literal.
  const privateKey = env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n').trim();
  if (!projectId || !clientEmail || !privateKey) return null;
  return { projectId, clientEmail, privateKey };
}

function base64Url(bytes: Uint8Array): string {
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function base64UrlOfJson(value: unknown): string {
  return base64Url(new TextEncoder().encode(JSON.stringify(value)));
}

function pemToPkcs8(pem: string): Uint8Array {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '');
  const binary = atob(body);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

async function signJwt(config: FcmConfig): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const unsigned = `${base64UrlOfJson({ alg: 'RS256', typ: 'JWT' })}.${base64UrlOfJson({
    iss: config.clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  })}`;

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToPkcs8(config.privateKey),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsigned),
  );
  return `${unsigned}.${base64Url(new Uint8Array(signature))}`;
}

async function getAccessToken(config: FcmConfig): Promise<string> {
  const cacheKey = `${config.projectId}:${config.clientEmail}`;
  if (tokenCache && tokenCache.key === cacheKey && tokenCache.expiresAt > Date.now() + 60_000) {
    return tokenCache.value;
  }

  const assertion = await signJwt(config);
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  const payload = (await response.json().catch(() => ({}))) as {
    access_token?: string;
    expires_in?: number;
    error_description?: string;
  };

  if (!response.ok || !payload.access_token) {
    throw new Error(
      `FCM: gagal menukar service account (${payload.error_description ?? response.status})`,
    );
  }

  tokenCache = {
    key: cacheKey,
    value: payload.access_token,
    expiresAt: Date.now() + (payload.expires_in ?? 3600) * 1000,
  };
  return payload.access_token;
}

/**
 * Mengirim pesan ke banyak token. Mengembalikan token yang sudah tidak valid
 * agar pemanggil bisa menghapusnya; penghapusan dilakukan pemanggil dengan
 * `await` karena Worker membatalkan promise yang menggantung setelah respons.
 */
export async function sendPush(
  env: Bindings,
  tokens: string[],
  message: PushMessage,
): Promise<string[]> {
  const config = getFcmConfig(env);
  if (!config) {
    if (tokens.length > 0) {
      console.warn(
        'notifications: push dilewati, FIREBASE_PROJECT_ID/FIREBASE_CLIENT_EMAIL/FIREBASE_PRIVATE_KEY belum diset',
      );
    }
    return [];
  }

  let accessToken: string;
  try {
    accessToken = await getAccessToken(config);
  } catch (err) {
    console.error('notifications: push dilewati,', err instanceof Error ? err.message : err);
    return [];
  }

  const endpoint = `https://fcm.googleapis.com/v1/projects/${config.projectId}/messages:send`;
  const stale: string[] = [];

  await Promise.all(
    tokens.map(async (token) => {
      try {
        const response = await fetch(endpoint, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title: message.title, body: message.body },
              data: message.data,
              android: {
                priority: 'high',
                // Kanal & ikon harus sama dengan yang dibuat aplikasi
                // (PushService + AndroidManifest), agar notifikasi tampil
                // sebagai heads-up walau aplikasi tertutup.
                notification: {
                  channel_id: ANDROID_CHANNEL_ID,
                  icon: 'ic_notification',
                  color: '#2EB4F2',
                  sound: 'default',
                },
              },
            },
          }),
        });

        if (response.ok) return;

        const text = await response.text();
        // Token tidak valid lagi: laporkan agar pemanggil menghapusnya.
        if (text.includes('UNREGISTERED') || text.includes('INVALID_ARGUMENT')) {
          stale.push(token);
          return;
        }
        console.error('notifications: FCM menolak pesan', response.status, text);
      } catch (err) {
        console.error('notifications: push gagal', err instanceof Error ? err.message : err);
      }
    }),
  );

  return stale;
}
