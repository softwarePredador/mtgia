# Profile / Community Social Runtime - iPhone 15 Simulator - 2026-04-30

## Target

Profile proprio e Community Social com backend real: abrir/editar/recarregar perfil proprio, abrir perfil publico, validar tabs/contadores, buscar usuarios, follow/unfollow, abrir Community Explorar/Seguindo/Usuarios, abrir deck publico e navegar/back sem crash.

## Runtime Owner

Agent: `GitHub Copilot CLI`

## Fix Owner

Agent: `GitHub Copilot CLI`

## Status

Verdict: `PASS`.

Profile proprio edit/reload, perfil publico, busca de usuarios, follow/unfollow, Community tabs e deck publico foram provados no iPhone 15 Simulator contra `http://127.0.0.1:8082`. Nenhum Life Counter, Sets, meta pipeline, optimize/generate, scanner ou FCM foi alterado.

## Runtime Environment

| Item | Evidencia |
| --- | --- |
| Date | `2026-04-30` |
| Device type | `iPhone 15 Simulator` |
| Device id | `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` |
| Runtime | `com.apple.CoreSimulator.SimRuntime.iOS-17-4` |
| Backend target | `http://127.0.0.1:8082` |
| Health | `app/doc/runtime_flow_proofs_2026-04-30_iphone15_simulator_profile_community/backend_health.json` |
| Flutter/device discovery | `flutter_devices.log`, `simctl_devices.log` |
| Runtime log final | `profile_community_runtime_pass3.log` |

Backend command:

```bash
cd server
PORT=8082 dart run .dart_frog/server.dart
```

Launch command:

```bash
cd app
flutter test integration_test/profile_community_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=SENTRY_DSN=<SENTRY_DSN_REDACTED> \
  --reporter expanded \
  --no-version-check
```

## Account Used

Identifier: generated QA users with marker `qa_pc_19ddedda62f` in final runtime.

How it was created: integration setup used real `/auth/register`, `/auth/login`, card lookup and `/decks` calls against the local backend. No backend or app mock was used in the runtime proof.

## Navigation Path

1. Login viewer via app auth provider.
2. Open Profile screen.
3. Edit `display_name`, `location_state`, `location_city`, `trade_notes`; save; refresh/reopen profile.
4. Open public profile for creator user.
5. Follow creator, open followers tab/list, then unfollow.
6. Open user search, search creator username, tap result, return.
7. Open Community screen.
8. In `Explorar`, search runtime marker, open public deck detail, verify deck content, navigate back.
9. In `Seguindo`, verify followed-public-deck feed loads.
10. In `Usuarios`, search creator username, open public profile, navigate back.

## Evidence

Fresh evidence captured this round: Yes.

- Flutter log: `app/doc/runtime_flow_proofs_2026-04-30_iphone15_simulator_profile_community/profile_community_runtime_pass3.log`
- Backend health: `app/doc/runtime_flow_proofs_2026-04-30_iphone15_simulator_profile_community/backend_health.json`
- Device discovery: `app/doc/runtime_flow_proofs_2026-04-30_iphone15_simulator_profile_community/flutter_devices.log`, `simctl_devices.log`
- Earlier failed runtime logs kept in the same proof folder to preserve root-cause history for harness timing and fixed UI overflows.

Final runtime result: `00:57 +1: All tests passed!`.

Key HTTP observations from final runtime:

| Endpoint | Status/duration |
| --- | --- |
| `POST /auth/login` | `200 (663ms)` |
| `GET /users/me` | `200 (678ms)` then `200 (616ms)` after save |
| `PATCH /users/me` | `200 (599ms)` |
| `GET /community/users/:id` | `200 (1722ms)`, later `200 (1712ms/1714ms)` |
| `POST /users/:id/follow` | `200 (2841ms)`, classified as slow request |
| `GET /users/:id/followers` | `200 (1135ms)` |
| `DELETE /users/:id/follow` | `200 (1152ms)` |
| `GET /community/users?q=...` | `200 (1179ms/1166ms)` |
| `GET /community/decks` | `200 (1178ms)` |
| `GET /community/decks/:id` | `200 (1233ms)` |
| `GET /community/decks/following` | `200 (1164ms)` |

## Observed Result

All required Profile/Community paths completed on the iPhone 15 Simulator with backend real. Profile edit persisted and reloaded; public profile opened; follow/unfollow changed state and followers list loaded; user search opened the correct public profile; Community Explorar/Seguindo/Usuarios loaded; public deck detail opened and showed `Sol Ring`; back navigation returned to expected screens without crash.

## Stop Point

None. Final runtime completed.

## Findings

### Finding 1 - `/users/me` omitted supported Profile fields

Severity: High for requested Profile proof.

Area: Backend contract.

Problem: `GET /users/me` selected `location_state`, `location_city` and `trade_notes`, but did not include them in the response JSON, so edit/reload could not prove the fields supported by the app.

Evidence: Code audit of `server/routes/users/me/index.dart`; final runtime now shows `GET/PATCH/GET /users/me` passing after the contract fix.

Likely owner: Backend Profile.

Likely file/module: `server/routes/users/me/index.dart`.

Smallest next action: completed; keep live test `server/test/profile_community_live_test.dart`.

### Finding 2 - Long usernames overflowed Community deck rows

Severity: Medium UI defect.

Area: Community UI.

Problem: QA usernames generated for runtime overflowed owner rows in `CommunityScreen` deck cards and `CommunityDeckDetailScreen`.

Evidence: earlier runtime logs in the proof folder captured Flutter `RenderFlex overflow`; final runtime passed after wrapping owner text with `Expanded` and ellipsis.

Likely owner: App Community.

Likely file/module: `app/lib/features/community/screens/community_screen.dart`, `app/lib/features/community/screens/community_deck_detail_screen.dart`.

Smallest next action: completed.

### Finding 3 - Follow latency remains high

Severity: Medium performance pending.

Area: Social backend.

Problem: `POST /users/:id/follow` completed successfully but took `2841ms` in final runtime and was classified as slow request.

Evidence: `profile_community_runtime_pass3.log`.

Likely owner: Backend Social.

Likely file/module: `server/routes/users/[id]/follow/index.dart` and DB round-trips/notification path.

Smallest next action: profile as a P1/P2 performance item if follow becomes a target flow; keep current classification/logging.

## Commands Run

```bash
cd server && dart analyze routes/users routes/community lib test && dart test -r expanded
cd server && TEST_API_BASE_URL=http://127.0.0.1:8082 dart test -P live -r expanded
```

```bash
cd app && flutter analyze lib/features/profile lib/features/community lib/features/auth integration_test --no-version-check
cd app && flutter test test/features/profile test/features/community test/features/auth --no-version-check
cd app && flutter test integration_test/profile_community_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --dart-define=SENTRY_DSN=<SENTRY_DSN_REDACTED> --reporter expanded --no-version-check
```

## Validation Notes

- simulator validated: `PASS`.
- physical device validated: not in scope.
- backend real validated: `PASS` on 8082.
- Profile own edit/reload: `PASS`.
- public profile/search/follow/unfollow: `PASS`.
- Community tabs and public deck detail: `PASS`.
- 4xx/5xx/timeout classification: provider/backend tests cover `401`, `403`, `404`, invalid payload and route exceptions; runtime final had no unexpected 4xx/5xx/timeout.
- Secrets: no token, email address, auth body, Sentry DSN or service account content recorded in docs; logs use generated usernames and endpoint/status/duration metadata.

## Reproduction Notes For Fix Agent

Start backend on 8082, keep iPhone 15 Simulator booted, then run `app/integration_test/profile_community_runtime_test.dart` with the launch command above. Use the generated marker printed as `PROFILE_COMMUNITY_MARKER` to locate backend/app log rows for a single runtime pass.
