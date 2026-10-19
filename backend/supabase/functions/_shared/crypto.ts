// Tokens, hashes and encryption for phone delivery (ADR-0015).
//
// Web Crypto only, so the same code runs in Supabase Edge Functions (Deno)
// and in the Node test suite. Bearer tokens carry 256 bits of randomness
// and are stored only as SHA-256 hashes; phone numbers are encrypted with
// AES-256-GCM under a key from the secret store and indexed by a keyed
// HMAC-SHA-256 digest, so the database never holds a number in the clear.

const encoder = new TextEncoder();
const decoder = new TextDecoder();

/** `bytes` as lowercase hex. */
export function hex(bytes: Uint8Array): string {
  let out = '';
  for (const byte of bytes) out += byte.toString(16).padStart(2, '0');
  return out;
}

/** `bytes` as unpadded base64url. */
export function base64Url(bytes: Uint8Array): string {
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/, '');
}

export function fromBase64Url(text: string): Uint8Array<ArrayBuffer> {
  const padded = text.replaceAll('-', '+').replaceAll('_', '/') +
    '='.repeat((4 - (text.length % 4)) % 4);
  const binary = atob(padded);
  const out = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) out[i] = binary.charCodeAt(i);
  return out;
}

/** A bearer token with `bytes` random bytes (32: 256 bits). */
export function randomToken(bytes = 32): string {
  return base64Url(crypto.getRandomValues(new Uint8Array(bytes)));
}

/** SHA-256 of `text` (UTF-8) as lowercase hex: how tokens are stored. */
export async function sha256Hex(text: string | Uint8Array<ArrayBuffer>): Promise<string> {
  const data = typeof text === 'string' ? encoder.encode(text) : text;
  return hex(new Uint8Array(await crypto.subtle.digest('SHA-256', data)));
}

/** Compares two strings in time independent of where they differ. */
export function constantTimeEqual(a: string, b: string): boolean {
  const left = encoder.encode(a);
  const right = encoder.encode(b);
  let diff = left.length ^ right.length;
  const length = Math.max(left.length, right.length);
  for (let i = 0; i < length; i++) diff |= (left[i] ?? 0) ^ (right[i] ?? 0);
  return diff === 0;
}

function hmacKey(secret: string): Promise<CryptoKey> {
  return crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
}

/** Keyed digest of a phone number, for suppression and throttles. */
export async function recipientDigest(secret: string, e164: string): Promise<string> {
  const key = await hmacKey(secret);
  return hex(new Uint8Array(await crypto.subtle.sign('HMAC', key, encoder.encode(e164))));
}

function aesKey(keyBase64Url: string): Promise<CryptoKey> {
  const raw = fromBase64Url(keyBase64Url);
  if (raw.length !== 32) throw new Error('DELIVERY_PHONE_KEY must be 32 bytes');
  return crypto.subtle.importKey('raw', raw, { name: 'AES-GCM' }, false, [
    'encrypt',
    'decrypt',
  ]);
}

/** AES-256-GCM encryption of `plain`: `v1.<iv>.<ciphertext>`. */
export async function encryptText(keyBase64Url: string, plain: string): Promise<string> {
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const sealed = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv },
    await aesKey(keyBase64Url),
    encoder.encode(plain),
  );
  return `v1.${base64Url(iv)}.${base64Url(new Uint8Array(sealed))}`;
}

export async function decryptText(keyBase64Url: string, sealed: string): Promise<string> {
  const [version, iv, data] = sealed.split('.');
  if (version !== 'v1' || !iv || !data) throw new Error('unknown ciphertext');
  const plain = await crypto.subtle.decrypt(
    { name: 'AES-GCM', iv: fromBase64Url(iv) },
    await aesKey(keyBase64Url),
    fromBase64Url(data),
  );
  return decoder.decode(plain);
}
