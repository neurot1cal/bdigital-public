# Changelog

All notable changes to this repository are documented here. Format loosely
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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
