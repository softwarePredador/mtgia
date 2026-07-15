#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
AUDIT_OUT="$(mktemp -t manaloom-battle-product-audit.XXXXXX.json)"
trap 'rm -f "$AUDIT_OUT"' EXIT

cd "$ROOT_DIR"

PYTHONWARNINGS=error::ResourceWarning python3 -m unittest \
  server.test.native_battle_worker_test \
  server.test.native_battle_sidecar_test \
  server.test.manaloom_ops_daemon_test

python3 server/bin/manaloom_battle_product_e2e_audit.py --out "$AUDIT_OUT"

(
  cd server
  dart analyze \
    lib/ai/battle_engine_config.dart \
    lib/ai/battle_learning_evidence_support.dart \
    lib/ai/deck_battle_learning_evidence.dart \
    lib/ai/native_battle_client.dart \
    lib/battle/battle_replay_read_service.dart \
    lib/deck_card_name_resolution_support.dart \
    routes/ai/simulate/index.dart \
    'routes/decks/[id]/analysis/index.dart' \
    'routes/decks/[id]/battle-replays/index.dart' \
    'routes/decks/[id]/battle-replays/[replayId]/index.dart' \
    routes/decks/index.dart
  dart test --reporter compact \
    test/native_battle_client_test.dart \
    test/battle_engine_config_test.dart \
    test/battle_learning_evidence_support_test.dart \
    test/deck_battle_learning_evidence_test.dart \
    test/card_resolution_support_test.dart \
    test/battle_replay_read_service_test.dart \
    test/battle_product_e2e_test.dart \
    test/experimental_deck_ai_authorization_source_test.dart
)

bash -n \
  scripts/manaloom_deploy_ops_image.sh \
  scripts/manaloom_deploy_backend_image.sh \
  scripts/manaloom_deploy_battle_sidecars.sh

python3 - "$AUDIT_OUT" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    audit = json.load(handle)
print(json.dumps({
    "status": "pass",
    "gate": "manaloom_battle_product_gate_v1",
    "contract": audit["contract"],
    "checks": audit["summary"]["checks"],
}, separators=(",", ":")))
PY
