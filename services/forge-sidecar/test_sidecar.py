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
                forge_sidecar.subprocess, "run", return_value=completed
            ):
                with self.assertRaises(forge_sidecar.SimulationTimeout):
                    service.simulate(request)


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
