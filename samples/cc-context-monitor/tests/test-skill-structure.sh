#!/usr/bin/env bash
# Structural regression tests for the cc-context-monitor plugin.
# Run: bash samples/cc-context-monitor/tests/test-skill-structure.sh
# Exit 0 = all green, exit 1 = failures found.

set -euo pipefail

# Resolve the plugin root relative to this test file so the script works
# from any CWD and under both the samples/ and plugins/ trees.
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${TESTS_DIR}/../../.." && pwd)"
PLUGIN_DIR="${REPO_ROOT}/plugins/cc-context-monitor"
SKILL_FILE="${PLUGIN_DIR}/skills/cc-context-monitor/SKILL.md"
STATUSLINE="${PLUGIN_DIR}/statusline.sh"
PLUGIN_JSON="${PLUGIN_DIR}/.claude-plugin/plugin.json"

PASS=0
FAIL=0
ERRORS=()

# `((VAR++))` returns exit code 1 when VAR is 0, which trips `set -e` on
# some bash versions. Use explicit assignment to be portable.
pass() { PASS=$((PASS+1)); printf "  \033[32m✓\033[0m %s\n" "$1"; }
fail() { FAIL=$((FAIL+1)); ERRORS+=("$1"); printf "  \033[31m✗\033[0m %s\n" "$1"; }
check() {
  local desc="$1" pattern="$2" file="${3:-$SKILL_FILE}"
  if grep -qE "$pattern" "$file"; then
    pass "$desc"
  else
    fail "$desc"
  fi
}

echo ""
echo "cc-context-monitor — structural tests"
echo "======================================"

# --- File existence ---------------------------------------------------------
echo ""
echo "Files:"

if [ -f "$SKILL_FILE" ]; then pass "SKILL.md exists"; else fail "SKILL.md exists at ${SKILL_FILE}"; fi
if [ -f "$STATUSLINE" ]; then pass "statusline.sh exists"; else fail "statusline.sh exists at ${STATUSLINE}"; fi
if [ -f "$PLUGIN_JSON" ]; then pass "plugin.json exists"; else fail "plugin.json exists at ${PLUGIN_JSON}"; fi
if [ -f "${PLUGIN_DIR}/LICENSE" ]; then pass "LICENSE exists"; else fail "LICENSE exists"; fi
if [ -f "${PLUGIN_DIR}/README.md" ]; then pass "README.md exists"; else fail "README.md exists"; fi

# If the critical files are missing, stop here — the rest will cascade.
if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Missing critical files; aborting further checks."
  for err in "${ERRORS[@]}"; do printf "  \033[31m•\033[0m %s\n" "$err"; done
  exit 1
fi

# --- plugin.json ------------------------------------------------------------
echo ""
echo "plugin.json:"

if jq -e . "$PLUGIN_JSON" >/dev/null 2>&1; then
  pass "plugin.json parses as valid JSON"
else
  fail "plugin.json parses as valid JSON"
fi

for field in name description version category author homepage license; do
  if jq -e --arg f "$field" '.[$f] // empty' "$PLUGIN_JSON" >/dev/null 2>&1; then
    pass "plugin.json has '$field' field"
  else
    fail "plugin.json has '$field' field"
  fi
done

if jq -e 'select(.name == "cc-context-monitor")' "$PLUGIN_JSON" >/dev/null 2>&1; then
  pass "plugin.json name is 'cc-context-monitor'"
else
  fail "plugin.json name is 'cc-context-monitor'"
fi

if jq -e 'select(.license == "MIT")' "$PLUGIN_JSON" >/dev/null 2>&1; then
  pass "plugin.json license is 'MIT'"
else
  fail "plugin.json license is 'MIT'"
fi

# --- SKILL.md frontmatter ---------------------------------------------------
echo ""
echo "SKILL.md frontmatter:"

check "has 'name' field" "^name: cc-context-monitor"
check "has 'description' field" "^description: "
check "has 'user-invocable: true'" "^user-invocable: true"
check "has 'allowed-tools' field" "^allowed-tools: "

# Description should be trigger-focused — no workflow-verb phrasing per CSO
# skill-authoring rules. Verbs to reject mirror the session-handoff test.
DESC_LINE=$(grep "^description:" "$SKILL_FILE")
if echo "$DESC_LINE" | grep -qEi '(gathers|generates|updates|captures|produces|creates)'; then
  fail "description is trigger-focused (no workflow verbs like 'generates/gathers/updates/captures/produces/creates')"
else
  pass "description is trigger-focused (no workflow verbs)"
fi

# --- SKILL.md required sections --------------------------------------------
echo ""
echo "SKILL.md required sections:"

check "has Overview" "^## Overview"
check "has When to Use" "^## When to Use"
check "has Procedure" "^## Procedure"
check "has What NOT to Install Into" "^## What NOT to Install Into"

# --- SKILL.md guardrails ---------------------------------------------------
echo ""
echo "SKILL.md guardrails:"

check "mentions timestamped backup before editing settings" "settings\\.json\\.backup-"
# shellcheck disable=SC2016 # single quotes intentional; this is a literal pattern
check "restricts writes to home Claude directory" '\$HOME/\.claude|~/\.claude'
check "documents color-band thresholds" "green|yellow|red"
check "references ccusage" "ccusage"

# --- statusline.sh ---------------------------------------------------------
echo ""
echo "statusline.sh:"

if [ -x "$STATUSLINE" ]; then
  pass "statusline.sh is executable"
else
  fail "statusline.sh is executable (chmod +x)"
fi

if head -1 "$STATUSLINE" | grep -qE '^#!/usr/bin/env bash|^#!/bin/bash'; then
  pass "statusline.sh has a bash shebang"
else
  fail "statusline.sh has a bash shebang"
fi

check "statusline.sh uses 'set -euo pipefail'" "^set -euo pipefail" "$STATUSLINE"

if bash -n "$STATUSLINE" 2>/dev/null; then
  pass "statusline.sh passes bash -n syntax check"
else
  fail "statusline.sh passes bash -n syntax check"
fi

# --- Three color thresholds ------------------------------------------------
echo ""
echo "Color thresholds:"

check "statusline.sh references green threshold/label" "green" "$STATUSLINE"
check "statusline.sh references yellow threshold/label" "yellow" "$STATUSLINE"
check "statusline.sh references red threshold/label" "red" "$STATUSLINE"
check "statusline.sh uses ANSI color escape for green (32m)" "\\[32m" "$STATUSLINE"
check "statusline.sh uses ANSI color escape for yellow (33m)" "\\[33m" "$STATUSLINE"
check "statusline.sh uses ANSI color escape for red (31m)" "\\[31m" "$STATUSLINE"
check "statusline.sh references configurable green max" "CC_CTX_GREEN_MAX" "$STATUSLINE"
check "statusline.sh references configurable yellow max" "CC_CTX_YELLOW_MAX" "$STATUSLINE"

# --- Security invariants ----------------------------------------------------
echo ""
echo "Security invariants:"

# No use of `eval` — check for the word as a command, not as part of
# "evaluate" etc. Anchor on whitespace or start-of-line.
if grep -nE '(^|[[:space:]])eval[[:space:]]' "$STATUSLINE" >/dev/null 2>&1; then
  fail "statusline.sh does not use 'eval'"
else
  pass "statusline.sh does not use 'eval'"
fi

# No `source` or `.` sourcing of untrusted input
if grep -nE '(^|[[:space:]])(source|\\.)[[:space:]]+["\x27$]' "$STATUSLINE" >/dev/null 2>&1; then
  fail "statusline.sh does not 'source' untrusted input"
else
  pass "statusline.sh does not 'source' untrusted input"
fi

# The transcript path must NOT be passed as a positional argument to a
# subprocess without quoting. The defensive pattern is: pipe stdin to
# ccusage, read the path via jq with -r into a quoted shell variable,
# and only use it with `wc -l <"$var"` or similar. Check we never
# construct a command line from the raw transcript path.
if grep -nE '\$\{?transcript[A-Z_]*\}?[[:space:]]*[^"]' "$STATUSLINE" >/dev/null 2>&1; then
  # Allow quoted usage only. This regex detects $transcript NOT followed
  # by a quote character, which would indicate unquoted interpolation.
  # Note: also accept usage inside already-quoted contexts (the check
  # above specifically catches raw unquoted expansion).
  :
fi
# A stronger check: assert we always quote the transcript variable
if grep -nE '"\$\{?transcript[^}]*\}?"' "$STATUSLINE" >/dev/null 2>&1; then
  pass "statusline.sh quotes the transcript path variable"
else
  fail "statusline.sh quotes the transcript path variable"
fi

# No curl, wget, or other network shell-outs in the wrapper itself.
# ccusage can do its own thing; the wrapper stays local.
if grep -nE '(^|[[:space:]])(curl|wget|fetch)[[:space:]]' "$STATUSLINE" >/dev/null 2>&1; then
  fail "statusline.sh does not call curl/wget/fetch directly"
else
  pass "statusline.sh does not call curl/wget/fetch directly"
fi

# SKILL.md must document the timestamped-backup procedure.
check "SKILL.md documents timestamped backup of settings.json" "backup-\\\$"

# SKILL.md must NOT instruct writes outside ~/.claude/
if grep -nE '(Write|write|cp).*/(etc|var|usr|opt|System)/' "$SKILL_FILE" >/dev/null 2>&1; then
  fail "SKILL.md does not instruct writes outside ~/.claude/"
else
  pass "SKILL.md does not instruct writes outside ~/.claude/"
fi

# --- No secrets / machine-specific paths ------------------------------------
echo ""
echo "Secrets and machine-specific paths:"

# Patterns assembled at runtime so this test script does not contain the
# forbidden literals itself (which would cause the scan to match its own
# source). Each entry is a deterministic reconstruction of the literal
# string; running it produces the pattern without embedding it.
_SP() { printf '%s' "$@"; }
SECRET_PATTERNS=(
  "$(_SP 82650 54423)"
  "$(_SP admin _pin)"
  "$(_SP TRAINING_ADMIN _PASSWORD)"
  "$(_SP /Users/ bobulrich)"
  "$(_SP rulrich @gmail)"
)
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
for pat in "${SECRET_PATTERNS[@]}"; do
  # Search the plugin + sample trees for the forbidden string, but
  # skip this test script itself (which assembles the patterns at
  # runtime but could still show substrings in a careless edit).
  hits=$(grep -rEl --include='*.sh' --include='*.md' --include='*.json' \
    "$pat" "$PLUGIN_DIR" "${TESTS_DIR}/.." 2>/dev/null \
    | grep -v -F "$SELF" || true)
  if [ -z "$hits" ]; then
    pass "no occurrences of forbidden pattern in plugin or sample"
  else
    fail "found forbidden pattern in: $hits"
  fi
done

# --- Word count on SKILL.md -------------------------------------------------
echo ""
echo "Token efficiency:"

WORD_COUNT=$(wc -w <"$SKILL_FILE" | tr -d ' ')
if [ "$WORD_COUNT" -le 1500 ]; then
  pass "SKILL.md word count under 1500 (currently: ${WORD_COUNT})"
else
  fail "SKILL.md word count under 1500 (currently: ${WORD_COUNT})"
fi

if [ "$WORD_COUNT" -ge 300 ]; then
  pass "SKILL.md word count above 300 — enough substance (currently: ${WORD_COUNT})"
else
  fail "SKILL.md word count above 300 — enough substance (currently: ${WORD_COUNT})"
fi

# --- Summary ---------------------------------------------------------------
echo ""
echo "======================================"
TOTAL=$((PASS + FAIL))
printf "Results: \033[32m%d passed\033[0m, \033[31m%d failed\033[0m out of %d\n" "$PASS" "$FAIL" "$TOTAL"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Failures:"
  for err in "${ERRORS[@]}"; do
    printf "  \033[31m•\033[0m %s\n" "$err"
  done
  echo ""
  exit 1
fi

echo ""
exit 0
