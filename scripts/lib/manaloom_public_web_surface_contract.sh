#!/usr/bin/env bash

# Executable scope shared by the local smoke and the post-deploy proof. The
# public Beta keeps informational/legal pages and explicitly shared reports;
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
    /|/pricing|/pricing/|/app|/app/|/app/*|/app\?*)
      return 0
      ;;
  esac

  if [[ "$canonical_base" == https://* ]]; then
    case "$location" in
      "$canonical_base"|"$canonical_base/"|"$canonical_base/pricing"|"$canonical_base/pricing/"|"$canonical_base/app"|"$canonical_base/app/"|"$canonical_base/app/"*|"$canonical_base/app?"*)
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

manaloom_public_web_assert_free_beta_files() {
  local home_html="$1"
  local pricing_html="$2"

  if ! grep -Eqi 'beta' "$home_html" "$pricing_html" ||
     ! grep -Eqi 'gratuit|gr[aá]tis' "$home_html" "$pricing_html" ||
     ! grep -Eqi 'sem cobran[cç]a' "$pricing_html"; then
    echo "landing/pricing nao identificam uma unica Beta gratuita e sem cobranca" >&2
    return 1
  fi

  if grep -Eqi '(^|[^[:alnum:]_])pro([^[:alnum:]_]|$)|checkout|(^|[^[:alnum:]_])trades?([^[:alnum:]_]|$)|marketplace|upgrade|[Rr]\$[[:space:]]*[0-9]' \
      "$home_html" "$pricing_html"; then
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
