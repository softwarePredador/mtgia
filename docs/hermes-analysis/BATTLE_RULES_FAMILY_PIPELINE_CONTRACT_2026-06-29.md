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
| Source hierarchy | Scryfall/MTGJSON normalize Oracle data; local XMage is authoritative behavior source for any card with a resolvable XMage class; Forge is cross-check only when ambiguous or high-risk |
| Community/log inputs | 17Lands, logs, Reddit, and meta sources are strategy evidence only, not rules truth |
| XMage extraction | Broad XMage extraction creates source-authoritative ManaLoom adapter candidates for resolved XMage cards |
| Generic scopes | Generic `xmage_*_review_v1` scopes are adapter/runtime work units; they are not executable PG candidates until the matching ManaLoom adapter exists |
| Pattern registry | Pattern registry rows are `shadow_only`, non-executable, and non-autopromotable |
| Card-level proof | A battle aggregate is not card-level proof unless the candidate card was drawn/used or a focused test exercised it |
| Consumer joins | Consumers must use one-row-per-card snapshots or aggregate multi-row rule/tag tables before deck joins |

`resolvable XMage class` in this frozen table means a source candidate. It only
counts as executable coverage after
`xmage_source_catalog_reconciliation.py` confirms the exact card identity in
the pinned live XMage catalog, or routes a structured XMage gap to pinned
Forge. Similar Java class names are not sufficient.

The governance command for this checkpoint is:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_strategy_consistency_audit.py \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_$(date -u +%Y%m%d_%H%M%S)_contract_checkpoint
```

## Execution Order

After the checkpoint passes, work in this order:

1. Rebuild the current replay/deck scope queue.
2. Rebuild the global authoritative XMage adaptation queue with
   `xmage_authoritative_adaptation_queue.py`.
3. Reconcile resolved local classes with the live catalog, then treat confirmed
   XMage identities as final behavior source and implement the largest
   ManaLoom adapter work units first.
4. Split broad authoritative work units with
   `xmage_authoritative_exact_scope_split.py` or an equivalent exact family
   splitter; do not feed generic `xmage_*_review_v1` scopes directly into a
   PostgreSQL package.
5. Promote only exact package-ready lanes with focused runtime/test
   proof and approved PostgreSQL package evidence.
6. Split `ramp_permanent` into exact executable subpatterns.
7. Split `targeted_interaction` into exact executable subpatterns.
8. Split `tutor` into exact executable subpatterns.
9. Split `free_cast` into exact executable subpatterns.
10. Continue with `passive`, `recursion`, `targeted_protection`,
   `ramp_ritual`, and `life_total_change` unless replay/deck evidence changes
   priority.
11. Treat `Hazel's Brewmaster` as an exact runtime exception, not as permission
   to implement generic token-maker behavior.
12. Reduce the remaining `manual_model` backlog by improving XMage effect
    hints/adapter classification, not by reviewing cards one by one.

## Required Evidence Per Family Wave

Every family wave must leave these artifacts or explicit proof:

- current replay/deck scope manifest;
- global authoritative XMage queue report when the wave is all-card/global;
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

- a generic `xmage_*_review_v1` scope is selected for executable PostgreSQL
  promotion without a matching ManaLoom runtime adapter;
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
