# Lorehold From-Scratch Challenger Builder

- generated_at: `2026-07-04T23:37:12.733968+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- corpus_deck_ids: `607, 608, 609, 610, 611, 612, 613, 614, 615, 616`
- protected_baseline_deck_id: `607`
- from_scratch_policy: `607 may be a corpus source and fixed opponent, but no candidate is generated as a 607 swap list`
- postgres_writes: `false`
- source_db_mutated: `false`

## Challengers

| Candidate | Intent Score | Lands | Ramp | Draw | Protection | Wincon | Missing Required | Battle Gate |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| [Lorehold From-Scratch Spell Volume Access Depressure v1](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260704_spell_volume_access_depressure_spell_volume_access_depressure.md) | 100.0 | 34 | 18 | 14 | 14 | 9 | none | `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260704_spell_volume_access_depressure_spell_volume_access_depressure_fixed607_gate.json` |

## Next Gate

Run each emitted battle command. The fixed opponent deck id is `607`, and the protected baseline `607` also remains the only registered deck in `--deck-ids`, so the same run compares the challenger to baseline behavior and to a table that always includes deck 607 as one opponent.
