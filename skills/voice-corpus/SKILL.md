---
name: voice-corpus
description: >-
  Build a personal-voice corpus from your own writing and turn it into a portable
  "voice pack" that makes any LLM write in your real voice. Pulls from iMessage,
  Slack, Discord, email/mbox, your own articles, or any text export, runs one
  shared cleaning + anti-AI-slop + length-tiering pipeline, and emits both a JSONL
  corpus and a paste-ready prompt artifact. Use when the user says "clone my
  writing voice", "make the AI sound like me", "extract my voice from my
  texts/messages/Slack", "train on my own writing", "build a voice corpus", "my
  AI writing doesn't sound human", or wants to feed their authentic style to
  Claude, Codex, Cursor, Copilot, or a raw API call. Model- and harness-agnostic;
  the engine is a standalone CLI with a pure-stdlib core.
user-invocable: true
allowed-tools: Bash, Read, Write
---

# voice-corpus

Make AI write like *you* by feeding it your own writing instead of a style guide.

A style guide *describes* your voice. It cannot *demonstrate* it. This skill
extracts thousands of things you actually wrote, strips the contamination, and
turns them into exemplars an LLM conditions on. The output is harness-agnostic:
a JSONL corpus plus a `voice-pack.md` you can drop into any model or agent.

See `references/RESEARCH.md` for the evidence behind this approach (why corpus
exemplars beat prompting, and when a local fine-tune is the better call).

## When to use this

The user wants their AI-assisted writing to read as authentically them, and
prompt-level style rules are not getting there. They have a body of their own
real writing somewhere (messages, chats, email, past articles).

## The pipeline (same for every source)

```
source adapter  ->  RawMessage  ->  clean  ->  drop noise  ->  drop AI-paste  ->  length tiers  ->  corpus + voice pack
```

The contamination guard is the part people miss. Most personal corpora are
poisoned two ways, and the pipeline removes both automatically for every source:

- **Reactions / system noise** (tapbacks, "Loved ...", URL-only, emoji-only).
- **Pasted / forwarded text**: anyone who texts AI output or forwards an
  article injects the exact tells you are trying to escape (em-dashes, markdown
  bold, "Here's a step-by-step ...", numbered headers). Length is an inverted
  signal: a hand-typed message is rarely over ~60 words, so the curated `voice`
  tier caps there.

## Steps

1. **Pick a source** and get the export onto disk (see Sources below).
2. **Run the extractor.** It writes four corpus tiers and, with `--pack`, the
   portable artifact:

   ```bash
   python3 -m voicecorpus <source> [source-flags] --out ./corpus --pack --name "Your Name"
   ```

   Tiers written to `--out`: `all.jsonl`, `substantive.jsonl` (>=8 words),
   `expressive.jsonl` (>=15 words), `voice.jsonl` (curated 12-60 word exemplars).
   `voice-pack.md` is built from the `voice` tier.
3. **Read the report.** It prints how much was dropped and why, the tier counts,
   and sample exemplars so you can eyeball that the voice is real.
4. **Use the voice pack** in whatever harness the user works in (see Using it).

Run from the skill directory (so `python3 -m voicecorpus` resolves), or add the
skill directory to `PYTHONPATH`.

## Sources

| Source | Flag | Notes |
|--------|------|-------|
| iMessage / SMS | `imessage --db <chat.db>` | macOS. Copy `~/Library/Messages/chat.db` to an unprotected folder first (Full Disk Access protects the original). Needs `pip install pytypedstream`. |
| Slack | `slack --export <dir> [--user-id U…]` | Unzipped workspace export or `slackdump` output. Pass your user ID so only your messages count. |
| Discord | `discord --export <dir>` | "Request my Data" package. Everything in it is yours. |
| Email | `email --mbox <file.mbox> [--address you@x.com]` | Gmail Takeout "Sent" mbox. Strips quoted replies + signatures. |
| Your articles | `markdown --path <dir>` | Folder of your own `.md`/`.txt`. Split per paragraph. Best with hand-written prose. |
| Anything else | `textlines --path <file>` | `.txt` (one per line), `.jsonl` (`text`, optional `is_self`), or `.csv`. |

Adding a new source is one file. See `references/ARCHITECTURE.md`.

### Privacy

This is your private writing. The engine runs entirely locally and writes only
to `--out`. Keep that directory out of any git repo. Never paste raw private
messages into a training API. The `voice-pack.md` you share is a curated sample
you control; review it before handing it to a hosted model if that matters.

## Using the voice pack (any harness)

`voice-pack.md` is plain markdown: an instruction block plus your real samples.

- **Claude / Codex / Cursor session**: paste it at the top of the task, or drop
  it into the project's instructions file.
- **Cursor / Codex / Aider / Windsurf (AGENTS.md)**: append it to `AGENTS.md`.
- **GitHub Copilot**: append it to `.github/copilot-instructions.md`.
- **Raw API / any model**: prepend it as a system prompt.
- **ChatGPT / Grok / browser**: paste it before your writing request.

Then ask for the draft. The model writes new content in your voice instead of
the averaged-internet default.

## Honest limits

This produces a draft that reads as you and that you still edit; it is not an
indistinguishable clone. It shifts voice for human readers, which is the winnable
goal. It does not defeat every AI-text detector, which is a separate and
unwinnable arms race. For full detail and the fine-tune alternative, read
`references/RESEARCH.md`.
