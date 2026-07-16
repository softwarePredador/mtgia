from __future__ import annotations

import argparse
import contextlib
import importlib.util
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "server/bin/premium_visual_audit.py"
SPEC = importlib.util.spec_from_file_location("premium_visual_audit_under_test", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
AUDIT = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = AUDIT
SPEC.loader.exec_module(AUDIT)


def _write_config(root: Path, config: dict) -> None:
    (root / "config.json").write_text(json.dumps(config))


def _surface(
    surface_id: str,
    files: list[str],
    *,
    strict: bool = False,
) -> dict:
    return {
        "id": surface_id,
        "label": surface_id,
        "strict_file_inventory": strict,
        "files": files,
        "captures": [],
        "focus": [],
    }


def _config(*surfaces: dict) -> dict:
    return {
        "baseline_documents": [],
        "baseline_rules": [],
        "capture_commands": {},
        "surfaces": list(surfaces),
    }


class PremiumVisualAuditInventoryTest(unittest.TestCase):
    def test_production_life_counter_inventory_is_complete_and_strict(self) -> None:
        config = json.loads(
            (REPO / "server/config/premium_visual_qa_surfaces.json").read_text()
        )
        life_counter = next(
            surface
            for surface in config["surfaces"]
            if surface["id"] == "life_counter"
        )
        configured = set(life_counter["files"])

        self.assertIs(life_counter.get("strict_file_inventory"), True)
        self.assertNotIn(
            "app/lib/features/home/life_counter_screen.dart",
            configured,
        )

        renderer_files = {
            "app/lib/features/home/life_counter_route.dart",
            "app/lib/features/home/lotus_life_counter_screen.dart",
            "app/lib/features/home/lotus/lotus_host_controller.dart",
            "app/lib/features/home/lotus/lotus_host_overlays.dart",
            "app/lib/features/home/lotus/lotus_visual_skin.dart",
            "app/assets/lotus/index.html",
            "app/assets/lotus/flutter_bootstrap.js",
            "app/assets/lotus/css/styles.min.css",
            "app/assets/lotus/js/app.min.js",
            "app/assets/lotus/fonts/Inter.ttf",
            "app/assets/lotus/fonts/Fraunces.ttf",
        }
        self.assertTrue(renderer_files.issubset(configured))

        sheet_root = REPO / "app/lib/features/home/life_counter"
        native_sheets = {
            str(path.relative_to(REPO))
            for path in sheet_root.glob("life_counter_native_*_sheet.dart")
        }
        self.assertTrue(native_sheets)
        self.assertTrue(native_sheets.issubset(configured))

        required_captures = {
            "life_counter_main_2_players",
            "life_counter_main_6_players",
            "life_counter_main_4_players_landscape",
            "life_counter_menu_open_active_state",
            "life_counter_settings",
            "life_counter_history",
            "life_counter_player_appearance_custom_image",
            "life_counter_exit_flow",
        }
        self.assertTrue(required_captures.issubset(set(life_counter["captures"])))

        _, issues = AUDIT.configured_file_inventory(
            config,
            include_life_counter=True,
        )
        life_counter_issues = [
            issue for issue in issues if issue.surface_id == "life_counter"
        ]
        self.assertEqual(life_counter_issues, [])

    def test_excluded_life_counter_does_not_validate_its_strict_paths(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            present = root / "present.dart"
            present.write_text("const present = true;\n")
            config = _config(
                _surface("home", ["present.dart"]),
                _surface("life_counter", ["missing.dart"], strict=True),
            )

            with mock.patch.object(AUDIT, "REPO", root):
                files, issues = AUDIT.configured_file_inventory(
                    config,
                    include_life_counter=False,
                )

            self.assertEqual(files, [present])
            self.assertEqual(issues, [])

    def test_inventory_reports_invalid_paths_and_directories(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "directory.dart").mkdir()
            config = _config(
                _surface(
                    "life_counter",
                    ["", "directory.dart"],
                    strict=True,
                ),
            )

            with mock.patch.object(AUDIT, "REPO", root):
                files, issues = AUDIT.configured_file_inventory(
                    config,
                    include_life_counter=True,
                )

            self.assertEqual(files, [])
            self.assertEqual(
                [(issue.reason, issue.blocking) for issue in issues],
                [("invalid_path", True), ("not_a_file", True)],
            )

    def test_binary_inventory_file_is_not_scanned_as_source_text(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            font = Path(directory) / "font.ttf"
            font.write_bytes(b"\x00Color(0xFFFFFFFF)\n")
            signals: list[AUDIT.Signal] = []
            counters = AUDIT.Counter()

            AUDIT.audit_dart_file(font, signals, counters)

            self.assertEqual(signals, [])
            self.assertEqual(counters, {})

    def test_main_reports_and_fails_for_missing_strict_file(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "present.dart").write_text("const present = true;\n")
            _write_config(
                root,
                _config(
                    _surface("home", ["present.dart"]),
                    _surface("life_counter", ["missing.dart"], strict=True),
                ),
            )
            args = argparse.Namespace(
                config="config.json",
                output="report.md",
                include_life_counter=True,
                include_git_status=False,
            )
            stdout = io.StringIO()
            stderr = io.StringIO()

            with (
                mock.patch.object(AUDIT, "REPO", root),
                mock.patch.object(AUDIT, "parse_args", return_value=args),
                mock.patch.object(AUDIT, "run", return_value="test"),
                contextlib.redirect_stdout(stdout),
                contextlib.redirect_stderr(stderr),
            ):
                exit_code = AUDIT.main()

            report = (root / "report.md").read_text()
            self.assertEqual(exit_code, AUDIT.CONFIG_ERROR_EXIT_CODE)
            self.assertIn(
                "VISUAL_PREMIUM_QA_CONFIG_RESULT: issues=1 blocking=1 valid=false",
                stderr.getvalue(),
            )
            self.assertIn(
                "ERROR: surface=life_counter reason=missing path=missing.dart",
                stderr.getvalue(),
            )
            self.assertIn("`CONFIG_INVALID` surface=`life_counter`", report)
            self.assertIn("reason=`missing` path=`missing.dart`", report)
            self.assertIn("- Arquivos inventariados: `1`", report)
            self.assertIn("- Arquivos textuais auditados: `1`", report)

    def test_legacy_surface_missing_file_is_reported_without_exit_regression(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            _write_config(
                root,
                _config(_surface("legacy", ["missing.dart"])),
            )
            args = argparse.Namespace(
                config="config.json",
                output="report.md",
                include_life_counter=False,
                include_git_status=False,
            )
            stdout = io.StringIO()
            stderr = io.StringIO()

            with (
                mock.patch.object(AUDIT, "REPO", root),
                mock.patch.object(AUDIT, "parse_args", return_value=args),
                mock.patch.object(AUDIT, "run", return_value="test"),
                contextlib.redirect_stdout(stdout),
                contextlib.redirect_stderr(stderr),
            ):
                exit_code = AUDIT.main()

            report = (root / "report.md").read_text()
            self.assertEqual(exit_code, 0)
            self.assertIn(
                "VISUAL_PREMIUM_QA_CONFIG_RESULT: issues=1 blocking=0 valid=true",
                stderr.getvalue(),
            )
            self.assertIn(
                "WARNING: surface=legacy reason=missing path=missing.dart",
                stderr.getvalue(),
            )
            self.assertIn("`CONFIG_WARNING` surface=`legacy`", report)


if __name__ == "__main__":
    unittest.main()
