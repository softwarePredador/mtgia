# Battle Rules Family Pipeline Contract - 2026-06-29

Status: `frozen_operating_contract`.

This file freezes the operating contract for ManaLoom battle-rule adaptation.
It does not replace `XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md`; it
turns that flow into the day-to-day execution rule so future cycles stop
reopening the same strategic decision.

## Frozen Decision

Do not revalidate the whole battle/rules philosophy before each card wave.
Run the short contract checkpoint below. If it passes, continue directly into
family mapping and exact subpattern work.

Reopen the full strategy only when one of these is true:

1. the contract checkpoint fails;
2. the battle runtime, PostgreSQL schema, or Hermes sync contract changed;
3. a newer source-backed document explicitly supersedes this contract.

## Contract Checkpoint

Before starting or promoting a family wave, verify these invariants:

| Invariant | Required State |
| --- | --- |
| Durable truth | PostgreSQL `card_battle_rules` is the durable source of truth |
| Runtime mirror | Hermes SQLite is cache/lab/runtime evidence and must not overwrite PostgreSQL |
| Source hierarchy | Scryfall/MTGJSON normalize Oracle data; local XMage is primary rules-engine reference; Forge is cross-check only when ambiguous or high-risk |
| Community/log inputs | 17Lands, logs, Reddit, and meta sources are strategy evidence only, not rules truth |
| XMage extraction | Broad XMage extraction may create review candidates and family lanes only |
| Generic scopes | Generic `xmage_*_review_v1` scopes are review/split-only and never batch PG candidates |
| Pattern registry | Pattern registry rows are `shadow_only`, non-executable, and non-autopromotable |
| Card-level proof | A battle aggregate is not card-level proof unless the candidate card was drawn/used or a focused test exercised it |
| Consumer joins | Consumers must use one-row-per-card snapshots or aggregate multi-row rule/tag tables before deck joins |

The governance command for this checkpoint is:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_strategy_consistency_audit.py \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_$(date -u +%Y%m%d_%H%M%S)_contract_checkpoint
```

## Execution Order

After the checkpoint passes, work in this order:

1. Rebuild the current replay/deck scope queue.
2. Promote only exact, non-generic package-ready lanes with focused runtime/test
   proof and approved PostgreSQL package evidence.
3. Split `ramp_permanent` into exact executable subpatterns.
4. Split `targeted_interaction` into exact executable subpatterns.
5. Split `tutor` into exact executable subpatterns.
6. Split `free_cast` into exact executable subpatterns.
7. Continue with `passive`, `recursion`, `targeted_protection`,
   `ramp_ritual`, and `life_total_change` unless replay/deck evidence changes
   priority.
8. Treat `Hazel's Brewmaster` as an exact runtime exception, not as permission
   to implement generic token-maker behavior.
9. Reduce the remaining `manual_model` backlog by adding mapper patterns, not
   by reviewing cards one by one.

## Required Evidence Per Family Wave

Every family wave must leave these artifacts or explicit proof:

- current replay/deck scope manifest;
- XMage index or local source resolution;
- validity audit;
- semantic family report;
- proposal report;
- shadow pattern registry;
- exact `battle_model_scope` for every promotable rule;
- focused positive and negative tests for executable behavior;
- PostgreSQL precheck/apply/rollback/postcheck package when a durable rule is
  promoted;
- PG -> Hermes/SQLite sync report after apply;
- post-sync deck/replay audit for affected cards.

## Stop Rules

Stop the current wave and fix the contract before continuing if any of these
happen:

- a generic `xmage_*_review_v1` scope is selected for PostgreSQL promotion;
- a pattern registry row becomes executable;
- Hermes is treated as newer truth than PostgreSQL;
- a candidate is called validated only from aggregate battle results without
  drawn/used or focused-test evidence;
- a full-XMage parsing task is started without shrinking the active queue;
- a raw multi-row rule/tag table is joined directly into deck-card consumers.

## Current Next Step

The next productive implementation step is not another full revalidation. It is
to rebuild the current queue and continue family/subpattern work under this
contract.
