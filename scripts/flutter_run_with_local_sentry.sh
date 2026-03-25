#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${MTGIA_ENV_FILE:-$ROOT_DIR/server/.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Arquivo de ambiente nao encontrado: $ENV_FILE" >&2
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

cd "$ROOT_DIR/app"

exec flutter run \
  --dart-define=API_BASE_URL="${API_BASE_URL:-http://127.0.0.1:8080}" \
  --dart-define=SENTRY_DSN="${SENTRY_MOBILE_DSN:-${SENTRY_DSN:-}}" \
  --dart-define=SENTRY_ENVIRONMENT="${SENTRY_ENVIRONMENT:-development}" \
  --dart-define=SENTRY_RELEASE="${SENTRY_RELEASE:-manaloom@local}" \
  --dart-define=SENTRY_TRACES_SAMPLE_RATE="${SENTRY_TRACES_SAMPLE_RATE:-0.0}" \
  "$@"
