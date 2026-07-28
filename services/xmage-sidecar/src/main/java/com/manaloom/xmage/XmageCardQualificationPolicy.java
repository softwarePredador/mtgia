package com.manaloom.xmage;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Pin-scoped fail-closed policy for cards that resolve in XMage but are not
 * qualified for ManaLoom battle execution.
 *
 * <p>The policy commit must move with {@link SidecarMain#XMAGE_COMMIT}. That
 * makes a future pin update review every restriction explicitly instead of
 * silently inheriting or dropping it.</p>
 */
final class XmageCardQualificationPolicy {
    static final String ENGINE_COMMIT =
            "2c43ec8cdb5cd475d47e6b555a4077151f476a3b";

    private static final Map<String, Restriction> RESTRICTIONS;

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
        RESTRICTIONS = Collections.unmodifiableMap(restrictions);
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

    static final class Restriction {
        final String cardName;
        final String reasonCode;
        final String reason;
        final String upstreamReference;
        final String releaseCondition;

        Restriction(
                String cardName,
                String reasonCode,
                String reason,
                String upstreamReference,
                String releaseCondition
        ) {
            this.cardName = cardName;
            this.reasonCode = reasonCode;
            this.reason = reason;
            this.upstreamReference = upstreamReference;
            this.releaseCondition = releaseCondition;
        }

        Map<String, Object> evidence() {
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("support_status", "quarantined");
            result.put("reason_code", reasonCode);
            result.put("reason", reason);
            result.put("qualification_engine_commit", ENGINE_COMMIT);
            result.put("upstream_reference", upstreamReference);
            result.put("release_condition", releaseCondition);
            return result;
        }
    }
}
