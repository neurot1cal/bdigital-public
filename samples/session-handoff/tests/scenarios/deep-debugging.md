---
name: deep-debugging
expect: rich-handoff
description: Agent should capture dead ends, root cause, and mental model from a long debugging session
---

# Scenario: Deep Debugging Session

## Simulated Session Context

2-hour session debugging why Tier 4 shadow tests timeout on large PRs:

1. User reported: "shadow tests hang on PRs with >50 changed files"
2. Agent investigated `scripts/prizm-local-review.py` — found it spawns one Claude call per file
3. First hypothesis: rate limiting. Checked Anthropic API docs — rate limit is 60 RPM. Rejected: 50 files should be fine.
4. Second hypothesis: memory. Added logging, found Python subprocess accumulates memory per file. At 50 files, hits 4GB and OS kills it.
5. Fix: added batch processing (10 files per Claude call). Committed to branch `W-20512345/fix-shadow-timeout`.
6. Tests pass locally but CI is still running.
7. Along the way, discovered that `scripts/lib/sdk.py` has a hardcoded 120s timeout that should be configurable.
8. Memory updated: added note about the 4GB OOM threshold.

## Expected Handoff Content

Must include:
- **What Didn't Work**: rate limiting hypothesis and why it was rejected
- **Key Findings**: 4GB OOM threshold, per-file subprocess memory accumulation
- **Decisions Made**: batch processing (10 per call) and rationale
- **Next Steps**: wait for CI, follow up on configurable timeout in sdk.py
- **Branch and commit state**

Must NOT include:
- Full contents of prizm-local-review.py
- Complete git log
- Step-by-step replay of the debugging process

## Red Flags (failure modes)

- Handoff only mentions the fix, not the rejected approaches
- "Key Findings" is empty or generic ("found and fixed a bug")
- The sdk.py timeout observation is lost (it wasn't the main task but is valuable)
- Output exceeds 500 words (over-narrating the debugging journey)
