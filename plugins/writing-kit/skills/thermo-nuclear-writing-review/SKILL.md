---
name: thermo-nuclear-writing-review
description: Run an extremely strict prose review for structure, voice, and clarity of finished technical communication — design docs, RFCs, ADRs, blog posts, executive summaries, postmortems, README files, Slack thread retrospectives, customer-facing emails, or any AI-drafted writing that needs an unforgiving audit before it ships. Use for a thermo-nuclear writing review, thermonuclear prose review, deep writing audit, especially harsh editorial pass, or "tear this draft apart". Parallels `thermo-nuclear-code-quality-review` but applies its discipline to prose: writing-judo moves that delete whole sections, length-discipline limits, prose-spaghetti detection, AI-fingerprint and buzzword bans, voice consistency, and a final APPROVE / REVISE / MAJOR REVISION verdict.
user-invocable: true
---

# Thermo-Nuclear Writing Review

Use this skill for an unusually strict review of finished technical communication, focused on structure, voice, clarity, and the absence of AI fingerprints. This is the prose parallel of [`thermo-nuclear-code-quality-review`](https://github.com/cursor/plugins/tree/main/cursor-team-kit/skills/thermo-nuclear-code-quality-review): same demanding tone, same priority ordering, same "ambitious about structural simplification" stance — but for prose.

Above all, this skill should push the reviewer to be **ambitious about prose structure**. Do not merely identify local wording opportunities. Actively search for "writing-judo" moves: deletions and restructurings that preserve the argument while making the draft dramatically shorter, more direct, and harder to misread.

## When to invoke

- A draft is supposedly finished and needs an unforgiving editorial pass before it ships.
- The user asks for "a thermo-nuclear review", "tear this apart", "be brutal", "no soft feedback", or "is this ready to publish?".
- A reviewer wants the strict version, not the polite version.
- AI-drafted content needs an audit for fingerprints before going to a human reader.

Companion skill: [`deslop-tech-comms`](../deslop-tech-comms/SKILL.md) runs at draft time. This skill runs at review time. Use both for max effect.

## Core prompt

Start from this baseline:

> Perform a deep editorial audit of this draft. Rethink how to structure, sequence, and phrase the argument to meaningfully improve clarity and density without losing technical precision. Work to delete dead sections, sharpen vague claims, tighten run-on paragraphs, and eliminate AI fingerprints. Be ambitious — if there is a clear path to a much shorter or much sharper version, push hard for that path. Be thorough and rigorous. Measure twice, cut once.

## Non-negotiable additional standards

Apply the baseline prompt above, plus these explicit review rules.

### 0. Be ambitious about structural simplification

- Do not stop at "this could be a bit cleaner."
- Look for opportunities to **delete entire sections, paragraphs, or argumentative branches** without losing the load-bearing claims.
- Prefer the draft that makes the argument feel inevitable in hindsight.
- Assume there is often a "writing-judo" move available: a reframing that lets the author drop two of three rebuttals, or collapse three half-overlapping examples into one strong one.
- If you see a path to delete prose rather than rearrange it, push hard for that path.

### 1. Length discipline — the 1,000-word rule

- **Do not let a single section exceed 1,000 words without a very strong reason.** Treat this as a strong structural smell by default.
- Prefer extracting subsections, splitting examples into a separate piece, or just cutting material instead of letting a section sprawl.
- For full pieces: blog posts over 3,000 words, design docs over 2,500 words, postmortems over 1,500 words, and Slack threads over 6 messages all need an explicit justification. Length is not a virtue.
- Tight prose beats comprehensive prose. If the reader stops reading at the 1,500-word mark, the next 1,500 words contributed nothing.

### 2. No prose-spaghetti growth

- Be highly suspicious of new ad-hoc qualifiers, scattered parenthetical asides, or one-off "we should also note" insertions that tangle a clean line of argument.
- If a paragraph adds three hedges to defang one claim, the claim probably wasn't the right claim. Either commit to it or replace it.
- Prefer pushing supporting evidence into a dedicated subsection or footnote over stuffing it inline.
- Call out passages that make the surrounding argument harder to follow, even if they technically belong.

### 3. Bias toward redesign, not just acceptance

- If the piece reads correctly but the structure could be meaningfully clearer, push for the cleaner version.
- Do not rubber-stamp "the words are fine" drafts that leave the argument harder than necessary to follow.
- Strongly prefer simplifications that remove sections altogether over rewrites that just shuffle the same complexity.

### 4. Prefer direct, boring, maintainable prose

- Treat jargon, dead metaphors, and buzzword density as prose-quality problems.
- Be skeptical of generic frames ("paradigm shift", "force multiplier", "first principles") that hide simple claims behind impressive vocabulary.
- Flag opening throat-clearing ("Let me explain", "In today's fast-paced world", "I'd like to start by") that adds indirection without buying clarity.

### 5. Push hard on antecedent and reference cleanliness

- Question every unclear "this", "that", "it", "we", or unidentified pronoun. A draft that repeatedly says "this is important" without naming the antecedent is structurally broken.
- Prefer explicit nouns and named subjects over loose pronouns, especially across paragraph boundaries.
- Acronyms must be defined on first use. Internal jargon must either be defined or replaced with the plain noun.
- If a paragraph relies on the reader holding three abstract terms in working memory, the paragraph is over-engineered.

### 6. Keep claims in the canonical layer; reuse existing structure

- Call out feature claims that get restated three times across different sections instead of being made once well.
- Prefer one strong example over three half-overlapping examples.
- Push content toward the section where it actually belongs ("Risks" content stuffed in "Proposal" is a leak).
- If two sections are arguing the same thing, merge them or cut one.

### 7. Treat sequential scaffolding as a design smell when better structure is obvious

- If a piece is paced with "First / Then / Next / Finally" markers across consecutive sentences for no reason, the structure is leaking through the prose. Use a list, or use real transitions.
- If a series of independent points are serialized into one long paragraph for no reason, ask whether bullets would let the reader scan.
- Do not over-index on micro-style preferences, but do flag pacing constructs that make the piece more brittle than it needs to be.

## AI-fingerprint bans (mandatory cut-on-sight)

These are the patterns that mark a draft as AI-flavored regardless of the underlying content. A thermo-nuclear review must catch all of them.

### Phrases to cut

- "In today's fast-paced world" and all variants ("In today's AI-driven landscape", "As AI continues to reshape...", "In recent years").
- "It's important to note that", "It should be mentioned that", "Worth pointing out".
- "Let me explain", "I'd like to start by", "Before we dive in".
- **"Why it matters" / "What matters here" / "The part that matters" / "This matters when".** Cut the word "matters"; state the thing.
- **"Load-bearing" / "load bearing"**. Tech buzzword smell. Describe what the thing actually does instead.
- **"N reasons, one solution" framing**. "Two issues, one fix" / "Three suspicions, one cause". The symmetric count-then-resolve cadence reads as scaffolding. Either flowing prose or a plain list, never the count-vs-count opener.
- **Exclamation points** in formal technical writing.
- **"Great question" / chatbot enthusiasm** ("Excellent point!", "Happy to help!"). Treat the reader as a peer.

### Buzzword bans

These should not appear in shipped technical prose without a very specific justification:

leverage, utilize, facilitate, spearheaded, robust (without a specific behavior), seamless (without a specific user-visible property), cutting-edge, state-of-the-art, premier, elevate, synergy, turnkey, solution (as a generic noun), empower, paradigm shift, force multiplier, holistic, ecosystem (outside actual software-ecosystem contexts), unlock (as a verb for plain enablement), bleeding-edge.

Replacements:
| Avoid | Use instead |
|---|---|
| leverage | use |
| utilize | use |
| facilitate | run, set up, host |
| robust | name what makes it robust ("retries on 5xx", "idempotent") |
| seamless | name what makes it seamless ("no manual steps", "single API call") |
| empower | enable, let, give X the ability to |
| solution (generic) | name the specific change |

### Specificity rules

- **Replace adjectives with measurements**: "fast" → "p95 under 200ms", "large" → "12k rows", "often" → "twice a week".
- **Replace placeholder nouns with the actual thing**: "the system" → "the deployment pipeline".
- **Date every claim**: "recently" → an actual date or relative anchor.
- **Source every number**: a percentage in the body must be traceable to a source within three sentences.

### Fabrication ban

A made-up specific is worse than no specific because it makes the writing look both confident AND wrong. If a quantitative claim is not in the source material with a verifiable trace, **cut it or qualify it**. Pre-publish scan: every quantitative claim in body prose needs a source within three sentences, OR it gets flagged.

### Sentence-rhythm rules

- **Vary sentence length aggressively.** Three sentences of similar length in a row is a smell.
- **No fragment clusters.** Two short fragments back-to-back triggers AI smell. One fragment for punch is fine.
- **No "The" sentence-starter clusters.** Three sentences starting with "The" in a row signals AI cadence.
- **No sentence-initial "I" clusters.** Three "I" starters in a section, especially in status updates or self-promotional contexts, reads as both AI-flavored AND self-centered.

## Primary review questions

For every meaningful section, ask:

- Is there a "writing-judo" move that would let me delete this section entirely?
- Can this argument be reframed so two of three points become unnecessary?
- Does this paragraph make the piece more or less reader-friendly?
- Did the draft add three hedges where one strong claim would land?
- Did a previously focused section become rambling, exemplar-stuffed, or restated?
- Are these claims living in the right section, or did the draft leak details across structural boundaries?
- Did this draft enlarge a section past a healthy length boundary?
- Are there repeated similar examples that signal one missing canonical example?
- Is the prose direct and legible, or does it rely on jargon and dead metaphors?
- Is this section actually earning its keep, or is it a wrapper restating the thesis?
- Did the draft introduce ambiguous pronouns, undefined acronyms, or hedge-stacking that obscures the real claim?
- Is this content living in the canonical section for it, or did the draft duplicate it across two places?
- Is this pacing more sequential or less direct than it needs to be?

## What to flag aggressively

Escalate findings when you see:

- A complicated draft where a cleaner framing could delete whole paragraphs or sections.
- Rewrites that move prose around but fail to reduce the number of concepts the reader must hold.
- A section crossing 1,000 words due to the draft, especially when sub-claims could be split out.
- New hedges or qualifiers bolted onto otherwise direct claims.
- "Temporary" framing devices that are likely to become permanent prose debt (the same "background" subsection inflated across three revisions).
- Voice-specific bans firing in shipped prose: any of the buzzword list, any of the cut-on-sight phrases, fabricated specifics, fragment clusters, "The"-starter clusters, exclamation points in formal writing, chatbot enthusiasm.
- Narrow exception-case prose implemented in the middle of an already busy section.
- Sections that technically belong to the outline but actually duplicate content from a sibling section.
- Bespoke transitions / pacing constructs where the codebase of this piece already has a canonical structure (matching introductions across sections, etc.).
- Argument added in the wrong section/layer when it should live somewhere more central.
- Sequential pacing where bullets or a list would let the reader scan.
- Partial-claim hedging that leaves the reader unsure whether the author actually believes the claim.

## Preferred remedies

When you identify a prose-quality problem, prefer suggestions like:

- Delete a whole section rather than polish it.
- Reframe the argument so qualifying clauses disappear instead of accumulating.
- Change the section ownership so the side-claim becomes a natural extension of the canonical claim.
- Turn special-case carve-outs into a simpler default with fewer exceptions.
- Extract an example into a sidebar / appendix.
- Split a 1,200-word section into two focused sections under 600 words each.
- Move side-arguments into a "Risks" or "Open questions" section instead of letting them dilute the proposal.
- Replace condition chains ("if X, then Y, unless Z, except W") with a typed list or a small table.
- Separate orchestration prose from substantive argument.
- Collapse duplicate paragraphs into a single clearer one.
- Delete wrappers that do not meaningfully clarify the claim.
- Reuse the existing canonical example instead of introducing a near-duplicate.
- Make antecedents more explicit so the argument gets simpler.
- Move the content to the section that already owns the concept.
- Replace sequential pacing with a list or a small table.

Do not be satisfied with "maybe rename this section" feedback when the real issue is structural.
Do not be satisfied with a merely cleaner version of the same bloated idea when there is a plausible path to a much shorter idea.

## Review tone

Be direct, serious, and demanding about quality.
Do not be rude, but do not soften major structural issues into mild suggestions.
If the draft is making the piece harder to read, say so clearly.
If the draft missed an opportunity for a dramatic simplification, say that clearly too.

Good phrases:

- `this section is 1,400 words for a 200-word claim. can we cut it to a paragraph?`
- `this adds three hedges to a claim that should either be made or dropped. which is it?`
- `this works, but it makes the surrounding argument more spaghetti. let's keep the conclusion and restructure the section.`
- `this feels like Risks content leaking into the Proposal section. can we move it?`
- `this section seems unnecessary. can we just delete it and let the proposal stand?`
- `why do we need three examples of the same pattern? can we pick the strongest one and drop the others?`
- `this looks like a bespoke transition for something the rest of the piece already has a pattern for. can we reuse the canonical opener?`
- `i think there's a writing-judo move here that makes this section much shorter. can we reframe the argument so these qualifiers disappear?`
- `this rewrite moves prose around but doesn't really delete it. is there a way to make the argument itself simpler?`

## Output expectations

Prioritize findings in this order:

1. **Structural prose regressions** — section bloat, restated theses, leaked content across section boundaries
2. **Missed opportunities for dramatic simplification** — sections that could disappear, examples that could collapse
3. **Spaghetti / hedge accumulation** — qualifying clauses, parenthetical asides, "we should also note" stacking
4. **Antecedent / reference / acronym cleanliness** — ambiguous pronouns, undefined terms, hedges-as-style
5. **Length and decomposition** — sections past 1k words, full pieces past their genre's reasonable cap
6. **Voice and AI-fingerprint bans** — cut-on-sight phrases, buzzword density, fragment clusters, "The" / "I" clusters, exclamation marks, chatbot enthusiasm
7. **Specificity and sourcing** — adjectives that should be measurements, undated claims, fabricated quantitatives

Do not flood the review with low-value nits if there are larger structural issues.
Prefer a smaller number of high-conviction comments over a long list of cosmetic notes.

## Approval bar

Do not approve merely because the prose reads correctly.
The bar for approval is:

- no clear structural regression
- no obvious missed opportunity to make the argument dramatically shorter when such a path is visible
- no unjustified section-length sprawl
- no obvious hedge-spaghetti growth
- no obviously generic or buzzword-heavy phrasing that makes the piece feel AI-drafted
- no unnecessary restated-thesis churn that dilutes the argument
- no clear section-boundary leak
- no AI-fingerprint phrases (see the cut-on-sight list)

Treat these as presumptive blockers unless the author can justify them clearly:

- the draft preserves a lot of dead prose when a plausible writing-judo move would delete it
- the draft contains a section over 1,000 words without an explicit reason
- the draft adds hedges or qualifiers that make a clean claim murky
- the draft solves a local concern by scattering caveats across the piece
- the draft duplicates a claim or example already made elsewhere in the piece
- the draft contains any of the AI-fingerprint cut-on-sight phrases
- the draft contains any of the banned buzzwords without specific replacement

If those conditions are not met, leave explicit, actionable feedback and push for a tighter draft.

## Verdict

Every review ends with exactly one verdict:

- **`APPROVE`** — ready to ship. May still suggest 1–2 minor edits, but no structural changes required.
- **`REVISE`** — fixable in one editorial pass: surface-level cuts, buzzword replacements, sentence-rhythm rewrites, minor restructuring. The author can address every finding without rethinking the piece.
- **`MAJOR REVISION`** — structural rethink required: section bloat, missing canonical argument, the wrong structure for the surface, fundamental voice issues. The author should not just polish; they should re-outline.

A `REVISE` or `MAJOR REVISION` verdict must include a numbered action list with the specific changes required.

## Output shape

```
VERDICT: APPROVE | REVISE | MAJOR REVISION

Top findings (priority-ordered):
1. <structural issue, specific paragraph or section reference, suggested move>
2. <next priority issue>
3. <continued; aim for 3–8 high-conviction items, not 30 nits>

Voice / AI-fingerprint scan:
- <list specific phrases that fired against the cut-on-sight list, with line/section references>
- <list buzzwords that fired, with replacement suggestions>

Length and structure:
- <section-word-count callouts if any section exceeds 1k words>
- <piece-length callout if applicable>

Specific cuts proposed (writing-judo):
- <whole-section or whole-paragraph deletes proposed, with justification>

Action list (only on REVISE or MAJOR REVISION):
1. <specific change, with location reference>
2. <next>
...
```

## Guardrails

- **Respect the author's voice.** If the source has a distinctive cadence that is intentional and consistent (rapid-fire fragments, long Faulknerian sentences, deliberate em-dashes in a venue that allows them), preserve it. The AI-fingerprint bans target *unintentional* AI flavor, not deliberate style.
- **Don't rewrite the author's claims.** Flag a vague or unsourced claim; don't silently restate it stronger or weaker.
- **Don't add information.** If the draft lacks an action items section, flag the gap; do not invent action items.
- **Honor pre-existing style guides.** If the user has a brand voice file (e.g., `context/brand-voice.md`) or a project CLAUDE.md voice section, read it first and apply its rules on top of these defaults.
- **A short clear `MAJOR REVISION` is a useful review.** Do not soften the verdict because the author put work into the draft. Effort doesn't earn a ship decision.

## Companion skill

The proactive draft-time counterpart to this skill is [`deslop-tech-comms`](../deslop-tech-comms/SKILL.md). Use the deslop skill while drafting to prevent slop; use this skill to audit a finished draft.
