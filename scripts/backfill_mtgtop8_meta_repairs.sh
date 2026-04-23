#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_DIR="$ROOT_DIR/server"

formats=("ST" "PI" "MO" "LE" "VI" "EDH" "cEDH" "PAU" "PREM")
limit_events=1
limit_decks=10
delay_event_ms=0
delay_deck_ms=0
apply=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      apply=1
      shift
      ;;
    --format)
      formats=("$2")
      shift 2
      ;;
    --formats)
      IFS=',' read -r -a formats <<< "$2"
      shift 2
      ;;
    --limit-events)
      limit_events="$2"
      shift 2
      ;;
    --limit-decks)
      limit_decks="$2"
      shift 2
      ;;
    --delay-event-ms)
      delay_event_ms="$2"
      shift 2
      ;;
    --delay-deck-ms)
      delay_deck_ms="$2"
      shift 2
      ;;
    *)
      echo "Argumento desconhecido: $1" >&2
      echo "Uso: $0 [--apply] [--format EDH|--formats EDH,cEDH] [--limit-events N] [--limit-decks N] [--delay-event-ms N] [--delay-deck-ms N]" >&2
      exit 1
      ;;
  esac
done

mode_args=(--dry-run)
mode_label="DRY-RUN"
if [[ "$apply" -eq 1 ]]; then
  mode_args=()
  mode_label="APPLY"
fi

echo "MTGTop8 meta repair backfill"
echo "Mode: $mode_label"
echo "Formats: ${formats[*]}"
echo "limit-events: $limit_events"
echo "limit-decks: $limit_decks"
echo

cd "$SERVER_DIR"

for format in "${formats[@]}"; do
  echo "=== $format ==="
  dart run bin/fetch_meta.dart "$format" \
    --refresh-existing \
    "${mode_args[@]}" \
    --limit-events="$limit_events" \
    --limit-decks="$limit_decks" \
    --delay-event-ms="$delay_event_ms" \
    --delay-deck-ms="$delay_deck_ms"
  echo
done
