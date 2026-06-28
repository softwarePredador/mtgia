# Lorehold Hidden Retreat Unblock Readiness - 2026-06-28

- generated_at: `2026-06-28T10:35:28Z`
- postgres_writes: `false`
- source_db_mutated: `false`
- readiness_status: `blocked_db_precheck_and_no_safe_cut`
- safe_to_run_battle_gate_now: `false`
- hidden_retreat_package_status: `prepared_read_only_pending_apply_approval`
- gate_ready_package_count: `0`
- preflight_access_candidate_ready_count: `0`
- deeper_gate_candidate_count: `0`
- rejected_current_pair_count: `11`
- inconclusive_no_used_sample_count: `8`
- recommended_next_action: `fix_or_retry_pg244_precheck_access_before_requesting_apply; do_not_run_blind_battle_gate`

## Precheck Status

- psql_path: `/opt/homebrew/bin/psql`
- selected_env_file: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/.env`
- database_url_available_from_env_file: `true`
- precheck_environment_ready: `true`
- run_requested: `true`

| Attempt | SSL mode | Classification | Exit | Stderr excerpt |
| ---: | --- | --- | ---: | --- |
| 1 | `default` | `failed_connection_closed` | 2 | psql: error: connection to server at "<redacted-host>", port <redacted-port> failed: server closed the connection unexpectedly<br>	This probably means the server terminated abnormally<br>	before or while processing the request. |
| 2 | `require` | `failed_ssl_unsupported` | 2 | psql: error: connection to server at "<redacted-host>", port <redacted-port> failed: server does not support SSL, but SSL was required |

## Blocker Chain

| Blocker | Evidence | Resolution |
| --- | --- | --- |
| `no_gate_ready_package` | focus queue gate_ready_package_count=0 | rerun focus package generation only after runtime/safe-cut blockers change |
| `no_safe_access_cut` | access model preflight_access_candidate_ready_count=0 | find a seed-safe cut for the access/topdeck lane before battle gating |
| `hidden_retreat_not_product_truth` | PG244 status=prepared_read_only_pending_apply_approval | run precheck, obtain explicit approval for apply SQL, apply, postcheck, then sync Hermes |
| `card_level_evidence_required` | outcome audit deeper_gate_candidate_count=0, rejected_current_pair_count=11, inconclusive_no_used_sample_count=8 | promote only packages where the added card has observed used-game support |

## Guardrails

- Do not run blind three-game swaps when the package queue has zero gate-ready candidates.
- Do not treat aggregate battle record as card-level proof.
- Do not repeat exact rejected pairs without a new failure target or cut rationale.
- Do not apply PG244 SQL without explicit approval for the exact command.
- Hermes/runtime overlay is laboratory evidence until PostgreSQL apply and sync complete.
