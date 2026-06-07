"""voicecorpus: a model/harness-agnostic personal-voice corpus builder.

Pull your own writing from any source (iMessage, Slack, Discord, email, your
articles, ...), run it through one shared cleaning + contamination + tiering
pipeline, and emit a corpus plus a portable "voice pack" that makes any LLM
write in your voice.
"""
from __future__ import annotations

__version__ = "0.1.0"

from .record import RawMessage, CorpusRecord
from .pipeline import build_corpus, clean, is_noise, is_ai_paste, word_count

__all__ = [
    "RawMessage", "CorpusRecord", "build_corpus",
    "clean", "is_noise", "is_ai_paste", "word_count", "__version__",
]
