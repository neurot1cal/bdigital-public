"""Source-adapter registry.

A ``Source`` subclass with a non-empty ``name`` registers itself here
automatically (via ``Source.__init_subclass__``). That is the entire extension
surface: drop a module in ``voicecorpus/sources/``, subclass ``Source``, and
import it in ``sources/__init__.py``. It becomes a CLI subcommand with no
pipeline edits.
"""
from __future__ import annotations

SOURCES: dict[str, type] = {}


def register(cls: type) -> type:
    """Record a Source subclass under its ``name``. Called by Source.__init_subclass__."""
    name = getattr(cls, "name", "")
    if not name:
        raise ValueError(f"{cls.__name__} must set a non-empty `name`")
    if name in SOURCES and SOURCES[name] is not cls:
        raise ValueError(f"duplicate source name: {name!r}")
    SOURCES[name] = cls
    return cls
