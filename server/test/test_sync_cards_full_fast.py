import importlib.util
import json
from pathlib import Path


MODULE_PATH = Path(__file__).resolve().parents[1] / "bin" / "sync_cards_full_fast.py"
SPEC = importlib.util.spec_from_file_location("sync_cards_full_fast", MODULE_PATH)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def test_atomic_parser_preserves_oracle_identity_and_mana_value(tmp_path: Path) -> None:
    oracle_id = "00000000-0000-4000-8000-000000000010"
    printing_id = "00000000-0000-4000-8000-000000000011"
    fixture = {
        "data": {
            "Test Card": [
                {
                    "name": "Test Card",
                    "manaCost": "{2}{U}",
                    "manaValue": 3.0,
                    "type": "Creature — Wizard",
                    "text": "Draw a card.",
                    "colors": ["U"],
                    "colorIdentity": ["U"],
                    "power": "2",
                    "toughness": "3",
                    "keywords": [],
                    "printings": ["TST"],
                    "rarity": "rare",
                    "isReserved": False,
                    "legalities": {"commander": "Legal"},
                    "identifiers": {
                        "scryfallId": printing_id,
                        "scryfallOracleId": oracle_id,
                    },
                }
            ],
            "Oversized Card": [
                {
                    "name": "Oversized Card",
                    "manaValue": 1000000,
                    "identifiers": {
                        "scryfallOracleId": "00000000-0000-4000-8000-000000000012"
                    },
                }
            ],
        }
    }
    path = tmp_path / "AtomicCards.json"
    path.write_text(json.dumps(fixture), encoding="utf-8")

    cards, legalities = MODULE.parse_atomic_cards(path)

    assert len(cards) == 2
    row = cards[0]
    assert row[0] == oracle_id
    assert row[1] == oracle_id
    assert row[2] == "Test Card"
    assert row[11] == (
        "https://cards.scryfall.io/normal/front/0/0/"
        f"{printing_id}.jpg"
    )
    assert row[14] == 3.0
    assert row[15] is False
    assert cards[1][14] is None
    assert cards[1][11].startswith(
        "https://api.scryfall.com/cards/named?"
    )
    assert "00000000-0000-4000-8000-000000000012" not in cards[1][11]
    assert legalities == [(oracle_id, "commander", "legal")]


def test_image_url_prefers_matching_payload_normal_uri() -> None:
    printing_id = "00000000-0000-4000-8000-000000000021"
    direct = (
        "https://cards.scryfall.io/normal/front/0/0/"
        f"{printing_id}.jpg?123"
    )
    card = {
        "identifiers": {
            "scryfallId": printing_id,
            "scryfallOracleId": "00000000-0000-4000-8000-000000000020",
        },
        "image_uris": {"normal": direct},
    }

    assert MODULE.scryfall_image_url("Direct Art", card, "tst") == direct


def test_upsert_never_downgrades_a_direct_cdn_image() -> None:
    source = MODULE_PATH.read_text(encoding="utf-8")

    assert (
        "WHEN EXCLUDED.image_url LIKE 'https://cards.scryfall.io/%'"
        in source
    )
    assert (
        "WHEN cards.image_url LIKE 'https://cards.scryfall.io/%'"
        in source
    )
