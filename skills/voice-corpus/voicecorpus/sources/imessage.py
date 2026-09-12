"""iMessage / SMS source (macOS).

Reads a Messages ``chat.db`` (copy it out of ~/Library/Messages first; the
original is protected by Full Disk Access). Handles the modern-macOS quirk where
message text is stored in the binary ``attributedBody`` typedstream blob rather
than the ``text`` column.

Optional dependency: ``pip install pytypedstream`` (only needed for this source;
the rest of the platform is pure stdlib).
"""
from __future__ import annotations

import os
import sqlite3
from datetime import datetime, timezone
from typing import Iterator

from .base import Source
from ..record import RawMessage

APPLE_EPOCH = 978307200  # 2001-01-01 in unix seconds

# Pull only authored text bubbles: exclude tapbacks (associated_message_type!=0),
# system events (item_type!=0), app/payment bubbles (balloon_bundle_id), and
# unsent messages (date_retracted). is_from_me drives the is_self flag.
_QUERY = """
SELECT text, attributedBody, date, is_from_me, cache_roomnames
FROM message
WHERE COALESCE(associated_message_type, 0) = 0
  AND COALESCE(item_type, 0) = 0
  AND balloon_bundle_id IS NULL
  AND COALESCE(date_retracted, 0) = 0
"""


def _decode_attributed_body(blob: bytes | None) -> str | None:
    """First NSString payload in the typedstream is the message text."""
    if not blob:
        return None
    try:
        from typedstream.stream import TypedStreamReader
    except ImportError as e:  # pragma: no cover - environment dependent
        raise SystemExit(
            "The imessage source needs the typedstream decoder.\n"
            "  pip install pytypedstream"
        ) from e
    try:
        for event in TypedStreamReader.from_data(blob):
            if isinstance(event, (bytes, bytearray)):
                return event.decode("utf-8", "replace")
    except Exception:
        return None
    return None


def _to_iso(raw: int | None) -> str | None:
    if not raw:
        return None
    secs = raw / 1_000_000_000 if raw > 1_000_000_000_000 else raw
    try:
        return datetime.fromtimestamp(secs + APPLE_EPOCH, tz=timezone.utc).isoformat()
    except Exception:
        return None


class IMessageSource(Source):
    name = "imessage"
    description = "Apple Messages chat.db (iMessage + SMS) on macOS."

    def __init__(self, db: str):
        self.db = os.path.expanduser(db)

    @staticmethod
    def add_arguments(parser) -> None:
        parser.add_argument(
            "--db", required=True,
            help="path to a copy of chat.db (copy it out of ~/Library/Messages)",
        )

    @classmethod
    def from_args(cls, args) -> "IMessageSource":
        return cls(db=args.db)

    def records(self) -> Iterator[RawMessage]:
        con = sqlite3.connect(f"file:{self.db}?mode=ro", uri=True)
        try:
            for text_col, body, date, is_from_me, room in con.execute(_QUERY):
                text = text_col if (text_col and text_col.strip()) else _decode_attributed_body(body)
                if not text:
                    continue
                yield RawMessage(
                    text=text,
                    is_self=bool(is_from_me),
                    source=self.name,
                    channel="group" if room else "dm",
                    ts=_to_iso(date),
                )
        finally:
            con.close()
