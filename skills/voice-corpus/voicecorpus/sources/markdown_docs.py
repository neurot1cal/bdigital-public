"""Long-form source: a folder of your own articles / posts / notes.

Walks a directory for ``.md``/``.mdx``/``.txt`` files, strips frontmatter, code
blocks, and markdown syntax, then yields each paragraph as its own record so the
length-tiering still works (a whole article would never land in the short
"voice" tier). Everything here is treated as authored by you (``is_self=True``).

Best fed hand-written prose. If you point it at AI-drafted posts, the shared
pipeline's contamination filter will drop the paragraphs that carry AI tells.
"""
from __future__ import annotations

import os
import re
from typing import Iterator

from .base import Source
from ..record import RawMessage

_FRONTMATTER = re.compile(r"^﻿?---\n.*?\n---\n", re.S)
_CODEBLOCK = re.compile(r"```.*?```", re.S)
_INLINE_CODE = re.compile(r"`[^`]*`")
_IMAGE = re.compile(r"!\[[^\]]*\]\([^)]*\)")
_LINK = re.compile(r"\[([^\]]+)\]\([^)]*\)")
_HEADING = re.compile(r"^#{1,6}\s+", re.M)
_BLOCKQUOTE = re.compile(r"^>\s?", re.M)
_EMPHASIS = re.compile(r"(\*\*|__|\*|_)")
_HTML = re.compile(r"<[^>]+>")


def _strip_markdown(text: str) -> str:
    text = _FRONTMATTER.sub("", text)
    text = _CODEBLOCK.sub("", text)
    text = _IMAGE.sub("", text)
    text = _LINK.sub(r"\1", text)
    text = _INLINE_CODE.sub("", text)
    text = _HEADING.sub("", text)
    text = _BLOCKQUOTE.sub("", text)
    text = _HTML.sub("", text)
    text = _EMPHASIS.sub("", text)
    return text


class MarkdownDocsSource(Source):
    name = "markdown"
    description = "A folder of your own articles/notes (.md/.mdx/.txt), by paragraph."

    EXTS = (".md", ".mdx", ".txt", ".markdown")

    def __init__(self, path: str):
        self.path = os.path.expanduser(path)

    @staticmethod
    def add_arguments(parser) -> None:
        parser.add_argument("--path", required=True,
                            help="directory of your own markdown/text documents")

    @classmethod
    def from_args(cls, args) -> "MarkdownDocsSource":
        return cls(path=args.path)

    def records(self) -> Iterator[RawMessage]:
        for root, _dirs, files in os.walk(self.path):
            for fn in sorted(files):
                if not fn.lower().endswith(self.EXTS):
                    continue
                fpath = os.path.join(root, fn)
                try:
                    with open(fpath, encoding="utf-8") as fh:
                        raw = fh.read()
                except Exception:
                    continue
                body = _strip_markdown(raw)
                for para in re.split(r"\n\s*\n", body):
                    para = " ".join(para.split())
                    if para:
                        yield RawMessage(text=para, is_self=True,
                                         source=self.name, channel="doc")
