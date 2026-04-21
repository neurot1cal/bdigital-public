---
name: cc-context-monitor
description: Use when user asks about context usage, statusline setup, token usage, weekly quota, or says "configure statusline", "context monitor", or "show my weekly usage". Triggers on mentions of session token counts, 1M-context percent, rolling 5-hour session limits, or rolling 7-day quota.
user-invocable: true
allowed-tools: Bash, Read, Write, Edit
---

# cc-context-monitor

## Overview

Configure an info-dense Claude Code statusline that reads directly from the JSON blob Claude Code pipes to the statusline hook on stdin. No external tools required on recent CC builds (v2.1.x+): the blob already carries context-window fill, five-hour and seven-day rate-limit percentages, model label, cwd, and output style.

The rendered line looks like:

```
~/git/bdigital-public | feat/branch* | Opus 4.7 (1M context) | ●●○○○○○○○○ 18% ctx | ●●○○○○○○○○ 20% 5h | ●●●●●○○○○○ 54% 7d
```

Three 10-dot bars share one color-band palette — green, yellow, red — so pressure anywhere (context window, session block, weekly quota) jumps out visually.

Color bands on every bar and percent:

- **green** for 0–49%
- **yellow** for 50–74%
- **red** for 75%+

The branch name is followed by a `*` when the working tree is dirty.

Any trailing annotation composed via the environment variable `CC_STATUSLINE_ANNOTATION` (for example "Remote control active") is preserved, appended after the three bars so existing setups compose cleanly.

The wrapper falls back to `ccusage statusline` for the context percent only when running on older Claude Code versions that do not expose `context_window.used_percentage` in the stdin payload. On those hosts the 5h / 7d bars are simply omitted.

## When to Use

- User says "install the statusline", "configure statusline", "show my weekly usage", or "what's my context usage"
- User reports the current statusline is missing context-percent, session, or weekly quota info
- User asks how much of the 1M-token window they have left
- User wants the rolling 5-hour or 7-day subscription quota surfaced at a glance
- User asks to uninstall the statusline or revert to the default

**Short-circuit:** If the user only asks a purely informational question ("what's in the statusline stdin?"), answer inline without writing to `~/.claude/settings.json`. The configuration step only runs when the user explicitly asks to install, configure, or update.

## Procedure

### Step 1: Detect Current State

Read the user's existing Claude Code settings to decide which branch to run:

```bash
SETTINGS="$HOME/.claude/settings.json"
if [ -f "$SETTINGS" ]; then
  jq '.statusLine // null' "$SETTINGS"
fi
```

Check whether this plugin's own statusline script is already wired up — look for `cc-context-monitor/statusline.sh` in the `.statusLine.command` field.

Check Claude Code version — on a v2.1.x+ host, `jq -r '.version'` against a captured stdin dump should return `2.1.*` or newer.

### Step 2: Back Up settings.json

Before touching `~/.claude/settings.json`, always create a timestamped backup. Use dashes in the timestamp because colons break filenames on some filesystems:

```bash
TS=$(date +%Y-%m-%dT%H-%M-%S)
cp "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.backup-$TS"
```

Create `~/.claude/settings.json` with `{}` first if it does not exist. Never write anywhere outside `~/.claude/`.

### Step 3: Wire Up statusLine.command

Resolve the absolute path to the plugin's `statusline.sh`. On a standard install that is:

```
~/.claude/plugins/marketplaces/bdigital-public/plugins/cc-context-monitor/statusline.sh
```

Use `jq` to merge the statusline config into `settings.json` without overwriting unrelated fields. Write to a temp file and atomically replace:

```bash
SCRIPT="$HOME/.claude/plugins/marketplaces/bdigital-public/plugins/cc-context-monitor/statusline.sh"
TMP=$(mktemp)
jq --arg cmd "bash $SCRIPT" \
  '.statusLine = { "type": "command", "command": $cmd, "padding": 0 }' \
  "$HOME/.claude/settings.json" >"$TMP"
mv "$TMP" "$HOME/.claude/settings.json"
```

**Sanity check:** Re-read `settings.json` and confirm the expected `.statusLine.command` field is present. If the write failed, restore from the `.backup-$TS` copy.

### Step 4: Verify the Render

Capture a real CC stdin payload to confirm the bars render as expected:

```bash
echo '{"cwd":"'"$PWD"'","model":{"id":"claude-opus-4-7[1m]","display_name":"Opus 4.7 (1M context)"},"context_window":{"used_percentage":18,"remaining_percentage":82},"rate_limits":{"five_hour":{"used_percentage":20},"seven_day":{"used_percentage":54}}}' \
  | bash "$SCRIPT"
```

Expect three dot bars, color-banded by percent, and a dirty-flag asterisk if the cwd has uncommitted changes.

### Step 5: Tuning (Optional)

The wrapper honors these environment variables:

- `CC_CTX_GREEN_MAX` (default 49) — upper bound of the green band
- `CC_CTX_YELLOW_MAX` (default 74) — upper bound of the yellow band
- `CC_CTX_BAR_WIDTH` (default 10) — dots per bar
- `CC_STATUSLINE_ANNOTATION` — trailing dim-colored annotation

Set any of these in the `statusLine.command` via `env KEY=value bash $SCRIPT` if the user wants thresholds that differ from the defaults.

### Step 6: Confirm and Hand Off

Tell the user:

1. Which file was backed up, and the exact backup path
2. Which line was written to `settings.json`
3. That a fresh Claude Code session will now show the three-bar statusline
4. How to revert: `cp ~/.claude/settings.json.backup-<timestamp> ~/.claude/settings.json`

## What NOT to Install Into

- **Never** write to `~/.claude/plugins/`, `~/.claude/skills/`, or any path under the Claude Code installer-managed directories. These are overwritten on `/plugin marketplace update`. The only write target for the skill action is `~/.claude/settings.json` (plus its `.backup-<timestamp>` sibling).
- **Never** embed secrets, API keys, or absolute machine-specific paths from prior sessions into the generated statusline command. The command stays generic so the same plugin install works on any machine.
- **Never** run this configuration procedure without first confirming the user wants to modify `~/.claude/settings.json`. A purely informational question ("what does the statusline show?") does not authorize a write.

## Trust Model

This skill writes one line of configuration to `~/.claude/settings.json` (pointing at a shell script that lives inside the plugin install tree). It does not exfiltrate data, makes no network calls from within the statusline hook, and does not write outside `~/.claude/`.

The statusline script itself is defensive against malformed stdin, missing fields, and paths containing spaces or shell metacharacters. It never calls `eval`, never `source`s untrusted input, and quotes every path it touches.
