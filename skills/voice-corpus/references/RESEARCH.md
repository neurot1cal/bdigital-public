# Why corpus exemplars, not a style guide

This skill exists because of a specific, repeatable failure: you can spend
months tuning prompts and style guides and your AI-assisted writing still does
not sound human. This document explains what the research says actually closes
that gap, why this tool picks **exemplar conditioning (Path A)** as the default,
and when you should reach for a **local fine-tune (Path B)** instead.

The findings below come from two structured literature passes (50+ sources,
claims adversarially verified). Citations are arXiv / ACL / EMNLP / NeurIPS /
CHI / AAAI primary papers, 2020-2026. Treat detector-evasion claims as having a
6-12 month shelf life; this is an active arms race.

## The core disagreement, settled

Two camps argue about why AI writing does not sound human:

- *"Teach it your voice"*: feed it enough of your own writing and it learns how
  you sound.
- *"The substrate fights you"*: the base model prefers certain patterns and its
  tells leak through no matter what you do.

Both are half right, because "sounds like AI" is really **two stacked layers**:

1. **Voice layer.** Word choice, rhythm, attitude, what you would never say.
   This is what a *human reader* reacts to. It is movable.
2. **Substrate layer.** The perplexity/burstiness fingerprint of the decoder.
   This is what *detectors* read. Against style/representation-based detectors it
   is effectively irreducible.

The practical conclusion: the human-reader complaint lives entirely in the
movable layer. Chasing detector-evasion is the unwinnable game; making it read
as you to a person is the winnable one. This tool targets the winnable one.

## The methods, ranked

### Prompting / static style guide: describes voice, cannot demonstrate it
A style guide describes voice; it cannot demonstrate it across thousands of
tokens. On informal/personal genres (blogs, forums, chat) adding more in-context
examples barely moves stylistic-alignment metrics, and LLM imitation of everyday
authors stays under ~55% human-rated, collapsing hardest on exactly the casual
register most personal writing lives in.
*(Wang et al., EMNLP 2025 Findings, arXiv:2509.14543; Patel et al., EMNLP 2023
Findings, arXiv:2212.08986.)*

### Path A: exemplar conditioning (this tool's default)
Retrieve the author's own real passages and condition a strong model on them.
The low-resource style-transfer literature found in-context conditioning on an
author's own samples to be the **strongest available technique, beating
fine-tuning**, and it worked from a tiny corpus (~16 messages, ~500 words total)
for ordinary non-famous authors.
*(Patel, Andrews & Callison-Burch, EMNLP 2023 Findings, arXiv:2212.08986.)*

Why it is the default here:
- It keeps a frontier model doing the actual writing, so prose quality stays high.
- Zero training, zero GPU, near-zero cost.
- It is model- and harness-agnostic: the output is a prompt artifact.
- The hybrid of exemplars plus a profile is the documented best non-training
  stack. *(OPPU, Tan et al., EMNLP 2024 Main, arXiv:2402.04401.)*

### Path B: fine-tune on your corpus (the heavier, sometimes-right call)
Fine-tuning on an author's full corpus shifts *perceived* voice further than
prompting can. In one study, fine-tuning on authors' complete works flipped
expert preference from 82.7% human to 62% AI, a reversal prompting never
approaches.
*(Chakrabarty & Dhillon, CHI 2026, arXiv:2601.18353.)*

Preference tuning (DPO/ORPO) on pairs of *(raw AI draft, your hand-edited
final)* is especially efficient and teaches the model exactly what you always
fix; ~7k pairs measurably shifted output and defeated perplexity-based detectors.
*(Pedrotti et al., ACL 2025 Findings, arXiv:2505.24523.)*

Its honest costs:
- The trainable model is an open-weight 7-8B, a **weaker writer** than a frontier
  model. Rewriting a frontier draft with it can lower prose quality even as it
  raises voice fidelity. Use it as a critic/line-editor, not a full rewriter.
- It is a real training loop (data prep, a GPU or Apple-Silicon MLX run, iteration).
- It masks the substrate against perplexity detectors but **not** against
  style/representation detectors, which re-separate as sample size grows.
  *(arXiv:2505.14608.)*

### Inference-time steering: the cheap weights-free middle
A style/control vector extracted from the author's text steers generation with
no training. Cheapest model-level lever; stacks with exemplars.
*(StyleVector, ACL 2025, arXiv:2503.05213; TinyStyler, EMNLP 2024 Findings,
arXiv:2406.15586, an 800M re-styler that can beat GPT-4 on style transfer.)*

## When to choose A vs B

| Situation | Use |
|-----------|-----|
| You write with a frontier model (Claude, GPT, Gemini) | **Path A.** It wins on voice *and* keeps that model's prose quality. |
| You need fully offline / self-hosted / no cloud | **Path B.** A is only as good as the model you can run; if that is a small local model, training it on your corpus buys more than exemplars do. |
| You run a small/open local model by choice or constraint | **Path B**, optionally + steering. Exemplar conditioning helps a weak model less than fine-tuning its weights does. |
| You have thousands of *(draft, your-edit)* pairs | **Path B via DPO/ORPO** on those pairs, as a critic pass over A's output. |
| You just want it to sound like you today, cheaply | **Path A.** Minutes, not a weekend. |

**This tool builds the corpus both paths need.** The `voice` tier is Path A's
exemplar pool and `voice-pack.md` is the ready artifact. The full `all` /
`substantive` tiers are Path B's training data. Start with A; if a frontier model
is off the table for you, the same corpus feeds the fine-tune.

## What this does not do

It produces a draft that reads as you and that you still edit. It is not an
indistinguishable clone (the strongest non-fine-tuned studies report ~0.24
human-agreement; expect a strong assist, not perfection). It does not make text
"undetectable", which is a moving arms race and an explicit non-goal here.
The cross-register jump (e.g. chat exemplars to long-form articles) weakens the
signal further; the literature measures attribution and short-form transfer, not
long-form generation, so validate at the length you actually publish.

## Sources

- arXiv:2212.08986 · Patel, Andrews & Callison-Burch, EMNLP 2023 Findings (exemplar conditioning beats fine-tuning; ~16-message corpus)
- arXiv:2509.14543 · Wang et al., EMNLP 2025 Findings (more examples barely help on blog/forum voice)
- arXiv:2402.04401 · OPPU, Tan et al., EMNLP 2024 Main (hybrid PEFT + retrieval is best)
- arXiv:2601.18353 · Chakrabarty & Dhillon, CHI 2026 (full-corpus fine-tune flips preference to 62% AI)
- arXiv:2505.24523 · Pedrotti et al., ACL 2025 Findings (DPO style shift, ~7k pairs)
- arXiv:2505.14608 · style detectors re-separate after DPO (the substrate caveat)
- arXiv:2503.05213 · StyleVector (training-free activation steering)
- arXiv:2406.15586 · TinyStyler (800M local re-styler)
- Nature s41586-024-07566-y · Shumailov et al. (human data preserves distribution tails AI text loses)
