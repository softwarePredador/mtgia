import xmage_execution_contract_audit as audit


def test_current_xmage_execution_contract_is_aligned():
    report = audit.build_report()

    assert report["status"] == "pass", report["checks"]
    assert report["summary"]["failed"] == 0
    checks = {check["name"]: check for check in report["checks"]}
    assert checks["server.no_silent_configuration_fallback"]["status"] == "pass"
    assert checks["deployment.coordinated_sidecars"]["status"] == "pass"
    assert checks["forge.reproducible_image"]["status"] == "pass"
    assert checks["battle.resumable_async_runner"]["status"] == "pass"
    assert checks["coverage.source_catalog_reconciliation"]["status"] == "pass"
    assert checks["server.positive_battle_evidence"]["status"] == "pass"
