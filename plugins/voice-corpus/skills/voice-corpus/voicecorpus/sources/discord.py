"""Discord data-package source.

Discord's "Request my Data" export contains ``messages/<channel>/messages.csv``
(columns: ID, Timestamp, Contents, Attachments). Everything in your data package
is authored by you, so ``is_self`` is always True here.
"""
from __future__ import annotations

import csv
import glob
import os
from typing import Iterator

from .base import Source
from ..record import RawMessage


class DiscordSource(Source):
    name = "discord"
    description = "Discord data-package export (messages/*/messages.csv)."

    def __init__(self, export: str):
        self.export = os.path.expanduser(export)

    @staticmethod
    def add_arguments(parser) -> None:
        parser.add_argument("--export", required=True,
                            help="path to the Discord data package (the folder "
                                 "containing messages/, or the messages/ dir)")

    @classmethod
    def from_args(cls, args) -> "DiscordSource":
        return cls(export=args.export)

    def records(self) -> Iterator[RawMessage]:
        patterns = [
            os.path.join(self.export, "messages", "*", "messages.csv"),
            os.path.join(self.export, "*", "messages.csv"),
            os.path.join(self.export, "messages.csv"),
        ]
        seen: set[str] = set()
        for pat in patterns:
            for path in sorted(glob.glob(pat)):
                if path in seen:
                    continue
                seen.add(path)
                with open(path, encoding="utf-8", newline="") as f:
                    for row in csv.DictReader(f):
                        text = (row.get("Contents") or "").strip()
                        if not text:
                            continue
                        yield RawMessage(
                            text=text, is_self=True, source=self.name,
                            channel="other", ts=(row.get("Timestamp") or None),
                        )
