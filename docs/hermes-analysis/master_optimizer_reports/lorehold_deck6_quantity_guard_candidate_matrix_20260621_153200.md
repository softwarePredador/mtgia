# Lorehold Deck 6 Quantity Guard Candidate Matrix - 2026-06-21

## Scope

This report records the post-fix Lorehold deck candidate cycle after a runtime
deck-loader bug was found: `deck_cards.quantity=0` rows were still being loaded
as one copy. The bug made earlier candidate battle evidence unsafe because
temporary cuts could remain in the simulated deck.

No PostgreSQL deploy, PostgreSQL rollback, official deck swap, commit, push,
stash, revert, or cleanup was performed in this cycle.

## Runtime Fix

- File fixed: `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`.
- Behavior fixed: `load_deck_cards()` now keeps legacy `NULL` quantity as one
  copy but skips `quantity <= 0`.
- Regression added:
  `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_import_tests.py`
  `test_load_deck_ignores_zero_quantity_rows`.
- Test evidence:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed, including the new import regression and the prior tutor-without-target
  stack-casting regression.

## Candidate Evidence

All candidates used the same seed window: `--seeds 16 --start-seed 63212310`.
Each candidate was applied only to local Hermes SQLite, validated by
`load_deck_with_construction_report()`, run through the battle-strategy audit,
and then restored to the official SQLite shape.

| Artifact | Candidate | Final status | Deck source | Lorehold wins | Opponent wins | Stall | Reading |
| --- | --- | --- | --- | ---: | ---: | ---: | --- |
| `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_174142/summary.json` | Magus + Sphere before tutor/quantity cleanup | `review_required` | contaminated by later quantity issue | 5 | 11 | 0 | Not promotable; `tutor_no_target=1` and review gates. |
| `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_175408/summary.json` | Magus + Sphere after tutor guard, before quantity guard | `trusted_for_strategy_learning` | invalid Lorehold deck source | 4 | 11 | 1 | Not promotable; zero-quantity cuts were still loaded, producing 101 main / 102 total. |
| `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_180442/summary.json` | Magus + Sphere after quantity guard | `trusted_for_strategy_learning` | `{"none":64}` | 5 | 11 | 0 | Best clean candidate so far, but still only 31.25 percent in this window. |
| `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_181316/summary.json` | Magus + Sphere + Wrath over Austere | `trusted_for_strategy_learning` | `{"none":64}` | 4 | 12 | 0 | Rejected; worse win count and more low-confidence mulligan findings. |
| `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_181905/summary.json` | Magus + Sphere + Norn's Annex over Austere | `trusted_for_strategy_learning` | `{"none":64}` | 5 | 10 | 1 | Not better than Magus + Sphere; longer run/stall and five low-confidence mulligan findings. |

## Battle Log Evidence

Clean win example:

- Artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_180442/seed_63212311/replay.txt`.
- Seed: `63212311`.
- Result: `Winner: Lorehold (elimination)`.
- Relevant sequence:
  - `Sphere of Safety` was announced, paid, cast, and resolved on turn 15.
  - `Silent Arbiter` was cast and resolved on turn 16.
  - Lorehold eliminated the final opponent on turn 17.

Failure pattern:

- Across the clean Magus+Sphere candidate, losses were still mostly combat
  deaths under real target pressure.
- Target-pressure evidence for `20260621_180442`:
  `target_pressure_statuses={"pass":16}`,
  `target_pressure_opponent_combat_to_target=248`,
  `target_pressure_opponent_combat_to_other=3`.
- Several losing seeds never resolved a relevant defensive permanent before
  lethal combat; others resolved one late or had it countered/removed.

## Decision

- Do not promote any candidate to PostgreSQL yet.
- Do not apply a permanent deck swap yet.
- Treat the loader quantity guard as a real runtime correctness fix.
- Treat Magus + Sphere as the best clean candidate signal so far, but still
  insufficient for deployment because it only reached `5/16`.
- Next deck work should focus on earlier survivability and closing speed, not
  simply adding more expensive pillowfort cards.

## Restored Official State

Post-run local SQLite was restored:

- `deck_cards` for deck `6`: `100` rows / `100` summed quantity.
- Focused official rows restored:
  `Austere Command=1`, `Electroduplicate=1`, `Victory Chimes=1`.
- Focused candidates absent from official deck after restore:
  `Magus of the Moat`, `Sphere of Safety`, `Norn's Annex`, `Wrath of God`.
