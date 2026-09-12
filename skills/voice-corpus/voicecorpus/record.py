"""Normalized records that flow through the voice-corpus pipeline.

Every source adapter, no matter how exotic the export format, yields
``RawMessage`` objects. The shared pipeline (clean -> filter -> tier) only ever
sees ``RawMessage``, which is what makes a new source a one-file change.
"""
from __future__ import annotations

from dataclasses import dataclass, asdict
from typing import Optional


@dataclass
class RawMessage:
    """One unit of authored text from any source.

    Attributes:
        text:    The raw message/body text as written.
        is_self: True if *you* wrote it. Only your own writing trains your
                 voice; the pipeline drops everything else when ``--self-only``.
        source:  Adapter name that produced it ("imessage", "slack", ...).
        channel: "dm" | "group" | "doc" | "other". Kept as metadata so you can
                 later weight 1:1 chat vs. group vs. long-form differently.
        ts:      ISO-8601 timestamp if the source knows it, else None.
    """

    text: str
    is_self: bool
    source: str
    channel: str = "dm"
    ts: Optional[str] = None


@dataclass
class CorpusRecord:
    """A cleaned, kept record written to the corpus JSONL tiers."""

    text: str
    words: int
    source: str
    channel: str
    ts: Optional[str] = None

    def to_dict(self) -> dict:
        return asdict(self)
