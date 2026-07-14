# ManaLoom Project Revalidation And Global Card Queue

Date: 2026-07-14

## Verdict

The current contracts, validation runners, PostgreSQL target, Hermes/SQLite
linkage, and XMage routing flow are aligned with the frozen operating model.
This does not mean that all cards have native ManaLoom battle behavior. The
remaining semantic coverage is explicit in the global queue below.

## Validation Evidence

- Backend full suite: `1063 passed, 9 skipped`.
- Python full suite after removing five contaminating pseudo-tests:
  `4596 passed, 5 skipped, 434 subtests passed`.
- Flutter app suite: `613 passed` and analyzer clean.
- Commander resolution corpus: `19/19 passed`, with zero unresolved cases.
- Deep AI alignment: all AI/data, deckbuilding, XMage, operational,
  PostgreSQL, Hermes, and SQLite surfaces passed.
- PostgreSQL/Hermes/SQLite contract after cleanup: `55/55 passed`.

The quality gate now imposes an external timeout, per-test timeout, signal
handling, pipeline-status checks, and a literal success sentinel. This prevents
a stalled or partially successful test process from being reported as green.

## Validation Identity Cleanup

The product tables contained three historical synthetic identities created by
old validation runners. Their complete dependency set was backed up under
`manaloom_deploy_audit` and then removed transactionally from the live product
tables.

| Entity | Backed up | Live after cleanup |
| --- | ---: | ---: |
| Users | 3 | 0 |
| Decks | 640 | 0 |
| Deck cards | 37963 | 0 |
| Optimize fallback telemetry | 62 | 0 |
| Activation funnel events | 1 | 0 |
| AI user preferences | 2 | 0 |
| User plans | 3 | 0 |

Apply package:
`docs/hermes-analysis/master_optimizer_reports/validation_identity_residue_cleanup_20260714_apply.sql`

Rollback package:
`docs/hermes-analysis/master_optimizer_reports/validation_identity_residue_cleanup_20260714_rollback.sql`

The apply package requires the exact precheck counts, refuses an existing or
partial backup set, uses one transaction and advisory lock, and verifies that
all seven live dependency groups are empty before commit.

## Fresh Global Queue

The queue was rebuilt read-only from the new PostgreSQL target and the pinned
local XMage checkout at `/Users/desenvolvimentomobile/Downloads/mage-master`.
Generated JSON and Markdown stayed under `/tmp` and were not retained in the
repository.

| Metric | Current value |
| --- | ---: |
| PostgreSQL card rows | 34331 |
| Battle and Oracle ready | 6857 |
| Active rule requiring focused verification | 70 |
| Battle family mapper required | 26937 |
| Unique battle-gap identities | 26890 |
| Unique identities resolved by local XMage | 23955 |
| Unique identities missing from local XMage | 2935 |
| XMage source coverage of the unique battle-gap queue | 89.09% |
| XMage parser gaps among resolved sources | 0 |

## Required Execution Order

1. Close the 70 existing executable rules with focused runtime/E2E proof and
   promote only the rules that pass.
2. Split broad XMage review scopes into concrete runtime-safe semantic
   subfamilies; never promote a generic `xmage_*_review_v1` scope.
3. Process the highest-yield concrete families in batch, beginning with
   graveyard return/recursion and fixed draw variants, followed by counters,
   targeted damage, life gain, tutor, and removal.
4. For every family, require source resolution, exact adapter, focused tests,
   reversible PostgreSQL package, PostgreSQL-to-Hermes sync, contract audit,
   and report-retention cleanup.
5. Route the 2935 XMage-missing identities separately through Forge or manual
   source review. They must not block the 23955 XMage-resolved identities.

This order prioritizes cheap verification first, then family reuse. It avoids
returning to card-by-card semantic interpretation for XMage-resolved cards.
