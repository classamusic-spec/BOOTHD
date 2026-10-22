// Chromium smoke test of the web build (ADR-0018). Serve build/web first
// (node tool/web/serve.mjs), then:
//   NODE_PATH=$(npm root -g) node tool/web/smoke.mjs [url] [outDir]
// Chromium runs with a fake camera. Prints the browser console and saves
// screenshots; exits non-zero on a page error or a failed step.
import { mkdir } from 'node:fs/promises';
import { createRequire } from 'node:module';

// Playwright is installed globally (NODE_PATH), which ES imports ignore.
const { chromium } = createRequire(import.meta.url)('playwright');

const url = process.argv[2] ?? 'http://localhost:8787/';
const out = process.argv[3] ?? 'build/web_smoke';
await mkdir(out, { recursive: true });

const browser = await chromium.launch({
  executablePath: process.env.CHROMIUM ?? undefined,
  args: [
    '--use-fake-ui-for-media-stream',
    '--use-fake-device-for-media-stream',
    '--enable-unsafe-swiftshader',
  ],
});
const context = await browser.newContext({
  viewport: { width: 1180, height: 820 },
  permissions: ['camera'],
  locale: 'en-US',
});
const page = await context.newPage();
const errors = [];
page.on('console', (m) => console.log(`[console.${m.type()}] ${m.text()}`));
page.on('pageerror', (e) => {
  errors.push(e);
  console.log(`[pageerror] ${e}`);
});

async function shot(name) {
  await page.screenshot({ path: `${out}/${name}.png` });
  console.log(`screenshot ${out}/${name}.png`);
}

await page.goto(url, { waitUntil: 'load' });
await page.waitForTimeout(12000);
await shot('01-launch');
await page.waitForTimeout(30000);
await shot('02-later');
await page.reload({ waitUntil: 'load' });
await page.waitForTimeout(15000);
await shot('03-reload');
console.log(
  'isolated:',
  await page.evaluate(() => globalThis.crossOriginIsolated),
);
await browser.close();
if (errors.length) process.exit(1);
