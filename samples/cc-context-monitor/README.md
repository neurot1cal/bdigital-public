# cc-context-monitor sample

> **Looking for one-command install?** The same plugin ships as a Claude Code
> installable at [`plugins/cc-context-monitor/`](../../plugins/cc-context-monitor/).
> Run `/plugin marketplace add neurot1cal/bdigital-public` and then
> `/plugin install cc-context-monitor@bdigital-public`. This `samples/`
> directory is the read-the-source view for anyone who wants to study the
> plugin without installing.

A color-coded Claude Code statusline plus a user-invocable skill that
configures it. The statusline surfaces three numbers every turn:

- **Context window usage** (percent of the 1M-token window in the current session)
- **Session token usage** (rolling input + output + cache tokens for this session)
- **Weekly token usage** (rolling 7-day totals across all sessions on the machine)

The renderer delegates accounting to
[`ccusage`](https://github.com/ryoppippi/ccusage) and layers a three-band
color prefix on top (green 0 to 60 percent, yellow 61 to 80, red 81 plus).

## What is included

```
cc-context-monitor/
|-- README.md                         # this file
|-- tests/
|   `-- test-skill-structure.sh       # structural regression tests
`-- evals/
    |-- statusline-output.json        # eval cases for the wrapper (5 cases)
    `-- run-evals.sh                  # runs each case against statusline.sh
```

The live plugin source is under
[`plugins/cc-context-monitor/`](../../plugins/cc-context-monitor/). The
structural test script resolves the SKILL.md and statusline.sh paths
relative to its own location, so it tests the plugin copy directly.

## Run the tests

```bash
bash samples/cc-context-monitor/tests/test-skill-structure.sh
bash samples/cc-context-monitor/evals/run-evals.sh
```

Both scripts exit 0 on all-green and exit 1 on any failure. Together
they cover:

- Frontmatter shape (name, description, user-invocable, allowed-tools)
- Description is trigger-focused (no workflow verbs like "generates",
  "gathers", "updates", "captures", "produces", "creates")
- Required sections present (Overview, When to Use, Procedure, What NOT
  to Install Into)
- `statusline.sh` is executable, has a shebang, runs under
  `set -euo pipefail`
- `statusline.sh` references the three color thresholds (green, yellow,
  red)
- `plugin.json` parses and declares the required fields
- Security invariants: no `eval`, no `source` of untrusted input, no
  unquoted transcript path
- Five behavioral eval cases: 0% context, 55%, 75%, 92%, and
  ccusage-not-installed fallback

## Customizing

- **Change the color bands.** Edit the two default values at the top of
  `plugins/cc-context-monitor/statusline.sh` (`CC_CTX_GREEN_MAX`,
  `CC_CTX_YELLOW_MAX`) or override via environment variables.
- **Change the install target.** Edit Step 4 of
  `plugins/cc-context-monitor/skills/cc-context-monitor/SKILL.md` to
  point at a different statusline script path.
- **Swap the accounting engine.** The statusline wrapper is a thin
  shim over ccusage; swapping it for a different tool means rewriting
  the `$CCUSAGE_CMD statusline` call and the context-percent regex.

## License

MIT. Fork, adapt, ship.
