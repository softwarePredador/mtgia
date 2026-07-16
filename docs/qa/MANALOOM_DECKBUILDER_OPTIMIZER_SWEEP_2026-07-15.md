# ManaLoom Deckbuilder, Optimize and Battle Sweep — 2026-07-15

> Snapshot da primeira varredura do dia, anterior à consolidação do contrato
> E2E. Onde este arquivo usa `PASS` para o agregado local, leia como o perfil
> atualmente chamado `PARTIAL`: os checks solicitados passaram, mas live e
> device ficaram como `SKIP`. O fechamento final da reorganização está em
> `MANALOOM_E2E_PROJECT_CLOSURE_2026-07-15.md`.

## Executive result

- Local integrated status: `PASS`.
- Production health: healthy at SHA `49e5c34526cc0e9cc3d2b5fd5b7a43583469d419`.
- Local HEAD: `fce7cb405b1a1c17947e476c03422c37ca969749`, 11 commits ahead of the production SHA, plus uncommitted changes from this sweep.
- No commit, push or deploy was performed.
- No product PostgreSQL rows were changed.

The strongest measured improvement is in contract and failure-safety coverage, not yet in deck strength. The stored 2026-07-05 deckbuilding audit had 46 active surfaces; the final audit has 344 (`+298`, about `7.5x`). Product Commander readiness remains 6/16 (`37.5%`), so governance coverage must not be presented as deck-quality improvement.

## Current product truth (PostgreSQL read-only)

The final Commander product audit found:

- 16 product decks.
- 6 `structure_ready`.
- 10 `needs_repair`.
- 9 decks with quantity different from 100.
- 2 decks without commander.
- 1 unresolved card identifier.
- 1 illegal card row.

Current generation/reference lanes:

- 50 commander reference profiles: 36 high, 5 medium-high, 3 medium and 6 without confidence.
- Reference card stats: 1,618 rows, 44 commanders, zero unresolved.
- Accepted reference corpus: 121 decks, 27 commanders.
- Learned decks: 76 rows, 64 commanders, 60 active and explicitly legal.
- Usage: 1,767 commander/card rows, 1,074 distinct cards, 24 commanders and 13,739 observed usages.
- Profile coverage: 44/50 with stats, 24/50 with corpus, 9/50 with active legal learned deck and 19/50 with usage; 3/50 lack every auxiliary lane.
- `ai_generate_jobs`: 4 total, all completed, but zero in the last 7 days.

There is therefore no recent authenticated production generation cohort from which to claim a real improvement in output quality.

## Optimize quality evidence

The latest non-mock larger battle gate is still the 2026-07-06 Lorehold comparison:

- Immediate base deck 612: 7W/17L, `29.17%`.
- Candidate: 8W/16L, `33.33%` (`+4.16 percentage points`, one extra win in 24 games).
- Protected deck 607: 14W/9L/1S, `58.33%`.
- Candidate remains `25.00 percentage points` below the protected baseline.
- Promotion allowed: `false`.

Conclusion: the optimizer produced a small improvement over the weak immediate base, but no proven improvement over the protected product baseline and no promotion.

## Implemented corrections

### Generate and learned-deck safety

- `/ai/generate` now always emits `deckbuilding_contract`, including missing-profile, mock and fallback paths.
- Generate cache contract was bumped so pre-fix payloads cannot omit the contract.
- Missing deterministic diagnostics no longer count as ready; contract v4 requires explicit validation and zero unresolved cards.
- Learned decks are usable only when `legal_status` is explicitly `legal` or `commander_legal`; missing status no longer defaults to legal.
- Six invalid corpus UUIDs were replaced by stable Commander seeds; read-only preflight validates all 19 distinct decks before API startup or authentication.

### Optimize and apply safety

- Empty/malformed battle summaries and malformed divergence lists now fail closed.
- A blocked preflight publishes the current run's report instead of reusing a stale `latest` artifact.
- Development mock optimize is non-actionable, non-learning and returns zero swaps.
- Optimize cache contract moved to v8.
- Sync and async complete-mode responses now include `optimization_contract` and `battle_validation`.
- Partial optimize selection is atomic by swap index: an addition and removal cannot be cross-paired or applied out of range. Complete mode still supports individual additions.
- The retracted `path_provider_foundation 2.5.0` was minimally updated to 2.6.0, with `objective_c 9.1.0` to 9.4.1. Final app/server audits report zero advisories and zero retracted packages.

### Battle runtime safety

- XMage no longer reports success before a positive-turn `GameView` exists.
- XMage, Forge, Native clients and the async runner reject wrong-engine, error-bearing and zero-turn completed payloads.
- XMage 504 is not retried in the same process unless restart is explicitly required.
- Forge refuses completed output without positive turn evidence.
- Zero-turn results cannot become deck-learning evidence.
- `DamageAllEffect` source matching now distinguishes global, flying, nonflying, attacking, tapped, untapped and nonartifact scopes.
- A valid post-fix XMage run produced 19 turns, 678 events, 224 snapshots and zero engine errors; it remained non-promotable without strategy proof.

Battle launch coverage remains:

- 33,268 of 34,331 global cards covered (`96.9037%`).
- 23,942 of 23,951 local-catalog objects executable (`99.9624%`).
- The 1,063 global residuals are terminal nonstandard, auxiliary, physical/external or scenario/challenge objects rather than an unclassified normal-card backlog.

## Validation performed

- `quality_gate full`: PASS; Flutter full suite 637 tests.
- Integrated E2E: PASS for Patrol local, deckbuilder/UI, commercial/retention/trade, observability, server AI routes, battle pytest, 19-deck read-only corpus, AI bridge, PG/Hermes/SQLite contract and deep-AI alignment.
- Patrol: 9/9 local and 9/9 Chrome headless.
- Battle product gate: Native 17, Forge 13, async runner 12, XMage Maven 9, static audit 14/14, Dart 58 pass/1 skip.
- Scope split: 1,187 tests plus 266 subtests.
- UI audit: 10/10.
- Custom lint: app, server and lint package PASS.
- Dependency validator: app, server and lint package PASS.
- Report retention and server-target audits: PASS.
- Canonical audits: operational 53/53, deckbuilding 344 active/0 failures, XMage strategy 29/29, XMage execution 39/39, legacy contamination 32/32, Lorehold artifacts 260 pass/1 historical warning/0 invalid.
- Formatting, Bash syntax, Python compile checks and `git diff --check`: PASS.

## Intentionally not executed

- Mutating 19-deck resolution E2E: creates validation users/decks in PostgreSQL and requires explicit write approval.
- Authenticated server/live product E2E: creates users/decks and was not pointed at production.
- Physical Android/iOS Patrol: would install/control the connected device; local and Chrome fake-API coverage was used instead.

During the first pre-fix resolution attempt, the old gate reached its local PostgreSQL cleanup and removed one validation user. No product deck or product metadata was changed. The gate now runs read-only preflight first and defaults the integrated E2E to the read-only path.

## Remaining priorities

1. **P0 — Deploy and revalidate live:** the sidecar/backend fixes are local. Deploy them, then run an isolated authenticated generate/optimize/battle cohort before claiming production improvement.
2. **P1 — Repair product deck structure:** 10/16 product Commander decks still need repair. Prepare exact precheck/apply/rollback packages and obtain explicit PostgreSQL approval.
3. **P1 — Produce fresh real optimizer evidence:** the latest non-mock larger gate is from 2026-07-06 and promoted nothing.
4. **P2 — Recompute subset narrative:** when a user applies only some atomic swaps, `post_analysis` still describes the full preview and may be optimistic.
5. **P2 — Dependency modernization:** many non-vulnerable updates remain; handle them in small platform-specific batches rather than broad churn.
