# Architecture: adding a source

The platform is a shared pipeline plus pluggable source adapters. Adding a
source (WhatsApp, Telegram, Apple Notes, Bluesky, a CRM export, anything) is one
file. You never touch the cleaning, contamination, or tiering logic.

## The flow

```
your adapter ──┐
               ├─► RawMessage ─► clean ─► drop noise ─► drop AI-paste ─► length tiers ─► corpus + voice pack
other adapter ─┘                         (shared pipeline; you write none of this)
```

- `voicecorpus/record.py`: `RawMessage` (what every adapter yields) and
  `CorpusRecord` (what the pipeline emits).
- `voicecorpus/pipeline.py`: `build_corpus()`: cleaning, the noise + AI-paste
  guards, length tiering. Source-agnostic.
- `voicecorpus/sources/base.py`: the `Source` contract.
- `voicecorpus/registry.py`: adapters self-register; the CLI turns each into a
  subcommand automatically.

## The contract

A source yields `RawMessage(text, is_self, source, channel="dm", ts=None)`:

- `text`: the body as written. Do light source-specific cleanup here (strip
  mention syntax, link markup, quoted replies). The pipeline handles whitespace,
  attachment placeholders, noise, and AI-paste contamination.
- `is_self`: `True` only if the author wrote it. The pipeline drops everyone
  else when `--self-only` (the default). If a source only ever contains your own
  writing (a data-request export, your articles), set it `True` unconditionally.
- `channel`: `"dm" | "group" | "doc" | "other"`. Metadata only; keep it honest.
- `ts`: ISO-8601 if you can, else `None`. Used only for stable ordering.

Do **not** filter for quality, length, reactions, or AI tells in the adapter.
That is the pipeline's job, and centralizing it is what keeps the contamination
guard consistent across every source.

## Template

```python
# voicecorpus/sources/mything.py
from __future__ import annotations
from typing import Iterator
from .base import Source
from ..record import RawMessage


class MyThingSource(Source):
    name = "mything"                       # CLI subcommand; globally unique
    description = "Pull my writing from MyThing exports."

    def __init__(self, path: str):
        self.path = path

    @staticmethod
    def add_arguments(parser) -> None:     # optional source-specific flags
        parser.add_argument("--path", required=True, help="path to the export")

    @classmethod
    def from_args(cls, args) -> "MyThingSource":
        return cls(path=args.path)

    def records(self) -> Iterator[RawMessage]:
        for row in _read(self.path):
            yield RawMessage(
                text=row.body,
                is_self=row.author_is_me,
                source=self.name,
                channel="dm",
                ts=row.iso_timestamp,
            )
```

Then register it by adding one import to `voicecorpus/sources/__init__.py`:

```python
from . import mything   # noqa: F401
```

Subclassing `Source` with a non-empty `name` auto-registers it, so the import is
the only wiring. `python3 -m voicecorpus mything --path ... --out ./corpus`
works immediately, with all tiers, the report, and `--pack`.

## Test it

Add a fixture test to `tests/test_pipeline.py` that writes a tiny synthetic
export and asserts the records come out right (see `TestAdapters` for examples).
Keep it pure-stdlib `unittest` so it runs with no dependencies:

```bash
python3 -m unittest discover -s tests -v
```

## Optional dependencies

Keep the core pure-stdlib. If a source needs a library (the iMessage adapter
needs `pytypedstream` to decode `attributedBody`), import it lazily *inside* the
method that needs it and raise a clear install hint, so installing the platform
never forces a dependency a given user does not use.
