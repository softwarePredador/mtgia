#!/usr/bin/env bash

# Executable scope shared by the local smoke and the post-deploy proof. The
# controlled Beta keeps informational/legal pages and explicitly shared reports;
# marketplace, public deck pages and player profiles are retired.
manaloom_public_web_required_routes() {
  printf '%s\n' \
    / \
    /pricing \
    /blog \
    /legal/privacy \
    /legal/terms \
    /legal/disclaimer \
    /robots.txt \
    /sitemap.xml
}

manaloom_public_web_removed_routes() {
  printf '%s\n' \
    /marketplace \
    /decks/public-web-removed-surface \
    /players/public-web-removed-surface
}

manaloom_public_web_safe_retirement_location() {
  local location="$1"
  local public_base_url="${2:-}"
  local canonical_base="${public_base_url%/}"

  case "$location" in
    /|/pricing|/pricing/)
      return 0
      ;;
  esac

  if [[ "$canonical_base" == https://* ]]; then
    case "$location" in
      "$canonical_base"|"$canonical_base/"|"$canonical_base/pricing"|"$canonical_base/pricing/")
        return 0
        ;;
    esac
  fi
  return 1
}

manaloom_public_web_assert_removed_response() {
  local route="$1"
  local status="$2"
  local location="${3:-}"
  local public_base_url="${4:-}"

  case "$status" in
    404|410)
      if [[ -n "$location" ]]; then
        echo "superficie removida $route respondeu HTTP $status com Location inesperado: $location" >&2
        return 1
      fi
      ;;
    301|302|307|308)
      if [[ -z "$location" ]] ||
         ! manaloom_public_web_safe_retirement_location \
           "$location" "$public_base_url"; then
        echo "superficie removida $route redirecionou para destino inseguro: HTTP $status Location=$location" >&2
        return 1
      fi
      ;;
    *)
      echo "superficie removida $route continua publica: HTTP $status" >&2
      return 1
      ;;
  esac
}

# Casa um padrão fixando o locale, e trata erro como erro.
#
# `grep -q` devolve 2 quando o padrão é inválido ou o arquivo não pode ser
# lido, e um `if ! grep -q` não distingue isso de "não casou" — um padrão
# quebrado faria o contrato passar silenciosamente. Aqui 0 é casou, 1 é não
# casou, e qualquer outro status vira 2 e é tratado como falha pelos dois
# chamadores.
#
# `LC_ALL=C` não é detalhe: os padrões abaixo são escritos em BYTES, e sem
# fixar o locale eles se comportam de três maneiras diferentes conforme o
# `LANG` da máquina. Medido, com /usr/bin/grep:
#
#   LANG vazio  — `[cç]` nunca casa; `-i` não dobra `á`/`Á`; `[^[:alnum:]_]`
#                 casa o byte de continuação de `í`, e `proíbe` dispara o
#                 check de "Pro".
#   LANG UTF-8  — a faixa `\x80-\xff` é sequência multibyte inválida:
#                 `grep: illegal byte sequence`, status 2, e o check negativo
#                 falharia ABERTO.
#
# Fixando C, o comportamento é o mesmo em qualquer máquina e os padrões em
# bytes valem sempre.
manaloom_public_web_grep() {
  local pattern="$1"
  shift
  local status=0
  LC_ALL=C grep -Eqi -- "$pattern" "$@" || status=$?
  if ((status > 1)); then
    echo "grep falhou (status $status) ao avaliar o contrato de web publico" >&2
    return 2
  fi
  return "$status"
}

manaloom_public_web_assert_free_beta_files() {
  local home_html="$1"
  local pricing_html="$2"

  # Um caractere acentuado ocupa DOIS bytes em UTF-8 e `-i` não os dobra em
  # locale C, então cada caso do acentuado é escrito. Alternância no lugar de
  # classe (`(c|ç)`, não `[cç]`) casa a sequência inteira.
  if ! manaloom_public_web_grep 'beta' "$home_html" "$pricing_html" ||
     ! manaloom_public_web_grep 'gratuit|gr(a|á|Á)tis' \
         "$home_html" "$pricing_html" ||
     ! manaloom_public_web_grep 'sem cobran(c|ç|Ç)a' "$pricing_html"; then
    echo "landing/pricing nao identificam uma unica Beta gratuita e sem cobranca" >&2
    return 1
  fi

  # Byte alto conta como caractere de palavra: sem isso `proíbe` e `promoção`
  # satisfazem `(^|[^[:alnum:]_])pro([^[:alnum:]_]|$)` e acusam um tier pago
  # que não existe.
  local nonword=$'[^[:alnum:]_\x80-\xff]'
  # U+00A0 (\xc2\xa0) é o separador que `Intl.NumberFormat('pt-BR')` emite
  # entre `R$` e o valor. `[[:space:]]` não o cobre, e sem esta alternativa um
  # preço em BRL corretamente formatado passaria despercebido — o contrato
  # falharia aberto no caso exato que existe para barrar.
  local money_gap=$'([[:space:]]|\xc2\xa0)*'

  local paid_pattern
  paid_pattern="(^|${nonword})pro(${nonword}|\$)"
  paid_pattern="${paid_pattern}|checkout"
  paid_pattern="${paid_pattern}|(^|${nonword})trades?(${nonword}|\$)"
  paid_pattern="${paid_pattern}|marketplace|upgrade"
  paid_pattern="${paid_pattern}|[Rr]\\\$${money_gap}[0-9]"

  local status=0
  manaloom_public_web_grep "$paid_pattern" "$home_html" "$pricing_html" ||
    status=$?
  if ((status != 1)); then
    echo "landing/pricing voltaram a anunciar Pro, checkout, trade, marketplace, upgrade ou preco pago" >&2
    return 1
  fi
}

manaloom_public_web_assert_sitemap_file() {
  local sitemap_file="$1"

  if grep -Eqi '<loc>https://[^<]+/(marketplace|decks(/|<)|players(/|<))' \
      "$sitemap_file"; then
    echo "sitemap voltou a publicar superficie removida" >&2
    return 1
  fi
}

manaloom_public_web_validate_report_fixture_id() {
  local report_id="$1"

  if [[ ! "$report_id" =~ ^[A-Za-z0-9_-]{1,128}$ ]]; then
    echo "MANALOOM_PUBLIC_WEB_REPORT_FIXTURE_ID invalido" >&2
    return 1
  fi
}
