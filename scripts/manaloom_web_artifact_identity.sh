#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR=""
EXPECTED_GIT_SHA=""
EXPECTED_SOURCE_PATCH_SHA256=""
SOURCE_ROOT=""
VIEWPORT=""
DPR=""
DATASET=""
ACTUAL_RENDERER=""
OUTPUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-dir) BUILD_DIR="${2:-}"; shift 2 ;;
    --expected-git-sha) EXPECTED_GIT_SHA="${2:-}"; shift 2 ;;
    --expected-source-patch-sha256) EXPECTED_SOURCE_PATCH_SHA256="${2:-}"; shift 2 ;;
    --source-root) SOURCE_ROOT="${2:-}"; shift 2 ;;
    --viewport) VIEWPORT="${2:-}"; shift 2 ;;
    --dpr) DPR="${2:-}"; shift 2 ;;
    --dataset) DATASET="${2:-}"; shift 2 ;;
    --renderer) ACTUAL_RENDERER="${2:-}"; shift 2 ;;
    --output) OUTPUT="${2:-}"; shift 2 ;;
    *) echo "argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done

for tool in jq python3 shasum; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $tool" >&2
    exit 2
  }
done

if [[ -z "$BUILD_DIR" || -z "$EXPECTED_GIT_SHA" || -z "$VIEWPORT" ||
      -z "$DPR" || -z "$DATASET" || -z "$ACTUAL_RENDERER" ]]; then
  echo "uso: $0 --build-dir DIR --expected-git-sha SHA [--expected-source-patch-sha256 SHA256] [--source-root REPO] --viewport WIDTHxHEIGHT --dpr N --dataset ID --renderer ID [--output FILE]" >&2
  exit 2
fi
if [[ ! "$VIEWPORT" =~ ^[1-9][0-9]*x[1-9][0-9]*$ ]]; then
  echo "viewport invalido: use WIDTHxHEIGHT" >&2
  exit 2
fi
if [[ ! "$DPR" =~ ^([1-9][0-9]*([.][0-9]+)?|0[.][0-9]*[1-9][0-9]*)$ ]]; then
  echo "DPR invalido" >&2
  exit 2
fi

RELEASE_JSON="$BUILD_DIR/release.json"
INDEX_HTML="$BUILD_DIR/index.html"
MAIN_JS="$BUILD_DIR/main.dart.js"
for file in "$RELEASE_JSON" "$INDEX_HTML" "$MAIN_JS"; do
  [[ -f "$file" ]] || { echo "artefato Web ausente: $file" >&2; exit 2; }
done

grep -Fq '<base href="/app/">' "$INDEX_HTML" || {
  echo "artefato Web nao usa base href /app/" >&2
  exit 1
}

MANIFEST_GIT_SHA="$(jq -er '.git_sha' "$RELEASE_JSON")"
MANIFEST_SOURCE_PATCH_SHA256="$(jq -r '.source_patch_sha256 // ""' "$RELEASE_JSON")"
MANIFEST_MAIN_SHA="$(jq -er '.artifacts["main.dart.js"]' "$RELEASE_JSON")"
MAIN_SHA="$(shasum -a 256 "$MAIN_JS" | awk '{print $1}')"
RELEASE_SHA="$(shasum -a 256 "$RELEASE_JSON" | awk '{print $1}')"

if [[ "$MAIN_SHA" != "$MANIFEST_MAIN_SHA" ]]; then
  echo "bundle Web diverge do hash registrado em release.json" >&2
  exit 1
fi

if [[ "$MANIFEST_GIT_SHA" != "$EXPECTED_GIT_SHA" ]]; then
  if [[ "${MANALOOM_ALLOW_STALE_WEB_ARTIFACT:-}" != "I_ACCEPT_STALE_WEB_ARTIFACT" ]]; then
    echo "bundle Web antigo: git_sha do artefato difere do SHA esperado" >&2
    exit 1
  fi
  STALE_OVERRIDE=true
else
  STALE_OVERRIDE=false
fi

if [[ -n "$EXPECTED_SOURCE_PATCH_SHA256" &&
      "$MANIFEST_SOURCE_PATCH_SHA256" != "$EXPECTED_SOURCE_PATCH_SHA256" ]]; then
  echo "bundle Web antigo: patch das fontes difere do hash esperado" >&2
  exit 1
fi

if [[ -n "$SOURCE_ROOT" ]]; then
  SOURCE_TREE_SHA256="$(python3 - "$SOURCE_ROOT" <<'PY'
import hashlib
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
app = root / "app"
inputs = [app / "lib", app / "web", app / "assets"]
files = [app / "pubspec.yaml", app / "pubspec.lock"]
for input_path in inputs:
    if input_path.is_dir():
        files.extend(path for path in input_path.rglob("*") if path.is_file())

digest = hashlib.sha256()
for path in sorted(set(files), key=lambda item: item.relative_to(root).as_posix()):
    if not path.is_file():
        continue
    relative = path.relative_to(root).as_posix().encode("utf-8")
    digest.update(relative)
    digest.update(b"\0")
    digest.update(path.read_bytes())
    digest.update(b"\0")
print(digest.hexdigest())
PY
)"
  if [[ "$MANIFEST_SOURCE_PATCH_SHA256" != "$SOURCE_TREE_SHA256" ]]; then
    echo "bundle Web antigo: arvore das fontes runtime difere do hash registrado" >&2
    exit 1
  fi
fi

if [[ -z "$OUTPUT" ]]; then
  OUTPUT="${TMPDIR:-/tmp}/manaloom_web_artifact_identity.json"
fi
mkdir -p "$(dirname -- "$OUTPUT")"
TEMP_OUTPUT="$OUTPUT.tmp.$$"
trap 'rm -f "$TEMP_OUTPUT"' EXIT

jq -n \
  --arg verified_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg git_sha "$MANIFEST_GIT_SHA" \
  --arg source_patch_sha256 "$MANIFEST_SOURCE_PATCH_SHA256" \
  --arg main_sha256 "$MAIN_SHA" \
  --arg release_sha256 "$RELEASE_SHA" \
  --arg flutter_version "$(jq -r '.flutter_version // "unknown"' "$RELEASE_JSON")" \
  --arg renderer_contract "$(jq -r '.renderer_contract // "unknown"' "$RELEASE_JSON")" \
  --arg actual_renderer "$ACTUAL_RENDERER" \
  --arg viewport "$VIEWPORT" \
  --arg dpr "$DPR" \
  --arg dataset "$DATASET" \
  --argjson stale_override "$STALE_OVERRIDE" \
  '{
    schema_version: 1,
    verified_at: $verified_at,
    git_sha: $git_sha,
    source_patch_sha256: (if ($source_patch_sha256 | length) > 0 then $source_patch_sha256 else null end),
    main_dart_js_sha256: $main_sha256,
    release_manifest_sha256: $release_sha256,
    flutter_version: $flutter_version,
    renderer_contract: $renderer_contract,
    actual_renderer: $actual_renderer,
    viewport: $viewport,
    dpr: ($dpr | tonumber),
    dataset: $dataset,
    stale_override: $stale_override
  }' >"$TEMP_OUTPUT"
mv "$TEMP_OUTPUT" "$OUTPUT"
trap - EXIT
printf 'PASS: identidade do artefato Web validada\nmanifest=%s\n' "$OUTPUT"
