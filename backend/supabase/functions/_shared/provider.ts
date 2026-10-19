// The messaging provider (Twilio Programmable Messaging), server side only
// (AC-0911): the booth never holds these credentials.
//
// Every send has one of four outcomes, and the dispatcher treats each
// differently (AC-0915):
// - accepted: the provider created the message (not delivered);
// - rejected: the provider refused it for good (it will not be sent);
// - retryable: it certainly did not reach the provider (safe to retry);
// - ambiguous: it may have been created (a timeout or a server error after
//   the request left): never retried blindly; reconciled, then reviewed.

export interface SendRequest {
  to: string;
  body: string;
  mediaUrl: string;
  statusCallback: string;
}

export type SendOutcome =
  | { kind: 'accepted'; sid: string; status: string }
  | { kind: 'rejected'; code: string; providerCode: string | null }
  | { kind: 'retryable'; code: string; retryAfterSeconds: number | null }
  | { kind: 'ambiguous'; code: string };

export interface ProviderMessage {
  sid: string;
  status: string;
  body: string;
  createdAt: Date | null;
}

export type MediaCleanup = 'none' | 'deleted' | 'not_supported' | 'failed';

export interface MessagingProvider {
  send(request: SendRequest): Promise<SendOutcome>;
  /**
   * Messages sent to [to] since [since], to find a submission whose
   * outcome is unknown; null when the provider could not be asked.
   */
  findSent(to: string, since: Date): Promise<ProviderMessage[] | null>;
  /** Deletes the provider's stored copy of the message's media. */
  deleteMedia(sid: string): Promise<MediaCleanup>;
}

/** Provider error codes after which the message will never be sent. */
const permanentCodes: Record<string, string> = {
  '21211': 'PROVIDER_INVALID_NUMBER',
  '21408': 'PROVIDER_REGION_NOT_ENABLED',
  '21606': 'PROVIDER_SENDER_NOT_CAPABLE',
  '21610': 'RECIPIENT_OPTED_OUT',
  '21612': 'PROVIDER_UNREACHABLE_NUMBER',
  '21614': 'PROVIDER_NOT_MOBILE',
  '21620': 'PROVIDER_MEDIA_INVALID',
  '30007': 'PROVIDER_FILTERED',
};

const sidPattern = /^[A-Z]{2}[0-9a-f]{32}$/;

/** Twilio's REST API over `fetch` (the request shapes Twilio documents). */
export class TwilioRestProvider implements MessagingProvider {
  constructor(
    private readonly config: {
      accountSid: string;
      apiKeySid: string;
      apiKeySecret: string;
      messagingServiceSid: string;
      apiBase: string;
    },
    private readonly fetcher: typeof fetch = fetch,
    private readonly timeoutMs = 10_000,
  ) {}

  private get account(): string {
    return `${this.config.apiBase}/2010-04-01/Accounts/${this.config.accountSid}`;
  }

  private get auth(): string {
    return `Basic ${btoa(`${this.config.apiKeySid}:${this.config.apiKeySecret}`)}`;
  }

  async send(request: SendRequest): Promise<SendOutcome> {
    const form = new URLSearchParams({
      To: request.to,
      MessagingServiceSid: this.config.messagingServiceSid,
      Body: request.body,
      MediaUrl: request.mediaUrl,
      StatusCallback: request.statusCallback,
    });
    let response: Response;
    try {
      response = await this.fetcher(`${this.account}/Messages.json`, {
        method: 'POST',
        headers: {
          authorization: this.auth,
          'content-type': 'application/x-www-form-urlencoded',
        },
        body: form,
        signal: AbortSignal.timeout(this.timeoutMs),
      });
    } catch (error) {
      // Refused or unresolvable before anything was sent: safe to retry.
      // Anything else (a timeout, a reset) may have reached the provider.
      const cause = error instanceof Error ? error.cause : undefined;
      const message = [
        error instanceof Error ? error.message : String(error),
        cause instanceof Error ? cause.message : String(cause ?? ''),
      ].join(' ');
      if (/client error \(Connect\)|dns error|connection refused/i.test(message)) {
        return { kind: 'retryable', code: 'PROVIDER_UNREACHABLE', retryAfterSeconds: null };
      }
      return { kind: 'ambiguous', code: 'PROVIDER_SUBMIT_AMBIGUOUS' };
    }
    let payload: Record<string, unknown> = {};
    try {
      payload = await response.json();
    } catch {
      // Handled by status below.
    }
    if (response.status === 201 || response.status === 200) {
      const sid = String(payload.sid ?? '');
      if (!sidPattern.test(sid)) return { kind: 'ambiguous', code: 'PROVIDER_RESPONSE_INVALID' };
      return { kind: 'accepted', sid, status: String(payload.status ?? 'accepted') };
    }
    const providerCode = payload.code === undefined ? null : String(payload.code);
    if (response.status === 429 || providerCode === '20429') {
      const retryAfter = Number(response.headers.get('retry-after'));
      return {
        kind: 'retryable',
        code: 'PROVIDER_RATE_LIMITED',
        retryAfterSeconds: Number.isFinite(retryAfter) && retryAfter > 0 ? retryAfter : null,
      };
    }
    if (response.status === 401 || response.status === 403) {
      // Credentials or account trouble: nothing was created; an operator
      // must fix it, and the job waits within its window.
      return { kind: 'retryable', code: 'PROVIDER_AUTH_FAILED', retryAfterSeconds: 900 };
    }
    if (response.status >= 400 && response.status < 500) {
      return {
        kind: 'rejected',
        code: (providerCode && permanentCodes[providerCode]) ?? 'PROVIDER_REJECTED',
        providerCode,
      };
    }
    // 5xx: the provider may or may not have created the message.
    return { kind: 'ambiguous', code: 'PROVIDER_SERVER_ERROR' };
  }

  async findSent(to: string, since: Date): Promise<ProviderMessage[] | null> {
    const day = since.toISOString().slice(0, 10);
    const query = new URLSearchParams({ To: to, 'DateSent>': day, PageSize: '50' });
    try {
      const response = await this.fetcher(`${this.account}/Messages.json?${query}`, {
        headers: { authorization: this.auth },
        signal: AbortSignal.timeout(this.timeoutMs),
      });
      if (!response.ok) {
        await response.body?.cancel();
        return null;
      }
      const payload = await response.json() as { messages?: Array<Record<string, unknown>> };
      return (payload.messages ?? []).map((message) => ({
        sid: String(message.sid ?? ''),
        status: String(message.status ?? ''),
        body: String(message.body ?? ''),
        createdAt: typeof message.date_created === 'string' ? new Date(message.date_created) : null,
      })).filter((message) =>
        sidPattern.test(message.sid) && (!message.createdAt || message.createdAt >= since)
      );
    } catch {
      return null;
    }
  }

  async deleteMedia(sid: string): Promise<MediaCleanup> {
    if (!sidPattern.test(sid)) return 'none';
    try {
      const list = await this.fetcher(`${this.account}/Messages/${sid}/Media.json`, {
        headers: { authorization: this.auth },
        signal: AbortSignal.timeout(this.timeoutMs),
      });
      if (list.status === 404) {
        await list.body?.cancel();
        return 'none';
      }
      if (!list.ok) {
        await list.body?.cancel();
        return 'failed';
      }
      const payload = await list.json() as { media_list?: Array<Record<string, unknown>> };
      const media = (payload.media_list ?? []).map((item) => String(item.sid ?? ''))
        .filter((mediaSid) => sidPattern.test(mediaSid));
      if (media.length === 0) return 'none';
      for (const mediaSid of media) {
        const removed = await this.fetcher(
          `${this.account}/Messages/${sid}/Media/${mediaSid}.json`,
          {
            method: 'DELETE',
            headers: { authorization: this.auth },
            signal: AbortSignal.timeout(this.timeoutMs),
          },
        );
        await removed.body?.cancel();
        if (!removed.ok && removed.status !== 404) return 'failed';
      }
      return 'deleted';
    } catch {
      return 'failed';
    }
  }
}

/** When no provider is configured: nothing can be sent or looked up. */
export class UnconfiguredProvider implements MessagingProvider {
  send(): Promise<SendOutcome> {
    return Promise.resolve({
      kind: 'retryable',
      code: 'PROVIDER_NOT_CONFIGURED',
      retryAfterSeconds: 900,
    });
  }

  findSent(): Promise<ProviderMessage[] | null> {
    return Promise.resolve(null);
  }

  deleteMedia(): Promise<MediaCleanup> {
    return Promise.resolve('not_supported');
  }
}
