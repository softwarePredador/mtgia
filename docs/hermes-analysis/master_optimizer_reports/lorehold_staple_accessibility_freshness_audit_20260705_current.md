# Lorehold Staple Accessibility Freshness Audit

- Generated at: `2026-07-05T06:02:35Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Status: `staple_accessibility_current_legal_but_not_promotion_ready_keep_607`
- Cards reviewed: `2`
- External Commander-legal cards: `2`
- Local Commander-legal cards: `2`
- Owned cards: `1`
- Game Changers reviewed: `2`
- Format-staples gaps: `1`
- Promotion-blocked cards: `2`
- Natural-gate-ready cards: `0`
- Deck action allowed now: `false`
- Natural gate allowed now: `false`
- Recommended next action: `surface_accessibility_by_layer_and_require_new_cut_trace_before_retesting_staples`

## Source Reports

- `accessibility`: `docs/hermes-analysis/master_optimizer_reports/lorehold_accessibility_layer_matrix_20260705_current.json`
- `game_changer_audit`: `docs/hermes-analysis/master_optimizer_reports/game_changer_discovery_gap_audit_20260705_current.json`
- `hypothesis_queue`: `docs/hermes-analysis/master_optimizer_reports/lorehold_hypothesis_queue_from_value_model_20260705_current_relearn.json`
- `value_priority`: `docs/hermes-analysis/master_optimizer_reports/lorehold_card_value_priority_synthesis_20260705_current_relearn.json`

## External Rules Snapshot

- Commander banned list: https://mtgcommander.net/index.php/banned-list/
- Latest WotC B&R announcement: https://magic.wizards.com/en/news/announcements/banned-and-restricted-june-29-2026
- Commander Brackets source: https://magic.wizards.com/en/news/announcements/introducing-commander-brackets-beta
- Snapshot interpretation: Mana Vault and The One Ring are treated as Commander-legal, Lorehold-color-compatible Game Changers; Game Changer is a power/matchmaking signal, not promotion proof.

## Card Layer Results

| Card | External role | Owned | Format staple | Discovery gap | Hypothesis status | App label | Next action |
| --- | --- | ---: | --- | --- | --- | --- | --- |
| Mana Vault | `fast_mana` | 0 | `True` | `False` | `blocked_prior_reject` | `rules_accessible_collection_missing_promotion_blocked` | `do_not_offer_as_available_deck_change_until_collection_and_new_cut_trace_exist` |
| The One Ring | `resource_engine` | 1 | `False` | `True` | `blocked_prior_reject` | `rules_collection_accessible_promotion_blocked` | `show_owned_but_blocked_prior_reject_and_require_new_same_lane_trace` |

## Per-Card Explanation

### Mana Vault
- external role: `fast_mana`
- external reason: Wizards grouped Mana Vault with powerful fast-mana pieces that accelerate games.
- app label: `rules_accessible_collection_missing_promotion_blocked`
- promotion decision: `blocked_prior_gate_rejected`
- same-lane anchors: `Molecule Man, Reforge the Soul, Call Forth the Tempest, Hit the Mother Lode, Creative Technique`
- next action: `do_not_offer_as_available_deck_change_until_collection_and_new_cut_trace_exist`
### The One Ring
- external role: `resource_engine`
- external reason: Wizards grouped The One Ring with overwhelming resource-advantage cards that can snowball games.
- app label: `rules_collection_accessible_promotion_blocked`
- promotion decision: `blocked_existing_package_rejected`
- same-lane anchors: `-`
- next action: `show_owned_but_blocked_prior_reject_and_require_new_same_lane_trace`

## Decision

- keep_607_as_protected_baseline: `true`
- deck_action_allowed: `false`
- natural_gate_allowed_now: `false`
- promotion_allowed: `false`
- rules_legal_is_not_same_as_deck_accessible: `true`
- app_label_requirement: Show legal, collection, discovery, bracket, and promotion layers separately. Do not collapse Mana Vault or The One Ring into one accessible/inaccessible flag.
- reason: Both reviewed cards are legal and Lorehold-color-compatible by current external rules evidence, but the current 607 evidence has zero natural-gate-ready rows and both cards remain blocked by collection and/or prior promotion evidence.
