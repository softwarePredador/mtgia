package com.manaloom.xmage;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

/**
 * Pin-scoped fail-closed policy for cards that resolve in XMage but are not
 * qualified for ManaLoom battle execution.
 *
 * <p>The policy commit must move with {@link SidecarMain#XMAGE_COMMIT}. That
 * makes a future pin update review every restriction explicitly instead of
 * silently inheriting or dropping it.</p>
 */
final class XmageCardQualificationPolicy {
    static final String FROM_ENGINE_COMMIT =
            "34d81ea4995ce15d7e1a788dc6d2a3595d35bcec";
    static final String ENGINE_COMMIT =
            "2c43ec8cdb5cd475d47e6b555a4077151f476a3b";
    static final String ACTIVATION_POLICY_SCHEMA =
            "manaloom_xmage_transition_activation_policy_v1_2026-07-30";
    static final String POSTGRES_RECONCILIATION_SCHEMA =
            "manaloom_xmage_postgresql_scope_reconciliation_v1_2026-07-28";
    static final String POSTGRES_RECONCILIATION_SHA256 =
            "64f2175bc4b1c040ccb352f8e3647a11d0c1088d591b5a7b5ec8a08603ced3cb";
    static final String POSTGRES_ROWS_SHA256 =
            "7ed18075c34b0a4b7f3c3206f250aeb86879f7ea568f648586dd696ad2d412dc";
    private static final String ACTIVATION_POLICY_RESOURCE =
            "/xmage-transition-activation-policy.json";

    private static final Map<String, Restriction> RESTRICTIONS;
    private static final Set<String> ACTIVATION_RESTRICTED_NAMES;
    private static final Set<String> TRANSITION_CARD_NAMES;
    private static final int FUTURE_DEFERRED_COUNT;
    private static final int RELEASED_MISSING_COUNT;

    static {
        Map<String, Restriction> restrictions = new LinkedHashMap<>();
        register(
                restrictions,
                new Restriction(
                        "Planetarium of Wan Shi Tong",
                        "xmage_pin_semantic_defect",
                        "Triggered ability incorrectly exposes the mandatory look action as optional.",
                        "magefree/mage@84e46530",
                        "blocked_until_official_fix_and_focused_qualification"
                )
        );
        register(
                restrictions,
                new Restriction(
                        "Prudent Fateseer",
                        "xmage_upstream_mechanic_unfinished",
                        "Prepare is unfinished and the pinned set registry removes this card from the catalog.",
                        "magefree/mage@ac2c96d",
                        "blocked_until_prepare_is_officially_implemented_and_qualified"
                )
        );
        register(
                restrictions,
                new Restriction(
                        "Mandate of Peace",
                        "xmage_upstream_copy_lki_gap",
                        "Copy and last-known-information handling for this spell is not yet safely qualified.",
                        "magefree/mage#12911",
                        "blocked_until_copy_lki_fix_and_focused_qualification"
                )
        );
        ActivationPolicyStats activationPolicy = loadActivationPolicy(
                restrictions
        );
        RESTRICTIONS = Collections.unmodifiableMap(restrictions);
        ACTIVATION_RESTRICTED_NAMES = Collections.unmodifiableSet(
                activationPolicy.names
        );
        TRANSITION_CARD_NAMES = Collections.unmodifiableSet(
                activationPolicy.transitionCardNames
        );
        FUTURE_DEFERRED_COUNT = activationPolicy.futureDeferredCount;
        RELEASED_MISSING_COUNT = activationPolicy.releasedMissingCount;
    }

    private XmageCardQualificationPolicy() {
    }

    static void requireEngineCommit(String engineCommit) {
        if (!ENGINE_COMMIT.equals(engineCommit)) {
            throw new IllegalStateException(
                    "XMage card qualification policy is for "
                            + ENGINE_COMMIT
                            + " but runtime is "
                            + engineCommit
            );
        }
    }

    static Restriction restrictionFor(String cardName) {
        return RESTRICTIONS.get(XmageBattleService.identityAliasKey(cardName));
    }

    static int restrictionCount() {
        return RESTRICTIONS.size();
    }

    static int activationRestrictionCount() {
        return ACTIVATION_RESTRICTED_NAMES.size();
    }

    static Set<String> transitionCardNames() {
        return TRANSITION_CARD_NAMES;
    }

    static int futureDeferredCount() {
        return FUTURE_DEFERRED_COUNT;
    }

    static int releasedMissingCount() {
        return RELEASED_MISSING_COUNT;
    }

    static boolean isTransitionActivationRestricted(String cardName) {
        return ACTIVATION_RESTRICTED_NAMES.contains(
                XmageBattleService.identityAliasKey(cardName)
        );
    }

    private static void register(
            Map<String, Restriction> restrictions,
            Restriction restriction
    ) {
        String key = XmageBattleService.identityAliasKey(restriction.cardName);
        Restriction previous = restrictions.put(key, restriction);
        if (previous != null) {
            throw new IllegalStateException(
                    "Duplicate XMage card qualification restriction: "
                            + restriction.cardName
            );
        }
    }

    private static ActivationPolicyStats loadActivationPolicy(
            Map<String, Restriction> restrictions
    ) {
        JsonObject policy;
        try (
                InputStream input = XmageCardQualificationPolicy.class
                        .getResourceAsStream(ACTIVATION_POLICY_RESOURCE)
        ) {
            if (input == null) {
                throw new IllegalStateException(
                        "Battle activation policy resource is missing"
                );
            }
            try (
                    InputStreamReader reader = new InputStreamReader(
                            input,
                            StandardCharsets.UTF_8
                    )
            ) {
                policy = JsonParser.parseReader(reader).getAsJsonObject();
            }
        } catch (IOException | RuntimeException error) {
            throw new IllegalStateException(
                    "Unable to load Battle activation policy",
                    error
            );
        }
        if (!ACTIVATION_POLICY_SCHEMA.equals(string(policy, "schema_version"))
                || !FROM_ENGINE_COMMIT.equals(
                        string(policy, "from_engine_commit")
                )
                || !ENGINE_COMMIT.equals(string(policy, "engine_commit"))
                || integer(policy, "blocked_card_count") != 133
                || integer(policy, "transition_card_count") != 169
                || integer(policy, "future_deferred_count") != 45
                || integer(policy, "released_missing_count") != 88) {
            throw new IllegalStateException(
                    "Battle activation policy identity or counts diverged"
            );
        }
        JsonObject postgres =
                policy.getAsJsonObject("postgresql_reconciliation");
        JsonObject semantics = policy.getAsJsonObject("policy");
        if (postgres == null
                || semantics == null
                || !POSTGRES_RECONCILIATION_SCHEMA.equals(
                        string(postgres, "schema_version")
                )
                || !POSTGRES_RECONCILIATION_SHA256.equals(
                        string(postgres, "artifact_sha256")
                )
                || !POSTGRES_ROWS_SHA256.equals(
                        string(postgres, "rows_sha256")
                )
                || !bool(postgres, "transaction_read_only")
                || bool(postgres, "writes_performed")
                || bool(semantics, "catalog_absence_is_semantic_proof")
                || bool(semantics, "future_release_is_semantic_proof")
                || !bool(
                        semantics,
                        "activation_requires_new_versioned_review"
                )
                || !bool(
                        semantics,
                        "user_facing_reason_must_be_engine_neutral"
                )) {
            throw new IllegalStateException(
                    "Battle activation policy provenance diverged"
            );
        }
        String transitionId = string(policy, "transition_id");
        JsonArray transitionCardNames =
                policy.getAsJsonArray("transition_card_names");
        JsonArray cards = policy.getAsJsonArray("cards");
        if (transitionId.isEmpty()
                || transitionCardNames == null
                || transitionCardNames.size() != 169
                || cards == null
                || cards.size() != 133) {
            throw new IllegalStateException(
                    "Battle activation policy rows are incomplete"
            );
        }

        Set<String> transitionNames = new HashSet<>();
        Set<String> normalizedTransitionNames = new HashSet<>();
        for (JsonElement element : transitionCardNames) {
            if (!element.isJsonPrimitive()) {
                throw new IllegalStateException(
                        "Battle transition card identity is invalid"
                );
            }
            String cardName = element.getAsString();
            String key = XmageBattleService.identityAliasKey(cardName);
            if (cardName.isEmpty()
                    || !transitionNames.add(cardName)
                    || !normalizedTransitionNames.add(key)) {
                throw new IllegalStateException(
                        "Duplicate Battle transition card identity: "
                                + cardName
                );
            }
        }

        Set<String> names = new HashSet<>();
        int futureDeferred = 0;
        int releasedMissing = 0;
        for (JsonElement element : cards) {
            if (!element.isJsonObject()) {
                throw new IllegalStateException(
                        "Battle activation policy card row is invalid"
                );
            }
            JsonObject row = element.getAsJsonObject();
            String cardName = string(row, "card_name");
            String scopeStatus = string(row, "product_scope_status");
            String reasonCode = string(row, "reason_code");
            String releaseCondition = string(row, "release_condition");
            String sourcePath = string(row, "source_path");
            if (cardName.isEmpty()
                    || sourcePath.isEmpty()
                    || !"battle_card_activation_review_required".equals(
                            reasonCode
                    )
                    || !"repeat_product_identity_oracle_legality_and_semantic_review"
                    .equals(releaseCondition)
                    || !scopeStatus.equals("future_deferred")
                    && !scopeStatus.equals("released_missing_from_postgresql")) {
                throw new IllegalStateException(
                        "Battle activation policy card row diverged"
                );
            }
            String key = XmageBattleService.identityAliasKey(cardName);
            if (!names.add(key)) {
                throw new IllegalStateException(
                        "Duplicate Battle activation policy card: " + cardName
                );
            }
            if ("future_deferred".equals(scopeStatus)) {
                futureDeferred++;
            } else {
                releasedMissing++;
            }
            Restriction existing = restrictions.get(key);
            if (existing != null) {
                if (!"Prudent Fateseer".equals(cardName)) {
                    throw new IllegalStateException(
                            "Unexpected overlap in Battle activation policy: "
                                    + cardName
                    );
                }
                continue;
            }
            register(
                    restrictions,
                    new Restriction(
                            cardName,
                            reasonCode,
                            "Battle support for this card awaits a new "
                                    + "release-scoped qualification.",
                            "manaloom-transition-policy:" + transitionId,
                            releaseCondition,
                            "activation_blocked",
                            scopeStatus
                    )
            );
        }
        if (names.size() != 133
                || futureDeferred != 45
                || releasedMissing != 88
                || !normalizedTransitionNames.containsAll(names)) {
            throw new IllegalStateException(
                    "Battle activation policy derived counts diverged"
            );
        }
        return new ActivationPolicyStats(
                names,
                transitionNames,
                futureDeferred,
                releasedMissing
        );
    }

    private static String string(JsonObject object, String key) {
        JsonElement value = object.get(key);
        return value == null || value.isJsonNull() ? "" : value.getAsString();
    }

    private static int integer(JsonObject object, String key) {
        JsonElement value = object.get(key);
        return value == null || value.isJsonNull() ? -1 : value.getAsInt();
    }

    private static boolean bool(JsonObject object, String key) {
        JsonElement value = object.get(key);
        return value != null
                && !value.isJsonNull()
                && value.getAsBoolean();
    }

    private static final class ActivationPolicyStats {
        final Set<String> names;
        final Set<String> transitionCardNames;
        final int futureDeferredCount;
        final int releasedMissingCount;

        ActivationPolicyStats(
                Set<String> names,
                Set<String> transitionCardNames,
                int futureDeferredCount,
                int releasedMissingCount
        ) {
            this.names = new HashSet<>(names);
            this.transitionCardNames = new HashSet<>(transitionCardNames);
            this.futureDeferredCount = futureDeferredCount;
            this.releasedMissingCount = releasedMissingCount;
        }
    }

    static final class Restriction {
        final String cardName;
        final String reasonCode;
        final String reason;
        final String upstreamReference;
        final String releaseCondition;
        final String supportStatus;
        final String productScopeStatus;

        Restriction(
                String cardName,
                String reasonCode,
                String reason,
                String upstreamReference,
                String releaseCondition
        ) {
            this(
                    cardName,
                    reasonCode,
                    reason,
                    upstreamReference,
                    releaseCondition,
                    "quarantined",
                    null
            );
        }

        Restriction(
                String cardName,
                String reasonCode,
                String reason,
                String upstreamReference,
                String releaseCondition,
                String supportStatus,
                String productScopeStatus
        ) {
            this.cardName = cardName;
            this.reasonCode = reasonCode;
            this.reason = reason;
            this.upstreamReference = upstreamReference;
            this.releaseCondition = releaseCondition;
            this.supportStatus = supportStatus;
            this.productScopeStatus = productScopeStatus;
        }

        Map<String, Object> evidence() {
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("support_status", supportStatus);
            result.put("reason_code", reasonCode);
            result.put("reason", reason);
            result.put("qualification_engine_commit", ENGINE_COMMIT);
            result.put("upstream_reference", upstreamReference);
            result.put("release_condition", releaseCondition);
            if (productScopeStatus != null) {
                result.put("product_scope_status", productScopeStatus);
            }
            return result;
        }
    }
}
