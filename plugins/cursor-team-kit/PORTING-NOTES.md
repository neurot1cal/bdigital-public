# Porting notes: cursor-team-kit → Claude Code

Upstream commit ported: `3347cbab5b54136f6fba0994c3a01a56f7fb7fca`
Upstream path: [`cursor-team-kit/`](https://github.com/cursor/plugins/tree/3347cbab5b54136f6fba0994c3a01a56f7fb7fca/cursor-team-kit)

## Global adaptations

| Cursor convention | Claude Code adaptation | Why |
|---|---|---|
| `disable-model-invocation: true` | `user-invocable: true` | Cursor's flag prevents the model from auto-triggering the skill; Claude Code does not have an exact equivalent, but `user-invocable: true` (per Anthropic's plugin schema) exposes the skill as `/skill-name` while leaving auto-trigger gated by the description's specificity. Bob's existing `cc-context-monitor` plugin uses the same pattern. |
| `model: fast` on agents | (removed) | Claude Code subagents inherit the parent's model context; explicit `model` selection in frontmatter is not part of the schema for plugin-bundled subagents in the current release. |
| `is_background: true` on agents | (removed) | Claude Code subagents are invoked synchronously via the `Agent` tool with optional `run_in_background: true`. The agent definition itself doesn't carry a background flag. |
| `subagent_type: "shell"` (in agent body prose) | `Bash` tool calls | Cursor's "shell" subagent is its built-in command runner. In Claude Code, parents call `Bash` directly. |
| `subagent_type: "explore"` (in agent body prose) | `Explore` subagent | Claude Code has a built-in `Explore` subagent for read-only codebase search; the role transfers cleanly. |
| `subagent_type: "<plugin-subagent>"` (e.g. `thermo-nuclear-code-quality-review`) | Same name via `Agent(subagent_type=...)` | Claude Code's `Agent` tool accepts custom subagent_type values; plugin-bundled subagents register under their `name` field. |
| `rules/*.mdc` with `alwaysApply: true` | `CLAUDE.md` advisory section | Claude Code does not auto-inject project-rule fragments the way Cursor does. The two rules from the upstream `rules/` directory are listed in `CLAUDE.md` as advisory; individual skills can reference them in their body when relevant. |

## Per-file changes

### `agents/ci-watcher.md`
- Removed `model: fast` and `is_background: true` from frontmatter.
- Body workflow uses `gh` CLI calls unchanged — these are tool-agnostic.

### `agents/thermo-nuclear-code-quality-review.md`
- Removed `model: fast`.
- "Parent orchestration" section: rewrote the cursor-specific subagent recipe (`subagent_type: "shell"` + `subagent_type: "explore"` → `subagent_type: "thermo-nuclear-code-quality-review"`) to use Claude Code's `Bash` and `Explore` directly, with the final review still going through the plugin's `thermo-nuclear-code-quality-review` subagent.

### `skills/pr-review-canvas/SKILL.md`
- Frontmatter `disable-model-invocation: true` → `user-invocable: true`.
- Body unchanged — references to `gh api`, `jq`, `python3`, and the renderer.js/styles.css/template.html assets all work identically in Claude Code.

### `skills/thermo-nuclear-code-quality-review/SKILL.md`
- Frontmatter `disable-model-invocation: true` → `user-invocable: true`.
- Body unchanged.

### All other skills
- No frontmatter changes required; cursor and Claude Code share the YAML `name` + `description` shape.
- Body content preserved verbatim except where a cursor-specific tool or command would not exist in a Claude Code environment (none of the remaining 14 skills had such references).

### `rules/no-inline-imports.mdc` and `rules/typescript-exhaustive-switch.mdc`
- Consolidated into `CLAUDE.md` as an "Advisory rules" section. The original `alwaysApply: true` semantics do not transfer; instead the rules apply when this plugin's `CLAUDE.md` is read by the parent.

### `pr-review-canvas/renderer.js`, `styles.css`, `template.html`
- Preserved verbatim. These are static assets that the `pr-review-canvas` skill reads at runtime.

## What was NOT ported

- `assets/avatar.png` — Cursor branding; not appropriate to redistribute under bdigital's plugin namespace.
- `.cursor-plugin/plugin.json` — replaced with `.claude-plugin/plugin.json` (different schema).
