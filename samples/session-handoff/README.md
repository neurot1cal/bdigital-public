# session-handoff sample

A user-invocable Claude Code skill that generates a self-contained prompt
letting a fresh Claude Code session resume where a previous one left off.

This sample is a different shape from [`samples/pr-review/`](../pr-review/):
pr-review skills are structured LLM prompts invoked by a CI wrapper, while
`session-handoff` is an **interactive** skill loaded into a running Claude
Code session and triggered by the user (via `/session-handoff`, or phrases
like "handoff", "wrap up", "session summary"). Both are markdown-with-
frontmatter, but the frontmatter, tool scope, and intended runtime differ.

## What is included

```
session-handoff/
├── SKILL.md                         # the skill itself (frontmatter + procedure)
└── tests/
    ├── test-skill-structure.sh      # 36 structural regression tests
    └── scenarios/
        ├── trivial-session.md       # expected: short-circuit, no handoff
        ├── multi-feature.md         # expected: rich handoff across threads
        └── deep-debugging.md        # expected: rich handoff w/ dead ends
```

## Why a handoff skill

Claude Code sessions accumulate context: decisions made, approaches tried
and rejected, mental model built up around a bug. Git state, file contents,
and memory files are recoverable by a fresh session — **the session-
specific reasoning is not**. This skill implements the "Clear — start a
new session, usually with a brief you've distilled" pattern from
[Anthropic's session management guide](https://claude.com/blog/using-claude-code-session-management-and-1m-context).
The handoff IS the brief.

Typical triggers:

- The session is nearing context limits (auto-compaction is imminent)
- You've corrected Claude 2+ times on the same issue (context is polluted)
- You just solved a hard debugging problem and the "how we got here" is
  fresh but non-obvious
- You're about to switch to an unrelated task

## Install

Copy `SKILL.md` into a `.claude/skills/session-handoff/` directory in the
project (or `~/.claude/skills/session-handoff/` for user-global install).
Claude Code picks up skills from these directories automatically on
session start.

```bash
mkdir -p .claude/skills/session-handoff
cp samples/session-handoff/SKILL.md .claude/skills/session-handoff/
```

Invoke with `/session-handoff` inside Claude Code, or trigger implicitly
via phrases like "handoff", "session summary", or "wrap up".

## Run the tests

`tests/test-skill-structure.sh` is a pure-bash regression test over the
structural invariants described in the CSO skill-authoring rules:
frontmatter shape, required sections, guardrail phrases, absence of
anti-patterns (hardcoded configs, domain-specific heuristics), and word-
count budget.

```bash
bash samples/session-handoff/tests/test-skill-structure.sh
```

Exit 0 = all green, exit 1 = failures. The test runner exercises 36
assertions and finishes in under a second.

The `tests/scenarios/` directory holds three qualitative fixtures that
describe the **expected behavior** of the skill for three canonical
session shapes (trivial, multi-feature, deep debugging). They are not
auto-graded — they are reference cases for human review when tuning the
skill's guardrails.

## Customizing

- **Change the output format.** Edit the fenced prompt template under
  "Step 4: Generate Handoff Prompt" in `SKILL.md`. Sections are additive
  — add your own (e.g. `### Open Questions`) if your workflow needs it.
- **Tighten or loosen the short-circuit.** The "Short-circuit" block in
  "When to Use" is what prevents bogus handoffs from trivial sessions.
  Adjust the phrasing if you want the skill to be more or less eager.
- **Swap the memory strategy.** Step 3 assumes memory lives under
  `~/.claude/projects/<project-path>/memory/`. If your project uses a
  different persistence layer, rewrite that step accordingly.

## License

MIT. Fork, adapt, ship.
