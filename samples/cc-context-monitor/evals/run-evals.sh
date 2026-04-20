#!/usr/bin/env bash
# Runs each eval case in samples/cc-context-monitor/evals/statusline-output.json
# through plugins/cc-context-monitor/statusline.sh and asserts the output
# contains the expected substrings.
#
# Strategy:
#  - For each case, write a stub `ccusage` script into a temp directory
#    that prints the fixture's stub_ccusage_output and exits with
#    stub_ccusage_exit. When `disable_ccusage: true`, skip the stub so
#    the wrapper's missing-ccusage fallback fires.
#  - Prepend the temp dir to PATH and invoke statusline.sh with the
#    fixture's stdin JSON piped in.
#  - Grep the captured stdout for each expect_contains entry; fail on
#    any expect_not_contains hit.
#
# Exit 0 = all cases green. Exit 1 = any case failed.

set -euo pipefail

EVALS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${EVALS_DIR}/../../.." && pwd)"
STATUSLINE="${REPO_ROOT}/plugins/cc-context-monitor/statusline.sh"
FIXTURE="${EVALS_DIR}/statusline-output.json"

PASS=0
FAIL=0
ERRORS=()

echo ""
echo "cc-context-monitor — eval suite"
echo "================================"

if [ ! -f "$STATUSLINE" ]; then
  printf "  \033[31m✗\033[0m statusline.sh not found at %s\n" "$STATUSLINE"
  exit 1
fi
if [ ! -f "$FIXTURE" ]; then
  printf "  \033[31m✗\033[0m fixture not found at %s\n" "$FIXTURE"
  exit 1
fi

# Parse and validate the fixture.
if ! jq -e . "$FIXTURE" >/dev/null 2>&1; then
  printf "  \033[31m✗\033[0m fixture is not valid JSON\n"
  exit 1
fi

CASE_COUNT=$(jq '.cases | length' "$FIXTURE")
if [ "$CASE_COUNT" -lt 5 ]; then
  printf "  \033[31m✗\033[0m fixture has fewer than 5 cases (found: %s)\n" "$CASE_COUNT"
  exit 1
fi

# Make a stub transcript file that the fixture references via the
# "EVAL_TRANSCRIPT" placeholder. The wrapper calls `wc -l` on it in
# the fallback path, so it must exist and be readable.
STUB_TRANSCRIPT=$(mktemp -t cc-ctx-eval-transcript.XXXXXX)
printf '{"type":"assistant","content":"hi"}\n{"type":"user","content":"hello"}\n' >"$STUB_TRANSCRIPT"
trap 'rm -f "$STUB_TRANSCRIPT"' EXIT

run_case() {
  local i="$1"
  local name
  name=$(jq -r ".cases[$i].name" "$FIXTURE")
  local type
  type=$(jq -r ".cases[$i].type" "$FIXTURE")
  local disable_ccusage
  disable_ccusage=$(jq -r ".cases[$i].disable_ccusage // false" "$FIXTURE")
  local stub_out
  stub_out=$(jq -r ".cases[$i].stub_ccusage_output // \"\"" "$FIXTURE")
  local stub_exit
  stub_exit=$(jq -r ".cases[$i].stub_ccusage_exit // 0" "$FIXTURE")
  local expect_exit
  expect_exit=$(jq -r ".cases[$i].expect_exit_code // 0" "$FIXTURE")
  local raw_stdin
  raw_stdin=$(jq -r ".cases[$i].raw_stdin // \"\"" "$FIXTURE")

  echo ""
  printf "Case %d/%d: %s (%s)\n" "$((i+1))" "$CASE_COUNT" "$name" "$type"

  # Build a tmp PATH with just the bare essentials plus an optional
  # stub ccusage. Keep node + npm + jq reachable so the wrapper's
  # "find ccusage" code path still runs realistically.
  local tmpdir
  tmpdir=$(mktemp -d -t cc-ctx-eval.XXXXXX)

  if [ "$disable_ccusage" = "false" ]; then
    # Write a stub `ccusage` that prints the fixture's stub_ccusage_output
    # verbatim and exits with the fixture's stub_ccusage_exit.
    cat >"${tmpdir}/ccusage" <<STUB
#!/usr/bin/env bash
# Test stub installed by run-evals.sh. Ignores its arguments and stdin,
# prints the canned fixture output.
cat <<'OUT'
${stub_out}
OUT
exit ${stub_exit}
STUB
    chmod +x "${tmpdir}/ccusage"
  fi

  # Build the stdin blob. Substitute EVAL_TRANSCRIPT with our real
  # transcript file so the wrapper can `wc -l` it without errors.
  local stdin_blob
  if [ -n "$raw_stdin" ] && [ "$raw_stdin" != "null" ]; then
    stdin_blob="$raw_stdin"
  else
    stdin_blob=$(jq --arg t "$STUB_TRANSCRIPT" --argjson idx "$i" \
      '.cases[$idx].stdin_json | .transcript_path = $t' "$FIXTURE")
  fi

  # Extract env overrides for this case (if any).
  local env_json
  env_json=$(jq -c ".cases[$i].env // {}" "$FIXTURE")

  # Run the wrapper. Isolate PATH — real Homebrew bins for jq/wc,
  # our stub dir for (maybe) ccusage, and nothing else. This ensures
  # `npx --no-install ccusage` fails fast in the disabled-ccusage case.
  local isolated_path="${tmpdir}:/usr/bin:/bin"
  # If ccusage is NOT disabled for this case and a real ccusage exists
  # on the host, we still hide it so the stub takes precedence. jq
  # must stay reachable for the wrapper's stdin validation.
  # /usr/bin:/bin covers jq on most systems; if jq lives elsewhere,
  # add its dir explicitly.
  local jq_dir
  jq_dir=$(dirname "$(command -v jq)")
  if [ -n "$jq_dir" ] && [ "$jq_dir" != "/usr/bin" ] && [ "$jq_dir" != "/bin" ]; then
    isolated_path="${isolated_path}:${jq_dir}"
  fi

  # Run the wrapper. We place the stdin blob in a temp file rather than
  # piping through `env -i` (which drops bash-c positional args in
  # confusing ways) so each case sees a clean, deterministic stdin.
  local stdin_file
  stdin_file=$(mktemp -t cc-ctx-eval-stdin.XXXXXX)
  printf '%s' "$stdin_blob" >"$stdin_file"

  local annotation
  annotation=$(echo "$env_json" | jq -r '.CC_STATUSLINE_ANNOTATION // ""')

  local out
  local actual_exit
  set +e
  out=$(env -i \
    PATH="$isolated_path" \
    HOME="$HOME" \
    CC_STATUSLINE_ANNOTATION="$annotation" \
    bash "$STATUSLINE" <"$stdin_file" 2>&1)
  actual_exit=$?
  set -e

  rm -f "$stdin_file"

  # Clean up stub.
  rm -rf "$tmpdir"

  # Exit code check.
  local case_fail=0
  if [ "$actual_exit" != "$expect_exit" ]; then
    printf "  \033[31m✗\033[0m exit code %s (expected %s)\n" "$actual_exit" "$expect_exit"
    case_fail=1
  else
    printf "  \033[32m✓\033[0m exit code %s\n" "$actual_exit"
  fi

  # expect_contains checks.
  local contains_count
  contains_count=$(jq ".cases[$i].expect_contains | length" "$FIXTURE")
  local k=0
  while [ "$k" -lt "$contains_count" ]; do
    local needle
    needle=$(jq -r ".cases[$i].expect_contains[$k]" "$FIXTURE")
    # Decode possible \u001b escape
    local needle_decoded
    needle_decoded=$(printf '%s' "$needle")
    if printf '%s' "$out" | grep -qF -- "$needle_decoded"; then
      printf "  \033[32m✓\033[0m contains: %q\n" "$needle_decoded"
    else
      printf "  \033[31m✗\033[0m missing substring: %q\n" "$needle_decoded"
      case_fail=1
    fi
    k=$((k+1))
  done

  # expect_not_contains checks.
  local not_count
  not_count=$(jq ".cases[$i].expect_not_contains | length // 0" "$FIXTURE")
  k=0
  while [ "$k" -lt "$not_count" ]; do
    local needle
    needle=$(jq -r ".cases[$i].expect_not_contains[$k]" "$FIXTURE")
    local needle_decoded
    needle_decoded=$(printf '%s' "$needle")
    if printf '%s' "$out" | grep -qF -- "$needle_decoded"; then
      printf "  \033[31m✗\033[0m unexpected substring present: %q\n" "$needle_decoded"
      case_fail=1
    else
      printf "  \033[32m✓\033[0m absent: %q\n" "$needle_decoded"
    fi
    k=$((k+1))
  done

  if [ "$case_fail" -ne 0 ]; then
    FAIL=$((FAIL+1))
    ERRORS+=("${name}")
    echo "  --- wrapper output ---"
    printf '%s\n' "$out" | head -5 | sed 's/^/  | /'
  else
    PASS=$((PASS+1))
  fi
}

i=0
while [ "$i" -lt "$CASE_COUNT" ]; do
  run_case "$i"
  i=$((i+1))
done

echo ""
echo "================================"
TOTAL=$((PASS + FAIL))
printf "Cases: \033[32m%d passed\033[0m, \033[31m%d failed\033[0m out of %d\n" "$PASS" "$FAIL" "$TOTAL"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Failed cases:"
  for err in "${ERRORS[@]}"; do
    printf "  \033[31m•\033[0m %s\n" "$err"
  done
  echo ""
  exit 1
fi

exit 0
