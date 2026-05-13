# Sanitized runtime log summary - Commander Reference app value - 2026-05-13

- Classification: PASS.
- Device: Android SM A135M, id R58T300SREH, Android 14/API 34.
- Backend: https://evolution-cartinhas.8ktevp.easypanel.host.
- Backend health: HTTP 200, git_sha 0ac7fa972daed1c16850d0384976aaedee9978a5.
- Runtime command: `flutter test integration_test/commander_reference_app_value_runtime_test.dart -d R58T300SREH --dart-define=API_BASE_URL=<public-backend> --dart-define=PUBLIC_API_BASE_URL=<public-backend> --reporter expanded --no-version-check`.
- Result: `01:38 +1: All tests passed!`.
- Auth: disposable QA user created through UI; email/password/token omitted.
- Scanner/camera/OCR: not used.

## Commander summaries

| Commander | Preview | Details | Validate | Main | Total | Commander outside 99 | Off identity |
| --- | --- | --- | --- | ---: | ---: | --- | ---: |
| Prosper, Tome-Bound | PASS | PASS | PASS | 99 | 100 | PASS | 0 |
| Edgar Markov | PASS | PASS | PASS | 99 | 100 | PASS | 0 |
| Aesi, Tyrant of Gyre Strait | PASS | PASS | PASS | 99 | 100 | PASS | 0 |

## Captures emitted by integration test

The raw base64 screenshot chunks were emitted by `captureVisualProof`; this repository stores only this sanitized index, not the raw full test stream.

- commander_reference_app_value_01_login (474513 bytes)
- commander_reference_app_value_02_registered (367080 bytes)
- commander_reference_app_value_03_logged_in (444467 bytes)
- commander_reference_app_value_prosper_01_prompt (273425 bytes)
- commander_reference_app_value_prosper_02_preview (278609 bytes)
- commander_reference_app_value_prosper_03_details (838903 bytes)
- commander_reference_app_value_edgar_01_prompt (267296 bytes)
- commander_reference_app_value_edgar_02_preview (270548 bytes)
- commander_reference_app_value_edgar_03_details (856086 bytes)
- commander_reference_app_value_aesi_01_prompt (272480 bytes)
- commander_reference_app_value_aesi_02_preview (270531 bytes)
- commander_reference_app_value_aesi_03_details (798780 bytes)

## Sanitization notes

- Full QA email, password, auth token, JWT, SENTRY_DSN, DATABASE_URL, OPENAI_API_KEY and complete decklists are intentionally absent.
- Deck ids from the raw test stream are intentionally omitted from this stored summary.
- The Aesi commander row is normalized by face matching because the backend returned the commander card name as `Aesi, Tyrant of Gyre Strait // Aesi, Tyrant of Gyre Strait`; validation still passed with one commander outside the 99.
