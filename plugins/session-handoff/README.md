# session-handoff plugin

A Claude Code plugin that ships a single user-invocable skill: **session-handoff**. It
generates a distilled brief so a fresh Claude Code session (after `/clear` or on a new
machine) can resume where the previous one left off. It implements the "Clear — start a
new session, usually with a brief you've distilled" pattern from [Anthropic's session
management guide](https://claude.com/blog/using-claude-code-session-management-and-1m-context).

## Install

Add this repository as a plugin marketplace, then install the plugin. The
shorthand `owner/repo` form works on recent Claude Code builds:

```
/plugin marketplace add neurot1cal/bdigital-public
/plugin install session-handoff@bdigital-public
```

If your Claude Code version rejects the shorthand, pass the full Git URL:

```
/plugin marketplace add https://github.com/neurot1cal/bdigital-public.git
/plugin install session-handoff@bdigital-public
```

To iterate on a local fork before publishing, point at your working tree:

```
/plugin marketplace add /absolute/path/to/bdigital-public
/plugin install session-handoff@bdigital-public
```

The skill is then available as `/session-handoff` in every Claude Code session
on your machine. Phrases like "handoff", "wrap up", or "session summary" will
also trigger it.

To update later: `/plugin marketplace update bdigital-public`.
To remove: `/plugin uninstall session-handoff@bdigital-public` (use the
marketplace-qualified form — if two marketplaces ship a plugin named
`session-handoff`, the bare command is ambiguous).

## What it does

At the end of a long session — debugging, multi-file changes, architectural decisions —
run `/session-handoff` and Claude produces a fenced markdown block you can paste into a
fresh session. The block captures:

- What you were doing (status per thread)
- Decisions made (with rationale)
- What didn't work (dead ends, so the next session doesn't repeat them)
- Key findings (non-obvious things learned)
- Next steps (prioritized pickup points)
- Current git state (branch, uncommitted summary)

It short-circuits with a one-line "nothing to hand off" message when the session had no
code changes, no decisions, and no in-flight work — no padded empty template.

## Why a plugin (vs. copying the SKILL.md)

The same skill lives as readable source at
[`samples/session-handoff/`](../../samples/session-handoff) for anyone who wants to read
it without installing anything. The plugin package is for one-command install, version
pinning, and updates through `/plugin marketplace update`.

## What's inside

```
plugins/session-handoff/
├── .claude-plugin/
│   └── plugin.json                      # plugin manifest (name, version, homepage)
├── LICENSE                              # MIT, distributed with the plugin
├── README.md                            # this file
└── skills/
    └── session-handoff/
        └── SKILL.md                     # the skill itself
```

The `skills/<name>/SKILL.md` layout is the standard Claude Code plugin shape. A single
plugin can ship any number of skills, agents, hooks, or MCP servers from the same
manifest — this one just ships one skill, intentionally.

## Customizing

Fork this repo, edit `plugins/session-handoff/skills/session-handoff/SKILL.md`, then
point `/plugin marketplace add` at your fork instead. The skill is plain markdown —
sections like "What Didn't Work" or "Key Findings" can be renamed or dropped by editing
the prompt template in Step 4 of `SKILL.md`.

## Tools this plugin grants

`SKILL.md` declares `allowed-tools: Bash, Read, Write, Edit, TaskList,
TodoWrite`. Concretely, when `/session-handoff` fires:

- **Bash** — runs read-only git commands (`git branch`, `git log`,
  `git status`, `git remote`) to snapshot the branch state.
- **Read** — reads project memory files under `~/.claude/projects/.../memory/`
  plus the handful of files the handoff tells the next session to read first.
- **Write** — writes one log file to `~/.claude/data/session-handoff/logs/`.
- **Edit** — updates existing memory files when Step 3 decides something is
  worth persisting long-term.
- **TaskList / TodoWrite** — checks for pending tasks (whichever tool your
  Claude Code build exposes; the skill skips this step if neither is
  available).

If that tool surface is broader than you want, fork the plugin, narrow the
`allowed-tools` frontmatter, and install from your fork.

## Trust model

`/plugin install` is equivalent in spirit to `curl | bash`: you load
executable instructions (SKILL.md) and tool grants (allowed-tools) from a
git repo you didn't author. Here's what you're opting into when you
install this plugin specifically, and what's worth checking before you
install any plugin.

### What this plugin does

- Reads git metadata (`git branch`, `git log`, `git status`, `git remote`)
  — all read-only, all local.
- Reads project memory files under `~/.claude/projects/<project>/memory/`
  if they exist.
- Writes one handoff-log markdown file per invocation to
  `~/.claude/data/session-handoff/logs/`.
- Optionally edits existing memory files when Step 3 of the procedure
  decides something is worth persisting long-term.
- Emits a markdown brief to the conversation.

### What this plugin doesn't do

- No network requests. `SKILL.md` never instructs Claude to fetch or
  POST.
- No destructive shell commands. The only `git` invocations are
  read-only snapshots; there are no `git push`, `rm`, or file-destructive
  operations in the procedure.
- No writes outside the single log directory and (optionally) existing
  memory files it was already instructed to update.
- No credentials, tokens, or secrets are read, transmitted, or logged.
  The skill explicitly refuses to include secrets in the brief (see the
  "What NOT to Include" section of `SKILL.md`).

### Verifying you're installing the real thing

1. Run `/plugin marketplace add neurot1cal/bdigital-public` — note the
   **`neurot1cal`** owner. Any other owner is a typosquat.
2. After install, the skill appears in the available-skills list as
   `session-handoff:session-handoff`. The namespace before the colon is
   the plugin name; if you see a different namespace, a different
   marketplace's plugin is loaded.
3. Read the committed SKILL.md at
   [`plugins/session-handoff/skills/session-handoff/SKILL.md`](skills/session-handoff/SKILL.md)
   before installing. It's plain markdown, ~160 lines. If anything
   instructs Claude to fetch URLs, exfiltrate files, or run shell
   commands beyond the read-only git operations listed above, do not
   install.

### Staying safe installing any Claude Code plugin

- **Read the SKILL.md.** `/plugin install` doesn't prompt you to review
  first. A 60-second read of the source catches the obvious attacks.
- **Prefer pinned marketplaces.** External plugins in a trustworthy
  marketplace should be SHA-pinned in `marketplace.json` so pushes to the
  upstream repo don't silently change what runs on your machine. See
  [CONTRIBUTING.md](../../CONTRIBUTING.md) for the shape this repo
  requires.
- **Don't click through permission prompts.** When Claude Code asks to
  run a tool a newly-installed skill requires, pause. A plugin that
  needs `WebFetch` on first invocation has earned a question.
- **Scope narrowly.** A plugin declaring `Bash, Write, WebFetch`
  simultaneously with no explanation in the README is a smell.
- **Prefer project-scoped installs for untrusted plugins.** Adding a
  marketplace to a specific project's `.claude-plugin/` limits blast
  radius vs. a user-global install.

## License

MIT. See the [`LICENSE`](LICENSE) in this directory (distributed with the
plugin) or the [repo-root copy](../../LICENSE) on GitHub.

## Related reading

- [Anthropic's session management guide](https://claude.com/blog/using-claude-code-session-management-and-1m-context) — the "Clear with a brief" pattern this plugin implements.
- [`samples/session-handoff/README.md`](../../samples/session-handoff/README.md) — the
  source-reading view of the same skill, with structural tests and scenario fixtures.
