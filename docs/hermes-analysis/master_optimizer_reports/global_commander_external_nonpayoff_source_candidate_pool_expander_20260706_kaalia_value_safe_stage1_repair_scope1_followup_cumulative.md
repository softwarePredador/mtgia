# Global Commander External Nonpayoff Source Candidate Pool Expander

- generated_at: `2026-07-06T03:06:33.411243+00:00`
- status: `external_nonpayoff_source_candidate_pool_expansion_found_no_ready_candidates`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- prior_router_status: `external_nonpayoff_seed_exhaustion_recovery_routes_to_source_expansion`
- expanded_candidate_count: `26`
- expanded_ready_for_review_count: `0`
- candidate_copy_allowed_count: `0`
- card_level_cut_permission_count: `0`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `broaden_external_nonpayoff_source_research_live`

## Ready Expanded Source Candidates

| Role | Card | Scope | Evidence Terms | Sources |
| --- | --- | --- | --- | --- |

## All Expanded Candidates

| Role | Card | Status | In Deck | Legal | Recycled |
| --- | --- | --- | ---: | ---: | ---: |
| `haste_protection_silence` | `Swiftfoot Boots` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `haste_protection_silence` | `Boros Charm` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `haste_protection_silence` | `Teferi's Protection` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `haste_protection_silence` | `Mother of Runes` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `haste_protection_silence` | `Mithril Coat` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `haste_protection_silence` | `Whispersilk Cloak` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `haste_protection_silence` | `Kaya's Ghostform` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `haste_protection_silence` | `Rising of the Day` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `mana_acceleration` | `Fellwar Stone` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `mana_acceleration` | `Chromatic Lantern` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `mana_acceleration` | `Lotus Petal` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `mana_acceleration` | `Chrome Mox` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `mana_acceleration` | `Mox Diamond` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `mana_acceleration` | `Mox Amber` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `mana_acceleration` | `Thought Vessel` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `mana_acceleration` | `Mox Opal` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `mana_acceleration` | `Mana Vault` | `expanded_source_candidate_already_in_current_deck_blocked` | true | `legal` | true |
| `mana_acceleration` | `Mana Crypt` | `expanded_source_candidate_blocks_commander_banned` | false | `banned` | true |
| `mana_acceleration` | `Jeweled Lotus` | `expanded_source_candidate_blocks_commander_banned` | false | `banned` | true |
| `mana_acceleration` | `Dockside Extortionist` | `expanded_source_candidate_blocks_commander_banned` | false | `banned` | true |
| `tutors_access` | `Wishclaw Talisman` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `tutors_access` | `Gamble` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `tutors_access` | `Imperial Seal` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `tutors_access` | `Imperial Recruiter` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `tutors_access` | `Recruiter of the Guard` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |
| `tutors_access` | `Demonic Counsel` | `expanded_source_candidate_recycled_from_prior_seed_blocked` | false | `legal` | true |

## Blockers

- `expanded_external_candidates_are_review_seeds_not_cut_permission`
- `prior_reviewed_seeds_remain_recycled_and_blocked`
- `current_deck_cards_need_trace_or_negative_review_before_cut_consideration`
- `banned_cards_are_discarded_before_strategy_review`
- `candidate_copy_closed_until_seeded_miner_finds_traceable_current_deck_cut_source`

## Policy

- expansion_boundary: External pool expansion only creates reviewed-source candidates for a later local review gate.
- recycling_boundary: Candidates already reviewed or found in the prior seed pool are blocked, not reused.
- legality_boundary: Current Commander banned cards are discarded even if they appear in historical/high-power context.
- deck_boundary: Cards already present in the current deck cannot be used as fresh source seeds.
- mutation_boundary: This expander does not copy decks, mutate DBs, run battles, reclassify cuts, or promote packages.
