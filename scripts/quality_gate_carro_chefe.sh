#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_DIR="$ROOT_DIR/server"

SOURCE_DECK_ID="${SOURCE_DECK_ID:-0b163477-2e8a-488a-8883-774fcd05281f}"
TEST_NAME="source deck regression uses fixed sourceDeckId and persists full return for validation"
SERVER_PID=""

CARRO_CHEFE_STRICT="${CARRO_CHEFE_STRICT:-}"
RUN_RESOLUTION_FLOW="${RUN_RESOLUTION_FLOW:-1}"
RESOLUTION_VALIDATION_LIMIT="${RESOLUTION_VALIDATION_LIMIT:-3}"
RESOLUTION_SELECTION_MODE="${RESOLUTION_SELECTION_MODE:-three}"
VALIDATION_CORPUS_PATH="${VALIDATION_CORPUS_PATH:-}"
if [[ -z "$CARRO_CHEFE_STRICT" ]]; then
  if [[ "${CI:-}" == "1" || "${CI:-}" == "true" ]]; then
    CARRO_CHEFE_STRICT=1
  else
    CARRO_CHEFE_STRICT=0
  fi
fi

cleanup() {
  if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
}

trap cleanup EXIT

printf "\n============================================================\n"
printf "Quality Gate - Carro-Chefe (optimize/complete)\n"
printf "============================================================\n"
printf "SOURCE_DECK_ID=%s\n" "$SOURCE_DECK_ID"
printf "STRICT_MODE=%s\n" "$CARRO_CHEFE_STRICT"
printf "RUN_RESOLUTION_FLOW=%s\n" "$RUN_RESOLUTION_FLOW"
printf "RESOLUTION_VALIDATION_LIMIT=%s\n" "$RESOLUTION_VALIDATION_LIMIT"
printf "RESOLUTION_SELECTION_MODE=%s\n" "$RESOLUTION_SELECTION_MODE"
printf "SERVER=%s\n\n" "$SERVER_DIR"

cd "$SERVER_DIR"

if ! curl -s -o /dev/null "http://localhost:8080/"; then
  echo "ℹ️  Backend local não está ativo. Subindo servidor temporário para o gate..."
  dart_frog dev -p 8080 > "$SERVER_DIR/.carro_chefe_server.log" 2>&1 &
  SERVER_PID=$!

  READY=0
  for _ in {1..40}; do
    if curl -s -o /dev/null "http://localhost:8080/"; then
      READY=1
      break
    fi

    if ! kill -0 "$SERVER_PID" >/dev/null 2>&1; then
      echo "❌ Backend encerrou antes de ficar pronto. Log: $SERVER_DIR/.carro_chefe_server.log"
      tail -n 40 "$SERVER_DIR/.carro_chefe_server.log" || true
      exit 2
    fi

    sleep 1
  done

  if [[ "$READY" -ne 1 ]]; then
    echo "❌ Timeout aguardando backend local em http://localhost:8080"
    tail -n 40 "$SERVER_DIR/.carro_chefe_server.log" || true
    exit 2
  fi

  echo "✅ Backend temporário pronto para validação."
fi

RUN_INTEGRATION_TESTS=1 \
SOURCE_DECK_ID="$SOURCE_DECK_ID" \
dart test test/ai_optimize_flow_test.dart \
  -N "$TEST_NAME" \
  --reporter expanded \
  --no-color

ARTIFACT_PATH="$SERVER_DIR/test/artifacts/ai_optimize/source_deck_optimize_latest.json"

python3 - "$ARTIFACT_PATH" "$CARRO_CHEFE_STRICT" <<'PY'
import json
import sys

artifact_path = sys.argv[1]
strict_mode = str(sys.argv[2]).strip() == "1"

with open(artifact_path, "r", encoding="utf-8") as f:
  payload = json.load(f)

status = payload.get("optimize_status")
response = payload.get("optimize_response") or {}
quality_error = response.get("quality_error")
source_available = bool(payload.get("source_available"))

if strict_mode:
  if status != 200:
    print(f"❌ Gate carro-chefe (strict) falhou: optimize_status={status} (esperado 200).")
    if quality_error:
      print(f"   quality_error={quality_error}")
    sys.exit(2)
  if quality_error:
    print("❌ Gate carro-chefe (strict) falhou: status 200 com quality_error presente.")
    print(f"   quality_error={quality_error}")
    sys.exit(2)

# Contrato atual do teste de integração:
# - 200: complete com qualidade mínima
# - 422: complete parcial/degradado, desde que retorne quality_error diagnóstico
if not strict_mode and status not in (200, 422):
  print(f"❌ Gate carro-chefe falhou: optimize_status={status} (esperado 200 ou 422).")
  if quality_error:
    print(f"   quality_error={quality_error}")
  sys.exit(2)

if not strict_mode and status == 422:
  if not quality_error:
    print("❌ Gate carro-chefe falhou: status 422 sem quality_error diagnóstico.")
    sys.exit(2)

  if not source_available:
    print("⚠️  Gate carro-chefe: source deck indisponível localmente; 422 com quality_error aceito como diagnóstico válido.")
    print(f"   quality_error={quality_error}")
    sys.exit(0)

  print("❌ Gate carro-chefe falhou: source deck disponível, mas optimize retornou 422.")
  print(f"   quality_error={quality_error}")
  sys.exit(2)

if quality_error:
  print("❌ Gate carro-chefe falhou: status 200 com quality_error presente.")
  print(f"   quality_error={quality_error}")
  sys.exit(2)

mode = response.get("mode")
details = response.get("additions_detailed") or []
target_additions = int(response.get("target_additions") or 0)

if mode == "complete" and isinstance(details, list):
  total_added = 0
  basic_added = 0
  basic_names = {"plains", "island", "swamp", "mountain", "forest", "wastes"}

  for item in details:
    if not isinstance(item, dict):
      continue
    qty = int(item.get("quantity") or 0)
    total_added += qty
    name = str(item.get("name") or "").strip().lower()
    if name in basic_names:
      basic_added += qty

  non_basic_added = total_added - basic_added

  max_allowed_basics = int(target_additions * 0.65)

  if target_additions >= 40 and basic_added > max_allowed_basics:
    print(
      f"❌ Gate carro-chefe falhou: excesso de básicos (basic_added={basic_added}, total_added={total_added}, limite={max_allowed_basics})."
    )
    sys.exit(2)

  if target_additions >= 40 and non_basic_added < 12:
    print(
      f"❌ Gate carro-chefe falhou: não-básicas insuficientes (non_basic_added={non_basic_added}, total_added={total_added})."
    )
    sys.exit(2)

print("✅ Verificação estrita do artefato aprovada.")
PY

if [[ "$RUN_RESOLUTION_FLOW" == "1" ]]; then
  VALIDATION_ARTIFACT_DIR="${VALIDATION_ARTIFACT_DIR:-}"
  VALIDATION_SUMMARY_JSON_PATH="${VALIDATION_SUMMARY_JSON_PATH:-}"
  VALIDATION_SUMMARY_MD_PATH="${VALIDATION_SUMMARY_MD_PATH:-}"
  if [[ -z "$VALIDATION_CORPUS_PATH" && -f "$SERVER_DIR/test/fixtures/optimization_resolution_corpus.json" ]]; then
    VALIDATION_CORPUS_PATH="test/fixtures/optimization_resolution_corpus.json"
  fi

  if [[ -z "$VALIDATION_ARTIFACT_DIR" && "$RESOLUTION_VALIDATION_LIMIT" -gt 3 ]]; then
    VALIDATION_ARTIFACT_DIR="test/artifacts/optimization_resolution_suite"
  fi
  if [[ -z "$VALIDATION_SUMMARY_JSON_PATH" && "$RESOLUTION_VALIDATION_LIMIT" -gt 3 ]]; then
    VALIDATION_SUMMARY_JSON_PATH="test/artifacts/optimization_resolution_suite/latest_summary.json"
  fi
  if [[ -z "$VALIDATION_SUMMARY_MD_PATH" && "$RESOLUTION_VALIDATION_LIMIT" -gt 3 ]]; then
    VALIDATION_SUMMARY_MD_PATH="../RELATORIO_RESOLUCAO_SUITE_COMMANDER_$(date +%Y-%m-%d).md"
  fi

  echo
  echo "▶ Rodando validação do fluxo completo optimize -> rebuild..."
  VALIDATION_LIMIT="$RESOLUTION_VALIDATION_LIMIT" \
  VALIDATION_SELECTION_MODE="$RESOLUTION_SELECTION_MODE" \
  VALIDATION_CORPUS_PATH="$VALIDATION_CORPUS_PATH" \
  VALIDATION_ARTIFACT_DIR="$VALIDATION_ARTIFACT_DIR" \
  VALIDATION_SUMMARY_JSON_PATH="$VALIDATION_SUMMARY_JSON_PATH" \
  VALIDATION_SUMMARY_MD_PATH="$VALIDATION_SUMMARY_MD_PATH" \
  dart run bin/run_three_commander_resolution_validation.dart
fi

printf "\n✅ Quality gate carro-chefe concluído com sucesso.\n"
printf "📦 Artefato latest: %s\n" "$SERVER_DIR/test/artifacts/ai_optimize/source_deck_optimize_latest.json"
