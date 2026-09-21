#!/usr/bin/env bash
set -euo pipefail

# Coloca o ChromeDriver pinado no cache que as provas visuais de UI esperam.
#
# Idempotente: se o binário pinado já existe e confere, não toca na rede.
# Fechado: qualquer divergência de SHA-256 apaga o que baixou e sai com 2.
# Nunca instala no PATH, nunca sobrescreve outra versão — o layout
# `<versao>-<plataforma>/chromedriver.zip` + `unpacked/` é o que já existia
# para as versões anteriores, então elas continuam lá para comparação.

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib/manaloom_chromedriver.sh"

for command_name in curl shasum unzip; do
  command -v "$command_name" >/dev/null 2>&1 || {
    echo "$command_name e obrigatorio para o bootstrap do ChromeDriver" >&2
    exit 2
  }
done

if [[ "$(uname -s)-$(uname -m)" != "Darwin-arm64" ]]; then
  echo "BLOCKED: o pin e para $MANALOOM_CHROMEDRIVER_PLATFORM; esta maquina e $(uname -s)-$(uname -m)" >&2
  exit 2
fi

verify_archive() {
  local observed
  observed="$(shasum -a 256 "$MANALOOM_CHROMEDRIVER_ARCHIVE" | cut -d' ' -f1)"
  if [[ "$observed" != "$MANALOOM_CHROMEDRIVER_SHA256" ]]; then
    echo "SHA-256 do ChromeDriver nao confere:" >&2
    echo "  esperado $MANALOOM_CHROMEDRIVER_SHA256" >&2
    echo "  obtido   $observed" >&2
    return 2
  fi
}

if [[ -x "$MANALOOM_CHROMEDRIVER_PINNED" && -f "$MANALOOM_CHROMEDRIVER_ARCHIVE" ]] &&
   verify_archive 2>/dev/null; then
  echo "ChromeDriver $MANALOOM_CHROMEDRIVER_VERSION ja em cache e integro."
  "$MANALOOM_CHROMEDRIVER_PINNED" --version
  exit 0
fi

mkdir -p "$MANALOOM_CHROMEDRIVER_CACHE_DIR"
echo "Baixando ChromeDriver $MANALOOM_CHROMEDRIVER_VERSION ($MANALOOM_CHROMEDRIVER_PLATFORM)..."
echo "  $MANALOOM_CHROMEDRIVER_URL"
curl --fail --silent --show-error --location --max-time 300 \
  --output "$MANALOOM_CHROMEDRIVER_ARCHIVE" "$MANALOOM_CHROMEDRIVER_URL"

if ! verify_archive; then
  rm -f "$MANALOOM_CHROMEDRIVER_ARCHIVE"
  exit 2
fi

rm -rf "$MANALOOM_CHROMEDRIVER_CACHE_DIR/unpacked"
mkdir -p "$MANALOOM_CHROMEDRIVER_CACHE_DIR/unpacked"
unzip -q "$MANALOOM_CHROMEDRIVER_ARCHIVE" -d "$MANALOOM_CHROMEDRIVER_CACHE_DIR/unpacked"
chmod +x "$MANALOOM_CHROMEDRIVER_PINNED"

if [[ ! -x "$MANALOOM_CHROMEDRIVER_PINNED" ]]; then
  echo "BLOCKED: o arquivo desempacotado nao tem o layout esperado em $MANALOOM_CHROMEDRIVER_PINNED" >&2
  exit 2
fi

echo "ChromeDriver pronto:"
"$MANALOOM_CHROMEDRIVER_PINNED" --version
