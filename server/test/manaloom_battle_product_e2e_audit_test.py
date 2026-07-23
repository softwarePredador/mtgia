from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
AUDIT_PATH = REPO_ROOT / "server" / "bin" / "manaloom_battle_product_e2e_audit.py"
SPEC = importlib.util.spec_from_file_location("manaloom_battle_product_e2e_audit", AUDIT_PATH)
assert SPEC is not None and SPEC.loader is not None
AUDIT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AUDIT)


class ManaLoomBattleProductE2EAuditTest(unittest.TestCase):
    def test_gate_topology_has_one_canonical_battle_gate(self) -> None:
        report = AUDIT.build_report()
        canonical = [
            row
            for row in report["gate_topology"]
            if row["classification"] == "canonical_battle_product_gate"
        ]

        self.assertEqual(report["status"], "pass")
        self.assertEqual(
            [row["path"] for row in canonical],
            ["scripts/manaloom_battle_product_gate.sh"],
        )
        self.assertEqual(
            report["gate_topology_counts"]["legacy_manual_live"],
            3,
        )

    def test_local_dispatchers_reference_the_canonical_gate(self) -> None:
        report = AUDIT.build_report()
        checks_by_path: dict[str, list[dict[str, object]]] = {}
        for check in report["checks"]:
            checks_by_path.setdefault(check["path"], []).append(check)

        for path in (
            "scripts/manaloom_local_ci.sh",
            "melos.yaml",
            "scripts/quality_gate.sh",
            "scripts/manaloom_e2e_suite.sh",
        ):
            self.assertIn(path, checks_by_path)
            self.assertTrue(
                all(check["status"] == "pass" for check in checks_by_path[path]),
                path,
            )

    def test_release_dispatcher_is_local_and_github_actions_is_absent(self) -> None:
        report = AUDIT.build_report()
        local_checks = [
            check
            for check in report["checks"]
            if check["path"] == "scripts/manaloom_local_ci.sh"
        ]
        self.assertGreaterEqual(len(local_checks), 2)
        self.assertTrue(
            all(check["status"] == "pass" for check in local_checks),
            local_checks,
        )

        local_ci = (REPO_ROOT / "scripts" / "manaloom_local_ci.sh").read_text(
            encoding="utf-8"
        )
        self.assertIn("bootstrap_pinned_xmage_maven.sh", local_ci)
        self.assertIn('"$ROOT_DIR/scripts/quality_gate.sh" battle', local_ci)
        self.assertFalse(
            (REPO_ROOT / ".github" / "workflows" / "manaloom-guardrails.yml").exists()
        )

    def test_mutating_battle_contract_is_isolated_and_not_a_static_skip(self) -> None:
        report = AUDIT.build_report()
        isolated = [
            row
            for row in report["gate_topology"]
            if row["classification"] == "isolated_mutating_contract"
        ]
        self.assertEqual(len(isolated), 1)
        self.assertEqual(
            isolated[0]["invocation"],
            "scripts/manaloom_battle_product_gate.sh --isolated-e2e",
        )
        self.assertIn("IPv4-loopback", isolated[0]["scope"])

        gate_source = (
            REPO_ROOT / "scripts" / "manaloom_battle_product_gate.sh"
        ).read_text(encoding="utf-8")
        static_start = gate_source.index("run_static_gate()")
        isolated_start = gate_source.index("run_isolated_e2e()")
        static_source = gate_source[static_start:isolated_start]
        isolated_source = gate_source[isolated_start:]
        self.assertNotIn("test/battle_product_e2e_test.dart", static_source)
        self.assertIn("test/battle_product_e2e_test.dart", isolated_source)
        self.assertIn("dart_frog build", isolated_source)
        self.assertIn("dart run build/bin/server.dart", isolated_source)
        self.assertIn("InternetAddress.loopbackIPv4", isolated_source)
        self.assertNotIn("dart_frog dev", isolated_source)
        self.assertIn("mutation_audit.json", isolated_source)

        test_source = (
            REPO_ROOT / "server" / "test" / "battle_product_e2e_test.dart"
        ).read_text(encoding="utf-8")
        self.assertIn("BATTLE_E2E_RUN_TOKEN", test_source)
        self.assertIn("BATTLE_E2E_DEFER_CLEANUP_TO_HARNESS", test_source)
        self.assertNotIn("test_battle_product_e2e_v1@example.com", test_source)

    def test_retired_legacy_surfaces_stay_absent(self) -> None:
        report = AUDIT.build_report()
        retired = report["retired_legacy_surfaces"]

        self.assertEqual(len(retired), 4)
        for row in retired:
            self.assertFalse((REPO_ROOT / row["path"]).exists(), row["path"])
            self.assertTrue(row["replacement"])
            self.assertTrue(row["reason"])

    def test_static_gate_restores_locked_dependencies_before_analysis(self) -> None:
        gate_source = (
            REPO_ROOT / "scripts" / "manaloom_battle_product_gate.sh"
        ).read_text(encoding="utf-8")
        static_start = gate_source.index("run_static_gate()")
        isolated_start = gate_source.index("run_isolated_e2e()")
        static_source = gate_source[static_start:isolated_start]

        pub_get = static_source.index("dart pub get --enforce-lockfile")
        analyze = static_source.index("dart analyze")
        self.assertLess(pub_get, analyze)

    def test_deploy_builds_include_the_local_lint_package(self) -> None:
        backend_docker = (REPO_ROOT / "server" / "Dockerfile").read_text(
            encoding="utf-8"
        )
        ops_docker = (
            REPO_ROOT / "server" / "Dockerfile.manaloom-ops"
        ).read_text(encoding="utf-8")
        backend_deploy = (
            REPO_ROOT / "scripts" / "manaloom_deploy_backend_image.sh"
        ).read_text(encoding="utf-8")
        ops_deploy = (
            REPO_ROOT / "scripts" / "manaloom_deploy_ops_image.sh"
        ).read_text(encoding="utf-8")

        for dockerfile in (backend_docker, ops_docker):
            self.assertIn(
                "COPY tools/manaloom_lints /app/tools/manaloom_lints",
                dockerfile,
            )
            self.assertIn("server/pubspec.lock", dockerfile)
            self.assertIn("dart pub get --enforce-lockfile", dockerfile)

        self.assertIn(
            "git archive HEAD server tools/manaloom_lints",
            backend_deploy,
        )
        self.assertIn("require_clean_worktree", backend_deploy)
        self.assertGreaterEqual(
            backend_deploy.count("require_clean_worktree"),
            3,
        )
        self.assertIn("-f server/Dockerfile", backend_deploy)
        self.assertIn(
            "git archive HEAD server docs/hermes-analysis/manaloom-knowledge "
            "scripts/lib tools/manaloom_lints",
            ops_deploy,
        )
        self.assertIn("require_clean_worktree", ops_deploy)
        self.assertGreaterEqual(ops_deploy.count("require_clean_worktree"), 3)
        self.assertIn(
            "MANALOOM_CANONICAL_PG_DECK_ID=8938b746-1a9e-46ce-b0d9-c2ec932ddddd",
            ops_deploy,
        )
        self.assertIn(
            "MANALOOM_TARGET_PG_DECK_ID=8938b746-1a9e-46ce-b0d9-c2ec932ddddd",
            ops_deploy,
        )
        self.assertIn(
            "test -r /app/scripts/lib/manaloom_mutation_guard.sh",
            ops_deploy,
        )
        self.assertIn(
            "/app/docs/hermes-analysis/manaloom-knowledge/scripts/"
            "sync_pg_target_deck_to_hermes.py",
            ops_deploy,
        )
        self.assertIn(
            "/app/docs/hermes-analysis/manaloom-knowledge/scripts/"
            "battle_target_deck_identity_guard.py",
            ops_deploy,
        )
        self.assertIn("--protected-pg-deck-id", ops_deploy)
        self.assertIn("deploy_guard_$short_sha.json", ops_deploy)


if __name__ == "__main__":
    unittest.main()
