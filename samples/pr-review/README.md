# pr-review sample

Automated pull request review built as structured Claude skills.

This sample accompanies the three-part blog series on
[tech.bdigitalmedia.io](https://tech.bdigitalmedia.io/blog/designing-ai-pr-review-claude-skills).
Each review skill is a versioned markdown file with frontmatter plus
six named sections (system prompt, detection rules, exclusion categories,
evidence requirement, scope filter, output format). When a skill misfires,
the fix lives inside a specific section of the markdown, not in a prompt
rewrite.

## What is included

```
pr-review/
├── .claude/
│   └── skills/
│       ├── correctness-reviewer.md       # intent vs implementation
│       ├── test-adequacy-reviewer.md     # tests actually exercise the change
│       ├── design-fit-reviewer.md        # does this belong here, now, at this scope
│       ├── readability-reviewer.md       # naming, comments, cognitive complexity
│       └── breaking-change-reviewer.md   # api signatures, schemas, contract drift
├── scripts/
│   └── run-reviews.mjs                   # wrapper that invokes each skill
└── .github/
    └── workflows/
        └── pr-review.yml                 # drop-in GitHub Actions workflow
```

## Why only five skills

The blog series identifies six minimum categories: correctness, security,
test adequacy, design fit, readability, and breaking-change impact. This
sample ships five, leaving security-sensitive pattern review out on purpose.
Concrete security detection rules are better maintained against OWASP's
published checklists and existing SAST tooling than re-authored as a
general-purpose LLM skill. If you want a security review skill, we recommend
starting from the OWASP Code Review Guide and adapting it to your threat
model rather than cloning one from a public sample.

## Setup

1. **Copy the sample into your repo.** Copy `.claude/skills/`,
   `scripts/run-reviews.mjs`, and `.github/workflows/pr-review.yml` into
   the matching paths in your own repository.

2. **Add an Anthropic API key as a repo secret.** Settings → Secrets and
   variables → Actions → New repository secret. Name it
   `ANTHROPIC_API_KEY`. The workflow references this secret.

3. **Install Node 20 on the runner.** The wrapper uses native `fetch` and
   `fs/promises`, both available in Node 20+. The workflow is pinned to
   `ubuntu-latest`, which already ships Node 20.

4. **Grant the workflow write access to pull request comments.** The
   workflow sets `permissions: pull-requests: write`. No further config is
   needed for public repos; for private repos, make sure your organization
   Actions settings do not override this.

5. **Open a PR.** The workflow triggers on `pull_request` events for
   `opened` and `synchronize`. Expect each review skill to take roughly
   15–30 seconds to run.

6. **Bump the model ID when a newer dated release lands.** The wrapper
   pins a concrete dated Claude model ID (see the `model:` line in
   `scripts/run-reviews.mjs`). Bare aliases like `claude-sonnet-4-6` can
   404 against the public Messages API; always use the latest dated
   release (for example `claude-sonnet-4-6-20260201`) and update the
   string in `run-reviews.mjs` whenever Anthropic publishes a newer
   dated release.

### Fork PRs

Pull requests opened from a fork trigger the `pull_request` event, but
fork workflows run with a read-only `GITHUB_TOKEN`, and repository
secrets (including `ANTHROPIC_API_KEY`) are not exposed to fork PRs for
security reasons. As a result, this workflow will fail on fork PRs until
a maintainer re-runs the workflow from the PR page (which runs it in the
base repository's context with the secret available).

We do not recommend swapping `pull_request` for `pull_request_target` as
a workaround. `pull_request_target` runs against the base branch's
workflow and checks out fork code with repo secrets present, which is a
well-documented arbitrary-code-execution risk. Keep the workflow on
`pull_request` and accept the manual re-run on fork contributions.

## Eval fixtures and the Executor/Grader split

Every skill also ships a JSON eval fixture under `evals/<skill>.json` with
3–5 labeled cases (positive + negative). The runner at
`scripts/run-evals.mjs` mirrors Anthropic's skill-creator Executor/Grader
split:

1. **Executor phase.** Run the skill against each case's diff using the
   skill as the system prompt. Default model: `claude-sonnet-4-6-20260201`.
2. **Grader phase.** Send the Executor's findings and the expected findings
   to a separate model call with a grader-only system prompt. The grader
   returns `{ passed, reason }`. Default grader model:
   `claude-haiku-4-5-20251001` (different tier, different prompt, so the
   grader does not share the reviewer's biases).

Run all evals:

```bash
node samples/pr-review/scripts/run-evals.mjs \
  --skills samples/pr-review/.claude/skills \
  --evals samples/pr-review/evals \
  --out samples/pr-review/evals/results.json
```

Use `--only <skill>` to run a single skill's fixture, or
`--executor-model` / `--grader-model` to override the defaults.

Results are written to `evals/results-<timestamp>.json` (plus the
`--out` path). Non-zero exit if any case fails.

The two-or-three inline cases inside each skill's `## Examples` section
are few-shot calibration for inference; they overlap with the first
couple of fixture cases on purpose so that reading the skill reveals
what the skill expects to catch. The full labeled corpus belongs in the
eval fixture, not in the prompt.

## Customizing

- **Add a skill.** Drop a new `.md` file into `.claude/skills/` following
  the frontmatter-plus-six-named-sections shape. The wrapper picks it up
  automatically.
- **Tune a skill.** Open the markdown file, find the named section, and
  edit. Detection rules live in one section, exclusions in another, scope
  filters in a third. Changes land as normal PRs.
- **Disable a skill temporarily.** Rename the file to `.md.disabled` or
  move it out of `.claude/skills/`.
- **Change the output channel.** The workflow posts inline review comments
  by default. To post a single summary comment instead, replace the
  `github-script` step with a call to
  `github.rest.issues.createComment({ ... })` using the aggregated
  findings.

## How the wrapper works

`scripts/run-reviews.mjs` is a thin Node script. For each skill file in
`.claude/skills/`:

1. Load the markdown content.
2. Send it as the system prompt to the Anthropic API.
3. Send the PR diff as the user message.
4. Parse the structured JSON response into an array of findings.
5. Accumulate across all skills and write to the output JSON file.

The wrapper gives the model read-only access to the checked-out repo so
that findings can verify claims against actual code. This is why the
workflow uses `fetch-depth: 0` on the checkout step.

## Expected output shape

Each finding in `findings.json` has this shape:

```json
{
  "skill": "correctness-reviewer",
  "severity": "medium",
  "file": "src/orders/checkout.ts",
  "line": 42,
  "rationale": "Branch at line 42 returns before calling finalize(), which leaks the pending transaction.",
  "evidence": "Confirmed finalize() is expected based on orders/README.md and the sibling test file."
}
```

The workflow's GitHub-script step translates each finding into a
`pull_request_review_comment` attached to the specific file and line.

## Calibrating against noise

The blog series' Part 2 and Part 3 cover what to do when these skills
produce too many false positives. The short version: audit findings on
real PRs, cluster false positives by root cause (not by symptom), and
apply one of the four structural fix patterns to the specific skill
section that generated the noise.

## License

MIT. Fork, adapt, ship.
