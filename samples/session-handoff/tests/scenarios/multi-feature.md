---
name: multi-feature
expect: rich-handoff
description: Agent should capture multiple decision threads and prioritize next steps across features
---

# Scenario: Multi-Feature Session

## Simulated Session Context

Session touched three areas in 90 minutes:

1. **New skill authoring** — created `owasp-csrf` skill, validated it, ran Tier 1+2 tests. Tier 2 had 1 false positive on a non-form POST endpoint. Decided to add a "Do NOT Flag" entry rather than tighten selectors.
2. **Docs site fix** — user reported the Catalog drawer doesn't close on ESC key. Fixed in `SkillDrawer.jsx` by adding `onKeyDown` handler. Committed.
3. **Started but didn't finish** — began updating `site/src/data/skill-overrides.json` with display names for 5 new skills. Got through 3 of 5 before the user said "let's wrap up."

Branch: `W-20515678/csrf-skill-and-fixes` with 3 commits.
Memory: no updates needed (all context is code-level).

## Expected Handoff Content

Must include:
- **What We Were Doing**: all three threads with clear status (done / done / partial)
- **Decisions Made**: the "Do NOT Flag" approach for the false positive (with rationale)
- **In-flight work**: which 3 of 5 overrides were done, which 2 remain
- **Next Steps**: finish overrides, run Tier 4 on owasp-csrf

Must NOT include:
- The actual onKeyDown handler code (it's committed)
- Full list of all 5 display name overrides
- Memory update section (none were needed)

## Red Flags (failure modes)

- Only captures the last thing worked on (recency bias)
- Doesn't specify which overrides are done vs remaining
- Decision rationale for the FP approach is missing
- Produces separate handoff prompts per feature instead of one unified prompt
