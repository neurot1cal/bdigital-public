"""Shared, source-agnostic pipeline: clean -> filter -> tier.

Every source adapter feeds ``RawMessage`` objects in here. The cleaning, the
contamination guards, and the length tiering are applied uniformly, so a brand
new source automatically inherits the "don't train on forwarded AI slop" guard
without writing any of that logic itself.
"""
from __future__ import annotations

import re
from typing import Iterable

from .record import RawMessage, CorpusRecord

OBJ_REPLACEMENT = "￼"  # placeholder apps insert for inline attachments

URL_RE = re.compile(r"https?://\S+")
WS_RE = re.compile(r"\s+")
EMOJI_RE = re.compile(
    "[" "\U0001F300-\U0001FAFF" "\U00002600-\U000027BF" "\U0001F000-\U0001F0FF"
    "\U00002190-\U000021FF" "\U0000FE00-\U0000FE0F" "\U0001F1E6-\U0001F1FF" "]"
)

# High-precision markers that a passage was *pasted* (AI output, a forwarded
# article, a quoted block) rather than typed by the author. People do not
# hand-type markdown bold, em-dashes, code fences or "Here's a ..." preambles
# into a chat message. Training voice on these re-teaches the very tells we are
# trying to escape, so they are dropped for every source.
AI_PASTE_PATTERNS = [
    re.compile(r"—"),                                 # em-dash
    re.compile(r"\*\*"),                                   # markdown bold
    re.compile(r"```|#!/|</?\w+>|\bEOF\b"),                # code fence / shell / html
    re.compile(r"^(Here'?s|Here is|Sure[,!]|Certainly|Below is|The following)\b", re.I),
    re.compile(r"\b(TL;DR|Big Idea|Ruthless Edition|step-by-step breakdown)\b", re.I),
]
_STRUCT_RE = re.compile(r"(^|\n)\s*(#{1,6}\s|\d+\.\s|[-*]\s)")

REACTION_RE = re.compile(
    r'^(Loved|Liked|Disliked|Laughed at|Emphasized|Questioned)\s+[“"]'
)


def clean(text: str) -> str:
    return WS_RE.sub(" ", text.replace(OBJ_REPLACEMENT, " ")).strip()


def word_count(text: str) -> int:
    return len(text.split())


def is_noise(text: str) -> bool:
    """Logistics / non-prose that should never train voice."""
    if not text:
        return True
    stripped = URL_RE.sub("", text).strip()
    if not stripped:                              # url-only
        return True
    if not EMOJI_RE.sub("", stripped).strip():    # emoji-only
        return True
    if REACTION_RE.match(text):                   # reaction that slipped through
        return True
    return False


def is_ai_paste(text: str) -> bool:
    """True if the passage looks pasted/forwarded rather than authored."""
    if any(p.search(text) for p in AI_PASTE_PATTERNS):
        return True
    if len(_STRUCT_RE.findall(text)) >= 2:        # 2+ markdown list/header lines
        return True
    return False


# Tier names are part of the public contract (file names + docs).
TIERS = ("all", "substantive", "expressive", "voice")


def build_corpus(
    messages: Iterable[RawMessage],
    *,
    min_words: int = 15,
    voice_lo: int = 12,
    voice_hi: int = 60,
    self_only: bool = True,
    substantive_words: int = 8,
) -> dict:
    """Run the full pipeline. Returns kept records, tiers, and stats."""
    stats = {
        "scanned": 0, "not_self": 0, "empty": 0,
        "noise": 0, "ai_paste": 0, "kept": 0,
    }
    records: list[CorpusRecord] = []

    for m in messages:
        stats["scanned"] += 1
        if self_only and not m.is_self:
            stats["not_self"] += 1
            continue
        text = clean(m.text or "")
        if not text:
            stats["empty"] += 1
            continue
        if is_noise(text):
            stats["noise"] += 1
            continue
        if is_ai_paste(text):
            stats["ai_paste"] += 1
            continue
        records.append(CorpusRecord(
            text=text, words=word_count(text),
            source=m.source, channel=m.channel, ts=m.ts,
        ))

    records.sort(key=lambda r: r.ts or "")
    stats["kept"] = len(records)

    tiers = {
        "all": records,
        "substantive": [r for r in records if r.words >= substantive_words],
        "expressive": [r for r in records if r.words >= min_words],
        "voice": [r for r in records if voice_lo <= r.words <= voice_hi],
    }
    return {"records": records, "tiers": tiers, "stats": stats}
