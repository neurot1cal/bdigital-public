import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';
import { fahrenheit } from './public/temperature.mjs';

test('converts freezing, boiling, and negative temperatures', () => {
  assert.equal(fahrenheit(0), 32);
  assert.equal(fahrenheit(100), 212);
  assert.equal(fahrenheit(-40), -40);
});

test('the page loads the app and provides its input and output', async () => {
  const html = await readFile(new URL('./public/index.html', import.meta.url), 'utf8');
  for (const part of ['src="./app.mjs"', 'id="celsius"', 'id="fahrenheit"']) {
    assert.ok(html.includes(part), 'Missing ' + part);
  }
  await readFile(new URL('./public/app.mjs', import.meta.url));
});
