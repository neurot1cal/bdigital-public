# Contributing

Thanks for your interest in contributing. This repository hosts public code
samples that accompany the bdigital media engineering blog. Contributions
should keep each sample self-contained, generalized, and useful to readers who
arrive here from a blog post without further context.

## What makes a good contribution

- **A new sample tied to a blog post.** If a new engineering-blog post would
  benefit from a runnable example, open an issue first with a link to the draft
  (or a short outline) and the proposed directory layout.
- **A generalization of an existing sample.** If you spot company-specific,
  proprietary, or personal content that slipped into a sample, a PR removing it
  is always welcome.
- **A new review skill for `samples/pr-review/`.** The `.claude/skills/`
  directory is a good place for community-contributed review skills that
  complement the six starter skills. See the skill-authoring guide below.
- **Bug fixes.** Typos, broken links, stale references, CI failures.

## Before you start

Open an issue for anything beyond a small fix. That lets us discuss scope
before code lands. Issue templates are in `.github/ISSUE_TEMPLATE/`.

## Pull request process

1. Fork the repo and create a feature branch from `main`.
2. Keep the PR focused. One sample, one bugfix, one skill per PR.
3. Follow the file-and-naming conventions of the sample you are modifying.
4. Confirm the site still builds if you touched `site/`.
5. Fill in the PR template so the reviewer has enough context.

### PR title format

Titles must use conventional-commit prefixes. The `pr-hygiene` GitHub
Action blocks the merge until the title matches. Allowed types:

| Prefix      | Use when                                            |
|-------------|------------------------------------------------------|
| `feat:`     | New user-facing capability                           |
| `fix:`      | Bug fix                                              |
| `build:`    | Dependency bumps, build-system changes (Dependabot)  |
| `chore:`    | Tooling, non-functional maintenance                  |
| `docs:`     | Documentation-only                                   |
| `sample:`   | Change to anything under `samples/`                  |
| `skill:`    | Change to a review skill under `.claude/skills/`     |
| `site:`     | Change to the Astro landing page under `site/`       |
| `ci:`       | GitHub Actions workflow or CI-adjacent config        |
| `refactor:` | Structure change without behavior change             |
| `test:`     | Test-only change                                     |

The subject after the prefix must start with a lowercase letter or number
and be descriptive. Example: `skill: tighten scope filter for config-only PRs`.

### PR body format

The body must include `## Summary` and `## Checklist` sections from the PR
template, and at least one checklist item must be ticked. The `pr-hygiene`
check enforces this automatically.

All PRs are subject to the repo's own AI PR review workflow (see
`.github/workflows/pr-review.yml`). Findings appear as review comments; they
are advisory, not blocking.

## Code style

- JavaScript/TypeScript: Prettier defaults, double quotes, trailing commas in
  multi-line literals.
- Astro components: scope styles to the component, prefer Tailwind utility
  classes over custom CSS.
- Markdown: no trailing whitespace, one top-level H1 per file, fenced code
  blocks with language identifiers.

Deterministic style issues are handled by tooling, not by LLM review skills.
If a formatter disagrees with a style note, the formatter wins.

## Skill-authoring guide (for `samples/pr-review/`)

Every review skill in this repo has the same shape: frontmatter plus six
named sections. Please match it so the bulk-editing and cluster-analysis
workflows described in the blog series keep working.

1. **Frontmatter** with `name`, `description`, and optional `tags`.
2. **System prompt** setting the reviewer's role in one to three sentences.
3. **Detection rules**: bulleted list of what to flag, each with a concrete
   example.
4. **Exclusion categories**: five to six named categories, each with examples,
   grouped by reason rather than by individual file name.
5. **Evidence requirement**: explicit verification gate, ending with "silence
   is correct when evidence is unavailable."
6. **Scope filter**: deterministic path-based early exit.
7. **Output format**: JSON shape the skill must emit, matching
   `{ skill, severity, file, line, rationale, evidence }`.

Keep skills short. Any skill longer than about 200 lines usually has two
responsibilities and should split.

## Licensing

By submitting a contribution, you agree to license it under the repository's
MIT license. Do not include code from sources that are incompatible with MIT,
and do not include third-party assets (fonts, images, icons) without
confirming their license.

## Questions

Open an issue with the `question` label. Responses happen on a best-effort
basis, typically within a week.
