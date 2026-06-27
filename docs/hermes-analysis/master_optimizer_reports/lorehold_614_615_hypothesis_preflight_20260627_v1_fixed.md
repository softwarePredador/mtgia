# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T20:03:50.158824+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `True`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v3.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json`
- package_status_counts: `{"preflight_ready": 6}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| perch_protection_cut_avatar_wrath | pressure_absorber | Perch Protection | Avatar's Wrath | `clear` | - | - | +0.00 | - | preflight_ready |
| akromas_will_cut_avatar_wrath | pressure_absorber | Akroma's Will | Avatar's Wrath | `clear` | - | - | +0.00 | - | preflight_ready |
| silence_cut_avatar_wrath | spell_protection | Silence | Avatar's Wrath | `clear` | - | - | +0.00 | - | preflight_ready |
| dragon_rage_channeler_cut_scarlet_witch | topdeck_filter | Dragon's Rage Channeler | The Scarlet Witch | `clear` | - | - | +0.00 | - | preflight_ready |
| grand_abolisher_cut_mother_of_runes | spell_protection | Grand Abolisher | Mother of Runes | `clear` | - | - | +0.00 | - | preflight_ready |
| reprieve_cut_avatar_wrath | spell_protection | Reprieve | Avatar's Wrath | `clear` | - | - | +0.00 | - | preflight_ready |

## Package Notes

### perch_protection_cut_avatar_wrath

- family: pressure_absorber
- hypothesis: Perch Protection is present in the two strongest non-607 variants and has active local battle rules. It tests a same-lane protection upgrade over Avatar's Wrath while preserving Dawn's Truce, Fated Clash, Hexing Squelcher, High Noon, medallions, Storm Herd, and Thor.
- status: `preflight_ready`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### akromas_will_cut_avatar_wrath

- family: pressure_absorber
- hypothesis: Akroma's Will is a 614 protection/finisher bridge with active local battle rules. It challenges Avatar's Wrath without touching the locked protection shell or the medallion/topdeck engine.
- status: `preflight_ready`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### silence_cut_avatar_wrath

- family: spell_protection
- hypothesis: Silence is shared by 614/615 and protects the decisive Lorehold or Approach turn at one mana. This tests whether cheap proactive stack protection beats a slower protection spell without cutting locked cards.
- status: `preflight_ready`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### dragon_rage_channeler_cut_scarlet_witch

- family: topdeck_filter
- hypothesis: Dragon's Rage Channeler is a low-cost 614 topdeck/filter engine with active local battle rules. It targets seed 7's missing early engine by challenging The Scarlet Witch, a materialization-sensitive slot.
- status: `preflight_ready`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### grand_abolisher_cut_mother_of_runes

- family: spell_protection
- hypothesis: Grand Abolisher protects the whole decisive turn and appears in 615. Mother of Runes is the same-creature-protection comparison slot, so this is a risky same-lane test rather than a generic support cut.
- status: `preflight_ready`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### reprieve_cut_avatar_wrath

- family: spell_protection
- hypothesis: Reprieve is a 615 tempo/protection card with active local battle rules. It can buy a turn and draw without cutting cards already locked by the seed-42 protection pattern.
- status: `preflight_ready`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`
