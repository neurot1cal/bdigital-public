# voice-corpus

Make AI write like *you* by feeding it your own writing instead of a style guide.

A style guide describes your voice; it cannot demonstrate it. `voice-corpus`
extracts thousands of things you actually wrote, strips the contamination, and
turns them into a portable **voice pack** that conditions any LLM on your real
voice. The engine is a standalone CLI with a pure-stdlib core, so it works with
Claude, Codex, Cursor, Copilot, Grok, a raw API call, or copy-paste into a
browser chat.

## Install

**Claude Code (plugin):**
```
/plugin marketplace add neurot1cal/bdigital-public
/plugin install voice-corpus@bdigital-public
```

**Cursor / Codex / Aider / Windsurf (openskills, AGENTS.md):**
```
npx openskills install neurot1cal/bdigital-public --skill voice-corpus
```

**Standalone (no agent runtime):** clone the repo and run the CLI directly from
`plugins/voice-corpus/skills/voice-corpus/`. The only optional dependency is
`pytypedstream`, needed solely for the iMessage source.

## What it does

```
source adapter ─► RawMessage ─► clean ─► drop noise ─► drop AI-paste ─► length tiers ─► corpus + voice-pack.md
```

One shared pipeline handles every source, so the contamination guard (drop
tapbacks, URL/emoji-only, and pasted/forwarded text that carries AI tells)
applies everywhere automatically.

```bash
# from plugins/voice-corpus/skills/voice-corpus/
python3 -m voicecorpus imessage --db ~/copy-of/chat.db --out ./corpus --pack --name "You"
python3 -m voicecorpus slack    --export ./slack-export --user-id U012ABC --out ./corpus --pack
python3 -m voicecorpus markdown --path ./my-blog-posts --out ./corpus --pack
```

Outputs in `--out`: `all.jsonl`, `substantive.jsonl`, `expressive.jsonl`,
`voice.jsonl`, and `voice-pack.md` (the portable artifact).

## Sources

iMessage/SMS, Slack, Discord, email (mbox / Gmail Takeout), your own
articles (markdown), and a generic `.txt`/`.jsonl`/`.csv` catch-all. Adding
another is a one-file adapter. See
[`references/ARCHITECTURE.md`](skills/voice-corpus/references/ARCHITECTURE.md).

## Using the voice pack anywhere

`voice-pack.md` is plain markdown (instructions + your real samples). Paste it
into a Claude/Codex/Cursor session, append it to `AGENTS.md` or
`.github/copilot-instructions.md`, prepend it as a system prompt, or drop it into
any browser chat. Then ask for your draft.

## Why this approach

Corpus exemplars beat prompt-level style guides for voice, and they keep a
frontier model's prose quality. When you need a fully offline/self-hosted model
instead, the same corpus trains a local fine-tune. The evidence, the method
ranking, and the A-vs-B decision are documented in
[`references/RESEARCH.md`](skills/voice-corpus/references/RESEARCH.md).

## Privacy

Your writing never leaves your machine. The engine runs locally and writes only
to `--out`; keep that directory out of any git repo. Don't paste raw private
messages into a hosted training API. The `voice-pack.md` is a curated sample you
control and can review before sharing.

## What's inside

```
plugins/voice-corpus/
├── .claude-plugin/plugin.json
├── LICENSE
├── README.md
└── skills/voice-corpus/
    ├── SKILL.md
    ├── voicecorpus/            # the engine (pure-stdlib core)
    │   ├── cli.py  pipeline.py  pack.py  record.py  registry.py
    │   └── sources/            # one file per source
    ├── references/
    │   ├── RESEARCH.md         # why exemplars; A vs B
    │   └── ARCHITECTURE.md     # how to add a source
    └── tests/test_pipeline.py
```

MIT licensed.
