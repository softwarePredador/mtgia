from pathlib import Path

import lorehold_pressure_tradeoff_variant_builder as builder


def _base_rows():
    rows = [
        {
            "card_name": "Lorehold, the Historian",
            "quantity": 1,
            "functional_tag": "engine",
            "functional_tags_json": '["engine"]',
            "is_commander": 1,
            "type_line": "Legendary Creature",
            "cmc": 5,
            "oracle_text": "Flying",
        }
    ]
    for idx in range(95):
        rows.append(
            {
                "card_name": f"Base Card {idx}",
                "quantity": 1,
                "functional_tag": "draw",
                "functional_tags_json": '["draw"]',
                "is_commander": 0,
                "type_line": "Sorcery",
                "cmc": 3,
                "oracle_text": "Draw a card.",
            }
        )
    rows.extend(
        [
            {
                "card_name": "Call Forth the Tempest",
                "quantity": 1,
                "functional_tag": "board_wipe",
                "functional_tags_json": '["board_wipe"]',
                "is_commander": 0,
                "type_line": "Sorcery",
                "cmc": 8,
                "oracle_text": "Damage all creatures.",
            },
            {
                "card_name": "Tempt with Bunnies",
                "quantity": 1,
                "functional_tag": "wincon",
                "functional_tags_json": '["wincon"]',
                "is_commander": 0,
                "type_line": "Sorcery",
                "cmc": 3,
                "oracle_text": "Create creature tokens.",
            },
            {
                "card_name": "Everything Comes to Dust",
                "quantity": 1,
                "functional_tag": "board_wipe",
                "functional_tags_json": '["board_wipe"]',
                "is_commander": 0,
                "type_line": "Sorcery",
                "cmc": 10,
                "oracle_text": "Exile creatures.",
            },
            {
                "card_name": "Rise of the Eldrazi",
                "quantity": 1,
                "functional_tag": "wincon",
                "functional_tags_json": '["wincon"]',
                "is_commander": 0,
                "type_line": "Sorcery",
                "cmc": 12,
                "oracle_text": "Destroy target permanent.",
            },
        ]
    )
    assert len(rows) == 100
    return rows


def _add(card_name):
    return {
        "card_name": card_name,
        "normalized_name": builder.normalize_name(card_name),
        "quantity": 1,
        "roles": ["creature"],
        "is_commander": False,
        "is_land": False,
        "cmc": 3,
        "type_line": "Creature",
        "oracle_text": "",
    }


def _resolver_report():
    return {
        "primary_adds": [
            "Monastery Mentor",
            "Young Pyromancer",
            "Guttersnipe",
            "Storm-Kiln Artist",
        ],
        "diagnostic_tradeoff_cut_plan": {
            "selected_cuts": [
                {"card_name": "Call Forth the Tempest"},
                {"card_name": "Tempt with Bunnies"},
                {"card_name": "Everything Comes to Dust"},
                {"card_name": "Rise of the Eldrazi"},
            ]
        },
    }


def test_apply_tradeoff_keeps_legal_quantity_and_swaps_names():
    final = builder.apply_tradeoff(
        _base_rows(),
        [_add("Monastery Mentor"), _add("Young Pyromancer"), _add("Guttersnipe"), _add("Storm-Kiln Artist")],
        [
            "Call Forth the Tempest",
            "Tempt with Bunnies",
            "Everything Comes to Dust",
            "Rise of the Eldrazi",
        ],
    )
    names = {card["card_name"] for card in final}

    assert sum(card["quantity"] for card in final) == 100
    assert "Monastery Mentor" in names
    assert "Call Forth the Tempest" not in names
    assert sum(1 for card in final if card["is_commander"]) == 1


def test_build_report_marks_candidate_diagnostic_only():
    add_rows = [
        {"name": "Monastery Mentor", "type_line": "Creature", "oracle_text": "", "cmc": 3},
        {"name": "Young Pyromancer", "type_line": "Creature", "oracle_text": "", "cmc": 2},
        {"name": "Guttersnipe", "type_line": "Creature", "oracle_text": "", "cmc": 3},
        {"name": "Storm-Kiln Artist", "type_line": "Creature", "oracle_text": "", "cmc": 4},
    ]

    report = builder.build_report(
        resolver_report=_resolver_report(),
        base_rows=_base_rows(),
        add_rows=add_rows,
        resolver_path=Path("/tmp/resolver.json"),
        source_db=Path("/tmp/knowledge.db"),
    )

    assert report["status"] == "generated_diagnostic_only_candidate"
    assert report["diagnostic_only"] is True
    assert report["promotion_eligible"] is False
    assert report["natural_battle_gate_allowed"] is False
    assert report["quantity_total"] == 100


def test_apply_tradeoff_rejects_missing_cut():
    try:
        builder.apply_tradeoff(_base_rows(), [_add("Monastery Mentor")], ["Missing Cut"])
    except RuntimeError as exc:
        assert "cut cards missing" in str(exc)
    else:
        raise AssertionError("expected missing cut to fail")
