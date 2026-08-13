#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/manaloom-public-web-surface-contract.XXXXXX)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# shellcheck source=scripts/lib/manaloom_public_web_surface_contract.sh
source "$ROOT_DIR/scripts/lib/manaloom_public_web_surface_contract.sh"

fail() {
  echo "$*" >&2
  exit 1
}

expect_failure() {
  if "$@" >/dev/null 2>&1; then
    fail "contrato aceitou caso negativo: $*"
  fi
}

required_routes="$(manaloom_public_web_required_routes)"
removed_routes="$(manaloom_public_web_removed_routes)"
for route in / /pricing /blog /legal/privacy /legal/terms /legal/disclaimer /robots.txt /sitemap.xml; do
  grep -Fxq "$route" <<<"$required_routes" ||
    fail "rota publica obrigatoria ausente: $route"
done
for route in /marketplace /decks/public-web-removed-surface /players/public-web-removed-surface; do
  grep -Fxq "$route" <<<"$removed_routes" ||
    fail "rota removida ausente do contrato: $route"
  if grep -Fxq "$route" <<<"$required_routes"; then
    fail "rota removida ainda consta como obrigatoria: $route"
  fi
done

manaloom_public_web_assert_removed_response /marketplace 404 '' http://127.0.0.1:3000
manaloom_public_web_assert_removed_response /marketplace 410 '' https://brewtact.com
manaloom_public_web_assert_removed_response /marketplace 308 / https://brewtact.com
manaloom_public_web_assert_removed_response /decks/example 307 /app/decks/example https://brewtact.com
manaloom_public_web_assert_removed_response /players/example 301 https://brewtact.com/app/ https://brewtact.com
expect_failure manaloom_public_web_assert_removed_response /marketplace 200 '' https://brewtact.com
expect_failure manaloom_public_web_assert_removed_response /marketplace 404 /app/ https://brewtact.com
expect_failure manaloom_public_web_assert_removed_response /marketplace 308 http://brewtact.com/ https://brewtact.com
expect_failure manaloom_public_web_assert_removed_response /marketplace 308 //attacker.example/ https://brewtact.com
expect_failure manaloom_public_web_assert_removed_response /marketplace 308 /marketplace https://brewtact.com

HOME_FIXTURE="$TMP_DIR/home.html"
PRICING_FIXTURE="$TMP_DIR/pricing.html"
printf '%s\n' '<main>BrewTact — Beta gratuita</main>' >"$HOME_FIXTURE"
printf '%s\n' '<main>Uma única oferta. Sem cobrança durante a beta.</main>' >"$PRICING_FIXTURE"
manaloom_public_web_assert_free_beta_files "$HOME_FIXTURE" "$PRICING_FIXTURE"
for forbidden in Pro checkout trade marketplace upgrade 'R$ 19'; do
  printf '%s\n' "<main>Beta gratuita $forbidden</main>" >"$PRICING_FIXTURE"
  expect_failure manaloom_public_web_assert_free_beta_files \
    "$HOME_FIXTURE" "$PRICING_FIXTURE"
done
printf '%s\n' '<main>Acesso antecipado</main>' >"$PRICING_FIXTURE"
expect_failure manaloom_public_web_assert_free_beta_files \
  "$HOME_FIXTURE" "$PRICING_FIXTURE"

SITEMAP_FIXTURE="$TMP_DIR/sitemap.xml"
printf '%s\n' '<urlset><loc>https://brewtact.com/</loc><loc>https://brewtact.com/pricing</loc></urlset>' >"$SITEMAP_FIXTURE"
manaloom_public_web_assert_sitemap_file "$SITEMAP_FIXTURE"
for removed_url in \
  https://brewtact.com/marketplace \
  https://brewtact.com/decks/example \
  https://brewtact.com/players/example; do
  printf '%s\n' "<urlset><loc>$removed_url</loc></urlset>" >"$SITEMAP_FIXTURE"
  expect_failure manaloom_public_web_assert_sitemap_file "$SITEMAP_FIXTURE"
done

manaloom_public_web_validate_report_fixture_id report_fixture-123
expect_failure manaloom_public_web_validate_report_fixture_id '../report'
expect_failure manaloom_public_web_validate_report_fixture_id 'report?leak=true'

for executable in \
  "$ROOT_DIR/scripts/manaloom_public_web_smoke.sh" \
  "$ROOT_DIR/scripts/manaloom_deploy_public_web.sh"; do
  bash -n "$executable"
  grep -Fq 'manaloom_public_web_required_routes' "$executable"
  grep -Fq 'manaloom_public_web_removed_routes' "$executable"
  grep -Fq 'manaloom_public_web_assert_removed_response' "$executable"
  grep -Fq 'manaloom_public_web_assert_free_beta_files' "$executable"
  grep -Fq 'manaloom_public_web_assert_sitemap_file' "$executable"
  grep -Fq 'MANALOOM_PUBLIC_WEB_REPORT_FIXTURE_ID' "$executable"
done

printf 'ManaLoom public web surface contract PASS\n'
