---
name: get-pr-comments
description: Fetch and summarize review comments from the active pull request
---

# Get PR comments

## Trigger

Need a concise, actionable summary of feedback on the active pull request.

## Workflow

1. Resolve the active PR for the current branch.
2. Fetch review comments and discussion comments.
3. Group feedback by severity and actionability.
4. Return a concise action list.

## Output

- Grouped feedback summary
- Action list ordered by priority
- Open questions that still need clarification

---

> **Attribution:** Ported from [`cursor-team-kit/skills/get-pr-comments`](https://github.com/cursor/plugins/blob/3347cbab5b54136f6fba0994c3a01a56f7fb7fca/cursor-team-kit/skills/get-pr-comments/SKILL.md) by Team Cursor, MIT-licensed. Adapted to Claude Code primitives by bdigital media. See [`PORTING-NOTES.md`](../../PORTING-NOTES.md).
