#!/usr/bin/env bash
# cc-context-monitor statusline wrapper
#
# Reads the Claude Code statusline JSON blob on stdin, pulls
# `context_window.remaining_percentage` directly from the blob (the
# live signal CC provides each turn, no external call needed), and
# emits a compact info-dense line:
#
#   ~/git/bdigital-public | feat/branch | Opus 4.6 (1M context) | ●●●○○○○○○○ 28% ctx used
#
# Segments (left to right):
#   1. cwd              home-relative path (replaces $HOME with ~)
#   2. git branch       omitted when cwd is not inside a repo; a "*"
#                       suffix marks a dirty working tree
#   3. worktree         optional, from stdin .worktree.name (orange)
#   4. agent            optional, from stdin .agent.name (cyan)
#   5. model            e.g. "Opus 4.6 (1M context)" — context window
#                       inferred from the model id suffix ([1m] → 1M,
#                       otherwise 200K)
#   6. output style     optional, from stdin .output_style.name (dim)
#                       omitted when equal to "default"
#   7. progress bar     10 dots, color-banded by context fill
#   8. pct              "NN% ctx used"
#
# Color bands on the bar and the pct text:
#
#   green  : 0–49%
#   yellow : 50–74%
#   red    : 75%+
#
# If a trailing annotation was already composed via
# CC_STATUSLINE_ANNOTATION (for example "Remote control active"), it
# is appended after the main segment so existing setups compose
# cleanly.
#
# Security notes:
#   - No `eval`, no `source`, no command substitution over the
#     transcript path.
#   - The transcript path and cwd are only used as file / directory
#     arguments, always quoted.
#   - The only file writes under the skill's install action go to
#     ~/.claude/ (the skill handles that directly in SKILL.md — this
#     script itself never writes to disk).

set -euo pipefail

# --- Config (tweakable via environment) -------------------------------------
# Thresholds in integer percent. green < $GREEN_MAX <= yellow < $YELLOW_MAX <= red.
# Defaults follow the widely-used 50/75 convention: green under half,
# yellow through three-quarters, red beyond that.
CC_CTX_GREEN_MAX="${CC_CTX_GREEN_MAX:-49}"
CC_CTX_YELLOW_MAX="${CC_CTX_YELLOW_MAX:-74}"
# Width of the progress bar in dot-cells.
CC_CTX_BAR_WIDTH="${CC_CTX_BAR_WIDTH:-10}"

# ANSI escape sequences. Use printf '\033' so the file stays 7-bit ASCII.
ESC=$(printf '\033')
COLOR_GREEN="${ESC}[32m"
COLOR_YELLOW="${ESC}[33m"
COLOR_RED="${ESC}[31m"
COLOR_DIM="${ESC}[2m"
COLOR_CYAN="${ESC}[36m"
COLOR_MAGENTA="${ESC}[35m"
COLOR_ORANGE="${ESC}[38;5;208m"
COLOR_RESET="${ESC}[0m"

# --- Read stdin -------------------------------------------------------------
# Claude Code hands the statusline a JSON blob on stdin. Capture it up
# front so we can parse fields via jq.
STDIN_JSON="$(cat || true)"

# Optional debug: dump stdin to a file so we can verify which fields CC
# actually provides on this host. Enabled by exporting CC_CTX_DEBUG=1.
if [ "${CC_CTX_DEBUG:-0}" = "1" ] && [ -n "$STDIN_JSON" ]; then
  printf '%s\n' "$STDIN_JSON" >"/tmp/cc-context-monitor.stdin.json" 2>/dev/null || true
fi

# Quiet fallback if stdin is empty or clearly not JSON. Do not crash the
# statusline — just print a dim hint.
if [ -z "${STDIN_JSON:-}" ] || ! printf '%s' "$STDIN_JSON" | jq -e . >/dev/null 2>&1; then
  printf '%scc-context-monitor: no statusline input%s\n' "$COLOR_DIM" "$COLOR_RESET"
  exit 0
fi

# Tiny helper: read a JSON path with a default when absent/null/empty.
jq_field() {
  local path="$1" default="${2:-}"
  local out
  out=$(printf '%s' "$STDIN_JSON" | jq -r "${path} // empty" 2>/dev/null || printf '')
  if [ -n "$out" ]; then
    printf '%s' "$out"
  else
    printf '%s' "$default"
  fi
}

# Coerce a possibly-float numeric string to a rounded non-negative
# integer. CC has been observed to emit values like 55.00000000000001
# for rate-limit percentages; bash arithmetic and `[ -le ]` both reject
# floats, so every percent read from stdin passes through this before
# any integer math touches it. Empty input → empty output so callers
# can keep using `-n` checks to tell "missing" from "zero".
to_int() {
  local v="$1"
  [ -z "$v" ] && return 0
  awk -v x="$v" 'BEGIN { v = x + 0.5; if (v < 0) v = 0; printf "%d", v }'
}

# --- Pull top-level signals from the stdin blob ----------------------------
CWD=$(jq_field '.cwd // .workspace.current_dir' "")
MODEL_ID=$(jq_field '.model.id' "")
MODEL_NAME=$(jq_field '.model.display_name' "claude")
AGENT_NAME=$(jq_field '.agent.name' "")
WORKTREE_NAME=$(jq_field '.worktree.name' "")
OUTPUT_STYLE=$(jq_field '.output_style.name' "default")
# context_window.remaining_percentage is the live signal CC emits each
# turn. Some Claude Code versions nest it under .context_window.
# Different builds may use a .percent_used spelling. Check both shapes.
CTX_REMAINING=$(jq_field '.context_window.remaining_percentage' "")
CTX_USED_DIRECT=$(jq_field '.context_window.percent_used // .context_window.used_percentage' "")
RATE_5H=$(to_int "$(jq_field '.rate_limits.five_hour.used_percentage' "")")
RATE_7D=$(to_int "$(jq_field '.rate_limits.seven_day.used_percentage' "")")

# --- Compute the context-used percent --------------------------------------
CTX_PCT=""
if [ -n "$CTX_USED_DIRECT" ]; then
  CTX_PCT=$(to_int "$CTX_USED_DIRECT")
elif [ -n "$CTX_REMAINING" ]; then
  # remaining_percentage is "how much is LEFT". Used = 100 - remaining.
  CTX_PCT=$(awk -v r="$CTX_REMAINING" 'BEGIN { printf "%d", (100 - r + 0.5) }')
fi

# If CC didn't expose the field (older version), fall back to asking
# ccusage for the number. The fallback uses whatever is on PATH and
# caches through ccusage's own 1-second cache — not ideal, but keeps
# us compatible with older hosts.
if [ -z "$CTX_PCT" ]; then
  CCUSAGE_CMD=""
  if command -v ccusage >/dev/null 2>&1; then
    CCUSAGE_CMD="ccusage"
  elif command -v npx >/dev/null 2>&1; then
    if npx --no-install ccusage --version >/dev/null 2>&1; then
      CCUSAGE_CMD="npx --no-install ccusage"
    fi
  fi
  if [ -n "$CCUSAGE_CMD" ]; then
    set +e
    # shellcheck disable=SC2086
    CC_STATUSLINE_OUT="$(printf '%s' "$STDIN_JSON" | $CCUSAGE_CMD statusline --offline 2>/dev/null)"
    set -e
    if [ -n "${CC_STATUSLINE_OUT:-}" ] && [[ "$CC_STATUSLINE_OUT" =~ \(([0-9]+)%\) ]]; then
      CTX_PCT="${BASH_REMATCH[1]}"
    fi
  fi
fi

# --- Pretty-print the cwd --------------------------------------------------
display_cwd="$CWD"
if [ -n "$CWD" ] && [ -n "${HOME:-}" ]; then
  case "$CWD" in
    "$HOME") display_cwd="~" ;;
    "$HOME"/*) display_cwd="~${CWD#"$HOME"}" ;;
  esac
fi

# --- Derive git branch (if any) and dirty flag ----------------------------
branch=""
dirty=""
if [ -n "$CWD" ] && command -v git >/dev/null 2>&1; then
  if branch=$(git -C "$CWD" symbolic-ref --short HEAD 2>/dev/null); then
    :  # got a branch name
  else
    # detached HEAD: use short sha instead
    branch=$(git -C "$CWD" rev-parse --short HEAD 2>/dev/null || printf '')
  fi
  if [ -n "$branch" ]; then
    # Count porcelain-v1 lines to detect a dirty tree. We only need to
    # know whether there's at least one dirty entry.
    if [ -n "$(git -C "$CWD" status --porcelain 2>/dev/null | head -1)" ]; then
      dirty="*"
    fi
  fi
fi

# --- Render the model segment ----------------------------------------------
# Recent Claude Code versions ship model.display_name already formatted
# as e.g. "Opus 4.7 (1M context)". Prefer it verbatim. Older versions
# emit a bare "Opus" in display_name and carry the version in the id;
# parse that shape as a fallback so the wrapper still looks good on
# older CC builds.
model_label="$MODEL_NAME"
if ! printf '%s' "$MODEL_NAME" | grep -qE '[0-9]'; then
  # display_name has no digits — likely the bare "Opus" case. Build
  # "Opus X.Y (NNN context)" from the id.
  if [[ "$MODEL_ID" =~ claude-(opus|sonnet|haiku)-([0-9]+)-([0-9]+) ]]; then
    family="${BASH_REMATCH[1]}"
    major="${BASH_REMATCH[2]}"
    minor="${BASH_REMATCH[3]}"
    case "$family" in
      opus) family_label="Opus" ;;
      sonnet) family_label="Sonnet" ;;
      haiku) family_label="Haiku" ;;
      *) family_label="$family" ;;
    esac
    if [[ "$MODEL_ID" == *"[1m]"* ]]; then
      ctx_window="1M context"
    else
      ctx_window="200K context"
    fi
    model_label=$(printf '%s %s.%s (%s)' "$family_label" "$major" "$minor" "$ctx_window")
  fi
fi

# --- Band-color helper ------------------------------------------------------
# Returns the ANSI escape for green/yellow/red based on an integer
# percent and the GREEN/YELLOW thresholds. Call with: band_color <pct>
band_color() {
  local pct="$1"
  if [ "$pct" -le "$CC_CTX_GREEN_MAX" ]; then
    printf '%s' "$COLOR_GREEN"
  elif [ "$pct" -le "$CC_CTX_YELLOW_MAX" ]; then
    printf '%s' "$COLOR_YELLOW"
  else
    printf '%s' "$COLOR_RED"
  fi
}

# --- Pick the bar color based on the three bands ---------------------------
bar_color="$COLOR_GREEN"
if [ -n "$CTX_PCT" ]; then
  bar_color=$(band_color "$CTX_PCT")
fi

# --- Bar renderer -----------------------------------------------------------
# Render an N-dot progress bar for an integer percent. Filled dots use
# the band color; unfilled dots render dim so the bar shape is visible
# at any fill level. Call with: render_bar <pct> <color>
render_bar() {
  local pct="$1" color="$2" width="$CC_CTX_BAR_WIDTH"
  local filled=$(( (pct * width + 50) / 100 ))
  if [ "$filled" -lt 0 ]; then filled=0; fi
  if [ "$filled" -gt "$width" ]; then filled="$width"; fi
  local unfilled=$(( width - filled ))
  local filled_part=""
  while [ "$filled" -gt 0 ]; do
    filled_part+="●"
    filled=$(( filled - 1 ))
  done
  local unfilled_part=""
  while [ "$unfilled" -gt 0 ]; do
    unfilled_part+="○"
    unfilled=$(( unfilled - 1 ))
  done
  printf '%s%s%s%s%s' "$color" "$filled_part" "$COLOR_DIM" "$unfilled_part" "$COLOR_RESET"
}

bar=""
if [ -n "$CTX_PCT" ]; then
  bar=$(render_bar "$CTX_PCT" "$bar_color")
fi

# --- Assemble the final line ------------------------------------------------

segments=()

if [ -n "$display_cwd" ]; then
  segments+=("$(printf '%s%s%s' "$COLOR_CYAN" "$display_cwd" "$COLOR_RESET")")
fi

if [ -n "$branch" ]; then
  segments+=("$(printf '%s%s%s%s' "$COLOR_MAGENTA" "$branch" "$dirty" "$COLOR_RESET")")
fi

if [ -n "$WORKTREE_NAME" ]; then
  segments+=("$(printf '%s%s%s' "$COLOR_ORANGE" "$WORKTREE_NAME" "$COLOR_RESET")")
fi

if [ -n "$AGENT_NAME" ]; then
  segments+=("$(printf '%s%s%s' "$COLOR_CYAN" "$AGENT_NAME" "$COLOR_RESET")")
fi

segments+=("$model_label")

if [ -n "$OUTPUT_STYLE" ] && [ "$OUTPUT_STYLE" != "default" ]; then
  segments+=("$(printf '%s%s%s' "$COLOR_DIM" "$OUTPUT_STYLE" "$COLOR_RESET")")
fi

if [ -n "$CTX_PCT" ]; then
  segments+=("$(printf '%s %s%s%% ctx%s' "$bar" "$bar_color" "$CTX_PCT" "$COLOR_RESET")")
else
  segments+=("$(printf '%sctx n/a%s' "$COLOR_DIM" "$COLOR_RESET")")
fi

# Session (5-hour rate limit) and weekly (7-day) quota segments. Each
# gets its own dot bar + percent in its own band color so you can
# eyeball where the pressure is coming from at a glance.
if [ -n "$RATE_5H" ]; then
  c5h=$(band_color "$RATE_5H")
  bar5h=$(render_bar "$RATE_5H" "$c5h")
  segments+=("$(printf '%s %s%s%% 5h%s' "$bar5h" "$c5h" "$RATE_5H" "$COLOR_RESET")")
fi
if [ -n "$RATE_7D" ]; then
  c7d=$(band_color "$RATE_7D")
  bar7d=$(render_bar "$RATE_7D" "$c7d")
  segments+=("$(printf '%s %s%s%% 7d%s' "$bar7d" "$c7d" "$RATE_7D" "$COLOR_RESET")")
fi

# Join segments with " | ". IFS only uses its first char when expanding
# arrays, so build the join explicitly to preserve the literal " | ".
line=""
for seg in "${segments[@]}"; do
  if [ -z "$line" ]; then
    line="$seg"
  else
    line="$line | $seg"
  fi
done

annotation=""
if [ -n "${CC_STATUSLINE_ANNOTATION:-}" ]; then
  annotation=$(printf ' | %s%s%s' "$COLOR_DIM" "$CC_STATUSLINE_ANNOTATION" "$COLOR_RESET")
fi

printf '%s%s\n' "$line" "$annotation"
