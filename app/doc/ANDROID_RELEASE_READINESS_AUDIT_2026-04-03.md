# Android Release Readiness Audit - 2026-04-03

## Verdict

The Android app is technically ready for release validation and can be
published after two operational requirements are satisfied:

1. Provide a real Android release keystore via `android/key.properties`.
2. Provide `SENTRY_DSN` in the release build environment if production crash
   telemetry is expected.

This audit focused on crashes/logging, permissions, onboarding/navigation,
release builds, cold start, background/resume, and basic regressions outside
the life counter.

## Findings

### 1. Crashes and production logging

- `AppObservability.bootstrap()` wraps the app startup and installs:
  - `FlutterError.onError`
  - `PlatformDispatcher.instance.onError`
  - Sentry integration when `SENTRY_DSN` is provided
- Current implementation is safe to ship, but production crash reporting is
  operationally disabled unless `SENTRY_DSN` is injected at build time.
- Result:
  - code path is present and stable
  - release observability still depends on environment configuration

### 2. Permissions review

- Android manifest currently declares only:
  - `android.permission.INTERNET`
  - `android.permission.CAMERA`
- Camera is marked optional in the manifest.
- Runtime camera permission is requested only in the scanner flow:
  - `lib/features/scanner/screens/card_scanner_screen.dart`
- No excessive Android permissions were found in the audited surface.

### 3. Onboarding and navigation review

- Release cold start goes through splash and lands on login as expected when
  there is no authenticated session.
- `OnboardingCoreFlowScreen` exists and is routed, but it is not the default
  first-run destination for anonymous users; this appears to be a product
  decision, not a routing bug.
- A real navigation issue was found and fixed:
  - `Login -> Criar conta` used `context.go('/register')`
  - this replaced the route stack, so Android back from register exited the app
  - it now uses `context.push('/register')`
  - register now returns via `pop()` when possible, with `/login` fallback

### 4. Android release build validation

- `flutter build apk --release --no-version-check`: passed
- `flutter build appbundle --release --no-version-check`: passed

Release build was previously blocked by R8 / ML Kit optional script classes.
This was fixed by:

- adding `android/app/proguard-rules.pro`
- wiring release `proguardFiles(...)` in `android/app/build.gradle.kts`

Release signing is now prepared for a real keystore:

- if `android/key.properties` exists, release uses that signing config
- otherwise it falls back to debug signing for local validation only

That means:

- release builds are green
- Play Store publishing still requires a real keystore file

### 5. Cold start and background/resume

Validated on Android emulator with release APK:

- cold start:
  - `MainActivity` launched normally
  - login screen rendered after splash
  - observed launch time: about `5.8s` to `6.0s` on the current emulator
- background/resume:
  - app moved to launcher via Home
  - app resumed hot back to `MainActivity`
  - observed hot resume time: about `0.8s`
  - login state was preserved correctly

### 6. Basic regressions outside the life counter

Validated successfully:

- `test/smoke_test.dart`
- `test/features/auth/screens/auth_screens_test.dart`
- `test/features/decks/screens/deck_flow_entry_screens_test.dart`
- `test/features/decks/screens/deck_details_screen_smoke_test.dart`
- `test/features/decks/screens/deck_import_screen_test.dart`

These cover:

- basic app shell rendering
- auth entry screens
- deck generation/import entry flow
- deck details loading/error/optimize path
- deck import baseline states

## Remaining blockers

### Release blockers

- Missing real release keystore material in `android/key.properties`
- Missing `SENTRY_DSN` in release environment if production crash monitoring is
  a release requirement

### Non-blocking improvements

- Splash currently enforces a noticeable fixed delay before login; acceptable
  for now, but worth shortening later if startup polish becomes a priority.
- Onboarding is routed and functional, but not part of the anonymous default
  startup flow; this should be revisited only if product wants first-run
  onboarding before login.

## Final assessment

The app is in a publishable state from the perspective of code stability and
Android release packaging.

The main remaining work for store submission is operational:

- plug the real signing key into `android/key.properties`
- decide whether release builds must include active Sentry telemetry
