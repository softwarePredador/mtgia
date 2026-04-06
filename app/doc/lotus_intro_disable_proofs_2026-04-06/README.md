# Lotus Intro Disable Proofs

Cold-start captures for the embedded `life counter` after clearing app data on
Android and reopening the app in debug mode.

Files:
- `launch_after_2s.png`
- `launch_after_6s.png`

Validation paired with these captures:
- `flutter test test/features/home/lotus_shell_policy_test.dart --no-version-check`
- `flutter test integration_test/life_counter_webview_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`

The integration smoke now asserts that these intro selectors are not visible in
the embedded `WebView` and that their localStorage completion flags are already
set:
- `.first-time-user-overlay`
- `.own-commander-damage-hint-overlay`
- `.turn-tracker-hint-overlay`
- `.show-counters-hint-overlay`
