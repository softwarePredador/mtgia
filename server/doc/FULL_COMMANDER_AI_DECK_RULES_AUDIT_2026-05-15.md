# Full Commander/AI/deck rules audit - 2026-05-15

## Verdict

**PASS_WITH_RISKS** for Track D on `master`.

Scanner/camera/OCR/MLKit: **DEFERRED** and out of functional scope for this
non-scanner audit.

Public backend inspected:

- URL: `https://evolution-cartinhas.8ktevp.easypanel.host`
- Public backend SHA from `/health`: `2a727c801be4e40de4b1d5c41532812f80ca6d72`
- Public readiness: `/health/ready` returned ready with healthy database and
  card data.

Local repository baseline inspected:

- Branch: `master`
- Local HEAD before Track D patch: `2a727c8`
- Note: worktree already had unrelated app/provider changes and a Track A doc
  before this audit; this Track D patch only changed server Commander/deck-rule
  files and docs listed below.

## Scope read

Required docs were read or searched with sanitized output:

- `docs/README.md`
- `server/doc/DOCS_ARTIFACT_RETENTION_AUDIT_2026-05-15.md`
- `server/doc/FULL_FLOW_STATE_AND_DOC_AUDIT_2026-05-15.md`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `app/doc/UI_TEST_SURFACE_MAP.md`
- `app/doc/APP_AUDIT_2026-04-29.md`
- `server/manual-de-instrucao.md`

Code/test areas inspected:

- `server/routes/ai/generate/index.dart`
- `server/routes/ai/optimize/index.dart`
- `server/routes/decks`
- `server/routes/import`
- `server/lib/deck_rules_service.dart`
- `server/lib/color_identity.dart`
- `server/lib/generated_deck_validation_service.dart`
- Commander Reference support under `server/lib/ai`
- relevant server tests.

No secrets, JWTs, API keys, database URLs, Sentry DSNs, real emails, sensitive
payloads, full decklists or raw prompts are included in this report.

## Track D matrix

| Area | Result | Evidence / notes |
|---|---|---|
| `POST /ai/generate` Commander Reference | PASS_WITH_RISKS | Profiles/card stats/corpus diagnostics are documented and tested. Exact profile/card-stat/corpus flags are optional diagnostics; generated deck + validation remain source of truth. Bracket is still not proven as a hard power enforcement gate for generation. |
| `/ai/generate` fallback | PASS_WITH_RISKS | Deterministic reference fallback exists and focused tests pass. Public live generate was not re-run in this audit because the requested task was a non-scanner audit and no auth/payload proof was required. |
| `/ai/optimize` diagnostics | PASS_WITH_RISKS | Intensity, async, quality errors and aggressive diagnostics are documented as optional/evolving; focused optimization tests pass. Remaining risk: provider/mock/error hardening should continue separately. |
| `/decks/:id/validate` | PASS | `DeckRulesService` enforces Commander/Brawl commander count, singleton, legality, color identity and exact size in strict validation. Patch adds commander-not-in-99 by normalized name. |
| Deck create/edit/add/set quantity | PASS_WITH_RISKS | Create/edit/set paths validate via `DeckRulesService`. Incremental add now validates the composed deck before mutation and rejects commander as mainboard card. Live route tests were updated but not executed against a running mutable backend in this audit. |
| Edition visibility | PASS | Contract map confirms `GET /decks/:id` card rows expose `set_code`, `collector_number`, `rarity`, `foil`, optional `set_name`, `set_release_date`; edition picker runtime evidence remains referenced. |
| Import / import-to-deck | PASS_WITH_RISKS | Parser/validate tests pass. Patch prevents `replace_all=true` from silently clearing an existing Commander/Brawl commander when imported list has no commander and adds optional structured commander status fields. |
| Import without commander UX | PASS_WITH_RISKS | Backend now returns optional `missing_commander`/`commander_detected`/`commander_preserved` for import-to-deck. App should surface `missing_commander=true` as a clear draft/review state. |
| Commander not in the 99 | PASS after patch | Same card id and alternate printing/same normalized name are rejected by `POST /decks/:id/cards` and `DeckRulesService`. |
| Off-color cards | PASS after patch | Color identity resolution already supports `mana_cost`; `DeckRulesService` now passes `mana_cost` from DB so incomplete `colors/color_identity` fields are less likely to miss colored spells. |
| Bracket legality/power | PASS_WITH_RISKS | Optimize has bracket safety tests. Generate accepts `bracket` and uses it in cache normalization; hard bracket enforcement in generation remains not_proven. |

## Bugs fixed in this audit

### P0 fixed — Commander could be added to the 99 by exact card id

- File: `server/routes/decks/[id]/cards/index.dart`
- Fix: normal add now rejects a card already selected as commander instead of
  increasing/upserting it as a mainboard operation.
- Test added: live route test in `server/test/decks_incremental_add_test.dart`.

### P1 fixed — Commander could enter the 99 via another printing

- File: `server/lib/deck_rules_service.dart`
- Fix: Commander/Brawl validation builds the commander name set and rejects any
  non-commander row with the same normalized card name.
- Also covered by the composed-deck validation added to incremental card add.

### P1 fixed — Off-color card could be missed when DB color fields were empty

- File: `server/lib/deck_rules_service.dart`
- Fix: `_loadCardsData` now loads `mana_cost` and passes it into
  `resolveCardColorIdentity`.
- Existing deterministic test coverage in `test/color_identity_test.dart`
  verifies mana-cost identity inference.

### P1 fixed — `replace_all=true` could silently clear an existing commander

- File: `server/routes/import/to-deck/index.dart`
- Fix: for Commander/Brawl replace-all imports with no imported commander, the
  existing commander row is preserved.
- Optional response fields added: `commander_detected`, `missing_commander`,
  `commander_preserved`.
- Response semantics tightened: `cards_imported` counts only the submitted list,
  while `total_cards` now reports the final persisted deck total including any
  preserved commander.
- Test added: live route test in `server/test/import_to_deck_flow_test.dart`.
- API map updated for the additive response fields.

## Remaining risks

### P1 remaining

- Some server 500 handlers still return raw exception text in selected routes.
  Recommendation: sanitize client responses and keep detailed exception material
  in safe server logs only.
- Provider/upstream AI error bodies should be audited again to ensure no provider
  payload is echoed to clients.

### P2 remaining

- `POST /ai/generate` `bracket` hard enforcement remains **not_proven**; current
  contract should treat it as request/cache/context unless a future patch wires
  it into generation scoring and validation diagnostics.
- Import preview could be improved with structured edition metadata and explicit
  commander status for all preview cases, not only import-to-deck mutation.
- Optimize cache/result-shape parity should continue to be regression-tested
  when diagnostics evolve.

## Files changed by this Track D patch

- `server/lib/deck_rules_service.dart`
- `server/routes/decks/[id]/cards/index.dart`
- `server/routes/import/to-deck/index.dart`
- `server/test/decks_incremental_add_test.dart`
- `server/test/import_to_deck_flow_test.dart`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `server/manual-de-instrucao.md`
- `server/doc/FULL_COMMANDER_AI_DECK_RULES_AUDIT_2026-05-15.md`

## Validation commands run

```bash
git --no-pager status --short --branch
git --no-pager rev-parse --short HEAD
git --no-pager branch --show-current
grep -RInE "Commander|commander|generate|optimize|validate|import|edition|quantity|scanner|OCR|camera" <required-docs>
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health/ready
cd server && dart format lib/deck_rules_service.dart routes/decks/[id]/cards/index.dart routes/import/to-deck/index.dart test/decks_incremental_add_test.dart test/import_to_deck_flow_test.dart
cd server && dart analyze lib routes test
cd server && dart test test/color_identity_test.dart test/generated_deck_validation_service_test.dart test/import_list_service_test.dart test/import_parser_test.dart -r expanded
cd server && dart test test/commander_reference_deck_corpus_support_test.dart test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart test/ai_generate_performance_support_test.dart -r expanded
cd server && dart test test/mtg_rules_validation_test.dart test/optimization_validator_test.dart test/optimization_quality_gate_test.dart test/optimize_runtime_support_test.dart -r expanded
```

Results:

- `dart analyze lib routes test`: PASS.
- Focused import/color/generated-deck parser tests: PASS, 63 tests.
- Commander Reference focused suite: PASS, 42 tests.
- MTG rules/optimization focused suite: PASS, 91 tests.
- Public `/health` and `/health/ready`: PASS.

## Final classification

**PASS_WITH_RISKS**.

Track D has no remaining P0 after this patch. The highest remaining risks are
hardening/error-sanitization and proving generation `bracket` semantics with
fresh public/live evidence if product wants to present it as enforced power
control.
