# session-handoff plugin

A Claude Code plugin that ships a single user-invocable skill: **session-handoff**. It
generates a distilled brief so a fresh Claude Code session (after `/clear` or on a new
machine) can resume where the previous one left off. It implements the "Clear — start a
new session, usually with a brief you've distilled" pattern from [Anthropic's session
management guide](https://claude.com/blog/using-claude-code-session-management-and-1m-context).

## Install (one command)

Add this repository as a plugin marketplace, then install the plugin:

```
/plugin marketplace add neurot1cal/bdigital-public
/plugin install session-handoff@bdigital-public
```

That's it. The skill is now available as `/session-handoff` in every Claude Code session
on your machine. Phrases like "handoff", "wrap up", or "session summary" will also
trigger it.

To update later: `/plugin marketplace update bdigital-public`.
To remove: `/plugin uninstall session-handoff`.

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

## License

MIT. See [`LICENSE`](../../LICENSE) at the repo root.

## Related reading

- [Anthropic's session management guide](https://claude.com/blog/using-claude-code-session-management-and-1m-context) — the "Clear with a brief" pattern this plugin implements.
- [`samples/session-handoff/README.md`](../../samples/session-handoff/README.md) — the
  source-reading view of the same skill, with structural tests and scenario fixtures.
