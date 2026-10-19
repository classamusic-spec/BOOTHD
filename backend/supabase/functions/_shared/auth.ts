// Booth identity (PD-03, AC-0907): an administrator issues a single-use
// pairing code; the booth exchanges it once for a credential (256 random
// bits, stored here only as a hash) and the credential for short-lived
// access tokens. Revoking the booth stops both at once. There is no shared
// app secret and no anonymous send path; administrators use their own
// token, held outside every booth.

import { addMinutes, type Deps } from './context.ts';
import { constantTimeEqual, randomToken, sha256Hex } from './crypto.ts';
import { ApiError, bearer, readJson, str } from './http.ts';
import { addressKey, limit } from './limits.ts';

export interface TenantRow {
  id: string;
  name: string;
  brand_name: string;
  privacy_url: string;
  terms_url: string;
  support_contact: string;
  sending_enabled: boolean;
  registration_attested_at: Date | null;
  registration_reference: string | null;
  legal_review_attested_at: Date | null;
  daily_send_limit: number;
  event_send_limit: number;
  monthly_budget_cents: number;
  estimated_cost_millicents: number;
  link_days_default: number;
  link_days_max: number;
  preview_max_bytes: number;
  created_at: Date;
}

export interface BoothRow {
  id: string;
  tenant_id: string;
  name: string;
  daily_send_limit: number;
  revoked_at: Date | null;
}

export interface AuthenticatedBooth {
  booth: BoothRow;
  tenant: TenantRow;
}

/** Crockford base32: no I, L, O or U to misread. */
const codeAlphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/** A pairing code of 12 characters (60 bits), shown as XXXX-XXXX-XXXX. */
export function newPairingCode(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(12));
  const chars = [...bytes].map((byte) => codeAlphabet[byte % 32]);
  return [chars.slice(0, 4), chars.slice(4, 8), chars.slice(8)].map((part) => part.join('')).join(
    '-',
  );
}

/** A typed code in canonical form (case, spaces, hyphens and look-alikes). */
export function normalizePairingCode(input: string): string {
  return input.toUpperCase().replace(/[\s-]/g, '').replace(/[IL]/g, '1').replace(/O/g, '0');
}

/** POST /v1/booths/pair: a pairing code for a booth credential. */
export async function pairBooth(deps: Deps, request: Request): Promise<Record<string, unknown>> {
  await limit(deps, `pair:${await addressKey(deps, request)}`, 600, 10, 'PAIRING_RATE_LIMITED');
  const body = await readJson(request);
  const code = normalizePairingCode(str(body, 'code', /^[0-9A-Za-z -]{12,20}$/));
  const name = str(body, 'boothName', /^.{1,40}$/).trim();
  if (!name || /\p{Cc}/u.test(name)) {
    throw new ApiError(400, 'FIELD_INVALID', { field: 'boothName' });
  }
  if (!/^[0-9A-Z]{12}$/.test(code)) throw new ApiError(400, 'PAIRING_CODE_INVALID');
  const codeHash = await sha256Hex(code);
  const credential = randomToken();
  const credentialHash = await sha256Hex(credential);
  const now = deps.now();
  const result = await deps.sql.begin(async (tx) => {
    const [pairing] = await tx<{ tenant_id: string; used_at: Date | null; expires_at: Date }[]>`
      select tenant_id, used_at, expires_at from pairing_codes
      where code_hash = ${codeHash} for update`;
    if (!pairing || pairing.used_at || pairing.expires_at <= now) return null;
    await tx`update pairing_codes set used_at = ${now} where code_hash = ${codeHash}`;
    const [booth] = await tx<{ id: string }[]>`
      insert into registered_booths (tenant_id, name, credential_hash, last_seen_at)
      values (${pairing.tenant_id}, ${name}, ${credentialHash}, ${now}) returning id`;
    const [tenant] = await tx<TenantRow[]>`select * from tenants where id = ${pairing.tenant_id}`;
    return { boothId: booth.id, tenant };
  });
  // One answer for unknown, used and expired codes.
  if (!result) throw new ApiError(400, 'PAIRING_CODE_INVALID');
  deps.log.info('booth.paired', { booth: result.boothId, tenant: result.tenant.id });
  return {
    boothId: result.boothId,
    boothName: name,
    credential,
    brandName: result.tenant.brand_name,
  };
}

/** POST /v1/booths/token: the booth's credential for an access token. */
export async function issueAccessToken(
  deps: Deps,
  request: Request,
): Promise<Record<string, unknown>> {
  const credential = bearer(request);
  if (!credential) throw new ApiError(401, 'CREDENTIAL_INVALID');
  const hash = await sha256Hex(credential);
  const now = deps.now();
  const [booth] = await deps.sql<BoothRow[]>`
    select id, tenant_id, name, daily_send_limit, revoked_at from registered_booths
    where (credential_hash = ${hash}
        or (previous_credential_hash = ${hash} and previous_valid_until > ${now}))
      and revoked_at is null`;
  if (!booth) throw new ApiError(401, 'CREDENTIAL_INVALID');
  await limit(deps, `token:${booth.id}`, 3600, 120, 'TOKEN_RATE_LIMITED');
  const token = randomToken();
  const expiresAt = addMinutes(now, deps.config.accessTokenMinutes);
  await deps.sql`insert into booth_access_tokens (token_hash, booth_id, expires_at)
    values (${await sha256Hex(token)}, ${booth.id}, ${expiresAt})`;
  await deps.sql`update registered_booths set last_seen_at = ${now} where id = ${booth.id}`;
  return { accessToken: token, expiresAt: expiresAt.toISOString(), boothId: booth.id };
}

/** The booth behind the request's access token, or a 401. */
export async function authenticateBooth(
  deps: Deps,
  request: Request,
): Promise<AuthenticatedBooth> {
  const token = bearer(request);
  if (!token) throw new ApiError(401, 'ACCESS_TOKEN_INVALID');
  const hash = await sha256Hex(token);
  const rows = await deps.sql<(BoothRow & { tenant: TenantRow })[]>`
    select b.id, b.tenant_id, b.name, b.daily_send_limit, b.revoked_at, row_to_json(t.*) as tenant
    from booth_access_tokens a
    join registered_booths b on b.id = a.booth_id
    join tenants t on t.id = b.tenant_id
    where a.token_hash = ${hash} and a.expires_at > ${deps.now()} and b.revoked_at is null`;
  const row = rows[0];
  if (!row) throw new ApiError(401, 'ACCESS_TOKEN_INVALID');
  const { tenant, ...booth } = row;
  return { booth, tenant: reviveTenant(tenant) };
}

/** row_to_json returns timestamps as strings. */
function reviveTenant(raw: TenantRow): TenantRow {
  const date = (value: unknown) => (value ? new Date(String(value)) : null);
  return {
    ...raw,
    registration_attested_at: date(raw.registration_attested_at),
    legal_review_attested_at: date(raw.legal_review_attested_at),
    created_at: date(raw.created_at)!,
  };
}

/**
 * POST /v1/booths/rotate: a new credential; the old one keeps working for
 * ten minutes in case the answer is lost on the way.
 */
export async function rotateCredential(
  deps: Deps,
  { booth }: AuthenticatedBooth,
): Promise<Record<string, unknown>> {
  const credential = randomToken();
  const now = deps.now();
  await deps.sql`update registered_booths set
      previous_credential_hash = credential_hash,
      previous_valid_until = ${addMinutes(now, 10)},
      credential_hash = ${await sha256Hex(credential)}
    where id = ${booth.id}`;
  deps.log.info('booth.rotated', { booth: booth.id });
  return { credential };
}

/** Administrator requests carry the administrator token (never a booth's). */
export async function authenticateAdmin(deps: Deps, request: Request): Promise<void> {
  const token = bearer(request);
  const hash = token ? await sha256Hex(token) : '';
  if (!token || !constantTimeEqual(hash, deps.config.adminTokenSha256)) {
    await limit(deps, `admin:${await addressKey(deps, request)}`, 600, 20, 'ADMIN_RATE_LIMITED');
    throw new ApiError(401, 'ADMIN_TOKEN_INVALID');
  }
}
