# Lorehold Brain in a Jar Exact Runtime Contract

- Generated at: `2026-07-05T11:33:29Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Decision status: `brain_exact_runtime_contract_adapter_detected_preflight_required_keep_607`
- Contract drafted: `true`
- XMage signals: `13`
- Missing XMage signals: `0`
- Runtime surfaces detected: `8`
- Brain exact adapter present: `true`
- Effect scope: `xmage_brain_in_a_jar_charge_counter_free_cast_scry_v1`
- Focused test vectors: `3`
- Natural battle gate allowed now: `false`
- PostgreSQL writes allowed now: `false`
- Recommended next action: `rerun_brain_runtime_cut_preflight_before_any_deck_action`

## Source Reports

- `battle_runtime`: `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `preflight`: `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_runtime_cut_preflight_20260705_post_authorized_full_validation.json`
- `route_planner`: `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_next_route_planner_20260705_post_authorized_full_validation.json`
- `xmage_source`: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/b/BrainInAJar.java`

## Effect JSON Contract

- scope: `xmage_brain_in_a_jar_charge_counter_free_cast_scry_v1`
- first activation: `{1}, tap -> add charge counter then free-cast exact mana value from hand`
- free cast types: `instant, sorcery`
- mana value match: `source_charge_counters_after_add`
- second activation: `{3}, tap, remove X charge counters -> scry X`

## Runtime Surface Check

- `activated_add_counters_executor`: `true`
- `brain_exact_scope_adapter`: `true`
- `charge_counter_state_surface`: `true`
- `exact_mana_value_hand_free_cast_adapter`: `true`
- `free_cast_from_hand_primitive`: `true`
- `free_cast_without_paying_mana_primitive`: `true`
- `remove_x_charge_counters_scry_adapter`: `true`
- `scry_library_primitive`: `true`

## Focused Test Vectors

- `first_activation_casts_exact_mana_value_one`
- `second_activation_casts_exact_mana_value_two_or_declines`
- `remove_x_charge_counters_scry_x`

## Decision

- keep_607_as_protected_baseline: `true`
- deck_action_allowed: `false`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`
- postgres_writes_allowed: `false`
- runtime_adapter_required_before_pg_package: `false`
- safe_cut_still_required: `true`
- reason: The exact Brain runtime contract is explicit and the ManaLoom adapter is detectable, but protected deck 607 still cannot use Brain until an active PostgreSQL rule and a seed-safe same-lane cut exist.
- next_actions:
  - do_not_mutate_deck_607
  - prepare_brain_in_a_jar_pg_package_precheck_no_deck_action
  - rerun_brain_runtime_cut_preflight_after_pg_package_review
