# ManaLoom Failure Mode Validation Matrix - 2026-06-30

Status: `current_failure_mode_gate`.

Use this checklist before claiming that battle, card rules, deckbuilding,
Hermes/SQLite, PostgreSQL, or Lorehold promotion surfaces are aligned. It does
not replace the underlying contracts; it sequences the old bug classes that
must be checked after broad work.

Canonical contracts:

- `DATA_FIELD_ALIAS_CONTRACT_2026-06-30.md`
- `XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md`
- `BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md`
- `COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md`
- `MANALOOM_OPERATIONAL_LOOKUP_GUIDE_2026-06-30.md`

## Required Failure-Mode Gates

| Gate | Old bug class blocked | Required evidence |
| --- | --- | --- |
| Field aliases | Duplicate `oracle*`, `card_id`, `scryfall_id`, name, or `logical_rule_key` paths drift | `pg_hermes_sqlite_contract_audit.py` passes, or residual drift is listed explicitly |
| Intelligence fanout | Raw multi-row intelligence joins multiply deck rows; block raw multi-row intelligence joins in product deck queries | Consumers join `card_intelligence_snapshot` or aggregate `card_battle_rules`, `card_function_tags`, and `card_semantic_tags_v2` by `card_id` first |
| PostgreSQL -> Hermes/SQLite | SQLite cache or Hermes artifact overwrites durable PostgreSQL truth | PostgreSQL apply/postcheck evidence exists before sync; SQLite is treated as cache/lab/runtime evidence |
| XMage promotion | Broad XMage extraction becomes executable truth | Only exact `battle_model_scope` rows with focused tests and package precheck can enter PostgreSQL |
| Pattern registry | Shadow pattern rows become autopromotable | Pattern registry remains `shadow_only`, non-executable, and non-autopromotable |
| Runtime rule proof | Battle aggregate is treated as card-level proof | Card was drawn/cast/used in replay traces or covered by a focused positive/negative runtime test |
| Deckbuilder source proof | Popularity, staple rank, or XMage rule availability decides deck membership | Commander intent, source corpus, lane fit, legal validation, strategy matrix, and battle gate remain separate |
| EDHREC scoring | Absolute `inclusion` count overpowers commander-specific ratio | All Commander adoption scoring uses `inclusionRate`, not raw `inclusion`; `numDecks / potentialDecks` is the denominator |
| Staple cuts | A famous card cuts a different lane or protected anchor | Structural staples and commander engines require same-lane replacement or explicit package hypothesis plus equal-gate evidence |
| Lorehold baseline | Historical baseline `deck_6` is used as current shell | Protected baseline `607` is the default current shell; legacy baseline `deck_6` is observation-only unless explicitly marked historical comparison |
| Lorehold artifacts | Historical `ranked_decks` reports are consumed as current schema | `lorehold_artifact_contract_audit.py` normalizes artifacts; current matrix uses `decks[] + ranked_deck_keys` |
| Forced exposure | Forced-access probes promote deck changes | Forced exposure is diagnostic only; natural equal gate with forced access `none` is required for promotion |
| Legacy runners | Deprecated builders or registry runners become active handoff | `build_optimized_deck.py`, `universal_optimizer.py`, and `lorehold_registry_candidate_runner.py` remain blocked/historical unless explicitly run in legacy mode |
| Legacy contamination | Old path/default/schema/scoring bugs are reintroduced outside reviewed history | `legacy_contamination_audit.py` passes against `LEGACY_CONTAMINATION_BASELINE_2026-06-30.json`; new or increased legacy occurrences fail |

## Minimum Command Set

Run these before reporting cross-surface alignment:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/operational_surface_alignment_audit.py \
  --out-prefix docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_$(date -u +%Y%m%d_%H%M%S)_current

python3 docs/hermes-analysis/manaloom-knowledge/scripts/deckbuilding_contract_surface_audit.py \
  --out-prefix docs/hermes-analysis/master_optimizer_reports/deckbuilding_contract_surface_audit_$(date -u +%Y%m%d_%H%M%S)_current

python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_strategy_consistency_audit.py \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_$(date -u +%Y%m%d_%H%M%S)_current

python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_artifact_contract_audit.py \
  --out-prefix docs/hermes-analysis/master_optimizer_reports/lorehold_artifact_contract_audit_$(date -u +%Y%m%d_%H%M%S)_current

python3 docs/hermes-analysis/manaloom-knowledge/scripts/legacy_contamination_audit.py \
  --out-prefix docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_$(date -u +%Y%m%d_%H%M%S)_current
```

Run this when the claim includes PostgreSQL/Hermes/SQLite field alignment:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/pg_hermes_sqlite_contract_audit.py \
  --out-prefix docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_$(date -u +%Y%m%d_%H%M%S)_current
```

If PostgreSQL credentials are not available in the current environment, use
the script's read-only/SQLite-safe options only for local drift triage and state
that live PostgreSQL was not proven.

## Stop Rules

Stop and fix before continuing if any of these occur:

- a report says "aligned" while any command above fails;
- a current deck gate uses `deck_6` as the candidate shell or protected
  baseline;
- a score, sort, or weight uses raw EDHREC `inclusion` count as commander
  adoption evidence;
- a direct deck join touches raw multi-row battle/function/semantic tables
  without aggregation;
- an old artifact is consumed without schema normalization;
- a candidate card is declared better without card-use evidence or focused
  runtime exercise;
- a PostgreSQL apply or SQLite sync is inferred from markdown instead of
  postcheck rows and sync output.
- `legacy_contamination_audit.py` reports any new or increased stale SQLite
  path, hardcoded PG fallback, `deck_6` default, raw `ranked_decks`, or raw
  EDHREC `inclusion` score occurrence.

## Current Known Guardrails

- `operational_surface_alignment_audit.py` checks active docs, blocked legacy
  runners, protected baseline `607`, current XMage manifest, and the rebuild
  EDHREC inclusion-rate path.
- `deckbuilding_contract_surface_audit.py` checks deckbuilding contract,
  staple policy, active Lorehold matrix/gate, and the same inclusion-rate
  scoring guardrail.
- `lorehold_learning_evidence_ledger.py` treats legacy baseline `deck_6` result
  reports as historical observation only.
- `lorehold_artifact_contract_audit.py` normalizes current `decks[]` matrices
  and legacy `ranked_decks` reports instead of letting consumers read old
  shapes directly.
- `legacy_contamination_audit.py` scans broad code/docs surfaces against
  `LEGACY_CONTAMINATION_BASELINE_2026-06-30.json`, so reviewed historical
  references can shrink but cannot silently grow.
