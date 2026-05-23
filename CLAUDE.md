# bdigital-public — CLAUDE.md

Operational rules for working in this repo. Read this before authoring or
editing a skill.

## Skill layout standard (openskills-first)

This repo ships skills under two paths that must stay byte-identical:

```
plugins/<plugin-name>/skills/<skill-name>/SKILL.md   ← canonical (you edit here)
skills/<skill-name>/SKILL.md                         ← mirror (auto-generated, openskills install target)
```

`npx openskills install neurot1cal/bdigital-public` discovers skills at the
repo-root `/skills/` path. `/plugin install <name>@bdigital-public` (Claude
Code marketplace flow) discovers them at the `plugins/<plugin>/skills/` path.
We support **both** install paths. The repo-root mirror is the preferred
install path for portability across agents (Cursor, Windsurf, Aider, etc.);
the Claude Code marketplace path is preserved for users who want the full
plugin bundle (LICENSE, plugin.json, tests, agents).

## When you add or edit a skill

1. Author or edit `plugins/<plugin>/skills/<name>/SKILL.md` (canonical).
2. If the skill has sibling resources (`scripts/`, `references/`,
   `assets/`, `template.html`, etc.), put them next to the canonical SKILL.md.
3. Run `node scripts/sync-skills.mjs`. The script regenerates the repo-root
   `skills/<name>/` mirror byte-identical to the canonical.
4. Commit both paths.
5. CI (`.github/workflows/skills-sync-check.yml`) runs the script in
   `--check` mode on every PR. The check fails on any drift, orphan, or
   name collision.

**Never edit `skills/<name>/SKILL.md` directly.** Always edit the canonical
copy under `plugins/<plugin>/skills/<name>/SKILL.md` and re-run the sync
script.

## Name uniqueness

Skill names must be globally unique across all plugins in this repo. The
sync script aborts on collision. If two plugins want to ship a skill
called `deslop`, rename one (e.g. `deslop` in `cursor-team-kit` for code
slop vs `deslop-tech-comms` in `writing-kit` for prose slop).

## Required files per plugin (mirrors peer plugins)

Every plugin under `plugins/<name>/` ships:

```
plugins/<name>/
├── .claude-plugin/
│   └── plugin.json           # name, description, version, category, author, homepage, license
├── LICENSE                   # MIT (or upstream license if a port + bdigital port copyright preserved)
├── README.md                 # install + design overview + non-goals
└── skills/<name>/
    └── SKILL.md              # YAML frontmatter (name, description, user-invocable) + body
```

`plugin.json` must be valid JSON. The marketplace entry in
`.claude-plugin/marketplace.json` must match the plugin's `name` field. The
LICENSE file must be reachable from the plugin root.

## Required content of SKILL.md frontmatter

```yaml
---
name: <kebab-case-skill-name>           # must match the parent directory name
description: <one-paragraph, narrow trigger words, mention surface names>
user-invocable: true                    # if the skill should be exposed as a slash command
allowed-tools: Read, Write, Edit, Bash  # only what the skill actually needs
---
```

## Skill content guidelines

- **Self-contained.** SKILL.md should not require the reader to open another
  file to understand what the skill does. Sibling resources are referenced
  by name with a one-line description of their purpose.
- **Anthropic-spec compliant.** Same frontmatter shape as
  [`anthropics/skills`](https://github.com/anthropics/skills) (name +
  description required, other fields optional).
- **Voice.** Follow `~/.claude/SOUL.md` rules in user-facing prose: no
  "matters", no em-dashes in shipped content, no fragment clusters, no
  buzzwords (leverage / utilize / facilitate / robust without specifics /
  cutting-edge / synergy / turnkey / paradigm shift). The `writing-kit`
  plugin's `thermo-nuclear-writing-review` is the canonical reference for
  the full ban list.

## Pre-commit checklist

Before opening a PR that adds or modifies a skill:

- [ ] `node scripts/sync-skills.mjs` ran without errors
- [ ] `node scripts/sync-skills.mjs --check` exits 0
- [ ] `.claude-plugin/plugin.json` is valid JSON (`python3 -c "import json; json.load(open(...))"`)
- [ ] Plugin LICENSE is present and reachable
- [ ] Marketplace entry name matches plugin.json name
- [ ] PR title uses conventional-commit format
  (`plugin(<name>):`, `skill(<name>):`, `ci:`, `docs:`, etc. — see
  `.github/PULL_REQUEST_TEMPLATE.md`)
- [ ] PR body includes `## Checklist` section (the pr-hygiene check enforces this)

## Install paths supported

| Audience | Command | What it pulls |
|---|---|---|
| Claude Code users (full bundle) | `/plugin marketplace add neurot1cal/bdigital-public` then `/plugin install <name>@bdigital-public` | Plugin including agents, LICENSE, tests, etc. |
| Cursor / Windsurf / Aider / other agents | `npx openskills install neurot1cal/bdigital-public` | Discovers all skills at repo-root `skills/<name>/` |
| Single skill, any agent | `npx openskills install neurot1cal/bdigital-public --skill <name>` | One skill (if the openskills CLI supports the flag — check version) |
| Direct, no installer | `git clone https://github.com/neurot1cal/bdigital-public.git` + symlink `skills/<name>/` into `~/.claude/skills/` | Always works |

## When to use `samples/` vs `skills/`

- `skills/<name>/` — the openskills-discoverable mirror. **Auto-generated.**
  Do not edit by hand.
- `samples/<name>/` — read-the-source view for blog posts, eval fixtures,
  test infrastructure. **Hand-maintained.** May contain a hand-authored
  `SKILL.md` that drifts from the plugin canonical *intentionally* (e.g.
  for a blog post that calls out specific lines). Document any intentional
  drift in `samples/<name>/README.md`.
- `plugins/<name>/` — canonical plugin bundle. Source of truth for the
  SKILL.md content shipped to users.

## Related

- Anthropic skills standard: [agentskills.io](https://agentskills.io)
- openskills CLI: [github.com/numman-ali/openskills](https://github.com/numman-ali/openskills)
- This repo's marketplace manifest:
  [`.claude-plugin/marketplace.json`](./.claude-plugin/marketplace.json)
