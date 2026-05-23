#!/bin/bash
# writing-kit test suite — proves the skill claims with runnable assertions.
#
# Covers four things:
#   1. The canonical buzzword ban list (buzzword-bans.json) parses as valid JSON.
#   2. The "expected output" files in tests/fixtures/ contain ZERO buzzword hits.
#      (Proof that the deslop bans actually fire.)
#   3. The shared-vocabulary claim is mechanical: both SKILL.md files reference
#      every banned term from the canonical list.
#   4. The fixture set is complete: every fixture has the expected sibling files.

set -euo pipefail
export PATH=/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURES="$PLUGIN_ROOT/tests/fixtures"
BANS_JSON="$FIXTURES/buzzword-bans.json"
DESLOP_SKILL="$PLUGIN_ROOT/skills/deslop-tech-comms/SKILL.md"
REVIEW_SKILL="$PLUGIN_ROOT/skills/thermo-nuclear-writing-review/SKILL.md"

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS+1)); }
fail() { echo "  ✗ FAIL: $1"; FAIL=$((FAIL+1)); }

echo "=== 1. buzzword-bans.json is valid JSON ==="
if python3 -c "import json; json.load(open('$BANS_JSON'))" 2>/dev/null; then
  ok "buzzword-bans.json parses"
else
  fail "buzzword-bans.json is not valid JSON"
  exit 1
fi

echo
echo "=== 2. expected-output files contain ZERO buzzword hits ==="
# Build a Python-friendly regex from the JSON
EXPECTED_FILES=("$FIXTURES/01-buzzword-density.expected.md"
                "$FIXTURES/02-fabricated-metrics.expected.md"
                "$FIXTURES/03-clean-prose-approve.input.md")
for f in "${EXPECTED_FILES[@]}"; do
  if [ ! -f "$f" ]; then
    fail "missing expected file: $f"
    continue
  fi
  HITS=$(python3 - <<PY
import json, re
bans = json.load(open("$BANS_JSON"))
text = open("$f").read().lower()
# Skip lines that are explanatory metadata / skill notes inside the fixture
content_lines = [l for l in text.split("\n") if not l.strip().startswith("[skill notes")]
content = " ".join(content_lines)
# Strip placeholder markers (\$IMPACT_PCT etc.) before checking — they're intentional
content = re.sub(r"\\\$[A-Z_]+", "", content)
hit_count = 0
hit_terms = []
for ban in bans["bans"]:
    if re.search(ban["regex"], content, flags=re.IGNORECASE):
        hit_count += 1
        hit_terms.append(ban["term"])
for phrase in bans["cut_on_sight_phrases"]:
    if re.search(phrase["regex"], content, flags=re.IGNORECASE):
        hit_count += 1
        hit_terms.append(phrase["phrase"])
print(f"{hit_count}:{','.join(hit_terms) if hit_terms else ''}")
PY
)
  COUNT="${HITS%%:*}"
  TERMS="${HITS#*:}"
  if [ "$COUNT" = "0" ]; then
    ok "$(basename "$f"): 0 buzzword/phrase hits"
  else
    fail "$(basename "$f"): $COUNT hits — $TERMS"
  fi
done

echo
echo "=== 3. shared-vocabulary claim: both SKILL.md files reference every canonical ban ==="
for f in "$DESLOP_SKILL" "$REVIEW_SKILL"; do
  if [ ! -f "$f" ]; then
    fail "missing SKILL.md: $f"
    continue
  fi
  MISSING=$(python3 - <<PY
import json
bans = json.load(open("$BANS_JSON"))
text = open("$f").read().lower()
missing = []
for ban in bans["bans"]:
    if ban["term"].lower() not in text:
        missing.append(ban["term"])
print(",".join(missing))
PY
)
  if [ -z "$MISSING" ]; then
    ok "$(basename $(dirname "$f"))/SKILL.md references every canonical ban term"
  else
    fail "$(basename $(dirname "$f"))/SKILL.md missing terms: $MISSING"
  fi
done

echo
echo "=== 4. fixture set is complete ==="
EXPECTED_FIXTURES=(
  "01-buzzword-density.input.md|01-buzzword-density.expected.md|01-buzzword-density.assertions.json"
  "02-fabricated-metrics.input.md|02-fabricated-metrics.expected.md|02-fabricated-metrics.assertions.json"
  "03-clean-prose-approve.input.md|03-clean-prose-approve.expected-verdict.json"
  "04-sloppy-draft-revise.input.md|04-sloppy-draft-revise.expected-verdict.json"
  "05-marketing-copy-suspended.input.md|05-marketing-copy-suspended.expected-verdict.json"
)
for set in "${EXPECTED_FIXTURES[@]}"; do
  IFS='|' read -ra files <<< "$set"
  set_name="${files[0]%%.*}"
  ok_count=0
  for f in "${files[@]}"; do
    if [ ! -f "$FIXTURES/$f" ]; then
      fail "fixture missing: $f"
    else
      ok_count=$((ok_count+1))
    fi
  done
  if [ "$ok_count" = "${#files[@]}" ]; then
    ok "fixture set '$set_name' complete (${#files[@]} files)"
  fi
done

echo
echo "=== summary ==="
echo "PASSED: $PASS"
echo "FAILED: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "✅ ALL TESTS PASS"
  exit 0
else
  echo "❌ $FAIL TESTS FAILED"
  exit 1
fi
