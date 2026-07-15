import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


MODULE_PATH = Path(__file__).with_name("sidecar.py")
SPEC = importlib.util.spec_from_file_location("forge_sidecar", MODULE_PATH)
forge_sidecar = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = forge_sidecar
SPEC.loader.exec_module(forge_sidecar)


class ForgeSidecarTest(unittest.TestCase):
    def test_global_corpus_payload_limit_and_process_identity(self):
        self.assertEqual(8 * 1024 * 1024, forge_sidecar.MAX_REQUEST_BYTES)
        self.assertTrue(forge_sidecar.PROCESS_ID)
        self.assertTrue(forge_sidecar.STARTED_AT.endswith("Z"))

    def test_card_index_and_split_name_resolution(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "e" / "emerias_call.txt"
            path.parent.mkdir(parents=True)
            path.write_text("Name:Emeria's Call\nTypes:Sorcery\n", encoding="utf-8")
            index = forge_sidecar.load_card_index(Path(directory))
            card = forge_sidecar.CardInput.parse(
                {"name": "Emeria's Call // Emeria, Shattered Skyclave"}
            )
            self.assertEqual("Emeria's Call", card.resolve(index))

    def test_deck_rejects_non_commander_cardinality(self):
        with self.assertRaisesRegex(
            forge_sidecar.InvalidRequest, "exactly 100 cards"
        ):
            forge_sidecar.DeckInput.parse(
                {
                    "cards": [
                        {"name": "Sol Ring", "quantity": 1, "is_commander": True}
                    ]
                },
                "deck_a",
            )

    def test_parse_requires_real_game_result(self):
        deck = _deck("deck-a", "Deck A")
        with self.assertRaisesRegex(forge_sidecar.SimulationFailed, "no completed"):
            forge_sidecar.parse_simulation_output(
                "Simulation mode\nCould not load deck - a.dck, match cannot start\n",
                request_id="test",
                seed=1,
                deck_a=deck,
                deck_b=_deck("deck-b", "Deck B"),
                duration_ms=3,
                started_at="2026-07-14T00:00:00Z",
                forge_commit="abc",
            )

    def test_parse_rejects_completed_game_with_engine_error(self):
        with self.assertRaisesRegex(forge_sidecar.SimulationFailed, "engine errors"):
            forge_sidecar.parse_simulation_output(
                "\n".join(
                    [
                        "Ai(1)-Deck A vs Ai(2)-Deck B - one game of Commander",
                        "RuntimeException: card script failed",
                        "Game Outcome: Turn 2",
                        "Game Result: Game 1 ended in 1000 ms. Ai(1)-Deck A has won!",
                    ]
                ),
                request_id="test",
                seed=1,
                deck_a=_deck("deck-a", "Deck A"),
                deck_b=_deck("deck-b", "Deck B"),
                duration_ms=1200,
                started_at="2026-07-14T00:00:00Z",
                forge_commit="abc",
            )

    def test_parse_completed_game_and_card_use(self):
        result = forge_sidecar.parse_simulation_output(
            "\n".join(
                [
                    "Ai(1)-Deck A vs Ai(2)-Deck B - one game of Commander",
                    "Turn: Turn 1 (Ai(1)-Deck A)",
                    "Add To Stack: Ai(1)-Deck A cast Sol Ring",
                    "Game Outcome: Turn 7",
                    "Game Result: Game 1 ended in 2830 ms. Ai(1)-Deck A has won!",
                ]
            ),
            request_id="test",
            seed=7,
            deck_a=_deck("deck-a", "Deck A"),
            deck_b=_deck("deck-b", "Deck B"),
            duration_ms=4000,
            started_at="2026-07-14T00:00:00Z",
            forge_commit="abc",
        )
        self.assertEqual("forge", result["engine"])
        self.assertEqual("deck-a", result["winner_deck_id"])
        self.assertEqual(7, result["turns"])
        self.assertEqual("Sol Ring", result["events"][1]["card_name"])
        self.assertEqual(1, result["metrics"]["cards_cast"])
        self.assertEqual([], result["decision_trace"])
        self.assertEqual(
            "best_effort_engine_log_lower_bound",
            result["learning_contract"]["event_stream_completeness"],
        )
        self.assertFalse(result["learning_contract"]["absence_proves_nonuse"])
        self.assertFalse(result["learning_contract"]["strategy_or_swap_proof"])

    def test_event_parser_stops_after_game_result(self):
        events = forge_sidecar._events_from_output(
            "\n".join(
                [
                    "Ai(1)-Deck A vs Ai(2)-Deck B - one game of Commander",
                    "Turn: Turn 1 (Ai(1)-Deck A)",
                    "Game Result: Game 1 ended in a Draw! Took 1000 ms.",
                    "stderr: trailing process noise",
                ]
            )
        )
        self.assertEqual(1, len(events))
        self.assertEqual("turn", events[0]["type"])

    def test_forge_internal_timeout_is_not_accepted_as_draw(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            forge_jar = root / "forge.jar"
            forge_jar.touch()
            service = forge_sidecar.ForgeService(
                forge_home=root,
                forge_jar=forge_jar,
                bootstrap_jar=None,
                java_command=("java",),
                deck_dir=root / "decks",
                card_index={"commander": "Commander", "plains": "Plains"},
                forge_commit="abc",
            )
            request = {
                "timeout_ms": 1000,
                "deck_a": _deck_payload("deck-a", "Deck A"),
                "deck_b": _deck_payload("deck-b", "Deck B"),
            }
            completed = forge_sidecar.subprocess.CompletedProcess(
                args=[],
                returncode=0,
                stdout="\n".join(
                    [
                        "Stopping slow match as draw",
                        "Game Result: Game 1 ended in a Draw! Took 1000 ms.",
                    ]
                ),
                stderr="",
            )
            with mock.patch.object(
                forge_sidecar, "run_isolated_process", return_value=completed
            ):
                with self.assertRaises(forge_sidecar.SimulationTimeout):
                    service.simulate(request)

    def test_isolated_process_kills_process_group_on_timeout(self):
        process = mock.Mock(pid=321, returncode=-9)
        process.communicate.side_effect = [
            forge_sidecar.subprocess.TimeoutExpired("forge", 6),
            ("stdout", "stderr"),
        ]

        with mock.patch.object(
            forge_sidecar.subprocess, "Popen", return_value=process
        ) as popen:
            with mock.patch.object(forge_sidecar.os, "killpg") as killpg:
                with self.assertRaises(forge_sidecar.subprocess.TimeoutExpired):
                    forge_sidecar.run_isolated_process(
                        ["forge"], cwd=Path("/tmp"), timeout=6, env={}
                    )

        self.assertTrue(popen.call_args.kwargs["start_new_session"])
        killpg.assert_called_once_with(321, forge_sidecar.signal.SIGKILL)
        self.assertEqual(2, process.communicate.call_count)

    def test_process_timeout_uses_only_bounded_startup_grace(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            forge_jar = root / "forge.jar"
            forge_jar.touch()
            service = forge_sidecar.ForgeService(
                forge_home=root,
                forge_jar=forge_jar,
                bootstrap_jar=None,
                java_command=("java",),
                deck_dir=root / "decks",
                card_index={"commander": "Commander", "plains": "Plains"},
                forge_commit="abc",
            )
            request = {
                "timeout_ms": 1000,
                "deck_a": _deck_payload("deck-a", "Deck A"),
                "deck_b": _deck_payload("deck-b", "Deck B"),
            }
            timeout = forge_sidecar.subprocess.TimeoutExpired("forge", 6)

            with mock.patch.object(
                forge_sidecar, "run_isolated_process", side_effect=timeout
            ) as run:
                with self.assertRaisesRegex(
                    forge_sidecar.SimulationTimeout, "exceeded 6000 ms"
                ):
                    service.simulate(request)

            self.assertEqual(6, run.call_args.kwargs["timeout"])

    def test_send_ignores_disconnected_client(self):
        handler = forge_sidecar.ForgeHandler.__new__(forge_sidecar.ForgeHandler)
        handler.send_response = mock.Mock()
        handler.send_header = mock.Mock()
        handler.end_headers = mock.Mock()
        handler.wfile = mock.Mock()
        handler.wfile.write.side_effect = BrokenPipeError

        handler._send(504, {"error": "simulation_timeout"})

        handler.wfile.write.assert_called_once()


def _deck(deck_id, name):
    return forge_sidecar.DeckInput(
        deck_id=deck_id,
        name=name,
        cards=(
            forge_sidecar.CardInput(
                name="Commander", quantity=1, is_commander=True
            ),
            forge_sidecar.CardInput(name="Plains", quantity=99, is_commander=False),
        ),
    )


def _deck_payload(deck_id, name):
    return {
        "id": deck_id,
        "name": name,
        "cards": [
            {"name": "Commander", "quantity": 1, "is_commander": True},
            {"name": "Plains", "quantity": 99, "is_commander": False},
        ],
    }


if __name__ == "__main__":
    unittest.main()
