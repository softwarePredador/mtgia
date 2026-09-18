#!/usr/bin/env bash

# Deterministic Node and paired Flutter/Dart toolchains used by local gates.
readonly MANALOOM_DART_TOOLCHAIN_VERSION="3.12.2"
readonly MANALOOM_FLUTTER_TOOLCHAIN_VERSION="3.44.6"
readonly MANALOOM_DART_TOOLCHAIN_DEFAULT="$HOME/.manaloom/toolchains/flutter-3.44.6/bin/cache/dart-sdk/bin/dart"
readonly MANALOOM_FLUTTER_TOOLCHAIN_DEFAULT="$HOME/.manaloom/toolchains/flutter-3.44.6"
readonly MANALOOM_NODE_TOOLCHAIN_REQUIREMENT="^20.19, ^22.13 ou >=24"

manaloom_node_is_supported() {
  "$1" -e '
    const [major, minor] = process.versions.node.split(".").map(Number);
    process.exit(
      major >= 24 || major === 22 && minor >= 13 || major === 20 && minor >= 19
        ? 0
        : 1,
    );
  ' >/dev/null 2>&1
}

resolve_manaloom_node() {
  local requested candidate
  requested="${MANALOOM_NODE_BIN:-}"

  if [[ -n "$requested" ]]; then
    candidate="$requested"
    if [[ "$candidate" != */* ]]; then
      candidate="$(command -v "$candidate" 2>/dev/null || true)"
    fi
    if [[ -z "$candidate" || ! -x "$candidate" ]] ||
       ! manaloom_node_is_supported "$candidate"; then
      echo "Node configurado incompativel: use $MANALOOM_NODE_TOOLCHAIN_REQUIREMENT" >&2
      return 2
    fi
  else
    candidate="$(command -v node 2>/dev/null || true)"
    if [[ -z "$candidate" || ! -x "$candidate" ]] ||
       ! manaloom_node_is_supported "$candidate"; then
      candidate=""
      local fallback
      for fallback in /opt/homebrew/bin/node /usr/local/bin/node; do
        if [[ -x "$fallback" ]] && manaloom_node_is_supported "$fallback"; then
          candidate="$fallback"
          break
        fi
      done
    fi
    if [[ -z "$candidate" ]]; then
      echo "Node local compativel obrigatorio ($MANALOOM_NODE_TOOLCHAIN_REQUIREMENT)" >&2
      return 2
    fi
  fi

  candidate="$(
    CDPATH='' cd -- "$(dirname "$candidate")" &&
      pwd
  )/$(basename "$candidate")"
  MANALOOM_NODE_BIN_RESOLVED="$candidate"
  export MANALOOM_NODE_BIN_RESOLVED
}

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

resolve_manaloom_flutter_dart_pair() {
  local flutter_bin paired_dart version_json versions
  local actual_flutter_version actual_dart_version

  resolve_manaloom_flutter_root || return $?
  flutter_bin="$MANALOOM_FLUTTER_ROOT_RESOLVED/bin/flutter"
  paired_dart="$MANALOOM_FLUTTER_ROOT_RESOLVED/bin/cache/dart-sdk/bin/dart"

  if [[ ! -x "$paired_dart" ]]; then
    echo "Dart correspondente ao Flutter $MANALOOM_FLUTTER_TOOLCHAIN_VERSION ausente: $paired_dart" >&2
    return 2
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 obrigatorio para validar o Flutter pinado" >&2
    return 2
  fi
  if ! version_json="$("$flutter_bin" --version --machine 2>/dev/null)"; then
    echo "Nao foi possivel validar o Flutter pinado: $flutter_bin" >&2
    return 2
  fi
  if ! versions="$(
    python3 -c '
import json
import sys

payload = json.load(sys.stdin)
print(payload.get("frameworkVersion", ""))
print(payload.get("dartSdkVersion", ""))
' <<<"$version_json"
  )"; then
    echo "Resposta invalida de flutter --version --machine: $flutter_bin" >&2
    return 2
  fi
  actual_flutter_version="${versions%%$'\n'*}"
  actual_dart_version="${versions#*$'\n'}"
  if [[ "$actual_flutter_version" != "$MANALOOM_FLUTTER_TOOLCHAIN_VERSION" ||
        "$actual_dart_version" != "$MANALOOM_DART_TOOLCHAIN_VERSION" ]]; then
    echo "Flutter incompativel: esperado $MANALOOM_FLUTTER_TOOLCHAIN_VERSION com Dart $MANALOOM_DART_TOOLCHAIN_VERSION, encontrado ${actual_flutter_version:-desconhecido} com Dart ${actual_dart_version:-desconhecido} em $flutter_bin" >&2
    return 2
  fi

  MANALOOM_DART_BIN="$paired_dart"
  resolve_manaloom_dart || return $?
  MANALOOM_FLUTTER_BIN_RESOLVED="$flutter_bin"
  export MANALOOM_FLUTTER_BIN_RESOLVED
}
