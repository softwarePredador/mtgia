# ManaLoom free beta: release and operations gate

Date: 2026-07-16
Scope: non-live implementation and local contract validation
Status: tooling ready; external proofs listed below remain open

## What this gate guarantees

The release tooling now rejects a publish when any of these invariants is not
proven:

1. The selected source, local `HEAD`, and `origin/master` are the same commit.
2. The release worktree is clean and `app/pubspec.yaml` has a valid positive
   `semver+build` version.
3. Web, APK, and AAB manifests identify that same Git SHA and version.
4. The APK package, version code/name, signing certificate, and strict Android
   permission allowlist pass inspection.
5. Checksums, CycloneDX SBOM, release identity, and in-toto/SLSA provenance are
   present and internally consistent.
6. Publication has a configured Sentry DSN and a `passed` Sentry/FCM evidence
   file for that exact SHA and version. `not_proven` is a hard failure.

A build-only candidate can intentionally be produced without a Sentry DSN for
local validation. Its manifests record `sentry_configured: false`, so it cannot
be published accidentally.

The release SBOM walks the production Dart dependency graph from the app's
locked direct dependencies; unrelated Node tooling and dev-only packages are
not attributed to the shipped APK/web artifact.

## Local checks with no deployment or external writes

Run the release/DR contract suite:

```bash
scripts/manaloom_release_ops_contract_test.sh
```

Run shell and workflow checks:

```bash
shellcheck -S warning -x \
  scripts/manaloom_build_android_release.sh \
  scripts/manaloom_build_beta_release.sh \
  scripts/manaloom_deploy_flutter_web.sh \
  scripts/manaloom_full_restore_drill.sh \
  scripts/manaloom_offsite_backup.sh \
  scripts/manaloom_publish_android_release.sh \
  scripts/manaloom_release_identity.sh \
  scripts/manaloom_release_observability_gate.sh \
  scripts/manaloom_verify_android_release_artifacts.sh \
  scripts/manaloom_release_ops_contract_test.sh
```

The two stateful operational scripts are dry-run by default:

```bash
scripts/manaloom_offsite_backup.sh \
  --source /path/to/postgres.dump \
  --destination s3://bucket/prefix \
  --recipient age1PUBLIC_KEY

scripts/manaloom_full_restore_drill.sh \
  --backup /path/to/downloaded.dump.age \
  --identity /secure/path/to/age-identity.txt \
  --manifest /path/to/downloaded.dump.age.json

scripts/manaloom_release_observability_gate.sh \
  --device ANDROID_SERIAL \
  --release-manifest /path/to/release-manifest.json
```

Each returns JSON with `status: dry_run` and `writes_performed: false`.

## Candidate build without publication

This command requires a clean, committed `origin/master`, Flutter/Android
toolchains, the Android upload keystore, and its Keychain passwords. It does not
need Sentry credentials by default and does not deploy:

```bash
MANALOOM_RELEASE_REQUIRE_SENTRY=0 \
  scripts/manaloom_build_beta_release.sh
```

The result is stored below
`~/.manaloom/releases/<version>/<short-sha>/` and includes:

- web build plus `/app/release.json`;
- signed APK and AAB;
- `beta-candidate.json` with the cross-platform identity invariant;
- SBOM, permission report, provenance, release manifests, and SHA-256 sums.

## Off-site encrypted backup proof

Execution is deliberately double-gated and requires `age`, AWS credentials, an
age X25519 public recipient, and an S3 destination:

```bash
MANALOOM_OFFSITE_BACKUP_EXECUTE=1 \
  scripts/manaloom_offsite_backup.sh \
    --source /path/to/postgres.dump \
    --destination s3://bucket/prefix \
    --recipient age1PUBLIC_KEY \
    --evidence-dir /secure/evidence \
    --execute
```

The uploaded object is encrypted client-side with age and server-side by S3.
The script verifies remote bytes, SHA-256 metadata, source SHA metadata, and the
separate manifest object before returning `status: uploaded`.

## Isolated full-restore proof

After downloading the `.age` object and its JSON manifest, run:

```bash
MANALOOM_RESTORE_DRILL_EXECUTE=1 \
  scripts/manaloom_full_restore_drill.sh \
    --backup /path/to/downloaded.dump.age \
    --identity /secure/path/to/age-identity.txt \
    --manifest /path/to/downloaded.dump.age.json \
    --evidence-dir /secure/restore-evidence \
    --execute
```

The script verifies the encrypted checksum, decrypts to an ephemeral `0700`
directory, verifies the original dump checksum, and performs a full restore in
a temporary Postgres 17 container with `--network none`. It checks the minimum
table count, immediate foreign-key constraints, database size, and critical row
counts, then destroys the container and plaintext staging directory.

## Sentry and FCM proof for publication

The gate needs a physical Android device, Sentry API credentials, a release
manifest built with Sentry, and an explicit foreground/background FCM delivery
log. The FCM registration smoke creates a QA user/token in the selected API, so
stateful execution is separately acknowledged:

```bash
MANALOOM_RELEASE_OBSERVABILITY_EXECUTE=1 \
MANALOOM_OBSERVABILITY_ALLOW_STATEFUL_API=1 \
  scripts/manaloom_release_observability_gate.sh \
    --device ANDROID_SERIAL \
    --api-base-url https://staging.example \
    --release-manifest /path/to/release-manifest.json \
    --fcm-delivery-log /path/to/fcm-delivery-proof.log \
    --evidence-dir /secure/observability-evidence \
    --execute
```

The log must contain both `FCM_FOREGROUND_DELIVERY_PASS` and
`FCM_BACKGROUND_TAP_DELIVERY_PASS`. The result JSON contains Sentry event ID,
smoke tag, FCM registration/delivery proof, SHA, and version. Android publication
requires this file through `MANALOOM_RELEASE_OBSERVABILITY_EVIDENCE`.

The script also rejects a dirty checkout, a `HEAD` that is not the same commit
as `origin/master` and the release manifest, or a committed pubspec version that
differs from the manifest. Its Flutter integration tests are rebuilt from that
exact clean source. They do **not** install or execute the signed APK file from
the release directory, so the evidence explicitly records
`artifact_installation: not_proven`. A physical install/start/flow pass of that
exact signed APK remains a separate release proof and must not be inferred from
this gate.

## CI evidence

`.github/workflows/manaloom-guardrails.yml` now has read-only repository
permissions and, on product changes:

- runs the release/DR contract suite;
- builds a release APK probe;
- enforces the Android permission allowlist;
- generates CycloneDX SBOM and in-toto/SLSA provenance;
- uploads the evidence bundle with a 30-day retention period.

## Backend production CORS deploy contract

Backend deployment now requires `MANALOOM_ALLOWED_ORIGINS` in the deployment
environment. It must be a comma-separated list of exact HTTPS origins and must
include:

```text
https://evolution-manaloom-web-public.2ta7qx.easypanel.host
```

The validator rejects `*`, HTTP, paths, credentials, whitespace/control
characters, duplicate origins, localhost/`.local`, and non-global IPs. During a
real deployment, the validated canonical value is applied with
`docker service update --env-add MANALOOM_ALLOWED_ORIGINS=...`. The script then
compares SHA-256 values for both the Swarm service spec and the running
container environment; it never prints the allowlist value or unrelated
environment secrets.

The validation itself is safe to run locally:

```bash
MANALOOM_ALLOWED_ORIGINS='https://evolution-manaloom-web-public.2ta7qx.easypanel.host' \
  scripts/manaloom_validate_production_origins.py
```

## External proofs still open on this workstation

An Android release probe was built and inspected locally on 2026-07-16. It
passed package/version/signature/release-mode and permission checks with APK
SHA-256
`c5525db2526cc258214621af98e0452eff3e3eef1882d8fd076fb0336b591ab4`.
Its permissions are limited to network state/internet, camera, notifications,
wake lock, FCM receive, and the app's internal dynamic-receiver permission.
Because it came from the active shared worktree rather than the clean
same-SHA release orchestrator, it is a validation probe, not the publishable
beta artifact.

The 2026-07-16 non-secret precheck found:

- no Sentry DSN/auth token/org/project configuration;
- no production `MANALOOM_ALLOWED_ORIGINS` configuration in the current local
  environment file; backend deploy is intentionally blocked until it is set;
- no physical Android device attached;
- the exact signed release APK has not been installed and exercised on a
  physical device;
- no FCM foreground/background delivery evidence;
- `age` is not installed and no age recipient or off-site S3 destination is
  configured;
- Docker CLI is installed, but the Docker daemon is unavailable;
- no real dump was selected for the isolated full-restore run.

These are environment/credential/device proofs, not source-code gaps. No deploy,
publication, cloud upload, production database operation, or device write was
performed while implementing this gate.
