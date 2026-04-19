#!/usr/bin/env bash
# Structural regression tests for session-handoff SKILL.md
# Run: ./tests/test-skill-structure.sh
# Exit 0 = all green, exit 1 = failures found

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_FILE="${SKILL_DIR}/SKILL.md"
PASS=0
FAIL=0
ERRORS=()

pass() { ((PASS++)); printf "  \033[32m✓\033[0m %s\n" "$1"; }
fail() { ((FAIL++)); ERRORS+=("$1"); printf "  \033[31m✗\033[0m %s\n" "$1"; }
check() {
  local desc="$1" pattern="$2"
  if grep -qE "$pattern" "$SKILL_FILE"; then
    pass "$desc"
  else
    fail "$desc"
  fi
}

echo ""
echo "session-handoff SKILL.md — structural tests"
echo "============================================="

# --- Frontmatter ---
echo ""
echo "Frontmatter:"

check "has name field" "^name: session-handoff"
check "has description field" "^description: "
# Description should be trigger-focused per CSO rules (no workflow summary)
DESC_LINE=$(grep "^description:" "$SKILL_FILE")
if echo "$DESC_LINE" | grep -qEi '(gathers|generates|updates|captures|produces|creates)'; then
  fail "description is trigger-focused (no workflow verbs) — should describe triggers, not actions like 'Gathers/Generates/Captures'"
else
  pass "description is trigger-focused (no workflow verbs)"
fi

# --- Required Sections ---
echo ""
echo "Required sections:"

check "has Overview" "^## Overview"
check "has When to Use" "^## When to Use"
check "has Procedure" "^## Procedure"
check "has Step 1: Gather" "^### Step 1"
check "has Step 2: Reflect" "^### Step 2"
check "has Step 3: Update Memory" "^### Step 3"
check "has Step 4: Generate" "^### Step 4"
check "has Step 5: Output" "^### Step 5"
check "has What NOT to Include" "^## What NOT to Include"

# --- Key Guardrails ---
echo ""
echo "Guardrails (the things that prevent bad output):"

check "trivial-session short-circuit" "Short-circuit.*skip the handoff"
check "quality check (ephemeral vs recoverable)" "Quality check.*recoverable"
check "self-check before output" "Self-check.*fresh session"
check "word count target (200-500)" "200-500 words"
check "memory-worthy vs ephemeral examples" "Memory-worthy vs ephemeral"
check "tasks: summarize if >3" "Summarize.*more than 3"
check "sensitive data guardrail" "API keys.*tokens.*passwords.*certificates.*secrets"
check "references Anthropic session management guide" "claude.com/blog/using-claude-code-session-management"
check "documents alternatives (compact/rewind/resume)" "Alternative to handoff"

# --- Anti-Patterns (things that should NOT be in the skill) ---
echo ""
echo "Anti-patterns (should NOT be present):"

# No hardcoded project config
if grep -qE "session-handoff\.yaml|project_name:|log_files:|state_files:" "$SKILL_FILE"; then
  fail "no hardcoded project config references"
else
  pass "no hardcoded project config references"
fi

# No manual path construction with sed
if grep -qE 'sed.*s\|/\|-\|g' "$SKILL_FILE"; then
  fail "no manual memory path construction via sed"
else
  pass "no manual memory path construction via sed"
fi

# Should not include full file contents instruction
check "warns against including full file contents" "Full file contents.*next session can read"

# No hardcoded dev server port checks
if grep -qE 'lsof.*TCP.*LISTEN|:(3000|5173|8080)' "$SKILL_FILE"; then
  fail "no hardcoded dev server detection (domain-specific)"
else
  pass "no hardcoded dev server detection (domain-specific)"
fi

# --- Prompt Template ---
echo ""
echo "Prompt template structure:"

check "template: Working Directory" "### Working Directory"
check "template: Read First" "### Read First"
check "template: Current State" "### Current State"
check "template: What We Were Doing" "### What We Were Doing"
check "template: Decisions Made" "### Decisions Made"
check "template: What Didn't Work" "### What Didn.*t Work"
check "template: Key Findings" "### Key Findings"
check "template: Next Steps" "### Next Steps"
check "template: Git Workflow" "### Git Workflow"

# --- Token Efficiency ---
echo ""
echo "Token efficiency:"

WORD_COUNT=$(wc -w < "$SKILL_FILE" | tr -d ' ')
if [ "$WORD_COUNT" -le 1500 ]; then
  pass "word count under 1500 (currently: ${WORD_COUNT})"
else
  fail "word count under 1500 (currently: ${WORD_COUNT})"
fi

if [ "$WORD_COUNT" -ge 500 ]; then
  pass "word count above 500 — enough substance (currently: ${WORD_COUNT})"
else
  fail "word count above 500 — enough substance (currently: ${WORD_COUNT})"
fi

# --- Summary ---
echo ""
echo "============================================="
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
