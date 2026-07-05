# Lorehold From-Scratch Challenger Builder

- generated_at: `2026-07-05T13:28:38.482065+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- corpus_deck_ids: `607, 608, 609, 610, 611, 612, 613, 614, 615, 616`
- protected_baseline_deck_id: `607`
- from_scratch_policy: `607 may be a corpus source and fixed opponent, but no candidate is generated as a 607 swap list`
- postgres_writes: `false`
- source_db_mutated: `false`

## Challengers

| Candidate | Intent Score | Lands | Ramp | Draw | Protection | Wincon | Missing Required | Battle Gate |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| [Lorehold From-Scratch Access Density Control v1](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260705_authorized_smoke_access_density_control.md) | 93.814 | 34 | 18 | 17 | 15 | 7 | none | `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260705_authorized_smoke_access_density_control_fixed607_gate.json` |
| [Lorehold From-Scratch Spell Volume Access Depressure v1](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260705_authorized_smoke_spell_volume_access_depressure.md) | 100.0 | 34 | 18 | 14 | 14 | 9 | none | `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260705_authorized_smoke_spell_volume_access_depressure_fixed607_gate.json` |
| [Lorehold From-Scratch Spell Pressure Mana Conversion Deoverfill v1](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260705_authorized_smoke_spell_pressure_mana_conversion_deoverfill.md) | 100.0 | 34 | 19 | 15 | 14 | 8 | none | `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260705_authorized_smoke_spell_pressure_mana_conversion_deoverfill_fixed607_gate.json` |

## Next Gate

Run each emitted battle command. The fixed opponent deck id is `607`, and the protected baseline `607` also remains the only registered deck in `--deck-ids`, so the same run compares the challenger to baseline behavior and to a table that always includes deck 607 as one opponent.
