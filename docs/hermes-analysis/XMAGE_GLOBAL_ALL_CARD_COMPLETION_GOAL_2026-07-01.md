# XMage Global All-Card Completion Goal - 2026-07-01

Status: `active_operational_goal`.

This goal supersedes stale numeric baselines inside thread-level goal text. The
thread goal remains active, but execution must use the current post-PG344
baseline and the stop criteria below.

This is the global control plane for the remaining card-rule work. Individual
PG waves are implementation cycles inside this goal; they are not separate
goals and they do not redefine the stopping point.

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
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg332_graveyard_exile_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg332_graveyard_exile_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg333_graveyard_self_return_battlefield_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg333_graveyard_self_return_battlefield_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg334_graveyard_to_library_spell_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg334_graveyard_to_library_spell_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg335_battlefield_counter_recursion_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg335_battlefield_counter_recursion_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg336_activated_graveyard_to_library_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg336_activated_graveyard_to_library_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg337_etb_graveyard_to_library_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg337_etb_graveyard_to_library_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg338_reveal_library_pick_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg338_reveal_library_pick_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg339_etb_library_pick_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg339_etb_library_pick_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg340_spell_cast_draw_engine_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg340_spell_cast_draw_engine_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg341_recursion_auxiliary_spell_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg341_recursion_auxiliary_spell_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg342_recursion_exile_self_spell_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg342_recursion_exile_self_spell_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg343_recursion_mill_return_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg343_recursion_mill_return_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg344_static_graveyard_count_pt_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg344_static_graveyard_count_pt_wave_commander_legal.md`
- `docs/hermes-analysis/XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md`

Post-PG344 counts:

- all known cards: `34331`
- all-card readiness `battle_and_oracle_ready`: `2429`
- all-card readiness `battle_family_mapper_required`: `30118`
- all-card readiness `snapshot_has_verified_rule`: `3577`
- target battle-gap identities in authoritative queue: `27195`
- XMage authoritative source resolved: `26881`
- XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26881`
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

## Terminal Stop Definition

The final stop is reached only after the last cycle produces a fresh global
readiness report and authoritative XMage queue where every remaining card
identity is in exactly one closed state:

1. `battle_and_oracle_ready` through a reviewed PostgreSQL rule synced to
   Hermes/SQLite and visible in the canonical snapshot.
2. Generic/no-runtime-needed because the card has no Oracle rules text or no
   battle-executable behavior needed by ManaLoom.
3. Documented product exclusion or unsupported runtime lane with source
   evidence, owner-visible reason, and no silent fallback into deck/battle
   execution.
4. Manual/official/Forge exception lane for cards with no resolvable local
   XMage class, with the exception recorded separately from the XMage-resolved
   adapter backlog.

Any identity left as broad `xmage_*_review_v1`, parser gap, unresolved
missing-source exception, stale SQLite-only rule, or PostgreSQL/Hermes mismatch
means the global goal is still open.

## Work-Control Rule

Each working session must choose one of the following measurable outcomes before
it is considered useful progress:

1. Promote an exact runtime-backed PostgreSQL package and prove the refreshed
   queue decreased.
2. Add a reusable exact subpattern/runtime adapter with focused tests, then
   produce a package from it.
3. Exhaust a candidate family with blocker counts that change the next queue
   selection.
4. Classify a missing-source exception lane with source evidence and no
   executable ambiguity.

If a session does none of these, it is not allowed to claim progress. The next
action must be to rebuild the queue, inspect the largest remaining work units,
and select a different exact subpattern.

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

The cycle is recursive: after each commit/push, immediately start again from
the newly generated queue instead of returning to deck-specific intuition or
historical artifacts.

If a selected family produces no safe package candidates, record blocker counts
and continue to the next highest reusable work unit in the same goal. Do not
fall back to per-card implementation unless all reusable subpatterns for that
family are exhausted and the residual card is explicitly classified as manual.

## Current Priority Order

Use the post-PG344 authoritative queue unless a newer queue exists:

1. `recursion::xmage_graveyard_return_variant_review_v1` - `1891`
2. `draw_engine::xmage_draw_card_variant_review_v1` - `1646`
3. `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1` - `1162`
4. `direct_damage::targeted_damage_variant_v1` - `928`
5. `add_counters::source_add_counters_variant_v1` - `795`
6. `life_gain::xmage_life_gain_variant_review_v1` - `740`
7. `draw_cards::xmage_draw_card_variant_review_v1` - `676`
8. `removal_destroy::targeted_destroy_variant_v1` - `636`
9. `tutor::xmage_library_search_variant_review_v1` - `613`
10. `add_counters::targeted_add_counters_variant_v1` - `459`

Immediate checkpoint after PG344:

1. PG336 promoted the exact
   `xmage_permanent_simple_activated_graveyard_to_library_v1` subpattern for
   `Epitaph Golem`, `Haunted Crossroads`, and `Tomb Trawler`.
2. PG337 promoted the exact
   `xmage_creature_etb_put_graveyard_card_on_library_v1` subpattern for
   `Dukhara Scavenger` and `Meldweb Curator`.
3. PG338 promoted the exact
   `xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1` subpattern
   for `Commune with the Gods`, `Glacial Revelation`, `Grisly Salvage`,
   `Kruphix's Insight`, `Pieces of the Puzzle`, and `Scout the Borders`.
4. PG339 promoted the exact
   `xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1`
   subpattern for `Organ Hoarder`, `Sibsig Appraiser`, `Sultai Soothsayer`,
   and `Tower Geist`.
5. PG340 promoted the exact `xmage_spell_cast_draw_engine_v1` subpattern for
   `Beast Whisperer`, `Enchantress's Presence`,
   `Jhoira, Weatherlight Captain`, `Mesa Enchantress`, `Primordial Sage`,
   `Reki, the History of Kamigawa`, `Satyr Enchanter`, `Secrets of the Dead`,
   `Sram, Senior Edificer`, `Tanufel Rimespeaker`, `Thunderous Snapper`,
   `Vedalken Archmage`, `Verduran Enchantress`, and
   `Whirlwind of Thought`.
6. PG341 promoted the exact recursion auxiliary spell subpattern for
   `Morgue Theft`, `Mystic Retrieval`, `Unburial Rites`, `Unearth`, and
   `Wander in Death`, preserving flashback/cycling metadata and supported
   graveyard-to-hand/battlefield targets.
7. PG342 promoted exact self-exiling recursion spells for
   `Reconstruct History`, `Retrieve`, and `Vivid Revival`, including
   multi-component graveyard-to-hand selection and supported multicolored-card
   constraints.
8. PG343 promoted exact mill-then-return recursion spells/ETB creatures for
   `Acolyte of Affliction`, `Corpse Churn`, `Eccentric Farmer`,
   `Grapple with the Past`, and `Pothole Mole`.
9. PG344 promoted the exact
   `xmage_static_source_power_toughness_equal_graveyard_count_v1` subpattern
   for `Boneyard Wurm`, `Cantivore`, `Cognivore`, `Lord of Extinction`,
   `Magnivore`, `Revenant`, `Slag Fiend`, and `Terravore`.
10. PG336 is applied, synced, and E2E validated. The package evidence is in
   `docs/hermes-analysis/master_optimizer_reports/pg336_xmage_activated_graveyard_to_library_wave_package.md`,
   `docs/hermes-analysis/master_optimizer_reports/pg336_xmage_activated_graveyard_to_library_wave_pg_apply_evidence.md`,
   and
   `docs/hermes-analysis/master_optimizer_reports/pg336_xmage_activated_graveyard_to_library_wave_e2e_validation.md`.
11. PG337 is applied, synced, and E2E validated. The package evidence is in
   `docs/hermes-analysis/master_optimizer_reports/pg337_xmage_etb_graveyard_to_library_wave_package.md`,
   `docs/hermes-analysis/master_optimizer_reports/pg337_xmage_etb_graveyard_to_library_wave_pg_apply_evidence.md`,
   and
   `docs/hermes-analysis/master_optimizer_reports/pg337_xmage_etb_graveyard_to_library_wave_e2e_validation.md`.
12. PG338 is applied, synced, and E2E validated. The package evidence is in
   `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_package.md`,
   `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_pg_apply_evidence.md`,
   and
   `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_e2e_validation.md`.
13. PG339 is applied, synced, and E2E validated. The package evidence is in
   `docs/hermes-analysis/master_optimizer_reports/pg339_xmage_etb_library_pick_wave_package.md`,
   `docs/hermes-analysis/master_optimizer_reports/pg339_xmage_etb_library_pick_wave_pg_apply_evidence.md`,
   and
   `docs/hermes-analysis/master_optimizer_reports/pg339_xmage_etb_library_pick_wave_e2e_validation.md`.
14. PG340 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_pg_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_e2e_validation.md`.
15. PG341 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg341_xmage_recursion_auxiliary_spell_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg341_xmage_recursion_auxiliary_spell_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg341_xmage_recursion_auxiliary_spell_wave_e2e_validation.md`.
16. PG342 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_e2e_validation.md`.
17. PG343 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg343_xmage_recursion_mill_return_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg343_xmage_recursion_mill_return_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg343_xmage_recursion_mill_return_wave_e2e_validation.md`.
18. PG344 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg344_xmage_static_graveyard_count_pt_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg344_xmage_static_graveyard_count_pt_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg344_xmage_static_graveyard_count_pt_wave_e2e_validation.md`.
19. The post-PG344 supported splitter recheck returned `proposal_count=0` over
    `7952` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg344_supported_recheck.md`.
20. Continue from the fresh post-PG344 queue. The top reusable work unit remains
   `recursion::xmage_graveyard_return_variant_review_v1`, now at `1891`, so
   the next cycle should split another exact recursion subpattern unless a
   fresher queue changes the ranking.

## Non-Goals

- Do not prioritize only Lorehold, deck `607`, saved decks, or currently
  registered user decks. Those are QA seeds, not the global scope.
- Do not promote generic `xmage_*_review_v1` rows as executable PostgreSQL
  rules.
- Do not treat Hermes SQLite, old generated artifacts, or local JSON as source
  of truth over PostgreSQL.
- Do not count a cycle as successful unless it shrinks a queue dimension or
  leaves an explicit blocker report that changes the next selection.
