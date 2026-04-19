#!/usr/bin/env node
// samples/pr-review/scripts/run-reviews.mjs
//
// Wrapper that runs every skill in .claude/skills/ against a PR diff
// and accumulates structured findings into a single JSON file.
//
// Usage:
//   node run-reviews.mjs \
//     --skills .claude/skills \
//     --diff /tmp/pr.diff \
//     --repo . \
//     --out /tmp/findings.json
//
// Assumes the checkout step ran with `fetch-depth: 0` so the skill can
// Read files referenced by the diff. Without full-repo context, evidence
// verification cannot work.

import { readFileSync, writeFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { parseArgs } from 'node:util';

const { values } = parseArgs({
  options: {
    skills: { type: 'string', default: '.claude/skills' },
    diff:   { type: 'string' },
    repo:   { type: 'string', default: '.' },
    out:    { type: 'string', default: 'findings.json' },
  },
});

if (!values.diff) {
  console.error('Missing --diff <path>');
  process.exit(1);
}

const apiKey = process.env.ANTHROPIC_API_KEY;
if (!apiKey) {
  console.error('Missing ANTHROPIC_API_KEY in environment');
  process.exit(1);
}

const diff = readFileSync(values.diff, 'utf-8');
if (!diff.trim()) {
  console.log('Empty diff; nothing to review.');
  writeFileSync(values.out, '[]');
  process.exit(0);
}

const skillFiles = readdirSync(values.skills).filter((f) => f.endsWith('.md'));
if (skillFiles.length === 0) {
  console.error(`No skill files found in ${values.skills}`);
  process.exit(1);
}

const VALID_SEVERITIES = ['low', 'medium', 'high'];

// Extract a JSON findings array from a model response. Tries a fenced
// ```json ... ``` block first, then falls back to the LAST non-greedy
// JSON array in the text so example `[]` snippets in prose do not
// swallow the real findings array.
function extractFindingsArray(text) {
  const fenced = text.match(/```(?:json)?\s*\n([\s\S]*?)\n```/);
  if (fenced) {
    const inner = fenced[1].trim();
    if (inner.startsWith('[') && inner.endsWith(']')) {
      return inner;
    }
  }
  const lastArray = text.match(/\[[\s\S]*?\](?![\s\S]*\])/);
  return lastArray ? lastArray[0] : null;
}

// Sleep for the given number of milliseconds.
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// POST to the Messages API with a 90s per-attempt timeout and up to two
// retries on 429 or 5xx, honoring retry-after when present.
async function postWithRetry(body) {
  const MAX_ATTEMPTS = 3;
  let lastErr;
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    try {
      const response = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(90_000),
      });

      if (response.ok) {
        return response;
      }

      const retriable = response.status === 429 || response.status >= 500;
      if (!retriable || attempt === MAX_ATTEMPTS) {
        return response;
      }

      const retryAfterHeader = response.headers.get('retry-after');
      let delayMs;
      if (retryAfterHeader) {
        const seconds = Number(retryAfterHeader);
        delayMs = Number.isFinite(seconds) ? seconds * 1000 : 2000 * attempt;
      } else {
        delayMs = 1000 * Math.pow(2, attempt); // 2s, 4s
      }
      console.log(`  retrying after ${delayMs}ms (status ${response.status}, attempt ${attempt}/${MAX_ATTEMPTS})`);
      await sleep(delayMs);
    } catch (err) {
      lastErr = err;
      if (attempt === MAX_ATTEMPTS) throw err;
      const delayMs = 1000 * Math.pow(2, attempt);
      console.log(`  retrying after ${delayMs}ms (fetch error: ${err.message}, attempt ${attempt}/${MAX_ATTEMPTS})`);
      await sleep(delayMs);
    }
  }
  throw lastErr ?? new Error('postWithRetry: exhausted retries');
}

const allFindings = [];

for (const file of skillFiles) {
  const skillName = file.replace(/\.md$/, '');
  const skillContent = readFileSync(join(values.skills, file), 'utf-8');

  console.log(`Running skill: ${skillName}`);

  const userMessage = [
    'Review the following pull request diff against the detection rules in your skill.',
    '',
    'Output a JSON array of findings. Each finding must have:',
    '  { "severity": "low|medium|high", "file": string, "line": number,',
    '    "rationale": string, "evidence": string }',
    '',
    'If there are no findings, output an empty array: []',
    '',
    'Diff:',
    '```diff',
    diff,
    '```',
  ].join('\n');

  try {
    const response = await postWithRetry({
      // Pin to dated IDs; bare aliases may 404 via the public Messages API.
      model: 'claude-sonnet-4-6-20260201',
      max_tokens: 8192,
      system: skillContent,
      messages: [{ role: 'user', content: userMessage }],
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error(`  API error for ${skillName}: ${response.status} ${errText}`);
      continue;
    }

    const data = await response.json();
    const text = data.content?.[0]?.text ?? '';

    if (data.stop_reason === 'max_tokens') {
      console.warn(`  WARNING: ${skillName} output was truncated (stop_reason=max_tokens). Consider raising max_tokens above ${8192}.`);
    }

    const raw = extractFindingsArray(text);
    if (!raw) {
      console.log(`  ${skillName}: no findings array in response`);
      continue;
    }

    let findings;
    try {
      findings = JSON.parse(raw);
    } catch (parseErr) {
      console.error(`  ${skillName}: failed to parse findings JSON (${parseErr.message}). Raw fragment: ${raw.slice(0, 200)}`);
      continue;
    }

    if (!Array.isArray(findings)) {
      console.error(`  ${skillName}: parsed value is not an array; skipping.`);
      continue;
    }

    let accepted = 0;
    for (const f of findings) {
      if (!f || typeof f !== 'object') {
        console.log(`  ${skillName}: skipping finding (not an object)`);
        continue;
      }
      if (typeof f.file !== 'string') {
        console.log(`  ${skillName}: skipping finding (file is not a string)`);
        continue;
      }
      const line = typeof f.line === 'number' ? f.line : Number(f.line);
      if (!Number.isInteger(line) || Number.isNaN(line)) {
        console.log(`  ${skillName}: skipping finding for ${f.file} (line is not an integer)`);
        continue;
      }
      if (typeof f.rationale !== 'string') {
        console.log(`  ${skillName}: skipping finding for ${f.file}:${line} (rationale is not a string)`);
        continue;
      }
      let severity = f.severity;
      if (!VALID_SEVERITIES.includes(severity)) {
        console.log(`  ${skillName}: coercing severity "${severity}" to "medium" for ${f.file}:${line}`);
        severity = 'medium';
      }
      allFindings.push({ skill: skillName, ...f, line, severity });
      accepted++;
    }
    console.log(`  ${skillName}: ${accepted} finding(s) accepted (of ${findings.length} emitted)`);
  } catch (err) {
    console.error(`  Exception running ${skillName}: ${err.message}`);
  }
}

writeFileSync(values.out, JSON.stringify(allFindings, null, 2));
console.log(`\nWrote ${allFindings.length} total finding(s) to ${values.out}`);
