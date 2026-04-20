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
| `plugin:`   | Change to an installable plugin under `plugins/` or to `.claude-plugin/marketplace.json` |
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

Every review skill in this repo has the same shape: frontmatter plus seven
named sections. Please match it so the bulk-editing and cluster-analysis
workflows described in the blog series keep working.

1. **Frontmatter** with `name`, `description`, and optional `tags`.
2. **System prompt** setting the reviewer's role in one to three sentences.
3. **Detection rules**: bulleted list of what to flag, each with a concrete
   example.
4. **Examples**: two or three inline reference cases, each a small diff
   paired with an expected finding (or `[]` for a negative case). Keep
   the count small; the full labeled corpus lives in the eval fixture,
   not here.
5. **Exclusion categories**: five to six named categories, each with examples,
   grouped by reason rather than by individual file name.
6. **Evidence requirement**: explicit verification gate, ending with "silence
   is correct when evidence is unavailable."
7. **Scope filter**: deterministic path-based early exit.
8. **Output format**: JSON shape the skill must emit, matching
   `{ skill, severity, file, line, rationale, evidence }`.

Each new skill also gets a fixture at `samples/pr-review/evals/<skill>.json`
with 3–5 labeled cases, and is verified by `scripts/run-evals.mjs`
before merge. Include both the inline Examples (duplicated in the
fixture) and additional edge cases that stress scope filters and
exclusion categories.

Keep skills short. Any skill longer than about 200 lines usually has two
responsibilities and should split.

## Plugin-authoring guide (for `plugins/`)

The repo is a Claude Code plugin marketplace. Each directory under `plugins/`
is one installable plugin, discovered via the top-level
`.claude-plugin/marketplace.json` manifest. Add a new plugin only when it has
a companion blog post or a clearly articulated standalone use case — plugins
are a publication contract, not a staging area for experiments.

1. **Layout.** Match the existing shape:
   ```
   plugins/<plugin-name>/
   ├── .claude-plugin/plugin.json     # name, version, description, author, license
   ├── README.md                      # install command + what the plugin does
   ├── LICENSE                        # copy of the MIT license — must be distributable with the plugin
   └── skills/<skill-name>/SKILL.md   # the skill(s) the plugin ships
   ```
   The `name` in `plugin.json` must match the `name` in the marketplace
   entry. Different marketplaces can ship plugins with the same name, so
   user-facing install and uninstall commands should always be qualified
   (`session-handoff@bdigital-public`).

2. **Marketplace entry.** Add a block to `.claude-plugin/marketplace.json`
   with `name`, `description`, `category`, `source: "./plugins/<name>"`,
   and `homepage`. The bare-string `source` form is only acceptable for
   plugins vendored in this repo — the source gets resolved relative to a
   git-tracked marketplace checkout, so mutation is gated by a PR here.

   **External plugins MUST pin a SHA.** Any marketplace entry whose
   `source` is an external git URL must use the object form with both
   `url` and `sha`:

   ```json
   {
     "name": "example-plugin",
     "source": {
       "source": "url",
       "url": "https://github.com/someone/example-plugin.git",
       "sha": "a1b2c3d4e5f6..."
     }
   }
   ```

   Without the `sha`, a subsequent push to the external repo silently
   changes what every installed user pulls on `/plugin marketplace
   update` — a standard supply-chain attack vector. Bumping the SHA for a
   new upstream release is a normal PR to this repo and goes through the
   same review as any other change. A CI check (to be added) will reject
   external-URL entries missing a `sha`.

3. **Duplication policy.** If a plugin also ships as a readable sample under
   `samples/`, the `SKILL.md` files at the two paths must stay byte-identical.
   The `session-handoff` CI job enforces this via `diff -q`. Either keep the
   sample as the canonical copy and vendor it into the plugin, or vice
   versa — just don't let them drift.

4. **`allowed-tools`.** Scope tightly. User-invocable skills granted broad
   `Bash` + `Write` access run with those tools any time the skill fires.
   Prefer the narrowest set the procedure actually uses and note it in the
   plugin README so installers can make an informed decision.

5. **User data paths.** Skills that persist state between sessions should
   write under `~/.claude/data/<plugin-name>/` rather than
   `~/.claude/skills/<name>/` or `~/.claude/plugins/…`. The first is a
   stable user-data directory; the second and third are managed by the
   Claude Code installer and can be overwritten on reinstall.

6. **Verification.** Before opening the PR, confirm:
   - `python3 -m json.tool` passes on both `.claude-plugin/marketplace.json`
     and `plugins/<name>/.claude-plugin/plugin.json`.
   - The plugin's structural test suite (if it has one) passes.
   - `/plugin marketplace add /path/to/your/fork` and `/plugin install
     <name>@bdigital-public` work end-to-end from a clean Claude Code
     session.
   - CI drift checks pass (the `session-handoff` job is a template for
     other plugins that ship alongside a `samples/` copy).

## Licensing

By submitting a contribution, you agree to license it under the repository's
MIT license. Do not include code from sources that are incompatible with MIT,
and do not include third-party assets (fonts, images, icons) without
confirming their license.

## Questions

Open an issue with the `question` label. Responses happen on a best-effort
basis, typically within a week.
