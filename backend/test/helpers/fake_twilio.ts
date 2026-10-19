// A stand-in for Twilio's Messages API on a local port: it checks the
// request shapes the real API documents (account path, basic auth, form
// fields), keeps the messages it "created", fetches the media URL like
// Twilio does (HEAD, then GET) and can be told to fail in each way the
// dispatcher must handle. It never sends anything anywhere.

export type SendMode =
  | 'accept'
  | 'accept_sent'
  | 'rate_limit'
  | 'auth_error'
  | { reject: string }
  | 'server_error_created'
  | 'server_error_not_created'
  | 'hang_created';

export interface FakeMessage {
  sid: string;
  to: string;
  body: string;
  mediaUrl: string;
  statusCallback: string;
  status: string;
  createdAt: Date;
  media: { head?: number; get?: number; contentType?: string | null; bytes?: number };
}

export interface FakeTwilio {
  apiBase: string;
  accountSid: string;
  apiKeySid: string;
  apiKeySecret: string;
  messages: FakeMessage[];
  /** Modes for the next sends, in order; afterwards every send is accepted. */
  modes: SendMode[];
  requests: number;
  mediaDeletes: string[];
  listCalls: number;
  close(): Promise<void>;
}

function sidFor(prefix: string): string {
  const hex = [...crypto.getRandomValues(new Uint8Array(16))]
    .map((byte) => byte.toString(16).padStart(2, '0')).join('');
  return `${prefix}${hex}`;
}

export function startFakeTwilio(
  { fetchMedia = true, now = () => new Date() } = {},
): Promise<FakeTwilio> {
  const accountSid = sidFor('AC');
  const apiKeySid = sidFor('SK');
  const apiKeySecret = 'fake-api-key-secret';
  const state: Omit<FakeTwilio, 'apiBase' | 'close'> = {
    accountSid,
    apiKeySid,
    apiKeySecret,
    messages: [],
    modes: [],
    requests: 0,
    mediaDeletes: [],
    listCalls: 0,
  };
  const account = `/2010-04-01/Accounts/${accountSid}`;
  const authorized = (request: Request) =>
    request.headers.get('authorization') === `Basic ${btoa(`${apiKeySid}:${apiKeySecret}`)}`;
  const reply = (status: number, body: unknown) =>
    new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });

  return new Promise((resolve) => {
    const server = Deno.serve({
      hostname: '127.0.0.1',
      port: 0,
      onListen: ({ port }) => {
        resolve(Object.assign(state, {
          apiBase: `http://127.0.0.1:${port}`,
          close: () => server.shutdown(),
        }) as FakeTwilio);
      },
    }, async (request) => {
      const url = new URL(request.url);
      if (!authorized(request)) return reply(401, { code: 20003, message: 'Authenticate' });
      if (request.method === 'POST' && url.pathname === `${account}/Messages.json`) {
        state.requests++;
        const form = new URLSearchParams(await request.text());
        const required = ['To', 'MessagingServiceSid', 'Body', 'MediaUrl', 'StatusCallback'];
        if (required.some((key) => !form.get(key))) {
          return reply(400, { code: 21602, message: 'Missing parameter' });
        }
        const mode = state.modes.shift() ?? 'accept';
        const create = (status: string) => {
          const message: FakeMessage = {
            sid: sidFor('MM'),
            to: form.get('To')!,
            body: form.get('Body')!,
            mediaUrl: form.get('MediaUrl')!,
            statusCallback: form.get('StatusCallback')!,
            status,
            createdAt: now(),
            media: {},
          };
          state.messages.push(message);
          return message;
        };
        const fetchPreview = async (message: FakeMessage) => {
          if (!fetchMedia) return;
          const head = await fetch(message.mediaUrl, { method: 'HEAD' });
          await head.body?.cancel();
          const get = await fetch(message.mediaUrl);
          const bytes = new Uint8Array(await get.arrayBuffer());
          message.media = {
            head: head.status,
            get: get.status,
            contentType: get.headers.get('content-type'),
            bytes: bytes.length,
          };
        };
        if (mode === 'rate_limit') return reply(429, { code: 20429, message: 'Too Many Requests' });
        if (mode === 'auth_error') return reply(401, { code: 20003, message: 'Authenticate' });
        if (typeof mode === 'object') {
          return reply(400, { code: Number(mode.reject), message: 'Rejected' });
        }
        if (mode === 'server_error_not_created') return reply(500, { message: 'Internal' });
        const message = create(mode === 'accept_sent' ? 'sent' : 'accepted');
        await fetchPreview(message);
        if (mode === 'server_error_created') return reply(500, { message: 'Internal' });
        if (mode === 'hang_created') await new Promise((done) => setTimeout(done, 1500));
        return reply(201, { sid: message.sid, status: message.status });
      }
      if (request.method === 'GET' && url.pathname === `${account}/Messages.json`) {
        state.listCalls++;
        const to = url.searchParams.get('To');
        return reply(200, {
          messages: state.messages.filter((message) => message.to === to).map((message) => ({
            sid: message.sid,
            status: message.status,
            body: message.body,
            date_created: message.createdAt.toUTCString(),
          })),
        });
      }
      const media = new RegExp(
        `^${account}/Messages/(MM[0-9a-f]{32})/Media(?:/(ME[0-9a-f]{32}))?\\.json$`,
      )
        .exec(url.pathname);
      if (media && request.method === 'GET') {
        return reply(200, { media_list: [{ sid: `ME${media[1].slice(2)}` }] });
      }
      if (media && request.method === 'DELETE' && media[2]) {
        state.mediaDeletes.push(media[1]);
        return new Response(null, { status: 204 });
      }
      return reply(404, { code: 20404, message: 'Not found' });
    });
  });
}
