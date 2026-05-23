# bdigital-public

Public code samples that accompany the bdigital media engineering blog.
Examples are extracted from real projects, generalized, and reduced to the
minimum shape needed to be useful without shipping proprietary context.

This repo doubles as a Claude Code plugin marketplace AND an
[openskills](https://github.com/numman-ali/openskills)-compatible source
of agent skills. Every skill ships at two paths:

- `plugins/<plugin>/skills/<skill>/SKILL.md` — canonical, where authors edit
- `skills/<skill>/SKILL.md` — repo-root mirror, byte-identical, what `npx openskills install` discovers

Both paths are kept in lockstep by `scripts/sync-skills.mjs`, gated by the
`skills-sync-check` CI workflow. The `samples/` directory is a separate
read-the-source view used by blog posts and eval infrastructure.

## What lives here

```
bdigital-public/
├── .claude-plugin/
│   └── marketplace.json        # Makes this repo a Claude Code plugin marketplace
├── plugins/                    # Canonical: full plugin bundles (Claude Code marketplace)
│   ├── session-handoff/        # Brief-generating skill for the /clear-then-resume workflow
│   ├── cc-context-monitor/     # Three-bar color-banded statusline: ctx / 5h / 7d
│   ├── cursor-team-kit/        # Claude Code port of Cursor's team-kit (18 skills + 2 subagents)
│   └── writing-kit/            # deslop-tech-comms + thermo-nuclear-writing-review for AI prose
├── skills/                     # Auto-generated mirrors for `npx openskills install`
│   ├── session-handoff/        # → byte-identical to plugins/session-handoff/skills/session-handoff/
│   └── cc-context-monitor/     # → byte-identical to plugins/cc-context-monitor/skills/cc-context-monitor/
├── samples/                    # Hand-maintained read-the-source views (tests + evals + blog mirroring)
│   ├── pr-review/              # Claude-skills-based automated PR review + eval runner
│   ├── session-handoff/        # Same skill + tests + scenario fixtures
│   └── cc-context-monitor/     # Same plugin + tests + evals
├── scripts/                    # sync-skills.mjs (regenerates skills/ from plugins/)
├── site/                       # Astro landing page (Cloudflare Workers)
└── .github/                    # Open-source workflows, templates, ownership
```

`samples/` is for readers who want to study or copy code; `plugins/` is for
readers who want to install and use. Both coexist so you can pick whichever
matches your intent — and blog posts can link to either.

## Install a skill or plugin

### Preferred — `npx openskills install` (cross-agent: Claude Code, Cursor, Windsurf, Aider, Codex)

```bash
# Install all skills from this repo
npx openskills install neurot1cal/bdigital-public

# Or pick a specific one
npx openskills install neurot1cal/bdigital-public --skill session-handoff
```

This works because the repo ships every skill at the openskills-discoverable
path `/skills/<name>/SKILL.md`. See
[openskills](https://github.com/numman-ali/openskills) for the full CLI
reference. The repo's [`CLAUDE.md`](./CLAUDE.md) documents the layout
standard.

### Alternative — Claude Code marketplace (full plugin bundle: LICENSE + plugin.json + agents)

```
/plugin marketplace add neurot1cal/bdigital-public
/plugin install session-handoff@bdigital-public
/plugin install cc-context-monitor@bdigital-public
/plugin install cursor-team-kit@bdigital-public
/plugin install writing-kit@bdigital-public
```

If your Claude Code build rejects the shorthand, use the full Git URL
(`https://github.com/neurot1cal/bdigital-public.git`) or a local-path
pointing at a checkout of this repo. Each plugin's own README documents
its full install matrix, tools granted, and trust model:

- [`plugins/session-handoff/README.md`](plugins/session-handoff/README.md)
- [`plugins/cc-context-monitor/README.md`](plugins/cc-context-monitor/README.md)
- [`plugins/cursor-team-kit/README.md`](plugins/cursor-team-kit/README.md)
- [`plugins/writing-kit/README.md`](plugins/writing-kit/README.md)

## Current plugins

### `plugins/session-handoff/`

A user-invocable Claude Code skill that generates a distilled brief for a
fresh session to resume from. Implements the "Clear with a brief" pattern
from Anthropic's session management guide.

Install: `/plugin install session-handoff@bdigital-public` (after adding
the marketplace as shown above). Source lives at
[`plugins/session-handoff/skills/session-handoff/SKILL.md`](plugins/session-handoff/skills/session-handoff/SKILL.md).

### `plugins/cc-context-monitor/`

A user-invocable skill plus a statusline wrapper. Once installed, the
bottom of your terminal shows:

```
~/git/repo | feat/branch* | Opus 4.7 (1M context) | ●●○○○○○○○○ 18% ctx | ●●○○○○○○○○ 20% 5h | ●●●●●○○○○○ 54% 7d
```

Three 10-dot bars share one green/yellow/red palette (thresholds 49 / 74)
so pressure anywhere — context fill, 5-hour session burn, or 7-day weekly
quota — jumps out at a glance. Reads Claude Code's native stdin payload on
v2.1.x and newer; falls back to `ccusage statusline` on older builds for
the context percent only.

Install: `/plugin install cc-context-monitor@bdigital-public`. Source
lives at
[`plugins/cc-context-monitor/skills/cc-context-monitor/SKILL.md`](plugins/cc-context-monitor/skills/cc-context-monitor/SKILL.md)
and [`plugins/cc-context-monitor/statusline.sh`](plugins/cc-context-monitor/statusline.sh).

### `plugins/writing-kit/`

Two skills for AI-drafted technical communication, designed as a pair: one prevents slop at draft time, the other audits a finished draft with no soft feedback.

- **`deslop-tech-comms`** runs proactively while you draft. Triages audience, purpose, surface, and constraints; picks the right structure for the surface (Slack message vs design doc vs postmortem vs executive summary vs email vs status update); applies an anti-slop checklist at every paragraph break (banned buzzwords, no generic openers, no fabricated specifics, vary sentence length, no fragment clusters, no "The"-starter clusters); and does a final re-read pass for AI fingerprints before returning the draft.
- **`thermo-nuclear-writing-review`** runs reactively on a finished draft. A prose parallel of Cursor's [`thermo-nuclear-code-quality-review`](https://github.com/cursor/plugins/tree/main/cursor-team-kit/skills/thermo-nuclear-code-quality-review): writing-judo moves that delete whole sections, length discipline (1,000-word section limit, genre-specific piece caps), prose-spaghetti detection, AI-fingerprint bans, antecedent and acronym cleanliness, and a strict `APPROVE` / `REVISE` / `MAJOR REVISION` verdict with a numbered action list when revision is required.

The two skills share one vocabulary (same buzzword ban list, same surface-specific structures, same sentence-rhythm rules) so the draft-time and review-time passes don't fight each other. Inspired by Anthropic's `anthropics/skills` repo for the deslop pattern and Cursor's team-kit for the thermo-nuclear rubric.

Install: `/plugin install writing-kit@bdigital-public`. Source lives at [`plugins/writing-kit/`](plugins/writing-kit/) with READMEs and skill files inside.

### `plugins/cursor-team-kit/`

Claude Code port of [Team Cursor's `cursor-team-kit`](https://github.com/cursor/plugins/tree/main/cursor-team-kit) — 18 skills and 2 subagents for CI loops, PR review, shipping, verification, CLI/UI control harnesses, code-quality audits, and weekly work summaries. Original work © 2026 Cursor (MIT). This port preserves Cursor's authorship, copyright, and license; every adapted file points back to the upstream source.

Highlights:

- `loop-on-ci`, `fix-ci`, `ci-watcher` (subagent) — CI monitoring + iterate-to-green loops on top of `gh pr checks`.
- `review-and-ship`, `make-pr-easy-to-review`, `get-pr-comments`, `pr-review-canvas` — the PR lifecycle, including an interactive HTML walkthrough generator with annotated diffs and moved-code detection.
- `verify-this` — falsifiable baseline/treatment evidence with `VERIFIED` / `NOT VERIFIED` / `INCONCLUSIVE` verdicts.
- `control-cli`, `control-ui` — local tmux/PTY and Playwright/CDP harnesses for driving interactive CLIs and web/Electron UIs without external services.
- `thermo-nuclear-code-quality-review` (skill + subagent) — an unusually strict maintainability rubric (code-judo moves, 1k-line rule, spaghetti detection, boundary cleanliness).
- `what-did-i-get-done`, `weekly-review`, `workflow-from-chats` — work-summary and preference-mining utilities.

Adaptations from cursor primitives → Claude Code primitives (frontmatter, subagent invocation, tool references, rule-fragment handling) are documented in [`plugins/cursor-team-kit/PORTING-NOTES.md`](plugins/cursor-team-kit/PORTING-NOTES.md).

Install: `/plugin install cursor-team-kit@bdigital-public`. Source lives at [`plugins/cursor-team-kit/`](plugins/cursor-team-kit/) and the README at [`plugins/cursor-team-kit/README.md`](plugins/cursor-team-kit/README.md).

## Current samples

### `samples/pr-review/`

A drop-in GitHub Actions workflow and five Claude skill files that
implement five of the review categories from the blog series:

1. Correctness and logic bugs
2. Test adequacy
3. Design fit and over-engineering
4. Readability (naming, comments, complexity)
5. Breaking-change and public-contract impact

Each skill is frontmatter plus seven named sections — detection rules,
exclusion categories, evidence requirement, scope filter, output format,
plus an `## Examples` section with one positive and one negative inline
reference case. The sample also ships
[`samples/pr-review/evals/`](samples/pr-review/evals/) (one JSON fixture
per skill, 3–5 labeled cases each) and
[`samples/pr-review/scripts/run-evals.mjs`](samples/pr-review/scripts/run-evals.mjs),
an Executor/Grader runner that defaults to Sonnet 4.6 for execution and
Haiku 4.5 for grading so the two roles sit on different model tiers.

See [`samples/pr-review/README.md`](samples/pr-review/README.md) for setup,
required secrets, and customization notes.

### `samples/session-handoff/`

The read-the-source view of the session-handoff plugin. `SKILL.md` is
byte-identical to the copy shipped in `plugins/session-handoff/`
(verified by a shared structural test runner). Three scenario fixtures
live under `tests/scenarios/` — trivial session (expected short-circuit),
multi-feature (rich handoff across threads), and deep debugging (rich
handoff with dead ends) — alongside a 36-assertion
`tests/test-skill-structure.sh` covering frontmatter shape, required
sections, guardrail phrases, anti-patterns, prompt template, and a
500–1500 word budget.

### `samples/cc-context-monitor/`

The read-the-source view of the cc-context-monitor plugin. Ships with
`tests/test-skill-structure.sh` (frontmatter shape, security invariants,
color threshold references, `plugin.json` validity) and `evals/` (five
behavioral cases against the statusline wrapper: 0%, 55%, 75%, 92%, and
float-percent ingestion).

## The landing page

`site/` is a minimal Astro project that renders a static landing page
linking to the samples and the blog series. It deploys to Cloudflare
Workers via Wrangler. The structure mirrors the production site (Space
Grotesk + Inter fonts, zinc palette, dark theme) so it can serve as a
starter template for a companion docs site.

```bash
cd site
npm install
npm run dev       # local dev server on :4321
npm run build     # static build
npm run deploy    # wrangler deploy
```

## Trust model for external plugins

`/plugin install` executes instructions and grants tools from a git repo
you did not author — operationally it is close to `curl | bash`. Two
things in this repo push back on that:

- `CONTRIBUTING.md` requires SHA-pinning for any `marketplace.json` entry
  whose `source` is an external git URL. In-repo plugins (`./plugins/...`)
  are gated by PR review instead.
- Each plugin README carries its own "what this plugin does / does not do"
  section plus a pre-install verification checklist (owner check, skill
  namespace, read the shell scripts before running).

## Related reading

- [Part 1: Designing automated PR reviews with Claude Skills](https://tech.bdigitalmedia.io/blog/designing-ai-pr-review-claude-skills)
- [Part 2: Diagnosing false positives in AI code review](https://tech.bdigitalmedia.io/blog/diagnosing-ai-review-false-positives)
- [Part 3: Four fix patterns for AI code review (and the AI-auditing-AI problem)](https://tech.bdigitalmedia.io/blog/ai-code-review-fix-patterns)

## Contributing

Issues and pull requests welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for
guidance on code style, skill authoring, and the review process.

## Security

To report a security issue in this repository, see [SECURITY.md](SECURITY.md).
Please do not open a public issue for security-sensitive disclosures.

## License

[MIT](LICENSE). Use these samples in commercial or personal projects without
attribution requirements beyond the standard MIT copyright notice.
