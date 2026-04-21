# Changelog

All notable changes to this repository are documented here. Format loosely
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Changed

- **cc-context-monitor 0.1.0 → 0.2.0**: rewrote `statusline.sh` to read
  directly from Claude Code's native stdin payload
  (`context_window.used_percentage`, `rate_limits.five_hour.used_percentage`,
  `rate_limits.seven_day.used_percentage`, `model.display_name`, `cwd`)
  on CC v2.1.x and newer. The output line now shows `cwd | branch* |
  model | ●●○○○○○○○○ NN% ctx | ●●○○○○○○○○ NN% 5h | ●●●●●○○○○○ NN% 7d`
  with three 10-dot bars sharing one green/yellow/red palette
  (thresholds 49 / 74). Dropped the dollar-denominated ccusage
  passthrough segment. Kept a `ccusage statusline` fallback for hosts
  predating the native stdin fields. Color thresholds, bar width, and
  annotation env vars are still overridable via `CC_CTX_GREEN_MAX`,
  `CC_CTX_YELLOW_MAX`, `CC_CTX_BAR_WIDTH`, `CC_STATUSLINE_ANNOTATION`.
  Structural tests, eval fixture, SKILL.md, and README.md updated to
  match.

### Added

- `## Examples` section added to every review skill in
  `samples/pr-review/.claude/skills/` with one positive and one negative
  inline reference case per skill. Skill shape is now "frontmatter plus
  seven named sections."
- `samples/pr-review/evals/` directory with one JSON fixture per skill
  (3–5 labeled cases each, positive and negative).
- `samples/pr-review/scripts/run-evals.mjs` implementing the Executor/
  Grader split from Anthropic's skill-creator toolkit. Executor defaults
  to Sonnet 4.6, Grader defaults to Haiku 4.5 so the two roles run on
  different model tiers by default.
- `samples/session-handoff/` — first user-invocable Claude Code skill
  in this repo. Generates a brief for resuming work in a fresh session
  after `/clear`. Ships with `SKILL.md`, `README.md`, three scenario
  fixtures under `tests/scenarios/`, an `evals/evals.json` behavioral
  eval fixture, and a 36-assertion structural test runner at
  `tests/test-skill-structure.sh` (frontmatter shape, required sections,
  guardrail phrases, anti-patterns, prompt template, 500–1500 word
  budget). PR #10.
- `.claude-plugin/marketplace.json` at the repo root, turning the
  repository into a Claude Code plugin marketplace. PR #11.
- `plugins/session-handoff/` — installable-plugin packaging of the
  session-handoff skill. Adds `.claude-plugin/plugin.json`, install
  README, and a `skills/session-handoff/SKILL.md` kept byte-identical
  to the `samples/` copy (verified by the existing 36-assertion
  structural test against the plugin path). Install via:
  `/plugin marketplace add neurot1cal/bdigital-public` then
  `/plugin install session-handoff@bdigital-public`. PR #11.
- **Trust model** section in `plugins/session-handoff/README.md`
  documenting what the plugin reads, writes, and does not do, plus a
  pre-install verification checklist and general safety guidance for
  any Claude Code plugin install. PR #12.

### Changed

- `CONTRIBUTING.md` now requires SHA-pinning for marketplace entries
  whose `source` is an external git URL. Bare-string `./plugins/...`
  is still acceptable for plugins vendored in this repo (mutation is
  gated by PR review). A future CI check will enforce this. PR #12.

## [0.1.0] - 2026-04-18

### Added

- Initial open-source scaffolding: `LICENSE` (MIT), `README.md`,
  `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, issue and pull
  request templates.
- `samples/pr-review/` sample that implements automated PR review using
  Claude skills. Five review skills are included at launch; additional
  categories may land over time.
- `site/` landing page built with Astro, Tailwind, and Cloudflare Workers
  deployment. Matches the visual language of the related engineering blog.
- GitHub Actions workflow that builds and type-checks the landing page on
  every PR.
