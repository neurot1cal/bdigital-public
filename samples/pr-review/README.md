# pr-review sample

Automated pull request review built as structured Claude skills.

This sample accompanies the three-part blog series on
[tech.bdigitalmedia.io](https://tech.bdigitalmedia.io/blog/designing-ai-pr-review-claude-skills).
Each review skill is a versioned markdown file with named sections
(detection rules, exclusion categories, evidence requirement, scope filter,
output format). When a skill misfires, the fix lives inside a specific
section of the markdown, not in a prompt rewrite.

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

## Customizing

- **Add a skill.** Drop a new `.md` file into `.claude/skills/` following
  the seven-section shape. The wrapper picks it up automatically.
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
