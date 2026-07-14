import json

import sync_game_changers_to_dart as sync


def test_reviewed_source_matches_generated_runtime():
    names = sync.read_game_changer_names(sync.DEFAULT_SOURCE)
    source = sync.DEFAULT_DART.read_text(encoding="utf-8")
    assert len(names) == 53
    assert sync.replace_generated_block(source, sync.render_block(names)) == source


def test_source_requires_official_provenance(tmp_path):
    source = tmp_path / "game_changers.json"
    source.write_text(
        json.dumps(
            {
                "schema_version": "commander_game_changers_v1",
                "source_url": "https://example.com/not-official",
                "source_checked_at": "2026-07-14",
                "names": [f"Card {index}" for index in range(53)],
            }
        ),
        encoding="utf-8",
    )

    try:
        sync.read_game_changer_names(source)
    except SystemExit as error:
        assert "official Wizards URL" in str(error)
    else:
        raise AssertionError("untrusted source provenance was accepted")
