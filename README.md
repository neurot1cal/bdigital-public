# bdigital-public

Public code samples that accompany the bdigital media engineering blog.
Examples are extracted from real projects, generalized, and reduced to the
minimum shape needed to be useful without shipping proprietary context.

## What lives here

```
bdigital-public/
├── samples/
│   └── pr-review/          # Claude-skills-based automated PR review
│                           # Matches the 3-part blog series on tech.bdigitalmedia.io
├── site/                   # Astro landing page (Cloudflare Workers)
└── .github/                # Open-source workflows, templates, ownership
```

Each directory under `samples/` is self-contained. Copy it into your own repo
or use it as a reference while reading the associated blog post.

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
