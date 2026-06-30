# Lorehold Deck Learning Goal Decision - 2026-06-30

- Status: `no_deck_promotion`
- Baseline protected: `deck_607`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Contract: `docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md`

## Decision

Keep `deck_607` as the definitive protected Lorehold baseline.

The current learning cycle proved useful package behavior, but no challenger or
swap package is promotable. The Squee recursion route is real when accessed,
but the from-scratch recursion shells lose too much miracle/topdeck frequency,
spell-chain volume, and win conversion versus protected `607`.

Do not create blind swaps. The next valid deck step is focused operational work:
improve the Squee/access-density and safe-cut model until it produces a
non-protected, failure-targeted package that can be naturally gated.

## Method Used

The cycle followed the frozen Commander deckbuilding contract:

1. preserve `607` as protected baseline;
2. use access/tutor/hand-filter cut models before battle;
3. build challengers only with explicit strategy hypotheses;
4. require natural battle gates against the same opponent set;
5. require card-use/trace evidence before card-level conclusions;
6. reject cross-lane or protected-anchor cuts without equal-gate proof.

## Cut And Package Models

Access model:

- Artifact: `lorehold_access_cut_model_20260630_after_profiled_gate_goal_current.md`
- Candidate count: `5`
- Deck rows evaluated: `94`
- Pair count: `470`
- Preflight-ready access swaps: `0`
- Status: `squee_route_modeled_access_density_needed`
- Next action: `no_access_swap_ready; build_new_seed_safe_cut`

Tutor model:

- Artifact: `lorehold_tutor_cut_model_20260630_goal_definitive_learning_v1.md`
- Candidate count: `2`
- Pair count: `188`
- Direct gate-ready swaps: `0`

Hand-filter model:

- Artifact: `lorehold_hand_filter_cut_model_20260630_goal_definitive_learning_v1.md`
- Candidate count: `5`
- Expanded pair count: `445`
- Expanded preflight-ready swaps: `0`

Focus-access package generator:

- Artifact: `lorehold_focus_access_package_generator_20260630_goal_definitive_learning_current.md`
- Package candidates evaluated: `52`
- Gate-ready packages: `0`
- Status counts: `blocked_no_safe_cut=30`, `blocked_no_target_failure_mode=15`,
  `blocked_prior_negative_exact=3`, `blocked_protected_cut=2`,
  `trace_or_runtime_probe_required=2`
- Recommended action:
  `do_not_create_blind_swap; run focused trace/runtime/cut-model work first`

## Challenger Results

From-scratch challengers:

- `miracle_topdeck_control`: smoke `0/4`; rejected.
- `spellchain_big_sorcery`: smoke `0/4`; rejected.
- `recursion_discard_engine`: smoke tied `1/4`, confirm `4/24` versus `607`
  `6/24`; rejected as full deck.
- `recursion_discard_pressure_repair`: smoke tied `1/4`, confirm `3/24`
  versus `607` `6/24`; rejected as full deck.

Current clean confirmation artifact:

- `lorehold_from_scratch_challengers_20260630_goal_pressure_repair_v1_recursion_discard_pressure_repair_confirm8x3_sources_v3.md`

Clean confirmation result:

| Deck | Games | W | L | S | WR | Miracle | Topdeck | Lorehold Spell Casts | Squee GY | Squee Return |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `deck_607` | 24 | 6 | 18 | 0 | 25.00% | 40 | 26 | 183 | 0 | 0 |
| `recursion_discard_pressure_repair` | 24 | 3 | 21 | 0 | 12.50% | 25 | 18 | 127 | 12 | 13 |

Interpretation:

- Squee recursion works: `squee_to_graveyard=12`,
  `squee_upkeep_return=13`, `squee_return_after_known_graveyard_entry=11`,
  and `lorehold_rummage_discards_squee=7`.
- The full recursion shell is worse than `607`: fewer Lorehold spell casts,
  fewer miracle casts, fewer topdeck activations, and lower win rate.
- `Squee` should remain a package-learning lane, not a current whole-deck
  replacement strategy.

## Runtime Fixes From This Cycle

The gate exposed telemetry/runtime issues that would have polluted deck
learning:

- attack restriction details now attribute `Crawlspace`, `Silent Arbiter`, and
  `Promise of Loyalty` instead of reporting `unattributed`;
- `Kayla's Music Box` now emits reachable play-from-exile replay events with
  `source_zone=exile`, locked cost, rule key, and rule hash;
- `Possibility Storm` free-cast tests now preserve explicit
  `damage_each_opponent` effect payloads for runtime test cards;
- Brainstone decision-trace tests now expect the current PG272 executable scope
  `brainstone_draw_three_put_two_back_for_first_draw_miracle_v1`.

Clean attack-restriction telemetry after the fix:

- `deck_607`: `Promise of Loyalty` restricted `3` attackers.
- `recursion_discard_pressure_repair`: `Silent Arbiter` restricted `52`,
  `Promise of Loyalty` restricted `6`, and `Crawlspace` restricted `1`.
- `unattributed` sources: `0`.

## Alignment Gates

- `test_battle_analyst_v10_3.py`: pass.
- `pytest` for access/tutor/from-scratch builder tests: `17 passed`.
- `deckbuilding_contract_surface_audit_20260630_goal_definitive_learning_current`: pass.
- `xmage_strategy_consistency_audit_20260630_goal_definitive_learning_current`: pass.
- `operational_surface_alignment_audit_20260630_goal_definitive_learning_current_v2`: pass.

Operational correction:

- `operational_surface_alignment_audit.py` now checks the current zero-gap
  runtime queue default:
  `lorehold_runtime_gap_family_queue_20260630_definitive_learning_v1.json`.

## Next Allowed Work

Only these next steps are valid from the current evidence:

1. run or improve `squee_access_density_model`;
2. find a new seed-safe, non-protected cut for Squee/access support;
3. do not cut `Bender's Waterskin`, `Victory Chimes`, `Molecule Man`,
   `The Scarlet Witch`, `The Mind Stone`, `Insurrection`, `Storm Herd`, or
   `Creative Technique` without same-lane proof;
4. once a gate-ready package exists, run natural gate against `607` with card
   access/use evidence;
5. promote only if it ties or beats `607` without regressing Winota/fast
   pressure and without reducing miracle/topdeck/spell-chain telemetry.
