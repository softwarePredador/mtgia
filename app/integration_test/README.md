# ManaLoom runtime and E2E harnesses

The app has four distinct test lanes. Keep them separate so a local quality
gate never starts a live or physical-device flow by accident.

## Deterministic Flutter tests

- `test/`: unit, widget, accessibility, and golden tests.
- Golden source images live under `test/**/goldens/` and are reviewable inputs.
- `test/**/failures/` contains generated diffs and must not be committed.

Run the UI lane from the repository root:

```bash
./scripts/quality_gate.sh ui-audit
```

## Flutter runtime tests

- `integration_test/`: device/simulator runtime scenarios.
- The files are scenario-specific; similar life-counter names represent a
  state/visibility/fallback matrix, not generated duplicates.
- `test_driver/integration_test.dart` remains active for `flutter drive`
  screenshot capture. Do not delete it as legacy while those commands exist.

Run one explicit scenario and device at a time:

```bash
cd app
flutter test integration_test/<scenario>_test.dart -d <device-id>
```

Some runtime tests use a public API or mutate an authenticated test account.
Do not run the whole directory without first reviewing its dart-defines and
target environment.

## Web image memory runtime

`image_memory_runtime_test.dart` keeps the Android image-cache/RSS lane and
also exposes explicit Web checkpoints. The Web measurement attaches CDP to the
same ChromeDriver session, samples the Chrome process tree and heap, and
correlates Resource Timing with a deterministic cacheable loopback fixture.
It fails closed when a checkpoint, browser PID, image sample, runtime sample,
or cache-reuse signal is missing.

Run the deterministic Python contract (also included in `full`) separately
from the real browser profile:

```bash
./scripts/quality_gate.sh performance

MANALOOM_CHROMEDRIVER_BIN=/absolute/path/to/matching/chromedriver \
./scripts/quality_gate.sh web-image-memory
```

The Chrome and ChromeDriver major versions must match. The real profile writes
its detailed ignored artifact to `app/build/manaloom_web_image_memory.json`,
starts only a loopback fixture, and does not mutate product data. A red runtime
result is release evidence and must not be converted into a deterministic
`PASS`.

## Patrol critical journeys

- `patrol_test/manaloom_patrol_smoke_test.dart`: deterministic critical product
  journeys with fake services for local and browser runs.
- `ios/RunnerUITests/`: native Patrol bridge for iOS; it is an active target.
- `test_bundle.dart`, `patrol_test/test_bundle.dart`, `playwright-report/`,
  `test-results/`, and `*.xcresult` are generated outputs.

```bash
./scripts/quality_gate.sh patrol-smoke

MANALOOM_RUN_PATROL_DEVICE_TESTS=1 \
MANALOOM_PATROL_DEVICE=chrome \
MANALOOM_PATROL_WEB_HEADLESS=true \
./scripts/quality_gate.sh patrol-smoke
```

For iOS, verify the native contract before running Patrol:

```bash
cd app
xcodebuild -list -project ios/Runner.xcodeproj
xcodebuild -list -workspace ios/Runner.xcworkspace
```

The project must continue to list `RunnerUITests`, and the workspace must list
`patrol` plus `Pods-Runner-RunnerUITests`.

## Product E2E gate

`./scripts/quality_gate.sh e2e` runs the local product/deckbuilder/battle/AI
contract suite. Its live Flutter, backend, and production layers are opt-in via
the `MANALOOM_RUN_*_E2E` variables documented in `test/README.md`.
