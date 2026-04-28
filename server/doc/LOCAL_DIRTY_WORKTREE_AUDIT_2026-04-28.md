# Local Dirty Worktree Audit - 2026-04-28

## Scope

Audited only these remaining dirty files:

- `app/ios/Flutter/AppFrameworkInfo.plist`
- `app/ios/Podfile.lock`
- `app/ios/Runner/AppDelegate.swift`
- `app/ios/Runner/Info.plist`
- `app/test/features/decks/providers/deck_provider_support_test.dart`
- `server/test/artifacts/ai_optimize/source_deck_optimize_latest.json`

Recent inspected commit window:

- `4479329` Add meta reference explainability
- `fffe4b8` Operationalize external meta pipeline
- `914a14d` Prove external meta value and extend scan-through
- `a5e3acb` Add scan-through meta expansion
- `a11e80a` Harden external meta pipeline
- `7b06c5a` Audit external meta promotion follow-up
- `7265edb` Audit commander optimize follow-up
- `8629ace` Fix commander optimize cache proof
- `8374732` Add commander optimize audit report
- `ec5bdf4` Add commander optimize flow audit agent
- `da4aa8d` Validate iPhone 15 runtime flow
- `c7b1b82` Expand Sentry coverage and switch runtime QA to iPhone 15

## Commands Run

```bash
git --no-pager status --short
git --no-pager log --oneline -12
git --no-pager diff -- <audited files>
git --no-pager diff -U1 -w -- app/test/features/decks/providers/deck_provider_support_test.dart
flutter test app/test/features/decks/providers/deck_provider_support_test.dart
flutter analyze app/lib/features/decks app/test/features/decks
flutter build ios --simulator --no-codesign
```

## Classification

| File | Classification | Evidence | Recommended action |
| --- | --- | --- | --- |
| `app/ios/Runner/AppDelegate.swift` | **intentional -> separate commit** | Real semantic change: app delegate now adopts `FlutterImplicitEngineDelegate` and registers plugins via `didInitializeImplicitFlutterEngine`. iOS simulator build succeeded. | Keep with the iOS runtime batch below. |
| `app/ios/Runner/Info.plist` | **intentional -> separate commit** | Real semantic change: adds `UIApplicationSceneManifest` with `FlutterSceneDelegate`; keeps ATS/camera/indirect-input keys in the active section instead of trailing duplicates. iOS simulator build succeeded. | Keep with the same iOS runtime batch. |
| `app/ios/Flutter/AppFrameworkInfo.plist` | **intentional -> separate commit** | Removes duplicated `MinimumOSVersion` from the Flutter framework bundle metadata. Build still succeeds; deployment target is still controlled elsewhere (`Runner.xcodeproj` and Podfile settings). | Keep with the same iOS runtime batch. |
| `app/ios/Podfile.lock` | **intentional -> separate commit** | Lockfile now reflects the already-declared `webview_flutter` dependency and current CocoaPods resolution (`webview_flutter_wkwebview`, updated plugin checksums, CocoaPods `1.16.2`). The same lock state built successfully for the simulator. | Keep with the same iOS runtime batch. |
| `app/test/features/decks/providers/deck_provider_support_test.dart` | **needs human decision** | No behavior change found. `git diff -w` reduces this to formatter-style wrapping/reindent only; targeted Flutter test still passes. This is source churn, not generated output. | Exclude from the iOS commit. Either discard as local formatting noise or commit later as an explicit formatting-only change if desired. |
| `server/test/artifacts/ai_optimize/source_deck_optimize_latest.json` | **discardable generated artifact** | Diff is dominated by volatile run data: `cloned_deck_id`, `job_id`, `cache_key`, `total_ms`, stage timings, and the non-deterministic optimize output snapshot from a fresh run. No paired report/update in this audit depends on this exact JSON blob. | Safe to remove only if no new audit/report is being committed with it. Do not mix into unrelated code commits. |

## Safe Separate Commit Candidate

These four files are clearly related and validated together:

- `app/ios/Flutter/AppFrameworkInfo.plist`
- `app/ios/Podfile.lock`
- `app/ios/Runner/AppDelegate.swift`
- `app/ios/Runner/Info.plist`

Suggested commit message:

```text
Align iOS runtime with implicit Flutter engine

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

Validation already collected for this batch:

- `flutter analyze app/lib/features/decks app/test/features/decks`
- `flutter test app/test/features/decks/providers/deck_provider_support_test.dart`
- `flutter build ios --simulator --no-codesign`

## Notes

- Nothing was reverted or removed automatically in this audit.
- `server/test/artifacts/ai_optimize/source_deck_optimize_latest.json` should be deleted only with intent, because it is tracked but this specific delta is pure run-by-run noise.
- `app/test/features/decks/providers/deck_provider_support_test.dart` should stay out of the iOS runtime commit unless someone explicitly wants a formatting-only commit.
