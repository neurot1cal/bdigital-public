"""Command-line entry point: ``python -m voicecorpus <source> [flags]``.

Each registered source becomes a subcommand. Shared flags (output dir, tier
thresholds, voice-pack emission) are added to every subcommand.
"""
from __future__ import annotations

import argparse
import json
import os
import sys

from . import sources  # noqa: F401  (importing registers all adapters)
from .registry import SOURCES
from .pack import build_pack
from .pipeline import build_corpus


def _add_shared(parser: argparse.ArgumentParser) -> None:
    g = parser.add_argument_group("output")
    g.add_argument("--out", required=True, help="output directory for corpus tiers")
    g.add_argument("--min-words", type=int, default=15,
                   help="word floor for the 'expressive' tier (default 15)")
    g.add_argument("--voice-lo", type=int, default=12,
                   help="min words for the curated 'voice' tier (default 12)")
    g.add_argument("--voice-hi", type=int, default=60,
                   help="max words for the curated 'voice' tier (default 60); "
                        "messages longer than this are usually pasted, not typed")
    g.add_argument("--all-messages", action="store_true",
                   help="keep messages from everyone, not just you")
    g.add_argument("--pack", action="store_true",
                   help="also emit voice-pack.md (the portable, harness-agnostic artifact)")
    g.add_argument("--pack-n", type=int, default=40,
                   help="number of exemplars to put in the voice pack (default 40)")
    g.add_argument("--name", default="the author",
                   help="how to refer to you in the voice pack")
    g.add_argument("--samples", type=int, default=10,
                   help="how many sample messages to print in the report")


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="voicecorpus",
        description="Build a clean personal-voice corpus from any source.",
    )
    sub = p.add_subparsers(dest="source", required=True, metavar="SOURCE")
    for name, cls in sorted(SOURCES.items()):
        sp = sub.add_parser(name, help=cls.description, description=cls.description)
        cls.add_arguments(sp)
        _add_shared(sp)
    return p


def _write_tiers(out: str, result: dict) -> dict:
    os.makedirs(out, exist_ok=True)
    paths = {}
    for tier, recs in result["tiers"].items():
        path = os.path.join(out, f"{tier}.jsonl")
        with open(path, "w", encoding="utf-8") as f:
            for r in recs:
                f.write(json.dumps(r.to_dict(), ensure_ascii=False) + "\n")
        paths[tier] = path
    return paths


def _report(args, result: dict, paths: dict, pack_path: str | None) -> None:
    s = result["stats"]
    tiers = result["tiers"]

    def w(recs):
        return sum(r.words for r in recs)

    print("=" * 60)
    print(f"VOICE CORPUS ({args.source})")
    print("=" * 60)
    print(f"scanned:                 {s['scanned']:>8,}")
    if not args.all_messages:
        print(f"dropped (not you):       {s['not_self']:>8,}")
    print(f"dropped (empty):         {s['empty']:>8,}")
    print(f"dropped (noise):         {s['noise']:>8,}")
    print(f"dropped (AI-paste):      {s['ai_paste']:>8,}")
    print("-" * 60)
    for tier in ("all", "substantive", "expressive", "voice"):
        recs = tiers[tier]
        print(f"TIER {tier:<12} {len(recs):>8,} msgs  {w(recs):>9,} words")
    print("-" * 60)
    for tier, path in paths.items():
        print(f"  wrote {path}")
    if pack_path:
        print(f"  wrote {pack_path}  <- portable voice pack")
    print("-" * 60)
    voice = tiers["voice"]
    if voice:
        print(f"sample of VOICE tier:")
        step = max(1, len(voice) // args.samples)
        for r in voice[::step][: args.samples]:
            print(f"  [{r.words:>3}w] {r.text[:150]}")


def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    cls = SOURCES[args.source]
    src = cls.from_args(args)

    result = build_corpus(
        src.records(),
        min_words=args.min_words,
        voice_lo=args.voice_lo,
        voice_hi=args.voice_hi,
        self_only=not args.all_messages,
    )
    paths = _write_tiers(args.out, result)

    pack_path = None
    if args.pack:
        pack_path = os.path.join(args.out, "voice-pack.md")
        with open(pack_path, "w", encoding="utf-8") as f:
            f.write(build_pack(result["tiers"]["voice"], n=args.pack_n, name=args.name))

    _report(args, result, paths, pack_path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
