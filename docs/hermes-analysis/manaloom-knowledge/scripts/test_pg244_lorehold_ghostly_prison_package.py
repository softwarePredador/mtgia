import json
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"


def test_pg244_manifest_points_to_guarded_package_files():
    manifest_path = REPORT_DIR / "pg244_lorehold_ghostly_prison_deck_swap_manifest.json"
    manifest = json.loads(manifest_path.read_text())

    assert manifest["deploy_id"] == "PG244"
    assert manifest["status"] == "prepared_read_only_pg_already_promoted_no_apply"
    assert manifest["precheck_result"]["ready_to_apply"] is False
    assert manifest["precheck_result"]["result"] == "postgres_already_has_target_swap"
    assert manifest["sync_status"] == "dry_run_blocked_by_postgres_disk_full"
    assert manifest["target"]["hermes_deck_id"] == 6
    assert manifest["target"]["pg_deck_id"] == "528c877f-f829-4207-95e6-73981776c323"

    for key in ("precheck", "apply", "rollback", "postcheck", "package"):
        file_name = Path(manifest["files"][key]).name
        assert (REPORT_DIR / file_name).exists(), key


def test_pg244_sql_has_exact_cards_guards_backup_and_rule_hash():
    apply_sql = (REPORT_DIR / "pg244_lorehold_ghostly_prison_deck_swap_apply.sql").read_text()
    precheck_sql = (REPORT_DIR / "pg244_lorehold_ghostly_prison_deck_swap_precheck.sql").read_text()
    postcheck_sql = (REPORT_DIR / "pg244_lorehold_ghostly_prison_deck_swap_postcheck.sql").read_text()

    required = [
        "Promise of Loyalty",
        "Ghostly Prison",
        "pg244_lorehold_ghostly_prison_deck_swap_20260627",
        "battle_rule_v1:99151859bece89ba3ead032e05b1f65a",
        "5725b39ca4bb7c5e8e4bebf0d246be13",
        "attack_tax_per_creature",
        "ready_to_apply",
    ]

    combined = "\n".join([apply_sql, precheck_sql, postcheck_sql])
    for token in required:
        assert token in combined

    assert "RAISE EXCEPTION 'PG244 deck shape guard failed" in apply_sql
    assert "RAISE EXCEPTION 'PG244 Ghostly Prison pre-existence guard failed" in apply_sql
    assert "postcheck_passed" in postcheck_sql
