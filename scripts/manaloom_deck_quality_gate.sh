#!/usr/bin/env bash
# Deterministic deck mana-consistency gate.
#
# NOTE ON SCOPE: this scores MANA CONSISTENCY, not deck power. See the header
# of server/lib/ai/deck_quality_report.dart and deck_quality_report_limits_test.dart.
#
# Scores every deck in the committed fixture and fails on any drift from the
# committed baseline. GoldfishSimulator seeds from a stable deck hash, so a
# difference is always a real behavioural change, never flakiness.
#
# No network, no LLM, no database.
#
# To accept an intentional change: run with --update-baseline, review the
# diff, and commit the new baseline with the change that caused it.
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_JSON="${MANALOOM_DECK_QUALITY_OUT:-/tmp/manaloom_deck_quality_$STAMP.json}"
FIXTURE="${MANALOOM_DECK_QUALITY_FIXTURE:-test/fixtures/deck_quality_fixture.json}"
BASELINE="${MANALOOM_DECK_QUALITY_BASELINE:-test/fixtures/deck_quality_baseline.json}"

cd "$ROOT_DIR/server"

dart run bin/deck_quality_report.dart \
  --check \
  --fixture="$FIXTURE" \
  --baseline="$BASELINE" \
  --json-out="$OUT_JSON"

dart test test/ai/deck_quality_report_test.dart test/ai/deck_quality_report_limits_test.dart
