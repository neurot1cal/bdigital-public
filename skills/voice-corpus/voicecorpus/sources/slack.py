"""Slack workspace export source.

A Slack export is a directory of per-channel folders, each holding
``YYYY-MM-DD.json`` files (arrays of message objects). Pass your own Slack user
ID so only your messages are marked ``is_self``.

Get it from: workspace export (Settings -> Import/Export Data) or `slackdump`.
"""
from __future__ import annotations

import glob
import html
import json
import os
import re
from datetime import datetime, timezone
from typing import Iterator

from .base import Source
from ..record import RawMessage

_MENTION = re.compile(r"<@[UW][A-Z0-9]+>")
_CHANNEL = re.compile(r"<#C[A-Z0-9]+\|([^>]+)>")
_LINK = re.compile(r"<(https?://[^|>]+)\|([^>]+)>")
_BARE = re.compile(r"<(https?://[^>]+)>")


def _clean_mrkdwn(text: str) -> str:
    text = _CHANNEL.sub(r"\1", text)
    text = _LINK.sub(r"\2", text)
    text = _BARE.sub(r"\1", text)
    text = _MENTION.sub("", text)
    return html.unescape(text)


class SlackSource(Source):
    name = "slack"
    description = "Slack workspace export (per-channel JSON day files)."

    def __init__(self, export: str, user_id: str | None):
        self.export = os.path.expanduser(export)
        self.user_id = user_id

    @staticmethod
    def add_arguments(parser) -> None:
        parser.add_argument("--export", required=True,
                            help="path to the unzipped Slack export directory")
        parser.add_argument("--user-id", default=None,
                            help="your Slack user ID (e.g. U012ABC); only your "
                                 "messages are marked is_self when set")

    @classmethod
    def from_args(cls, args) -> "SlackSource":
        return cls(export=args.export, user_id=args.user_id)

    def records(self) -> Iterator[RawMessage]:
        for path in sorted(glob.glob(os.path.join(self.export, "**", "*.json"),
                                     recursive=True)):
            # channel metadata files live at the export root, skip them
            base = os.path.basename(path)
            if not re.match(r"\d{4}-\d{2}-\d{2}\.json$", base):
                continue
            folder = os.path.basename(os.path.dirname(path))
            channel = "dm" if folder.startswith(("D", "mpdm-")) else "group"
            try:
                with open(path, encoding="utf-8") as fh:
                    msgs = json.load(fh)
            except Exception:
                continue
            for m in msgs:
                if m.get("type") != "message" or m.get("subtype"):
                    continue
                text = m.get("text") or ""
                if not text:
                    continue
                uid = m.get("user") or (m.get("user_profile") or {}).get("name")
                is_self = (uid == self.user_id) if self.user_id else True
                ts = None
                if m.get("ts"):
                    try:
                        ts = datetime.fromtimestamp(
                            float(m["ts"]), tz=timezone.utc).isoformat()
                    except Exception:
                        ts = None
                yield RawMessage(text=_clean_mrkdwn(text), is_self=is_self,
                                 source=self.name, channel=channel, ts=ts)
