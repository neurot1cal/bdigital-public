# bdigital-public

Public code samples that accompany the bdigital media engineering blog.
Examples are extracted from real projects, generalized, and reduced to the
minimum shape needed to be useful without shipping proprietary context.

This repo doubles as a Claude Code plugin marketplace: skills ship twice —
once under `samples/` for reading and once under `plugins/` for installing.

## What lives here

```
bdigital-public/
├── .claude-plugin/
│   └── marketplace.json        # Makes this repo a Claude Code plugin marketplace
├── plugins/                    # Installable plugins (one-command install via /plugin)
│   ├── session-handoff/        # Brief-generating skill for the /clear-then-resume workflow
│   └── cc-context-monitor/     # Three-bar color-banded statusline: ctx / 5h / 7d
├── samples/                    # Read-the-source versions (copy into your own repo)
│   ├── pr-review/              # Claude-skills-based automated PR review + eval runner
│   ├── session-handoff/        # Same skill as plugins/session-handoff, with tests + evals
│   └── cc-context-monitor/     # Same plugin as plugins/cc-context-monitor, with tests + evals
├── site/                       # Astro landing page (Cloudflare Workers)
└── .github/                    # Open-source workflows, templates, ownership
```

`samples/` is for readers who want to study or copy code; `plugins/` is for
readers who want to install and use. Both coexist so you can pick whichever
matches your intent — and blog posts can link to either.

## Install a plugin

This repo is itself a Claude Code plugin marketplace. Inside Claude Code:

```
/plugin marketplace add neurot1cal/bdigital-public
/plugin install session-handoff@bdigital-public
/plugin install cc-context-monitor@bdigital-public
```

If your Claude Code build rejects the shorthand, use the full Git URL
(`https://github.com/neurot1cal/bdigital-public.git`) or a local-path
pointing at a checkout of this repo. Each plugin's own README documents
its full install matrix, tools granted, and trust model:

- [`plugins/session-handoff/README.md`](plugins/session-handoff/README.md)
- [`plugins/cc-context-monitor/README.md`](plugins/cc-context-monitor/README.md)

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
