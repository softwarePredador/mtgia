#!/usr/bin/env bash
# BT-REL-002 (D-13): contrato da identidade de release por superfície nos scripts de
# build e deploy. Cada superfície leva produto, superfície, SHA completo e a matriz do
# SHA; o app compara o digest recebido com a matriz compilada nele (dart-define) e o
# site serve /release.json. Chamado por scripts/manaloom_release_ops_contract_test.sh.
# Os padrões abaixo são o texto literal dos scripts, com $ e aspas.
# shellcheck disable=SC2016
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
WEB="$ROOT_DIR/scripts/manaloom_deploy_flutter_web.sh"
for release_script in "$WEB" "$ROOT_DIR/scripts/manaloom_build_android_release.sh"; do
  grep -Fq -- '--dart-define="RELEASE_CAPABILITIES_DIGEST=$RELEASE_CAPABILITIES_DIGEST"' "$release_script"
  grep -Fq -- '--dart-define="RELEASE_CAPABILITIES_ALLOWED=$RELEASE_CAPABILITIES_ALLOWED"' "$release_script"
  grep -Fq -- '--dart-define="RELEASE_GIT_SHA=$SHA"' "$release_script"
  grep -Fq 'product: "brewtact",' "$release_script"
done
grep -Fq -- '--dart-define="RELEASE_SURFACE=app"' "$WEB"
# A identidade embarcada e o release.json do /app dizem a superfície.
# (com `|| exit`: o /bin/bash 3.2 do macOS não sai com set -e num [[ ]] que falha)
[[ "$(grep -c 'surface: "app",' "$WEB")" == "2" ]] || {
  echo "a identidade embarcada e o release.json do /app devem dizer a superfície" >&2
  exit 1
}
grep -Fq 'identidade servida pelo /app diverge da embarcada no build' "$WEB"
grep -Fq -- '--dart-define="RELEASE_SURFACE=android"' "$ROOT_DIR/scripts/manaloom_build_android_release.sh"
grep -Fq 'surface: "android",' "$ROOT_DIR/scripts/manaloom_publish_android_release.sh"
grep -Fq '.product == "brewtact" and .surface == "android" and .release_mode == $release_mode' \
  "$ROOT_DIR/scripts/manaloom_publish_android_release.sh"
grep -Fq "cat > '\$REMOTE_DIR/web-public/public/release.json'" \
  "$ROOT_DIR/scripts/manaloom_deploy_public_web.sh"
grep -Fq '.product == "brewtact" and .surface == "site" and .git_sha == $sha' \
  "$ROOT_DIR/scripts/manaloom_deploy_public_web.sh"
# O /app e o Android resolvem o modo da D-13 antes de compilar a matriz.
grep -Fq 'manaloom_resolve_public_app_release_mode "$RELEASE_CAPABILITIES_JSON"' \
  "$ROOT_DIR/scripts/manaloom_build_android_release.sh"
grep -Fq 'identidade embarcada do /app diverge da identidade do SHA' "$WEB"
grep -Fq 'identidade publica do site diverge do SHA do deploy' \
  "$ROOT_DIR/scripts/manaloom_deploy_public_web.sh"
echo "manaloom release identity contract: PASS"
