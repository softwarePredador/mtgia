#!/usr/bin/env python3
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import legacy_contamination_audit as audit


class LegacyContaminationAuditTests(unittest.TestCase):
    def test_unregistered_stale_sqlite_path_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            bad = root / "bad.py"
            bad.write_text('DB = SCRIPT_DIR / "knowledge.db"\n', encoding="utf-8")
            baseline = root / "baseline.json"
            baseline.write_text(
                json.dumps({"allowed_max_by_category_file": {}}),
                encoding="utf-8",
            )

            report = audit.build_report(roots=[root], baseline_path=baseline)

        self.assertEqual(report["status"], "fail")
        self.assertEqual(report["summary"]["excess_group_count"], 1)
        self.assertEqual(report["excess"][0]["category"], "stale_sqlite_path")

    def test_registered_legacy_count_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            allowed = root / "allowed.py"
            allowed.write_text('DB = SCRIPT_DIR / "knowledge.db"\n', encoding="utf-8")
            baseline = root / "baseline.json"
            baseline.write_text(
                json.dumps(
                    {
                        "allowed_max_by_category_file": {
                            "stale_sqlite_path": {str(allowed): 1}
                        }
                    }
                ),
                encoding="utf-8",
            )

            report = audit.build_report(roots=[root], baseline_path=baseline)

        self.assertEqual(report["status"], "pass")
        self.assertEqual(report["summary"]["excess_group_count"], 0)

    def test_increased_registered_legacy_count_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            allowed = root / "allowed.py"
            allowed.write_text(
                'DB = SCRIPT_DIR / "knowledge.db"\n'
                'fallback = "scripts/knowledge.db"\n',
                encoding="utf-8",
            )
            baseline = root / "baseline.json"
            baseline.write_text(
                json.dumps(
                    {
                        "allowed_max_by_category_file": {
                            "stale_sqlite_path": {str(allowed): 1}
                        }
                    }
                ),
                encoding="utf-8",
            )

            report = audit.build_report(roots=[root], baseline_path=baseline)

        self.assertEqual(report["status"], "fail")
        self.assertEqual(report["excess"][0]["current_count"], 2)
        self.assertEqual(report["excess"][0]["allowed_count"], 1)

    def test_raw_edhrec_inclusion_score_is_detected_but_rate_is_not(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            scorer = root / "score.dart"
            scorer.write_text(
                "final good = card.inclusionRate * 20;\n"
                "final bad = card.inclusion * 20;\n",
                encoding="utf-8",
            )
            baseline = root / "baseline.json"
            baseline.write_text(
                json.dumps({"allowed_max_by_category_file": {}}),
                encoding="utf-8",
            )

            report = audit.build_report(roots=[root], baseline_path=baseline)

        self.assertEqual(report["status"], "fail")
        self.assertEqual(report["summary"]["category_totals"], {"raw_edhrec_inclusion_score": 1})


if __name__ == "__main__":
    unittest.main()
