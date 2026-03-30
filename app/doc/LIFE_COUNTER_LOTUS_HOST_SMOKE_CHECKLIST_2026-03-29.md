# Life Counter Lotus Host Smoke Checklist - 2026-03-29

## Objective

Validate that the Flutter host around the embedded Lotus counter still boots, bridges correctly, and preserves the verified gameplay shell.

Use this after changes to:

- `lotus_life_counter_screen.dart`
- `app/lib/features/home/lotus/**`
- `app/assets/lotus/**`
- route/bootstrap behavior for `/life-counter`

## Preconditions

- emulator is running
- `com.mtgia.mtg_app` can be installed
- when needed, debug boot into `/life-counter` is enabled explicitly

## Build

```bash
flutter analyze
flutter build apk --debug
flutter run --dart-define=DEBUG_BOOT_INTO_LIFE_COUNTER=true
```

## Optional bridge probe

Use this only when validating bridge health:

```bash
flutter run --dart-define=DEBUG_LOTUS_BRIDGE_PROBE=true
```

Expected log lines:

- `Start Cordova Plugins`
- `bridge probe: {"cordova":true,"appReview":true,"insomnia":true,"clipboard":true}`

Expected side effects:

- clipboard probe is accepted by Flutter host
- app review bridge logs `AppReview requested: requestReview`

## Install / launch flow

Example with local `adb.exe`:

```powershell
$adb = "$env:LOCALAPPDATA\\Android\\Sdk\\platform-tools\\adb.exe"
& $adb uninstall com.mtgia.mtg_app
& $adb install "c:\\Users\\rafae\\OneDrive\\Documents\\mtgia\\app\\build\\app\\outputs\\flutter-apk\\app-debug.apk"
& $adb shell monkey -p com.mtgia.mtg_app -c android.intent.category.LAUNCHER 1
```

## Manual smoke checklist

1. App opens directly on the Lotus counter, not login.
2. Loading overlay disappears without hanging.
3. First onboarding overlay appears.
4. Dismissing onboarding reaches the 4-player board.
5. Horizontal swipe on a player card behaves like the original Lotus flow.
6. Main board visuals match the validated baseline.
7. Center interaction opens the radial/menu flow when applicable.
8. Settings overlay opens without white screen or dead interaction.
9. App remains responsive after background/foreground resume.

## What to compare against

Reference parity captures currently live in:

- `dddddd/comparison/original/`
- `dddddd/comparison/embedded/`

Stable surfaces that should remain effectively equivalent:

- board
- menu/radial state when opened
- settings overlay

## Red flags

Investigate immediately if any of the following happen:

- WebView hangs on black screen
- `Unable to open asset URL` errors return
- clipboard calls throw WebView focus errors again
- `AppReview` stops reaching Flutter
- board loads but gestures stop responding
- Android asset bundle and Flutter asset bundle drift out of sync

## Recovery checks

If behavior regresses, verify these first:

1. `app/assets/lotus/` is still the runtime source of truth
2. `index.html` is still the minimal ManaLoom-owned fallback shell
3. `/life-counter` still routes to `LotusLifeCounterScreen`
4. debug boot flag for life counter is enabled only when expected
