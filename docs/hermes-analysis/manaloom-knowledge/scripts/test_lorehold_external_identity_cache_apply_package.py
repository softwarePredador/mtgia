from pathlib import Path

import lorehold_external_identity_cache_apply_package as package


def resolution_report() -> dict:
    return {
        "resolution_rows": [
            {
                "card_name": "Brain in a Jar",
                "cache_insert_ready": True,
                "post_import_status": "identity_ready_then_runtime_or_cut_safety_required",
                "commander_legal": True,
                "lorehold_color_identity_compatible": True,
                "lookup": {
                    "lookup_status": "found",
                    "name": "Brain in a Jar",
                    "oracle_id": "brain-oracle",
                    "scryfall_id": "brain-scryfall",
                    "mana_cost": "{2}",
                    "cmc": 2,
                    "type_line": "Artifact",
                    "oracle_text": "Text with 'quote'.",
                    "colors": [],
                    "color_identity": [],
                    "keywords": [],
                },
            },
            {
                "card_name": "Haze of Rage",
                "cache_insert_ready": True,
                "post_import_status": "identity_ready_then_combo_runtime_and_cut_safety_required",
                "commander_legal": True,
                "lorehold_color_identity_compatible": True,
                "lookup": {
                    "lookup_status": "found",
                    "name": "Haze of Rage",
                    "oracle_id": "haze-oracle",
                    "scryfall_id": "haze-scryfall",
                    "mana_cost": "{1}{R}",
                    "cmc": 2,
                    "type_line": "Sorcery",
                    "oracle_text": "Buyback text.",
                    "colors": ["R"],
                    "color_identity": ["R"],
                    "keywords": [],
                },
            },
        ]
    }


def test_build_sql_files_quotes_values_and_keeps_marker():
    rows = package.ready_rows(resolution_report())
    sql = package.build_sql_files(rows, updated_at="2026-07-05T00:00:00Z")

    assert "Text with ''quote''." in sql["apply"]
    assert package.SOURCE_MARKER in sql["apply"]
    assert "ON CONFLICT" not in sql["apply"]
    assert "DELETE FROM card_oracle_cache" in sql["rollback"]
    assert "expected after apply" in sql["postcheck"].lower()


def test_payload_is_not_applied_and_keeps_607():
    rows = package.ready_rows(resolution_report())
    payload = package.build_payload(
        resolution_report=resolution_report(),
        resolution_path=Path("/tmp/resolution.json"),
        sql_paths={
            "precheck": Path("/tmp/pre.sql"),
            "apply": Path("/tmp/apply.sql"),
            "postcheck": Path("/tmp/post.sql"),
            "rollback": Path("/tmp/rollback.sql"),
        },
        rows=rows,
    )

    assert payload["status"] == "external_identity_cache_apply_package_prepared_not_applied_keep_607"
    assert payload["source_db_mutated"] is False
    assert payload["sqlite_apply_executed"] is False
    assert payload["summary"]["promotion_allowed"] is False


def test_markdown_surfaces_sql_files_and_rows():
    rows = package.ready_rows(resolution_report())
    payload = package.build_payload(
        resolution_report=resolution_report(),
        resolution_path=Path("/tmp/resolution.json"),
        sql_paths={
            "precheck": Path("/tmp/pre.sql"),
            "apply": Path("/tmp/apply.sql"),
            "postcheck": Path("/tmp/post.sql"),
            "rollback": Path("/tmp/rollback.sql"),
        },
        rows=rows,
    )
    markdown = package.render_markdown(payload)

    assert "Lorehold External Identity Cache Apply Package" in markdown
    assert "SQL Files" in markdown
    assert "Brain in a Jar" in markdown
