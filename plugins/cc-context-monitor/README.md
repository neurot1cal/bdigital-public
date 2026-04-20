# cc-context-monitor plugin

A Claude Code plugin that ships a color-coded statusline plus a single
user-invocable skill: **cc-context-monitor**. The statusline surfaces
three numbers you want to see on every turn:

1. **Context window usage.** Percent of the 1M-token window this session
   has consumed, read from the transcript JSON that Claude Code passes
   into the statusline hook on stdin.
2. **Session token usage.** Rolling input + output + cache-read +
   cache-creation tokens for this session. Distinct from the context
   percent; this is the running cost-style total.
3. **Weekly token usage.** Rolling 7-day token total across every
   session on this machine. Useful for staying inside a subscription
   quota.

The renderer delegates accounting to
[`ccusage`](https://github.com/ryoppippi/ccusage) and layers a
three-band color prefix on top:

- **green** for 0 to 60 percent of the context window
- **yellow** for 61 to 80 percent
- **red** for 81 percent and up

Any trailing annotation the user composes via
`CC_STATUSLINE_ANNOTATION` (for example "Remote control active") is
preserved after the main segment, so the wrapper composes with other
setups rather than clobbering them.

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
on your machine. The skill installs the `ccusage` dependency if
missing, backs up `~/.claude/settings.json` with a timestamped copy,
wires `statusLine.command` to this plugin's `statusline.sh`, and
confirms the change. Phrases like "install ccusage", "configure
statusline", or "show my weekly usage" also trigger the skill.

To update later: `/plugin marketplace update bdigital-public`.
To remove the plugin: `/plugin uninstall
cc-context-monitor@bdigital-public` (use the marketplace-qualified
form so the command is unambiguous across marketplaces).

To revert the statusline change without uninstalling, restore from the
timestamped backup the skill wrote alongside `settings.json`:

```
cp ~/.claude/settings.json.backup-YYYY-MM-DDTHH-MM-SS ~/.claude/settings.json
```

## What it does

After install, every Claude Code session shows a single line at the
bottom of the terminal that looks roughly like:

```
ctx 37% (green) | Opus | $1.23 session / $14.80 today / $72.10 block | 320,501 (32%)
```

The color changes as the context window fills. At 75 percent the
prefix goes yellow; at 85 percent it goes red. The `ctx n% (color)`
prefix renders first so a quick glance at the bottom-left tells you
how much context budget you have.

The skill also provides a one-shot action: ask "show my weekly
usage" and it runs `ccusage weekly --json` and summarizes the result
in plain text. This is useful before starting a long task you suspect
might blow past a quota.

## Why a plugin (vs. configuring the statusline yourself)

You can point `statusLine.command` directly at `npx ccusage
statusline` and get the same three numbers. This plugin adds three
things on top of that:

1. Color bands on the context percent so the number is preloaded with
   meaning rather than read as a digit.
2. An install procedure that always backs up `settings.json` before
   editing, so a mistake is recoverable.
3. Composition with an existing right-side annotation. If you
   already set `CC_STATUSLINE_ANNOTATION` for something else, this
   wrapper appends rather than replacing.

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
|-- statusline.sh                        # the wrapper Claude Code runs on every turn
`-- skills/
    `-- cc-context-monitor/
        `-- SKILL.md                     # the user-invocable configuration skill
```

The `skills/<name>/SKILL.md` layout is the standard Claude Code plugin
shape. A single plugin can ship any number of skills, agents, hooks,
or MCP servers from the same manifest; this one ships one skill plus
one shell script, by design.

## Customizing

Fork this repo, edit `statusline.sh` or the skill's procedure, then
point `/plugin marketplace add` at your fork instead. Common knobs:

- **Color thresholds.** Override at runtime via
  `CC_CTX_GREEN_MAX=70 CC_CTX_YELLOW_MAX=90` in the environment of the
  shell that renders the statusline. Permanent change: edit the two
  default values at the top of `statusline.sh`.
- **Right-side annotation.** Set `CC_STATUSLINE_ANNOTATION` in your
  shell profile to have an always-on label appended after the main
  segment.
- **Ccusage flags.** Edit the single line in `statusline.sh` that
  calls `ccusage statusline` to pass alternative flags (for example
  `--cost-source cc` if you prefer Claude Code's own cost accounting).

The script is under 150 lines and the skill is one markdown file. Both
are readable top to bottom.

## Tools this plugin grants

`SKILL.md` declares `allowed-tools: Bash, Read, Write, Edit`.
Concretely, when `/cc-context-monitor` fires:

- **Bash** runs `npm install -g ccusage` if ccusage is missing, plus
  read-only checks like `command -v ccusage` and `jq '.statusLine'`
  against the user's settings.
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
runs with no elevated permission; it only reads stdin and the
transcript file ccusage already reads.

## Trust model

`/plugin install` is equivalent in spirit to `curl | bash`: you load
executable instructions (SKILL.md plus the shell script) and tool
grants from a git repo you did not author. Here is what you are
opting into when you install this plugin specifically, and what is
worth checking before you install any plugin.

### What this plugin does

- Optionally runs `npm install -g ccusage` when the skill action fires
  and ccusage is missing.
- Writes one file: `~/.claude/settings.json` (with a timestamped
  backup of the prior contents alongside it).
- Runs `ccusage statusline --offline` on every terminal turn via the
  configured `statusLine.command`. `--offline` means ccusage uses its
  bundled pricing table rather than making a network call on every
  render.
- Reads the Claude Code transcript file whose path arrives on stdin
  from Claude Code itself. The path is never executed, only read.

### What this plugin does not do

- No network requests from the statusline wrapper itself. Ccusage
  under `--offline` is the upstream dependency's responsibility; it
  does not phone home on every render.
- No writes outside `~/.claude/`.
- No use of `eval`, no `source`ing untrusted input, no shell-substituting
  the transcript path.
- No credentials, tokens, or secrets read, transmitted, or logged.

### Verifying you are installing the real thing

1. Run `/plugin marketplace add neurot1cal/bdigital-public`. Note the
   **neurot1cal** owner. Any other owner is a typosquat.
2. After install, the skill appears as
   `cc-context-monitor:cc-context-monitor`. The namespace before the
   colon is the plugin name; a different namespace means a different
   marketplace's plugin is loaded.
3. Read the committed `statusline.sh` and `SKILL.md` before
   installing. The script is under 150 lines; the skill is one
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

- [`ccusage`](https://github.com/ryoppippi/ccusage) is the upstream
  npm package this plugin wraps. The statusline segment format, the
  session/daily/weekly accounting, and the cost calculations are its
  work.
- [`samples/cc-context-monitor/README.md`](../../samples/cc-context-monitor/README.md)
  is the source-reading view of the same plugin, with structural
  tests and an eval suite.
