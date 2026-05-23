---
name: deslop-tech-comms
description: Use this skill whenever the user is drafting AI-generated technical communication — design docs, RFCs, ADRs, runbooks, release notes, executive summaries, Slack messages or threads, email updates, status reports, or any AI-drafted technical writing destined for human readers. Trigger phrases include "write a doc", "draft a Slack post", "summarize this for [audience]", "write an update", "polish this draft", "deslop this", "AI slop check", "tighten this writing", or "make this sound less AI". Enforces audience triage, surface-specific structure (Slack vs doc vs summary vs email), anti-slop checklist (no buzzwords, no fabricated metrics, vary sentence length, specificity over abstraction), and a final re-read pass for AI fingerprints. The companion `thermo-nuclear-writing-review` skill applies the strict critique after the fact; this one prevents the slop at draft time.
user-invocable: true
allowed-tools: Read, Write, Edit
---

# Deslop Technical Communications

Produce technical communication that does not read like AI slop. This skill applies at **draft time** — it shapes what the model writes, before any reviewer sees it. The companion [`thermo-nuclear-writing-review`](../thermo-nuclear-writing-review/SKILL.md) does the strict critique after the fact.

## When to invoke

- Drafting a design doc, RFC, ADR, runbook, postmortem, or release note.
- Writing a Slack message or thread (status update, decision, announcement, retro takeaway).
- Composing an email or external comms (vendor outreach, customer update, internal announcement).
- Summarizing a meeting, an investigation, or a long thread.
- Producing a status update or weekly recap.
- Polishing an existing AI draft that reads like slop.

Do **not** invoke this for code, code comments, or conversational chat.

## The technique in one paragraph

AI slop in technical communication has predictable fingerprints: generic openings ("In today's fast-paced world..."), buzzword density ("leverage", "synergy", "robust", "cutting-edge"), fabricated specifics (made-up numbers, invented citations), uniform sentence length, the "N reasons, one solution" symmetric framing, and a default 4-paragraph essay structure regardless of surface. The fix is **proactive structural commitment before generation**: pin audience, purpose, surface, and constraints up front; pick the format the surface actually needs; then write with a specific anti-slop checklist that runs at every paragraph break.

## Step 1 — Triage (always run first)

Before drafting a single sentence, confirm four things. If any is ambiguous, ask the user once.

| Dimension | Concrete question | Example answers |
|---|---|---|
| **Audience** | Who reads this? | "Senior engineers on the platform team" / "VP of Engineering and her staff" / "an oncall Slack channel of 12 people, half asleep" / "an external customer who paid for a refund" |
| **Purpose** | What does the reader do after? | Approve a decision / unblock a ticket / understand a postmortem / hit a deadline / stop worrying |
| **Surface** | Where does this land? | Slack message / Slack thread / Notion doc / GitHub README / customer email / executive memo |
| **Constraint** | Length, jargon, tone? | "Under 200 words, no jargon, friendly" / "Long-form, technical, no marketing tone" / "One Slack message, terse" |

If the user hasn't said, **default**: audience = engineer peers, purpose = inform, surface = doc, constraint = match the precedent of the user's other artifacts (read 1–2 of their recent writings before drafting).

## Step 2 — Pick the right structure for the surface

Different surfaces require different shapes. Do not apply the doc shape to a Slack message or vice versa.

### Slack message (single)

- One message, under 500 characters, opens with the conclusion.
- No greeting line ("Hey team,"). No sign-off.
- One hyperlink max. No multi-paragraph essay collapsed into one message.

### Slack thread (multi-message)

- Hook message under 300 chars: conclusion + one question or call to action.
- Body messages 1–3 short paragraphs each, one idea per message.
- End the thread with a single explicit next step ("I'll pick this up Monday unless someone objects").

### Design doc / RFC / ADR

Order: **TL;DR → Context → Proposal → Alternatives considered → Risks and open questions → Decision and next steps**.

- TL;DR is 2–4 sentences. State the problem and the proposed answer. No throat-clearing.
- Each section earns its place; cut any section you can't fill with substance.
- Alternatives section names the alternatives and says why each was rejected. "We chose this because it's best" is not an alternatives section.
- Risks section names specific failure modes, not "this might be hard".

### Postmortem / incident retro

Order: **Summary → Impact → Timeline → Root cause → What worked / what didn't → Action items with owners and dates**.

- Summary is 3 sentences max. State what broke, who was affected, and how long.
- Timeline is bullet-per-event with timestamps. Not prose.
- Root cause is the cause, not the symptoms. If you wrote "the system went down because of a bug", you have not stated a root cause.
- Action items have owners and dates. "We should look into X" is not an action item.

### Release notes / changelog entry

- One bullet per change. Lead with the verb ("Fixed", "Added", "Removed").
- User-facing impact in the first half of the sentence. Implementation detail in parens at the end if needed.
- Group by audience: external-facing changes first, then internal.

### Executive summary

- 5 sentences max for the headline summary.
- Bullet structure for the body: **status → blockers → asks**.
- Numbers must be sourced. No "approximately" without an actual number behind it.

### Email (internal or external)

- Subject line states the action or the topic, not "Quick question" or "Following up".
- First sentence states the purpose. Save context for paragraphs 2–3.
- Max 3 paragraphs. If you need a fourth, attach a doc.
- Sign-off is bare ("— Bob") unless formality is required.

### Status update / weekly recap

- Three sections: **shipped / in progress / blocked**.
- "Shipped" lists merged work with one-line user-facing impact each.
- "In progress" includes ETA and current confidence.
- "Blocked" names the blocker and the person who can unblock it.

## Step 3 — Anti-slop checklist (apply at every paragraph break)

These are the AI fingerprints that signal slop. Catch them at draft time, not in review.

### Cut on sight

- **Generic openers**: "In today's fast-paced world", "As AI continues to reshape", "It is widely known that", "In recent years", "Let me explain", "I'd like to start by".
- **The N-reasons-one-solution frame**: "Three issues, one fix" / "Two suspicions, one cause" / "Five concerns, one answer". The symmetric count-then-resolve cadence reads as scaffolding. Either flowing prose or a plain list, never the count-vs-count opener.
- **Throat-clearing**: "It's important to note that...", "It should be mentioned that...", "Worth pointing out...". Just state the thing.
- **"Why it matters" or its flavors**: "Why this matters", "What matters here", "The part that matters", "This matters when". Cut the word; state the thing.
- **"Load-bearing"**: tech buzzword smell. Describe what the thing actually does instead.
- **Exclamation points** in formal technical writing (Slack acks are fine).
- **Chatbot enthusiasm**: "Great question!", "Happy to help!", "Excellent point!". Treat the reader as a peer.

### Buzzword bans

| Avoid | Use instead |
|---|---|
| leverage | use |
| utilize | use |
| facilitate | run, set up, host |
| spearheaded | led, ran |
| robust | name what makes it robust ("retries on 5xx", "idempotent") |
| seamless | name what makes it seamless ("no manual steps", "single API call") |
| cutting-edge / state-of-the-art / premier | name the specific capability and date it |
| synergy | name the specific interaction |
| turnkey | name what someone has to do (or not do) |
| elevate | improve, raise, lift |
| solution | name the specific change |
| empower | enable, let, give X the ability to |

### Specificity rules

- **Replace adjectives with measurements** where possible. "Fast" → "p95 under 200ms". "Large" → "12k rows". "Often" → "twice a week".
- **Replace placeholder words with the actual thing**: "the system" → "the deployment pipeline". "the team" → "the platform team". "users" → "free-tier users on the mobile app".
- **Date your facts**. "Recently" → a date or a relative anchor ("last sprint", "2026-04-10").
- **Source your numbers**. If you wrote a percentage, you should be able to point at where it came from in one sentence. If you can't, cut the percentage.

### No fabricated quantitative claims

This is the strictest rule, and the easiest to violate when an AI is drafting confidently. A made-up number is worse than no number because it makes the writing look both confident AND wrong. Mileage thresholds, temperatures, percentages, time spans, failure rates, sensory experiences ("user feels", "lazy response under load"): if it isn't already in the source material with a verifiable trace, do NOT write it. Use qualitative language ("over time", "under sustained load", "with use") OR cite the source ("per the dashboard at $URL", "per the postmortem in $DOC").

Pre-publish scan: every quantitative claim needs a source within three sentences, OR it gets cut.

### Sentence-rhythm rules

- **Vary length aggressively.** Mix short sentences with longer 20+ word narratives. Three sentences of similar length in a row is a smell.
- **No fragment clusters.** Two short fragments back-to-back is enough to trigger AI smell. One fragment for punch is fine.
- **No "The" sentence-starter clusters.** Three sentences starting with "The" in a row is a signal.
- **No sentence-initial "I" clusters.** Three "I" starters in a section, especially in a self-promotional or status-update context, reads as both AI-flavored AND self-centered. Titles never start with "I".

### Honest about what you don't know

When the source material is thin or contradictory, say so. "I don't have data on X" beats invented data on X. Hedging is allowed when the underlying fact is genuinely uncertain; what's banned is hedging-as-style ("might possibly somewhat occasionally").

## Step 4 — Surface-specific prompt templates

When the user asks for a specific surface, use these as the prompt scaffold inside this skill before writing.

### Slack message scaffold

```
Audience: <who reads this>
Purpose: <what they should do after reading>
Conclusion: <the one sentence>
Evidence/context (optional, 1–2 lines): <only if the conclusion isn't self-evident>
Call to action (if any): <one explicit next step>
Constraint: ≤500 chars, no greeting, no sign-off, ≤1 link
```

### Design doc scaffold

```
Title: <verb-led, ≤10 words>
TL;DR: <2–4 sentences: the problem and the proposed answer>
Context: <what the reader needs to know to evaluate the proposal>
Proposal: <the actual plan, with the load-bearing technical content>
Alternatives considered: <each named, with a sentence on why rejected>
Risks and open questions: <specific failure modes, not "this might be hard">
Decision and next steps: <who decides by when; what unblocks next>
```

### Postmortem scaffold

```
Summary: <3 sentences: what broke, who was affected, how long>
Impact: <numbers: users, revenue, time-to-detect, time-to-mitigate, time-to-resolve>
Timeline: <bullet per event with timestamps>
Root cause: <the cause, not the symptoms — name the chain that ended at the visible failure>
What worked: <what already in place limited the blast radius>
What didn't: <what was missing or slow>
Action items: <each with owner and date>
```

### Status update scaffold

```
Shipped this week: <bullets with user-facing impact, not internal mechanics>
In progress: <ETA + confidence>
Blocked: <blocker + who can unblock>
```

## Step 5 — Final re-read pass (always run)

Before returning the draft, do one more pass:

1. **Read the first sentence aloud**. If it starts with "In today's", "Let me", "I'd like to", or any throat-clearing phrase, cut it and re-read.
2. **Scan for the buzzword list**. Search the draft for: leverage, utilize, facilitate, robust, seamless, cutting-edge, state-of-the-art, synergy, turnkey, elevate, solution (as a generic noun), empower. If any survived, replace.
3. **Check every quantitative claim** has a source within three sentences. If not, cut or qualify.
4. **Check sentence rhythm**. Three similar-length sentences in a row: rewrite one. Two fragments back to back: combine.
5. **Check headings**. Does each heading describe the content, not its importance? ("Migration plan" yes; "Why this matters" no.)
6. **Check the close**. If it summarizes what was just said, cut it. If it adds a hedge ("Of course, your mileage may vary"), cut it.

## Output

Return the deslopped draft. If the user asked for a specific surface, deliver exactly that surface (one Slack message, not a doc that says "and here's how I would write it on Slack").

After the draft, append a brief **"what I changed"** note (3–6 bullets) so the user can verify the slop bans were honored. Example:

```
Changes made vs source material:
- Replaced "leverage" → "use" (4 instances)
- Replaced generic opener "In today's fast-paced AI landscape..." with the concrete claim
- Cut two unsourced percentages ("about 30%", "over half")
- Tightened 6-paragraph essay to 3 paragraphs + bullets for the proposal
- Removed throat-clearing close ("It's worth noting that...")
```

This makes the deslop pass auditable. The reader sees both the polished output and the evidence that the slop rules ran.

## Guardrails

- **Respect the author's voice.** If the source has a distinctive cadence (long Faulknerian sentences, rapid-fire fragments, a specific punctuation tic that's intentional), preserve it. The anti-slop rules target *AI fingerprints*, not all stylistic choices.
- **Don't deslop the source content.** Tighten the prose, not the facts. If the source contains a claim, keep it (or cut it explicitly with a note); do not silently rewrite the claim itself.
- **Don't add information.** If the source doesn't have the postmortem timeline, the deslopped postmortem doesn't have it either. Surface the gap; do not invent.
- **Length floor.** Some surfaces have a legitimate minimum (a postmortem with no timeline isn't a postmortem). If the source genuinely lacks structural prerequisites, say so and propose what to gather, rather than fabricating structure.
- **Honor pre-existing style guides.** If the user has a brand voice file (e.g., `context/brand-voice.md`) or a CLAUDE.md voice section, read it first and apply its rules on top of these defaults.

## Companion skill

The reactive critique counterpart to this skill is [`thermo-nuclear-writing-review`](../thermo-nuclear-writing-review/SKILL.md). Use the deslop skill while drafting; use the thermo-nuclear skill to audit a finished draft (yours or someone else's) for structural and voice issues with a strict APPROVE/REVISE/MAJOR verdict.
