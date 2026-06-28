# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T11:54:52.051057+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`

| Package | Adds | Cuts | Baseline | Candidate | Delta | Decision |
| --- | --- | --- | --- | --- | ---: | --- |
| one_ring_burden_reset | The One Ring | Artist's Talent | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | reject_or_rework |
| etb_tutor_blink | Imperial Recruiter, Recruiter of the Guard, Ranger-Captain of Eos | Prismari Pianist, Furygale Flocking, Tempt with Bunnies | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | reject_or_rework |
| sun_titan_blink_value | Sun Titan | Storm Herd | 3/0/0 `100.00%` | 3/0/0 `100.00%` | +0.00 | reject_or_rework |
| artifact_etb_value | Archaeomancer's Map, Soul-Guide Lantern, The One Ring | Bender's Waterskin, Artist's Talent, Tempt with Bunnies | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | reject_or_rework |

## Package Notes

### one_ring_burden_reset

- hypothesis: The Mind Stone can reset The One Ring burden counters after harness; test whether that draw engine beats the current Artist's Talent slot.
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v1_20260627_114609_one_ring_burden_reset/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v1_20260627_114609_one_ring_burden_reset.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v1_20260627_114609_one_ring_burden_reset.json`
- gate_returncode: `0`

### etb_tutor_blink

- hypothesis: The Mind Stone blink becomes materially stronger when it can reuse creature tutors that find protection and cheap engines.
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v1_20260627_114609_etb_tutor_blink/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v1_20260627_114609_etb_tutor_blink.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v1_20260627_114609_etb_tutor_blink.json`
- gate_returncode: `0`

### sun_titan_blink_value

- hypothesis: Sun Titan plus The Mind Stone creates repeatable permanent recursion for the deck's cheap artifacts, protection, and engines.
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v1_20260627_114609_sun_titan_blink_value/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v1_20260627_114609_sun_titan_blink_value.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v1_20260627_114609_sun_titan_blink_value.json`
- gate_returncode: `0`

### artifact_etb_value

- hypothesis: Artifact ETB cards from the Lorehold corpus may turn Mind Stone blink into mana/card velocity rather than a shallow utility mode.
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v1_20260627_114609_artifact_etb_value/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v1_20260627_114609_artifact_etb_value.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v1_20260627_114609_artifact_etb_value.json`
- gate_returncode: `0`
