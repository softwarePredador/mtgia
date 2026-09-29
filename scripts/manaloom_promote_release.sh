#!/usr/bin/env bash
# BT-REL-001 (D-13): transação de promoção full-stack com rollback comprovado. Na
# produção, quem roda é a coordenação, no lote de deploy, com a palavra do dono.
#
# Uso:
#   scripts/manaloom_promote_release.sh                              descreve, sem conectar
#   scripts/manaloom_promote_release.sh --status --receipt-dir D     só lê os diários locais
#   scripts/manaloom_promote_release.sh --execute --preflight --sha SHA [--surfaces a,b]
#       [--capacity-snapshot F]
#   scripts/manaloom_promote_release.sh --execute --promote --sha SHA --receipt-dir D
#       --capacity-snapshot F [--surfaces a,b]
#   scripts/manaloom_promote_release.sh --execute --resolve DIARIO --receipt-dir D
#       --reason TEXTO
#
# As superfícies e a ordem vêm de server/config/release_promotion.json (D-13:
# backend, ops, site, /app e Android); --surfaces escolhe um subconjunto, sempre
# nessa ordem. O --preflight só lê. O --promote e o --resolve exigem
# MANALOOM_CONFIRM_LIVE_MUTATIONS de quem chama, e o --promote repassa o ambiente
# aos deploys de cada superfície (a herança do e-mail do backend fica com quem
# chama). Todo modo com --execute exige a âncora de host
# (MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256), a do EasyPanel
# (MANALOOM_EXPECTED_EASYPANEL_BASE_URL_SHA256), a chave SSH do deploy e o token do
# EasyPanel (server/.env).
#
# A promoção é tudo ou nada. Cada passo entra no diário
# (D/promocao-<sha>-<carimbo>.jsonl) antes de acontecer; se uma superfície falha, as
# já promovidas voltam na ordem inversa, e cada volta é provada. Enquanto um diário
# estiver sem fim ou com rollback não provado, o marcador D/EM_ANDAMENTO fica e
# nenhuma promoção começa: a falha nunca some.
#
# Códigos: 0 feito (ou preflight PASS); 1 falhou (rollback provado ou não, ver o
# diário); 2 entrada ou ambiente recusado, nada mudou; 3 BLOCKED pelo preflight,
# nada mudou; 4 transação anterior aberta (--status e --promote).
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="${MANALOOM_NEW_SERVER_ENV:-$ROOT_DIR/server/.env}"
LOGIC="$ROOT_DIR/scripts/manaloom_promote_release.py"
READER="$ROOT_DIR/scripts/manaloom_capacity_resources.py"
CAPACITY="$ROOT_DIR/scripts/manaloom_capacity_policy.py"
WAIT_ATTEMPTS="${MANALOOM_PROMOTE_WAIT_ATTEMPTS:-90}"
WAIT_SECONDS="${MANALOOM_PROMOTE_WAIT_SECONDS:-2}"
PROBE_ATTEMPTS="${MANALOOM_PROMOTE_PROBE_ATTEMPTS:-30}"
EXECUTE=0
MODE=""
SHA=""
SURFACES=""
RECEIPT_DIR=""
SNAPSHOT=""
RESOLVE_JOURNAL=""
REASON=""

usage() {
  sed -n '2,33p' "$0" | sed 's/^# \{0,1\}//'
}

while (( $# > 0 )); do
  case "$1" in
    --execute) EXECUTE=1; shift ;;
    --preflight) MODE=preflight; shift ;;
    --promote) MODE=promote; shift ;;
    --status) MODE=status; shift ;;
    --resolve) MODE=resolve; RESOLVE_JOURNAL="${2:-}"; shift 2 ;;
    --sha) SHA="${2:-}"; shift 2 ;;
    --surfaces) SURFACES="${2:-}"; shift 2 ;;
    --receipt-dir) RECEIPT_DIR="${2:-}"; shift 2 ;;
    --capacity-snapshot) SNAPSHOT="${2:-}"; shift 2 ;;
    --reason) REASON="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "argumento desconhecido: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# Os únicos comandos que esta ferramenta manda para o host; os deploys de cada
# superfície têm os seus. O contrato (server/test/release_promotion_test.py)
# confere cada chamada.
inspect_cmd() { printf "docker service inspect '%s'" "$1"; }
running_cmd() {
  printf "docker service ps '%s' --filter desired-state=running --format '{{.Image}}|{{.CurrentState}}'" "$1"
}
rollback_cmd() { printf "docker service rollback --detach '%s'" "$1"; }

require_durable_dir() {
  local label="$1"
  [[ -n "$RECEIPT_DIR" && -d "$RECEIPT_DIR" ]] || {
    echo "$label exige um --receipt-dir existente" >&2; exit 2; }
  RECEIPT_DIR="$(cd "$RECEIPT_DIR" && pwd -P)"
  if python3 - "$RECEIPT_DIR" <<'PY'
import re
import sys

temporary = re.compile(
    r"(^|/)(tmp|private/tmp|var/folders)/|(^|/)\.claude/worktrees/|(^|/)worktrees?/")
raise SystemExit(0 if temporary.search(sys.argv[1] + "/") else 1)
PY
  then
    echo "o diário tem de ficar num diretório durável, não em $RECEIPT_DIR" >&2
    exit 2
  fi
}

if [[ "$MODE" == "status" ]]; then
  require_durable_dir --status
  rc=0
  python3 "$LOGIC" latest-open --dir "$RECEIPT_DIR" || rc=$?
  for journal in "$RECEIPT_DIR"/promocao-*.jsonl; do
    [[ -f "$journal" ]] || continue
    python3 "$LOGIC" journal-status --journal "$journal" || true
  done
  exit "$rc"
fi

if [[ "$EXECUTE" != "1" ]]; then
  python3 - "$LOGIC" <<'PY'
import json
import subprocess
import sys

rows = subprocess.run([sys.executable, sys.argv[1], "plan"], capture_output=True, text=True,
                      check=True).stdout.splitlines()
surfaces = []
for row in rows:
    surface, service, swarm, deploy, kind, url, field, fallback = row.split("\t")
    surfaces.append({"id": surface, "service": service, "swarm_service": swarm,
                     "deploy": deploy, "probe": None if kind == "none" else kind,
                     "probe_url": url or None})
print(json.dumps({
    "status": "dry_run",
    "task": "BT-REL-001",
    "order": [surface["id"] for surface in surfaces],
    "surfaces": surfaces,
    "remote_commands": [
        "docker service inspect '<servico>'",
        "docker service ps '<servico>' --filter desired-state=running "
        "--format '{{.Image}}|{{.CurrentState}}'",
        "docker service rollback --detach '<servico>'",
    ],
    "easypanel": ["projects.listProjectsAndServices", "services.app.updateSourceImage",
                  "services.app.deployService"],
    "execute": "--execute --preflight|--promote --sha <sha> [--surfaces a,b] "
               "[--receipt-dir <dir>] [--capacity-snapshot <arquivo>] ou "
               "--execute --resolve <diario> --receipt-dir <dir> --reason <texto>",
}, ensure_ascii=False, indent=2))
PY
  exit 0
fi

case "$MODE" in
  preflight|promote)
    [[ "$SHA" =~ ^[0-9a-f]{40}$ ]] || { echo "--$MODE exige --sha com o SHA completo" >&2; exit 2; }
    ;;
  resolve)
    [[ -f "$RESOLVE_JOURNAL" && -n "$REASON" ]] || {
      echo "--resolve exige um diário existente e --reason" >&2; exit 2; }
    ;;
  *) echo "--execute exige --preflight, --promote ou --resolve" >&2; exit 2 ;;
esac
python3 "$LOGIC" validate-config >/dev/null || {
  echo "política de promoção inválida (server/config/release_promotion.json)" >&2; exit 2; }
PLAN_TSV="$(python3 "$LOGIC" plan --surfaces "$SURFACES")" || {
  echo "superfícies inválidas: $SURFACES" >&2; exit 2; }
if [[ "$MODE" != "preflight" ]]; then
  require_durable_dir "--$MODE"
  # shellcheck source=scripts/lib/manaloom_mutation_guard.sh
  source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
  require_live_mutation_approval "BrewTact full-stack release promotion"
fi
if [[ "$MODE" == "promote" ]]; then
  [[ -f "$SNAPSHOT" ]] || {
    echo "--promote exige --capacity-snapshot (BT-CAP-001, no máximo 30 minutos)" >&2; exit 2; }
  if [[ -e "$RECEIPT_DIR/EM_ANDAMENTO" ]]; then
    echo "BLOCKED: há uma promoção em andamento ou interrompida: $(cat "$RECEIPT_DIR/EM_ANDAMENTO")" >&2
    exit 4
  fi
  open_rc=0
  python3 "$LOGIC" latest-open --dir "$RECEIPT_DIR" >/dev/null || open_rc=$?
  if [[ "$open_rc" != "0" ]]; then
    python3 "$LOGIC" latest-open --dir "$RECEIPT_DIR" >&2 || true
    echo "BLOCKED: diário anterior sem fim ou com rollback não provado; resolva antes" >&2
    exit 4
  fi
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

RUN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/manaloom-promote.XXXXXX")"
chmod 700 "$RUN_DIR"
JOURNAL=""
JOURNAL_OPEN=0
JOURNAL_ENDED=0
STARTED=()
COMMITTED=()

remote() { ssh -o BatchMode=yes -i "$SSH_KEY" "$SSH_HOST" "$1"; }

trpc_post() {
  curl -fsS --proto '=https' --tlsv1.2 \
    -H "Authorization: Bearer $EASYPANEL_API_TOKEN" \
    -H 'Content-Type: application/json' \
    --data "$(jq -cn --argjson input "$2" '{json:$input}')" \
    "$EASYPANEL_BASE_URL/api/trpc/$1"
}

# Uma linha do plano por superfície: id, serviço, serviço do Swarm, deploy, sonda.
plan_row() { awk -F'\t' -v id="$1" '$1 == id' <<<"$PLAN_TSV"; }
plan_field() { plan_row "$1" | cut -f"$2"; }

# Marcador público da superfície: o campo pedido, o SHA-256 do corpo ou o status HTTP.
probe_marker() {
  local id="$1" kind url field fallback body code value
  kind="$(plan_field "$id" 5)"
  url="$(plan_field "$id" 6)"
  field="$(plan_field "$id" 7)"
  fallback="$(plan_field "$id" 8)"
  case "$kind" in
    none) printf '' ;;
    status_only)
      code="$(curl -sS --proto '=https' --max-time 20 -o /dev/null -w '%{http_code}' "$url" 2>/dev/null || true)"
      printf 'http:%s' "${code:-000}"
      ;;
    json_field)
      if body="$(curl -fsS --proto '=https' --max-time 20 "$url" 2>/dev/null)" &&
         value="$(jq -er --arg field "$field" '.[$field]' <<<"$body" 2>/dev/null)"; then
        printf 'field:%s' "$value"
      fi
      ;;
    body_sha256)
      if body="$(curl -fsS --proto '=https' --max-time 20 "$url" 2>/dev/null)"; then
        printf 'sha256:%s' "$(printf '%s' "$body" | shasum -a 256 | awk '{print $1}')"
      elif [[ -n "$fallback" ]] &&
           body="$(curl -fsS --proto '=https' --max-time 20 "$fallback" 2>/dev/null)"; then
        printf 'fallback-sha256:%s' "$(printf '%s' "$body" | shasum -a 256 | awk '{print $1}')"
      fi
      ;;
  esac
}

# Leitura redigida: nenhum valor de env chega ao disco.
read_view() {
  local id="$1" label="$2" swarm marker
  swarm="$(plan_field "$id" 3)"
  trpc_post projects.listProjectsAndServices null |
    python3 "$READER" redact-easypanel --project "$PROJECT" \
      >"$RUN_DIR/$id.$label.easypanel.json" || return 1
  remote "$(inspect_cmd "$swarm")" |
    python3 "$READER" redact-inspect >"$RUN_DIR/$id.$label.inspect.json" || return 1
  remote "$(running_cmd "$swarm")" >"$RUN_DIR/$id.$label.running.txt" || return 1
  marker="$(probe_marker "$id")"
  python3 "$LOGIC" view --surface "$id" \
    --inspect "$RUN_DIR/$id.$label.inspect.json" \
    --easypanel "$RUN_DIR/$id.$label.easypanel.json" \
    --running "$RUN_DIR/$id.$label.running.txt" \
    --marker "$marker" >"$RUN_DIR/$id.$label.view.json" || return 1
}

wait_converged() {
  local id="$1" swarm attempt rc
  swarm="$(plan_field "$id" 3)"
  for attempt in $(seq 1 "$WAIT_ATTEMPTS"); do
    rc=0
    remote "$(inspect_cmd "$swarm")" |
      python3 "$READER" redact-inspect >"$RUN_DIR/$id.wait.inspect.json" || rc=1
    remote "$(running_cmd "$swarm")" >"$RUN_DIR/$id.wait.running.txt" || rc=1
    if [[ "$rc" == "0" ]]; then
      python3 "$READER" converged --inspect "$RUN_DIR/$id.wait.inspect.json" \
        --running "$RUN_DIR/$id.wait.running.txt" >/dev/null || rc=$?
      case "$rc" in
        0) return 0 ;;
        3) return 1 ;;
      esac
    fi
    if (( attempt < WAIT_ATTEMPTS )); then sleep "$WAIT_SECONDS"; fi
  done
  return 1
}

# Espera a sonda pública mostrar o marcador esperado (propagação do proxy).
wait_marker() {
  local id="$1" expected="$2" attempt
  [[ "$(plan_field "$id" 5)" != "none" ]] || return 0
  for attempt in $(seq 1 "$PROBE_ATTEMPTS"); do
    [[ "$(probe_marker "$id")" == "$expected" ]] && return 0
    if (( attempt < PROBE_ATTEMPTS )); then sleep "$WAIT_SECONDS"; fi
  done
  return 1
}

event() {
  local name="$1" data="$2"
  printf '%s' "$data" >"$RUN_DIR/event.json"
  python3 "$LOGIC" journal-append --journal "$JOURNAL" --event "$name" \
    --data-file "$RUN_DIR/event.json" >/dev/null
}

# Volta uma superfície à linha de base, se der para voltar exato; prova depois.
compensate_surface() {
  local id="$1" swarm decision_rc=0 image
  swarm="$(plan_field "$id" 3)"
  event compensation_started "$(jq -cn --arg surface "$id" '{surface:$surface}')"
  if ! read_view "$id" restore; then
    event surface_restore_failed "$(jq -cn --arg surface "$id" \
      '{surface:$surface, problems:["não li o estado da superfície"]}')"
    return 1
  fi
  python3 "$LOGIC" compensation-decision --surface "$id" \
    --baseline "$RUN_DIR/$id.baseline.view.json" \
    --view "$RUN_DIR/$id.restore.view.json" >"$RUN_DIR/$id.decision.json" || decision_rc=$?
  if [[ "$decision_rc" != "0" ]]; then
    event surface_restore_failed "$(jq -c --arg surface "$id" \
      '{surface:$surface, decision:., problems:(.reasons // [.error // "decisão ilegível"])}' \
      "$RUN_DIR/$id.decision.json" 2>/dev/null ||
      jq -cn --arg surface "$id" '{surface:$surface, problems:["decisão ilegível"]}')"
    return 1
  fi
  image="$(jq -r '.image' "$RUN_DIR/$id.decision.json")"
  if [[ "$(jq -r '.easypanel' "$RUN_DIR/$id.decision.json")" == "restore_image" ]]; then
    trpc_post services.app.updateSourceImage "$(jq -cn --arg project "$PROJECT" \
      --arg service "$(plan_field "$id" 2)" --arg image "$image" \
      '{projectName:$project,serviceName:$service,image:$image}')" >/dev/null || true
  fi
  case "$(jq -r '.swarm' "$RUN_DIR/$id.decision.json")" in
    swarm_rollback) remote "$(rollback_cmd "$swarm")" >/dev/null || true ;;
    easypanel_redeploy)
      trpc_post services.app.deployService "$(jq -cn --arg project "$PROJECT" \
        --arg service "$(plan_field "$id" 2)" \
        '{projectName:$project,serviceName:$service,forceRebuild:false}')" >/dev/null || true
      ;;
  esac
  wait_converged "$id" || true
  wait_marker "$id" "$(jq -r '.marker' "$RUN_DIR/$id.baseline.view.json")" || true
  if read_view "$id" restored &&
     python3 "$LOGIC" check-restored --surface "$id" \
       --baseline "$RUN_DIR/$id.baseline.view.json" \
       --view "$RUN_DIR/$id.restored.view.json" >"$RUN_DIR/$id.restored.json"; then
    event surface_restored "$(jq -c --arg surface "$id" \
      --slurpfile decision "$RUN_DIR/$id.decision.json" \
      '{surface:$surface, level:.level, swarm:$decision[0].swarm, easypanel:$decision[0].easypanel}' \
      "$RUN_DIR/$id.restored.json")"
    return 0
  fi
  event surface_restore_failed "$(jq -c --arg surface "$id" \
    '{surface:$surface, problems:(.problems // [.error // "conferência ilegível"])}' \
    "$RUN_DIR/$id.restored.json" 2>/dev/null ||
    jq -cn --arg surface "$id" '{surface:$surface, problems:["conferência ilegível"]}')"
  return 1
}

# Desfaz, na ordem inversa, tudo o que começou; devolve 0 só se tudo voltou provado.
compensate_all() {
  local failed=0 index
  for (( index=${#STARTED[@]}-1; index>=0; index-- )); do
    compensate_surface "${STARTED[$index]}" || failed=1
  done
  return "$failed"
}

end_transaction() {
  local status="$1"
  event end "$(jq -cn --arg status "$status" '{status:$status}')"
  JOURNAL_ENDED=1
  if [[ "$status" != "rollback_failed" ]]; then
    rm -f "$RECEIPT_DIR/EM_ANDAMENTO"
  fi
  python3 "$LOGIC" journal-status --journal "$JOURNAL" >"$RECEIPT_DIR/${JOURNAL_NAME%.jsonl}.json" || true
  chmod 600 "$RECEIPT_DIR/${JOURNAL_NAME%.jsonl}.json"
}

rollback_transaction() {
  if compensate_all; then
    end_transaction rolled_back
    echo "promoção desfeita: todas as superfícies voltaram à linha de base, provadas ($JOURNAL)" >&2
    return 0
  fi
  end_transaction rollback_failed
  echo "CRITICAL: o rollback da promoção não foi provado; o marcador EM_ANDAMENTO fica ($JOURNAL)" >&2
  return 1
}

# shellcheck disable=SC2329 # chamada pelos traps
finish() {
  local status="$?"
  trap - EXIT TERM INT HUP
  if [[ "$JOURNAL_OPEN" == "1" && "$JOURNAL_ENDED" != "1" ]]; then
    echo "a promoção parou no meio (saída $status); desfazendo o que começou" >&2
    event aborted "$(jq -cn --argjson status "$status" '{exit_status:$status}')" || true
    rollback_transaction || true
    status=1
  fi
  cleanup_manaloom_secure_ssh
  rm -rf "$RUN_DIR"
  exit "$status"
}
trap finish EXIT
trap 'exit 143' TERM
trap 'exit 130' INT
trap 'exit 129' HUP

# ------------------------------------------------------------ resolve

if [[ "$MODE" == "resolve" ]]; then
  state_rc=0
  python3 "$LOGIC" journal-status --journal "$RESOLVE_JOURNAL" >"$RUN_DIR/state.json" || state_rc=$?
  if [[ "$state_rc" != "1" && "$state_rc" != "4" ]]; then
    echo "o diário não está aberto (nada a resolver): $(cat "$RUN_DIR/state.json")" >&2
    exit 2
  fi
  JOURNAL="$RESOLVE_JOURNAL"
  python3 - "$JOURNAL" "$RUN_DIR" <<'PY'
import json
import sys
from pathlib import Path

records = [json.loads(line) for line in Path(sys.argv[1]).read_text(encoding="utf-8").splitlines()
           if line.strip()]
run = Path(sys.argv[2])
begin = records[0]["data"]
for surface, baseline in begin["baselines"].items():
    (run / f"{surface}.baseline.view.json").write_text(json.dumps(baseline), encoding="utf-8")
for record in records:
    if record["event"] == "surface_committed":
        data = record["data"]
        (run / f"{data['surface']}.committed.json").write_text(
            json.dumps(data["committed"]), encoding="utf-8")
(run / "surfaces.txt").write_text("\n".join(begin["surfaces"]) + "\n", encoding="utf-8")
PY
  PLAN_TSV="$(python3 "$LOGIC" plan --surfaces "$(paste -sd, "$RUN_DIR/surfaces.txt")")"
  states="{}"
  unresolved=0
  while IFS= read -r id; do
    [[ -n "$id" ]] || continue
    read_view "$id" now || { unresolved=1; continue; }
    if python3 "$LOGIC" check-restored --surface "$id" \
         --baseline "$RUN_DIR/$id.baseline.view.json" \
         --view "$RUN_DIR/$id.now.view.json" >/dev/null; then
      states="$(jq -c --arg id "$id" '. + {($id): "baseline"}' <<<"$states")"
    elif [[ -f "$RUN_DIR/$id.committed.json" ]] &&
         python3 "$LOGIC" check-converged --surface "$id" \
           --committed "$RUN_DIR/$id.committed.json" \
           --view "$RUN_DIR/$id.now.view.json" >/dev/null; then
      states="$(jq -c --arg id "$id" '. + {($id): "committed"}' <<<"$states")"
    else
      states="$(jq -c --arg id "$id" '. + {($id): "unknown"}' <<<"$states")"
      unresolved=1
    fi
  done <"$RUN_DIR/surfaces.txt"
  if [[ "$unresolved" != "0" ]]; then
    echo "BLOCKED: há superfície fora da linha de base e do promovido: $states" >&2
    exit 3
  fi
  event resolved "$(jq -cn --arg reason "$REASON" --argjson surfaces "$states" \
    '{reason:$reason, surfaces:$surfaces}')"
  if [[ -f "$RECEIPT_DIR/EM_ANDAMENTO" &&
        "$(cat "$RECEIPT_DIR/EM_ANDAMENTO")" == "$(basename "$JOURNAL")" ]]; then
    rm -f "$RECEIPT_DIR/EM_ANDAMENTO"
  fi
  jq -cn --arg journal "$JOURNAL" --argjson surfaces "$states" \
    '{status:"resolved", journal:$journal, surfaces:$surfaces}'
  exit 0
fi

# ------------------------------------------------------------ preflight (só leitura)

git -C "$ROOT_DIR" cat-file -e "$SHA^{commit}" 2>/dev/null || {
  echo "SHA desconhecido no repositório: $SHA" >&2; exit 2; }
[[ "$(git -C "$ROOT_DIR" rev-parse HEAD)" == "$SHA" ]] || {
  echo "o checkout não está no SHA pedido: $(git -C "$ROOT_DIR" rev-parse HEAD)" >&2; exit 2; }
[[ -z "$(git -C "$ROOT_DIR" status --porcelain --untracked-files=all)" ]] || {
  echo "checkout sujo: a promoção sai só de SHA limpo" >&2; exit 2; }
[[ "$(git -C "$ROOT_DIR" rev-parse origin/master 2>/dev/null || true)" == "$SHA" ]] || {
  echo "o SHA pedido não é o origin/master (os deploys exigem)" >&2; exit 2; }

# shellcheck source=scripts/lib/manaloom_release_capabilities_contract.sh
source "$ROOT_DIR/scripts/lib/manaloom_release_capabilities_contract.sh"
manaloom_load_release_capabilities_from_git "$ROOT_DIR" "$SHA"
manaloom_resolve_public_app_release_mode "$MANALOOM_RELEASE_CAPABILITIES_POLICY_JSON"
RELEASE_MODE="$MANALOOM_PUBLIC_APP_RELEASE_MODE"

capacity_status="not_checked"
if [[ -n "$SNAPSHOT" ]]; then
  if python3 "$CAPACITY" preflight --snapshot "$SNAPSHOT" >"$RUN_DIR/capacity.json"; then
    capacity_status="PASS"
  else
    capacity_status="BLOCKED"
  fi
fi

preflight_failed=0
blocked_reasons="[]"
[[ "$capacity_status" != "BLOCKED" ]] || {
  preflight_failed=1
  blocked_reasons="$(jq -c '. + ["preflight de capacidade BLOCKED"]' <<<"$blocked_reasons")"; }
SURFACE_IDS=()
while IFS=$'\t' read -r id _; do
  [[ -n "$id" ]] || continue
  SURFACE_IDS+=("$id")
  if ! read_view "$id" baseline; then
    preflight_failed=1
    blocked_reasons="$(jq -c --arg id "$id" '. + [("não li a linha de base de " + $id)]' <<<"$blocked_reasons")"
    continue
  fi
  if ! python3 "$LOGIC" baseline-check --surface "$id" \
       --view "$RUN_DIR/$id.baseline.view.json" >"$RUN_DIR/$id.baseline.check.json"; then
    preflight_failed=1
    blocked_reasons="$(jq -c --slurpfile check "$RUN_DIR/$id.baseline.check.json" \
      '. + ($check[0].problems // [$check[0].error])' <<<"$blocked_reasons")"
  fi
done <<<"$PLAN_TSV"

baselines="$(for id in "${SURFACE_IDS[@]}"; do
  if [[ -f "$RUN_DIR/$id.baseline.view.json" ]]; then
    jq -c --arg id "$id" '{($id): .}' "$RUN_DIR/$id.baseline.view.json"
  fi
done | jq -cs 'add // {}')"
summary="$(jq -cn --arg sha "$SHA" --arg mode "$RELEASE_MODE" --arg capacity "$capacity_status" \
  --argjson surfaces "$(printf '%s\n' "${SURFACE_IDS[@]}" | jq -Rsc 'split("\n") | map(select(length > 0))')" \
  --argjson reasons "$blocked_reasons" --argjson baselines "$baselines" \
  '{sha:$sha, release_mode:$mode, capacity:$capacity, surfaces:$surfaces,
    status:(if ($reasons | length) == 0 then "PASS" else "BLOCKED" end), reasons:$reasons,
    baselines:$baselines}')"

if [[ "$MODE" == "preflight" ]]; then
  jq -c 'del(.baselines) + {baseline_images: (.baselines | map_values(.spec.image))}' <<<"$summary"
  [[ "$preflight_failed" == "0" ]] && exit 0
  exit 3
fi

# ------------------------------------------------------------ promoção

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
JOURNAL_NAME="promocao-${SHA:0:12}-$STAMP.jsonl"
JOURNAL="$RECEIPT_DIR/$JOURNAL_NAME"
printf '%s\n' "$JOURNAL_NAME" >"$RECEIPT_DIR/EM_ANDAMENTO"
chmod 600 "$RECEIPT_DIR/EM_ANDAMENTO"
event begin "$(jq -c '{sha, release_mode, capacity, surfaces, baselines,
  tool: "scripts/manaloom_promote_release.sh"}' <<<"$summary")"
JOURNAL_OPEN=1
if [[ "$preflight_failed" != "0" ]]; then
  event end "$(jq -c '{status: "blocked", reasons}' <<<"$summary")"
  JOURNAL_ENDED=1
  rm -f "$RECEIPT_DIR/EM_ANDAMENTO"
  python3 "$LOGIC" journal-status --journal "$JOURNAL" >"$RECEIPT_DIR/${JOURNAL_NAME%.jsonl}.json" || true
  chmod 600 "$RECEIPT_DIR/${JOURNAL_NAME%.jsonl}.json"
  jq -c '{status: "BLOCKED", reasons}' <<<"$summary"
  echo "BLOCKED pelo preflight; nada mudou ($JOURNAL)" >&2
  exit 3
fi

for id in "${SURFACE_IDS[@]}"; do
  event surface_started "$(jq -cn --arg surface "$id" '{surface:$surface}')"
  STARTED+=("$id")
  deploy="$(plan_field "$id" 4)"
  log="$RECEIPT_DIR/${JOURNAL_NAME%.jsonl}-$id.log"
  echo "== $(date -u +%T) $id: $deploy (log em $log)" >&2
  deploy_rc=0
  : >"$log"
  chmod 600 "$log"
  MANALOOM_RELEASE_SOURCE_SHA="$SHA" /bin/bash "$ROOT_DIR/$deploy" \
    >"$RUN_DIR/$id.deploy.out" 2>>"$log" || deploy_rc=$?
  check_rc=1
  if [[ "$deploy_rc" == "0" ]]; then
    # A sonda pública pode demorar a mostrar o novo (proxy): confere até PROBE_ATTEMPTS.
    for attempt in $(seq 1 "$PROBE_ATTEMPTS"); do
      if read_view "$id" deployed &&
         python3 "$LOGIC" check-deployed --surface "$id" --sha "$SHA" \
           --release-mode "$RELEASE_MODE" \
           --baseline "$RUN_DIR/$id.baseline.view.json" \
           --view "$RUN_DIR/$id.deployed.view.json" \
           --result "$RUN_DIR/$id.deploy.out" >"$RUN_DIR/$id.check.json"; then
        check_rc=0
        break
      fi
      if (( attempt < PROBE_ATTEMPTS )); then sleep "$WAIT_SECONDS"; fi
    done
  fi
  if [[ "$check_rc" == "0" ]]; then
    event surface_committed "$(jq -c --arg surface "$id" \
      '{surface:$surface, committed:.committed}' "$RUN_DIR/$id.check.json")"
    COMMITTED+=("$id")
    continue
  fi
  event surface_failed "$(jq -cn --arg surface "$id" --argjson rc "$deploy_rc" \
    --arg tail "$(tail -n 20 "$log" 2>/dev/null || true)" \
    --argjson check "$(jq -c '.' "$RUN_DIR/$id.check.json" 2>/dev/null || echo null)" \
    '{surface:$surface, deploy_exit:$rc, check:$check, log_tail:$tail}')"
  echo "$id falhou (saída $deploy_rc); desfazendo a promoção na ordem inversa" >&2
  rollback_transaction || exit 1
  exit 1
done

# Todas convergem juntas: nenhuma superfície mudou enquanto as seguintes subiam.
converge_failed=0
for id in "${COMMITTED[@]}"; do
  jq -c --arg id "$id" 'select(.event == "surface_committed" and .data.surface == $id)
    | .data.committed' "$JOURNAL" >"$RUN_DIR/$id.committed.json"
  if ! read_view "$id" final ||
     ! python3 "$LOGIC" check-converged --surface "$id" \
       --committed "$RUN_DIR/$id.committed.json" --view "$RUN_DIR/$id.final.view.json" \
       >"$RUN_DIR/$id.final.json"; then
    converge_failed=1
  fi
done
if [[ "$converge_failed" != "0" ]]; then
  event surface_failed "$(jq -cn '{surface:"*", problems:["as superfícies não convergiram juntas"]}')"
  rollback_transaction || exit 1
  exit 1
fi

# BT-REL-002: same-SHA. O núcleo (same_sha na política) e o que esta transação promoveu
# mostram a identidade do release: SHA completo, produto, superfície, digest da matriz
# commitada no SHA, modo do /app e flags de build. Divergência, ou identidade que não
# se lê, falha fechado e desfaz a promoção.
identity_dir="$RUN_DIR/identity"
mkdir -p "$identity_dir"
promoted_csv="$(IFS=,; printf '%s' "${COMMITTED[*]}")"
git -C "$ROOT_DIR" show "$SHA:server/config/release_capabilities.json" >"$RUN_DIR/policy-at-sha.json"
python3 "$LOGIC" identity-sources --promoted "$promoted_csv" >"$RUN_DIR/identity-sources.tsv"
while IFS=$'\t' read -r id index kind target; do
  [[ -n "$id" ]] || continue
  if [[ "$kind" == "http_json" ]]; then
    code="$(curl -sS --proto '=https' --max-time 20 -o "$identity_dir/$id.$index.body" \
      -w '%{http_code}' "$target" 2>/dev/null || true)"
    printf '%s' "${code:-000}" >"$identity_dir/$id.$index.status"
  else
    remote "$(inspect_cmd "$target")" |
      python3 "$READER" redact-inspect >"$identity_dir/$id.$index.inspect.json" || true
  fi
done <"$RUN_DIR/identity-sources.tsv"
identity_rc=0
python3 "$LOGIC" identity-gate --sha "$SHA" --policy-file "$RUN_DIR/policy-at-sha.json" \
  --dir "$identity_dir" --promoted "$promoted_csv" >"$RUN_DIR/identity.json" || identity_rc=$?
if [[ "$identity_rc" != "0" ]]; then
  event surface_failed "$(jq -ec '{surface:"*", identity:{status, scope, problems}}' \
    "$RUN_DIR/identity.json" 2>/dev/null ||
    jq -cn '{surface:"*", problems:["portão same-SHA ilegível"]}')"
  echo "same-SHA falhou (BT-REL-002); desfazendo a promoção" >&2
  rollback_transaction || exit 1
  exit 1
fi
event converged "$(jq -c --argjson surfaces "$(printf '%s\n' "${COMMITTED[@]}" | jq -Rsc 'split("\n") | map(select(length > 0))')" \
  '{surfaces:$surfaces, identity:{expected, scope, surfaces:(.surfaces | map_values(.fields))}}' \
  "$RUN_DIR/identity.json")"
end_transaction committed
jq -cn --arg journal "$JOURNAL" --arg mode "$RELEASE_MODE" --arg sha "$SHA" \
  '{status:"committed", sha:$sha, release_mode:$mode, journal:$journal}'
