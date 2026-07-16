# ManaLoom Consistency Test Battery - 2026-07-06

## Scope

Validation of app and backend logic implemented up to 2026-07-06, focusing on:

- Flutter app analysis and widget/unit tests.
- Backend unit/contract tests.
- AI/deckbuilder/battle/PostgreSQL/Hermes alignment.
- App-to-AI knowledge bridge.
- New ManaLoom server target guardrail.
- Read-only production health and AI metrics endpoints.

No production PostgreSQL write was performed in this battery.

## Result

Overall status: PASS with one explicit exclusion.

The automated local/backend/app/deep-AI gates passed. The only gate not completed
was the resolution corpus live runner, because it requires a local API connected
to the new PostgreSQL target and performs live API writes/clones during the
validation flow.

## Commands Run

### Backend

```bash
cd server
JWT_SECRET=local_consistency_battery_20260706 dart test
```

Result:

- PASS
- Final runner output: `All tests passed!`
- Observed total: `631` passing, `9` skipped optional fixture-dependent tests.

### Flutter App

```bash
cd app
flutter analyze --no-fatal-infos
flutter test --no-version-check
```

Result:

- `flutter analyze`: PASS, `No issues found`.
- `flutter test`: PASS, `605` tests passed.

Covered app areas included:

- Core error mapping, request id, observability, theme tokens.
- Home and premium visual surfaces.
- Lotus/life counter shell, internal state, native fallback sheets, overflow.
- Deck detail, analysis tab, optimize dialogs, collection/budget recommendation UI.
- Profile editing.
- Community/social providers and error states.
- Scanner OCR/parser/search flows.
- Notifications.

### Deep AI / Data / Battle Alignment

```bash
./scripts/quality_gate.sh deep-ai
```

Result:

- PASS
- Summary: `/tmp/manaloom_deep_ai_alignment_reports/deep_ai_alignment_20260706_195704_summary.md`

Passed checks:

- Dart analyze server.
- Focused AI/data contract tests.
- Commander AI prompt eval.
- ManaLoom server target audit.
- New PostgreSQL migration status.
- New PostgreSQL data counts.
- Deckbuilding contract surface audit.
- XMage strategy consistency audit.
- Operational surface alignment audit.
- Legacy contamination audit.
- PG/Hermes/SQLite contract audit through new PostgreSQL.

Detailed auditor statuses:

- PG/Hermes/SQLite contract audit: PASS, `51/51`.
- Deckbuilding contract surface audit: PASS, `341` active surfaces, `0` failures.
- XMage strategy consistency audit: PASS, `26/26`.
- Operational surface alignment audit: PASS, `48/48`.
- Legacy contamination audit: PASS, `32/32`.

### App AI Bridge

```bash
./scripts/quality_gate.sh ai-bridge
```

Result:

- PASS
- App AI knowledge bridge audit: PASS, `22/22`.
- Server target audit: PASS, `5/5`, `0` old-server violations.
- Commander AI prompt eval: PASS, score `100`, `3/3` cases.

Validated Commander eval cases:

- Kaalia collection + budget + bracket 3.
- Lorehold protected anchors + bracket 2.
- Atraxa budget + curve + no cEDH drift.

### New PostgreSQL Read-only Checks

```bash
server/bin/with_new_server_pg.sh psql -X -A -t -F '|' -c '<read-only counts>'
```

Observed counts:

| Surface | Rows |
| --- | ---: |
| `cards` | 34331 |
| `card_intelligence_snapshot` | 34331 |
| `card_function_tags` | 112585 |
| `card_semantic_tags_v2` | 24185 |
| `card_battle_rules` | 9158 |
| `commander_learned_decks` | 76 |
| `commander_learning_snapshot` | 107 |

Battle rule drift guard:

```text
trusted_executable_rules_missing_oracle_hash|0
```

This means the previous `oracle_hash` blocker is no longer present in the
current validated target.

### Public Read-only Health Checks

Endpoints checked:

- `GET https://evolution-cartinhas.2ta7qx.easypanel.host/health`
- `GET https://evolution-cartinhas.2ta7qx.easypanel.host/ready`
- `GET https://evolution-cartinhas.2ta7qx.easypanel.host/health/ready`
- `GET https://evolution-cartinhas.2ta7qx.easypanel.host/health/commercial`
- `GET https://evolution-cartinhas.2ta7qx.easypanel.host/health/ai-history?days=30&bucket=day`

Result:

- `/health`: PASS, `status=healthy`, git SHA `83a8a6fe77d00501ba383f166f9cec761efec5ba`.
- `/ready`: PASS on retry, `status=ready`, `card_count=34331`.
- `/health/ready`: PASS, `status=ready`, `card_count=34331`.
- `/health/commercial`: PASS, `status=ok`.
- `/health/ai-history`: PASS, `status=ok`, `period_count=2`.

AI metric snapshot from `/health/commercial`:

- AI requests in window: `6`.
- Error count: `0`.
- Error rate: `0.0`.
- Optimize average latency: `3975 ms`.
- Optimize p95 latency: `5371 ms`.
- Total tokens: `22844`.

## Exclusion / Not Completed

### Resolution Corpus Gate

Command attempted:

```bash
./scripts/quality_gate.sh resolution
```

Result:

- NOT COMPLETED as a product logic failure.
- The local compiled API started, but connected to the internal EasyPanel host
  `evolution_manaloom-postgres`, which is not resolvable from local macOS
  outside the wrapper/tunnel.
- Running this gate correctly against the new PostgreSQL target requires
  `server/bin/with_new_server_pg.sh`.
- The runner `server/bin/run_three_commander_resolution_validation.dart` creates
  auth/deck validation data through the API, so it was not rerun through the
  production DB wrapper without explicit approval for live write/cleanup.

## Current Conclusion

The app and implemented logic are consistent in the tested non-mutating scope:

- Backend tests pass.
- Flutter app tests pass.
- Deep AI/data/battle/PostgreSQL/Hermes alignment passes.
- App-to-AI bridge passes.
- The new server target guard passes.
- The previous trusted executable battle-rule `oracle_hash` blocker is closed
  in the current target.
- Public health and AI metric endpoints are responding.

Remaining validation that still requires explicit approval:

- Live resolution corpus gate through the new PostgreSQL wrapper.
- Product smoke that creates/deletes a temporary user/deck/report in production.
- Mobile authenticated QA on a real simulator/device, also backed by a live API.
