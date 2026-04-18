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
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-6',
        max_tokens: 4096,
        system: skillContent,
        messages: [{ role: 'user', content: userMessage }],
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error(`  API error for ${skillName}: ${response.status} ${errText}`);
      continue;
    }

    const data = await response.json();
    const text = data.content?.[0]?.text ?? '';

    const match = text.match(/\[[\s\S]*\]/);
    if (!match) {
      console.log(`  ${skillName}: no findings array in response`);
      continue;
    }

    const findings = JSON.parse(match[0]);
    for (const f of findings) {
      allFindings.push({ skill: skillName, ...f });
    }
    console.log(`  ${skillName}: ${findings.length} finding(s)`);
  } catch (err) {
    console.error(`  Exception running ${skillName}: ${err.message}`);
  }
}

writeFileSync(values.out, JSON.stringify(allFindings, null, 2));
console.log(`\nWrote ${allFindings.length} total finding(s) to ${values.out}`);
