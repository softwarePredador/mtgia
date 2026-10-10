#!/usr/bin/env python3
"""BT-GATE-001: contrato do inventário de skip (D-17).

Cada regra tem um teste: skip fora da allowlist é PARTIAL (3), allowlist exige
motivo, dono e prazo, entrada vencida não vale, relatório truncado é BLOCKED (2)
e BLOCKED nunca vira sucesso. O teste de `quality_gate.sh` roda o script real
contra `dart`/`flutter` falsos que gravam o reporter JSON.
"""

from __future__ import annotations

import importlib.util
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from datetime import date
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
TOOL_PATH = REPO_ROOT / "scripts" / "manaloom_gate_skip_inventory.py"
ALLOWLIST_PATH = REPO_ROOT / "server" / "config" / "gate_skip_allowlist.json"
QUALITY_GATE = REPO_ROOT / "scripts" / "quality_gate.sh"
SPEC = importlib.util.spec_from_file_location("manaloom_gate_skip_inventory", TOOL_PATH)
assert SPEC is not None and SPEC.loader is not None
tool = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(tool)

TODAY = date(2026, 10, 10)
LOTUS_SUITE = "/work/app/test/features/home/lotus_web_host_runtime_test.dart"
LOTUS_NAME = "Lotus browser host runtime is covered on Chrome"


def entry(**overrides):
    base = {
        "id": "x.skip",
        "kind": "test",
        "suite": "test/x_test.dart",
        "test_name": "x",
        "reason": "motivo",
        "owner": "dono",
        "added": "2026-10-01",
        "review_by": "2026-12-31",
    }
    base.update(overrides)
    return base


def report(*skips: tuple[str, str], truncated: bool = False, extra=()) -> str:
    """Reporter JSON do `dart test`: suite, testStart, testDone e done."""
    events = [{"type": "start", "protocolVersion": "0.1.1"}]
    for index, (suite, name) in enumerate(skips, start=1):
        events.append({"type": "suite", "suite": {"id": index, "path": suite}})
        events.append(
            {
                "type": "testStart",
                "test": {
                    "id": 100 + index,
                    "name": name,
                    "suiteID": index,
                    "metadata": {"skip": True, "skipReason": "declarado"},
                },
            }
        )
        events.append(
            {"type": "testDone", "testID": 100 + index, "result": "success", "skipped": True, "hidden": False}
        )
    events.extend(extra)
    if not truncated:
        events.append({"type": "done", "success": True})
    return "\n".join(json.dumps(event) for event in events) + "\n"


class SkipInventoryTest(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="manaloom-skip-inventory.")
        self.addCleanup(temporary.cleanup)
        self.work = Path(temporary.name)

    def write(self, name: str, text: str) -> Path:
        path = self.work / name
        path.write_text(text, encoding="utf-8")
        return path

    def allowlist(self, *entries) -> Path:
        return self.write(
            "allow.json",
            json.dumps({"schema": tool.SCHEMA, "entries": list(entries)}),
        )

    def cli(self, *args: str):
        return subprocess.run(
            ["python3", str(TOOL_PATH), *args], text=True, capture_output=True
        )

    # --- allowlist --------------------------------------------------------

    def test_repository_allowlist_is_valid_and_documents_the_flutter_skip(self) -> None:
        active = tool.load_allowlist(ALLOWLIST_PATH, TODAY)
        ids = {item["id"]: item for item in active}
        lotus = ids["flutter.lotus_web_host_runtime_vm_stub"]
        self.assertEqual(lotus["test_name"], LOTUS_NAME)
        self.assertTrue(lotus["reason"] and lotus["owner"] and lotus["review_by"])
        # O arquivo que justifica o skip existe e é de fato o stub da VM.
        stub = REPO_ROOT / "app/test/features/home/lotus_web_host_runtime_test_stub.dart"
        self.assertIn(LOTUS_NAME, stub.read_text(encoding="utf-8"))
        self.assertIn("skip:", stub.read_text(encoding="utf-8"))

    def test_entry_without_reason_owner_or_deadline_is_rejected(self) -> None:
        for field in ("reason", "owner", "review_by", "added", "id", "test_name", "suite"):
            with self.subTest(field=field):
                bad = entry()
                bad.pop(field)
                with self.assertRaises(tool.InventoryError):
                    tool.load_allowlist(self.allowlist(bad), TODAY)
        with self.assertRaises(tool.InventoryError):
            tool.load_allowlist(self.allowlist(entry(reason="   ")), TODAY)

    def test_wrong_schema_duplicate_id_and_bad_dates_are_rejected(self) -> None:
        wrong = self.write("wrong.json", json.dumps({"schema": "x", "entries": []}))
        with self.assertRaises(tool.InventoryError):
            tool.load_allowlist(wrong, TODAY)
        with self.assertRaises(tool.InventoryError):
            tool.load_allowlist(self.allowlist(entry(), entry()), TODAY)
        with self.assertRaises(tool.InventoryError):
            tool.load_allowlist(self.allowlist(entry(review_by="amanhã")), TODAY)
        with self.assertRaises(tool.InventoryError):
            tool.load_allowlist(self.allowlist(entry(review_by="2026-09-01")), TODAY)
        with self.assertRaises(tool.InventoryError):
            tool.load_allowlist(self.write("broken.json", "{"), TODAY)

    def test_expired_entry_no_longer_covers_the_skip(self) -> None:
        path = self.allowlist(entry(review_by="2026-10-09"))
        self.assertEqual(tool.load_allowlist(path, TODAY), [])
        skips = tool.skipped_tests(self.write("r.json", report(("/w/test/x_test.dart", "x"))))
        result = tool.classify_tests(skips, tool.load_allowlist(path, TODAY))
        self.assertEqual(result["status"], "PARTIAL")

    # --- skip de teste ----------------------------------------------------

    def test_skip_outside_the_allowlist_is_partial_with_exit_3(self) -> None:
        json_file = self.write("r.json", report(("/w/test/x_test.dart", "outro teste")))
        result = self.cli(
            "test-report", "--json", str(json_file),
            "--allowlist", str(self.allowlist(entry())), "--today", "2026-10-10",
        )
        self.assertEqual(result.returncode, 3)
        self.assertIn("unlisted=1", result.stdout)
        self.assertIn("UNLISTED", result.stderr)

    def test_skip_in_the_allowlist_passes_and_is_still_inventoried(self) -> None:
        json_file = self.write("r.json", report(("/w/test/x_test.dart", "x")))
        out = self.work / "inventory.json"
        result = self.cli(
            "test-report", "--json", str(json_file), "--out", str(out),
            "--allowlist", str(self.allowlist(entry())), "--today", "2026-10-10",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("skipped=1 allowlisted=1 unlisted=0", result.stdout)
        inventory = json.loads(out.read_text(encoding="utf-8"))
        self.assertEqual(inventory["items"][0]["owner"], "dono")
        self.assertEqual(inventory["items"][0]["allowlist_id"], "x.skip")

    def test_allowlist_matches_suite_and_name_exactly(self) -> None:
        allow = tool.load_allowlist(self.allowlist(entry()), TODAY)
        wrong_suite = tool.classify_tests([{"suite": "/w/test/other_test.dart", "test_name": "x", "reason": ""}], allow)
        wrong_name = tool.classify_tests([{"suite": "/w/test/x_test.dart", "test_name": "x2", "reason": ""}], allow)
        self.assertEqual(wrong_suite["status"], "PARTIAL")
        self.assertEqual(wrong_name["status"], "PARTIAL")

    def test_real_flutter_skip_is_covered_only_by_its_allowlist_entry(self) -> None:
        json_file = self.write("r.json", report((LOTUS_SUITE, LOTUS_NAME)))
        covered = self.cli("test-report", "--json", str(json_file), "--today", "2026-10-10")
        self.assertEqual(covered.returncode, 0, covered.stderr)
        empty = self.allowlist()
        uncovered = self.cli(
            "test-report", "--json", str(json_file), "--allowlist", str(empty), "--today", "2026-10-10"
        )
        self.assertEqual(uncovered.returncode, 3)

    def test_hidden_loading_pseudo_tests_are_not_counted(self) -> None:
        extra = [
            {"type": "testStart", "test": {"id": 9, "name": "loading x", "suiteID": 1, "metadata": {}}},
            {"type": "testDone", "testID": 9, "result": "success", "skipped": True, "hidden": True},
        ]
        json_file = self.write("r.json", report(("/w/test/x_test.dart", "x"), extra=extra))
        skips = tool.skipped_tests(json_file)
        self.assertEqual([item["test_name"] for item in skips], ["x"])

    def test_run_without_skips_is_pass(self) -> None:
        json_file = self.write("r.json", report())
        result = self.cli("test-report", "--json", str(json_file), "--today", "2026-10-10")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("skipped=0", result.stdout)

    # --- BLOCKED nunca vira sucesso --------------------------------------

    def test_missing_empty_or_truncated_report_is_blocked_not_pass(self) -> None:
        cases = {
            "missing": self.work / "does-not-exist.json",
            "empty": self.write("empty.json", ""),
            "truncated": self.write("trunc.json", report(truncated=True)),
            "garbage": self.write("garbage.json", "not json\n"),
        }
        for name, path in cases.items():
            with self.subTest(name=name):
                result = self.cli("test-report", "--json", str(path), "--today", "2026-10-10")
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertIn("BLOCKED", result.stderr)

    def test_invalid_allowlist_is_blocked(self) -> None:
        json_file = self.write("r.json", report())
        broken = self.write("broken.json", "{")
        result = self.cli("test-report", "--json", str(json_file), "--allowlist", str(broken))
        self.assertEqual(result.returncode, 2)

    # --- marcadores textuais ---------------------------------------------

    def scan(self, text: str, *entries):
        allow = tool.load_allowlist(self.allowlist(*entries), TODAY)
        return tool.scan_log_text(text, allow)

    def test_skip_marker_in_a_log_is_partial(self) -> None:
        for line in (
            "SKIP: leitura PostgreSQL requer env",
            "- SKIP: Optimizer mana floor - runner PostgreSQL",
            "PARTIAL: gate estrito incompleto",
            "  SKIPPED: etapa opcional",
            "PARTIAL_DIAGNOSTIC: skips inventariados",
        ):
            with self.subTest(line=line):
                self.assertEqual(self.scan(line + "\n")["status"], "PARTIAL")

    def test_prose_and_test_names_are_not_skip_markers(self) -> None:
        text = "\n".join(
            [
                "00:01 +3: reduced motion skips the home entrance animation",
                "Nenhum teste foi skipped aqui, só prosa",
                "ok SKIP no meio da linha",
            ]
        )
        self.assertEqual(self.scan(text)["status"], "PASS")

    def test_log_line_allowlist_covers_a_known_marker(self) -> None:
        line = "SKIP: toolchain opcional do iOS"
        allowed = entry(id="log.ios", kind="log_line", pattern="toolchain opcional do iOS")
        for key in ("suite", "test_name"):
            allowed.pop(key)
        self.assertEqual(self.scan(line, allowed)["status"], "PASS")
        self.assertEqual(self.scan("SKIP: outra coisa", allowed)["status"], "PARTIAL")

    def test_blocked_marker_is_blocked_and_beats_partial(self) -> None:
        self.assertEqual(self.scan("BLOCKED: toolchain ausente\n")["status"], "BLOCKED")
        self.assertEqual(self.scan("SKIP: x\nBLOCKED: y\n")["status"], "BLOCKED")
        result = self.cli_scan("BLOCKED: x\n")
        self.assertEqual(result.returncode, 2)

    def cli_scan(self, text: str):
        return self.cli("scan-log", "--log", str(self.write("step.log", text)), "--today", "2026-10-10")

    def test_test_counter_without_inventory_is_partial(self) -> None:
        for text in (
            "00:12 +34 ~2: All other tests passed!\n",
            "\r00:03 +10 ~1: some test\r",
            "OK (skipped=3)\n",
            "5 passed, 2 skipped in 1.2s\n",
            "All other tests passed!\n",
        ):
            with self.subTest(text=text):
                result = self.scan(text)
                self.assertEqual(result["status"], "PARTIAL")
                self.assertEqual(result["findings"][0]["kind"], "uninventoried_test_skip")

    def test_test_counter_with_a_clean_inventory_passes(self) -> None:
        text = (
            "00:12 +34 ~1: All other tests passed!\n"
            "GATE_SKIP_INVENTORY label=flutter-full skipped=1 allowlisted=1 unlisted=0\n"
        )
        self.assertEqual(self.scan(text)["status"], "PASS")

    def test_inventory_with_unlisted_skip_is_partial_even_with_counter(self) -> None:
        text = (
            "00:12 +34 ~1: All other tests passed!\n"
            "GATE_SKIP_INVENTORY label=flutter-full skipped=1 allowlisted=0 unlisted=1\n"
        )
        result = self.scan(text)
        self.assertEqual(result["status"], "PARTIAL")
        self.assertIn("unlisted_test_skip", [item["kind"] for item in result["findings"]])

    def test_scan_exit_codes_through_the_cli(self) -> None:
        self.assertEqual(self.cli_scan("tudo certo\n").returncode, 0)
        self.assertEqual(self.cli_scan("SKIP: x\n").returncode, 3)
        self.assertEqual(self.cli_scan("BLOCKED: x\n").returncode, 2)
        missing = self.cli("scan-log", "--log", str(self.work / "nada.log"))
        self.assertEqual(missing.returncode, 2)


class QualityGateSkipWiringTest(unittest.TestCase):
    """O `quality_gate.sh full` real, com Flutter/Dart falsos que gravam o JSON."""

    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="manaloom-quality-skip.")
        self.addCleanup(temporary.cleanup)
        self.work = Path(temporary.name)
        self.bin = self.work / "bin"
        self.bin.mkdir()

    def fake_runner(self, name: str, report_text: str, exit_code: int = 0, console: str = "") -> Path:
        report = self.work / f"{name}.report.json"
        report.write_text(report_text, encoding="utf-8")
        script = self.bin / name
        script.write_text(
            "#!/usr/bin/env bash\n"
            'if [[ "${1:-}" == "--version" ]]; then echo "Dart SDK version: 3.12.2"; exit 0; fi\n'
            'out=""\n'
            'while (($#)); do\n'
            '  if [[ "$1" == "--file-reporter" ]]; then out="${2#json:}"; shift; fi\n'
            "  shift\n"
            "done\n"
            f'[[ -n "$out" ]] && cp {report} "$out"\n'
            f"printf '%s\\n' {json.dumps(console)}\n"
            f"exit {exit_code}\n",
            encoding="utf-8",
        )
        script.chmod(0o755)
        return script

    def run_wiring(self, snippet: str, *, allowlist: Path | None = None):
        """Carrega só as funções de teste do quality_gate.sh e chama o trecho."""
        source = QUALITY_GATE.read_text(encoding="utf-8")
        start = source.index("SKIP_INVENTORY_TOOL=")
        end = source.index("run_backend_quick() {")
        helpers = source[start:end]
        flutter_start = source.index("run_flutter_tests_with_proof() {")
        flutter_end = source.index("run_frontend_full() {")
        script = (
            "set -euo pipefail\n"
            f'ROOT_DIR="{REPO_ROOT}"\n'
            f'TEST_CONCURRENCY=1\nFLUTTER_TEST_TIMEOUT_SECONDS=30\n'
            f'FLUTTER_BIN="{self.bin}/flutter"\n'
            + helpers
            + source[flutter_start:flutter_end]
            + snippet
            + "\n"
        )
        env = os.environ.copy()
        env["PATH"] = f"{self.bin}:{env['PATH']}"
        env["MANALOOM_GATE_SKIP_ALLOWLIST"] = str(allowlist or ALLOWLIST_PATH)
        return subprocess.run(["bash", "-c", script], text=True, capture_output=True, env=env, cwd=self.work)

    def test_flutter_all_other_tests_passed_is_no_longer_enough(self) -> None:
        self.fake_runner(
            "flutter",
            report(("/w/app/test/unknown_test.dart", "teste novo pulado")),
            console="00:09 +100 ~1: All other tests passed!",
        )
        result = self.run_wiring("run_flutter_tests_with_proof")
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertIn("PARTIAL", result.stderr)

    def test_flutter_known_skip_with_allowlist_entry_passes(self) -> None:
        self.fake_runner(
            "flutter",
            report((LOTUS_SUITE, LOTUS_NAME)),
            console="00:09 +100 ~1: All other tests passed!",
        )
        result = self.run_wiring("run_flutter_tests_with_proof")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("allowlisted=1 unlisted=0", result.stdout)

    def test_flutter_without_a_reporter_file_is_blocked(self) -> None:
        # Runner que declara sucesso mas não grava o JSON: BLOCKED, nunca PASS.
        script = self.bin / "flutter"
        script.write_text("#!/usr/bin/env bash\necho 'All tests passed!'\nexit 0\n", encoding="utf-8")
        script.chmod(0o755)
        result = self.run_wiring("run_flutter_tests_with_proof")
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("BLOCKED", result.stderr)

    def test_failing_tests_keep_their_own_exit_code(self) -> None:
        self.fake_runner("flutter", report(), exit_code=1, console="Some tests failed.")
        result = self.run_wiring("run_flutter_tests_with_proof")
        self.assertEqual(result.returncode, 1)

    def test_dart_test_wrapper_applies_the_same_rule(self) -> None:
        self.fake_runner("dart", report(("/w/server/test/a_test.dart", "pulado")))
        partial = self.run_wiring('run_inventoried_test backend dart test test/a_test.dart')
        self.assertEqual(partial.returncode, 3, partial.stdout + partial.stderr)
        self.fake_runner("dart", report())
        clean = self.run_wiring('run_inventoried_test backend dart test test/a_test.dart')
        self.assertEqual(clean.returncode, 0, clean.stdout + clean.stderr)

    def test_every_test_runner_in_quality_gate_goes_through_the_inventory(self) -> None:
        import re

        source = QUALITY_GATE.read_text(encoding="utf-8").replace("\\\n", " ")
        runner = re.compile(r'\bdart test\b|\bflutter test\b|"\$FLUTTER_BIN" test|"\$DART_BIN" test')
        seen = 0
        for line in source.splitlines():
            stripped = line.strip()
            if stripped.startswith(("#", "./scripts", "echo")) or "echo " in stripped:
                continue
            if not runner.search(stripped):
                continue
            seen += 1
            self.assertTrue(
                "run_inventoried_test" in stripped or "--file-reporter" in stripped,
                f"quality_gate.sh roda teste fora do inventário de skip: {stripped}",
            )
        self.assertGreaterEqual(seen, 7)


if __name__ == "__main__":
    unittest.main(verbosity=2)
