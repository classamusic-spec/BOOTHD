// Chromium smoke test of the web build (ADR-0018). Serve build/web first
// (node tool/web/serve.mjs), then:
//   NODE_PATH=$(npm root -g) node tool/web/smoke.mjs [url] [outDir]
// Chromium runs with a fake camera. Prints the browser console and saves
// screenshots; asserts setup, reload, storage failure and recovery.
// Every check uses isolated browser storage, never the operator's profile.
import assert from 'node:assert/strict';
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

async function shot(name, target = page) {
  await target.screenshot({ path: `${out}/${name}.png` });
  console.log(`screenshot ${out}/${name}.png`);
}

async function enableAccessibility(target) {
  await target.locator('flt-semantics-placeholder').evaluate((el) => el.click());
}

try {
  page.setDefaultTimeout(30000);
  await page.goto(url, { waitUntil: 'load' });
  await enableAccessibility(page);
  await page.getByRole('button', { name: 'Begin setup', exact: true }).waitFor();
  assert.equal(await page.evaluate(() => globalThis.crossOriginIsolated), true);
  await shot('01-launch');
  await page.getByRole('button', { name: 'Begin setup', exact: true }).click();
  // The privacy point merges its title and body into one semantics node.
  await page.getByText('Stored in this browser', { exact: false }).waitFor();
  await shot('02-privacy');
  await page.reload({ waitUntil: 'load' });
  await enableAccessibility(page);
  await page.getByRole('button', { name: 'Begin setup', exact: true }).waitFor();
  await shot('03-reload');

  const blocked = await browser.newContext({ viewport: { width: 1180, height: 820 } });
  await blocked.addInitScript(() => {
    window.__boothBlockStorage = true;
    const original = IDBFactory.prototype.open;
    IDBFactory.prototype.open = function (...args) {
      if (window.__boothBlockStorage) throw new DOMException('Storage blocked', 'SecurityError');
      return original.apply(this, args);
    };
  });
  const recovery = await blocked.newPage();
  recovery.setDefaultTimeout(30000);
  recovery.on('pageerror', (error) => errors.push(error));
  await recovery.goto(url, { waitUntil: 'load' });
  await enableAccessibility(recovery);
  await recovery.getByText("The booth couldn't start", { exact: true }).waitFor();
  await shot('04-storage-unavailable', recovery);
  await recovery.evaluate(() => { window.__boothBlockStorage = false; });
  await recovery.getByRole('button', { name: 'Try again', exact: true }).click();
  await recovery.getByRole('button', { name: 'Begin setup', exact: true }).waitFor();
  await shot('05-storage-recovered', recovery);
  assert.equal(errors.length, 0, errors.map(String).join('\n'));
  console.log('PASS: setup, privacy, reload, isolation, storage failure and retry');
} finally {
  await browser.close();
}
