# Lorehold Unresolved Rule Rows Audit - 2026-06-27

- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Summary: `5` deck materialization gaps, `1` missing battle-rule/model gap, `0` already ready.

| Card | Deck Rule Count | Active Rule Count | Decision | Action | Evidence |
| --- | ---: | ---: | --- | --- | --- |
| The Scarlet Witch | 0 | 1 | `deck_rule_materialization_gap` | `fixed_for_future_equal_gates_by_deck_rule_materialization_sweep` | battle_rule_v1:0b23c5f26d2bc884b7f506cdd9d422fc |
| Molecule Man | 0 | 1 | `deck_rule_materialization_gap` | `fixed_for_future_equal_gates_by_deck_rule_materialization_sweep` | battle_rule_v1:752f8cfd0a44d1889ffdb40610847374 |
| The Mind Stone | 0 | 1 | `deck_rule_materialization_gap` | `fixed_for_future_equal_gates_by_deck_rule_materialization_sweep` | battle_rule_v1:57bb1f91d9eea2ad14a8e8d24d2f8d53 |
| Thor, God of Thunder | 0 | 0 | `missing_battle_rule_model` | `create_reviewed_battle_card_rule_and_runtime_family_before_trusting_gate_result` | Flying When Thor enters, exile target Equipment, instant, or sorcery card from your graveyard. Until the end of your next turn, you may play that card. Whenever you cast a noncreat... |
| Emeria's Call // Emeria, Shattered Skyclave | 0 | 1 | `deck_rule_materialization_gap` | `fixed_for_future_equal_gates_by_deck_rule_materialization_sweep` | battle_rule_v1:ae4a933d873bec332ec2a46106b79277 |
| Tragic Arrogance | 0 | 1 | `deck_rule_materialization_gap` | `fixed_for_future_equal_gates_by_deck_rule_materialization_sweep` | battle_rule_v1:d4d676e6ecea500f7aca4cbc7f7ae04a |

## Read

- The repeated per-card work should shrink here: five rows already had reviewed active rules and only needed candidate-deck rule materialization.
- `Thor, God of Thunder` is the remaining real modeling item in this six-card set. Its rule family must cover graveyard impulse recast on ETB plus noncreature-spell damage triggers before battle evidence can judge it fairly.
- Temp-copy verification of the new materializer filled `93` deck rows; in the six-card focus set, it changed the five rule-backed cards to rule count `1` and left only `Thor, God of Thunder` at `0`.
