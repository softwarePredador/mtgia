# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T19:38:03.096064+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v1.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json`
- package_status_counts: `{"gated": 7}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| birgi_spellchain_cut_jeskas_will | spellchain_mana | Birgi, God of Storytelling // Harnfel, Horn of Bounty | Jeska's Will | `clear` | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | cost -41, spell -38, spell mana +1, birgi mana +1, ritual +0, miracle -13, tutor -5, random discard -1, topdeck -12, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -12, squee gy -1, squee return +0, squee explained +0 | reject_or_rework |
| seething_song_cut_fellwar_stone | spellchain_mana | Seething Song | Fellwar Stone | `clear` | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | cost -30, spell -22, spell mana +0, birgi mana +0, ritual +0, miracle -8, tutor -1, random discard -1, topdeck -8, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -10, squee gy -1, squee return +0, squee explained +0 | reject_or_rework |
| storm_kiln_artist_cut_arcane_signet | spellchain_mana | Storm-Kiln Artist | Arcane Signet | `clear` | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | cost -22, spell -22, spell mana +0, birgi mana +0, ritual +0, miracle -6, tutor -2, random discard +0, topdeck -7, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -7, squee gy -1, squee return +0, squee explained +0 | reject_or_rework |
| runaway_steamkin_cut_talisman | spellchain_mana | Runaway Steam-Kin | Talisman of Conviction | `clear` | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | cost -35, spell -35, spell mana +0, birgi mana +0, ritual +0, miracle -13, tutor -3, random discard -1, topdeck -11, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -12, squee gy -1, squee return +0, squee explained +0 | reject_or_rework |
| boros_charm_pressure_cut_avatar_wrath | pressure_absorber | Boros Charm | Avatar's Wrath | `clear` | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | cost -32, spell -21, spell mana +0, birgi mana +0, ritual +0, miracle -7, tutor -1, random discard +0, topdeck -6, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -8, squee gy -1, squee return +0, squee explained +0 | reject_or_rework |
| overmaster_protect_draw_cut_tibalts_trickery | spell_protection | Overmaster | Tibalt's Trickery | `clear` | 3/0/0 `100.00%` | 2/1/0 `66.67%` | -33.33 | cost -19, spell -22, spell mana +0, birgi mana +0, ritual +2, miracle -7, tutor -6, random discard -1, topdeck -12, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -12, squee gy -1, squee return +0, squee explained +0 | reject_or_rework |
| ghostly_prison_pressure_cut_promise | pressure_absorber | Ghostly Prison | Promise of Loyalty | `clear` | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | cost -30, spell -27, spell mana +0, birgi mana +0, ritual +0, miracle -10, tutor -3, random discard +0, topdeck -11, discard-to-top +1, rummage-to-top +1, spell-rummage-to-top +0, hand to top +0, spell rummage -12, squee gy -1, squee return +0, squee explained +0 | reject_or_rework |

## Package Notes

### birgi_spellchain_cut_jeskas_will

- family: spellchain_mana
- hypothesis: Birgi tests the same early-mana/spell-chain job without cutting the now-protected medallions, Bender's Waterskin, or Victory Chimes. Jeska's Will is the comparison slot because it is a powerful but one-shot mana burst rather than a repeatable cast-trigger engine.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Birgi, God of Storytelling // Harnfel, Horn of Bounty": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_birgi_spellchain_cut_jeskas_will/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_birgi_spellchain_cut_jeskas_will.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_birgi_spellchain_cut_jeskas_will.json`
- gate_returncode: `0`

### seething_song_cut_fellwar_stone

- family: spellchain_mana
- hypothesis: Seething Song tests whether a ritual burst converts the current mana/spell bottleneck faster than a generic two-mana rock while preserving all cut-safety-protected ramp slots.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Seething Song": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_seething_song_cut_fellwar_stone/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_seething_song_cut_fellwar_stone.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_seething_song_cut_fellwar_stone.json`
- gate_returncode: `0`

### storm_kiln_artist_cut_arcane_signet

- family: spellchain_mana
- hypothesis: Storm-Kiln Artist can turn every instant or sorcery into treasure. This tests a repeatable spell-mana engine over the most generic untested rock, without touching medallions, Bender's Waterskin, Victory Chimes, or the finisher package.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Storm-Kiln Artist": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_storm_kiln_artist_cut_arcane_signet/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_storm_kiln_artist_cut_arcane_signet.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_storm_kiln_artist_cut_arcane_signet.json`
- gate_returncode: `0`

### runaway_steamkin_cut_talisman

- family: spellchain_mana
- hypothesis: Runaway Steam-Kin is a low-curve red spell mana engine. It tests whether repeated red-spell turns create more conversion pressure than a generic two-mana Boros rock while preserving the protected three-mana ramp and medallion shell.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Runaway Steam-Kin": 3}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_runaway_steamkin_cut_talisman/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_runaway_steamkin_cut_talisman.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_runaway_steamkin_cut_talisman.json`
- gate_returncode: `0`

### boros_charm_pressure_cut_avatar_wrath

- family: pressure_absorber
- hypothesis: Boros Charm previously failed when it cut protected Fated Clash. This retest keeps Fated Clash, Dawn's Truce, Hexing Squelcher, and the ramp shell intact, using another pressure/protection lane slot as the comparison instead. This is an explicit same-lane high-CMC spell benchmark, not a free cut of the miracle payoff package.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Avatar's Wrath`
- added_rule_counts: `{"Boros Charm": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_boros_charm_pressure_cut_avatar_wrath/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_boros_charm_pressure_cut_avatar_wrath.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_boros_charm_pressure_cut_avatar_wrath.json`
- gate_returncode: `0`

### overmaster_protect_draw_cut_tibalts_trickery

- family: spell_protection
- hypothesis: Overmaster protects a decisive instant or sorcery and replaces itself. This tests the spell-protection lane while keeping Hexing Squelcher and the known protection shell intact, comparing against a swingy protection/counter slot instead.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Overmaster": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_overmaster_protect_draw_cut_tibalts_trickery/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_overmaster_protect_draw_cut_tibalts_trickery.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_overmaster_protect_draw_cut_tibalts_trickery.json`
- gate_returncode: `0`

### ghostly_prison_pressure_cut_promise

- family: pressure_absorber
- hypothesis: Ghostly Prison previously failed when it cut protected Hexing Squelcher. This retest keeps Hexing Squelcher and Fated Clash, then checks whether a static attack tax is better than a slower pressure cleanup spell against the combat-pressure deaths. This is an explicit pressure-lane benchmark, not a generic cut of the big-spell miracle plan.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Promise of Loyalty`
- added_rule_counts: `{"Ghostly Prison": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_ghostly_prison_pressure_cut_promise/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_ghostly_prison_pressure_cut_promise.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2_ghostly_prison_pressure_cut_promise.json`
- gate_returncode: `0`
