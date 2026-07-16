#!/usr/bin/env python3
"""Focused fail-closed tests for direct historical EDHREC collectors."""

from __future__ import annotations

import io
import os
import runpy
import subprocess
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
FETCH_SCRIPT = SCRIPT_DIR / "fetch_edhrec_live.py"
RESEARCH_SCRIPT = SCRIPT_DIR / "research_vampires_theme_20260527.py"
SCOUT_SCRIPT = (
    REPO_ROOT
    / "docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian"
    / "scout_cycle_20260527.py"
)
AUTHORIZATION_FLAG = "MANALOOM_EDHREC_AUTOMATED_COLLECTION_AUTHORIZED"


class EdhrecCollectionGateTest(unittest.TestCase):
    def setUp(self) -> None:
        self.original_flag = os.environ.pop(AUTHORIZATION_FLAG, None)

    def tearDown(self) -> None:
        if self.original_flag is None:
            os.environ.pop(AUTHORIZATION_FLAG, None)
        else:
            os.environ[AUTHORIZATION_FLAG] = self.original_flag

    def test_standalone_fetch_exits_before_urlopen_without_flag(self) -> None:
        with mock.patch("urllib.request.urlopen") as urlopen:
            with self.assertRaises(SystemExit) as caught:
                with redirect_stdout(io.StringIO()):
                    runpy.run_path(str(FETCH_SCRIPT), run_name="__main__")

        self.assertEqual(caught.exception.code, 78)
        urlopen.assert_not_called()

    def test_scout_blocks_edhrec_before_curl_without_flag(self) -> None:
        namespace = runpy.run_path(str(SCOUT_SCRIPT))
        runner = mock.Mock(side_effect=AssertionError("curl must not run"))
        namespace["run"] = runner

        with self.assertRaisesRegex(RuntimeError, "fail-closed"):
            namespace["curl_text"](
                "https://json.edhrec.com/pages/commanders/lorehold.json"
            )

        runner.assert_not_called()

    def test_research_blocks_edhrec_before_curl_without_flag(self) -> None:
        namespace = runpy.run_path(str(RESEARCH_SCRIPT))
        with mock.patch.object(namespace["subprocess"], "run") as runner:
            result = namespace["curl"](
                "https://edhrec.com/commanders/edgar-markov"
            )

        self.assertEqual(result["exit_code"], 78)
        self.assertIn("fail-closed", result["stderr"])
        runner.assert_not_called()

    def test_explicit_flag_enables_edhrec_request_path(self) -> None:
        os.environ[AUTHORIZATION_FLAG] = "true"
        namespace = runpy.run_path(str(RESEARCH_SCRIPT))
        completed = subprocess.CompletedProcess(
            args=["curl"],
            returncode=0,
            stdout="authorized",
            stderr="",
        )
        with mock.patch.object(
            namespace["subprocess"],
            "run",
            return_value=completed,
        ) as runner:
            result = namespace["curl"](
                "https://edhrec.com/commanders/edgar-markov"
            )

        self.assertEqual(result["exit_code"], 0)
        self.assertEqual(result["stdout"], "authorized")
        runner.assert_called_once()

    def test_authorized_snapshot_strips_nested_auth_metadata(self) -> None:
        os.environ[AUTHORIZATION_FLAG] = "true"
        raw_payload = {
            "props": {
                "pageProps": {
                    "data": {
                        "site": {"auth": "sensitive-placeholder", "name": "EDHREC"},
                        "container": {
                            "json_dict": {
                                "cardlists": [
                                    {
                                        "cardviews": [
                                            {"name": "Arcane Signet", "auth": "nested-placeholder"}
                                        ]
                                    }
                                ]
                            }
                        },
                    }
                }
            }
        }
        html = (
            '<script id="__NEXT_DATA__" type="application/json">'
            + __import__("json").dumps(raw_payload)
            + "</script>"
        ).encode()
        response = mock.MagicMock()
        response.__enter__.return_value.read.return_value = html
        opened = mock.mock_open()

        with mock.patch("urllib.request.urlopen", return_value=response):
            with mock.patch("builtins.open", opened):
                with redirect_stdout(io.StringIO()):
                    runpy.run_path(str(FETCH_SCRIPT), run_name="__main__")

        written = "".join(
            call.args[0]
            for call in opened().write.call_args_list
            if call.args and isinstance(call.args[0], str)
        )
        sanitized = __import__("json").loads(written)
        self.assertNotIn("auth", sanitized["props"]["pageProps"]["data"]["site"])
        card = sanitized["props"]["pageProps"]["data"]["container"]["json_dict"]["cardlists"][0]["cardviews"][0]
        self.assertEqual(card["name"], "Arcane Signet")
        self.assertNotIn("auth", card)


if __name__ == "__main__":
    unittest.main()
