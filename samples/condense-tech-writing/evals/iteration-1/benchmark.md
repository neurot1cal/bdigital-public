# condense-tech-writing — Iteration 1 Benchmark

## Headline

| Configuration | Pass rate | Mean duration | Mean tokens |
|---|---|---|---|
| **with_skill** | **20/22 (91%)** | 33.6s | 23,850 |
| without_skill (baseline) | 13/22 (59%) | 20.1s | 20,049 |
| **Delta** | **+32 pp** | +13.5s | +3,801 |

## Per-eval breakdown

| Eval | with_skill | without_skill |
|---|---|---|
| trivial-tight (short-circuit case) | **3/3 (100%)** | 1/3 (33%) |
| bloated-design-doc-section | 9/10 (90%) | 6/10 (60%) |
| generic-security-block | 8/9 (89%) | 6/9 (67%) |

## What the skill did better than baseline

1. **Short-circuit on already-tight input.** The trivial-tight test (35-word webhook signature note) is the strongest discriminating signal. With-skill recognized the input was tight and refused to trim. Baseline produced a 24-word trim that subtly broadened "Requests without a valid signature" to "Invalid or missing signatures", introducing a category (missing) that was not in the original. Exactly the regression the skill exists to prevent.

2. **Structured output (diff log + stats).** Every with-skill run produced a numbered diff log and a stats block with original / trimmed / percentage / rejected-edit counts. Baseline produced prose summaries that are not auditable line-by-line.

3. **No em dashes in trimmed output.** The baseline on eval-1 introduced an em dash ("list-after-write semantics — track uploaded keys"). The with-skill output reliably avoids them per the skill's explicit "no em dashes" rule.

4. **Explicit "generic-prose first" pass.** The with-skill output on eval-2 walked through each cut paragraph and labeled it as generic ("standard web-app checklist", "generic compliance statement"). Baseline cut the same paragraphs but did not surface the categorization. The label is what lets the reviewer trust the cut.

## What the baseline did equally well

- Preserved every technical specific across all three cases (R2, bdigital-clips, zero egress, eventual consistency, clips.json, /api/download, Stripe webhook trigger, 1-hour TTL, clip-ID-and-customer-email binding). No accuracy regressions in either configuration.
- Identified the right paragraphs to cut on eval-2. The baseline correctly recognized the security section was mostly generic prose; the skill did not provide a meaningful accuracy advantage on that recognition task, only on the output structure.

## Where the skill needs work

1. **Word-count floor calibration.** With-skill cut to 148 words on eval-1 (assertion floor: 150) and 63 words on eval-2 (assertion floor: 100). In both cases the cut was correct (no technical content lost per the diff audit), but the floors were too tight for inputs that are >60% generic prose. Options for iteration 2: (a) raise the assertion floors to match the skill's own 60% audit threshold, (b) add a Step 7 in the skill that warns the user when the cut went past 60% and asks for confirmation, (c) leave it and trust the audit.

2. **Latency overhead.** With-skill runs are ~13s slower per eval. For one-shot use that is fine; for repeated invocations in one session, the Step 1 classification redoes work each time. A future optimization could cache the classification within a session.

3. **The skill helped less on eval-2 than expected.** The baseline got 6/9 on the generic-security-block case, which means a vanilla Claude with no skill can identify generic best-practices wallpaper. The skill's value on this case was the structured diff log, not the cut decision itself.

## Recommendation

Ship the skill at v0.1 with these eval results. The +32 pp pass-rate advantage and the short-circuit behavior on tight drafts are real wins. Two follow-ups for v0.2:

- Recalibrate the word-count assertion floors against the skill's own audit threshold (60%), not against the user's nominal "half the length" ask
- Add a small example in SKILL.md showing the short-circuit output format for tight inputs (this iteration's with-skill response on eval-0 is itself a good template)
