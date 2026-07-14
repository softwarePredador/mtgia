import xmage_execution_contract_audit as audit


def test_current_xmage_execution_contract_is_aligned():
    report = audit.build_report()

    assert report["status"] == "pass", report["checks"]
    assert report["summary"]["failed"] == 0
    checks = {check["name"]: check for check in report["checks"]}
    assert checks["server.no_silent_configuration_fallback"]["status"] == "pass"
