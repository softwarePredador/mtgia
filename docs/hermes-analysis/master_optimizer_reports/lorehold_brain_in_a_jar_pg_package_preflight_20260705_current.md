# Lorehold Brain in a Jar PostgreSQL Package Preflight

- Generated at: `2026-07-05T10:07:28Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Decision status: `prepared_read_only_pending_apply_approval`
- Apply ready for manual review: `true`
- Apply executed by this script: `false`
- Brain exact adapter present: `true`
- Runtime preflight status: `brain_in_a_jar_runtime_cut_preflight_blocked_adapter_present_no_active_rule_no_safe_cut_keep_607`
- Runtime preflight required status: `brain_in_a_jar_runtime_cut_preflight_blocked_adapter_present_no_active_rule_no_safe_cut_keep_607`
- Runtime route gate valid: `true`
- Runtime route planner status: `miracle_next_route_planner_selected_brain_floor_protected_no_seed_safe_cut_keep_607`
- Runtime candidate queue governed: `true`
- Runtime candidate queue next-shell status: `next_shell_cut_path_closed_route_miracle_access_first_keep_607`
- Runtime candidate queue matrix-route governed: `true`
- Active Brain rule count before apply: `0`
- Safe cut count before apply: `0`
- Logical rule key: `battle_rule_v1:aedfa4929249f55c1d607effe109f3f3`
- Oracle hash: `41468898bf6400763de517269fdeb456`
- Battle model scope: `xmage_brain_in_a_jar_charge_counter_free_cast_scry_v1`
- Recommended next action: `review_precheck_then_request_explicit_postgresql_apply_if_approved`

## Files

- `apply_sql`: `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_pg_package_preflight_20260705_current_apply.sql`
- `exact_contract`: `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_exact_runtime_contract_20260705_current.json`
- `postcheck_sql`: `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_pg_package_preflight_20260705_current_postcheck.sql`
- `precheck_sql`: `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_pg_package_preflight_20260705_current_precheck.sql`
- `rollback_sql`: `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_pg_package_preflight_20260705_current_rollback.sql`
- `runtime_cut_preflight`: `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_runtime_cut_preflight_20260705_current.json`

## Proposed Rule

- card: `Brain in a Jar`
- normalized_name: `brain in a jar`
- review_status: `verified`
- execution_status: `auto`
- source: `curated`
- confidence: `0.96`
- shadow_handling: `preserve_existing_rows`

## Oracle Evidence

- Scryfall ID: `88ecfcbe-e8db-4f08-aa8b-5b7b3e6c6ce7`
- Oracle ID: `321dbd10-1d48-49fc-ba6a-1df241a53338`
- Oracle hash: `41468898bf6400763de517269fdeb456`
- Rulings preserved:
  - the newly placed charge counter is counted for the first ability
  - the cast is optional and casts at most one matching instant or sorcery from hand
  - the spell is cast during Brain in a Jar ability resolution without paying mana cost
  - alternative costs are not payable, additional costs can still matter, and X is zero unless another effect sets it

## Gates

- deck_action_allowed: `false`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`
- postgres_writes_allowed: `false`
- package_apply_requires_explicit_approval: `true`
- known_runtime_followup: Current Brain adapter handles the core exact mana-value free-cast and scry flow. Nontrivial additional costs and unusual X-spell choices remain explicit follow-up validation before using Brain as broad deck-quality proof.
