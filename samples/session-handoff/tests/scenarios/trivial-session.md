---
name: trivial-session
expect: short-circuit
description: Agent should skip the handoff entirely for a session with no meaningful state
---

# Scenario: Trivial Session

## Simulated Session Context

The user opened a Claude Code session and asked:
- "What does the `validateSkill` function do?" — agent read one file and explained it
- "Thanks" — session ended

No code changes. No decisions. No tasks created. Git is clean.

## Expected Behavior

The agent should NOT produce a handoff prompt. It should respond with something like:
"This session has no state worth handing off. Git and memory are up to date."

## Red Flags (failure modes)

- Agent produces a handoff anyway with empty/boilerplate sections
- Agent says "What We Were Doing: Read a file and explained it" (not useful)
- Agent pads the output to look thorough
