"""Email source (mbox / Gmail Takeout).

Point it at an mbox file (Gmail Takeout exports your "Sent Mail" as one) and your
own address. Only messages you sent are marked ``is_self``. Quoted reply lines
and common signature blocks are stripped so the corpus is your prose, not the
thread you replied under.

Pure stdlib (``mailbox``, ``email``).
"""
from __future__ import annotations

import mailbox
import os
import re
from email.utils import parsedate_to_datetime
from typing import Iterator

from .base import Source
from ..record import RawMessage

_QUOTE = re.compile(r"^\s*>.*$", re.M)
_ON_WROTE = re.compile(r"^On .+ wrote:\s*$", re.M)       # reply attribution line
_SIG = re.compile(r"\n-- \n.*$", re.S)                    # standard sig delimiter


def _strip_reply(text: str) -> str:
    text = _SIG.sub("", text)
    # cut everything from the first "On ... wrote:" attribution onward
    m = _ON_WROTE.search(text)
    if m:
        text = text[: m.start()]
    text = _QUOTE.sub("", text)
    return text.strip()


def _body(msg) -> str:
    if msg.is_multipart():
        for part in msg.walk():
            if part.get_content_type() == "text/plain":
                try:
                    return part.get_payload(decode=True).decode(
                        part.get_content_charset() or "utf-8", "replace")
                except Exception:
                    continue
        return ""
    try:
        return msg.get_payload(decode=True).decode(
            msg.get_content_charset() or "utf-8", "replace")
    except Exception:
        return msg.get_payload() or ""


class EmailMboxSource(Source):
    name = "email"
    description = "Email mbox / Gmail Takeout (your sent messages)."

    def __init__(self, mbox_path: str, address: str | None):
        self.mbox_path = os.path.expanduser(mbox_path)
        self.address = (address or "").lower()

    @staticmethod
    def add_arguments(parser) -> None:
        parser.add_argument("--mbox", required=True, dest="mbox",
                            help="path to an .mbox file (e.g. Gmail Takeout Sent)")
        parser.add_argument("--address", default=None,
                            help="your email address; only mail you sent is "
                                 "marked is_self when set")

    @classmethod
    def from_args(cls, args) -> "EmailMboxSource":
        return cls(mbox_path=args.mbox, address=args.address)

    def records(self) -> Iterator[RawMessage]:
        box = mailbox.mbox(self.mbox_path)
        for msg in box:
            frm = (msg.get("From") or "").lower()
            is_self = (self.address in frm) if self.address else True
            text = _strip_reply(_body(msg))
            if not text:
                continue
            ts = None
            if msg.get("Date"):
                try:
                    ts = parsedate_to_datetime(msg["Date"]).isoformat()
                except Exception:
                    ts = None
            yield RawMessage(text=text, is_self=is_self, source=self.name,
                             channel="other", ts=ts)
