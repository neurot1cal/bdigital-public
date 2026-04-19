# Changelog

All notable changes to this repository are documented here. Format loosely
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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
