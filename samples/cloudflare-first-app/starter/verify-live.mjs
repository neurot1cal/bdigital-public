import assert from 'node:assert/strict';

const [url, expectedHeading] = process.argv.slice(2);
if (!url || !expectedHeading) {
  throw new Error('Usage: node verify-live.mjs <site-url> "<expected heading>"');
}
const page = await fetch(url, { signal: AbortSignal.timeout(15000) });
assert.equal(page.status, 200, 'The homepage must return HTTP 200');
assert.ok(page.headers.get('content-type')?.includes('text/html'), 'Expected an HTML page');
const html = await page.text();
assert.ok(html.includes(`<h1>${expectedHeading}</h1>`), 'The expected heading is missing');
for (const name of ['app.mjs', 'temperature.mjs']) {
  const asset = await fetch(new URL(name, page.url), { signal: AbortSignal.timeout(15000) });
  assert.equal(asset.status, 200, name);
  assert.match(asset.headers.get('content-type') ?? '', /javascript|ecmascript/i, name);
}
console.log(`Verified the heading and both JavaScript assets at ${page.url}`);
