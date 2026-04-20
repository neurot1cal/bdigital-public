#!/usr/bin/env bash
# cc-context-monitor statusline wrapper
#
# Reads the Claude Code statusline JSON blob on stdin, delegates to
# `ccusage statusline` for the session/daily/weekly/context accounting,
# then prepends a color-coded context-window segment based on three
# thresholds:
#
#   green  : 0–60%
#   yellow : 61–80%
#   red    : 81%+
#
# If a trailing annotation was already passed through (for example a
# project-specific "Remote control active" line in the environment
# variable CC_STATUSLINE_ANNOTATION), it is appended after the main
# segment so existing setups compose cleanly.
#
# If ccusage is unavailable, a minimal fallback statusline is emitted
# so the hook never returns an empty line and never crashes Claude
# Code's statusline renderer.
#
# Security notes:
#   - No `eval`, no `source`, no command substitution over the
#     transcript path.
#   - The transcript path is only used as a file argument to `jq` /
#     `wc`, always quoted.
#   - The stdin JSON is forwarded to ccusage via a pipe; we never
#     expand it as a shell string.
#   - The only file writes under the skill's install action go to
#     ~/.claude/ (the skill handles that directly in SKILL.md — this
#     script itself never writes to disk).

set -euo pipefail

# --- Config (tweakable via environment) -------------------------------------
# Thresholds in integer percent. Keep defaults aligned with the three-band
# rule documented in SKILL.md and the structural tests.
CC_CTX_GREEN_MAX="${CC_CTX_GREEN_MAX:-60}"
CC_CTX_YELLOW_MAX="${CC_CTX_YELLOW_MAX:-80}"

# ANSI escape sequences. Use printf '\033' so the file stays 7-bit ASCII.
ESC=$(printf '\033')
COLOR_GREEN="${ESC}[32m"
COLOR_YELLOW="${ESC}[33m"
COLOR_RED="${ESC}[31m"
COLOR_DIM="${ESC}[2m"
COLOR_RESET="${ESC}[0m"

# --- Read stdin -------------------------------------------------------------
# Claude Code hands the statusline a JSON blob on stdin. Capture it up
# front so we can pipe it to ccusage and optionally parse the transcript
# path ourselves for the fallback branch.
STDIN_JSON="$(cat || true)"

# Quiet fallback if stdin is empty or clearly not JSON. Do not crash the
# statusline — just print a dim hint.
if [ -z "${STDIN_JSON:-}" ] || ! printf '%s' "$STDIN_JSON" | jq -e . >/dev/null 2>&1; then
  printf '%scc-context-monitor: no statusline input%s\n' "$COLOR_DIM" "$COLOR_RESET"
  exit 0
fi

# --- Locate ccusage ---------------------------------------------------------
# Prefer an already-installed binary. Fall back to `npx --no-install` so
# we never trigger a surprise network install from the statusline hook
# (a hot path that runs on every turn). If neither is available, print a
# fallback and exit cleanly.
CCUSAGE_CMD=""
if command -v ccusage >/dev/null 2>&1; then
  CCUSAGE_CMD="ccusage"
elif command -v npx >/dev/null 2>&1; then
  # --no-install avoids the slow "do you want to install ccusage?" prompt
  # and a cold network hit. Users install once via the skill action.
  if npx --no-install ccusage --version >/dev/null 2>&1; then
    CCUSAGE_CMD="npx --no-install ccusage"
  fi
fi

# --- Fallback path: no ccusage available ------------------------------------
if [ -z "$CCUSAGE_CMD" ]; then
  # Pull just enough context out of stdin to render a useful minimal
  # line. The transcript path and model display name are the two
  # cheapest signals.
  model=$(printf '%s' "$STDIN_JSON" | jq -r '.model.display_name // .model.id // "claude"')
  transcript=$(printf '%s' "$STDIN_JSON" | jq -r '.transcript_path // ""')
  lines=0
  if [ -n "$transcript" ] && [ -f "$transcript" ]; then
    # `wc -l` is safe: we quote the path and never expand it as a command.
    lines=$(wc -l <"$transcript" 2>/dev/null | tr -d ' ' || printf '0')
  fi
  printf '%s%s%s | ctx lines: %s | %sccusage not installed. Run /cc-context-monitor to configure.%s\n' \
    "$COLOR_DIM" "$model" "$COLOR_RESET" "$lines" "$COLOR_DIM" "$COLOR_RESET"
  exit 0
fi

# --- Delegate to ccusage ----------------------------------------------------
# Pipe stdin unchanged so ccusage sees exactly the blob Claude Code
# provided. `--offline` avoids a network call on every render.
# `--no-cache` is intentionally not set so we respect ccusage's default
# cache (cheap, refreshed on each turn).
#
# We capture output and status without `eval` — $CCUSAGE_CMD is a
# space-separated token list we control, never user data.
set +e
# shellcheck disable=SC2086
CC_OUT="$(printf '%s' "$STDIN_JSON" | $CCUSAGE_CMD statusline --offline 2>/dev/null)"
CC_STATUS=$?
set -e

if [ "$CC_STATUS" -ne 0 ] || [ -z "$CC_OUT" ]; then
  printf '%scc-context-monitor: ccusage returned no output%s\n' "$COLOR_DIM" "$COLOR_RESET"
  exit 0
fi

# --- Extract context percentage ---------------------------------------------
# ccusage includes a `🧠 25,014 (3%)` segment at the end. Pull the integer
# percent out for our own color band. Regex is anchored on the percent-
# in-parens pattern to avoid false positives on other numbers.
CTX_PCT=""
if [[ "$CC_OUT" =~ \(([0-9]+)%\) ]]; then
  CTX_PCT="${BASH_REMATCH[1]}"
fi

# --- Pick a color based on the three bands ---------------------------------
ctx_color="$COLOR_GREEN"
ctx_label="green"
if [ -n "$CTX_PCT" ]; then
  if [ "$CTX_PCT" -le "$CC_CTX_GREEN_MAX" ]; then
    ctx_color="$COLOR_GREEN"
    ctx_label="green"
  elif [ "$CTX_PCT" -le "$CC_CTX_YELLOW_MAX" ]; then
    ctx_color="$COLOR_YELLOW"
    ctx_label="yellow"
  else
    ctx_color="$COLOR_RED"
    ctx_label="red"
  fi
fi

# --- Assemble the final line ------------------------------------------------
# Prepend our color-banded context prefix so it shows first, then the
# full ccusage line (which already contains session + weekly + raw
# context). Finally, preserve any upstream annotation the user composed
# via CC_STATUSLINE_ANNOTATION so "Remote control active" etc. survives
# this wrapper rather than being clobbered.

if [ -n "$CTX_PCT" ]; then
  prefix=$(printf '%sctx %s%% (%s)%s' "$ctx_color" "$CTX_PCT" "$ctx_label" "$COLOR_RESET")
else
  prefix=$(printf '%sctx n/a%s' "$COLOR_DIM" "$COLOR_RESET")
fi

annotation=""
if [ -n "${CC_STATUSLINE_ANNOTATION:-}" ]; then
  annotation=$(printf ' | %s%s%s' "$COLOR_DIM" "$CC_STATUSLINE_ANNOTATION" "$COLOR_RESET")
fi

printf '%s | %s%s\n' "$prefix" "$CC_OUT" "$annotation"
