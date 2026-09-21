#!/usr/bin/env bash

# ChromeDriver determinístico para as provas visuais de UI.
#
# Um pin, um lugar. Antes disto, seis scripts carregavam o mesmo caminho
# literal cada um, quatro pegavam o que houvesse no PATH, e o cache tinha um
# driver 151 baixado à mão que nenhum script usava porque os pins ficaram no
# 150 — enquanto o Chrome instalado já ia no 153 e o `chromedriver` do PATH
# era o 147 do Homebrew. Cada script decidia sozinho e todos decidiam errado.
#
# A resolução é fechada: override explícito, senão o pin em cache, senão
# BLOCKED apontando para o bootstrap. O PATH nunca entra — é a mesma armadilha
# do `flutter` do PATH que reescreve o lockfile.
readonly MANALOOM_CHROMEDRIVER_VERSION="153.0.8010.52"
readonly MANALOOM_CHROMEDRIVER_PLATFORM="mac-arm64"
readonly MANALOOM_CHROMEDRIVER_SHA256="23dc682b73c6473562b4b0d6ddd5b8a0823dbeeccd32a901d085df5f8d87b5cd"
readonly MANALOOM_CHROMEDRIVER_URL="https://storage.googleapis.com/chrome-for-testing-public/${MANALOOM_CHROMEDRIVER_VERSION}/${MANALOOM_CHROMEDRIVER_PLATFORM}/chromedriver-${MANALOOM_CHROMEDRIVER_PLATFORM}.zip"
readonly MANALOOM_CHROMEDRIVER_CACHE_DIR="$HOME/Library/Caches/manaloom/chromedriver/${MANALOOM_CHROMEDRIVER_VERSION}-${MANALOOM_CHROMEDRIVER_PLATFORM}"
readonly MANALOOM_CHROMEDRIVER_ARCHIVE="$MANALOOM_CHROMEDRIVER_CACHE_DIR/chromedriver.zip"
readonly MANALOOM_CHROMEDRIVER_PINNED="$MANALOOM_CHROMEDRIVER_CACHE_DIR/unpacked/chromedriver-${MANALOOM_CHROMEDRIVER_PLATFORM}/chromedriver"

manaloom_chromedriver_major() {
  "$1" --version 2>/dev/null | sed -E 's/^[^0-9]*([0-9]+).*/\1/'
}

# Define MANALOOM_CHROMEDRIVER_BIN_RESOLVED ou devolve 2 com a razão em stderr.
#
# MANALOOM_CHROMEDRIVER_BIN continua sendo o override — é o nome que os
# scripts sempre aceitaram e que o contrato de política cobra. Mas um override
# precisa existir e executar; um valor errado não cai no pin em silêncio.
resolve_manaloom_chromedriver() {
  local requested candidate
  requested="${MANALOOM_CHROMEDRIVER_BIN:-}"

  if [[ -n "$requested" ]]; then
    candidate="$requested"
    if [[ ! -x "$candidate" ]]; then
      echo "MANALOOM_CHROMEDRIVER_BIN nao executa: $candidate" >&2
      return 2
    fi
  elif [[ -x "$MANALOOM_CHROMEDRIVER_PINNED" ]]; then
    candidate="$MANALOOM_CHROMEDRIVER_PINNED"
  else
    echo "BLOCKED: ChromeDriver $MANALOOM_CHROMEDRIVER_VERSION nao esta em cache." >&2
    echo "Rode scripts/manaloom_chromedriver_bootstrap.sh (baixa, confere SHA-256 e desempacota)." >&2
    return 2
  fi

  candidate="$(
    CDPATH='' cd -- "$(dirname "$candidate")" &&
      pwd
  )/$(basename "$candidate")"
  MANALOOM_CHROMEDRIVER_BIN_RESOLVED="$candidate"
  export MANALOOM_CHROMEDRIVER_BIN_RESOLVED
}

# Falha fechado se o major do driver não for o major do Chrome que vai
# dirigir. Cada script de captura já fazia esta conta; agora fazem a mesma.
assert_manaloom_chromedriver_matches_chrome() {
  local chrome_executable="$1"
  local browser_major driver_major
  browser_major="$(manaloom_chromedriver_major "$chrome_executable")"
  driver_major="$(manaloom_chromedriver_major "$MANALOOM_CHROMEDRIVER_BIN_RESOLVED")"
  if [[ -z "$browser_major" || -z "$driver_major" || "$browser_major" != "$driver_major" ]]; then
    echo "ChromeDriver major $driver_major does not match Chrome major $browser_major" >&2
    return 2
  fi
}
