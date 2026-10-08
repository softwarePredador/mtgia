#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck source=scripts/lib/manaloom_dart_toolchain.sh
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/lib/manaloom_dart_toolchain.sh"
# Flutter e Dart pinados e PAREADOS, como no quality_gate: o resolvedor
# confere `flutter --version --machine` contra o pin e usa o Dart do proprio
# SDK desse Flutter. MANALOOM_FLUTTER_BIN/MANALOOM_FLUTTER_ROOT continuam
# valendo como override, mas um SDK fora do pin falha em vez de rodar.
resolve_manaloom_flutter_dart_pair
FLUTTER_BIN="$MANALOOM_FLUTTER_BIN_RESOLVED"
DART_BIN="$MANALOOM_DART_BIN_RESOLVED"

print_header() {
  echo ""
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

# Roda o validador com a toolchain PINADA, nunca com o `dart` do PATH.
#
# Este script rodava `dart run dependency_validator` puro. Medido em
# 2026-09-22, nesta maquina, o `dart` do PATH e o 3.11.4 do Flutter antigo, e o
# `pub get` implicito que o `dart run` dispara num pacote Flutter resolve SEM a
# restricao do SDK que fixa `meta` em 1.18.0. Resultado, reproduzido:
#
#   meta      1.18.0 -> 1.17.0
#   test_api  0.7.11 -> 0.7.10
#
# Esse par rebaixado quebra o build de integration_test
# (`_TestFlutterView implements FlutterView` sem `displayCornerRadii`) e, pior,
# `app/pubspec.lock` esta no escopo de `manaloom_ui_source_digest.sh`: o
# rebaixamento MOVE o digest de UI e invalida toda a evidencia ja capturada.
# Um gate de auditoria corrompia a evidencia que o gate de UI exige.
#
# Para o pacote Flutter o `pub get` precisa ser o do Flutter pinado; para os
# pacotes Dart puros, o Dart pinado. O `pub get` roda sempre, antes do
# validador: o `dart run` que vem depois encontra essa resolucao atual e nao
# re-resolve nada. O `dart run` nao tem `--no-pub`; e a ordem que garante que
# nenhuma resolucao implicita escolha versoes por conta propria.
run_dependency_validator() {
  local package_dir="$1"
  local label="$2"
  local kind="$3"

  print_header "Dependency validator: ${label}"
  cd "$ROOT_DIR/$package_dir"
  if [[ "$kind" == "flutter" ]]; then
    "$FLUTTER_BIN" pub get --no-example >/dev/null
  else
    "$DART_BIN" pub get >/dev/null
  fi
  "$DART_BIN" run dependency_validator
}

run_dependency_validator app "Flutter app" flutter
run_dependency_validator server "Dart Frog server" dart
run_dependency_validator tools/manaloom_lints "ManaLoom custom lint package" dart
run_dependency_validator tools/project_logic "ManaLoom project logic generator" dart

print_header "Dependency audit concluído"
echo "Todos os pacotes auditados declaram apenas dependências coerentes com o uso atual."
