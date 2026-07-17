# ManaLoom free beta: release and operations gate

Date: 2026-07-16; technical validation refreshed 2026-07-17
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
7. Backend, public Web, Flutter Web, Android distribution host, manaloom-ops, XMage, and Forge
   capture the previous immutable identity and prove convergence after promote
   or rollback. Container promotion uses a resolved `RepoDigest`, never a
   mutable tag alone.
8. Production auth refuses weak/placeholder JWT secrets and refuses to derive
   client identity from proxy headers unless trusted proxy hops and peers are
   configured explicitly.

A build-only candidate can intentionally be produced without a Sentry DSN for
local validation. Its manifests record `sentry_configured: false`, so it cannot
be published accidentally.

The release SBOM walks the production Dart dependency graph from the app's
locked direct dependencies and inventories every locked Gradle coordinate. A
Gradle component is release-relevant only when the exact right-hand-side token
`releaseRuntimeClasspath` is present; tooling, test, debug and profile entries
remain visible with `scope=excluded` and their canonical configuration evidence.
For Android, generation fails unless the required Gradle set matches the AAB
`BUNDLE-METADATA/com.android.tools.build.libraries/dependencies.pb` in both
directions. It must run with the Dart executable shipped beside the validated
Flutter `3.44.6` binary and rejects any component version that differs from
`app/pubspec.lock`; a Dart independently resolved from `PATH` cannot produce
release evidence.

The current local proof produced a 936-component SBOM. OSV queried all 936
components, classified 226 as excluded, preserved 60 vulnerability occurrences
only in excluded/non-release dependencies, and returned zero release
vulnerabilities. This is local candidate evidence and must be regenerated from
the final clean SHA.

## Local checks with no deployment or external writes

Run the release/DR contract suite:

```bash
MANALOOM_FLUTTER_BIN=/absolute/path/to/flutter-3.44.6/bin/flutter \
  scripts/manaloom_release_ops_contract_test.sh
```

Run the core shell and workflow checks below; the aggregate contract maintains
the complete manifest used by the current release gate:

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

The three stateful operational scripts are dry-run by default:

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

The refreshed local aggregate passed **25/25 contracts**. All 35 shell files in
the validated diff passed both `bash -n` and `shellcheck -S warning -x`. The
integrated client and server suites passed, respectively, **948 tests + 1
intentional skip** and **1,583 tests**, with zero analyzer findings.

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

- pins every third-party Action to a verified commit and pins Flutter `3.44.6`;
- runs the release/DR contract suite;
- builds release APK and AAB probes;
- enforces the Android permission allowlist;
- proves Gradle-lock/AAB parity, scans the full SBOM with OSV, and generates
  in-toto/SLSA provenance for APK, AAB, SBOM, OSV report and permission report;
- uploads the evidence bundle with a 30-day retention period.

The Android dependency graph is also locked and verified by Gradle metadata;
the wrapper distribution has an expected checksum. Docker build inputs and
third-party Actions are pinned to reviewed versions/digests. These controls
reduce drift but do not replace an SBOM, secret scan, or a rebuild from the
final clean commit.

The production backend image runs its compiled AOT binary as UID/GID
`10001:10001` and declares a healthcheck. The public Next.js image runs as
`node` and also declares a healthcheck. These proven controls are distinct from
the P1 container residuals documented at the end of this gate.

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

Every backend, Web, or Android promotion script requires
`MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL` from the invoking
process before it loads `server/.env`. Persisting that value in the environment
file cannot authorize a run. Before the first backend SSH/mutation, the deploy
also executes a PostgreSQL `READ ONLY` transaction and refuses promotion unless
migrations `038`–`040` are present: privacy/post-game sync, Deckbuilder
validation-state triggers, and normalized `cards.is_reserved`. It never applies
the migrations automatically.

Production startup also runs an authentication preflight. `JWT_SECRET` must be
at least 32 characters/bytes, have sufficient character diversity, and not
match a placeholder. The rate-limit/client-IP layer fails closed when trusted
proxy hops and peers are absent or when an untrusted peer supplies forwarding
headers. `/health` remains a liveness probe independent of PostgreSQL;
readiness is the database-dependent signal.

## Environment, transport, and mutation boundaries

Deployment scripts read only an explicit allowlist of environment keys through
the safe-env helpers; they do not `source` or evaluate arbitrary dotenv shell
content. Live approval is captured from the invoking process before any env
file is read, so a persisted env value cannot grant authority.

Remote mutations require the expected SSH target and host-key fingerprint,
with strict host-key checking. HTTPS/TLS verification fails closed; release
paths do not use `curl -k`, `CERT_NONE`, `accept-new`, or equivalent insecure
bypasses. PostgreSQL callers declare either `with_new_server_pg --read-only
psql` or `--write-approved`; the write path requires both exact approval
literals before connecting. QA test-user cleanup is atomic and proves zero
residue, and the commercial gate rejects degraded AI as a successful result.

The validation itself is safe to run locally:

```bash
MANALOOM_ALLOWED_ORIGINS='https://evolution-manaloom-web-public.2ta7qx.easypanel.host' \
  scripts/manaloom_validate_production_origins.py
```

## External proofs still open on this workstation

An Android release probe was rebuilt and inspected locally on 2026-07-17. It
passed package/version/signature/release-mode and permission checks with APK
SHA-256
`f8cc6a5b74c24ccb601e5577053d59439121f60f06f8b52c82fac27c94b395b4`.
The matching AAB has SHA-256
`3f9b55d216646797e757f61d6a8ba963151948e77dd7e79db3936dcb4c5b9fd4`.
Its permissions are limited to network state/internet, camera, notifications,
wake lock, FCM receive, and the app's internal dynamic-receiver permission.
Because it came from the active shared worktree rather than the clean
same-SHA release orchestrator, it is a validation probe, not the publishable
beta artifact.

The final local non-secret precheck found:

- Sentry DSN/auth token are available from Keychain for org `rafa-pz` and
  project `manaloom`, but no event correlated to the final promoted SHA exists;
- no production `MANALOOM_ALLOWED_ORIGINS` configuration in the current local
  environment file; backend deploy is intentionally blocked until it is set;
- no final `MANALOOM_TRUSTED_PROXY_HOPS`/`MANALOOM_TRUSTED_PROXY_PEERS`
  production proof;
- no physical Android device attached;
- a signed release APK passed install and cold launch on Android 36 emulator,
  but the exact promoted artifact has not been exercised on a physical device;
- no FCM foreground/background delivery evidence;
- Play App Signing compatibility with the registered upload key is not yet
  externally proven;
- `age` and Docker are ready, but no age recipient or off-site S3 destination
  is configured;
- a pre-migration dump of 300,692,505 bytes, mode `0600`, passed checksum and a
  PostgreSQL 17 schema restore with 87 tables. Because that dump predates the
  account-password rotation, a fresh backup is still mandatory before live
  migrations;
- the encrypted off-site chain and restore from that chain remain unproven.
- one account credential was present in the predecessor `origin/master`
  snapshot and remains in Git history. It is absent from the candidate
  working tree and its password has been rotated: the old value returned HTTP
  401 and the replacement HTTP 200. The replacement is stored outside the
  repository. Backend deployment must still rotate `JWT_SECRET` and prove that
  a token signed by the former secret is rejected.

Real local container evidence was also collected: the app Web image reached a
healthy state with `/healthz` 200 and security/cache headers validated;
manaloom-ops and XMage built and returned health 200. Forge built all six Maven
modules after applying its official `skipLaunch4j` property. The final Forge
runtime then returned `/health` 200 with the pinned commit and 33,288 indexed
cards; this is local runtime evidence, not production promotion.

The remaining live/physical proofs require deployment, environment or device
evidence. Separate P1 source/runtime hardening remains: the app Nginx
master starts as root; manaloom-ops, XMage, and Forge run as root without a
Dockerfile `HEALTHCHECK`. No deploy, publication, cloud upload, production database operation, or
physical-device write was performed while implementing this gate.
