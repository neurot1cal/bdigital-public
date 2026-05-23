# writing-kit tests

Runnable proof for the skill claims. Addresses the panel-review finding that
the plugin shipped "vibes" without falsifiable assertions.

## What's here

- **`fixtures/buzzword-bans.json`** — canonical buzzword ban list with regexes,
  carveouts, and a `version` field. Both `SKILL.md` files in this plugin must
  reference every term in this list; the check script enforces parity.
- **`fixtures/01-buzzword-density.*`** — sloppy Slack status update → deslopped
  output. Proves the buzzword bans fire and the audit log surfaces the cuts.
- **`fixtures/02-fabricated-metrics.*`** — postmortem with invented numbers →
  deslopped output with `$PLACEHOLDER` variables. Proves the skill cuts unsourced
  quantitatives instead of inventing replacements.
- **`fixtures/03-clean-prose-approve.*`** — already-tight design doc → expected
  verdict `APPROVE`. Proves the review skill does not invent findings on clean
  prose.
- **`fixtures/04-sloppy-draft-revise.*`** — buzzword-dense, restated-thesis
  draft → expected verdict `MAJOR REVISION` with a 5+ item action list. Proves
  the review skill catches structural and stylistic issues together.
- **`fixtures/05-marketing-copy-suspended.*`** — marketing landing copy with
  intentional buzzwords. Proves the surface-detection edge case suspends the
  buzzword ban while keeping structural rules active.

## Run

From the repo root:

```bash
bash plugins/writing-kit/tests/check.sh
```

The check asserts:

1. `buzzword-bans.json` parses as valid JSON.
2. Every "expected output" fixture contains ZERO buzzword hits (proof the bans
   actually fire on the deslop side).
3. Both `SKILL.md` files reference every canonical ban term (proof the shared-
   vocabulary claim is mechanical, not marketing).
4. The fixture set is complete (every input has its expected sibling files).

## What this does NOT yet do

This iteration ships **fixture-level** assertions. A full eval that runs the
skills as LLM calls and grades the outputs against the expected fixtures is the
next iteration — that follows the pattern set by
`samples/condense-tech-writing/scripts/run-evals.mjs` in this repo. The current
check guards against the fastest-decaying failure mode (the bans drifting out
of the two SKILL.md files, or the fixtures themselves containing the patterns
they claim to remove).
