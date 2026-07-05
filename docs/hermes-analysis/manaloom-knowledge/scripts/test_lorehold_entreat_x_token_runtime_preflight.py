import json
import sqlite3
from pathlib import Path

import lorehold_entreat_x_token_runtime_preflight as preflight


def make_db(path: Path) -> None:
    with sqlite3.connect(path) as conn:
        conn.executescript(
            """
            CREATE TABLE battle_card_rules (
              normalized_name TEXT,
              card_name TEXT,
              logical_rule_key TEXT,
              effect_json TEXT,
              review_status TEXT,
              execution_status TEXT,
              source TEXT
            );
            """
        )


def test_build_payload_marks_x_token_runtime_ready_but_not_promotable(tmp_path: Path) -> None:
    db_path = tmp_path / "knowledge.db"
    make_db(db_path)
    runtime = tmp_path / "battle.py"
    runtime.write_text(
        """
        def x_value_from_effect_context(effect_data): return 3
        def effect_uses_x_cast_value(effect_data):
            return str(effect_data.get("token_count_source") or "").strip().lower() == "x_value"
        uses_x_cast_value = effect_uses_x_cast_value(effect_data)
        def native_miracle_cost_for_effect(effect_data): return "{X}{W}{W}"
        def miracle_cast_plan_for_card(player, card, effect_data):
            return {"alternative_cost_kind": "native_miracle"}
        def token_count_for_effect(player, effect_data):
            if effect_data.get("token_count_source") == "x_value":
                token_count_per_x = 1
                return x_value_from_effect_context(effect_data) * token_count_per_x
        emit_replay_event("tokens_created", token_count_source=effect_data.get("token_count_source"), x_value=x_value_from_effect_context(effect_data))
        """,
        encoding="utf-8",
    )
    test_path = tmp_path / "test_runtime.py"
    test_path.write_text(
        """
        def test_x_create_creature_tokens_spell_uses_cast_context_x_value():
            effect = {"_cast_context": {"x_value": 3}, "token_flying": True}
            card = "Entreat the Angels"
            token = "Angel Token"
            assert "tokens_requested"
            assert "token_count_source"
        def test_x_create_creature_tokens_spell_cast_plan_uses_xx_cost():
            assert True
        def test_native_x_miracle_create_creature_tokens_uses_xww_cost():
            assert True
        """,
        encoding="utf-8",
    )
    contract_report = tmp_path / "contract.json"
    contract_report.write_text(
        json.dumps(
            {
                "status": "runtime_contracts_drafted_no_battle_ready_keep_607",
                "summary": {"best_first_runtime_contract": "Entreat the Angels"},
            }
        ),
        encoding="utf-8",
    )

    payload = preflight.build_payload(
        db_path=db_path,
        runtime_path=runtime,
        test_path=test_path,
        contract_report_path=contract_report,
    )

    assert payload["status"] == "entreat_x_token_runtime_primitive_ready_rule_still_blocked_keep_607"
    assert payload["summary"]["runtime_primitive_ready"] is True
    assert payload["summary"]["entreat_active_rule_count"] == 0
    assert payload["summary"]["entreat_active_rule_ready"] is False
    assert payload["summary"]["battle_ready_now_count"] == 0
    assert payload["decision"]["promotion_allowed"] is False
    assert payload["summary"]["recommended_next_action"] == "apply_entreat_rule_only_after_pg_precheck_then_run_607_battle_gate"


def test_build_payload_marks_runtime_and_rule_ready_but_cut_blocked(tmp_path: Path) -> None:
    db_path = tmp_path / "knowledge.db"
    make_db(db_path)
    with sqlite3.connect(db_path) as conn:
        conn.execute(
            """
            INSERT INTO battle_card_rules (
              normalized_name, card_name, logical_rule_key, effect_json,
              review_status, execution_status, source
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            [
                "entreat the angels",
                "Entreat the Angels",
                "battle_rule_v1:entreat",
                json.dumps({"battle_model_scope": "xmage_x_create_creature_tokens_spell_v1"}),
                "verified",
                "auto",
                "curated",
            ],
        )
    runtime = tmp_path / "battle.py"
    runtime.write_text(
        """
        def x_value_from_effect_context(effect_data): return 3
        def effect_uses_x_cast_value(effect_data):
            return str(effect_data.get("token_count_source") or "").strip().lower() == "x_value"
        uses_x_cast_value = effect_uses_x_cast_value(effect_data)
        def native_miracle_cost_for_effect(effect_data): return "{X}{W}{W}"
        def miracle_cast_plan_for_card(player, card, effect_data):
            return {"alternative_cost_kind": "native_miracle"}
        token_count_per_x = 1
        emit_replay_event("tokens_created", token_count_source=effect_data.get("token_count_source"), x_value=x_value_from_effect_context(effect_data))
        """,
        encoding="utf-8",
    )
    test_path = tmp_path / "test_runtime.py"
    test_path.write_text(
        """
        def test_x_create_creature_tokens_spell_uses_cast_context_x_value():
            effect = {"_cast_context": {"x_value": 3}, "token_flying": True}
            card = "Entreat the Angels"
            token = "Angel Token"
            assert "tokens_requested"
            assert "token_count_source"
        def test_x_create_creature_tokens_spell_cast_plan_uses_xx_cost():
            assert True
        def test_native_x_miracle_create_creature_tokens_uses_xww_cost():
            assert True
        """,
        encoding="utf-8",
    )

    payload = preflight.build_payload(
        db_path=db_path,
        runtime_path=runtime,
        test_path=test_path,
        contract_report_path=tmp_path / "missing_contract.json",
    )

    assert payload["status"] == "entreat_x_token_runtime_and_rule_ready_cut_still_blocked_keep_607"
    assert payload["summary"]["runtime_primitive_ready"] is True
    assert payload["summary"]["entreat_active_rule_count"] == 1
    assert payload["summary"]["entreat_active_rule_ready"] is True
    assert payload["summary"]["battle_ready_now_count"] == 0
    assert payload["summary"]["recommended_next_action"] == "mine_entreat_named_same_lane_safe_cut_before_matrix_or_battle"


def test_build_payload_marks_incomplete_without_focused_test(tmp_path: Path) -> None:
    db_path = tmp_path / "knowledge.db"
    make_db(db_path)
    runtime = tmp_path / "battle.py"
    runtime.write_text("def x_value_from_effect_context(effect_data): pass", encoding="utf-8")
    missing_test = tmp_path / "missing_test.py"
    missing_test.write_text("", encoding="utf-8")

    payload = preflight.build_payload(
        db_path=db_path,
        runtime_path=runtime,
        test_path=missing_test,
        contract_report_path=tmp_path / "missing_contract.json",
    )

    assert payload["status"] == "entreat_x_token_runtime_primitive_incomplete_keep_607"
    assert payload["summary"]["runtime_primitive_ready"] is False
    assert payload["summary"]["entreat_active_rule_ready"] is False
    assert payload["decision"]["keep_607_as_protected_baseline"] is True
