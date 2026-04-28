# cc-context-monitor plugin

A Claude Code plugin that ships an info-dense, color-banded statusline
plus a single user-invocable skill: **cc-context-monitor**.

```
~/git/bdigital-public | feat/branch* | Opus 4.7 (1M context) | ●●○○○○○○○○ 18% ctx | ●●○○○○○○○○ 20% 5h | ●●●●●○○○○○ 54% 7d
```

The bottom-of-terminal line surfaces six signals at a glance:

1. **Current working directory** — home-relative (`~/...`) in cyan.
2. **Git branch** — in magenta, with a trailing `*` when the working
   tree is dirty. Omitted when cwd is not inside a git repo.
3. **Model label** — taken from Claude Code's own `display_name`
   field, e.g. `Opus 4.7 (1M context)`.
4. **Context window fill** — 10-dot bar plus percent. Color-banded:
   **green** under 50%, **yellow** under 75%, **red** at 75% and up.
5. **5-hour session quota** — same 10-dot + percent layout, same
   color bands. This is the rolling rate-limit window Anthropic
   enforces on Claude subscriptions.
6. **7-day weekly quota** — same layout, same bands. The one to watch
   for long stretches of heavy use.

Three bars with one shared palette lets you spot where pressure is
coming from with a single glance — context fullness, session burn, or
weekly quota. Any trailing annotation the user composes via
`CC_STATUSLINE_ANNOTATION` (for example "Remote control active") is
preserved after the main segment, so the wrapper composes rather than
clobbers.

## How the signals flow

Claude Code v2.1.x and newer pipes a rich JSON blob into the
`statusLine.command` script on every assistant turn. That blob
already carries everything the statusline needs:

- `model.display_name` → the pre-formatted model label
- `cwd` → the directory segment
- `context_window.used_percentage` → the ctx bar
- `rate_limits.five_hour.used_percentage` → the 5h bar
- `rate_limits.seven_day.used_percentage` → the 7d bar

No external tool is required on v2.1.x hosts — the wrapper reads
stdin with `jq`, formats, and prints. On older Claude Code versions
that do not expose `context_window` natively, the wrapper falls back
to `ccusage statusline` for the context percent only and skips the
5h / 7d bars.

## Install

Add this repository as a plugin marketplace, then install the plugin.
The shorthand `owner/repo` form works on recent Claude Code builds:

```
/plugin marketplace add neurot1cal/bdigital-public
/plugin install cc-context-monitor@bdigital-public
```

If your Claude Code version rejects the shorthand, pass the full Git
URL:

```
/plugin marketplace add https://github.com/neurot1cal/bdigital-public.git
/plugin install cc-context-monitor@bdigital-public
```

To iterate on a local fork before publishing, point at your working
tree:

```
/plugin marketplace add /absolute/path/to/bdigital-public
/plugin install cc-context-monitor@bdigital-public
```

Once installed, run `/cc-context-monitor` from any Claude Code session
on your machine. The skill backs up `~/.claude/settings.json` with a
timestamped copy, wires `statusLine.command` to this plugin's
`statusline.sh`, and confirms the change. Phrases like "configure
statusline", "show my weekly usage", or "context monitor" also
trigger the skill.

To update later: `/plugin marketplace update bdigital-public`.
To remove the plugin: `/plugin uninstall cc-context-monitor@bdigital-public`.

To revert the statusline change without uninstalling, restore from
the timestamped backup the skill wrote alongside `settings.json`:

```
cp ~/.claude/settings.json.backup-YYYY-MM-DDTHH-MM-SS ~/.claude/settings.json
```

## Troubleshooting

If the statusline does not appear after install, the diagnostic ladder
inside the skill resolves most cases. Inside Claude Code, just say
"my statusline isn't showing" or "the bottom bar is blank" and the
skill walks through the steps.

For OS- and terminal-specific edge cases (Windows / WSL2 / Git Bash,
JetBrains terminal ANSI bugs, tmux 256-color, font glyph issues),
see [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) at the plugin root.

## Why a plugin (vs. configuring the statusline yourself)

You can write your own bash script against the CC stdin contract and
point `statusLine.command` at it. This plugin packages three things
on top of that:

1. **Three color-banded dot bars** sharing one palette, so pressure
   anywhere (ctx, 5h, 7d) jumps out visually instead of being buried
   in a dollar-denominated string.
2. **An install procedure** that always backs up `settings.json`
   before editing, so a mistake is recoverable.
3. **Composition with any existing right-side annotation.** If you
   already set `CC_STATUSLINE_ANNOTATION` for something else, this
   wrapper appends rather than replaces.

The same source lives as readable code at
[`samples/cc-context-monitor/`](../../samples/cc-context-monitor/) for
anyone who wants to read it without installing anything. The plugin
package is for one-command install, version pinning, and updates
through `/plugin marketplace update`.

## What's inside

```
plugins/cc-context-monitor/
|-- .claude-plugin/
|   `-- plugin.json                      # plugin manifest (name, version, homepage)
|-- LICENSE                              # MIT, distributed with the plugin
|-- README.md                            # this file
|-- TROUBLESHOOTING.md                   # OS / terminal-specific diagnostics
|-- statusline.sh                        # the wrapper Claude Code runs on every turn
`-- skills/
    `-- cc-context-monitor/
        `-- SKILL.md                     # the user-invocable configuration + troubleshooting skill
```

The `skills/<name>/SKILL.md` layout is the standard Claude Code plugin
shape. A single plugin can ship any number of skills, agents, hooks,
or MCP servers from the same manifest; this one ships one skill plus
one shell script, by design.

## Customizing

Fork this repo, edit `statusline.sh` or the skill's procedure, then
point `/plugin marketplace add` at your fork instead. Common knobs:

- **Color thresholds.** Override at runtime via
  `CC_CTX_GREEN_MAX=40 CC_CTX_YELLOW_MAX=70` in the environment of
  the shell that renders the statusline. Permanent change: edit the
  two default values at the top of `statusline.sh`.
- **Bar width.** `CC_CTX_BAR_WIDTH=20` renders 20-dot bars instead
  of 10 for more resolution.
- **Right-side annotation.** Set `CC_STATUSLINE_ANNOTATION` in your
  shell profile to have an always-on label appended after the main
  segments.

The script is under 300 lines of straight-line bash and the skill is
one markdown file. Both are readable top to bottom.

## Tools this plugin grants

`SKILL.md` declares `allowed-tools: Bash, Read, Write, Edit`.
Concretely, when `/cc-context-monitor` fires:

- **Bash** runs read-only checks like `jq '.statusLine'` against the
  user's settings, plus an `ls` to locate the plugin install tree.
- **Read** reads `~/.claude/settings.json` to detect the current
  state before editing.
- **Write** writes the timestamped backup file
  (`~/.claude/settings.json.backup-<timestamp>`) and the updated
  `settings.json`.
- **Edit** is available for in-place updates when the skill decides
  only one field needs changing; in practice the procedure uses a
  read-merge-write pass via `jq` instead.

If that tool surface is broader than you want, fork the plugin and
narrow the `allowed-tools` frontmatter. The statusline script itself
runs with no elevated permission; it reads stdin and, as a fallback
on older CC hosts, invokes `ccusage statusline` via whatever binary
is already on the user's PATH.

## Trust model

`/plugin install` is equivalent in spirit to `curl | bash`: you load
executable instructions (SKILL.md plus the shell script) and tool
grants from a git repo you did not author. Here is what you are
opting into when you install this plugin specifically, and what is
worth checking before you install any plugin.

### What this plugin does

- Writes one file on configuration: `~/.claude/settings.json` (with
  a timestamped backup of the prior contents alongside it).
- Runs `statusline.sh` on every terminal turn via the configured
  `statusLine.command`. The script reads stdin, parses it with `jq`,
  and prints one line. It touches no other files.
- On legacy Claude Code versions, invokes `ccusage statusline
  --offline` as a fallback to derive the context percent when CC does
  not expose `context_window.used_percentage` on stdin.

### What this plugin does not do

- No network requests from the statusline wrapper itself. The
  fallback `ccusage statusline --offline` invocation (legacy CC only)
  uses ccusage's bundled pricing table rather than making a network
  call on every render.
- No writes outside `~/.claude/`.
- No use of `eval`, no `source`ing untrusted input, no
  shell-substituting the transcript path.
- No credentials, tokens, or secrets read, transmitted, or logged.

### Verifying you are installing the real thing

1. Run `/plugin marketplace add neurot1cal/bdigital-public`. Note the
   **neurot1cal** owner. Any other owner is a typosquat.
2. After install, the skill appears as
   `cc-context-monitor:cc-context-monitor`. The namespace before the
   colon is the plugin name; a different namespace means a different
   marketplace's plugin is loaded.
3. Read the committed `statusline.sh` and `SKILL.md` before
   installing. The script is under 300 lines; the skill is one
   markdown file. If anything instructs Claude to fetch URLs,
   exfiltrate files, or run shell commands beyond the read-only
   checks listed above, do not install.

### Staying safe installing any Claude Code plugin

- **Read the SKILL.md and any shell scripts.** `/plugin install` does
  not prompt you to review first. A 60-second read catches the
  obvious attacks.
- **Prefer pinned marketplaces.** External plugins should be
  SHA-pinned in `marketplace.json` so pushes to the upstream repo do
  not silently change what runs on your machine. See
  [CONTRIBUTING.md](../../CONTRIBUTING.md) for the shape this repo
  requires.
- **Do not click through permission prompts.** When Claude Code asks
  to run a tool a newly-installed skill requires, pause. A plugin
  that needs `WebFetch` on first invocation has earned a question.
- **Prefer project-scoped installs for untrusted plugins.** Adding a
  marketplace to a specific project's `.claude-plugin/` limits blast
  radius vs. a user-global install.

## License

MIT. See the [`LICENSE`](LICENSE) in this directory (distributed with
the plugin) or the [repo-root copy](../../LICENSE) on GitHub.

## Related reading

- Claude Code's [statusline hook
  contract](https://docs.anthropic.com/en/docs/claude-code/statusline)
  — the JSON schema the stdin blob follows.
- [`ccusage`](https://github.com/ryoppippi/ccusage) — the legacy
  fallback for context percent on Claude Code versions that do not
  yet expose `context_window.used_percentage` natively.
- [`samples/cc-context-monitor/README.md`](../../samples/cc-context-monitor/README.md)
  — the source-reading view of the same plugin, with structural
  tests and an eval suite.
