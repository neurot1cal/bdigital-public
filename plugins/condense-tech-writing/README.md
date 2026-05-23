# condense-tech-writing

Tighten AI-drafted technical writing (design docs, RFCs, ADRs, runbooks) without losing technical precision.

## What it does

Edits a draft in place, reports every change with reasoning, protects every number / API name / invariant / threshold / specific noun, and cuts the generic prose that could appear in any other doc. Output: trimmed draft + diff log + word-count delta.

## When it triggers

User pastes a draft and says one of: "condense", "tighten", "shorten", "trim", "compress", "too wordy", "too verbose", "edit for length". Or pastes a design-doc / RFC / ADR / runbook section with visible AI bloat.

## What it doesn't do

- Marketing copy / blogs / social — wrong voice profile
- Source text the user didn't write — use extractive summarization
- Code comments inside files — use targeted edits

## Install

```
/plugin marketplace add neurot1cal/bdigital-public
/plugin install condense-tech-writing@bdigital-public
```

## Tools granted

Read, Write, Edit, Bash. Bash is used only for `wc -w` to count words. No network, no file access outside what the user passes in.

## See also

- Full source + evals: [`samples/condense-tech-writing/`](https://github.com/neurot1cal/bdigital-public/tree/main/samples/condense-tech-writing)
- The companion blog post (TBD) walks through the research synthesis (Galileo, Refactoring English, PromptLayer, Louis Bouchard) that informed each step of the procedure.
