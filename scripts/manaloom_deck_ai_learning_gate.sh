#!/usr/bin/env bash
set -u -o pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
PROFILE="${MANALOOM_DECK_AI_GATE_PROFILE:-local}"
REPORT_ROOT="${MANALOOM_DECK_AI_GATE_REPORT_DIR:-/tmp/manaloom_deck_ai_learning_gate}"
RECEIPT_MAX_AGE_HOURS="${MANALOOM_DECK_AI_RECEIPT_MAX_AGE_HOURS:-24}"
POLICY_FILE="$ROOT_DIR/server/config/deck_ai_learning_gate_policy.json"
RECEIPT_VALIDATOR="$ROOT_DIR/scripts/manaloom_deck_ai_learning_receipt_validator.py"

usage() {
  cat <<'EOF'
Uso:
  ./scripts/manaloom_deck_ai_learning_gate.sh [--profile local|release-read-only]

Perfis:
  local              Executa contratos e auditores locais sob isolamento de
                     rede, sem Flutter, pub, PostgreSQL, API ou runtime.
                     Worktree dirty e evidencia em /tmp sao permitidos, mas o
                     unico sucesso possivel e PASS_CODE_ONLY.
  release-read-only  Executa a mesma camada local e exige uma evidencia PG
                     read-only v2 fresca, duravel, ligada ao mesmo checkout,
                     target, schema 058, checks e artifacts, em
                     MANALOOM_DECK_AI_RELEASE_RECEIPT. Tambem exige que
                     MANALOOM_NEW_SERVER_ENV aponte para a configuracao de
                     credenciais existente. Este gate valida a evidencia; ele
                     nao abre rede nem carrega segredos. Sucesso: PASS.

Status/exit code:
  PASS ou PASS_CODE_ONLY = 0
  FAIL                   = 1
  BLOCKED                = 2
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --profile)
      if (( $# < 2 )); then
        echo "BLOCKED: --profile exige um valor" >&2
        exit 2
      fi
      PROFILE="$2"
      shift 2
      ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    *)
      echo "BLOCKED: argumento desconhecido: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "$PROFILE" != "local" && "$PROFILE" != "release-read-only" ]]; then
  echo "BLOCKED: perfil invalido: $PROFILE" >&2
  usage >&2
  exit 2
fi

if [[ ! "$RECEIPT_MAX_AGE_HOURS" =~ ^[1-9][0-9]*$ ]]; then
  echo "BLOCKED: MANALOOM_DECK_AI_RECEIPT_MAX_AGE_HOURS deve ser inteiro positivo" >&2
  exit 2
fi

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_DIR="$REPORT_ROOT/${STAMP}_$$"
SUMMARY_JSON="$RUN_DIR/summary.json"
SUMMARY_MD="$RUN_DIR/summary.md"
SOURCE_START_JSON="$RUN_DIR/source-start.json"
SOURCE_END_JSON="$RUN_DIR/source-end.json"
STEP_RECORD_DIR="$RUN_DIR/step-records"
RUN_STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
mkdir -p "$RUN_DIR"

PASSED_STEPS=()
FAILED_STEPS=()
BLOCKED_STEPS=()
STEP_IDS=()
NETWORK_SANDBOX_CMD=()
NETWORK_ENFORCEMENT="unsupported"
EXTERNAL_RECEIPT_PATH=""
EXTERNAL_RECEIPT_SHA256=""
GIT_SHA=""
WORKTREE_DIGEST_SHA256=""
PROJECT_LOGIC_SOURCE_DIGEST=""

slugify() {
  printf '%s' "$1" |
    tr '[:upper:]' '[:lower:]' |
    sed -E 's/[^a-z0-9]+/_/g; s/^_+//; s/_+$//'
}

record_pass() {
  PASSED_STEPS+=("$1")
  printf 'PASS: %s\n' "$1"
}

record_fail() {
  FAILED_STEPS+=("$1")
  printf 'FAIL: %s\n' "$1" >&2
}

record_blocked() {
  BLOCKED_STEPS+=("$1")
  printf 'BLOCKED: %s\n' "$1" >&2
}

record_step_json() {
  local step_id="$1"
  local label="$2"
  local status="$3"
  local exit_code="$4"
  local log_file="$5"
  local record_file
  record_file="$STEP_RECORD_DIR/$(slugify "$step_id").json"

  mkdir -p "$STEP_RECORD_DIR"
  python3 - "$record_file" "$step_id" "$label" "$status" "$exit_code" "$log_file" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

record_path, step_id, label, status, exit_code, raw_log_path = sys.argv[1:]
log_path = Path(raw_log_path)
content = log_path.read_bytes()
payload = {
    "id": step_id,
    "label": label,
    "status": status,
    "exit_code": int(exit_code),
    "log": {
        "path": str(log_path.resolve()),
        "sha256": hashlib.sha256(content).hexdigest(),
        "size_bytes": len(content),
    },
}
Path(record_path).write_text(
    json.dumps(payload, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
PY
}

run_step() {
  local step_id="$1"
  local label="$2"
  local working_dir="$3"
  shift 3
  local log_file
  log_file="$RUN_DIR/$(slugify "$step_id").log"
  local step_rc
  local existing_step_id

  if [[ ! "$step_id" =~ ^[a-z0-9][a-z0-9_.-]*$ ]]; then
    record_fail "invalid stable step id: $step_id"
    return
  fi
  for existing_step_id in "${STEP_IDS[@]-}"; do
    if [[ "$existing_step_id" == "$step_id" ]]; then
      record_fail "duplicate stable step id: $step_id"
      return
    fi
  done
  STEP_IDS+=("$step_id")

  printf '\n============================================================\n'
  printf '%s\n' "$label"
  printf '============================================================\n'
  printf '$ (cd %q &&' "$working_dir" | tee "$log_file"
  printf ' %q' "$@" | tee -a "$log_file"
  printf ')\n' | tee -a "$log_file"

  (
    cd "$working_dir" || exit 1
    if (( ${#NETWORK_SANDBOX_CMD[@]} > 0 )); then
      "${NETWORK_SANDBOX_CMD[@]}" "$@"
    else
      "$@"
    fi
  ) >>"$log_file" 2>&1
  step_rc=$?
  sed -n '2,$p' "$log_file"
  if (( step_rc == 0 )) && grep -Eq \
    'All other tests passed!|(^|[^[:alnum:]_])skipped=[1-9][0-9]*|[+][0-9]+[[:space:]]+~[1-9][0-9]*' \
    "$log_file"; then
    step_rc=86
    printf 'FAIL: %s declarou teste pulado; SKIP nao recebe credito de PASS.\n' \
      "$label" >&2
  fi
  if (( step_rc == 0 )); then
    record_pass "$label"
    record_step_json "$step_id" "$label" "PASS" 0 "$log_file"
  elif (( step_rc == 2 )); then
    BLOCKED_STEPS+=("$label (exit $step_rc; log=$log_file)")
    printf 'BLOCKED: %s (exit %s; log=%s)\n' \
      "$label" "$step_rc" "$log_file" >&2
    record_step_json "$step_id" "$label" "BLOCKED" "$step_rc" "$log_file"
  else
    FAILED_STEPS+=("$label (exit $step_rc; log=$log_file)")
    printf 'FAIL: %s (exit %s; log=%s)\n' \
      "$label" "$step_rc" "$log_file" >&2
    record_step_json "$step_id" "$label" "FAIL" "$step_rc" "$log_file"
  fi
}

write_summary() {
  local final_status="$1"
  local exit_code="$2"
  local generated_at
  generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  python3 - \
    "$SUMMARY_JSON" \
    "$SUMMARY_MD" \
    "$generated_at" \
    "$PROFILE" \
    "$final_status" \
    "$exit_code" \
    "$ROOT_DIR" \
    "$RUN_DIR" \
    "$RUN_STARTED_AT" \
    "$SOURCE_START_JSON" \
    "$SOURCE_END_JSON" \
    "$POLICY_FILE" \
    "$STEP_RECORD_DIR" \
    "$NETWORK_ENFORCEMENT" \
    "$EXTERNAL_RECEIPT_PATH" \
    "$EXTERNAL_RECEIPT_SHA256" \
    "$(printf '%s\n' "${PASSED_STEPS[@]-}")" \
    "$(printf '%s\n' "${FAILED_STEPS[@]-}")" \
    "$(printf '%s\n' "${BLOCKED_STEPS[@]-}")" <<'PY'
import json
import hashlib
import sys
from pathlib import Path

(
    json_path,
    markdown_path,
    generated_at,
    profile,
    status,
    exit_code,
    repo,
    run_dir,
    started_at,
    source_start_path,
    source_end_path,
    policy_path,
    step_record_dir,
    network_enforcement,
    external_receipt_path,
    external_receipt_sha256,
    passed_text,
    failed_text,
    blocked_text,
) = sys.argv[1:]

def lines(value: str) -> list[str]:
    return [line for line in value.splitlines() if line]

def load_object(path_text: str) -> dict:
    path = Path(path_text)
    if not path.is_file():
        return {}
    value = json.loads(path.read_text(encoding="utf-8"))
    return value if isinstance(value, dict) else {}

def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while chunk := handle.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()

def under(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
        return True
    except ValueError:
        return False

repo_path = Path(repo).resolve()
run_path = Path(run_dir).resolve()
policy = load_object(policy_path)
source_start = load_object(source_start_path)
source_end = load_object(source_end_path)
records = []
records_path = Path(step_record_dir)
if records_path.is_dir():
    for record_path in sorted(records_path.glob("*.json")):
        record = load_object(str(record_path))
        if record:
            records.append(record)

artifacts = []
excluded = {Path(json_path).resolve(), Path(markdown_path).resolve()}
for artifact_path in sorted(path for path in run_path.rglob("*") if path.is_file()):
    if artifact_path.resolve() in excluded or artifact_path.is_symlink():
        continue
    artifacts.append(
        {
            "path": artifact_path.relative_to(run_path).as_posix(),
            "sha256": sha256(artifact_path),
            "size_bytes": artifact_path.stat().st_size,
        }
    )
artifact_manifest_sha256 = hashlib.sha256(
    json.dumps(
        artifacts,
        ensure_ascii=True,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
).hexdigest()

temporary = False
for raw_prefix in policy.get("temporary_path_prefixes") or []:
    if isinstance(raw_prefix, str) and raw_prefix.startswith("/"):
        if under(run_path, Path(raw_prefix).resolve()):
            temporary = True
            break
source_stable = bool(source_start) and source_start == source_end
git_sha = str(source_start.get("git_sha") or "")
git_dirty = source_start.get("git_dirty") is True
worktree_digest_sha256 = str(source_start.get("worktree_digest_sha256") or "")
project_logic_source_digest = str(
    source_start.get("project_logic_source_digest") or ""
)
release_eligible = (
    profile == "release-read-only"
    and status == "PASS"
    and source_stable
    and not git_dirty
    and not temporary
    and bool(external_receipt_sha256)
)

payload = {
    "schema_version": 2,
    "schema": "manaloom.deck_ai_learning_gate_run.v2",
    "gate": "deck-ai-learning",
    "policy": {
        "id": policy.get("policy_id"),
        "sha256": sha256(Path(policy_path)),
    },
    "started_at": started_at,
    "generated_at": generated_at,
    "profile": profile,
    "status": status,
    "exit_code": int(exit_code),
    "repo": repo,
    "run_dir": run_dir,
    "git_sha": git_sha,
    "git_dirty": git_dirty,
    "worktree_digest_sha256": worktree_digest_sha256,
    "project_logic_source_digest": project_logic_source_digest,
    "source": {
        "start": source_start,
        "end": source_end,
        "stable": source_stable,
    },
    "safety": {
        "network_opened": False,
        "network_enforcement": network_enforcement,
        "product_mutations_performed": [],
        "flutter_or_pub_invoked": False,
        "guarded_local_artifacts_stable": (
            source_start.get("guarded_local_artifacts")
            == source_end.get("guarded_local_artifacts")
            and bool(source_start)
        ),
    },
    "evidence": {
        "durable": not temporary,
        "artifacts": artifacts,
        "artifact_manifest_sha256": artifact_manifest_sha256,
    },
    "release_eligible": release_eligible,
    "external_receipt": (
        {
            "path": external_receipt_path,
            "sha256": external_receipt_sha256,
        }
        if external_receipt_sha256
        else None
    ),
    "steps": {
        "passed": lines(passed_text),
        "failed": lines(failed_text),
        "blocked": lines(blocked_text),
        "records": records,
    },
}
Path(json_path).write_text(
    json.dumps(payload, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)

markdown = [
    "# Deckbuilder / AI / Learning gate",
    "",
    f"- Status: `{status}`",
    f"- Profile: `{profile}`",
    f"- Generated at: `{generated_at}`",
    f"- Git SHA: `{git_sha}`",
    f"- Git dirty: `{str(git_dirty).lower()}`",
    f"- Worktree digest SHA-256: `{worktree_digest_sha256}`",
    f"- Project logic digest: `{project_logic_source_digest}`",
    f"- Source stable start/end: `{str(source_stable).lower()}`",
    f"- Evidence durable: `{str(not temporary).lower()}`",
    f"- Release eligible: `{str(release_eligible).lower()}`",
    f"- Network enforcement: `{network_enforcement}`",
    "- Network opened by local checks: `false`",
    "- Product mutations: `none`",
    "- Flutter/pub invoked: `false`",
    f"- Artifact manifest SHA-256: `{artifact_manifest_sha256}`",
    "",
    "## Passed",
    "",
]
markdown.extend(f"- {item}" for item in payload["steps"]["passed"])
markdown.extend(["", "## Failed", ""])
markdown.extend(f"- {item}" for item in payload["steps"]["failed"])
markdown.extend(["", "## Blocked", ""])
markdown.extend(f"- {item}" for item in payload["steps"]["blocked"])
Path(markdown_path).write_text("\n".join(markdown) + "\n", encoding="utf-8")
PY

  printf '\nStatus: %s\n' "$final_status"
  printf 'Summary JSON: %s\n' "$SUMMARY_JSON"
  printf 'Summary Markdown: %s\n' "$SUMMARY_MD"
}

required_files=(
  server/config/deck_ai_learning_gate_policy.json
  scripts/manaloom_deck_ai_learning_receipt_validator.py
  scripts/manaloom_deck_ai_learning_release_receipt.sh
  server/test/ai_generate_learning_boundary_test.dart
  server/test/deck_learning_event_support_test.dart
  server/test/commander_learned_deck_support_test.dart
  server/test/optimize_cache_support_test.dart
  server/test/optimize_runtime_support_test.dart
  server/test/optimize_learning_pipeline_test.dart
  server/test/commander_reference_read_only_contract_test.dart
  server/test/production_ai_mock_fallback_policy_test.dart
  server/test/ai_generate_performance_support_test.dart
  server/test/source_reachability_audit_test.dart
  server/test/auto_promote_learned_decks_test.py
  server/test/auto_sync_learned_decks_test.py
  server/test/pull_learning_events_schema_test.py
  server/test/optimizer_loop_tombstone_contract_test.py
  server/test/deck_ai_learning_gate_contract_test.py
  server/test/deck_ai_learning_receipt_validator_test.py
  server/test/manaloom_knowledge_import_test.py
  docs/hermes-analysis/manaloom-knowledge/scripts/test_export_hermes_learned_deck_metadata.py
  docs/hermes-analysis/manaloom-knowledge/scripts/test_export_hermes_learned_deck_wrapper_parity.py
  docs/hermes-analysis/manaloom-knowledge/scripts/commander_deckbuilding_flow_research_audit.py
  docs/hermes-analysis/manaloom-knowledge/scripts/deckbuilding_contract_surface_audit.py
  docs/hermes-analysis/manaloom-knowledge/scripts/operational_surface_alignment_audit.py
)

for relative_path in "${required_files[@]}"; do
  if [[ ! -f "$ROOT_DIR/$relative_path" ]]; then
    record_fail "required contract missing: $relative_path"
  fi
done

if ! command -v python3 >/dev/null 2>&1; then
  record_blocked "python3 is required"
fi

if [[ "$PROFILE" == "release-read-only" ]] &&
   ! python3 "$RECEIPT_VALIDATOR" check-durable-path \
     --path "$RUN_DIR" \
     --policy "$POLICY_FILE" \
     --repo "$ROOT_DIR" >/dev/null 2>&1; then
  record_blocked \
    "release-read-only requires MANALOOM_DECK_AI_GATE_REPORT_DIR outside temporary roots"
fi

if (( ${#FAILED_STEPS[@]} == 0 && ${#BLOCKED_STEPS[@]} == 0 )); then
  if ! python3 "$RECEIPT_VALIDATOR" snapshot-source \
      --repo "$ROOT_DIR" \
      --policy "$POLICY_FILE" \
      --out "$SOURCE_START_JSON"; then
    record_blocked "source start snapshot could not be captured"
  else
    read -r GIT_SHA WORKTREE_DIGEST_SHA256 PROJECT_LOGIC_SOURCE_DIGEST < <(
      python3 - "$SOURCE_START_JSON" <<'PY'
import json
import sys

source = json.load(open(sys.argv[1], encoding="utf-8"))
print(
    source.get("git_sha", ""),
    source.get("worktree_digest_sha256", ""),
    source.get("project_logic_source_digest", ""),
)
PY
    )
  fi
fi
if [[ ! "$GIT_SHA" =~ ^[0-9a-f]{40}$ ]]; then
  record_blocked "full 40-character Git SHA is required"
fi
if [[ ! "$WORKTREE_DIGEST_SHA256" =~ ^[0-9a-f]{64}$ ]]; then
  record_blocked "full worktree SHA-256 digest is required"
fi
if [[ ! "$PROJECT_LOGIC_SOURCE_DIGEST" =~ ^[0-9a-f]{64}$ ]]; then
  record_blocked "project logic source SHA-256 digest is required"
fi

if [[ "$(uname -s)" == "Darwin" && -x /usr/bin/sandbox-exec ]]; then
  SANDBOX_PROFILE="$RUN_DIR/network-deny.sb"
  printf '%s\n' \
    '(version 1)' \
    '(allow default)' \
    '(deny network*)' >"$SANDBOX_PROFILE"
  NETWORK_SANDBOX_CMD=(/usr/bin/sandbox-exec -f "$SANDBOX_PROFILE")
  NETWORK_ENFORCEMENT="darwin-sandbox-deny-network"
elif command -v unshare >/dev/null 2>&1 && unshare -n -- true >/dev/null 2>&1; then
  NETWORK_SANDBOX_CMD=(unshare -n --)
  NETWORK_ENFORCEMENT="linux-network-namespace"
else
  record_blocked "OS-enforced network isolation is required for local gate steps"
fi

# shellcheck source=scripts/lib/manaloom_dart_toolchain.sh
source "$ROOT_DIR/scripts/lib/manaloom_dart_toolchain.sh"
if ! resolve_manaloom_dart; then
  record_blocked "pinned Dart $MANALOOM_DART_TOOLCHAIN_VERSION is required"
else
  DART_BIN="$MANALOOM_DART_BIN_RESOLVED"
  export MANALOOM_DART_BIN="$DART_BIN"
  DART_BIN_DIR="$(dirname "$DART_BIN")"
  export PATH="$DART_BIN_DIR:$PATH"
fi

if (( ${#FAILED_STEPS[@]} == 0 && ${#BLOCKED_STEPS[@]} == 0 )); then
  python_contracts=(
    test/auto_promote_learned_decks_test.py
    test/auto_sync_learned_decks_test.py
    test/pull_learning_events_schema_test.py
    test/deck_ai_learning_gate_contract_test.py
    test/deck_ai_learning_receipt_validator_test.py
    test/manaloom_knowledge_import_test.py
  )
  python_contract_ids=(
    python.auto_promote_learned_decks
    python.auto_sync_learned_decks
    python.pull_learning_events_schema
    python.deck_ai_learning_gate_contract
    python.deck_ai_learning_receipt_validator
    python.manaloom_knowledge_import
  )
  for (( contract_index=0; contract_index<${#python_contracts[@]}; contract_index++ )); do
    python_contract="${python_contracts[$contract_index]}"
    run_step \
      "${python_contract_ids[$contract_index]}" \
      "Python containment contract: $(basename "$python_contract")" \
      "$ROOT_DIR/server" \
      env \
        -u PGHOST \
        -u PGPORT \
        -u PGDATABASE \
        -u PGUSER \
        -u PGPASSWORD \
        -u DATABASE_URL \
        MTGIA_ENV_FILE="$RUN_DIR/no-env" \
        MANALOOM_POSTGRES_ENV="$RUN_DIR/no-pg-env" \
        MTGIA_SYNC_SERVER_DIR="$RUN_DIR/no-server-env" \
        python3 "$python_contract"
  done

  exporter_contracts=(
    test_export_hermes_learned_deck_metadata.py
    test_export_hermes_learned_deck_wrapper_parity.py
  )
  exporter_contract_ids=(
    hermes.learned_deck_metadata_contract
    hermes.learned_deck_wrapper_parity_contract
  )
  for (( contract_index=0; contract_index<${#exporter_contracts[@]}; contract_index++ )); do
    exporter_contract="${exporter_contracts[$contract_index]}"
    run_step \
      "${exporter_contract_ids[$contract_index]}" \
      "Hermes learned-deck exporter contract: $exporter_contract" \
      "$ROOT_DIR/docs/hermes-analysis/manaloom-knowledge/scripts" \
      env \
        -u PGHOST \
        -u PGDATABASE \
        -u PGUSER \
        -u PGPASSWORD \
        -u DATABASE_URL \
        python3 "$exporter_contract"
  done

  run_step \
    "optimizer.legacy_loop_tombstone_contract" \
    "Optimizer loop tombstone contract" \
    "$ROOT_DIR/server" \
    python3 test/optimizer_loop_tombstone_contract_test.py

  run_step \
    "dart.deck_ai_learning_containment_contracts" \
    "Dart deck AI and learning containment contracts" \
    "$ROOT_DIR/server" \
    env \
      -u DATABASE_URL \
      -u API_BASE_URL \
      -u TEST_API_BASE_URL \
      RUN_INTEGRATION_TESTS=0 \
      JWT_SECRET=local_deck_ai_learning_gate_not_for_production \
      "$DART_BIN" test \
      --exclude-tags "live || live_backend || live_db_write || live_external" \
      --reporter compact \
      test/ai_generate_learning_boundary_test.dart \
      test/deck_learning_event_support_test.dart \
      test/commander_learned_deck_support_test.dart \
      test/optimize_cache_support_test.dart \
      test/optimize_runtime_support_test.dart \
      test/optimize_learning_pipeline_test.dart \
      test/commander_reference_read_only_contract_test.dart \
      test/production_ai_mock_fallback_policy_test.dart \
      test/ai_generate_performance_support_test.dart \
      test/source_reachability_audit_test.dart

  run_step \
    "audit.commander_deckbuilding_research_flow" \
    "Commander deckbuilding research flow audit" \
    "$ROOT_DIR" \
    python3 \
      docs/hermes-analysis/manaloom-knowledge/scripts/commander_deckbuilding_flow_research_audit.py \
      --out-prefix "$RUN_DIR/commander_deckbuilding_flow_research_audit"

  run_step \
    "audit.commander_deckbuilding_contract_surface" \
    "Commander deckbuilding contract surface audit" \
    "$ROOT_DIR" \
    python3 \
      docs/hermes-analysis/manaloom-knowledge/scripts/deckbuilding_contract_surface_audit.py \
      --out-prefix "$RUN_DIR/deckbuilding_contract_surface_audit"

  run_step \
    "audit.operational_surface_alignment" \
    "Operational surface alignment audit" \
    "$ROOT_DIR" \
    python3 \
      docs/hermes-analysis/manaloom-knowledge/scripts/operational_surface_alignment_audit.py \
      --out-prefix "$RUN_DIR/operational_surface_alignment_audit"

  run_step \
    "project_logic.drift_check" \
    "Project logic source/manifest drift check" \
    "$ROOT_DIR" \
    "$ROOT_DIR/scripts/manaloom_project_logic.sh" --check
fi

if [[ -f "$SOURCE_START_JSON" ]]; then
  if ! python3 "$RECEIPT_VALIDATOR" snapshot-source \
      --repo "$ROOT_DIR" \
      --policy "$POLICY_FILE" \
      --out "$SOURCE_END_JSON"; then
    record_fail "source end snapshot could not be captured"
  elif [[ "$PROFILE" == "release-read-only" ]]; then
    run_step \
      "source.toctou_guard" \
      "Source start/end TOCTOU guard (clean release)" \
      "$ROOT_DIR" \
      python3 "$RECEIPT_VALIDATOR" verify-source-stable \
        --start "$SOURCE_START_JSON" \
        --end "$SOURCE_END_JSON" \
        --require-clean
  else
    run_step \
      "source.toctou_guard" \
      "Source start/end TOCTOU guard (local dirty allowed)" \
      "$ROOT_DIR" \
      python3 "$RECEIPT_VALIDATOR" verify-source-stable \
        --start "$SOURCE_START_JSON" \
        --end "$SOURCE_END_JSON"
  fi
fi

if (( ${#FAILED_STEPS[@]} == 0 && ${#BLOCKED_STEPS[@]} == 0 )); then
  if ! python3 - "$POLICY_FILE" "$RUN_DIR/local-step-catalog.json" "${STEP_IDS[@]-}" <<'PY'
import json
import sys
from pathlib import Path

policy_path, output_path, *actual = sys.argv[1:]
policy = json.loads(Path(policy_path).read_text(encoding="utf-8"))
expected = policy.get("local_step_ids") or []
payload = {
    "status": "PASS" if actual == expected else "FAIL",
    "expected": expected,
    "actual": actual,
    "missing": [item for item in expected if item not in actual],
    "extra": [item for item in actual if item not in expected],
}
Path(output_path).write_text(
    json.dumps(payload, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
raise SystemExit(0 if payload["status"] == "PASS" else 1)
PY
  then
    record_fail "local stable step catalog does not match policy"
  fi
fi

if [[ "$PROFILE" == "release-read-only" &&
      ${#FAILED_STEPS[@]} -eq 0 &&
      ${#BLOCKED_STEPS[@]} -eq 0 ]]; then
  credential_file="${MANALOOM_NEW_SERVER_ENV:-}"
  receipt_file="${MANALOOM_DECK_AI_RELEASE_RECEIPT:-}"

  if [[ -z "$credential_file" || ! -f "$credential_file" || ! -r "$credential_file" ]]; then
    record_blocked \
      "MANALOOM_NEW_SERVER_ENV must point to a readable credential configuration"
  fi
  if [[ -z "$receipt_file" || ! -f "$receipt_file" || ! -r "$receipt_file" ]]; then
    record_blocked \
      "MANALOOM_DECK_AI_RELEASE_RECEIPT must point to a readable canonical v2 receipt"
  elif (( ${#BLOCKED_STEPS[@]} == 0 )); then
    failed_before_receipt=${#FAILED_STEPS[@]}
    blocked_before_receipt=${#BLOCKED_STEPS[@]}
    run_step \
      "release.external_receipt_v2" \
      "Fresh source/target-bound PostgreSQL/Hermes receipt v2" \
      "$ROOT_DIR" \
      python3 "$RECEIPT_VALIDATOR" validate-release \
        --receipt "$receipt_file" \
        --policy "$POLICY_FILE" \
        --repo "$ROOT_DIR" \
        --credential-file "$credential_file" \
        --max-age-hours "$RECEIPT_MAX_AGE_HOURS"
    if (( ${#FAILED_STEPS[@]} == failed_before_receipt &&
          ${#BLOCKED_STEPS[@]} == blocked_before_receipt )); then
      EXTERNAL_RECEIPT_PATH="$(python3 - "$receipt_file" <<'PY'
import sys
from pathlib import Path

print(Path(sys.argv[1]).resolve())
PY
)"
      EXTERNAL_RECEIPT_SHA256="$(python3 - "$receipt_file" <<'PY'
import hashlib
import sys
from pathlib import Path

print(hashlib.sha256(Path(sys.argv[1]).read_bytes()).hexdigest())
PY
)"
    fi
  fi
fi

if (( ${#FAILED_STEPS[@]} > 0 )); then
  write_summary "FAIL" 1
  exit 1
fi
if (( ${#BLOCKED_STEPS[@]} > 0 )); then
  write_summary "BLOCKED" 2
  exit 2
fi
if [[ "$PROFILE" == "local" ]]; then
  write_summary "PASS_CODE_ONLY" 0
  exit 0
fi

write_summary "PASS" 0
exit 0
