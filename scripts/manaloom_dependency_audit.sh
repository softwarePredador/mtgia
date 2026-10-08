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
#
# `--enforce-lockfile`, como nos scripts de build e deploy: a auditoria le o
# lock, nunca o escreve. Sem a flag, um pubspec.yaml que divergiu do lock era
# resolvido de novo e o `pubspec.lock` reescrito em silencio -- o de `app/`
# move o digest de UI pelo mesmo caminho descrito acima. Com a flag o lock
# fica como estava, e uma divergencia que ele nao satisfaz (pacote novo,
# restricao fora da versao travada) para a auditoria no `pub get` com
# "Unable to satisfy `pubspec.yaml` using `pubspec.lock`" (medido em
# 2026-10-08 numa copia descartavel).
#
# O que a flag NAO barra, medido em 2026-10-08 com o Dart 3.12.2 pinado numa
# copia descartavel de tools/project_logic: promover a dependencia direta um
# pacote que o lock ja tem como transitivo (`collection: ^1.19.1`, travado em
# 1.19.1 como `dependency: transitive`). As versoes nao mudam, entao o
# `pub get --enforce-lockfile` sai com 0 e deixa o lock byte a byte igual,
# ainda dizendo `transitive`; ele so imprime "collection 1.19.1 (from
# transitive dependency to direct dependency)" e "Would change 1
# dependency.", e essa saida vai para /dev/null aqui. So um `pub get` sem a
# flag reescreveria o lock para `direct main`. Quem pega essa divergencia e o
# validador que roda logo depois, o pacote `dependency_validator` (`"$DART_BIN"
# run dependency_validator`; 5.0.5 no lock do app e dos tools, 3.2.3 no do
# server): com o pacote promovido e nao importado ele lista "These packages
# may be unused" e sai com 1, e a auditoria para. Com o pacote promovido E
# importado em lib/, nenhum dos dois reclama: a auditoria passa e o lock
# segue com o rotulo `transitive` ate o proximo `pub get` sem a flag, fora
# desta auditoria.
run_dependency_validator() {
  local package_dir="$1"
  local label="$2"
  local kind="$3"

  print_header "Dependency validator: ${label}"
  cd "$ROOT_DIR/$package_dir"
  if [[ "$kind" == "flutter" ]]; then
    "$FLUTTER_BIN" pub get --no-example --enforce-lockfile >/dev/null
  else
    "$DART_BIN" pub get --enforce-lockfile >/dev/null
  fi
  "$DART_BIN" run dependency_validator
}

run_dependency_validator app "Flutter app" flutter
run_dependency_validator server "Dart Frog server" dart
run_dependency_validator tools/manaloom_lints "ManaLoom custom lint package" dart
run_dependency_validator tools/project_logic "ManaLoom project logic generator" dart

print_header "Dependency audit concluído"
echo "Todos os pacotes auditados declaram apenas dependências coerentes com o uso atual."
