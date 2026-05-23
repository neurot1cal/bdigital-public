---
name: loop-on-ci
description: Monitor PR checks and fix failures until green. Uses gh pr checks as the source of truth for PR-attached checks.
---

# Loop on CI

## Trigger

Need to watch a branch or pull request and iterate on CI failures until all required checks are green.

Use `gh pr checks` as the source of truth. It includes all PR-attached checks, while `gh run list` only covers GitHub Actions.

## Workflow

1. Resolve the PR for the current branch.
2. Inspect current PR checks before waiting.
3. If checks already failed, diagnose those failures first.
4. If checks are pending, watch with `gh pr checks --watch --fail-fast`.
5. After each push, re-check the full PR check set and repeat until green.

## Commands

```bash
# Resolve the active PR
gh pr view --json number,url,headRefName

# Inspect all attached checks
gh pr checks --json name,bucket,state,workflow,link

# Watch pending checks and fail fast
gh pr checks --watch --fail-fast

# GitHub Actions logs, when the failing check links to a GHA run
gh run view <run-id> --log-failed
```

## Guardrails

- Keep each fix scoped to a single failure cause when possible.
- Do not bypass hooks (`--no-verify`) to force progress.
- If the failure is clearly unrelated to the PR and appears fixed on main, merge latest main instead of bloating the PR with unrelated fixes.
- If failures are flaky, retry once and report flake evidence.
- Re-run `gh pr checks --json name,bucket,state,workflow,link` after every push; the check set can change.

## Output

- Current CI status
- Failure summary and fixes applied
- PR URL once checks are green

---

> **Attribution:** Ported from [`cursor-team-kit/skills/loop-on-ci`](https://github.com/cursor/plugins/blob/3347cbab5b54136f6fba0994c3a01a56f7fb7fca/cursor-team-kit/skills/loop-on-ci/SKILL.md) by Team Cursor, MIT-licensed. Adapted to Claude Code primitives by bdigital media. See [`PORTING-NOTES.md`](../../PORTING-NOTES.md).
