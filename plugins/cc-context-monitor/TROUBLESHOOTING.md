# cc-context-monitor — troubleshooting

The statusline is shaped like a small UNIX pipe: `/plugin install` puts files
on disk, `/cc-context-monitor` writes one line to `~/.claude/settings.json`,
and Claude Code pipes a JSON payload into `statusline.sh` on every assistant
turn. When the line does not appear, one of those three handoffs broke.

The 7-step diagnostic ladder in
[`skills/cc-context-monitor/SKILL.md`](skills/cc-context-monitor/SKILL.md#troubleshooting)
resolves the common cases. This file covers the long tail: OS-specific
install gotchas, terminal-specific render glitches, and harder edge cases.

If you are running inside Claude Code, the skill already knows the ladder.
Just say "my statusline isn't showing" or "the bottom bar is blank" and
Claude will walk through the diagnostics. This file is for human readers
who want the deeper reference.

## Quick triage table

| Symptom | Most likely cause | Fix |
|--------|---------|---------|
| No statusline at all | Skill never ran, or CC not relaunched after install | Run `/cc-context-monitor`, then quit and relaunch CC |
| `cc-context-monitor: no statusline input` | CC version does not pipe stdin to statusline hook | Upgrade CC to v2.1.x+ |
| `ctx n/a` segment | CC < v2.1.x and `ccusage` not installed | `npm i -g ccusage` or upgrade CC |
| Garbled box-drawing characters | Terminal not rendering UTF-8 (●○ are U+25CF / U+25CB) | Set UTF-8 font and `LANG=*.UTF-8` |
| Colors look gray / monochrome | `TERM` is `xterm` or `screen` instead of `*-256color` | `export TERM=xterm-256color` |
| Bars wrap to next line | Terminal too narrow | `CC_CTX_BAR_WIDTH=5` |
| Yellow band invisible | Light theme contrast issue | `CC_CTX_GREEN_MAX=40` or change theme |
| Shows once then disappears | Hook erroring on real CC payload | Enable `CC_CTX_DEBUG=1`, inspect `/tmp/cc-context-monitor.stdin.json` |
| Path-not-found errors | Marketplace added by full Git URL → cache path mismatch | Re-run `/cc-context-monitor` |
| Renders correctly with fake payload, not in CC | Wrong settings.json wiring or stale CC session | Re-run `/cc-context-monitor`, then relaunch CC |

## Operating systems

### macOS

The default install path. `jq` install: `brew install jq`. Default shell is
zsh on macOS 10.15+; CC runs the hook in `bash` regardless via the script's
shebang, so user shell choice does not matter. Settings live at
`~/.claude/settings.json`.

If you previously installed `jq` via MacPorts or built from source, make
sure `/opt/homebrew/bin/jq` (Apple Silicon) or `/usr/local/bin/jq` (Intel)
is on the PATH that CC inherits.

### Linux (Ubuntu / Debian / Fedora / Arch)

`jq` install:

- Debian / Ubuntu: `sudo apt install jq`
- Fedora / RHEL: `sudo dnf install jq`
- Arch: `sudo pacman -S jq`

The plugin is path-portable; nothing in the script is macOS-specific.
Locale must be UTF-8 capable for the dot glyphs to render — verify with
`locale | grep -i utf` and set `LANG=en_US.UTF-8` (or another UTF-8 locale)
in your shell profile if missing.

### Windows (WSL2)

Recommended Windows configuration. CC runs inside the WSL2 distro;
`~/.claude/` is the Linux home directory (e.g. `/home/<user>/.claude`),
not `C:\Users\<user>\.claude`. The Windows-side file is unrelated. Treat
the WSL2 distro exactly like its base Linux distribution above for
package installs.

If your Windows Terminal profile does not include a Unicode font, the
dot glyphs render as `??` even though the script ran fine. Pick Cascadia
Code, JetBrains Mono, or MesloLGS NF.

### Windows (Git Bash / MSYS2)

Works, but `jq` is not in the default Git Bash install. Install via:

```
pacman -S mingw-w64-x86_64-jq
```

or via [scoop](https://scoop.sh/): `scoop install jq`. The bash shebang
resolves correctly under Git Bash.

### Windows (PowerShell / cmd, no WSL)

Not supported. The statusline script is bash. Install WSL2 or Git Bash
and run CC inside one of those.

## Terminal emulators

### iTerm2 (macOS)

Works out of the box. If colors render dim, check Profiles → Colors →
Color Presets. Some custom palettes flatten ANSI 32 / 33 / 31 toward
gray. Default or any high-contrast preset is fine.

### Terminal.app (macOS)

Works on macOS 10.13+. Older versions ship limited color support;
upgrade Terminal.app via the OS rather than tweaking thresholds.

### Warp

Works. Warp's own block UI renders the statusline inside the agent's
output block. If the line appears truncated, the cause is usually
Warp's "compact view" mode — toggle it.

### VS Code integrated terminal

Works. If colors appear monochrome, set
`"terminal.integrated.env.osx": {"TERM": "xterm-256color"}` (or `linux`
or `windows`) in `settings.json`. The default works on most builds.

### JetBrains integrated terminal (IntelliJ, PyCharm, WebStorm, etc.)

Historical bugs with ANSI 256-color rendering. Mitigations, in order
of preference:

1. Settings → Tools → Terminal → check **Use IDEA terminal emulation**,
   restart the IDE.
2. Set `TERM=xterm-256color` in the IDE's environment variables.
3. Run CC in an external terminal alongside the IDE.

### Windows Terminal (under WSL2)

Works. If box-drawing characters render as `??`, set the profile font
to a Unicode-aware font (Cascadia Code, JetBrains Mono, MesloLGS NF).
This is a font issue, not a CC issue.

### tmux

The outer `TERM` defaults to `screen` inside tmux, which strips
256-color. Either start tmux with `tmux -2` or add to `~/.tmux.conf`:

```
set -g default-terminal "screen-256color"
```

Reload with `tmux source-file ~/.tmux.conf` and start a new window.

### GNU screen

Same fix as tmux: `TERM=screen-256color` in your shell profile, or run
`screen -T xterm-256color`.

### mosh / ssh

ANSI passes through transparently. The local-side fonts and terminal
settings (above) still apply.

## Common diagnostic patterns

### "I see nothing at all after install"

99% of the time, one of these:

1. `/plugin install` ran, but `/cc-context-monitor` never did. The
   install puts files on disk; the skill writes the config that points
   CC at them. Run `/cc-context-monitor` now.
2. The skill ran inside the same CC session that needs the new config.
   Settings changes apply only to *new* sessions. Quit and relaunch CC.
3. `~/.claude/settings.json` already had a `.statusLine.command` from
   another plugin or earlier custom config, and the skill did not
   overwrite it. Confirm with
   `jq '.statusLine' ~/.claude/settings.json` and decide which to keep.

### "I see weird characters where dots should be"

The `●` and `○` glyphs are U+25CF and U+25CB. The terminal needs a
UTF-8 locale and a font with these glyphs. Verify:

```bash
locale | grep -i utf
printf '● ○\n'
```

If the second command prints `??` or boxes, fix the locale (`export
LANG=en_US.UTF-8`) and pick a font that includes Geometric Shapes.

### "It works in my test but not in real CC"

Capture the live payload by setting `CC_CTX_DEBUG=1` in the user's
shell, restart CC, then read `/tmp/cc-context-monitor.stdin.json`.
Compare against the test payloads in
`samples/cc-context-monitor/evals/statusline-output.json`. Field shape
mismatches surface immediately. Most common cause on older CC builds
is the `context_window` field being absent or under a different name.

### "Statusline runs but is super slow"

The native v2.1.x+ path has no external calls and runs in well under
50 ms. If it feels slow, the wrapper is falling into the `ccusage`
fallback. Confirm CC version with `claude --version`. Upgrade if older
than 2.1, or check that `jq` is on the PATH that CC inherits — when
`jq` fails the script can not extract `.context_window` and falls
through.

### "I see colors but no bars"

The bars are filled (`●`) and unfilled (`○`) Unicode dots. If you see
only colored numbers but no shape, the font is not rendering Geometric
Shapes. Switch to a Nerd Font, JetBrains Mono, or Cascadia Code.

### "I want to roll back"

Every install writes a timestamped backup. Restore with:

```bash
ls -la ~/.claude/settings.json.backup-*
cp ~/.claude/settings.json.backup-<timestamp> ~/.claude/settings.json
```

Then quit and relaunch CC. If you also want to remove the plugin
files: `/plugin uninstall cc-context-monitor@bdigital-public`.

### "I want a different layout / colors / thresholds"

Environment variables override defaults at runtime:

- `CC_CTX_GREEN_MAX` (default 49) — upper bound of the green band
- `CC_CTX_YELLOW_MAX` (default 74) — upper bound of the yellow band
- `CC_CTX_BAR_WIDTH` (default 10) — dots per bar
- `CC_STATUSLINE_ANNOTATION` — appended after the main line

Set them inline via the `statusLine.command` itself:

```bash
jq '.statusLine.command = "env CC_CTX_GREEN_MAX=40 CC_CTX_BAR_WIDTH=5 bash $SCRIPT"' \
  ~/.claude/settings.json
```

(Substitute `$SCRIPT` with the resolved absolute path.)

For deeper changes, fork the plugin and point `/plugin marketplace
add` at your fork.

## Reporting a bug

If the ladder above does not resolve the issue, open an issue at
[github.com/neurot1cal/bdigital-public/issues](https://github.com/neurot1cal/bdigital-public/issues)
with:

1. Output of `claude --version`
2. Output of `bash --version`
3. OS, distribution, and terminal emulator (with version)
4. Output of `jq '.statusLine' ~/.claude/settings.json`
5. Output of the test-payload command from step 4 of the ladder
6. The captured payload from `/tmp/cc-context-monitor.stdin.json`
   after enabling `CC_CTX_DEBUG=1` (sanitize cwd if private)
7. Output of `tput colors` (should be 256 on a healthy terminal)

The more of these you include up front, the faster the round-trip.
