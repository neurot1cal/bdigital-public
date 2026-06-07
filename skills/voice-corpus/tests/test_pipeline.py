"""Unit tests for the source-agnostic pipeline, adapters, and voice pack.

Pure-stdlib (unittest). Run from the skill directory:
    python3 -m unittest discover -s tests -v
"""
import json
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from voicecorpus.pipeline import (  # noqa: E402
    clean, word_count, is_noise, is_ai_paste, build_corpus,
)
from voicecorpus.record import RawMessage  # noqa: E402
from voicecorpus.pack import build_pack  # noqa: E402


class TestClean(unittest.TestCase):
    def test_collapses_whitespace_and_strips_attachment_placeholder(self):
        self.assertEqual(clean("  hey   there \n man  "), "hey there man")
        self.assertEqual(clean("photo ￼ here"), "photo here")

    def test_word_count(self):
        self.assertEqual(word_count("one two three"), 3)


class TestNoise(unittest.TestCase):
    def test_url_only_is_noise(self):
        self.assertTrue(is_noise("https://example.com/x"))

    def test_emoji_only_is_noise(self):
        self.assertTrue(is_noise("😂😂🔥"))

    def test_reaction_is_noise(self):
        self.assertTrue(is_noise('Loved “see you then”'))

    def test_real_message_is_not_noise(self):
        self.assertFalse(is_noise("running late, leaving the house now"))


class TestAiPaste(unittest.TestCase):
    def test_em_dash_flagged(self):
        self.assertTrue(is_ai_paste("This is a tool — not a silver bullet."))

    def test_markdown_bold_flagged(self):
        self.assertTrue(is_ai_paste("Here are the **key** points"))

    def test_code_fence_flagged(self):
        self.assertTrue(is_ai_paste("```\n#!/usr/bin/env bash\n```"))

    def test_preamble_flagged(self):
        self.assertTrue(is_ai_paste("Here's a precise step-by-step breakdown of the thing"))

    def test_structured_list_flagged(self):
        self.assertTrue(is_ai_paste("1. first thing\n2. second thing"))

    def test_authentic_casual_message_not_flagged(self):
        self.assertFalse(is_ai_paste(
            "nobody's gonna bet the business on a bot that gets state wrong at 2am"))
        self.assertFalse(is_ai_paste("i hate trucks that are too wide"))


class TestBuildCorpus(unittest.TestCase):
    def _msgs(self):
        return [
            RawMessage("ok", True, "t"),                       # too short, but kept in 'all'
            RawMessage("this is a genuinely expressive sentence with enough words here now", True, "t"),
            RawMessage("https://x.com", True, "t"),            # noise
            RawMessage("This is great — really.", True, "t"),  # ai-paste
            RawMessage("someone else wrote this longer message that we should drop", False, "t"),
        ]

    def test_self_only_drops_others(self):
        out = build_corpus(self._msgs(), self_only=True)
        self.assertEqual(out["stats"]["not_self"], 1)
        self.assertTrue(all(r.text != "someone else wrote this longer message that we should drop"
                            for r in out["records"]))

    def test_filters_counted(self):
        out = build_corpus(self._msgs(), self_only=True)
        self.assertEqual(out["stats"]["noise"], 1)
        self.assertEqual(out["stats"]["ai_paste"], 1)

    def test_tiers_monotonic(self):
        out = build_corpus(self._msgs(), self_only=True, min_words=8)
        t = out["tiers"]
        self.assertGreaterEqual(len(t["all"]), len(t["substantive"]))
        self.assertGreaterEqual(len(t["substantive"]), len(t["expressive"]))

    def test_all_messages_keeps_others(self):
        out = build_corpus(self._msgs(), self_only=False)
        self.assertEqual(out["stats"]["not_self"], 0)


class TestAdapters(unittest.TestCase):
    def setUp(self):
        # import here so registration happens
        import voicecorpus.sources  # noqa: F401
        self.tmp = tempfile.mkdtemp()

    def test_textlines_txt(self):
        from voicecorpus.sources.textlines import TextLinesSource
        p = os.path.join(self.tmp, "x.txt")
        open(p, "w").write("first line\nsecond line\n\n")
        recs = list(TextLinesSource(p).records())
        self.assertEqual([r.text for r in recs], ["first line", "second line"])
        self.assertTrue(all(r.is_self for r in recs))

    def test_textlines_jsonl_respects_is_self(self):
        from voicecorpus.sources.textlines import TextLinesSource
        p = os.path.join(self.tmp, "x.jsonl")
        with open(p, "w") as f:
            f.write(json.dumps({"text": "mine", "is_self": True}) + "\n")
            f.write(json.dumps({"text": "theirs", "is_self": False}) + "\n")
        recs = list(TextLinesSource(p).records())
        self.assertEqual(len(recs), 2)
        self.assertTrue(recs[0].is_self)
        self.assertFalse(recs[1].is_self)

    def test_slack_export(self):
        from voicecorpus.sources.slack import SlackSource
        chan = os.path.join(self.tmp, "general")
        os.makedirs(chan)
        with open(os.path.join(chan, "2026-01-01.json"), "w") as f:
            json.dump([
                {"type": "message", "user": "U1", "text": "hey <@U2> check <http://a.com|this>", "ts": "1700000000.0"},
                {"type": "message", "user": "U2", "text": "not mine", "ts": "1700000001.0"},
                {"type": "message", "subtype": "channel_join", "user": "U1", "text": "joined"},
            ], f)
        recs = list(SlackSource(self.tmp, user_id="U1").records())
        self.assertEqual(len(recs), 2)
        mine = [r for r in recs if r.is_self]
        self.assertEqual(mine[0].text, "hey  check this")  # mention stripped, link labeled

    def test_discord_csv(self):
        from voicecorpus.sources.discord import DiscordSource
        d = os.path.join(self.tmp, "messages", "c123")
        os.makedirs(d)
        with open(os.path.join(d, "messages.csv"), "w", newline="") as f:
            f.write("ID,Timestamp,Contents,Attachments\n")
            f.write("1,2026-01-01T00:00:00,hello world,\n")
            f.write("2,2026-01-01T00:01:00,,\n")
        recs = list(DiscordSource(self.tmp).records())
        self.assertEqual([r.text for r in recs], ["hello world"])
        self.assertTrue(recs[0].is_self)

    def test_markdown_paragraphs(self):
        from voicecorpus.sources.markdown_docs import MarkdownDocsSource
        p = os.path.join(self.tmp, "post.md")
        open(p, "w").write("---\ntitle: x\n---\n# Heading\n\nFirst **para** here.\n\nSecond para.\n")
        recs = list(MarkdownDocsSource(self.tmp).records())
        texts = [r.text for r in recs]
        self.assertIn("First para here.", texts)
        self.assertIn("Second para.", texts)
        self.assertTrue(all(r.channel == "doc" for r in recs))


class TestPack(unittest.TestCase):
    def test_pack_contains_samples_and_header(self):
        out = build_corpus(
            [RawMessage("this is a real sentence with enough words to qualify here", True, "t")
             for _ in range(5)],
            self_only=True,
        )
        pack = build_pack(out["tiers"]["voice"], n=3, name="Tester")
        self.assertIn("write as Tester", pack)
        self.assertIn("Real samples", pack)


if __name__ == "__main__":
    unittest.main()
