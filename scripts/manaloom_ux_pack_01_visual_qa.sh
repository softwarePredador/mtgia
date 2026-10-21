#!/usr/bin/env bash
# Recaptura os cinco pacotes ux-pack-01 a partir de UMA corrida do p0.
#
# Por que este roteiro existe: os cinco pacotes eram montados a mao. A captura
# em si ja era automatica -- `manaloom_p0_runtime_capture.sh --profile
# web_mobile_390x844` roda `app_existing_user_visual_audit_test.dart` por
# `flutter drive` e cobre os 31 checkpoints exigidos (conferido em 2026-09-24
# contra os proprios manifestos: 31 de 31, nenhum faltando). O que faltava era
# o empacotamento: separar as capturas em cinco diretorios e indexar cada um.
#
# A divisao vem dos manifestos que ja estao no repositorio, nao de uma lista
# escrita aqui: se um pacote mudar de escopo, este roteiro acompanha sozinho.
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/app"
PINNED_DART="$HOME/.manaloom/toolchains/flutter-3.44.6/bin/cache/dart-sdk/bin/dart"
DART_BIN="${MANALOOM_DART_BIN:-$PINNED_DART}"
PROFILE="web_mobile_390x844"
GOLDENS="$APP_DIR/test/ui/goldens/runtime/web_mobile"

PACOTES=(
  ux-pack-01-card-printing-web
  ux-pack-01-catalog-web
  ux-pack-01-community-web
  ux-pack-01-completion-web
  ux-pack-01-deck-detail-web
)

usage() {
  cat <<'EOF'
uso:
  manaloom_ux_pack_01_visual_qa.sh --ready-manifest <ready.json> --runtime-log <log>

O ready manifest vem de manaloom_authenticated_visual_qa_isolated.sh.
O roteiro delega a captura ao p0 e so entao empacota e indexa os cinco pacotes.
EOF
}

READY_MANIFEST=""
RUNTIME_LOG=""
while (($#)); do
  case "$1" in
    --ready-manifest) READY_MANIFEST="${2:-}"; shift 2 ;;
    --runtime-log) RUNTIME_LOG="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "argumento desconhecido: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -f "$READY_MANIFEST" ]] || { echo "--ready-manifest obrigatorio" >&2; exit 2; }
[[ -n "$RUNTIME_LOG" ]] || { echo "--runtime-log obrigatorio" >&2; exit 2; }

SOURCE_DIGEST="$("$ROOT_DIR/scripts/manaloom_ui_source_digest.sh")"

echo "== captura p0 ($PROFILE) =="
"$ROOT_DIR/scripts/manaloom_p0_runtime_capture.sh" \
  --profile "$PROFILE" \
  --ready-manifest "$READY_MANIFEST" \
  --runtime-log "$RUNTIME_LOG"

echo "== empacotando os cinco pacotes =="
for pacote in "${PACOTES[@]}"; do
  destino="$ROOT_DIR/docs/qa/ui-live/current/$pacote"
  manifesto="$destino/capture-manifest.json"
  [[ -f "$manifesto" ]] || { echo "manifesto ausente: $manifesto" >&2; exit 2; }

  # A lista exigida sai do proprio manifesto anterior.
  mapfile -t exigidos < <(python3 - "$manifesto" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
req = d.get('required_checkpoints') or [s.get('name') for s in d.get('screenshots', [])]
for r in req:
    if r:
        print(r)
PY
)
  (( ${#exigidos[@]} > 0 )) || { echo "manifesto sem checkpoints: $manifesto" >&2; exit 2; }

  staging="$(mktemp -d "${TMPDIR:-/tmp}/manaloom_ux_pack_01.XXXXXX")"
  faltando=()
  for nome in "${exigidos[@]}"; do
    if [[ -f "$GOLDENS/$nome.png" ]]; then
      cp "$GOLDENS/$nome.png" "$staging/$nome.png"
    else
      faltando+=("$nome")
    fi
  done
  if (( ${#faltando[@]} > 0 )); then
    echo "$pacote: a corrida do p0 nao produziu ${faltando[*]}" >&2
    rm -rf "$staging"
    exit 1
  fi

  (cd "$APP_DIR" && "$DART_BIN" run tool/ui_runtime_evidence.dart validate-directory \
      --screenshots "$staging")

  rm -f "$destino"/*.png
  cp "$staging"/*.png "$destino/"
  rm -rf "$staging"

  (cd "$APP_DIR" && "$DART_BIN" run tool/ui_runtime_evidence.dart index-directory \
      --repo-root "$ROOT_DIR" \
      --screenshots "docs/qa/ui-live/current/$pacote" \
      --log "$RUNTIME_LOG" \
      --manifest "docs/qa/ui-live/current/$pacote/capture-manifest.json" \
      --source-digest "$SOURCE_DIGEST" \
      --surface "$(basename "$pacote" | tr '-' '_')" \
      --profile "$PROFILE" \
      --runtime flutter_drive \
      --target web_real_build \
      --device-contract "$(python3 - "$manifesto" <<'PY'
import json, sys
print(json.load(open(sys.argv[1])).get('device_contract', ''))
PY
)")
  echo "$pacote: ${#exigidos[@]} checkpoints indexados"
done

echo "ux-pack-01: cinco pacotes recapturados de uma unica corrida do p0."
echo "Abra todas as 31 capturas antes de registrar PASS_VISUAL_REVIEWED."
