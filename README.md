# bdigital-public

Public code samples that accompany the bdigital media engineering blog.
Examples are extracted from real projects, generalized, and reduced to the
minimum shape needed to be useful without shipping proprietary context.

## What lives here

```
bdigital-public/
├── .claude-plugin/
│   └── marketplace.json    # Makes this repo a Claude Code plugin marketplace
├── plugins/                # Installable plugins (one-command install via /plugin)
│   └── session-handoff/    # Brief-generating skill for /clear-then-resume workflow
├── samples/                # Read-the-source versions (copy into your own repo)
│   ├── pr-review/          # Claude-skills-based automated PR review
│   └── session-handoff/    # Same skill as plugins/session-handoff, with tests
├── site/                   # Astro landing page (Cloudflare Workers)
└── .github/                # Open-source workflows, templates, ownership
```

`samples/` is for readers who want to study or copy code; `plugins/` is for
readers who want to install and use. Both coexist so you can pick whichever
matches your intent — and blog posts can link to either.

## Install a plugin (one command)

This repo is itself a Claude Code plugin marketplace. Inside Claude Code:

```
/plugin marketplace add neurot1cal/bdigital-public
/plugin install session-handoff@bdigital-public
```

That registers the marketplace and installs the `session-handoff` skill. See
[`plugins/session-handoff/README.md`](plugins/session-handoff/README.md) for what
the plugin does and how to customize it.

## Current plugins

### `plugins/session-handoff/`

A user-invocable Claude Code skill that generates a distilled brief for a fresh
session to resume from. Implements the "Clear with a brief" pattern from
Anthropic's session management guide.

Install: `/plugin install session-handoff@bdigital-public` (after adding the
marketplace as shown above). Source lives at
[`plugins/session-handoff/skills/session-handoff/SKILL.md`](plugins/session-handoff/skills/session-handoff/SKILL.md).

## Current samples

### `samples/pr-review/`

A drop-in GitHub Actions workflow and six Claude skill files that implement the
top six review categories from the blog series:

1. Correctness and logic bugs
2. Security-sensitive patterns
3. Test adequacy
4. Design fit and over-engineering
5. Readability (naming, comments, complexity)
6. Breaking-change and public-contract impact

The sample mirrors the architecture described in
[Part 1 of the series](https://tech.bdigitalmedia.io/blog/designing-ai-pr-review-claude-skills):
review skills are structured markdown files with named sections (detection
rules, exclusion categories, evidence requirement, scope filter, output
format). Each skill is a first-class versioned file, editable in normal code
review.

See [`samples/pr-review/README.md`](samples/pr-review/README.md) for setup,
required secrets, and customization notes.

## The landing page

`site/` is a minimal Astro project that renders a static landing page linking
to the samples and the blog series. It deploys to Cloudflare Workers via
Wrangler. The structure mirrors the production site (Space Grotesk + Inter
fonts, zinc palette, dark theme) so it can serve as a starter template for a
companion docs site.

```bash
cd site
npm install
npm run dev       # local dev server on :4321
npm run build     # static build
npm run deploy    # wrangler deploy
```

## Related reading

- [Part 1: Designing automated PR reviews with Claude Skills](https://tech.bdigitalmedia.io/blog/designing-ai-pr-review-claude-skills)
- [Part 2: Diagnosing false positives in AI code review](https://tech.bdigitalmedia.io/blog/diagnosing-ai-review-false-positives)
- [Part 3: Four fix patterns for AI code review (and the AI-auditing-AI problem)](https://tech.bdigitalmedia.io/blog/ai-code-review-fix-patterns)

## Contributing

Issues and pull requests welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for
guidance on code style, skill authoring, and the review process.

## Security

To report a security issue in this repository, see [SECURITY.md](SECURITY.md).
Please do not open a public issue for security-sensitive disclosures.

## License

[MIT](LICENSE). Use these samples in commercial or personal projects without
attribution requirements beyond the standard MIT copyright notice.
