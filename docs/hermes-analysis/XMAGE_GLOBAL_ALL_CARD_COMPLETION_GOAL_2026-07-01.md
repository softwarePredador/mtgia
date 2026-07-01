# XMage Global All-Card Completion Goal - 2026-07-01

Status: `active_operational_goal`.

This goal supersedes stale numeric baselines inside thread-level goal text. The
thread goal remains active, but execution must use the current post-PG331
baseline and the stop criteria below.

## Objective

Finish the global XMage -> ManaLoom card-rule adaptation for every applicable
ManaLoom all-card/Commander-legal battle-gap identity without switching back to
card-by-card semantic approval.

Resolved local XMage source is accepted as final card-behavior truth. ManaLoom
work is adapter/runtime translation, exact-scope validation, PostgreSQL
promotion, Hermes/SQLite sync, and audit evidence.

## Current Baseline

Source artifacts:

- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg331_creature_dies_recursion_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg331_creature_dies_recursion_wave_commander_legal.md`
- `docs/hermes-analysis/XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md`

Post-PG331 counts:

- all known cards: `34331`
- all-card readiness `battle_and_oracle_ready`: `2362`
- all-card readiness `battle_family_mapper_required`: `30185`
- target battle-gap identities in authoritative queue: `27262`
- XMage authoritative source resolved: `26948`
- XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26948`
- adapter work-unit keys: `11429`

## Completion Criteria

Stop only when a freshly regenerated global queue and readiness report prove all
of these conditions:

1. `xmage_authoritative_adapter_required_count = 0`.
2. `xmage_authoritative_parser_gap_count = 0`.
3. `xmage_missing_source_exception_count = 0`, or every remaining exception is
   explicitly classified with evidence as official-source/manual-model,
   Forge-cross-check, unsupported/non-product, or no-runtime-needed.
4. No applicable all-card/Commander-legal identity remains in
   `battle_family_mapper_required` without a documented executable rule,
   generic/no-card-rule classification, or explicit exclusion.
5. PostgreSQL is the source of truth for every promoted executable rule, with
   matching `oracle_hash` for newly touched rows.
6. Hermes SQLite and `known_cards_canonical_snapshot.json` are synced from
   PostgreSQL after the final apply.
7. Focused runtime tests, E2E package validation, XMage strategy audit,
   operational surface audit, PG/Hermes/SQLite contract audit, and legacy
   contamination audit pass.
8. Final evidence is committed and pushed.

The goal is not complete just because a deck runs, a family looks broadly
mapped, or a generated `xmage_*_review_v1` scope exists. Broad review scopes are
planning lanes, not executable rules.

## Required Cycle

Repeat this cycle until the completion criteria are met:

1. Regenerate global all-card readiness and authoritative XMage adaptation
   queue.
2. Select the highest reusable work unit from the fresh queue.
3. Split it into a narrow `battle_model_scope` using XMage Java class/effect,
   Oracle text, target/cost constraints, and explicit blocker reasons.
4. Implement only exact runtime-backed behavior in the splitter and
   `battle_analyst_v9.py`.
5. Add focused positive and negative tests for the exact scope.
6. Generate PostgreSQL precheck/apply/rollback/postcheck package.
7. Apply PostgreSQL only through precheck -> apply -> postcheck.
8. Sync PostgreSQL -> Hermes/SQLite and refresh the canonical snapshot.
9. Run E2E validation and final alignment audits.
10. Rebuild readiness/queue and record the actual queue reduction.

If a selected family produces no safe package candidates, record blocker counts
and continue to the next highest reusable work unit in the same goal. Do not
fall back to per-card implementation unless all reusable subpatterns for that
family are exhausted and the residual card is explicitly classified as manual.

## Current Priority Order

Use the post-PG331 authoritative queue unless a newer queue exists:

1. `recursion::xmage_graveyard_return_variant_review_v1` - `1944`
2. `draw_engine::xmage_draw_card_variant_review_v1` - `1660`
3. `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1` - `1162`
4. `direct_damage::targeted_damage_variant_v1` - `928`
5. `add_counters::source_add_counters_variant_v1` - `795`
6. `life_gain::xmage_life_gain_variant_review_v1` - `740`
7. `draw_cards::xmage_draw_card_variant_review_v1` - `676`
8. `removal_destroy::targeted_destroy_variant_v1` - `636`
9. `tutor::xmage_library_search_variant_review_v1` - `613`
10. `add_counters::targeted_add_counters_variant_v1` - `459`

Immediate checkpoint before PG332:

1. Finish PG331 evidence closure: final supported-split recheck, strategy audit,
   operational audit, PG/Hermes/SQLite contract audit, legacy contamination
   audit, doc update, commit, and push.
2. Continue splitting the highest reusable work unit,
   `recursion::xmage_graveyard_return_variant_review_v1`, into another exact
   runtime-backed subpattern.
3. If the post-PG331 supported splitter recheck has `proposal_count=0`, the next
   package must add a new exact subpattern rather than rerunning the current
   splitter unchanged.

## Non-Goals

- Do not prioritize only Lorehold, deck `607`, saved decks, or currently
  registered user decks. Those are QA seeds, not the global scope.
- Do not promote generic `xmage_*_review_v1` rows as executable PostgreSQL
  rules.
- Do not treat Hermes SQLite, old generated artifacts, or local JSON as source
  of truth over PostgreSQL.
- Do not count a cycle as successful unless it shrinks a queue dimension or
  leaves an explicit blocker report that changes the next selection.
