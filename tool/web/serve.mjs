// Serves build/web locally with the same headers as vercel.json, for the
// Chromium smoke test (tool/web/smoke.mjs) and for trying the web build:
//   node tool/web/serve.mjs [port]
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { extname, join, normalize } from 'node:path';

const root = new URL('../../build/web/', import.meta.url).pathname;
const port = Number(process.argv[2] ?? 8787);
const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.woff2': 'font/woff2',
  '.bin': 'application/octet-stream',
  '.frag': 'application/octet-stream',
  '.mp3': 'audio/mpeg',
  '.wav': 'audio/wav',
};
const vercel = JSON.parse(
  await readFile(new URL('../../vercel.json', import.meta.url), 'utf8'),
);
const globalHeaders = vercel.headers.find((h) => h.source === '/(.*)').headers;

createServer(async (req, res) => {
  const path = normalize(decodeURIComponent(new URL(req.url, 'http://x').pathname));
  let file = join(root, path);
  if (!file.startsWith(root)) {
    res.writeHead(400).end();
    return;
  }
  try {
    if ((await stat(file)).isDirectory()) file = join(file, 'index.html');
  } catch {
    file = join(root, 'index.html'); // SPA rewrite, as vercel.json
  }
  try {
    const body = await readFile(file);
    const headers = { 'Content-Type': types[extname(file)] ?? 'application/octet-stream' };
    for (const { key, value } of globalHeaders) headers[key] = value;
    res.writeHead(200, headers).end(body);
  } catch {
    res.writeHead(404).end();
  }
}).listen(port, () => console.log(`http://localhost:${port}`));
