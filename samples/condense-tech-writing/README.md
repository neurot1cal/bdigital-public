# condense-tech-writing (sample)

Tighten AI-drafted technical writing (design docs, RFCs, ADRs, runbooks) without losing technical precision. The skill edits in place and reports every change, so the user can audit the diff for any softened claim before accepting the trim.

This is the read-the-source copy. The installable plugin lives at
[`plugins/condense-tech-writing/`](../../plugins/condense-tech-writing/).

## Why this exists

AI tools produce design docs in 2x the words a human would write. The bloat hides in generic Security/Privacy paragraphs, hedge stacks ("it is worth noting that"), restatement closers, and three-sentence transitions. The technical content (numbers, API surfaces, invariants, thresholds) is the part the writer cannot afford to lose.

Existing summarizers either rewrite from scratch (lose precision) or extract sentences (lose flow). This skill does neither. It edits in place, reports each change, and protects the named technical content explicitly.

## How it works

1. Classify the input and short-circuit on already-tight drafts
2. Mark generic paragraphs that could appear in any other doc — cut those first
3. Convert any word-count target to a shape target (LLMs obey shape, ignore word budgets)
4. Run the edit-in-place prompt against each section
5. Audit the diff log against technical claims; reject edits that hedge, round, or genericize
6. Report original / trimmed / percentage / rejected-edit counts

See [`SKILL.md`](./SKILL.md) for the full procedure and the prompt templates.

## Test cases

Three eval prompts live in [`evals/evals.json`](./evals/evals.json):

1. **trivial-tight** — a 35-word security note that is already tight; skill should short-circuit
2. **bloated-design-doc-section** — a 380-word architecture decision section with hedge stacks and restatement; target ~50% reduction
3. **generic-security-block** — a 280-word Security section that is mostly generic web-app best practices; target heavy cuts on the generic paragraphs while preserving the one system-specific control

Run the skill-creator eval framework against these to compare with-skill vs no-skill output.

## Install

This skill ships as a Claude Code plugin in the bdigital-public marketplace:

```
/plugin marketplace add neurot1cal/bdigital-public
/plugin install condense-tech-writing@bdigital-public
```

## Trust model

The skill reads the input text the user pastes and writes a trimmed version plus a diff log. It does not run network calls, does not read other files unless the user passes paths explicitly, and does not write to disk unless asked. Allowed tools: Read, Write, Edit, Bash (Bash limited to word counts via `wc -w`).
