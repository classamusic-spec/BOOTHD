// Private object storage for delivered images (PD-04, AC-0908): two
// private buckets, one for finished photos (`final/...`) and one for MMS
// previews (`preview/...`). Keys come from the delivery id, never from a
// phone number. Nothing here is ever public: images reach the provider and
// guests only through this service, behind a checked grant.

/** Bytes backed by an ordinary ArrayBuffer (what fetch and Response take). */
export type Bytes = Uint8Array<ArrayBuffer>;

export interface StoredObject {
  bytes: Bytes;
  contentType: string;
}

export interface ObjectStore {
  put(key: string, bytes: Bytes, contentType: string): Promise<void>;
  /** The object, or null if there is none. Throws if storage fails. */
  get(key: string): Promise<StoredObject | null>;
  /** Removes the object; an object already gone is not an error. */
  delete(key: string): Promise<void>;
}

/** In memory, for tests and local runs. */
export class MemoryObjectStore implements ObjectStore {
  readonly objects = new Map<string, StoredObject>();
  failing = false;

  put(key: string, bytes: Bytes, contentType: string): Promise<void> {
    if (this.failing) return Promise.reject(new Error('storage unavailable'));
    this.objects.set(key, { bytes: bytes.slice(), contentType });
    return Promise.resolve();
  }

  get(key: string): Promise<StoredObject | null> {
    if (this.failing) return Promise.reject(new Error('storage unavailable'));
    return Promise.resolve(this.objects.get(key) ?? null);
  }

  delete(key: string): Promise<void> {
    if (this.failing) return Promise.reject(new Error('storage unavailable'));
    this.objects.delete(key);
    return Promise.resolve();
  }
}

const buckets: Record<string, string> = {
  final: 'delivery-final',
  preview: 'delivery-preview',
};

/**
 * Supabase Storage through its REST API with the service role key (kept in
 * the function's secret store). Buckets are private. A delivery's keys
 * are fixed by its id, so a re-declared upload replaces its own object.
 */
export class SupabaseObjectStore implements ObjectStore {
  constructor(
    private readonly url: string,
    private readonly serviceRoleKey: string,
    private readonly fetcher: typeof fetch = fetch,
  ) {}

  private locate(key: string): { bucket: string; path: string } {
    const [area, ...rest] = key.split('/');
    const bucket = buckets[area];
    const path = rest.join('/');
    if (!bucket || !/^[0-9a-f-]{36}\.(jpg|png)$/.test(path)) {
      throw new Error('invalid object key');
    }
    return { bucket, path };
  }

  private headers(extra: Record<string, string> = {}): Record<string, string> {
    return {
      authorization: `Bearer ${this.serviceRoleKey}`,
      apikey: this.serviceRoleKey,
      ...extra,
    };
  }

  async put(key: string, bytes: Bytes, contentType: string): Promise<void> {
    const { bucket, path } = this.locate(key);
    const response = await this.fetcher(`${this.url}/storage/v1/object/${bucket}/${path}`, {
      method: 'POST',
      headers: this.headers({ 'content-type': contentType, 'x-upsert': 'true' }),
      body: bytes,
      signal: AbortSignal.timeout(30_000),
    });
    await response.body?.cancel();
    if (!response.ok) throw new Error(`storage put failed: ${response.status}`);
  }

  async get(key: string): Promise<StoredObject | null> {
    const { bucket, path } = this.locate(key);
    const response = await this.fetcher(`${this.url}/storage/v1/object/${bucket}/${path}`, {
      headers: this.headers(),
      signal: AbortSignal.timeout(30_000),
    });
    if (response.status === 404 || response.status === 400) {
      await response.body?.cancel();
      return null;
    }
    if (!response.ok) {
      await response.body?.cancel();
      throw new Error(`storage get failed: ${response.status}`);
    }
    return {
      bytes: new Uint8Array(await response.arrayBuffer()),
      contentType: response.headers.get('content-type') ?? 'application/octet-stream',
    };
  }

  async delete(key: string): Promise<void> {
    const { bucket, path } = this.locate(key);
    const response = await this.fetcher(`${this.url}/storage/v1/object/${bucket}`, {
      method: 'DELETE',
      headers: this.headers({ 'content-type': 'application/json' }),
      body: JSON.stringify({ prefixes: [path] }),
      signal: AbortSignal.timeout(30_000),
    });
    await response.body?.cancel();
    if (!response.ok && response.status !== 404) {
      throw new Error(`storage delete failed: ${response.status}`);
    }
  }
}
