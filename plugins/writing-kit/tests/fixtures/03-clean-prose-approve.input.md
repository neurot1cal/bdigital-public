# Already-tight design doc snippet (clean input)

## TL;DR

The current deployment pipeline serializes a step that does not need to be
serial. Refactoring to parallel cuts pipeline runtime from $CURRENT_AVG to
roughly $TARGET_AVG and removes a class of timeout incidents that have
fired three times in the last 90 days.

## Proposal

Run the artifact-scan step concurrently with the integration-test step
instead of waiting for scan to complete first. The two steps share no
state and write to different artifact directories.

## Risk

If artifact-scan finds a critical violation after integration-test has
already started, we waste integration-test compute. The waste budget is
roughly $WASTE_BUDGET_PCT of one CI minute per occurrence, well under the
expected savings from parallel execution.
