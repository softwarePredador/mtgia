#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_DIR="$ROOT_DIR/server"

PORT="${PORT:-8080}"
API_BASE_URL="${API_BASE_URL:-http://127.0.0.1:${PORT}}"
SERVER_START_TIMEOUT="${SERVER_START_TIMEOUT:-60}"
VALIDATION_CORPUS_PATH="${VALIDATION_CORPUS_PATH:-test/fixtures/optimization_resolution_corpus.json}"
VALIDATION_SELECTION_MODE="${VALIDATION_SELECTION_MODE:-corpus}"
VALIDATION_ARTIFACT_DIR="${VALIDATION_ARTIFACT_DIR:-test/artifacts/optimization_resolution_suite}"
VALIDATION_SUMMARY_JSON_PATH="${VALIDATION_SUMMARY_JSON_PATH:-test/artifacts/optimization_resolution_suite/latest_summary.json}"
VALIDATION_SUMMARY_MD_PATH="${VALIDATION_SUMMARY_MD_PATH:-../RELATORIO_RESOLUCAO_SUITE_COMMANDER_$(date +%Y-%m-%d).md}"

SERVER_PID=""
STARTED_BY_SCRIPT=0

print_header() {
  echo ""
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

api_ready() {
  if ! command -v curl >/dev/null 2>&1; then
    return 1
  fi

  local headers_file body_file
  headers_file="$(mktemp)"
  body_file="$(mktemp)"

  cleanup_probe_files() {
    rm -f "$headers_file" "$body_file"
  }

  local probe_url="${API_BASE_URL%/}/health/ready"
  curl -sS -m 5 -D "$headers_file" -o "$body_file" "$probe_url" >/dev/null 2>&1 || true

  if [[ ! -s "$headers_file" ]]; then
    probe_url="${API_BASE_URL%/}/auth/login"
    curl -sS -m 5 -D "$headers_file" -o "$body_file" -X POST "$probe_url" -H 'Content-Type: application/json' -d '{}' >/dev/null 2>&1 || true
    [[ -s "$headers_file" ]] || {
      cleanup_probe_files
      return 1
    }
  fi

  local content_type status body
  content_type="$(awk -F': ' 'tolower($1)=="content-type"{print tolower($2)}' "$headers_file" | tr -d '\r' | tail -n1)"
  status="$(awk 'toupper($1) ~ /^HTTP\// {code=$2} END{print code}' "$headers_file")"
  body="$(cat "$body_file")"

  cleanup_probe_files

  [[ "$status" =~ ^(200|400|401|403|405|503)$ ]] || return 1
  [[ "$content_type" == application/json* ]] || return 1
  [[ "$body" == *"status"* || "$body" == *"error"* || "$body" == *"token"* || "$body" == *"user"* || "$body" == *"message"* ]] || return 1

  return 0
}

port_in_use() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$port" -sTCP:LISTEN -t >/dev/null 2>&1
    return
  fi

  if command -v nc >/dev/null 2>&1; then
    nc -z localhost "$port" >/dev/null 2>&1
    return
  fi

  return 1
}

select_free_local_port() {
  local from_port="$1"
  local max_tries="${2:-20}"
  local p

  for ((offset = 0; offset <= max_tries; offset++)); do
    p=$((from_port + offset))
    if ! port_in_use "$p"; then
      echo "$p"
      return 0
    fi
  done

  return 1
}

cleanup() {
  if [[ "$STARTED_BY_SCRIPT" -eq 1 && -n "$SERVER_PID" ]]; then
    if kill -0 "$SERVER_PID" >/dev/null 2>&1; then
      print_header "Encerrando API local"
      kill "$SERVER_PID" >/dev/null 2>&1 || true
      wait "$SERVER_PID" 2>/dev/null || true
    fi
  fi
}

trap cleanup EXIT INT TERM

resolve_corpus_count() {
  python3 - "$SERVER_DIR/$VALIDATION_CORPUS_PATH" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
obj = json.loads(path.read_text(encoding="utf-8"))

if isinstance(obj, list):
    decks = obj
elif isinstance(obj, dict):
    decks = obj.get("decks") or obj.get("entries") or []
else:
    decks = []

print(len(decks))
PY
}

print_usage() {
  cat <<EOF
Uso:
  ./scripts/quality_gate_resolution_corpus.sh

Variaveis uteis:
  API_BASE_URL                URL da API (default: http://127.0.0.1:PORT)
  PORT                        porta local para bootstrap do servidor (default: 8080)
  VALIDATION_CORPUS_PATH      corpus a usar (default: test/fixtures/optimization_resolution_corpus.json)
  VALIDATION_ARTIFACT_DIR     pasta de artefatos
  VALIDATION_SUMMARY_JSON_PATH resumo JSON final
  VALIDATION_SUMMARY_MD_PATH   resumo Markdown final

Este gate:
  1. sobe a API local se necessario
  2. conta automaticamente o corpus estavel
  3. roda o runner oficial de resolucao com VALIDATION_LIMIT do corpus
  4. falha se houver unresolved, failed ou total inconsistente
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "${1:-}" == "help" ]]; then
  print_usage
  exit 0
fi

if [[ ! -f "$SERVER_DIR/$VALIDATION_CORPUS_PATH" ]]; then
  echo "❌ Corpus não encontrado: $SERVER_DIR/$VALIDATION_CORPUS_PATH"
  exit 1
fi

VALIDATION_LIMIT="$(resolve_corpus_count)"
if [[ -z "$VALIDATION_LIMIT" || "$VALIDATION_LIMIT" -le 0 ]]; then
  echo "❌ Não foi possível resolver a quantidade de decks do corpus."
  exit 1
fi

print_header "Quality Gate - Resolution Corpus"
echo "API_BASE_URL=${API_BASE_URL}"
echo "VALIDATION_CORPUS_PATH=${VALIDATION_CORPUS_PATH}"
echo "VALIDATION_LIMIT=${VALIDATION_LIMIT}"
echo "VALIDATION_ARTIFACT_DIR=${VALIDATION_ARTIFACT_DIR}"

if api_ready; then
  echo "ℹ️ API já está pronta em ${API_BASE_URL}."
else
  if [[ "$API_BASE_URL" == http://127.0.0.1:* || "$API_BASE_URL" == http://localhost:* ]]; then
    if port_in_use "$PORT"; then
      next_port="$(select_free_local_port "$PORT" 30 || true)"
      if [[ -n "$next_port" ]]; then
        PORT="$next_port"
        API_BASE_URL="http://127.0.0.1:${PORT}"
        echo "ℹ️ Porta original ocupada. Usando porta local livre: ${PORT}."
      fi
    fi
  fi

  if [[ ! -f "$SERVER_DIR/build/bin/server.dart" || "${FORCE_BUILD:-0}" == "1" ]]; then
    echo "ℹ️ Gerando build do backend para execução não-interativa..."
    (
      cd "$SERVER_DIR"
      dart_frog build
    ) >/tmp/mtgia_resolution_build.log 2>&1
  fi

  echo "ℹ️ API não detectada. Iniciando servidor compilado local em porta ${PORT}..."
  (
    cd "$SERVER_DIR"
    PORT="$PORT" dart run build/bin/server.dart
  ) >/tmp/mtgia_resolution_gate.log 2>&1 &

  SERVER_PID="$!"
  STARTED_BY_SCRIPT=1

  for ((i = 1; i <= SERVER_START_TIMEOUT; i++)); do
    if api_ready; then
      echo "✅ API pronta em ${API_BASE_URL} (t=${i}s)."
      break
    fi

    if ! kill -0 "$SERVER_PID" >/dev/null 2>&1; then
      echo "❌ O processo do servidor encerrou antes de ficar pronto."
      echo "   Verifique logs em /tmp/mtgia_resolution_gate.log"
      exit 1
    fi

    sleep 1

    if [[ "$i" -eq "$SERVER_START_TIMEOUT" ]]; then
      echo "❌ Timeout aguardando API local em ${API_BASE_URL}."
      echo "   Verifique logs em /tmp/mtgia_resolution_gate.log"
      exit 1
    fi
  done
fi

print_header "Executando runner oficial de resolução"
(
  cd "$SERVER_DIR"
  TEST_API_BASE_URL="$API_BASE_URL" \
  VALIDATION_LIMIT="$VALIDATION_LIMIT" \
  VALIDATION_SELECTION_MODE="$VALIDATION_SELECTION_MODE" \
  VALIDATION_CORPUS_PATH="$VALIDATION_CORPUS_PATH" \
  VALIDATION_ARTIFACT_DIR="$VALIDATION_ARTIFACT_DIR" \
  VALIDATION_SUMMARY_JSON_PATH="$VALIDATION_SUMMARY_JSON_PATH" \
  VALIDATION_SUMMARY_MD_PATH="$VALIDATION_SUMMARY_MD_PATH" \
  dart run bin/run_three_commander_resolution_validation.dart
)

python3 - "$SERVER_DIR/$VALIDATION_SUMMARY_JSON_PATH" "$VALIDATION_LIMIT" <<'PY'
import json
import sys
from pathlib import Path

summary_path = Path(sys.argv[1])
expected_total = int(sys.argv[2])

if not summary_path.exists():
    print(f"❌ Resumo não encontrado: {summary_path}")
    sys.exit(2)

summary = json.loads(summary_path.read_text(encoding="utf-8"))
total = int(summary.get("total") or 0)
passed = int(summary.get("passed") or 0)
failed = int(summary.get("failed") or 0)
unresolved = int(summary.get("unresolved") or 0)

if total != expected_total:
    print(
        f"❌ Gate de resolução falhou: total={total}, esperado={expected_total}."
    )
    sys.exit(2)

if failed > 0 or unresolved > 0 or passed != total:
    print(
        "❌ Gate de resolução falhou: "
        f"passed={passed}, failed={failed}, unresolved={unresolved}, total={total}."
    )
    sys.exit(2)

print(
    "✅ Resumo do corpus validado: "
    f"passed={passed}, failed={failed}, unresolved={unresolved}, total={total}."
)
PY

print_header "Quality gate de resolução concluído"
echo "✅ Gate recorrente do corpus executado com sucesso."
echo "📦 Resumo JSON: $SERVER_DIR/$VALIDATION_SUMMARY_JSON_PATH"
