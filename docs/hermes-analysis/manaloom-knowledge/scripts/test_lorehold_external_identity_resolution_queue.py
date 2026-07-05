from pathlib import Path

import lorehold_external_identity_resolution_queue as queue


def preflight_report() -> dict:
    return {
        "queues": {"identity_import_required": ["Brain in a Jar", "Haze of Rage", "Late to Dinner"]},
        "preflight_rows": [
            {
                "card_name": "Brain in a Jar",
                "preflight_status": "identity_import_required",
                "route_types": ["topdeck_pressure_reference"],
            },
            {
                "card_name": "Haze of Rage",
                "preflight_status": "identity_import_required_before_combo_runtime",
                "route_types": ["combo_package"],
            },
            {
                "card_name": "Late to Dinner",
                "preflight_status": "identity_import_required",
                "route_types": ["archetype_fork"],
            },
        ],
    }


def found(name: str, colors: list[str], commander: str = "legal") -> dict:
    return {
        "lookup_status": "found",
        "name": name,
        "oracle_id": f"{name}-oracle",
        "scryfall_id": f"{name}-scryfall",
        "mana_cost": "{2}",
        "cmc": 2,
        "type_line": "Artifact",
        "oracle_text": "test text",
        "colors": colors,
        "color_identity": colors,
        "keywords": [],
        "legalities": {"commander": commander},
        "scryfall_uri": "https://scryfall.test/card",
        "scryfall_api_url": "https://api.scryfall.test/cards/named",
    }


def build_payload() -> dict:
    return queue.build_payload(
        preflight_report=preflight_report(),
        preflight_path=Path("/tmp/preflight.json"),
        scryfall_lookups={
            "Brain in a Jar": found("Brain in a Jar", []),
            "Haze of Rage": found("Haze of Rage", ["R"]),
            "Late to Dinner": found("Late to Dinner", ["W"]),
        },
    )


def test_resolution_queue_is_report_only_and_keeps_607():
    payload = build_payload()

    assert payload["status"] == "external_identity_resolution_ready_for_apply_plan_keep_607"
    assert payload["source_db_mutated"] is False
    assert payload["apply_sqlite_allowed_now"] is False
    assert payload["summary"]["promotion_allowed"] is False
    assert payload["decision"]["natural_battle_allowed_now"] is False


def test_found_legal_lorehold_cards_are_cache_ready_but_not_deck_ready():
    payload = build_payload()
    rows = {row["card_name"]: row for row in payload["resolution_rows"]}

    assert payload["summary"]["cache_insert_ready_count"] == 3
    assert rows["Brain in a Jar"]["post_import_status"] == "identity_ready_then_runtime_or_cut_safety_required"
    assert rows["Haze of Rage"]["post_import_status"] == "identity_ready_then_combo_runtime_and_cut_safety_required"
    assert rows["Late to Dinner"]["post_import_status"] == "identity_ready_then_shell_contract_required"
    assert rows["Haze of Rage"]["deck_test_allowed_after_identity"] is False


def test_failed_lookup_blocks_identity_resolution():
    payload = queue.build_payload(
        preflight_report=preflight_report(),
        preflight_path=Path("/tmp/preflight.json"),
        scryfall_lookups={
            "Brain in a Jar": {"lookup_status": "not_found", "details": "missing"},
            "Haze of Rage": found("Haze of Rage", ["R"]),
            "Late to Dinner": found("Late to Dinner", ["W"]),
        },
    )
    rows = {row["card_name"]: row for row in payload["resolution_rows"]}

    assert rows["Brain in a Jar"]["cache_insert_ready"] is False
    assert rows["Brain in a Jar"]["post_import_status"] == "identity_resolution_blocked"
    assert "scryfall_identity_not_resolved" in rows["Brain in a Jar"]["blockers"]


def test_markdown_surfaces_resolution_rows_and_queues():
    markdown = queue.render_markdown(build_payload())

    assert "Lorehold External Identity Resolution Queue" in markdown
    assert "Resolution Rows" in markdown
    assert "cache_insert_ready" in markdown
    assert "Haze of Rage" in markdown
