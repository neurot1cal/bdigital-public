---
name: condense-tech-writing
description: Use when the user wants to tighten AI-drafted technical writing — design docs, RFCs, ADRs, runbooks, engineering specs — without losing precision. Trigger phrases include "condense", "tighten", "shorten", "trim", "compress", "too wordy", "too verbose", "edit for length", or any case where the user is staring at an AI draft that says the right things in twice the words. Especially fires when the input is a section from a design doc, an RFC, or any structured technical document where API surfaces, invariants, thresholds, or quantitative claims must survive intact.
user-invocable: true
allowed-tools: Read, Write, Edit, Bash
---

# Condense Technical Writing

## What this skill does

Tighten AI-drafted technical prose without softening the technical claims inside it.

The job is not to summarize. Summarization rewrites; this skill edits in place and reports every change. The output is a tighter draft plus a diff log the user scans for any claim that got hedged.

## When to invoke

User shows up with a draft and one of these signals:

- Phrases like "this is too wordy", "tighten this", "condense this section", "compress this", "trim the fluff", "edit for length"
- A pasted design doc, RFC, ADR, runbook, or spec section with obvious AI bloat (generic Security/Privacy paragraphs, hedge stacks like "it is worth noting that", filler transitions, three-sentence restatements)
- Asks like "shorten this without losing the technical details"
- Asks like "make this fit in N words" — convert to shape constraints, see Procedure step 3

Do NOT invoke for:
- Marketing copy, blog prose, social posts (different voice rules apply)
- Source text the user didn't write (use extractive summarization instead)
- Code comments inside source files (use targeted edits, not this skill)

## The technique in one paragraph

Hand the model the draft and tell it to trim filler, hedging, redundancy, and generic prose while reporting every change with reasoning. Reject any edit that softens a quantitative claim, an API surface, an invariant, or a threshold. Pin the document's shape with structural constraints ("3 bullets for decisions, 2 for tradeoffs, 1 line each") rather than word counts, because models obey shape and ignore word budgets. Cut generic paragraphs first because they compress to zero loss; protect the specific content because that is the document.

## Procedure

### Step 1: Classify the input

Read the draft. Count words. Identify the document type (design doc, RFC, ADR, runbook, blog, internal email). The skill applies cleanly to design docs, RFCs, ADRs, and runbooks. For blogs or emails, ask the user to confirm before proceeding.

If the draft is under 200 words and reads tight on first pass, short-circuit. Tell the user the draft does not need condensing and stop. Wasted token budget on a tight draft is itself bloat.

### Step 2: Mark the generic-prose paragraphs

Before any edits, scan each paragraph and flag the ones that could appear unchanged in a different design doc. Common offenders:

- Security/Privacy sections that list generic web-app best practices instead of system-specific surfaces
- Background sections that restate well-known concepts the reader already knows
- Closing paragraphs that summarize what was just said
- Sentences that hedge with "it is worth noting that", "of course", "as one might expect", "in many cases"
- Transitions that announce what is about to be said ("In the next section, we will...")

These paragraphs compress to zero with no information loss. Cut them outright or rewrite them to add system-specific content. Do this pass first because it is the highest-leverage cut.

### Step 3: Convert word-count targets to shape targets

If the user asked for "under N words" or "half the length", translate that to a structural constraint before editing. Models reliably obey shape and reliably ignore word budgets.

Examples:

- "Under 500 words" → "1 sentence problem statement, 3 bullets for decisions, 3 bullets for tradeoffs, 1 line risks"
- "Half the length" → "Keep the section headings; under each heading, max 2 paragraphs of 3 sentences each"
- "Make it shorter" → "Each paragraph max 4 sentences; cut paragraphs that restate"

Tell the user the shape you picked. Let them adjust before you edit.

### Step 4: Run the edit-in-place pass

Use this prompt template against the draft, one section at a time:

> Edit the text below for clarity and concision. Do not rewrite sentences from scratch. Remove filler, hedging, redundancy, vague claims, and sentences that do not add new information. Keep every quantitative claim, API name, invariant, threshold, and specific noun exactly as written. Tell me every change you made and why. If a sentence is fine as-is, leave it alone.
>
> Draft:
>
> {paste section}

For aggressive trims (target ~50% length reduction):

> Trim this draft aggressively. Remove filler, vague claims, unnecessary repetition, empty corporate language, and sentences that do not add new value. Preserve every number, name, threshold, API surface, and technical decision exactly. Output the trimmed version followed by a numbered diff log of every cut and why.

Section-by-section beats whole-doc. One section at a time keeps the diff readable and stops the model from rewriting structure unprompted.

### Step 5: Audit the diff log against technical claims

Read the diff log. For each change, ask:

- Did a number get rounded, hedged, or dropped? Reject.
- Did an API name, function signature, env var, or config key get genericized? Reject.
- Did an invariant ("must be idempotent", "exactly-once", "at-least-once") get softened to "should" or "typically"? Reject.
- Did a threshold ("5 minute timeout", "300 RPM rate limit") get described instead of stated? Reject.
- Did a specific noun ("Cloudflare R2", "Vitest", "Postgres logical replication") become a generic ("object storage", "test runner", "replication")? Reject unless the user explicitly asked for vendor-agnostic prose.

Hand the user the trimmed draft and the diff log together. Mark any rejected edits and explain why the original wording survived.

### Step 6: Report the numbers

Report three counts:

- Original word count
- Trimmed word count
- Percentage reduction

If the cut is under 15%, the draft was probably already tight or the trim was too cautious. Run Step 4 again with the aggressive template. If the cut is over 60%, the model probably dropped technical content. Audit the diff log harder.

## Output format

Always return three blocks in this order:

1. **Trimmed draft** — full text, ready to paste back into the doc
2. **Diff log** — numbered list, one line per change, format: `LINE N: cut "<original>" → "<replacement>" (reason)`
3. **Stats** — original words, trimmed words, percentage reduction, count of rejected edits

Example:

```
## Trimmed draft

The webhook handler validates the X-Signature header against the shared secret using constant-time comparison. Requests without a valid signature return 401.

## Diff log

1. Cut "It is worth noting that" prefix on sentence 1 (filler)
2. Cut "in order to prevent timing attacks" trailing clause (implied by "constant-time comparison")
3. Rejected: would have changed "X-Signature" to "the signature header" (API surface)

## Stats

Original: 87 words
Trimmed: 31 words
Reduction: 64%
Rejected edits: 1
```

## What to avoid

- Don't summarize. The output is an edited version of the input, not a paraphrase.
- Don't rewrite paragraph structure unless the user asked. Reorder is a separate operation.
- Don't introduce new claims. If the source said "we use Postgres", the trim cannot become "we use Postgres for its ACID guarantees" unless that fact was in the original.
- Don't use em dashes in the trimmed output. Commas, semicolons, or "and" instead. Em dashes are an AI-writing signal that defeats the purpose.
- Don't drop citations or links. Filler around a citation can go; the citation itself stays.

## Common bloat patterns to cut on sight

| Pattern | Cut |
|---------|-----|
| "It is worth noting that X" | "X" |
| "It is important to understand that X" | "X" |
| "X plays a critical role in Y" | "X enables Y" or just describe what X does |
| "In order to Y, we will X" | "X Y's" (passive→active when possible) |
| "There are several reasons why X" then a list | Just the list |
| "As mentioned earlier, X" | Cut entirely if X was mentioned, or restate without the meta-reference |
| "X is a Y that does Z" (where Y is generic) | "X does Z" |
| Three-sentence paragraphs that restate the heading | Cut |
| Closing summary of a short section | Cut |

## Why each step earns its place

Step 2 (mark generic prose first) gets the biggest cuts at zero accuracy cost. Generic content is the easy 30-40% the model wrote because it had nothing specific to say.

Step 3 (shape over word count) works because LLMs obey structural constraints reliably and ignore word budgets reliably. "Under 500 words" produces 800-word output; "3 bullets max, 1 line each" produces 3 bullets.

Step 4 (edit-in-place with diff) prevents the model from rewriting structure or introducing new claims. Summarization is a different operation; this is not that.

Step 5 (audit the diff against technical claims) is the precision guard. The whole point of the skill is that the user keeps the technical content. Without the audit, the skill is a wordcount reducer with accuracy regression.

Step 6 (report the numbers) lets the user decide if the trim was the right depth. Under 15% means the model played it safe and the user can rerun aggressive. Over 60% means content probably got lost and the audit needs another pass.
