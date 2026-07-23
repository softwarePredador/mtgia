#!/usr/bin/env bash

# Deterministic Dart toolchain used by generated project logic and local gates.
readonly MANALOOM_DART_TOOLCHAIN_VERSION="3.12.2"
readonly MANALOOM_DART_TOOLCHAIN_DEFAULT="$HOME/.manaloom/toolchains/flutter-3.44.6/bin/cache/dart-sdk/bin/dart"
readonly MANALOOM_FLUTTER_TOOLCHAIN_DEFAULT="$HOME/.manaloom/toolchains/flutter-3.44.6"

resolve_manaloom_dart() {
  local candidate actual_version
  candidate="${MANALOOM_DART_BIN:-}"
  if [[ -z "$candidate" && -x "$MANALOOM_DART_TOOLCHAIN_DEFAULT" ]]; then
    candidate="$MANALOOM_DART_TOOLCHAIN_DEFAULT"
  elif [[ -z "$candidate" ]]; then
    candidate="$(command -v dart 2>/dev/null || true)"
  elif [[ "$candidate" != */* ]]; then
    candidate="$(command -v "$candidate" 2>/dev/null || true)"
  fi

  if [[ -z "$candidate" || ! -x "$candidate" ]]; then
    echo "Dart $MANALOOM_DART_TOOLCHAIN_VERSION obrigatorio nao encontrado" >&2
    return 2
  fi

  if [[ "$candidate" == */* ]]; then
    candidate="$(
      CDPATH='' cd -- "$(dirname "$candidate")" &&
        pwd
    )/$(basename "$candidate")"
  fi
  actual_version="$("$candidate" --version 2>&1 | awk '{print $4}')"
  if [[ "$actual_version" != "$MANALOOM_DART_TOOLCHAIN_VERSION" ]]; then
    echo "Dart incompativel: esperado $MANALOOM_DART_TOOLCHAIN_VERSION, encontrado ${actual_version:-desconhecido} em $candidate" >&2
    echo "Defina MANALOOM_DART_BIN para o executavel exato aprovado." >&2
    return 2
  fi

  MANALOOM_DART_BIN_RESOLVED="$candidate"
  export MANALOOM_DART_BIN_RESOLVED
}

resolve_manaloom_flutter_root() {
  local candidate flutter_candidate
  candidate="${MANALOOM_FLUTTER_ROOT:-}"
  flutter_candidate="${MANALOOM_FLUTTER_BIN:-}"

  if [[ -z "$candidate" && -n "$flutter_candidate" ]]; then
    if [[ "$flutter_candidate" != */* ]]; then
      flutter_candidate="$(command -v "$flutter_candidate" 2>/dev/null || true)"
    fi
    if [[ -n "$flutter_candidate" ]]; then
      candidate="$(CDPATH='' cd -- "$(dirname "$flutter_candidate")/.." && pwd)"
    fi
  elif [[ -z "$candidate" && -d "$MANALOOM_FLUTTER_TOOLCHAIN_DEFAULT" ]]; then
    candidate="$MANALOOM_FLUTTER_TOOLCHAIN_DEFAULT"
  elif [[ -z "$candidate" ]]; then
    flutter_candidate="$(command -v flutter 2>/dev/null || true)"
    if [[ -n "$flutter_candidate" ]]; then
      candidate="$(CDPATH='' cd -- "$(dirname "$flutter_candidate")/.." && pwd)"
    fi
  fi

  if [[ -z "$candidate" || ! -x "$candidate/bin/flutter" ||
        ! -f "$candidate/packages/flutter/pubspec.yaml" ]]; then
    echo "Flutter root 3.44.6 obrigatorio nao encontrado" >&2
    return 2
  fi

  MANALOOM_FLUTTER_ROOT_RESOLVED="$candidate"
  export MANALOOM_FLUTTER_ROOT_RESOLVED
}
