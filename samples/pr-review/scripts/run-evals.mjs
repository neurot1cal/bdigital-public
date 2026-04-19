#!/usr/bin/env node
// samples/pr-review/scripts/run-evals.mjs
//
// Executor/Grader harness for the pr-review skills.
//
// For each fixture in evals/, load the matching skill markdown, run every
// case through the Executor (the skill under test), then hand the Executor
// output plus the expected shape to a separate Grader model and ask ONLY
// whether the findings satisfy the expected findings. The Grader never
// re-reviews the diff.
//
// Usage:
//   node scripts/run-evals.mjs \
//     --skills .claude/skills \
//     --evals evals \
//     --out evals/results.json \
//     [--executor-model <id>] \
//     [--grader-model <id>] \
//     [--only <skill-name>]

import { readFileSync, writeFileSync, readdirSync, existsSync } from 'node:fs';
import { join, basename } from 'node:path';
import { parseArgs } from 'node:util';

const { values } = parseArgs({
  options: {
    skills:          { type: 'string', default: '.claude/skills' },
    evals:           { type: 'string', default: 'evals' },
    out:             { type: 'string', default: 'evals/results.json' },
    'executor-model': { type: 'string', default: 'claude-sonnet-4-6-20260201' },
    'grader-model':   { type: 'string', default: 'claude-haiku-4-5-20251001' },
    only:            { type: 'string' },
  },
});

const apiKey = process.env.ANTHROPIC_API_KEY;
if (!apiKey) {
  console.error('Missing ANTHROPIC_API_KEY in environment');
  process.exit(1);
}

const EXECUTOR_MODEL = values['executor-model'];
const GRADER_MODEL = values['grader-model'];
const VALID_SEVERITIES = ['low', 'medium', 'high'];

// ---------------------------------------------------------------------------
// Shared API helpers (mirrors run-reviews.mjs; duplicated intentionally so
// the two scripts can evolve independently without cross-file drift).
// ---------------------------------------------------------------------------

// Extract a JSON array or object from a model response. Prefers a fenced
// ```json ... ``` block, then falls back to the LAST top-level array or
// object so example snippets in prose do not swallow the real payload.
function extractJsonPayload(text, { shape = 'array' } = {}) {
  const fenced = text.match(/```(?:json)?\s*\n([\s\S]*?)\n```/);
  if (fenced) {
    const inner = fenced[1].trim();
    if (shape === 'array' && inner.startsWith('[') && inner.endsWith(']')) return inner;
    if (shape === 'object' && inner.startsWith('{') && inner.endsWith('}')) return inner;
  }
  if (shape === 'array') {
    const lastArray = text.match(/\[[\s\S]*?\](?![\s\S]*\])/);
    return lastArray ? lastArray[0] : null;
  }
  const lastObject = text.match(/\{[\s\S]*?\}(?![\s\S]*\})/);
  return lastObject ? lastObject[0] : null;
}

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

      if (response.ok) return response;

      const retriable = response.status === 429 || response.status >= 500;
      if (!retriable || attempt === MAX_ATTEMPTS) return response;

      const retryAfterHeader = response.headers.get('retry-after');
      let delayMs;
      if (retryAfterHeader) {
        const seconds = Number(retryAfterHeader);
        delayMs = Number.isFinite(seconds) ? seconds * 1000 : 2000 * attempt;
      } else {
        delayMs = 1000 * Math.pow(2, attempt);
      }
      console.log(`    retrying after ${delayMs}ms (status ${response.status}, attempt ${attempt}/${MAX_ATTEMPTS})`);
      await sleep(delayMs);
    } catch (err) {
      lastErr = err;
      if (attempt === MAX_ATTEMPTS) throw err;
      const delayMs = 1000 * Math.pow(2, attempt);
      console.log(`    retrying after ${delayMs}ms (fetch error: ${err.message}, attempt ${attempt}/${MAX_ATTEMPTS})`);
      await sleep(delayMs);
    }
  }
  throw lastErr ?? new Error('postWithRetry: exhausted retries');
}

// ---------------------------------------------------------------------------
// Executor phase: run the skill against one diff and return its findings.
// ---------------------------------------------------------------------------

async function runExecutor({ skillName, skillContent, diff }) {
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

  const response = await postWithRetry({
    model: EXECUTOR_MODEL,
    max_tokens: 8192,
    system: skillContent,
    messages: [{ role: 'user', content: userMessage }],
  });

  if (!response.ok) {
    const errText = await response.text();
    return { ok: false, error: `API ${response.status}: ${errText}`, findings: null, raw: null };
  }

  const data = await response.json();
  const text = data.content?.[0]?.text ?? '';
  const truncated = data.stop_reason === 'max_tokens';

  const raw = extractJsonPayload(text, { shape: 'array' });
  if (!raw) {
    return { ok: false, error: 'no JSON array in executor response', findings: null, raw: text, truncated };
  }

  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (parseErr) {
    return { ok: false, error: `executor JSON parse: ${parseErr.message}`, findings: null, raw, truncated };
  }
  if (!Array.isArray(parsed)) {
    return { ok: false, error: 'executor payload is not an array', findings: null, raw, truncated };
  }

  // Normalize findings in the same spirit as run-reviews.mjs, but keep
  // invalid-shape findings visible to the grader so it can penalize them.
  const findings = parsed.map((f) => {
    if (!f || typeof f !== 'object') return { invalid: true, value: f };
    const line = typeof f.line === 'number' ? f.line : Number(f.line);
    const normLine = Number.isInteger(line) ? line : null;
    const severity = VALID_SEVERITIES.includes(f.severity) ? f.severity : 'medium';
    return {
      severity,
      file: typeof f.file === 'string' ? f.file : null,
      line: normLine,
      rationale: typeof f.rationale === 'string' ? f.rationale : null,
      evidence: typeof f.evidence === 'string' ? f.evidence : null,
    };
  });

  return { ok: true, findings, skill: skillName, truncated };
}

// ---------------------------------------------------------------------------
// Grader phase: judge whether executor findings satisfy expected findings.
// This prompt is DELIBERATELY different from the executor's: the grader
// is told NOT to re-review the diff.
// ---------------------------------------------------------------------------

const GRADER_SYSTEM = [
  'You are an evaluation grader. Your ONLY job is to decide whether a set of',
  '"executor findings" satisfies a set of "expected findings" for a PR-review',
  'skill eval.',
  '',
  'Rules:',
  '1. You are NOT reviewing the diff. Do not re-examine the code. Do not add',
  '   new findings. Do not disagree with the expected findings even if you',
  '   think the expected set is wrong.',
  '2. Matching rules:',
  '   - If the expected findings list is empty, the case PASSES only when',
  '     the executor findings list is also empty (strict negative).',
  '   - If the expected findings list is non-empty, the case PASSES only when',
  '     every expected finding has a corresponding executor finding that:',
  '       a. references the same file path,',
  '       b. points at a line within +/- 3 of the expected line,',
  '       c. has severity at or above the expected severity',
  '          (low < medium < high), and',
  '       d. has a rationale whose text contains the expected',
  '          "rationale_contains" substring, case-insensitive.',
  '   - Extra executor findings beyond the expected set are allowed as long',
  '     as they do not invert the verdict of a strict-negative case.',
  '3. Output STRICTLY a single JSON object, no prose, in this shape:',
  '   { "passed": boolean, "reason": "<short sentence, <=200 chars>" }',
  '4. The "reason" must reference the specific rule that passed or failed',
  '   (e.g., "missing file path match", "rationale substring not found",',
  '   "strict-negative violated: executor emitted 2 findings").',
].join('\n');

async function runGrader({ expected, executorFindings, executorError }) {
  const user = [
    'Grade the following case.',
    '',
    'Expected findings (authoritative):',
    '```json',
    JSON.stringify(expected, null, 2),
    '```',
    '',
    'Executor findings (to be judged):',
    '```json',
    JSON.stringify(executorFindings ?? [], null, 2),
    '```',
    '',
    executorError
      ? `Executor error note (for context only): ${executorError}`
      : 'Executor ran without error.',
    '',
    'Return only the JSON object described in your instructions.',
  ].join('\n');

  const response = await postWithRetry({
    model: GRADER_MODEL,
    max_tokens: 512,
    system: GRADER_SYSTEM,
    messages: [{ role: 'user', content: user }],
  });

  if (!response.ok) {
    const errText = await response.text();
    return { passed: false, reason: `grader API error ${response.status}: ${errText.slice(0, 200)}` };
  }

  const data = await response.json();
  const text = data.content?.[0]?.text ?? '';
  const raw = extractJsonPayload(text, { shape: 'object' });
  if (!raw) {
    return { passed: false, reason: `grader returned no JSON object: ${text.slice(0, 200)}` };
  }
  try {
    const parsed = JSON.parse(raw);
    if (typeof parsed.passed !== 'boolean') {
      return { passed: false, reason: `grader missing boolean "passed": ${raw.slice(0, 200)}` };
    }
    return {
      passed: parsed.passed,
      reason: typeof parsed.reason === 'string' ? parsed.reason : '(no reason returned)',
    };
  } catch (err) {
    return { passed: false, reason: `grader JSON parse: ${err.message}` };
  }
}

// ---------------------------------------------------------------------------
// Main loop.
// ---------------------------------------------------------------------------

function loadFixtures(dir, onlyFilter) {
  const fixtureFiles = readdirSync(dir)
    .filter((f) => f.endsWith('.json') && !f.startsWith('results'));
  const fixtures = [];
  for (const f of fixtureFiles) {
    const path = join(dir, f);
    let content;
    try {
      content = JSON.parse(readFileSync(path, 'utf-8'));
    } catch (err) {
      console.error(`Skipping ${f}: JSON parse error (${err.message})`);
      continue;
    }
    if (!content.skill || !Array.isArray(content.cases)) {
      console.error(`Skipping ${f}: missing "skill" or "cases"`);
      continue;
    }
    if (onlyFilter && content.skill !== onlyFilter) continue;
    fixtures.push({ ...content, _file: f });
  }
  return fixtures;
}

async function main() {
  const fixtures = loadFixtures(values.evals, values.only);
  if (fixtures.length === 0) {
    console.error(`No fixtures matched in ${values.evals}${values.only ? ` (filter: ${values.only})` : ''}`);
    process.exit(1);
  }

  const startedAt = new Date().toISOString();
  console.log(`Starting eval run at ${startedAt}`);
  console.log(`Executor model: ${EXECUTOR_MODEL}`);
  console.log(`Grader model:   ${GRADER_MODEL}`);
  console.log(`Skills dir:     ${values.skills}`);
  console.log(`Evals dir:      ${values.evals}`);
  console.log('');

  const perSkill = [];
  let totalPassed = 0;
  let totalFailed = 0;

  for (const fixture of fixtures) {
    const skillPath = join(values.skills, `${fixture.skill}.md`);
    if (!existsSync(skillPath)) {
      console.error(`[${fixture.skill}] skill markdown not found at ${skillPath}; skipping fixture`);
      perSkill.push({
        skill: fixture.skill,
        fixture: fixture._file,
        error: `missing skill markdown at ${skillPath}`,
        cases: [],
      });
      continue;
    }
    const skillContent = readFileSync(skillPath, 'utf-8');

    console.log(`=== ${fixture.skill} (${fixture.cases.length} case${fixture.cases.length === 1 ? '' : 's'}) ===`);
    const caseResults = [];
    let passed = 0;
    let failed = 0;

    for (const c of fixture.cases) {
      process.stdout.write(`  ${c.name} [${c.type}] ... `);
      let executorResult;
      try {
        executorResult = await runExecutor({
          skillName: fixture.skill,
          skillContent,
          diff: c.diff,
        });
      } catch (err) {
        executorResult = { ok: false, error: `executor exception: ${err.message}`, findings: null };
      }

      let grade;
      try {
        grade = await runGrader({
          expected: c.expected,
          executorFindings: executorResult.findings,
          executorError: executorResult.ok ? null : executorResult.error,
        });
      } catch (err) {
        grade = { passed: false, reason: `grader exception: ${err.message}` };
      }

      if (grade.passed) {
        passed++;
        totalPassed++;
        console.log(`PASS - ${grade.reason}`);
      } else {
        failed++;
        totalFailed++;
        console.log(`FAIL - ${grade.reason}`);
      }

      caseResults.push({
        name: c.name,
        type: c.type,
        notes: c.notes,
        expected: c.expected,
        executor: executorResult,
        grade,
      });
    }

    const rate = fixture.cases.length === 0
      ? '0.0%'
      : `${((passed / fixture.cases.length) * 100).toFixed(1)}%`;
    console.log(`  -> ${passed}/${fixture.cases.length} passed (${rate})`);
    console.log('');

    perSkill.push({
      skill: fixture.skill,
      fixture: fixture._file,
      passed,
      failed,
      total: fixture.cases.length,
      rate,
      cases: caseResults,
    });
  }

  const finishedAt = new Date().toISOString();
  const totalCases = totalPassed + totalFailed;
  const summary = {
    startedAt,
    finishedAt,
    executorModel: EXECUTOR_MODEL,
    graderModel: GRADER_MODEL,
    totalCases,
    totalPassed,
    totalFailed,
    overallRate: totalCases === 0
      ? '0.0%'
      : `${((totalPassed / totalCases) * 100).toFixed(1)}%`,
    skills: perSkill.map(({ cases, ...rest }) => rest),
  };

  // Write a per-run results file so older runs are preserved.
  const outPath = values.out;
  const timestamped = outPath.replace(
    /(\.json)?$/,
    `-${finishedAt.replace(/[:.]/g, '-')}.json`,
  );
  const targets = [outPath, timestamped];
  const payload = JSON.stringify({ summary, skills: perSkill }, null, 2);
  for (const target of targets) {
    writeFileSync(target, payload);
  }

  console.log('=== Summary ===');
  for (const s of perSkill) {
    if (s.error) {
      console.log(`  ${s.skill}: ERROR (${s.error})`);
      continue;
    }
    console.log(`  ${s.skill}: ${s.passed}/${s.total} (${s.rate})`);
  }
  console.log(`  overall:  ${totalPassed}/${totalCases} (${summary.overallRate})`);
  console.log('');
  console.log(`Wrote ${basename(outPath)} and ${basename(timestamped)}`);

  if (totalFailed > 0) process.exit(1);
}

main().catch((err) => {
  console.error(`Fatal: ${err.stack ?? err.message}`);
  process.exit(1);
});
