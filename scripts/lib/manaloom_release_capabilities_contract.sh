#!/usr/bin/env bash

# Canonical release-capability identity. Callers must select a committed source
# revision first; the working tree is never accepted as release evidence.
readonly MANALOOM_RELEASE_CAPABILITIES_PATH="server/config/release_capabilities.json"
readonly MANALOOM_RELEASE_CAPABILITY_KEYS_JSON='[
  "account_registration",
  "ads",
  "ai_analyze_optimize_advisory",
  "ai_generate_rebuild",
  "art_paywall",
  "battle_batch",
  "battle_coach",
  "battle_live",
  "billing_checkout",
  "binder_public",
  "catalog_private",
  "collection_private",
  "comments",
  "deck_replace_all",
  "decks_private",
  "direct_messages",
  "follows",
  "gallery_public",
  "learning_reads",
  "learning_writes",
  "legacy_ai_routes",
  "life_counter_local",
  "marketplace",
  "profiles_public",
  "scanner",
  "social_push",
  "subscriptions",
  "trades",
  "user_search"
]'
readonly MANALOOM_RELEASE_IMPLEMENTATION_STATUS_VALUES_JSON='[
  "contained_legacy",
  "experimental_guarded",
  "experimental_p0_open",
  "implemented_guarded",
  "implemented_p0_open",
  "not_implemented"
]'

manaloom_release_capabilities_block() {
  echo "BLOCKED: release capabilities: $1" >&2
  return 2
}

manaloom_load_release_capabilities_from_git() {
  local source_root="$1"
  local source_sha="$2"
  local raw_policy digest policy_json capability_count

  if ! git -C "$source_root" cat-file -e \
      "$source_sha:$MANALOOM_RELEASE_CAPABILITIES_PATH" 2>/dev/null; then
    manaloom_release_capabilities_block \
      "$MANALOOM_RELEASE_CAPABILITIES_PATH ausente no SHA candidato"
    return 2
  fi
  if ! raw_policy="$(
    git -C "$source_root" show \
      "$source_sha:$MANALOOM_RELEASE_CAPABILITIES_PATH"
  )"; then
    manaloom_release_capabilities_block \
      "$MANALOOM_RELEASE_CAPABILITIES_PATH nao pode ser lido no SHA candidato"
    return 2
  fi

  if ! jq -e \
    --argjson expected_capability_keys \
      "$MANALOOM_RELEASE_CAPABILITY_KEYS_JSON" \
    --argjson implementation_status_values \
      "$MANALOOM_RELEASE_IMPLEMENTATION_STATUS_VALUES_JSON" '
    def nonempty_string:
      type == "string" and length > 0;
    def timestamp_or_null:
      . == null or
      (type == "string" and
       test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\\.[0-9]+)?Z$"));
    type == "object" and
    keys == [
      "capabilities",
      "implementation_status",
      "live_verified_as_of",
      "offer_mode",
      "policy_version",
      "product",
      "release_channel",
      "schema_version"
    ] and
    .schema_version == "release_capabilities_v1" and
    .product == "brewtact" and
    .release_channel == "free_beta" and
    .offer_mode == "free_beta_no_commerce" and
    (.policy_version | nonempty_string) and
    (.implementation_status as $status |
      $implementation_status_values | index($status) != null) and
    (.live_verified_as_of | timestamp_or_null) and
    (.capabilities | type == "object" and
      keys == $expected_capability_keys) and
    all(.capabilities | keys[]; test("^[a-z][a-z0-9_]*$")) and
    all(.capabilities[];
      type == "object" and
      keys == [
        "allowed",
        "implementation_status",
        "live_verified_as_of",
        "release_capability"
      ] and
      (.implementation_status as $status |
        $implementation_status_values | index($status) != null) and
      (.release_capability == "off") and
      (.allowed == false) and
      (.live_verified_as_of | timestamp_or_null)
    )
  ' >/dev/null 2>&1 <<<"$raw_policy"; then
    manaloom_release_capabilities_block \
      "schema, chave ou valor desconhecido; a Free Beta exige matriz canonical default-deny"
    return 2
  fi

  if ! digest="$(
    git -C "$source_root" cat-file blob \
      "$source_sha:$MANALOOM_RELEASE_CAPABILITIES_PATH" |
      shasum -a 256 |
      awk '{print $1}'
  )" || [[ ! "$digest" =~ ^[0-9a-f]{64}$ ]]; then
    manaloom_release_capabilities_block \
      "digest SHA-256 do blob candidato nao pode ser provado"
    return 2
  fi

  capability_count="$(jq -er '.capabilities | length' <<<"$raw_policy")"
  policy_json="$(
    jq -cS \
      --arg policy_digest_sha256 "$digest" \
      --argjson capability_count "$capability_count" \
      '. + {
        configuration_status: "valid",
        policy_digest_sha256: $policy_digest_sha256,
        capability_count: $capability_count
      }' <<<"$raw_policy"
  )"

  # Public readonly outputs are consumed by scripts that source this library.
  # shellcheck disable=SC2034
  readonly MANALOOM_RELEASE_CAPABILITIES_POLICY_JSON="$policy_json"
  # shellcheck disable=SC2034
  readonly MANALOOM_RELEASE_CAPABILITIES_DIGEST_SHA256="$digest"
  # shellcheck disable=SC2034
  readonly MANALOOM_RELEASE_CAPABILITIES_COUNT="$capability_count"
}

manaloom_require_exact_release_capabilities() {
  local label="$1"
  local actual_json="$2"

  if ! jq -e \
    --argjson expected "$MANALOOM_RELEASE_CAPABILITIES_POLICY_JSON" \
    'if has("capability_count") then .
     else . + {capability_count: (.capabilities | length)}
     end | . == $expected' >/dev/null 2>&1 <<<"$actual_json"; then
    manaloom_release_capabilities_block \
      "$label diverge da matriz e do digest do SHA candidato"
    return 2
  fi
}

manaloom_require_public_app_release_open() {
  local policy_json="$1"

  if ! jq -e '
    def verified_timestamp:
      type == "string" and
      test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\\.[0-9]+)?Z$");
    (.live_verified_as_of | verified_timestamp) and
    any(.capabilities[];
      .release_capability == "on" and
      .allowed == true and
      (.live_verified_as_of | verified_timestamp)
    )
  ' >/dev/null 2>&1 <<<"$policy_json"; then
    manaloom_release_capabilities_block \
      "/app permanece inacessivel: capability ON com verificacao live datada ausente"
    return 2
  fi
}
