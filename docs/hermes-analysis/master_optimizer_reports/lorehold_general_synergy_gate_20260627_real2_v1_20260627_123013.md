# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T12:52:30.915554+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `2`
- opponent_seed: `20260626`
- simulation_seed: `42`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| birgi_spellchain_cut_squelcher | spellchain_mana | Birgi, God of Storytelling // Harnfel, Horn of Bounty | Hexing Squelcher | 1/1/0 `50.00%` | 1/1/0 `50.00%` | +0.00 | cost -4, spell +0, miracle +0, topdeck -3 | tie_promote_to_deeper_gate |
| birgi_spellchain_cut_waterskin | spellchain_mana | Birgi, God of Storytelling // Harnfel, Horn of Bounty | Bender's Waterskin | 1/1/0 `50.00%` | 1/1/0 `50.00%` | +0.00 | cost +0, spell +2, miracle -1, topdeck -1 | tie_watch_strategy_regression |
| galvanoth_topdeck_freecast | topdeck_freecast | Galvanoth | Bender's Waterskin | 1/1/0 `50.00%` | 1/1/0 `50.00%` | +0.00 | cost +4, spell +1, miracle -3, topdeck -3 | tie_watch_strategy_regression |
| brainstone_topdeck_miracle | topdeck_setup | Brainstone | Bender's Waterskin | 1/1/0 `50.00%` | 0/2/0 `0.00%` | -50.00 | cost -13, spell -11, miracle -5, topdeck -3 | reject_or_rework |
| primal_amulet_spell_engine | cost_reduce_copy | Primal Amulet // Primal Wellspring | Bender's Waterskin | 1/1/0 `50.00%` | 1/1/0 `50.00%` | +0.00 | cost -16, spell -11, miracle -3, topdeck -3 | tie_watch_strategy_regression |
| chandra_copy_engine | spell_copy | Chandra, Hope's Beacon | Bender's Waterskin | 1/1/0 `50.00%` | 0/2/0 `0.00%` | -50.00 | cost -13, spell -11, miracle -5, topdeck -3 | reject_or_rework |
| arcane_bombardment_engine | spell_copy_recursion | Arcane Bombardment | Bender's Waterskin | 1/1/0 `50.00%` | 1/1/0 `50.00%` | +0.00 | cost -16, spell -12, miracle -2, topdeck +0 | tie_watch_strategy_regression |
| past_in_flames_recast | graveyard_recast | Past in Flames | Bender's Waterskin | 1/1/0 `50.00%` | 2/0/0 `100.00%` | +50.00 | cost -7, spell -4, miracle +1, topdeck -3 | promote_to_deeper_gate |
| copy_stack_package | spell_copy | Reverberate, Return the Favor, Flare of Duplication | Hexing Squelcher, Bender's Waterskin, Victory Chimes | 1/1/0 `50.00%` | 1/1/0 `50.00%` | +0.00 | cost -11, spell -9, miracle -4, topdeck -3 | tie_watch_strategy_regression |
| overmaster_protect_draw | spell_protection | Overmaster | Hexing Squelcher | 1/1/0 `50.00%` | 1/1/0 `50.00%` | +0.00 | cost +10, spell +7, miracle +4, topdeck +5 | tie_promote_to_deeper_gate |
| core_challenge_dance_over_storm | payoff_challenge | Dance with Calamity | Storm Herd | 1/1/0 `50.00%` | 1/1/0 `50.00%` | +0.00 | cost -2, spell +2, miracle +2, topdeck -1 | tie_promote_to_deeper_gate |
| core_challenge_past_over_tragic | payoff_challenge | Past in Flames | Tragic Arrogance | 1/1/0 `50.00%` | 0/2/0 `0.00%` | -50.00 | cost -6, spell -6, miracle -3, topdeck -3 | reject_or_rework |

## Package Notes

### birgi_spellchain_cut_squelcher

- family: spellchain_mana
- hypothesis: Birgi adds red mana on every spell cast, which should help Lorehold chain miracle spells without cutting the expensive spell package.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Birgi, God of Storytelling // Harnfel, Horn of Bounty": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_birgi_spellchain_cut_squelcher/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_birgi_spellchain_cut_squelcher.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_birgi_spellchain_cut_squelcher.json`
- gate_returncode: `0`

### birgi_spellchain_cut_waterskin

- family: spellchain_mana
- hypothesis: Birgi may outperform a three-mana mana rock because the deck often casts several spells in a turn after a miracle setup.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Birgi, God of Storytelling // Harnfel, Horn of Bounty": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_birgi_spellchain_cut_waterskin/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_birgi_spellchain_cut_waterskin.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_birgi_spellchain_cut_waterskin.json`
- gate_returncode: `0`

### galvanoth_topdeck_freecast

- family: topdeck_freecast
- hypothesis: Galvanoth turns topdeck setup into free upkeep casts for the same expensive instant/sorcery package Lorehold wants to miracle.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Galvanoth": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_galvanoth_topdeck_freecast/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_galvanoth_topdeck_freecast.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_galvanoth_topdeck_freecast.json`
- gate_returncode: `0`

### brainstone_topdeck_miracle

- family: topdeck_setup
- hypothesis: Brainstone is another cheap topdeck manipulation artifact that can turn the first draw into a planned miracle window.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Brainstone": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_brainstone_topdeck_miracle/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_brainstone_topdeck_miracle.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_brainstone_topdeck_miracle.json`
- gate_returncode: `0`

### primal_amulet_spell_engine

- family: cost_reduce_copy
- hypothesis: Primal Amulet reduces instant/sorcery costs and can transform into a spell-copying mana land, matching the deck's expensive spell plan.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Primal Amulet // Primal Wellspring": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_primal_amulet_spell_engine/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_primal_amulet_spell_engine.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_primal_amulet_spell_engine.json`
- gate_returncode: `0`

### chandra_copy_engine

- family: spell_copy
- hypothesis: Chandra, Hope's Beacon copies the first instant or sorcery each turn and can add mana, so it may turn one miracle spell into a win turn.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Chandra, Hope's Beacon": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_chandra_copy_engine/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_chandra_copy_engine.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_chandra_copy_engine.json`
- gate_returncode: `0`

### arcane_bombardment_engine

- family: spell_copy_recursion
- hypothesis: Arcane Bombardment rewards repeated instant/sorcery casting by copying graveyard spells, which should scale with Lorehold chains.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Arcane Bombardment": 2}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_arcane_bombardment_engine/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_arcane_bombardment_engine.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_arcane_bombardment_engine.json`
- gate_returncode: `0`

### past_in_flames_recast

- family: graveyard_recast
- hypothesis: Past in Flames turns the graveyard of used instant/sorcery cards into a second spell chain without removing a miracle payoff.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Past in Flames": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_past_in_flames_recast/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_past_in_flames_recast.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_past_in_flames_recast.json`
- gate_returncode: `0`

### copy_stack_package

- family: spell_copy
- hypothesis: A compact copy package should make the deck's expensive miracle spells matter more without replacing the payoff suite itself.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Flare of Duplication": 1, "Return the Favor": 1, "Reverberate": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_copy_stack_package/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_copy_stack_package.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_copy_stack_package.json`
- gate_returncode: `0`

### overmaster_protect_draw

- family: spell_protection
- hypothesis: Overmaster protects the next key instant or sorcery and replaces itself, so it may be better than narrow anti-counter pressure.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Overmaster": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_overmaster_protect_draw/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_overmaster_protect_draw.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_overmaster_protect_draw.json`
- gate_returncode: `0`

### core_challenge_dance_over_storm

- family: payoff_challenge
- hypothesis: Dance with Calamity is an expensive sorcery payoff that may produce more immediate wins than Storm Herd when miracle makes it cheap.
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Storm Herd`
- added_rule_counts: `{"Dance with Calamity": 2}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_core_challenge_dance_over_storm/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_core_challenge_dance_over_storm.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_core_challenge_dance_over_storm.json`
- gate_returncode: `0`

### core_challenge_past_over_tragic

- family: payoff_challenge
- hypothesis: Past in Flames may be a stronger spell-chain payoff than a generic five-mana cleanup sorcery in the current shell.
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Tragic Arrogance`
- added_rule_counts: `{"Past in Flames": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_core_challenge_past_over_tragic/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_core_challenge_past_over_tragic.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_core_challenge_past_over_tragic.json`
- gate_returncode: `0`
