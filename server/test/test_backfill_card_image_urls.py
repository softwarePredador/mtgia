import importlib.util
import json
from pathlib import Path
import sys

import pytest


MODULE_PATH = (
    Path(__file__).resolve().parents[1] / "bin" / "backfill_card_image_urls.py"
)
SPEC = importlib.util.spec_from_file_location("backfill_card_image_urls", MODULE_PATH)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


PRINTING_ID = "00000000-0000-4000-8000-000000000011"
PRINTING_ID_2 = "00000000-0000-4000-8000-000000000012"
ORACLE_ID = "00000000-0000-4000-8000-000000000010"
DIRECT_URL = (
    "https://cards.scryfall.io/normal/front/0/0/"
    f"{PRINTING_ID}.jpg?123"
)
DIRECT_URL_2 = (
    "https://cards.scryfall.io/normal/front/0/0/"
    f"{PRINTING_ID_2}.jpg?456"
)


def test_default_bulk_index_accepts_only_matching_direct_images(
    tmp_path: Path,
) -> None:
    fixture = [
        {
            "id": PRINTING_ID,
            "oracle_id": ORACLE_ID,
            "set": "TST",
            "collector_number": "7",
            "image_uris": {"normal": DIRECT_URL},
        },
        {
            "id": "00000000-0000-4000-8000-000000000021",
            "oracle_id": "00000000-0000-4000-8000-000000000020",
            "image_uris": {"normal": "https://example.com/not-scryfall.jpg"},
        },
    ]
    path = tmp_path / "default-cards.json"
    path.write_text(json.dumps(fixture), encoding="utf-8")

    index = MODULE.load_card_image_index(path)

    assert index.by_printing == {PRINTING_ID: DIRECT_URL}
    assert index.by_oracle_set_collector == {
        (ORACLE_ID, "tst", "7"): frozenset({DIRECT_URL})
    }
    assert index.by_oracle_set == {
        (ORACLE_ID, "tst"): frozenset({DIRECT_URL})
    }
    assert index.by_oracle == {ORACLE_ID: frozenset({DIRECT_URL})}


def test_plan_updates_only_missing_or_legacy_api_urls() -> None:
    index = MODULE.CardImageIndex(
        by_printing={PRINTING_ID: DIRECT_URL},
        by_oracle_set_collector={
            (ORACLE_ID, "tst", "7"): frozenset({DIRECT_URL})
        },
        by_oracle_set={(ORACLE_ID, "tst"): frozenset({DIRECT_URL})},
        by_oracle={ORACLE_ID: frozenset({DIRECT_URL})},
    )
    rows = [
        ("card-1", PRINTING_ID, ORACLE_ID, "TST", "7", None),
        (
            "card-2",
            ORACLE_ID,
            ORACLE_ID,
            "TST",
            "7",
            "https://api.scryfall.com/cards/named?exact=Test&format=image",
        ),
        ("card-3", ORACLE_ID, ORACLE_ID, "TST", "7", DIRECT_URL),
        (
            "card-4",
            ORACLE_ID,
            ORACLE_ID,
            "TST",
            "7",
            "https://images.example/card.jpg",
        ),
    ]

    updates, stats = MODULE.plan_updates(rows, index)

    assert [row[0] for row in updates] == ["card-1", "card-2"]
    assert stats["scanned"] == 4
    assert stats["exact_printing"] == 1
    assert stats["legacy_set_collector"] == 1
    assert stats["already_direct_or_external"] == 2


def test_two_real_printings_keep_their_own_art() -> None:
    index = MODULE.CardImageIndex(
        by_printing={
            PRINTING_ID: DIRECT_URL,
            PRINTING_ID_2: DIRECT_URL_2,
        },
        by_oracle_set_collector={},
        by_oracle_set={},
        by_oracle={},
    )
    legacy = "https://api.scryfall.com/cards/named?exact=Test&format=image"
    rows = [
        ("card-1", PRINTING_ID, ORACLE_ID, "TST", "7", legacy),
        ("card-2", PRINTING_ID_2, ORACLE_ID, "TST", "8", legacy),
    ]

    updates, stats = MODULE.plan_updates(rows, index)

    assert [row[2] for row in updates] == [DIRECT_URL, DIRECT_URL_2]
    assert stats["exact_printing"] == 2


def test_legacy_alias_uses_unique_set_but_skips_ambiguous_art() -> None:
    unique_set_index = MODULE.CardImageIndex(
        by_printing={},
        by_oracle_set_collector={},
        by_oracle_set={(ORACLE_ID, "one"): frozenset({DIRECT_URL})},
        by_oracle={ORACLE_ID: frozenset({DIRECT_URL, DIRECT_URL_2})},
    )
    ambiguous_set_index = MODULE.CardImageIndex(
        by_printing={},
        by_oracle_set_collector={},
        by_oracle_set={
            (ORACLE_ID, "tst"): frozenset({DIRECT_URL, DIRECT_URL_2})
        },
        by_oracle={ORACLE_ID: frozenset({DIRECT_URL, DIRECT_URL_2})},
    )
    legacy = "https://api.scryfall.com/cards/named?exact=Test&format=image"
    row = ("card-1", ORACLE_ID, ORACLE_ID, "ONE", None, legacy)

    updates, stats = MODULE.plan_updates([row], unique_set_index)
    assert updates == [("card-1", legacy, DIRECT_URL)]
    assert stats["legacy_set_unique"] == 1

    ambiguous_row = ("card-2", ORACLE_ID, ORACLE_ID, "TST", None, legacy)
    updates, stats = MODULE.plan_updates(
        [ambiguous_row],
        ambiguous_set_index,
    )
    assert updates == []
    assert stats["legacy_ambiguous"] == 1


def test_apply_sql_is_compare_and_set_and_never_rekeys_cards() -> None:
    source = MODULE_PATH.read_text(encoding="utf-8")
    update_sql = source.split("UPDATE cards AS c", 1)[1].split('"""', 1)[0]

    assert "SET image_url = incoming.image_url" in update_sql
    assert "c.id = incoming.card_id::uuid" in update_sql
    assert "c.image_url IS NOT DISTINCT FROM incoming.previous_url" in update_sql
    assert "SET scryfall_id" not in update_sql
    assert "SET oracle_id" not in update_sql


def test_apply_requires_both_explicit_approval_tokens() -> None:
    with pytest.raises(RuntimeError) as error:
        MODULE.require_apply_approval(
            {MODULE.LIVE_APPROVAL_ENV: MODULE.APPROVAL_VALUE}
        )

    assert MODULE.POSTGRES_APPROVAL_ENV in str(error.value)
    MODULE.require_apply_approval(
        {
            MODULE.LIVE_APPROVAL_ENV: MODULE.APPROVAL_VALUE,
            MODULE.POSTGRES_APPROVAL_ENV: MODULE.APPROVAL_VALUE,
            MODULE.WRAPPER_MODE_ENV: "write-approved",
        }
    )


def test_apply_requires_the_pinned_postgres_wrapper() -> None:
    with pytest.raises(RuntimeError, match="with_new_server_pg.sh"):
        MODULE.require_apply_approval(
            {
                MODULE.LIVE_APPROVAL_ENV: MODULE.APPROVAL_VALUE,
                MODULE.POSTGRES_APPROVAL_ENV: MODULE.APPROVAL_VALUE,
            }
        )


def test_dry_run_connection_is_forced_read_only() -> None:
    class FakeConnection:
        def __init__(self) -> None:
            self.calls = []

        def set_session(self, **kwargs) -> None:
            self.calls.append(kwargs)

    conn = FakeConnection()
    MODULE.configure_connection(conn, apply=False)
    assert conn.calls == [{"readonly": True, "autocommit": False}]

    apply_conn = FakeConnection()
    MODULE.configure_connection(apply_conn, apply=True)
    assert apply_conn.calls == []
