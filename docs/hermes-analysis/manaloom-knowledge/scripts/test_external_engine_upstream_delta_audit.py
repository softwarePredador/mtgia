#!/usr/bin/env python3
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import external_engine_upstream_delta_audit as audit


SCRIPT_DIR = Path(__file__).resolve().parent
FIXTURE_DIR = SCRIPT_DIR / "fixtures/external_engine_upstream_delta"


class ExternalEngineUpstreamDeltaAuditTests(unittest.TestCase):
    def test_current_local_pin_contract_is_aligned_without_network(self) -> None:
        with mock.patch.object(
            audit,
            "fetch_official_compare",
            side_effect=AssertionError("network must not be used by local-only audit"),
        ):
            report = audit.build_report(local_only=True)

        self.assertEqual(report["status"], "pass", report["errors"])
        self.assertFalse(report["review_required"])
        self.assertEqual(report["summary"]["pin_contract_failures"], 0)
        self.assertEqual(
            {engine["engine"] for engine in report["engines"]},
            {"xmage", "forge"},
        )
        self.assertTrue(report["safety"]["read_only"])
        self.assertEqual(report["safety"]["mutations_performed"], [])

    def test_fixture_compare_marks_review_and_classifies_cards_and_fixtures(self) -> None:
        report = audit.build_report(
            compare_fetcher=audit.fixture_compare_fetcher(FIXTURE_DIR),
        )

        self.assertEqual(report["status"], "review_required", report["errors"])
        self.assertTrue(report["review_required"])
        self.assertEqual(report["summary"]["engines_requiring_review"], 2)
        self.assertEqual(report["summary"]["candidate_cards"], 2)
        self.assertGreaterEqual(report["summary"]["candidate_fixtures"], 4)
        engines = {engine["engine"]: engine for engine in report["engines"]}
        self.assertEqual(engines["xmage"]["compare"]["ahead_by"], 3)
        self.assertEqual(
            engines["xmage"]["classification_summary"]["commits"],
            {"card_additions": 1, "engine_changes": 1, "rules_fixes": 1},
        )
        self.assertEqual(
            engines["forge"]["candidate_cards"][0]["card_name"],
            "Clockwork Example",
        )
        self.assertEqual(
            engines["forge"]["candidate_cards"][0]["name_confidence"],
            "exact",
        )
        self.assertTrue(
            any(
                fixture["kind"] == "changed_upstream_test_or_fixture"
                for fixture in engines["xmage"]["candidate_fixtures"]
            )
        )

    def test_pin_divergence_fails_before_compare_fetch(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self._write_minimal_pin_contract(repo_root)
            forge_dockerfile = repo_root / "services/forge-sidecar/Dockerfile"
            forge_dockerfile.write_text(
                "ARG FORGE_COMMIT=" + "f" * 40 + "\n",
                encoding="utf-8",
            )
            fetcher = mock.Mock(side_effect=AssertionError("compare must not run"))

            report = audit.build_report(repo_root, compare_fetcher=fetcher)

        self.assertEqual(report["status"], "fail")
        self.assertEqual(report["summary"]["pin_contract_failures"], 1)
        self.assertFalse(fetcher.called)
        forge = next(engine for engine in report["engines"] if engine["engine"] == "forge")
        self.assertEqual(forge["pin_consistency"]["status"], "fail")
        self.assertIn(
            "mirror_diverges_from_canonical_pin",
            forge["pin_consistency"]["mirrors"][0]["detail"],
        )

    def test_upstream_failure_is_unknown_and_never_claims_up_to_date(self) -> None:
        def unavailable(spec: audit.EngineSpec, pin: str) -> dict:
            raise audit.CompareFetchError("rate limited for test")

        report = audit.build_report(compare_fetcher=unavailable)

        self.assertEqual(report["status"], "fail")
        self.assertFalse(report["review_required"])
        self.assertEqual(
            {engine["upstream"]["status"] for engine in report["engines"]},
            {"unknown"},
        )

    def test_official_compare_fetcher_paginates_commits_without_network(self) -> None:
        spec = audit.ENGINE_SPECS[0]
        pin = "a" * 40
        first = {
            "status": "ahead",
            "ahead_by": 101,
            "behind_by": 0,
            "total_commits": 101,
            "base_commit": {"sha": pin},
            "commits": [{"sha": f"{index:040x}", "commit": {}} for index in range(100)],
            "files": [],
        }
        second = {
            **first,
            "commits": [{"sha": "f" * 40, "commit": {}}],
            "files": [],
        }
        with mock.patch.object(audit, "_github_json", side_effect=[first, second]) as request:
            payload = audit.fetch_official_compare(spec, pin, timeout=1)

        self.assertEqual(len(payload["commits"]), 101)
        self.assertEqual(payload["_audit_pagination"]["pages_fetched"], 2)
        self.assertFalse(payload["_audit_pagination"]["commits_truncated"])
        self.assertIn("page=1", request.call_args_list[0].args[0])
        self.assertIn("page=2", request.call_args_list[1].args[0])

    @staticmethod
    def _write_minimal_pin_contract(repo_root: Path) -> None:
        xmage_pin = "a" * 40
        forge_pin = "b" * 40
        files = {
            "services/xmage-sidecar/XMAGE_COMMIT": xmage_pin + "\n",
            "services/forge-sidecar/FORGE_COMMIT": forge_pin + "\n",
            "services/xmage-sidecar/Dockerfile": f"ARG XMAGE_COMMIT={xmage_pin}\n",
            "services/forge-sidecar/Dockerfile": f"ARG FORGE_COMMIT={forge_pin}\n",
            "services/xmage-sidecar/src/main/java/com/manaloom/xmage/SidecarMain.java": (
                f'static final String XMAGE_COMMIT = "{xmage_pin}";\n'
            ),
            "docs/hermes-analysis/manaloom-knowledge/scripts/xmage_execution_contract_audit.py": (
                f'XMAGE_PIN = "{xmage_pin}"\nFORGE_PIN = "{forge_pin}"\n'
            ),
            "docs/hermes-analysis/manaloom-knowledge/scripts/external_card_rule_reference_harvester.py": (
                'XMAGE_PIN = canonical_engine_pin("services/xmage-sidecar/XMAGE_COMMIT")\n'
                'FORGE_PIN = canonical_engine_pin("services/forge-sidecar/FORGE_COMMIT")\n'
                'local_root_pin_contract = validate_xmage_local_root_pin(xmage_root)\n'
                'STATE = {"xmage_local_root_pin_contract": local_root_pin_contract}\n'
                'POLICY = {"upstream_head_allowed": False}\n'
            ),
        }
        for relative_path, content in files.items():
            path = repo_root / relative_path
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")


if __name__ == "__main__":
    unittest.main()
