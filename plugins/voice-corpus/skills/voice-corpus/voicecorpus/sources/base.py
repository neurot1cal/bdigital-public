"""The Source contract: the one thing a new adapter must implement.

Implementing a source is deliberately tiny:

    class MySource(Source):
        name = "mything"
        description = "Pull my writing from MyThing exports."

        @staticmethod
        def add_arguments(parser):
            parser.add_argument("--path", required=True)

        @classmethod
        def from_args(cls, args):
            return cls(path=args.path)

        def records(self):
            for row in ...:
                yield RawMessage(text=row.body, is_self=row.mine, source=self.name)

That is the whole platform extension surface. The shared pipeline does cleaning,
contamination filtering, and tiering for you.
"""
from __future__ import annotations

import abc
from typing import Iterator

from ..record import RawMessage
from ..registry import register


class Source(abc.ABC):
    #: CLI subcommand name, e.g. "imessage". Globally unique.
    name: str = ""
    #: One-line help shown in `voicecorpus --help`.
    description: str = ""

    def __init_subclass__(cls, **kwargs):
        super().__init_subclass__(**kwargs)
        # Auto-register any concrete subclass that declares a name.
        if getattr(cls, "name", ""):
            register(cls)

    @staticmethod
    def add_arguments(parser) -> None:
        """Declare this source's CLI flags on its subparser. Optional."""

    @classmethod
    def from_args(cls, args) -> "Source":
        """Build an instance from parsed CLI args. Override if you take flags."""
        return cls()

    @abc.abstractmethod
    def records(self) -> Iterator[RawMessage]:
        """Yield every authored message/passage this source can find."""
        raise NotImplementedError
