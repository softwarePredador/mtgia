from pathlib import Path

import lorehold_topdeck_forced_access_audit as audit


TARGETS = audit.TARGET_CARDS


def _hypothesis_row(name, *, status="needs_safe_cut_model", priority="P1_forced_access_diagnostic"):
    return {
        "card_name": name,
        "readiness_status": status,
        "priority": priority,
        "allowed_next_test": "forced_access_diagnostic_only_until_miracle_access_floors_pass",
        "hypothesis_lanes": ["topdeck_miracle_setup"],
        "variant_deck_count": 4,
        "variant_deck_ids": [608, 609, 610, 611],
        "runtime_ready": True,
        "staple_tier": "not_format_staple",
        "best_edhrec_rank": None,
        "same_lane_cut_contract": "named_current_607_slot_and_equal_gate_required",
        "same_lane_current_607_anchors": [
            {"card_name": "Sensei's Divining Top"},
            {"card_name": "Scroll Rack"},
            {"card_name": "Land Tax"},
        ],
        "reason": "test",
    }


def _hypothesis_queue(*, ready_card=None, missing_card=None):
    rows = []
    for name in TARGETS:
        if name == missing_card:
            continue
        status = "natural_gate_ready" if name == ready_card else "needs_safe_cut_model"
        rows.append(_hypothesis_row(name, status=status))
    return {
        "status": "lorehold_hypothesis_queue_ready_no_natural_gate",
        "summary": {"natural_gate_ready_count": int(bool(ready_card))},
        "hypotheses": rows,
    }


def _preflight(*, include_floors=True):
    summary = {
        "gate_ready_now_count": 0,
        "promotion_allowed": False,
    }
    if include_floors:
        summary.update(
            {
                "strategic_floors_from_607": {
                    "miracle_cast": 4,
                    "topdeck_manipulation_activated": 5,
                    "lorehold_spell_cast": 22,
                },
                "anchor_access_floors_from_607": {
                    "Land Tax": 1,
                    "Scroll Rack": 1,
                    "Sensei's Divining Top": 2,
                },
            }
        )
    return {
        "status": "no_current_candidate_passes_miracle_access_first_preflight",
        "summary": summary,
    }


def _trace_miner():
    return {"status": "lorehold_miracle_trace_failure_learning_ready"}


def _value_priority():
    return {"status": "card_value_priority_no_direct_cut_ready_current_607"}


def _paths():
    return {
        "hypothesis_queue": Path("/tmp/hypothesis.json"),
        "preflight": Path("/tmp/preflight.json"),
        "trace_miner": Path("/tmp/trace.json"),
        "value_priority": Path("/tmp/value.json"),
    }


def _build(**overrides):
    return audit.build_report(
        hypothesis_queue=overrides.get("hypothesis_queue", _hypothesis_queue()),
        preflight=overrides.get("preflight", _preflight()),
        trace_miner=overrides.get("trace_miner", _trace_miner()),
        value_priority=overrides.get("value_priority", _value_priority()),
        target_cards=overrides.get("target_cards", TARGETS),
        paths=_paths(),
    )


def test_current_like_topdeck_rows_are_diagnostic_only_and_keep_607():
    payload = _build()

    assert payload["status"] == "topdeck_forced_access_diagnostic_ready_no_natural_gate_keep_607"
    assert payload["summary"]["candidate_count"] == 5
    assert payload["summary"]["diagnostic_ready_count"] == 5
    assert payload["summary"]["natural_gate_ready_count"] == 0
    assert payload["summary"]["safe_cut_ready_count"] == 0
    assert payload["summary"]["deck_607_mutated"] is False
    assert payload["decision"]["allow_deck_mutation_now"] is False
    assert payload["decision"]["promotion_allowed"] is False


def test_penance_is_first_learning_priority_due_direct_hand_to_top_source():
    payload = _build()
    first = payload["candidates"][0]

    assert first["card_name"] == "Penance"
    assert first["external_evidence"]["source"] == "Card Kingdom Lorehold synergy review"
    assert first["external_evidence"]["signal"] == "direct_hand_to_top_setup"
    assert first["decision"] == "forced_access_diagnostic_ready_only"


def test_natural_gate_ready_row_still_does_not_auto_promote_or_mutate_deck():
    payload = _build(hypothesis_queue=_hypothesis_queue(ready_card="Galvanoth"))
    by_card = {row["card_name"]: row for row in payload["candidates"]}

    assert by_card["Galvanoth"]["safe_cut_ready"] is True
    assert by_card["Galvanoth"]["natural_gate_allowed_now"] is False
    assert by_card["Galvanoth"]["deck_action_allowed_now"] is False
    assert payload["decision"]["allow_deck_mutation_now"] is False
    assert payload["decision"]["promotion_allowed"] is False


def test_missing_preflight_floors_blocks_diagnostic_completeness():
    payload = _build(preflight=_preflight(include_floors=False))

    assert payload["status"] == "topdeck_forced_access_inputs_missing_keep_607"
    assert payload["summary"]["diagnostic_ready_count"] == 0
    assert "preflight:strategic_floors_from_607" in payload["summary"]["missing_inputs"]
    assert "missing_607_miracle_access_floors" in payload["summary"]["blocker_counts"]


def test_markdown_surfaces_read_only_boundary_and_sources():
    markdown = audit.render_markdown(_build())

    assert "- postgres_writes: `false`" in markdown
    assert "- deck_607_mutated: `false`" in markdown
    assert "https://edhrec.com/commanders/lorehold-the-historian" in markdown
    assert "https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/" in markdown
    assert "allow_deck_mutation_now: `false`" in markdown
