// Structured, redacted logging (AC-0918). Log lines carry event names,
// codes, ids and counts only. As a second line of defence every string is
// scrubbed of anything shaped like a phone number or a bearer token before
// it is written, so a mistake elsewhere cannot leak one.

export type LogFields = Record<string, string | number | boolean | null | undefined>;

export type LogSink = (line: string) => void;

// A number never starts or ends inside a word or an identifier.
const phoneLike = /(?<![0-9A-Za-z])\+?\(?\d[\d ().-]{8,}\d(?![0-9A-Za-z])/g;
// Tokens are 43 base64url characters; UUIDs (36) are left readable.
const tokenLike = /[A-Za-z0-9_-]{40,}/g;
// UUIDs are ids support needs, and their digit groups can look like phone
// numbers: they are set aside while the rest is redacted.
const uuidLike = /\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/gi;

/** [text] with phone numbers and tokens replaced; UUIDs kept. */
export function redact(text: string): string {
  const ids: string[] = [];
  return text
    .replace(uuidLike, (id) => `\uE000${ids.push(id) - 1}\uE001`)
    .replace(tokenLike, '[redacted]')
    .replace(phoneLike, '[redacted]')
    .replace(/\uE000(\d+)\uE001/g, (_, index: string) => ids[Number(index)]);
}

export class Logger {
  constructor(private readonly sink: LogSink = (line) => console.log(line)) {}

  info(event: string, fields: LogFields = {}): void {
    this.write('info', event, fields);
  }

  warn(event: string, fields: LogFields = {}): void {
    this.write('warn', event, fields);
  }

  error(event: string, fields: LogFields = {}): void {
    this.write('error', event, fields);
  }

  private write(level: string, event: string, fields: LogFields): void {
    const clean: Record<string, string | number | boolean | null> = {};
    for (const [key, value] of Object.entries(fields)) {
      if (value === undefined) continue;
      clean[key] = typeof value === 'string' ? redact(value) : value;
    }
    this.sink(JSON.stringify({ level, event: redact(event), ...clean }));
  }
}
