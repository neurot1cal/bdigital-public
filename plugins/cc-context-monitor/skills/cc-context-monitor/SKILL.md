---
name: cc-context-monitor
description: Use when user asks about context usage, statusline setup, token usage, weekly quota, or says "install ccusage", "show my weekly usage", "configure statusline", or "context monitor". Triggers on mentions of session token counts, 1M-context percent, or rolling 7-day quota checks.
user-invocable: true
allowed-tools: Bash, Read, Write, Edit
---

# cc-context-monitor

## Overview

Configure a color-coded Claude Code statusline that surfaces three numbers at a glance:

1. **Context window usage** — percent of the 1M-token window the current session has consumed. Pulled from the transcript JSON path Claude Code passes into the statusline hook on stdin.
2. **Session token usage** — rolling input + output + cache-read + cache-creation tokens for this session. Distinct from the context percent; this is the running cost-style total.
3. **Weekly token usage** — rolling 7-day token total across every session on this machine. Useful signal for staying inside a subscription quota.

The statusline renderer delegates the heavy accounting to [`ccusage`](https://github.com/ryoppippi/ccusage) and layers a three-band color prefix on top:

- **green** for 0–60% of the context window
- **yellow** for 61–80%
- **red** for 81%+

Any existing trailing annotation the user composes via `CC_STATUSLINE_ANNOTATION` (for example "Remote control active") is preserved rather than clobbered, so the wrapper composes with other setups.

## When to Use

- User says "install ccusage", "configure statusline", "show my weekly usage", or "what's my context usage"
- User reports their statusline is missing context-percent or token-count info
- User asks how much of the 1M-token window they have left
- User wants a one-shot read of their rolling 7-day Claude Code token total
- User asks to uninstall the statusline or revert to the default

**Short-circuit:** If the user only asks "what is ccusage?" or a purely informational question, answer inline without writing to `~/.claude/settings.json`. The configuration step only runs when the user explicitly asks to install, configure, or update.

## Procedure

### Step 1: Detect Current State

Read the user's existing Claude Code settings to decide which branch to run:

```bash
SETTINGS="$HOME/.claude/settings.json"
if [ -f "$SETTINGS" ]; then
  jq '.statusLine // null' "$SETTINGS"
fi
```

Check whether `ccusage` is already on PATH:

```bash
command -v ccusage || echo "not installed"
```

Check whether this plugin's own statusline script is already wired up — look for `cc-context-monitor/statusline.sh` in the `.statusLine.command` field.

### Step 2: Install ccusage If Missing

Prefer a global npm install so the statusline hook (which runs on every turn) does not pay a cold `npx` cost:

```bash
npm install -g ccusage
```

If the user cannot install globally, note that the statusline script will fall back to `npx --no-install ccusage` but will print a quiet "ccusage not installed" hint until a reachable binary exists. Do not write the statusline config until ccusage is reachable either via PATH or via a usable `npx` cache.

### Step 3: Back Up settings.json

Before touching `~/.claude/settings.json`, always create a timestamped backup. Use dashes in the timestamp because colons break filenames on some filesystems:

```bash
TS=$(date +%Y-%m-%dT%H-%M-%S)
cp "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.backup-$TS"
```

Create `~/.claude/settings.json` with `{}` first if it does not exist. Never write anywhere outside `~/.claude/`.

### Step 4: Wire Up statusLine.command

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

**Sanity check:** Re-read `settings.json` and confirm the expected `.statusLine.command` field is present. If the write failed, restore from the `.backup-<timestamp>` copy.

### Step 5: Weekly Usage On Demand

When the user asks "show my weekly usage right now" or "what's my weekly quota", run ccusage's weekly report directly rather than reading the statusline:

```bash
ccusage weekly --json | jq '.totals'
```

Summarize the result in plain text. Flag any day that exceeds a round threshold (for example, >500k tokens in a single day) as a high-use day worth noting.

### Step 6: Confirm and Hand Off

Tell the user:

1. Which file was backed up, and the exact backup path
2. Which line was written to `settings.json`
3. That a fresh Claude Code session will now show the color-coded statusline
4. How to revert: `cp ~/.claude/settings.json.backup-<timestamp> ~/.claude/settings.json`

## What NOT to Install Into

- **Never** write to `~/.claude/plugins/`, `~/.claude/skills/`, or any path under the Claude Code installer-managed directories. These are overwritten on `/plugin marketplace update`. The only write target for the skill action is `~/.claude/settings.json` (plus its `.backup-<timestamp>` sibling).
- **Never** install ccusage into a project's node_modules. The statusline hook runs in the user's home shell environment, not inside a project, so a project-local binary will not be on PATH.
- **Never** embed secrets, API keys, or absolute machine-specific paths from prior sessions into the generated statusline command. The command stays generic so the same plugin install works on any machine.
- **Never** run this configuration procedure without first confirming the user wants to modify `~/.claude/settings.json`. A purely informational question ("what does ccusage do?") does not authorize a write.

## Trust Model

This skill writes one line of configuration to `~/.claude/settings.json` (pointing at a shell script that lives inside the plugin install tree), and optionally runs `npm install -g ccusage`. It does not exfiltrate data, does not make network requests from within the statusline hook beyond what ccusage does (ccusage itself is offline-capable via `--offline`, which this plugin uses), and does not write outside `~/.claude/`.

The statusline script itself is defensive against malformed stdin, missing ccusage, missing transcript files, and paths containing spaces or shell metacharacters. It never calls `eval`, never `source`s untrusted input, and quotes every path it touches.
