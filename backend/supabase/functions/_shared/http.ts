// HTTP helpers: errors with stable codes, JSON responses with security
// headers, and request bodies read with a hard size limit.

/** An error the client is told about: an HTTP status and a stable code. */
export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    readonly details: Record<string, unknown> = {},
  ) {
    super(code);
  }
}

/** Headers on every response: nothing is cached, framed or sniffed. */
export const baseHeaders: Record<string, string> = {
  'cache-control': 'no-store, max-age=0',
  'x-content-type-options': 'nosniff',
  'referrer-policy': 'no-referrer',
  'x-frame-options': 'DENY',
  'x-robots-tag': 'noindex, nofollow, noarchive',
  'strict-transport-security': 'max-age=31536000',
};

/**
 * Whether [path] is the booth API, the only part a browser page may call
 * across origins (ADR-0018): never the administrator API, Twilio's
 * webhooks or the guest pages.
 */
export function isBoothApi(path: string): boolean {
  return /^\/v1\/(booths|deliveries|uploads|delivery|diagnostics)(\/|$)/.test(path);
}

/** CORS headers for an allowed booth page; no cookies are ever allowed. */
export function corsHeaders(origin: string): Record<string, string> {
  return {
    'access-control-allow-origin': origin,
    'access-control-expose-headers': 'retry-after',
    vary: 'Origin',
  };
}

/** The answer to an allowed booth page's preflight request. */
export function preflight(origin: string): Response {
  return new Response(null, {
    status: 204,
    headers: {
      ...baseHeaders,
      ...corsHeaders(origin),
      'access-control-allow-methods': 'GET, POST, PUT',
      'access-control-allow-headers': 'authorization, content-type, accept',
      'access-control-max-age': '600',
    },
  });
}

export function json(
  status: number,
  body: unknown,
  headers: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...baseHeaders, 'content-type': 'application/json; charset=utf-8', ...headers },
  });
}

export function errorResponse(error: ApiError): Response {
  return json(error.status, { error: { code: error.code, ...error.details } });
}

/** The request body, at most [maxBytes]; larger bodies are refused (413). */
export async function readBody(
  request: Request,
  maxBytes: number,
): Promise<Uint8Array<ArrayBuffer>> {
  const declared = request.headers.get('content-length');
  if (declared !== null && Number(declared) > maxBytes) {
    throw new ApiError(413, 'BODY_TOO_LARGE', { maxBytes });
  }
  if (!request.body) return new Uint8Array(0);
  const reader = request.body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    total += value.byteLength;
    if (total > maxBytes) {
      await reader.cancel();
      throw new ApiError(413, 'BODY_TOO_LARGE', { maxBytes });
    }
    chunks.push(value);
  }
  const out = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    out.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return out;
}

/** A JSON object body of at most 16 KB. */
export async function readJson(request: Request): Promise<Record<string, unknown>> {
  const type = request.headers.get('content-type') ?? '';
  if (!type.toLowerCase().startsWith('application/json')) {
    throw new ApiError(415, 'JSON_REQUIRED');
  }
  const bytes = await readBody(request, 16 * 1024);
  let value: unknown;
  try {
    value = JSON.parse(new TextDecoder().decode(bytes));
  } catch {
    throw new ApiError(400, 'JSON_INVALID');
  }
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new ApiError(400, 'JSON_INVALID');
  }
  return value as Record<string, unknown>;
}

/** Form fields of a webhook (at most 32 KB), every value a string. */
export async function readForm(request: Request): Promise<Record<string, string>> {
  const type = request.headers.get('content-type') ?? '';
  if (!type.toLowerCase().startsWith('application/x-www-form-urlencoded')) {
    throw new ApiError(415, 'FORM_REQUIRED');
  }
  const text = new TextDecoder().decode(await readBody(request, 32 * 1024));
  const params: Record<string, string> = {};
  for (const [key, value] of new URLSearchParams(text)) params[key] = value;
  return params;
}

// Field readers that turn malformed input into a 400 with the field name.

export function str(body: Record<string, unknown>, key: string, pattern: RegExp): string {
  const value = body[key];
  if (typeof value !== 'string' || !pattern.test(value)) {
    throw new ApiError(400, 'FIELD_INVALID', { field: key });
  }
  return value;
}

export function int(body: Record<string, unknown>, key: string, min: number, max: number): number {
  const value = body[key];
  if (typeof value !== 'number' || !Number.isInteger(value) || value < min || value > max) {
    throw new ApiError(400, 'FIELD_INVALID', { field: key });
  }
  return value;
}

export function obj(body: Record<string, unknown>, key: string): Record<string, unknown> {
  const value = body[key];
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new ApiError(400, 'FIELD_INVALID', { field: key });
  }
  return value as Record<string, unknown>;
}

/** The bearer token of the `Authorization` header, if well formed. */
export function bearer(request: Request): string | null {
  const header = request.headers.get('authorization') ?? '';
  const match = /^Bearer ([A-Za-z0-9_-]{20,128})$/.exec(header);
  return match ? match[1] : null;
}

/**
 * The caller's address as the platform forwards it, for rate limits only
 * (they store a keyed hash of it, never the address).
 */
export function clientAddress(request: Request): string {
  const forwarded = request.headers.get('x-forwarded-for') ?? '';
  return forwarded.split(',')[0].trim() || request.headers.get('x-real-ip') || 'unknown';
}

export const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
export const tokenPattern = /^[A-Za-z0-9_-]{43}$/;
