# Global Commander External Reference Corpus Collector

- generated_at: `2026-07-05T22:52:17.902477+00:00`
- status: `external_reference_corpus_collected_no_cut_permission`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- hypothesis_count: `8`
- source_count: `5`
- commander_public_decks_observed: `37936`
- filtered_midrange_sample_decks: `16`
- corpus_present_count: `3`
- corpus_absent_count: `5`
- usage_blocked_count: `6`
- seen_without_usage_count: `2`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `map_external_corpus_to_cut_policy_before_rerun_miner`

## Card Corpus Rows

| Cut | Trace | Corpus Support | Corpus Status | Decision |
| --- | --- | --- | --- | --- |
| `Biotransference` | `usage_blocked` | `absent_from_checked_kaalia_sources` | `external_absence_cannot_override_target_usage` | `do_not_cut_from_absence_only` |
| `Maskwood Nexus` | `usage_blocked` | `absent_from_checked_kaalia_sources` | `external_absence_cannot_override_target_usage` | `do_not_cut_from_absence_only` |
| `Necromancy` | `usage_blocked` | `commander_corpus_present` | `external_corpus_supports_preserve_or_strict_same_lane_proof` | `do_not_cut_without_same_lane_or_equal_gate` |
| `Necropotence` | `usage_blocked` | `commander_corpus_present_high_power` | `external_corpus_supports_preserve_or_strict_same_lane_proof` | `do_not_cut_without_same_lane_or_equal_gate` |
| `Puresteel Paladin` | `seen_without_usage` | `absent_from_checked_kaalia_sources` | `external_absence_plus_seen_without_usage_requires_negative_review` | `negative_or_force_access_required_before_cut_consideration` |
| `Sigarda's Aid` | `usage_blocked` | `absent_from_checked_kaalia_sources` | `external_absence_cannot_override_target_usage` | `do_not_cut_from_absence_only` |
| `Sram, Senior Edificer` | `usage_blocked` | `absent_from_checked_kaalia_sources` | `external_absence_cannot_override_target_usage` | `do_not_cut_from_absence_only` |
| `Trouble in Pairs` | `seen_without_usage` | `commander_corpus_present` | `external_presence_requires_negative_trace_before_cut` | `negative_trace_required_before_cut_consideration` |

## Source Corpus Snapshot

- `edhrec_kaalia_current`: broad public Kaalia corpus for anchor/card presence and role hints (https://edhrec.com/commanders/kaalia-of-the-vast)
- `edhrec_kaalia_expensive_midrange_2026_06_24`: small high-budget midrange comparison set for high-power anchors (https://edhrec.com/commanders/kaalia-of-the-vast/midrange/expensive)
- `edhrec_kaalia_hidden_gems_2026_03_26`: protect attack-window, payoff-density, recast, and recovery lanes from generic cuts (https://edhrec.com/articles/hidden-gems-for-kaalia-of-the-vast)
- `wizards_commander_brackets_2026_02_09`: bracket and Game Changer context for high-power staple risk (https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-february-9-2026)
- `wizards_commander_brackets_2025_10_21`: avoid treating optimized staples as generic over-target cut fodder (https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-october-21-2025)

## Blockers

- `external_corpus_is_not_cut_permission`
- `used_cards_still_require_same_lane_or_equal_gate_proof`
- `seen_without_usage_cards_still_require_negative_or_force_access_review`
- `candidate_copy_closed_until_corpus_maps_to_internal_cut_policy_and_trace_evidence`

## Policy

- source_boundary: External corpus presence protects or routes review; absence is not proof that a used card is safe to cut.
- trace_boundary: Target-deck usage remains stronger than public-corpus absence.
- bracket_boundary: Game Changer and bracket context marks high-power staples as context-sensitive, not generic cuts.
- mutation_boundary: This collector does not copy decks, mutate DBs, run battles, reclassify cuts, or promote a package.
