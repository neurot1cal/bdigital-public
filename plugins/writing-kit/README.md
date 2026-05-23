# writing-kit

Two skills for AI-drafted technical communication. **Use them as a pair**: one prevents slop while you draft; the other audits a finished draft with no soft feedback.

## What's in the kit

### `deslop-tech-comms` — proactive, at draft time

Use when drafting design docs, RFCs, ADRs, runbooks, release notes, executive summaries, Slack messages or threads, emails, status updates, or any AI-drafted technical writing destined for human readers. Enforces:

- **Audience triage**: who reads this, what they do after, where this lands, what the length and tone constraint is.
- **Surface-specific structure**: different shapes for Slack vs doc vs postmortem vs executive summary vs email vs status update. The skill carries scaffolds for each surface.
- **Anti-slop checklist** at every paragraph break: no generic openers, no buzzwords (full ban list), no fabricated specifics, vary sentence length, no fragment clusters, no "The"-starter clusters.
- **Specificity over abstraction**: replace adjectives with measurements, dates with anchors, pronouns with named subjects.
- **Final re-read pass**: scan the draft for AI fingerprints before returning.

The skill returns the deslopped draft plus a short "what I changed" audit log so the deslop pass is auditable.

### `thermo-nuclear-writing-review` — reactive, at review time

The prose parallel of Cursor's `thermo-nuclear-code-quality-review`. Use when a draft is supposedly finished and needs an unforgiving editorial pass before it ships. Applies:

- **Writing-judo moves**: actively look for opportunities to delete whole sections, not just polish them.
- **Length discipline**: 1,000-word section limit; piece-length caps by genre (blog posts < 3,000, design docs < 2,500, postmortems < 1,500, Slack threads ≤ 6 messages).
- **Prose-spaghetti detection**: hedge accumulation, parenthetical aside stacking, "we should also note" insertions.
- **AI-fingerprint bans**: cut-on-sight phrases, buzzword density, fragment clusters, "The" / "I" sentence-starter clusters, exclamation points in formal writing.
- **Antecedent / reference / acronym cleanliness**: ambiguous pronouns, undefined acronyms, hedges-as-style.
- **Verdict**: every review ends with exactly one of `APPROVE`, `REVISE`, or `MAJOR REVISION`, plus a numbered action list when revision is required.

## Why both

`deslop-tech-comms` prevents slop at generation time. `thermo-nuclear-writing-review` catches what slips through. The two skills share a vocabulary (same buzzword ban list, same surface-specific structures, same sentence-rhythm rules) so the draft-time and review-time passes don't fight each other.

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

Both skills are `user-invocable: true` — you can trigger them by slash command (`/deslop-tech-comms`, `/thermo-nuclear-writing-review`) or by mentioning them by name in a prompt.

## What this plugin does NOT do

- It does **not** rewrite the author's claims. It tightens the prose and surfaces structural issues; it does not silently make the argument stronger or weaker than the source.
- It does **not** invent missing structural prerequisites. If the source lacks a postmortem timeline, the deslopped postmortem also lacks the timeline — the skill surfaces the gap.
- It does **not** apply to code, code comments, or chat. Those have their own slop rules (see Cursor's `cursor-team-kit/skills/deslop` for code slop).
- It does **not** override pre-existing brand voice files. If a `context/brand-voice.md` or project CLAUDE.md voice section exists, the skills honor it on top of their defaults.

## Inspiration and prior art

- The `thermo-nuclear-writing-review` rubric is a direct prose parallel of Cursor's [`thermo-nuclear-code-quality-review`](https://github.com/cursor/plugins/tree/main/cursor-team-kit/skills/thermo-nuclear-code-quality-review) — same priority ordering, same "ambitious about structural simplification" stance, same tone, adapted to the prose problem.
- The `deslop-tech-comms` skill pattern (frontmatter + structured workflow + anti-slop bans + surface-specific scaffolds) follows the shape established by [Anthropic's `anthropics/skills`](https://github.com/anthropics/skills) repo.

## License

[MIT](./LICENSE). Use these skills in commercial or personal projects.
