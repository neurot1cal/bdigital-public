"""Build the portable "voice pack": the harness-agnostic artifact.

The voice pack is plain markdown: a short instruction block plus a diverse
sample of the author's real messages. It is the universal interface; paste it
into any system prompt, ``AGENTS.md``, ``.github/copilot-instructions.md``, a
Claude/Codex/Cursor session, or a raw API call. No runtime, no model lock-in.
"""
from __future__ import annotations

from typing import Sequence

from .record import CorpusRecord


def sample_diverse(records: Sequence[CorpusRecord], n: int) -> list[CorpusRecord]:
    """Even-spaced (deterministic) sample across the corpus for variety."""
    if len(records) <= n:
        return list(records)
    stride = len(records) / n
    return [records[int(i * stride)] for i in range(n)]


def observed_habits(records: Sequence[CorpusRecord]) -> list[str]:
    """A few cheap, accurate style signals to state explicitly in the pack."""
    if not records:
        return []
    n = len(records)
    med = sorted(r.words for r in records)[n // 2]
    em_dash = sum("—" in r.text for r in records) / n
    lower_open = sum(r.text[:1].islower() for r in records) / n
    habits = [f"Typical message length is around {med} words; vary it, never uniform."]
    if em_dash < 0.02:
        habits.append("Does not use em-dashes. Use commas, periods, or 'and'.")
    if lower_open > 0.3:
        habits.append("Often starts sentences lowercase and casual; not buttoned-up.")
    return habits


def build_pack(records: Sequence[CorpusRecord], *, n: int = 40,
               name: str = "the author") -> str:
    samples = sample_diverse(records, n)
    habits = observed_habits(records)

    lines = [
        f"# Voice pack: write as {name}",
        "",
        f"You are writing as {name}, a specific real human. Absorb the voice in "
        "the samples below: word choice, rhythm, directness, humor, and "
        "attitude. Match how they sound, not what any one sample is about. The "
        "goal is prose a reader who knows them would believe they wrote.",
        "",
    ]
    if habits:
        lines.append("## Observed habits")
        lines += [f"- {h}" for h in habits]
        lines.append("")
    lines.append(f"## Real samples authored by {name}")
    for r in samples:
        text = r.text.replace("\n", " ").strip()
        lines.append(f"- {text}")
    lines.append("")
    lines.append(
        "When you draft, do not copy these lines. Write new content in this "
        "voice. Keep their cadence and bluntness; drop any corporate or "
        "AI-assistant register."
    )
    return "\n".join(lines) + "\n"
