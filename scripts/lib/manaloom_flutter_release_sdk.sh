#!/usr/bin/env bash

# Reproducible Flutter release toolchain contract. Callers must already require
# jq and python3 before resolving the SDK.
readonly MANALOOM_RELEASE_FLUTTER_VERSION="3.44.6"
readonly MANALOOM_RELEASE_FLUTTER_REVISION="ee80f08bbf97172ec030b8751ceab557177a34a6"
readonly MANALOOM_RELEASE_FLUTTER_ENGINE_REVISION="83675ed27633283e7fc296c8bca22e841224c096"
readonly MANALOOM_RELEASE_DART_VERSION="3.12.2"

resolve_manaloom_release_flutter() {
  local candidate version_json actual_version actual_revision actual_engine_revision actual_dart_version
  candidate="${MANALOOM_FLUTTER_BIN:-}"
  if [[ -z "$candidate" ]]; then
    candidate="$(command -v flutter 2>/dev/null || true)"
  elif [[ "$candidate" != */* ]]; then
    candidate="$(command -v "$candidate" 2>/dev/null || true)"
  fi

  if [[ -z "$candidate" ]]; then
    echo "ferramenta obrigatoria ausente: Flutter $MANALOOM_RELEASE_FLUTTER_VERSION" >&2
    return 2
  fi

  if ! candidate="$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$candidate" 2>/dev/null)"; then
    echo "nao foi possivel resolver o executavel Flutter de release" >&2
    return 2
  fi
  if [[ ! -f "$candidate" || ! -x "$candidate" ]]; then
    echo "ferramenta obrigatoria ausente: Flutter $MANALOOM_RELEASE_FLUTTER_VERSION" >&2
    return 2
  fi

  local dart_candidate
  dart_candidate="$(dirname "$candidate")/dart"
  if [[ ! -f "$dart_candidate" || ! -x "$dart_candidate" ]]; then
    echo "Dart correspondente ao Flutter de release ausente: $dart_candidate" >&2
    return 2
  fi

  if ! version_json="$("$candidate" --version --machine 2>/dev/null)"; then
    echo "nao foi possivel validar o Flutter de release: $candidate" >&2
    return 2
  fi
  actual_version="$(jq -er '.frameworkVersion' <<<"$version_json" 2>/dev/null || true)"
  actual_revision="$(jq -er '.frameworkRevision' <<<"$version_json" 2>/dev/null || true)"
  actual_engine_revision="$(jq -er '.engineRevision' <<<"$version_json" 2>/dev/null || true)"
  actual_dart_version="$(jq -er '.dartSdkVersion' <<<"$version_json" 2>/dev/null || true)"
  if [[ "$actual_version" != "$MANALOOM_RELEASE_FLUTTER_VERSION" ||
        "$actual_revision" != "$MANALOOM_RELEASE_FLUTTER_REVISION" ||
        "$actual_engine_revision" != "$MANALOOM_RELEASE_FLUTTER_ENGINE_REVISION" ||
        "$actual_dart_version" != "$MANALOOM_RELEASE_DART_VERSION" ]]; then
    echo "Flutter de release incompativel: esperado $MANALOOM_RELEASE_FLUTTER_VERSION/$MANALOOM_RELEASE_FLUTTER_REVISION com Dart $MANALOOM_RELEASE_DART_VERSION, encontrado ${actual_version:-desconhecido}/${actual_revision:-desconhecido} com Dart ${actual_dart_version:-desconhecido} em $candidate" >&2
    echo "Defina MANALOOM_FLUTTER_BIN para o executavel exato aprovado." >&2
    return 2
  fi

  local sdk_root
  sdk_root="$(dirname "$(dirname "$candidate")")"
  if git -C "$sdk_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if [[ "$(git -C "$sdk_root" rev-parse HEAD 2>/dev/null || true)" != "$MANALOOM_RELEASE_FLUTTER_REVISION" ]] ||
       ! git -C "$sdk_root" diff --quiet --ignore-submodules -- ||
       ! git -C "$sdk_root" diff --cached --quiet --ignore-submodules --; then
      echo "SDK Flutter de release possui revision ou alteracoes rastreadas divergentes: $sdk_root" >&2
      return 2
    fi
  fi

  MANALOOM_FLUTTER_BIN_RESOLVED="$candidate"
  MANALOOM_RELEASE_DART_BIN_RESOLVED="$dart_candidate"
  readonly MANALOOM_FLUTTER_BIN_RESOLVED
  readonly MANALOOM_RELEASE_DART_BIN_RESOLVED
  export MANALOOM_FLUTTER_BIN_RESOLVED
  export MANALOOM_RELEASE_DART_BIN_RESOLVED
}
