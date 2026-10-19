// The guest's download page (S33, UX-PD4, AC-0910, AC-0919): a small,
// self-contained mobile page under the guest's bearer link. No scripts,
// no fonts or images from anywhere else, no analytics, no indexing, no
// referrer. Expired, revoked, deleted and unavailable links get honest
// pages that say nothing about the guest, the event or other sessions.

import type { Deps } from './context.ts';
import { baseHeaders } from './http.ts';
import { addressKey, limit } from './limits.ts';
import { grantFor } from './media.ts';
import { ApiError } from './http.ts';
import type { TenantRow } from './auth.ts';

const pageHeaders = {
  ...baseHeaders,
  'content-type': 'text/html; charset=utf-8',
  'content-security-policy': "default-src 'none'; img-src 'self'; style-src 'unsafe-inline'; " +
    "form-action 'none'; frame-ancestors 'none'; base-uri 'none'",
  'cache-control': 'private, no-store, max-age=0',
};

export function escapeHtml(text: string): string {
  return text.replace(
    /[&<>"']/g,
    (char) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[char]!,
  );
}

const styles = `
:root { color-scheme: light; --ivory: #f7f2ea; --card: #fffdf9; --ink: #2b2724;
  --muted: #5f5750; --gold: #8a6a2f; --gold-soft: #e9dcc3; --line: #e4d9c8; }
* { box-sizing: border-box; }
body { margin: 0; background: var(--ivory); color: var(--ink);
  font: 17px/1.5 -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; }
main { max-width: 560px; margin: 0 auto; padding: 28px 18px 40px; }
.brand { text-align: center; font: 600 15px/1.2 Georgia, "Times New Roman", serif;
  letter-spacing: .14em; text-transform: uppercase; color: var(--gold); margin: 0 0 18px; }
h1 { font: 600 30px/1.15 Georgia, "Times New Roman", serif; text-align: center; margin: 0 0 22px; }
.print { background: var(--card); padding: 14px; border-radius: 6px;
  box-shadow: 0 12px 30px rgba(60, 44, 20, .14), 0 1px 0 rgba(255, 255, 255, .8) inset; }
.print img { display: block; width: 100%; height: auto; border-radius: 2px; }
.button { display: block; margin: 26px 0 10px; padding: 16px 20px; min-height: 52px;
  text-align: center; text-decoration: none; font-weight: 600; font-size: 18px; color: #fffdf9;
  background: linear-gradient(#a3813f, #7d5f27); border-radius: 30px;
  box-shadow: 0 6px 16px rgba(125, 95, 39, .35); }
.button:focus-visible { outline: 3px solid var(--ink); outline-offset: 3px; }
.until { text-align: center; color: var(--muted); margin: 0 0 26px; }
.note { background: var(--card); border: 1px solid var(--line); border-radius: 14px;
  padding: 14px 16px; color: var(--muted); font-size: 15px; }
.note p { margin: 0 0 8px; } .note p:last-child { margin: 0; }
a { color: var(--gold); }
footer { margin-top: 26px; text-align: center; color: var(--muted); font-size: 14px; }
.notice { text-align: center; padding-top: 12vh; }
.notice p { color: var(--muted); }
`;

function document(title: string, body: string): string {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow, noarchive">
<meta name="referrer" content="no-referrer">
<title>${escapeHtml(title)}</title>
<style>${styles}</style>
</head>
<body><main>${body}</main></body>
</html>`;
}

function formatUntil(date: Date): string {
  return new Intl.DateTimeFormat('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
    timeZone: 'UTC',
  }).format(date);
}

function notice(status: number, title: string, message: string): Response {
  const body = `<div class="notice"><h1>${escapeHtml(title)}</h1>
<p>${escapeHtml(message)}</p></div>`;
  return new Response(document(title, body), { status, headers: pageHeaders });
}

const notices = {
  unknown: [404, 'Link not found', 'This link isn’t valid. Check that the whole link was copied.'],
  expired: [
    410,
    'This link has expired',
    'These photos are no longer available here. Links last a limited time.',
  ],
  revoked: [410, 'This link was turned off', 'The photo booth operator turned this link off.'],
  deleted: [410, 'These photos were deleted', 'The photos for this link have been deleted.'],
  used_up: [410, 'This link has been used up', 'This link has been opened the most times allowed.'],
  unavailable: [
    503,
    'Temporarily unavailable',
    'We couldn’t load these photos just now. Please try again in a few minutes.',
  ],
  busy: [
    429,
    'Please wait a moment',
    'Too many requests from this network. Please try again in a few minutes.',
  ],
} as const;

export function noticePage(kind: keyof typeof notices): Response {
  const [status, title, message] = notices[kind];
  return notice(status, title, message);
}

async function guard(deps: Deps, request: Request): Promise<Response | null> {
  try {
    await limit(deps, `page:${await addressKey(deps, request)}`, 600, 120, 'PAGE_RATE_LIMITED');
    return null;
  } catch (error) {
    if (error instanceof ApiError && error.status === 429) return noticePage('busy');
    throw error;
  }
}

/** GET /p/{token} */
export async function downloadPage(deps: Deps, token: string, request: Request): Promise<Response> {
  const busy = await guard(deps, request);
  if (busy) return busy;
  const found = await grantFor(deps, token, 'download');
  if (!found.ok) return noticePage(found.reason);
  const { job, grant } = found;
  const [tenant] = await deps.sql<TenantRow[]>`select * from tenants where id = ${job.tenant_id}`;
  const until = formatUntil(grant.expires_at);
  const body = `
<p class="brand">${escapeHtml(tenant.brand_name)}</p>
<h1>Your photos from ${escapeHtml(job.event_name)}</h1>
<div class="print"><img src="${token}/preview.jpg" width="${job.preview_width}" height="${job.preview_height}"
  alt="Your finished photo from ${escapeHtml(job.event_name)}"></div>
<a class="button" href="${token}/download">Download full quality</a>
<p class="until">Available until ${escapeHtml(until)} (UTC)</p>
<div class="note">
<p>Anyone who has this link can see and download these photos until it expires. Forwarding the link shares them.</p>
<p>The booth operator can turn the link off at any time. Texts and photos already saved on phones can’t be recalled.</p>
<p><a href="${escapeHtml(tenant.privacy_url)}" rel="noreferrer noopener">Privacy</a> ·
<a href="${escapeHtml(tenant.terms_url)}" rel="noreferrer noopener">Terms</a> ·
Help: ${escapeHtml(tenant.support_contact)}</p>
</div>
<footer>${escapeHtml(tenant.brand_name)} · Porcelain Photo Booth</footer>`;
  return new Response(document(`Your photos from ${job.event_name}`, body), {
    status: 200,
    headers: pageHeaders,
  });
}

/** GET /p/{token}/preview.jpg and /p/{token}/download */
export async function downloadFile(
  deps: Deps,
  token: string,
  which: 'preview' | 'final',
  request: Request,
): Promise<Response> {
  const busy = await guard(deps, request);
  if (busy) return busy;
  const found = await grantFor(deps, token, 'download');
  if (!found.ok) return noticePage(found.reason);
  const { job, grant } = found;
  const key = which === 'final' ? job.final_key : job.preview_key;
  if (!key) return noticePage('deleted');
  let object;
  try {
    object = await deps.store.get(key);
  } catch {
    return noticePage('unavailable');
  }
  if (!object) return noticePage('deleted');
  const png = key.endsWith('.png');
  const name = `${
    job.event_name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '') || 'photos'
  }`;
  const headers: Record<string, string> = {
    ...baseHeaders,
    'content-type': png ? 'image/png' : 'image/jpeg',
    'content-length': String(object.bytes.length),
    'cache-control': 'private, no-store, max-age=0',
  };
  if (which === 'final') {
    await deps.sql`update access_grants set access_count = access_count + 1 where id = ${grant.id}`;
    headers['content-disposition'] = `attachment; filename="${name.slice(0, 40)}-photo.${
      png ? 'png' : 'jpg'
    }"`;
    deps.log.info('download.served', { job: job.id });
  } else {
    headers['content-disposition'] = 'inline';
  }
  return new Response(object.bytes, { status: 200, headers });
}
