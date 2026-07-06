# ManaLoom Deep AI Data Coherence Validation - 2026-07-06

## Objective

Validate whether the ManaLoom AI surfaces are functional and coherent with the curated data layers used by battle and deckbuilder flows, and whether they can consume and use those data sources instead of operating as generic/mock AI.

## Verdict

Status: PARTIAL PASS.

The core AI architecture is coherent and functional for deckbuilder/optimizer usage. The generate, optimize, rebuild/reference, commander-learning, matchup, weakness-analysis, and explain surfaces are wired to Postgres-backed card/deck data, validation services, Commander reference evidence, learned deck evidence, semantic tags, collection/budget constraints, and production fallback guards.

It is not correct to claim 100% closed yet because one real battle-data integrity issue remains:

- `pg_integrity.battle_rules_trusted_oracle_hash_coverage` failed.
- 44 trusted/executable `card_battle_rules` rows are missing `oracle_hash`.
- This does not prove the optimizer is failing to consume data, but it weakens drift protection for battle-rule truth and blocks a "100% battle-governed" claim.

## Current Data Surface Verified

New Postgres target was validated through `server/bin/with_new_server_pg.sh`.

Rows observed:

| Table/View | Rows |
| --- | ---: |
| `cards` | 34,331 |
| `card_intelligence_snapshot` | 34,331 |
| `card_function_tags` | 112,585 |
| `card_semantic_tags_v2` | 24,185 |
| `card_battle_rules` | 9,158 |
| `commander_learned_decks` | 76 |
| `commander_learning_snapshot` | 107 |

Migration status:

- Total migrations: 31
- Executed: 31
- Pending: 0

## AI Surfaces Reviewed

Reviewed routes:

- `POST /ai/generate`
- `POST /ai/optimize`
- `POST /ai/rebuild`
- `GET /ai/commander-reference`
- `GET /ai/commander-learning`
- `POST /ai/weakness-analysis`
- `POST /ai/simulate-matchup`
- `POST /ai/simulate`
- `POST /ai/explain`
- `POST /ai/archetypes`
- `GET /ai/ml-status`

## Consumption Evidence

### Generate / Deckbuilder

Confirmed behavior:

- Loads OpenAI runtime config and blocks missing provider in production-like profiles.
- Uses Commander reference profile/card stats/corpus guidance when available.
- Uses active learned deck and promoted learned card evidence in deterministic fallback/guidance.
- Validates generated cards with `GeneratedDeckValidationService` against Postgres.
- Emits `deckbuilding_contract` diagnostics for Commander reference flows.
- Logs valid Commander generated decks for learning.
- Blocks invalid generated output with `422` in production-like profiles instead of silently using mock fallback.

Conclusion: coherent. The generate flow is not just generic text generation; it is contract-validated and source-aware.

### Optimize / Deck Improvement

Confirmed behavior:

- Requires authenticated user/deck context.
- Blocks missing OpenAI provider in production-like profiles for normal optimize.
- Uses `card_intelligence_snapshot` as the one-row-per-card surface.
- Consumes functional tags, semantic tags, role scores, battle rules, popularity, prices, color identity, collection ownership, and budget.
- Applies `prefer_collection` and `budget_limit_brl`.
- Filters off-color additions.
- Validates and trims swap pairs.
- Produces `additions_detailed` with recommendation detail, risk, priority, collection/market info, and BRL price context.
- Runs `OptimizationValidator` over the virtual post-change deck.

Conclusion: coherent. The optimizer consumes the curated data model and has guardrails for collection, budget, identity, role preservation, and post-change validation.

### Commander Learning / Reference

Confirmed behavior:

- Reads `commander_learned_decks` for promoted active decks.
- Rejects incomplete learned decks.
- Rebuilds role summary/metadata from canonical card metadata.
- Validates learned deck payloads through Commander deck validation.
- `commander-reference` combines persisted reference profiles, card stats, deck corpus guidance, and promoted learned deck evidence.

Conclusion: coherent. Learned data is used as evidence, with validation and safe public response shape.

### Weakness / Matchup / Simulation

Confirmed behavior:

- Prefer `card_intelligence_snapshot` when available.
- Fallback selectors aggregate `card_function_tags` and `card_semantic_tags_v2` with subqueries, avoiding multi-row fanout.
- Routes scope private deck reads by owner.
- Tests cover authorization and no-fanout behavior.

Conclusion: coherent for data consumption and access boundaries.

### Explain

Confirmed behavior:

- Uses cached `cards.ai_description` when available.
- Calls OpenAI with judge/coach-style instructions.
- Blocks offline/mock explanation in production-like profile when provider is missing.

Conclusion: functional. It is less deeply tied to battle/deckbuilder data than optimize/generate, but has production fallback policy.

## Automated Validation Run

### Dart Tests

Command:

```bash
JWT_SECRET=local_deep_ai_validation_20260706 dart test \
  test/commander_ai_prompt_eval_suite_test.dart \
  test/commander_deckbuilding_contract_support_test.dart \
  test/commander_learned_deck_support_test.dart \
  test/ai_generate_learning_boundary_test.dart \
  test/experimental_deck_ai_authorization_source_test.dart \
  test/candidate_quality_data_support_test.dart \
  test/data_model_migration_test.dart \
  test/optimize_route_request_support_test.dart \
  test/optimize_route_recommendation_context_support_test.dart \
  test/optimization_quality_gate_test.dart \
  test/ai_optimize_authorization_source_test.dart \
  test/production_ai_mock_fallback_policy_test.dart \
  test/openai_runtime_config_test.dart \
  test/commander_reference_card_stats_support_test.dart \
  test/commander_reference_profile_support_test.dart
```

Result:

- 149 tests passed.

Coverage highlights:

- AI prompt eval suite.
- Deckbuilding contract diagnostics.
- Learned deck parsing/import gates.
- Generate/learning source boundary.
- AI route authorization.
- Card intelligence snapshot anti-fanout.
- Data migrations for semantic/battle/community/retention surfaces.
- Optimize request context for collection and budget.
- Optimization quality gate.
- Production mock fallback policy.
- OpenAI runtime profile behavior.
- Commander reference card stats/profile rules.

### Static Analysis

Command:

```bash
dart analyze
```

Result:

- No issues found.

### Product Eval Gate

Command:

```bash
./scripts/quality_gate.sh ai-eval
```

Result:

- Status: pass
- Score: 100
- Minimum score: 90
- Cases: 3/3 passed

Validated fixed cases:

- Kaalia collection + budget + bracket 3
- Lorehold protected anchors + bracket 2
- Atraxa budget + curve + no cEDH drift

The eval checks:

- Output card exists in catalog.
- Removed card exists in original deck.
- Added card is not already in deck.
- Protected anchors are preserved.
- Color identity is respected.
- Bracket fit is respected.
- Same functional lane is preserved.
- Battle-feedback blocked pairs are blocked.
- Explanation includes function, risk, curve, price, and bracket.
- No unsupported battle-proof claims are made.
- Budget and collection constraints are respected.

## Auditor Results

| Auditor | Result | Evidence |
| --- | --- | --- |
| Deckbuilding contract surface audit | PASS | 341 active surfaces, 0 failures |
| XMage strategy consistency audit | PASS | 26/26 checks |
| Operational surface alignment audit | PASS | 42/42 checks |
| Legacy contamination audit | PASS | 32/32 checks |
| PG/Hermes/SQLite contract audit through new PG tunnel | FAIL | 50/51 checks passed |

The failed PG/Hermes check:

```text
pg_integrity.battle_rules_trusted_oracle_hash_coverage
trusted_executable_rules_missing_oracle_hash=44
```

This means 44 trusted/executable battle rules are missing oracle-hash provenance.

## Warnings

1. Some historical Kaalia battle artifacts are volatile and missing locally because they depend on ignored replay/Hermes artifacts. The deckbuilding contract audit treats these as warnings, not active failures.

2. Deterministic fallback exists for development and timeout recovery, but production-like profile blocks missing provider and invalid validation fallback where it matters. Production still needs live environment monitoring to confirm provider config and response latency continuously.

3. The current prompt eval suite has 3 fixed product cases. It is useful, but should grow before claiming broad model quality across all commanders/archetypes.

## Final Product Read

What is confirmed:

- The AI deckbuilder is source-aware and validation-backed.
- The optimizer consumes curated collection, budget, semantic, battle, and card-intelligence data.
- Learned decks and Commander reference evidence are consumed through validated, safe surfaces.
- Production mock fallback policy is covered by tests.
- Anti-fanout card intelligence access is covered by tests.
- Current database has enough populated data to support the flows.

What is not yet 100%:

- Battle-rule drift governance is incomplete until the 44 trusted/executable rules missing `oracle_hash` are backfilled and re-audited.
- Live OpenAI response quality has not been sampled at large scale across many real user decks in this run.
- Historical battle replay artifacts that are intentionally ignored locally cannot be used as current proof unless regenerated or rehydrated.

## Required Next Step To Close 100%

Prepare and run a controlled Postgres backfill for the 44 `card_battle_rules` rows missing `oracle_hash`, with:

1. Precheck query listing affected rules.
2. Backfill based on the current canonical Oracle text/hash source.
3. Rollback plan.
4. Postcheck proving `trusted_executable_rules_missing_oracle_hash=0`.
5. Rerun `pg_hermes_sqlite_contract_audit.py` through `server/bin/with_new_server_pg.sh`.

Because this changes production Postgres truth, it should only be applied after explicit database-write approval.
