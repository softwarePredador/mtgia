#!/usr/bin/env bash
# BT-CAP-002 (D-14): aplica e desfaz as reservas e os limites de UM serviço da produção,
# com preflight antes de qualquer mudança e rollback exato. Na produção, quem roda é a
# coordenação, no lote de deploy, com a palavra do dono.
#
# Uso:
#   scripts/manaloom_capacity_resources.sh                         descreve, sem conectar
#   scripts/manaloom_capacity_resources.sh --execute --plan --service S --snapshot F
#   scripts/manaloom_capacity_resources.sh --execute --apply --service S --snapshot F \
#       --receipt-dir D
#   scripts/manaloom_capacity_resources.sh --execute --rollback RECEIPT --receipt-dir D
#
# --plan só lê. --apply e --rollback exigem MANALOOM_CONFIRM_LIVE_MUTATIONS. Todo modo
# com --execute exige a âncora de host (MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256), a do
# EasyPanel (MANALOOM_EXPECTED_EASYPANEL_BASE_URL_SHA256), a chave SSH do deploy e o
# token do EasyPanel (server/.env). O snapshot vem de
# scripts/manaloom_capacity_snapshot.sh, no máximo 30 minutos antes.
#
# Aplicar recursos troca a tarefa do serviço (stop-first, uma réplica): é um
# reinício curto, como um deploy. No lote, um serviço por vez, depois dos deploys.
#
# Códigos: 0 feito (ou plano PASS, ou nada a mudar); 1 falhou (com rollback provado
# ou não, ver o receipt); 2 entrada ou ambiente recusado, nada mudou; 3 BLOCKED pelo
# preflight ou pela decisão de rollback, nada mudou (no --apply, com receipt blocked).
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="${MANALOOM_NEW_SERVER_ENV:-$ROOT_DIR/server/.env}"
LOGIC="$ROOT_DIR/scripts/manaloom_capacity_resources.py"
POLICY="$ROOT_DIR/server/config/capacity_policy.json"
WAIT_ATTEMPTS="${MANALOOM_CAPACITY_WAIT_ATTEMPTS:-90}"
WAIT_SECONDS="${MANALOOM_CAPACITY_WAIT_SECONDS:-2}"
EXECUTE=0
MODE=""
SERVICE=""
SNAPSHOT=""
RECEIPT_DIR=""
ROLLBACK_RECEIPT=""

usage() {
  sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'
}

while (( $# > 0 )); do
  case "$1" in
    --execute) EXECUTE=1; shift ;;
    --plan) MODE=plan; shift ;;
    --apply) MODE=apply; shift ;;
    --rollback) MODE=rollback; ROLLBACK_RECEIPT="${2:-}"; shift 2 ;;
    --service) SERVICE="${2:-}"; shift 2 ;;
    --snapshot) SNAPSHOT="${2:-}"; shift 2 ;;
    --receipt-dir) RECEIPT_DIR="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "argumento desconhecido: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# Os únicos comandos que esta ferramenta manda para o host. O contrato
# (server/test/capacity_resources_test.py) confere cada chamada.
inspect_cmd() { printf "docker service inspect '%s'" "$1"; }
running_cmd() {
  printf "docker service ps '%s' --filter desired-state=running --format '{{.Image}}|{{.CurrentState}}'" "$1"
}
update_cmd() {
  printf "docker service update --detach=true --limit-memory %s --reserve-memory %s --limit-cpu %s --reserve-cpu %s '%s'" \
    "$1" "$2" "$3" "$4" "$5"
}
rollback_cmd() { printf "docker service rollback --detach '%s'" "$1"; }

if [[ "$EXECUTE" != "1" ]]; then
  python3 - "$POLICY" <<'PY'
import json
import sys

policy = json.load(open(sys.argv[1], encoding="utf-8"))
section = policy["reservations_and_limits"]
print(json.dumps({
    "status": "dry_run",
    "task": "BT-CAP-002",
    "policy_version": policy["version"],
    "services": {
        name: {key: entry[key] for key in (
            "applied_by", "memory_reservation_mb", "memory_limit_mb",
            "cpu_reservation", "cpu_limit")}
        for name, entry in section["services"].items()
    },
    "remote_commands": [
        "docker service inspect '<servico>'",
        "docker service ps '<servico>' --filter desired-state=running "
        "--format '{{.Image}}|{{.CurrentState}}'",
        "docker service update --detach=true --limit-memory <bytes> --reserve-memory <bytes> "
        "--limit-cpu <vCPU> --reserve-cpu <vCPU> '<servico>'",
        "docker service rollback --detach '<servico>'",
    ],
    "easypanel": ["projects.listProjectsAndServices", "services.app.updateResources"],
    "execute": "--execute --plan|--apply --service <nome> --snapshot <arquivo> "
               "[--receipt-dir <dir>] ou --execute --rollback <receipt> --receipt-dir <dir>",
}, ensure_ascii=False, indent=2))
PY
  exit 0
fi

case "$MODE" in
  plan|apply)
    [[ -n "$SERVICE" && -f "$SNAPSHOT" ]] || {
      echo "--$MODE exige --service e um --snapshot existente" >&2; exit 2; }
    ;;
  rollback)
    [[ -f "$ROLLBACK_RECEIPT" ]] || { echo "--rollback exige um receipt existente" >&2; exit 2; }
    ;;
  *) echo "--execute exige --plan, --apply ou --rollback" >&2; exit 2 ;;
esac
if [[ "$MODE" != "plan" ]]; then
  [[ -n "$RECEIPT_DIR" && -d "$RECEIPT_DIR" ]] || {
    echo "--$MODE exige um --receipt-dir existente" >&2; exit 2; }
  RECEIPT_DIR="$(cd "$RECEIPT_DIR" && pwd -P)"
  if python3 - "$RECEIPT_DIR" <<'PY'
import re
import sys

temporary = re.compile(
    r"(^|/)(tmp|private/tmp|var/folders)/|(^|/)\.claude/worktrees/|(^|/)worktrees?/")
raise SystemExit(0 if temporary.search(sys.argv[1] + "/") else 1)
PY
  then
    echo "o receipt tem de ficar num diretório durável, não em $RECEIPT_DIR" >&2
    exit 2
  fi
  # shellcheck source=scripts/lib/manaloom_mutation_guard.sh
  source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
  require_live_mutation_approval "ManaLoom resource reservations and limits"
fi

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=scripts/lib/manaloom_safe_env.sh
  source "$ROOT_DIR/scripts/lib/manaloom_safe_env.sh"
  load_manaloom_env_keys "$ENV_FILE" \
    EASYPANEL_API_TOKEN EASYPANEL_BASE_URL EASYPANEL_PROJECT_NAME \
    EASYPANEL_SSH_KEY MANALOOM_EASYPANEL_SSH_HOST MANALOOM_EASYPANEL_SSH_KEY
fi
# shellcheck source=scripts/lib/manaloom_release_runtime_contract.sh
source "$ROOT_DIR/scripts/lib/manaloom_release_runtime_contract.sh"
PROJECT="${EASYPANEL_PROJECT_NAME:-evolution}"
SSH_HOST="${MANALOOM_EASYPANEL_SSH_HOST:-root@evolution-cartinhas.2ta7qx.easypanel.host}"
SSH_KEY="${MANALOOM_EASYPANEL_SSH_KEY:-${EASYPANEL_SSH_KEY:-$HOME/.ssh/manaloom_easy_parallel_20260703}}"
for key in EASYPANEL_BASE_URL EASYPANEL_API_TOKEN; do
  [[ -n "${!key:-}" ]] || { echo "variável obrigatória ausente: $key" >&2; exit 2; }
done
[[ -f "$SSH_KEY" ]] || { echo "chave SSH do deploy não encontrada: $SSH_KEY" >&2; exit 2; }
validate_manaloom_exact_coordinate project "$PROJECT" "$MANALOOM_PRODUCTION_EASYPANEL_PROJECT"
validate_manaloom_easypanel_base_url "$EASYPANEL_BASE_URL"
initialize_manaloom_secure_ssh "$SSH_HOST"

RUN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom-capacity-resources.XXXXXX")"
chmod 700 "$RUN_DIR"
MUTATION_STARTED=0
FINISHED=0
PLAN_FILE="$RUN_DIR/plan.json"

remote() { ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "$1"; }

trpc_post() {
  curl -fsS --proto '=https' --tlsv1.2 \
    -H "Authorization: Bearer $EASYPANEL_API_TOKEN" \
    -H 'Content-Type: application/json' \
    --data "$(jq -cn --argjson input "$2" '{json:$input}')" \
    "$EASYPANEL_BASE_URL/api/trpc/$1"
}

# Nenhum valor de env chega ao disco: as duas leituras passam pelo redator antes.
read_inspect() {
  remote "$(inspect_cmd "$1")" | python3 "$LOGIC" redact-inspect >"$2"
}

read_easypanel() {
  trpc_post projects.listProjectsAndServices null |
    python3 "$LOGIC" redact-easypanel --project "$PROJECT" >"$1"
}

read_state() {
  local swarm="$1" label="$2"
  read_easypanel "$RUN_DIR/$label.easypanel.json"
  read_inspect "$swarm" "$RUN_DIR/$label.inspect.json"
  remote "$(running_cmd "$swarm")" >"$RUN_DIR/$label.running.txt"
}

update_easypanel() {
  local name="$1" resources="$2"
  trpc_post services.app.updateResources "$(jq -cn \
    --arg project "$PROJECT" --arg service "$name" --argjson resources "$resources" \
    '{projectName:$project,serviceName:$service,resources:$resources}')" >/dev/null
}

wait_converged() {
  local swarm="$1" label="$2" attempt rc
  for attempt in $(seq 1 "$WAIT_ATTEMPTS"); do
    read_inspect "$swarm" "$RUN_DIR/$label.inspect.json"
    remote "$(running_cmd "$swarm")" >"$RUN_DIR/$label.running.txt"
    rc=0
    python3 "$LOGIC" converged --inspect "$RUN_DIR/$label.inspect.json" \
      --running "$RUN_DIR/$label.running.txt" >"$RUN_DIR/$label.converged.json" || rc=$?
    case "$rc" in
      0) return 0 ;;
      3) return 1 ;;
    esac
    if (( attempt < WAIT_ATTEMPTS )); then sleep "$WAIT_SECONDS"; fi
  done
  return 1
}

tool_git_sha() { git -C "$ROOT_DIR" rev-parse HEAD; }

write_receipt() {
  local status="$1" out="$2"
  shift 2
  python3 "$LOGIC" receipt --plan "$PLAN_FILE" --status "$status" \
    --tool-git-sha "$(tool_git_sha)" --out "$out" "$@" >/dev/null
}

# Volta a spec e o EasyPanel ao que estava antes, só se a nossa mudança ainda for a
# última nos dois lugares; prova com a spec inteira e com o que o EasyPanel tem gravado.
RESTORE_MUTATED=0
restore() {
  local receipt="$1" swarm="$2" name="$3" decision_rc=0
  RESTORE_MUTATED=0
  read_state "$swarm" restore
  python3 "$LOGIC" rollback-decision --receipt "$receipt" \
    --inspect "$RUN_DIR/restore.inspect.json" \
    --easypanel "$RUN_DIR/restore.easypanel.json" >"$RUN_DIR/decision.json" || decision_rc=$?
  cat "$RUN_DIR/decision.json" >&2
  if [[ "$decision_rc" != "0" ]]; then
    jq -ec '{status: "BLOCKED", decision: ., problems: ["rollback não exato; nada foi desfeito"]}' \
      "$RUN_DIR/decision.json" >"$RUN_DIR/rollback-check.json" 2>/dev/null ||
      echo '{"status":"BLOCKED","problems":["decisão de rollback ilegível; nada foi desfeito"]}' \
        >"$RUN_DIR/rollback-check.json"
    return "$decision_rc"
  fi
  RESTORE_MUTATED=1
  if [[ "$(jq -r '.easypanel' "$RUN_DIR/decision.json")" == "restore_resources" ]]; then
    update_easypanel "$name" "$(jq -c '.before.easypanel.resources' "$receipt")" || true
  fi
  if [[ "$(jq -r '.swarm' "$RUN_DIR/decision.json")" == "swarm_rollback" ]]; then
    remote "$(rollback_cmd "$swarm")" >/dev/null || true
  fi
  wait_converged "$swarm" restored || true
  read_state "$swarm" restored
  python3 "$LOGIC" check-rollback --receipt "$receipt" \
    --inspect "$RUN_DIR/restored.inspect.json" \
    --easypanel "$RUN_DIR/restored.easypanel.json" \
    --running "$RUN_DIR/restored.running.txt" >"$RUN_DIR/rollback-check.json"
}

# shellcheck disable=SC2329 # chamada pelo trap EXIT
cleanup() {
  local status="$?"
  trap - EXIT
  if [[ "$MUTATION_STARTED" == "1" && "$FINISHED" != "1" ]]; then
    echo "a aplicação parou no meio; restaurando os recursos de antes" >&2
    write_receipt applied "$RUN_DIR/partial.json" || true
    if restore "$RUN_DIR/partial.json" "${SWARM_SERVICE:-}" "$SERVICE"; then
      write_receipt rolled_back "$RECEIPT_OUT" \
        --rollback-check "$RUN_DIR/rollback-check.json" || true
    else
      write_receipt rollback_failed "$RECEIPT_OUT" \
        --rollback-check "$RUN_DIR/rollback-check.json" || true
      echo "CRITICAL: rollback dos recursos não foi provado; ver $RECEIPT_OUT" >&2
    fi
    status=1
  fi
  cleanup_manaloom_secure_ssh
  rm -rf "$RUN_DIR"
  exit "$status"
}
trap cleanup EXIT

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"

if [[ "$MODE" == "rollback" ]]; then
  SERVICE="$(jq -er '.service' "$ROLLBACK_RECEIPT")"
  SWARM_SERVICE="$(jq -er '.swarm_service' "$ROLLBACK_RECEIPT")"
  [[ "$SWARM_SERVICE" == "${PROJECT}_$SERVICE" ]] || {
    echo "receipt de outro projeto: $SWARM_SERVICE" >&2; exit 2; }
  [[ "$(jq -r '.kind' "$ROLLBACK_RECEIPT")" == "brewtact-capacity-resources-receipt" &&
     "$(jq -r '.status' "$ROLLBACK_RECEIPT")" == "applied" ]] || {
    echo "--rollback exige o receipt de uma aplicação (status applied)" >&2; exit 2; }
  cp "$ROLLBACK_RECEIPT" "$PLAN_FILE"
  RECEIPT_OUT="$RECEIPT_DIR/capacidade-$SERVICE-rollback-$STAMP.json"
  restore_rc=0
  restore "$ROLLBACK_RECEIPT" "$SWARM_SERVICE" "$SERVICE" || restore_rc=$?
  if [[ "$restore_rc" != "0" && "$RESTORE_MUTATED" == "0" ]]; then
    echo "BLOCKED: o rollback não seria exato ou o estado não foi lido; nada mudou" >&2
    exit "$restore_rc"
  fi
  if [[ "$restore_rc" == "0" ]]; then
    write_receipt rolled_back "$RECEIPT_OUT" --rollback-check "$RUN_DIR/rollback-check.json"
    jq -c '{status: "rolled_back", service: .service, receipt: $receipt}' \
      --arg receipt "$RECEIPT_OUT" "$RECEIPT_OUT"
    exit 0
  fi
  write_receipt rollback_failed "$RECEIPT_OUT" --rollback-check "$RUN_DIR/rollback-check.json"
  echo "CRITICAL: rollback não provado; ver $RECEIPT_OUT" >&2
  exit 1
fi

SWARM_SERVICE="${PROJECT}_$SERVICE"
RECEIPT_OUT="$RECEIPT_DIR/capacidade-$SERVICE-$STAMP.json"
read_state "$SWARM_SERVICE" before
plan_rc=0
python3 "$LOGIC" plan --service "$SERVICE" --snapshot "$SNAPSHOT" \
  --easypanel "$RUN_DIR/before.easypanel.json" --inspect "$RUN_DIR/before.inspect.json" \
  --running "$RUN_DIR/before.running.txt" --policy "$POLICY" >"$PLAN_FILE" || plan_rc=$?
cat "$PLAN_FILE"
if [[ "$MODE" == "plan" ]]; then
  exit "$plan_rc"
fi
if [[ "$plan_rc" == "3" ]]; then
  write_receipt blocked "$RECEIPT_OUT"
  echo "BLOCKED pelo preflight; nada mudou ($RECEIPT_OUT)" >&2
  exit 3
fi
if [[ "$plan_rc" != "0" ]]; then
  exit "$plan_rc"
fi
if [[ "$(jq -r '.already_applied // false' "$PLAN_FILE")" == "true" ]]; then
  echo "os recursos de $SERVICE já são os da política; nada mudou" >&2
  exit 0
fi

MUTATION_STARTED=1
update_easypanel "$SERVICE" "$(jq -c '.desired.easypanel' "$PLAN_FILE")"
remote "$(update_cmd \
  "$(jq -er '.desired.flags.limit_memory' "$PLAN_FILE")" \
  "$(jq -er '.desired.flags.reserve_memory' "$PLAN_FILE")" \
  "$(jq -er '.desired.flags.limit_cpu' "$PLAN_FILE")" \
  "$(jq -er '.desired.flags.reserve_cpu' "$PLAN_FILE")" \
  "$SWARM_SERVICE")" >/dev/null
wait_converged "$SWARM_SERVICE" applied || true
read_state "$SWARM_SERVICE" after
apply_rc=0
python3 "$LOGIC" check-apply --plan "$PLAN_FILE" \
  --inspect "$RUN_DIR/after.inspect.json" --easypanel "$RUN_DIR/after.easypanel.json" \
  --running "$RUN_DIR/after.running.txt" >"$RUN_DIR/apply-check.json" || apply_rc=$?
if [[ "$apply_rc" == "0" ]]; then
  FINISHED=1
  write_receipt applied "$RECEIPT_OUT" --apply-check "$RUN_DIR/apply-check.json"
  jq -c '{status: "applied", service: .service, receipt: $receipt}' \
    --arg receipt "$RECEIPT_OUT" "$RECEIPT_OUT"
  exit 0
fi

echo "a conferência depois de aplicar falhou; restaurando" >&2
cat "$RUN_DIR/apply-check.json" >&2
write_receipt applied "$RUN_DIR/partial.json" --apply-check "$RUN_DIR/apply-check.json"
FINISHED=1
if restore "$RUN_DIR/partial.json" "$SWARM_SERVICE" "$SERVICE"; then
  write_receipt rolled_back "$RECEIPT_OUT" --apply-check "$RUN_DIR/apply-check.json" \
    --rollback-check "$RUN_DIR/rollback-check.json"
  echo "rollback dos recursos provado: spec e EasyPanel iguais aos de antes ($RECEIPT_OUT)" >&2
else
  write_receipt rollback_failed "$RECEIPT_OUT" --apply-check "$RUN_DIR/apply-check.json" \
    --rollback-check "$RUN_DIR/rollback-check.json"
  echo "CRITICAL: rollback dos recursos não foi provado; ver $RECEIPT_OUT" >&2
fi
exit 1
