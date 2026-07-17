#!/usr/bin/env bash
set -euo pipefail

SOURCE="${MANALOOM_OFFSITE_BACKUP_SOURCE:-}"
DESTINATION="${MANALOOM_OFFSITE_BACKUP_DESTINATION:-}"
RECIPIENT="${MANALOOM_BACKUP_AGE_RECIPIENT:-}"
EVIDENCE_DIR="${MANALOOM_BACKUP_EVIDENCE_DIR:-}"
EXECUTE=0

usage() {
  cat <<'EOF'
Uso: manaloom_offsite_backup.sh [opcoes]

Por padrao apenas imprime o plano. A escrita exige simultaneamente --execute e
MANALOOM_OFFSITE_BACKUP_EXECUTE=1.

Opcoes:
  --source FILE                 dump PostgreSQL local
  --destination s3://BUCKET/PREFIX
  --recipient AGE_PUBLIC_KEY
  --evidence-dir DIR
  --execute
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) SOURCE="${2:-}"; shift 2 ;;
    --destination) DESTINATION="${2:-}"; shift 2 ;;
    --recipient) RECIPIENT="${2:-}"; shift 2 ;;
    --evidence-dir) EVIDENCE_DIR="${2:-}"; shift 2 ;;
    --execute) EXECUTE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "argumento desconhecido: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$SOURCE" || -z "$DESTINATION" || -z "$RECIPIENT" ]]; then
  echo "source, destination e recipient sao obrigatorios" >&2
  exit 2
fi
if [[ "$DESTINATION" != s3://* ]]; then
  echo "destination deve usar s3://" >&2
  exit 2
fi
if [[ "$RECIPIENT" != age1* ]]; then
  echo "recipient deve ser uma chave publica age X25519 (age1...)" >&2
  exit 2
fi
command -v shasum >/dev/null 2>&1 || {
  echo "ferramenta obrigatoria ausente: shasum" >&2
  exit 2
}

RECIPIENT_FINGERPRINT="$(printf '%s' "$RECIPIENT" | shasum -a 256 | awk '{print $1}')"
if [[ "$EXECUTE" == "0" ]]; then
  printf '{"status":"dry_run","source":"%s","destination":"%s","encryption":"age-x25519","recipient_sha256":"%s","writes_performed":false}\n' \
    "$SOURCE" "$DESTINATION" "$RECIPIENT_FINGERPRINT"
  exit 0
fi

# shellcheck source=scripts/lib/manaloom_mutation_guard.sh
ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"
require_live_mutation_approval "backup off-site criptografado ManaLoom"
readonly LIVE_MUTATION_APPROVED=1
: "$LIVE_MUTATION_APPROVED"

if [[ "${MANALOOM_OFFSITE_BACKUP_EXECUTE:-0}" != "1" ]]; then
  echo "execucao recusada: defina MANALOOM_OFFSITE_BACKUP_EXECUTE=1 junto com --execute" >&2
  exit 2
fi
APPROVED_DESTINATION="${MANALOOM_APPROVED_OFFSITE_BACKUP_DESTINATION:-}"
APPROVED_RECIPIENT_SHA256="${MANALOOM_APPROVED_BACKUP_RECIPIENT_SHA256:-}"
if [[ "$APPROVED_DESTINATION" != s3://* ||
      ! "$APPROVED_RECIPIENT_SHA256" =~ ^[0-9a-f]{64}$ ]]; then
  echo "execucao recusada: destino e fingerprint age aprovados devem vir do ambiente protegido" >&2
  exit 2
fi
if [[ "${DESTINATION%/}" != "${APPROVED_DESTINATION%/}" ||
      "$RECIPIENT_FINGERPRINT" != "$APPROVED_RECIPIENT_SHA256" ]]; then
  echo "destino ou recipient do backup diverge da allowlist aprovada" >&2
  exit 2
fi
if [[ ! -f "$SOURCE" ]]; then
  echo "backup de origem ausente: $SOURCE" >&2
  exit 2
fi

for tool in age aws jq shasum; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ferramenta obrigatoria ausente: $tool" >&2
    exit 2
  }
done

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
SOURCE_BASENAME="$(basename "$SOURCE")"
SOURCE_SHA256="$(shasum -a 256 "$SOURCE" | awk '{print $1}')"
STAGING_DIR="$(mktemp -d /tmp/manaloom-offsite-backup.XXXXXX)"
cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

ENCRYPTED_BASENAME="${SOURCE_BASENAME}.${STAMP}.${SOURCE_SHA256:0:12}.age"
ENCRYPTED_FILE="$STAGING_DIR/$ENCRYPTED_BASENAME"
MANIFEST_FILE="$STAGING_DIR/$ENCRYPTED_BASENAME.json"
age --recipient "$RECIPIENT" --output "$ENCRYPTED_FILE" "$SOURCE"
chmod 600 "$ENCRYPTED_FILE"
ENCRYPTED_SHA256="$(shasum -a 256 "$ENCRYPTED_FILE" | awk '{print $1}')"
ENCRYPTED_BYTES="$(wc -c < "$ENCRYPTED_FILE" | tr -d ' ')"
SOURCE_BYTES="$(wc -c < "$SOURCE" | tr -d ' ')"

jq -n \
  --arg schema_version "1" \
  --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg source_file "$SOURCE_BASENAME" \
  --arg source_sha256 "$SOURCE_SHA256" \
  --arg encrypted_file "$ENCRYPTED_BASENAME" \
  --arg encrypted_sha256 "$ENCRYPTED_SHA256" \
  --arg recipient_sha256 "$RECIPIENT_FINGERPRINT" \
  --argjson source_bytes "$SOURCE_BYTES" \
  --argjson encrypted_bytes "$ENCRYPTED_BYTES" \
  '{
    schema_version: ($schema_version | tonumber),
    created_at: $created_at,
    source: {file: $source_file, sha256: $source_sha256, bytes: $source_bytes},
    encrypted: {
      file: $encrypted_file,
      sha256: $encrypted_sha256,
      bytes: $encrypted_bytes,
      format: "age-x25519",
      recipient_sha256: $recipient_sha256
    }
}' > "$MANIFEST_FILE"
MANIFEST_SHA256="$(shasum -a 256 "$MANIFEST_FILE" | awk '{print $1}')"
MANIFEST_BYTES="$(wc -c < "$MANIFEST_FILE" | tr -d ' ')"

REMOTE_PREFIX="${DESTINATION%/}"
REMOTE_ENCRYPTED="$REMOTE_PREFIX/$ENCRYPTED_BASENAME"
REMOTE_MANIFEST="$REMOTE_ENCRYPTED.json"
SSE_ARGS=(--sse AES256)
if [[ -n "${MANALOOM_BACKUP_AWS_KMS_KEY_ID:-}" ]]; then
  SSE_ARGS=(--sse aws:kms --sse-kms-key-id "$MANALOOM_BACKUP_AWS_KMS_KEY_ID")
fi

aws s3 cp --only-show-errors "${SSE_ARGS[@]}" \
  --metadata "sha256=$ENCRYPTED_SHA256,source-sha256=$SOURCE_SHA256,recipient-sha256=$RECIPIENT_FINGERPRINT" \
  "$ENCRYPTED_FILE" "$REMOTE_ENCRYPTED"
aws s3 cp --only-show-errors "${SSE_ARGS[@]}" \
  --metadata "sha256=$MANIFEST_SHA256" \
  "$MANIFEST_FILE" "$REMOTE_MANIFEST"

S3_PATH="${REMOTE_ENCRYPTED#s3://}"
BUCKET="${S3_PATH%%/*}"
KEY="${S3_PATH#*/}"
REMOTE_HEAD="$(aws s3api head-object --bucket "$BUCKET" --key "$KEY" --output json)"
REMOTE_BYTES="$(jq -r '.ContentLength' <<<"$REMOTE_HEAD")"
REMOTE_SHA256="$(jq -r '.Metadata.sha256 // ""' <<<"$REMOTE_HEAD")"
REMOTE_SOURCE_SHA256="$(jq -r '.Metadata["source-sha256"] // ""' <<<"$REMOTE_HEAD")"
REMOTE_SSE="$(jq -r '.ServerSideEncryption // ""' <<<"$REMOTE_HEAD")"
if [[ "$REMOTE_BYTES" != "$ENCRYPTED_BYTES" ]]; then
  echo "upload off-site divergiu em bytes: local=$ENCRYPTED_BYTES remoto=$REMOTE_BYTES" >&2
  exit 1
fi
if [[ "$REMOTE_SHA256" != "$ENCRYPTED_SHA256" || "$REMOTE_SOURCE_SHA256" != "$SOURCE_SHA256" ]]; then
  echo "upload off-site divergiu nos metadados SHA-256" >&2
  exit 1
fi
if [[ "$REMOTE_SSE" != "AES256" && "$REMOTE_SSE" != "aws:kms" ]]; then
  echo "upload off-site sem server-side encryption verificavel" >&2
  exit 1
fi

MANIFEST_S3_PATH="${REMOTE_MANIFEST#s3://}"
MANIFEST_KEY="${MANIFEST_S3_PATH#*/}"
REMOTE_MANIFEST_HEAD="$(aws s3api head-object --bucket "$BUCKET" --key "$MANIFEST_KEY" --output json)"
if [[ "$(jq -r '.ContentLength' <<<"$REMOTE_MANIFEST_HEAD")" != "$MANIFEST_BYTES" ||
      "$(jq -r '.Metadata.sha256 // ""' <<<"$REMOTE_MANIFEST_HEAD")" != "$MANIFEST_SHA256" ]]; then
  echo "manifesto off-site divergiu em tamanho ou SHA-256" >&2
  exit 1
fi

if [[ -n "$EVIDENCE_DIR" ]]; then
  mkdir -p "$EVIDENCE_DIR"
  cp "$MANIFEST_FILE" "$EVIDENCE_DIR/"
  chmod 600 "$EVIDENCE_DIR/$(basename "$MANIFEST_FILE")"
fi

jq -n \
  --arg status uploaded \
  --arg destination "$REMOTE_ENCRYPTED" \
  --arg manifest "$REMOTE_MANIFEST" \
  --arg source_sha256 "$SOURCE_SHA256" \
  --arg encrypted_sha256 "$ENCRYPTED_SHA256" \
  --arg manifest_sha256 "$MANIFEST_SHA256" \
  --arg server_side_encryption "$REMOTE_SSE" \
  --argjson encrypted_bytes "$ENCRYPTED_BYTES" \
  '{
    status: $status,
    destination: $destination,
    manifest: $manifest,
    source_sha256: $source_sha256,
    encrypted_sha256: $encrypted_sha256,
    manifest_sha256: $manifest_sha256,
    encrypted_bytes: $encrypted_bytes,
    remote_size_verified: true,
    remote_metadata_verified: true,
    destination_allowlist_verified: true,
    recipient_allowlist_verified: true,
    server_side_encryption: $server_side_encryption
  }'
