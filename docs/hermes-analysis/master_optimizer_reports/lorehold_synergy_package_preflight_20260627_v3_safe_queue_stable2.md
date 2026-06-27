# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T19:37:12.373040+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `True`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v1.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json`
- package_status_counts: `{"preflight_ready": 7}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| birgi_spellchain_cut_jeskas_will | spellchain_mana | Birgi, God of Storytelling // Harnfel, Horn of Bounty | Jeska's Will | `clear` | - | - | +0.00 | - | preflight_ready |
| seething_song_cut_fellwar_stone | spellchain_mana | Seething Song | Fellwar Stone | `clear` | - | - | +0.00 | - | preflight_ready |
| storm_kiln_artist_cut_arcane_signet | spellchain_mana | Storm-Kiln Artist | Arcane Signet | `clear` | - | - | +0.00 | - | preflight_ready |
| runaway_steamkin_cut_talisman | spellchain_mana | Runaway Steam-Kin | Talisman of Conviction | `clear` | - | - | +0.00 | - | preflight_ready |
| boros_charm_pressure_cut_avatar_wrath | pressure_absorber | Boros Charm | Avatar's Wrath | `clear` | - | - | +0.00 | - | preflight_ready |
| overmaster_protect_draw_cut_tibalts_trickery | spell_protection | Overmaster | Tibalt's Trickery | `clear` | - | - | +0.00 | - | preflight_ready |
| ghostly_prison_pressure_cut_promise | pressure_absorber | Ghostly Prison | Promise of Loyalty | `clear` | - | - | +0.00 | - | preflight_ready |

## Package Notes

### birgi_spellchain_cut_jeskas_will

- family: spellchain_mana
- hypothesis: Birgi tests the same early-mana/spell-chain job without cutting the now-protected medallions, Bender's Waterskin, or Victory Chimes. Jeska's Will is the comparison slot because it is a powerful but one-shot mana burst rather than a repeatable cast-trigger engine.
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

### seething_song_cut_fellwar_stone

- family: spellchain_mana
- hypothesis: Seething Song tests whether a ritual burst converts the current mana/spell bottleneck faster than a generic two-mana rock while preserving all cut-safety-protected ramp slots.
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

### storm_kiln_artist_cut_arcane_signet

- family: spellchain_mana
- hypothesis: Storm-Kiln Artist can turn every instant or sorcery into treasure. This tests a repeatable spell-mana engine over the most generic untested rock, without touching medallions, Bender's Waterskin, Victory Chimes, or the finisher package.
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

### runaway_steamkin_cut_talisman

- family: spellchain_mana
- hypothesis: Runaway Steam-Kin is a low-curve red spell mana engine. It tests whether repeated red-spell turns create more conversion pressure than a generic two-mana Boros rock while preserving the protected three-mana ramp and medallion shell.
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

### boros_charm_pressure_cut_avatar_wrath

- family: pressure_absorber
- hypothesis: Boros Charm previously failed when it cut protected Fated Clash. This retest keeps Fated Clash, Dawn's Truce, Hexing Squelcher, and the ramp shell intact, using another pressure/protection lane slot as the comparison instead. This is an explicit same-lane high-CMC spell benchmark, not a free cut of the miracle payoff package.
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

### overmaster_protect_draw_cut_tibalts_trickery

- family: spell_protection
- hypothesis: Overmaster protects a decisive instant or sorcery and replaces itself. This tests the spell-protection lane while keeping Hexing Squelcher and the known protection shell intact, comparing against a swingy protection/counter slot instead.
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

### ghostly_prison_pressure_cut_promise

- family: pressure_absorber
- hypothesis: Ghostly Prison previously failed when it cut protected Hexing Squelcher. This retest keeps Hexing Squelcher and Fated Clash, then checks whether a static attack tax is better than a slower pressure cleanup spell against the combat-pressure deaths. This is an explicit pressure-lane benchmark, not a generic cut of the big-spell miracle plan.
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
