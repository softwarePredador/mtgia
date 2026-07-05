from pathlib import Path

import lorehold_entreat_rule_package_preapply as package


def test_entreat_proposal_is_auto_after_native_x_miracle_runtime_exists() -> None:
    proposal = package.entreat_proposal()

    assert proposal["card_name"] == "Entreat the Angels"
    assert proposal["review_status"] == "verified"
    assert proposal["execution_status"] == "auto"
    assert proposal["shadow_handling"] == "preserve_existing_rows"
    assert proposal["effect_json"]["token_count_source"] == "x_value"
    assert proposal["effect_json"]["normal_mana_cost"] == "{X}{X}{W}{W}{W}"
    assert proposal["effect_json"]["native_miracle_cost"] == "{X}{W}{W}"
    assert proposal["effect_json"]["native_miracle_runtime_status"] == "runtime_executor_v1"


def test_write_outputs_generates_auto_sql_package_without_applying(tmp_path: Path) -> None:
    out_prefix = tmp_path / "pg472_lorehold_entreat_x_token_rule_20260705_current"
    payload = package.build_payload(out_prefix)
    package.write_outputs(payload, out_prefix)

    manifest = out_prefix.with_suffix(".json")
    markdown = out_prefix.with_suffix(".md")
    precheck = out_prefix.with_name(out_prefix.name + "_precheck.sql")
    apply = out_prefix.with_name(out_prefix.name + "_apply.sql")
    rollback = out_prefix.with_name(out_prefix.name + "_rollback.sql")
    postcheck = out_prefix.with_name(out_prefix.name + "_postcheck.sql")

    for path in [manifest, markdown, precheck, apply, rollback, postcheck]:
        assert path.exists()

    apply_sql = apply.read_text(encoding="utf-8")
    precheck_sql = precheck.read_text(encoding="utf-8")
    assert "'verified'" in apply_sql
    assert "'auto'" in apply_sql
    assert "postgres_writes_executed" in manifest.read_text(encoding="utf-8")
    assert "CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg472_lorehold_entreat_x_token_rule_20260705_current" in apply_sql
    assert "md5(coalesce(c.oracle_text, '')) = p.oracle_hash" in precheck_sql
    assert "auto_rows" in postcheck.read_text(encoding="utf-8")
    assert "runtime_executor_v1" in markdown.read_text(encoding="utf-8")
