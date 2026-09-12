"""Importing this package registers every bundled source adapter.

To add a source: create ``yourname.py`` in this directory with a ``Source``
subclass, then add one import line below. That is the entire wiring step.
"""
from . import imessage          # noqa: F401
from . import slack             # noqa: F401
from . import discord           # noqa: F401
from . import email_mbox        # noqa: F401
from . import markdown_docs     # noqa: F401
from . import textlines         # noqa: F401
