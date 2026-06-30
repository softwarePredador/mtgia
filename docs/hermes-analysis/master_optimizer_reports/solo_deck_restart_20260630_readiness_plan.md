# Solo Deck Restart Readiness Plan

- Generated at: `2026-06-30T14:22:00Z`
- Branch: `codex/solo-consolidation-20260630`
- Baseline deck: `607`
- Lorehold variants checked: `608, 609, 610, 611, 612, 613, 614, 615, 616`
- Source SQLite: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- PostgreSQL writes: `false`
- Deck mutations: `false`

## Current Evidence

| Report | Result |
| --- | --- |
| `solo_deck_restart_20260630_variant_gap_miner` | 270 variant-only cards; 243 runtime-ready unexplored; 18 tested-negative adds; 0 gate-ready pairings. |
| `solo_deck_restart_20260630_runtime_gap_family_queue` | 9 raw runtime gaps, with `Birgi` filtered by current verified/auto rule evidence; 8 remaining split-scope family gaps. |
| `solo_deck_restart_20260630_runtime_candidate_readiness` | 13 reviewed cards; 2 applied/synced packages; 3 review-required access cards; 8 split-scope review cards. |
| `solo_deck_restart_20260630_next_action_planner` | 0 gate-ready actions; next action is review focus-access trace, then define deck/runtime package. |
| `solo_deck_restart_20260630_ideal_deck_candidate_matrix` | 348 rows; 340 battle-ready; 5 no-rule-signal; 3 package-already-prepared; 172 priority benchmark candidates. |
| `solo_deck_restart_20260630_registry_runner_dryrun` | Runner ready, but no queue rows emitted for the current registry dry-run slice. |

## Cards Still Blocking Rule-First Strategy

These are the only cards still marked `needs_rule_before_strategy` after fixing basic-land and face-alias false positives.

| Card | Decks | Roles | Score | Required next action |
| --- | --- | --- | ---: | --- |
| `Deathbellow War Cry` | `616` | tutor | 21.5 | Reconcile mapper exact scope, then focused tutor/runtime test before benchmark. |
| `Charmbreaker Devils` | `612` | unknown | -1.0 | Inspect XMage trigger/recursion behavior and decide if this is worth runtime work. |
| `Naktamun Lorespinner // Wheel of Fortune` | `608` | unknown | -2.0 | Split draw-engine/wheel scope or postpone if not a deck priority. |
| `Karn's Sylex` | `610` | unknown | -6.0 | Keep review-only unless a Karn/Sylex package becomes strategically relevant. |
| `Karn, the Great Creator` | `610` | unknown | -6.0 | Keep review-only unless a Karn artifact-lock/wish package becomes strategically relevant. |

## Prepared But Not Final Truth

These are not hard blockers for strategy discovery, but they should not be promoted as durable PostgreSQL truth without the normal package/hash/precheck/postcheck workflow.

| Card | Decks | Current status | Practical decision |
| --- | --- | --- | --- |
| `Chandra's Ignition` | `613` | package already prepared / watchlist | Do not benchmark as final until wipe/damage runtime confidence is explicit. |
| `Blood Moon` | `616` | package already prepared / watchlist | Mapper exact scope can be reconciled, but static lock runtime semantics need explicit confidence. |
| `Ancient Gold Dragon` | `612` | package already prepared / low priority | Runtime-local test exists from Agent 3; PG promotion remains pending. |

## First Battle-Ready Benchmark Pool

The first safe pool for deckbuilding work, after baseline/hash guard and cut-lane model, is:

1. `Mizzix's Mastery`
2. `Library of Leng`
3. `Reforge the Soul`
4. `Deflecting Swat`
5. `Restoration Seminar`
6. `Enlightened Tutor`
7. `Gamble`
8. `Monument to Endurance`
9. `Sensei's Divining Top`
10. `Teferi's Protection`
11. `Scroll Rack`
12. `Boros Charm`
13. `Silence`
14. `Big Score`
15. `Storm-Kiln Artist`
16. `Olórin's Searing Light`
17. `Brass's Bounty`
18. `Volcanic Vision`
19. `Improvisation Capstone`
20. `Smothering Tithe`

`Lorehold, the Historian` appears as a high benchmark row in the historical matrix because that matrix is variant-focused; direct SQLite inspection confirms deck `607` already has `Lorehold, the Historian` marked as commander.

## Blocking Work Before Returning To Deck Swaps

1. Reconcile mapper work manually. Use the safer generic `xmage_*_review_v1` downgrade guard from `codex/session-agent-xmage-mapper-20260630`, then re-add only exact scopes that prove batch safety. Do not merge Agent 2 as-is.
2. Fix rule-first queue noise before strategy gates. This branch already fixed basic lands and face-alias matching in `lorehold_ideal_deck_candidate_matrix.py`.
3. Decide whether to close or defer the five rule-first cards. Prioritize `Deathbellow War Cry`; defer Karn/Sylex unless the deck strategy wants them.
4. Build cut/lane models. The miner found 0 gate-ready pairings; the blocker is safe cuts, not lack of battle-ready additions.
5. Only then run slot/battle benchmarks with drawn/cast/used evidence. Aggregate battle result alone remains insufficient.

## Ready State

The solo branch is now the correct continuation branch. The next actual implementation task should be one of:

- mapper reconciliation for `Deathbellow War Cry`, `Blood Moon`, and generic review-scope guardrails;
- runtime/package closure for `Ancient Gold Dragon`;
- cut-lane model generation for the first battle-ready benchmark pool;
- baseline/hash guarded deck benchmark for a single package after cut model exists.

## Validation

| Command | Status | Result |
| --- | --- | --- |
| `python3 -m unittest test_lorehold_ideal_deck_candidate_matrix.py test_lorehold_607_research_candidate.py test_lorehold_variant_battle_gate.py test_lorehold_focus_access_package_generator.py test_lorehold_registry_candidate_runner.py test_operational_surface_alignment_audit.py` | pass | `52 tests OK` |
| `python3 test_artifact_topdeck_runtime.py && python3 test_session_agent3_finisher_draw_recursion_runtime.py` | pass | both runtime tests passed |
| `python3 xmage_strategy_consistency_audit.py --output-prefix /tmp/solo_deck_restart_xmage_strategy` | pass | `26 checks pass` |
| `python3 operational_surface_alignment_audit.py --out-prefix /tmp/solo_deck_restart_operational_surface` | pass | status `pass` |
| `python3 deckbuilding_contract_surface_audit.py --out-prefix /tmp/solo_deck_restart_deckbuilding_contract` | pass | status `pass` |
| `python3 pg_hermes_sqlite_contract_audit.py --skip-pg --sqlite-db /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --out-prefix /tmp/solo_deck_restart_pg_hermes_sqlite_skip_pg` | pass with warnings | `29 pass`, `3 warn`; PostgreSQL skipped |
