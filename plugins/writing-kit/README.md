# writing-kit

**Thesis:** AI writing tools default to reactive editing. This kit pairs a proactive draft-time constraint layer with a strict review-time audit so generic-fluent prose never enters the draft in the first place.

The pair is the product. One skill enforces structure and bans averaging artifacts while you write. The other refuses to approve drafts that slipped through.

## See it work — one example

Sloppy AI-drafted Slack update:

> Hey team! In today's fast-paced AI landscape, I wanted to leverage this opportunity to share that we've been working hard to facilitate a robust deployment of our new feature. The team has done amazing work and we're seeing some really exciting numbers (around 30% improvement!). Stay tuned!

After `/deslop-tech-comms`:

> Deployed the new caching layer this morning. p95 dropped from 540ms to 380ms (per the dashboard at $URL). Watching memory through end of day.

Audit log returned by the skill:

- Cut "In today's fast-paced AI landscape" generic opener
- Replaced "leverage / facilitate / robust" with concrete verbs
- Replaced unsourced "around 30% improvement" with the actual numbers from the dashboard
- Cut "Stay tuned" + exclamation point
- 78 words → 30 words

> *"A made-up number is worse than no number because it makes the writing look both confident AND wrong."* — from `deslop-tech-comms`

## The 2×2 the kit covers

|  | **Structural** (audience, surface, section count, length) | **Stylistic** (buzzwords, sentence rhythm, fragments) |
|---|---|---|
| **Draft-time** | `deslop-tech-comms` forces audience/purpose/surface/constraint commitment before generation, then picks the right scaffold for the surface | `deslop-tech-comms` applies the buzzword ban table + sentence-rhythm rules per paragraph break |
| **Review-time** | `thermo-nuclear-writing-review` pushes for delete-not-polish moves and enforces length discipline (1,000-word section cap, genre-specific piece caps) | `thermo-nuclear-writing-review` fires the cut-on-sight ban list + averaging-artifact scan |

The kit covers all four quadrants because draft-time and review-time produce different failure modes — the structural problem you remember to avoid while writing isn't the same as the one you only catch after a fresh read.

## What's in the kit

### `deslop-tech-comms` — proactive, at draft time

Triages audience, purpose, surface, and constraint before generation. Picks surface-specific structure (Slack message vs Slack thread vs design doc vs postmortem vs executive summary vs email vs status update vs release notes). Applies an averaging-artifact checklist at every paragraph break with a configurable buzzword ban table (carveout for "named-specific-behavior" usage; brand-voice file overrides). Returns the deslopped draft plus a "what I changed" audit log so the pass is auditable.

### `thermo-nuclear-writing-review` — reactive, at review time

A prose parallel of Cursor's `thermo-nuclear-code-quality-review`. Delete-not-polish structural cuts; length discipline (1,000-word section cap; genre caps for blog posts, design docs, postmortems, Slack threads). Prose-spaghetti detection. Averaging-artifact and buzzword bans (same configurable table as the draft skill). Antecedent and acronym cleanliness. Determinism: temperature-0 directive, tie-breaker rule, edge-case behaviors for already-tight prose, intentional buzzwords in marketing copy, and non-English prose. Verdict: `APPROVE`, `REVISE`, or `MAJOR REVISION`, with a one-sentence "what's salvageable" map before the numbered action list so the author leaves with a path, not a score.

## Why both

`deslop-tech-comms` prevents averaging artifacts at generation time. `thermo-nuclear-writing-review` catches what slips through. The two skills share one vocabulary (same buzzword ban list, same surface-specific scaffolds, same sentence-rhythm rules, derived from the same canonical source in `tests/fixtures/buzzword-bans.json`) so draft-time and review-time passes don't fight each other.

## Installation

```
/plugin marketplace add neurot1cal/bdigital-public
/plugin install writing-kit@bdigital-public
```

Or for development against a local checkout:

```
/plugin marketplace add ~/git/bdigital-public
/plugin install writing-kit@bdigital-public
```

Both skills are `user-invocable: true` — trigger them by slash command (`/deslop-tech-comms`, `/thermo-nuclear-writing-review`) or by mentioning them in a prompt.

## Tests and evals

The plugin ships fixture pairs under `tests/fixtures/` plus a check script (`tests/check.sh`) that:

- Asserts the buzzword regex finds zero hits in the expected-output files (proof the bans actually fire).
- Diffs the buzzword ban list across the two SKILL.md files and fails on divergence (proof the shared-vocabulary claim is mechanical, not marketing).
- Calibrates the `thermo-nuclear-writing-review` LLM judge against a labeled set of 5 drafts (3 deliberately sloppy, 2 deliberately clean) with expected verdicts.

Run `bash plugins/writing-kit/tests/check.sh` from the repo root.

## What this plugin does NOT do

- It does **not** rewrite the author's claims. It tightens the prose and surfaces structural issues; it does not silently make the argument stronger or weaker than the source.
- It does **not** invent missing structural prerequisites. If the source lacks a postmortem timeline, the deslopped postmortem also lacks the timeline — the skill surfaces the gap.
- It does **not** apply to code, code comments, or chat. Those have their own slop rules (see Cursor's `cursor-team-kit/skills/deslop` for code slop).
- It does **not** override pre-existing brand voice files. If a `context/brand-voice.md` or project `CLAUDE.md` voice section exists, the skills honor it on top of their defaults.
- It does **not** apply to non-English prose. The English-idiom rules will not generalize; the skill refuses non-English drafts and recommends a language-specific equivalent.

## Inspiration

The two skills derive from a paired pattern that earlier work in this space hinted at but did not name explicitly:

- `thermo-nuclear-writing-review` is a prose parallel of Cursor's [`thermo-nuclear-code-quality-review`](https://github.com/cursor/plugins/tree/main/cursor-team-kit/skills/thermo-nuclear-code-quality-review) — same priority ordering, same "ambitious about structural simplification" stance, adapted to the prose problem.
- `deslop-tech-comms` uses frontmatter conventions similar to those in [Anthropic's `anthropics/skills`](https://github.com/anthropics/skills) repo. The structural design (draft-time + review-time pair, shared vocabulary, surface-specific scaffolds, audit log) is original to this kit.

## License

[MIT](./LICENSE). Use these skills in commercial or personal projects.
