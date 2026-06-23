# Boros Charm PG030 Focused Event Proof

Generated: 2026-06-22 19:38 UTC

Artifacts:

- Events: `docs/hermes-analysis/master_optimizer_reports/boros_charm_pg030_focused_events_20260622_193818.jsonl`

Rule evidence:

- logical_rule_key: `battle_rule_v1:32605a838d7a519f44eaa0899d2c40bf`
- oracle_hash: `98a7be829075118b499a7c283a23501f`
- active effect: `modal_boros_charm`
- battle_model_scope: `boros_charm_choose_one_damage_indestructible_double_strike_v1`

Scenarios:

1. `indestructible_all_permanents`
   - `spell_resolved` emitted with the PG030 logical rule key.
   - `modal_boros_charm_resolved` selected `permanents_you_control_gain_indestructible_until_eot`.
   - A creature, artifact, enchantment, and land all received temporary indestructible.
   - `clear_until_eot` removed the temporary keyword from all four permanents.

2. `double_strike_single_target`
   - `spell_resolved` emitted with the PG030 logical rule key.
   - `modal_boros_charm_resolved` selected `target_creature_gains_double_strike_until_eot`.
   - Exactly one creature (`Large Creature`) received temporary double strike.
   - `clear_until_eot` removed the temporary keyword.

Caveat:

- The 4 damage player/planeswalker mode remains `annotation_only` metadata in PG030 because this runtime path does not yet select direct-damage modal targets.
