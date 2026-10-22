// The delivery service's routes (backend/openapi/delivery-v1.yaml). One
// handler serves the booth API, the administrator API, Twilio's webhooks
// and preview fetches, and the guest's download page.

import * as admin from './admin.ts';
import {
  authenticateAdmin,
  authenticateBooth,
  issueAccessToken,
  pairBooth,
  rotateCredential,
} from './auth.ts';
import { capabilities, uploadTest } from './capabilities.ts';
import type { Deps } from './context.ts';
import * as deliveries from './deliveries.ts';
import {
  ApiError,
  baseHeaders,
  corsHeaders,
  errorResponse,
  isBoothApi,
  json,
  preflight,
} from './http.ts';
import { previewForProvider } from './media.ts';
import { downloadFile, downloadPage, noticePage } from './page.ts';
import { inboundWebhook, statusWebhook } from './webhooks.ts';

type Handler = (deps: Deps, request: Request, params: string[]) => Promise<Response>;

const routes: [string, RegExp, Handler][] = [];
const table: [string, string][] = [];

function route(method: string, pattern: string, handler: Handler) {
  const regex = new RegExp(`^${pattern.replace(/\{[a-z]+\}/g, '([^/]+)')}$`);
  routes.push([method, regex, handler]);
  table.push([method, pattern]);
}

/** Every route as [method, path pattern], for the contract test. */
export function routeTable(): [string, string][] {
  return [...table];
}

const ok = (status = 200) => (body: unknown) => json(status, body);

// Booth: pairing and tokens.
route('POST', '/v1/booths/pair', async (deps, request) => ok(201)(await pairBooth(deps, request)));
route(
  'POST',
  '/v1/booths/token',
  async (deps, request) => ok()(await issueAccessToken(deps, request)),
);
route(
  'POST',
  '/v1/booths/rotate',
  async (deps, request) =>
    ok()(await rotateCredential(deps, await authenticateBooth(deps, request))),
);

// Booth: deliveries.
route(
  'GET',
  '/v1/delivery/capabilities',
  async (deps, request) => ok()(await capabilities(deps, await authenticateBooth(deps, request))),
);
route('POST', '/v1/deliveries', async (deps, request) => {
  const result = await deliveries.createDelivery(
    deps,
    await authenticateBooth(deps, request),
    request,
  );
  return json(result.status, result.body);
});
route(
  'POST',
  '/v1/deliveries/{id}/upload-init',
  async (deps, request, [id]) =>
    ok()(await deliveries.initUpload(deps, await authenticateBooth(deps, request), id, request)),
);
route(
  'PUT',
  '/v1/uploads/{token}',
  async (deps, request, [token]) => ok(201)(await deliveries.receiveUpload(deps, token, request)),
);
route(
  'POST',
  '/v1/deliveries/{id}/commit',
  async (deps, request, [id]) =>
    ok()(await deliveries.commitDelivery(deps, await authenticateBooth(deps, request), id)),
);
route(
  'GET',
  '/v1/deliveries/{id}',
  async (deps, request, [id]) =>
    ok()(await deliveries.deliveryStatus(deps, await authenticateBooth(deps, request), id)),
);
route(
  'POST',
  '/v1/deliveries/{id}/cancel',
  async (deps, request, [id]) =>
    ok()(await deliveries.cancelDelivery(deps, await authenticateBooth(deps, request), id)),
);
route(
  'POST',
  '/v1/deliveries/{id}/revoke',
  async (deps, request, [id]) =>
    ok()(await deliveries.revokeDelivery(deps, await authenticateBooth(deps, request), id)),
);
route(
  'POST',
  '/v1/deliveries/{id}/resolve',
  async (deps, request, [id]) =>
    ok()(
      await deliveries.resolveDelivery(deps, await authenticateBooth(deps, request), id, request),
    ),
);
route(
  'POST',
  '/v1/diagnostics/upload-test',
  async (deps, request) =>
    ok()(await uploadTest(deps, await authenticateBooth(deps, request), request)),
);

// Administrator.
const asAdmin = (handler: Handler): Handler => async (deps, request, params) => {
  await authenticateAdmin(deps, request);
  return await handler(deps, request, params);
};
route(
  'POST',
  '/v1/admin/tenants',
  asAdmin(async (deps, request) => ok(201)(await admin.createTenant(deps, request))),
);
route(
  'PATCH',
  '/v1/admin/tenants/{id}',
  asAdmin(async (deps, request, [id]) => ok()(await admin.updateTenant(deps, id, request))),
);
route(
  'POST',
  '/v1/admin/tenants/{id}/attestations',
  asAdmin(async (deps, request, [id]) => ok()(await admin.attest(deps, id, request))),
);
route(
  'POST',
  '/v1/admin/tenants/{id}/pairing-codes',
  asAdmin(async (deps, _request, [id]) => ok(201)(await admin.issuePairingCode(deps, id))),
);
route(
  'POST',
  '/v1/admin/tenants/{id}/test-recipients',
  asAdmin(async (deps, request, [id]) => ok(201)(await admin.addTestRecipient(deps, id, request))),
);
route(
  'GET',
  '/v1/admin/tenants/{id}/summary',
  asAdmin(async (deps, _request, [id]) => ok()(await admin.tenantSummary(deps, id))),
);
route(
  'POST',
  '/v1/admin/booths/{id}/revoke',
  asAdmin(async (deps, _request, [id]) => ok()(await admin.revokeBooth(deps, id))),
);
route(
  'POST',
  '/v1/admin/suppressions',
  asAdmin(async (deps, request) => ok(201)(await admin.addSuppression(deps, request))),
);
route('POST', '/v1/admin/worker/run', asAdmin(async (deps) => ok()(await admin.runWorker(deps))));

// Twilio.
route('POST', '/webhooks/twilio/status', (deps, request) => statusWebhook(deps, request));
route('POST', '/webhooks/twilio/inbound', (deps, request) => inboundWebhook(deps, request));
route('GET', '/m/{token}', (deps, request, [token]) => previewForProvider(deps, token, request));
route('HEAD', '/m/{token}', (deps, request, [token]) => previewForProvider(deps, token, request));

// Guests.
route('GET', '/p/{token}', (deps, request, [token]) => downloadPage(deps, token, request));
route(
  'GET',
  '/p/{token}/preview.jpg',
  (deps, request, [token]) => downloadFile(deps, token, 'preview', request),
);
route(
  'GET',
  '/p/{token}/download',
  (deps, request, [token]) => downloadFile(deps, token, 'final', request),
);

route('GET', '/healthz', () => Promise.resolve(json(200, { ok: true })));
route('GET', '/robots.txt', () =>
  Promise.resolve(
    new Response('User-agent: *\nDisallow: /\n', {
      headers: { ...baseHeaders, 'content-type': 'text/plain; charset=utf-8' },
    }),
  ));

/** The request path without the platform's prefix (`/delivery/...`). */
export function routePath(pathname: string, prefixes: string[]): string {
  for (const prefix of prefixes) {
    if (pathname === prefix) return '/';
    if (pathname.startsWith(`${prefix}/`)) return pathname.slice(prefix.length);
  }
  return pathname;
}

export function createHandler(deps: Deps): (request: Request) => Promise<Response> {
  const respond = handle(deps);
  return async (request: Request) => {
    const path = routePath(new URL(request.url).pathname, deps.config.pathPrefixes);
    const origin = request.headers.get('origin');
    if (origin === null || !isBoothApi(path)) return await respond(request, path);
    // A browser booth page (ADR-0018): only the configured origins.
    const allowed = deps.config.boothOrigins.includes(origin);
    if (request.method === 'OPTIONS') {
      return allowed ? preflight(origin) : json(403, { error: { code: 'ORIGIN_NOT_ALLOWED' } });
    }
    const response = await respond(request, path);
    if (!allowed) return response;
    const headers = new Headers(response.headers);
    for (const [name, value] of Object.entries(corsHeaders(origin))) headers.set(name, value);
    return new Response(response.body, { status: response.status, headers });
  };
}

function handle(deps: Deps): (request: Request, path: string) => Promise<Response> {
  return async (request: Request, path: string) => {
    const guestPage = path.startsWith('/p/');
    try {
      let allowed: string[] = [];
      for (const [method, regex, handler] of routes) {
        const match = regex.exec(path);
        if (!match) continue;
        if (method !== request.method) {
          allowed.push(method);
          continue;
        }
        return await handler(deps, request, match.slice(1).map(decodeURIComponent));
      }
      allowed = [...new Set(allowed)];
      if (allowed.length > 0) {
        return json(405, { error: { code: 'METHOD_NOT_ALLOWED' } }, { allow: allowed.join(', ') });
      }
      return guestPage ? noticePage('unknown') : json(404, { error: { code: 'NOT_FOUND' } });
    } catch (error) {
      if (error instanceof ApiError) return errorResponse(error);
      // Never the error's text: it could hold a number or a token.
      deps.log.error('request.failed', {
        route: path.split('/').slice(0, 3).join('/'),
        kind: error instanceof Error ? error.name : 'unknown',
      });
      return guestPage ? noticePage('unavailable') : json(500, { error: { code: 'INTERNAL' } });
    }
  };
}
