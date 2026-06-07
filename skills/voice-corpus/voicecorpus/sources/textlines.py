"""Generic catch-all source: plain text, JSONL, or CSV.

The universal escape hatch for any export this platform does not have a
dedicated adapter for yet. Convert whatever you have into one of:

  * ``.txt``   one message per line
  * ``.jsonl`` one JSON object per line, with a ``text`` field (and optional
               ``is_self`` boolean)
  * ``.csv``   a ``text`` column (and optional ``is_self`` column)

Anything without an explicit is_self signal is treated as authored by you.
"""
from __future__ import annotations

import csv
import json
import os
from typing import Iterator

from .base import Source
from ..record import RawMessage


def _truthy(v) -> bool:
    if isinstance(v, bool):
        return v
    return str(v).strip().lower() in ("1", "true", "yes", "y", "self", "me")


class TextLinesSource(Source):
    name = "textlines"
    description = "Generic .txt / .jsonl / .csv (one message per line/row)."

    def __init__(self, path: str):
        self.path = os.path.expanduser(path)

    @staticmethod
    def add_arguments(parser) -> None:
        parser.add_argument("--path", required=True,
                            help="a .txt (one message per line), .jsonl, or .csv file")

    @classmethod
    def from_args(cls, args) -> "TextLinesSource":
        return cls(path=args.path)

    def records(self) -> Iterator[RawMessage]:
        ext = os.path.splitext(self.path)[1].lower()
        if ext == ".jsonl":
            yield from self._jsonl()
        elif ext == ".csv":
            yield from self._csv()
        else:
            yield from self._txt()

    def _txt(self) -> Iterator[RawMessage]:
        with open(self.path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line:
                    yield RawMessage(text=line, is_self=True,
                                     source=self.name, channel="other")

    def _jsonl(self) -> Iterator[RawMessage]:
        with open(self.path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except Exception:
                    continue
                text = (obj.get("text") or "").strip()
                if not text:
                    continue
                is_self = _truthy(obj["is_self"]) if "is_self" in obj else True
                yield RawMessage(text=text, is_self=is_self,
                                 source=self.name, channel="other",
                                 ts=obj.get("ts"))

    def _csv(self) -> Iterator[RawMessage]:
        with open(self.path, encoding="utf-8", newline="") as f:
            for row in csv.DictReader(f):
                text = (row.get("text") or "").strip()
                if not text:
                    continue
                is_self = _truthy(row["is_self"]) if "is_self" in row else True
                yield RawMessage(text=text, is_self=is_self,
                                 source=self.name, channel="other",
                                 ts=row.get("ts"))
