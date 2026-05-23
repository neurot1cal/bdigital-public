# cursor-team-kit (Claude Code port)

Claude Code port of [Cursor's `cursor-team-kit`](https://github.com/cursor/plugins/tree/main/cursor-team-kit) — internal-style workflows for CI loops, code review, shipping, test reliability, code-quality audits, and weekly work summaries. Designed to work without third-party service integrations.

## Attribution

**Original work:** [`cursor-team-kit`](https://github.com/cursor/plugins/tree/main/cursor-team-kit) by Team Cursor (`plugins@cursor.com`). MIT-licensed.

This port preserves Cursor's authorship, copyright, and license notice as required by MIT. Every adapted SKILL.md and agent file includes an attribution line in its frontmatter pointing to the upstream source. The intent, structure, naming, and prose of each skill are Cursor's — only the primitives have been adapted to Claude Code's plugin schema.

If you found this useful, the people to thank are Team Cursor. Open issues and improvement ideas welcome here, but credit for the design and writing flows upstream.

## What ports cleanly vs what was adapted

| Cursor primitive | Claude Code equivalent | Adaptation |
|---|---|---|
| `.cursor-plugin/plugin.json` (skills/agents/rules paths) | `.claude-plugin/plugin.json` (name, description, author) | Rewritten — different schema |
| `skills/<name>/SKILL.md` | `skills/<name>/SKILL.md` | Mostly drop-in. `disable-model-invocation: true` → `user-invocable: true` (preserves narrow-trigger intent) |
| `agents/<name>.md` w/ `model: fast`, `is_background: true` | `agents/<name>.md` subagent files | `model: fast` dropped (parent context picks model); `is_background: true` has no equivalent and is dropped; body refs to `subagent_type: shell`/`explore` rewritten as `Bash` / `Explore` tool calls |
| `rules/*.mdc` w/ `alwaysApply: true` | No direct equivalent | Folded into [`CLAUDE.md`](./CLAUDE.md) as advisory guidance. Claude Code does not auto-inject project-rule fragments the way Cursor does — these guidelines apply when this plugin's `CLAUDE.md` is in scope or when an individual skill references them |
| `pr-review-canvas/{renderer.js, styles.css, template.html}` | Same files | Preserved verbatim — they're just static assets the skill reads at runtime |

See [`PORTING-NOTES.md`](./PORTING-NOTES.md) for the per-file change log.

## Components

### Skills (16)

| Skill | Description |
|:------|:------------|
| `loop-on-ci` | Watch PR checks and iterate on failures until checks pass |
| `review-and-ship` | Run a structured review, commit changes, and open a PR |
| `pr-review-canvas` | Generate an interactive HTML PR walkthrough with annotated, categorized diffs |
| `verify-this` | Prove or disprove claims with baseline/treatment artifacts and a clear verdict |
| `control-cli` | Build or adapt a local harness to drive and profile interactive CLIs or TUIs |
| `control-ui` | Build or adapt a local browser/CDP harness for web or Electron UIs |
| `make-pr-easy-to-review` | Clean noisy PR history, improve descriptions, and add reviewer guidance |
| `run-smoke-tests` | Run Playwright smoke tests and triage failures |
| `fix-ci` | Find failing CI jobs, inspect logs, and apply focused fixes |
| `new-branch-and-pr` | Create a fresh branch, complete work, and open a pull request |
| `get-pr-comments` | Fetch and summarize review comments from the active pull request |
| `check-compiler-errors` | Run compile and type-check commands and report failures |
| `what-did-i-get-done` | Summarize authored commits over a given time period into a status update |
| `weekly-review` | Generate a weekly recap of shipped work with bugfix/tech-debt/net-new highlights |
| `fix-merge-conflicts` | Resolve merge conflicts, validate build/tests, and summarize decisions |
| `deslop` | Remove AI-generated code slop and clean up code style |
| `workflow-from-chats` | Extract durable working preferences from chats into skills, rules, or docs |
| `thermo-nuclear-code-quality-review` | Run an unusually strict maintainability review (code-judo, 1k-line rule, spaghetti, boundaries) |

### Agents (2)

| Agent | Description |
|:------|:------------|
| `ci-watcher` | Monitor GitHub Actions runs and return concise pass/fail summaries |
| `thermo-nuclear-code-quality-review` | Task subagent that runs the thermo-nuclear rubric against a diff |

### Rules → CLAUDE.md (2)

Folded into [`CLAUDE.md`](./CLAUDE.md) — `typescript-exhaustive-switch` and `no-inline-imports` are listed there as advisory guidance, since Claude Code has no auto-apply rules primitive.

## Installation

This plugin is distributed via the `bdigital-public` marketplace. From Claude Code:

```
/plugin marketplace add neurot1cal/bdigital-public
/plugin install cursor-team-kit@bdigital-public
```

Or for development against a local checkout:

```
/plugin marketplace add ~/git/bdigital-public
/plugin install cursor-team-kit@bdigital-public
```

## License

MIT. Both the upstream Cursor copyright and the bdigital media port copyright are preserved in [`LICENSE`](./LICENSE).
