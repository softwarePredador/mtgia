# ManaLoom XMage Sidecar

Executes Commander battles with the official XMage runtime pinned by
[`XMAGE_COMMIT`](XMAGE_COMMIT). The service is strict: unresolved cards are
reported and are never removed from a deck.

## HTTP contract

- `GET /health`: engine version, pinned commit, `catalog_ready=true`, indexed
  name count, `sidecar_process_id`, and `sidecar_started_at` after the card
  catalog has been loaded.
- `POST /coverage`: validates two 100-card, one-commander decks and returns
  `ready` plus structured `unsupported_cards`.
- `POST /cards/coverage`: batch-checks arbitrary catalog rows without requiring
  decks; this is the queue gate for the global card corpus. It uses XMage's
  in-memory name index; deck validation and simulation still resolve concrete
  `CardInfo` objects. Full multi-face names use exact repository resolution as
  a compatibility fallback because XMage's name index stores individual faces.
- `POST /simulate`: runs a covered battle. Coverage failures return HTTP 422;
  execution timeouts return HTTP 504.

Simulation timeout is a hard process boundary. The HTTP watchdog allows a
five-second cleanup grace, returns `504`, and exits the sidecar so the container
restarts both XMage processes. A timed-out engine state is never reused.
The timeout body identifies the contaminated process and sets
`restart_required=true`. Batch runners must wait until `/health` exposes a
different process ID before sending another game.

Request bodies are capped at 8 MiB. This supports one full current card-corpus
coverage request while retaining a bounded memory contract.

The request contains `request_id`, `seed`, `timeout_ms`, `deck_a`, and `deck_b`.
Each deck contains `id`, `name`, and card rows with `name`, `set_code`,
`collector_number`, `quantity`, and `is_commander`.

The result includes engine provenance, seed, winner, turns, normalized events,
visual snapshots, final state, and compact metrics. XMage rules execution does
not by itself prove deck legality or deck-building quality.

XMage watcher replays expose visible stack entries, battlefield entries, zone
changes, tap/damage/counter changes, and combat declarations. Hidden hand and
library identities are not visible, and XMage does not expose the AI's rejected
options or rationale. The response therefore carries
`learning_contract.schema_version=external_battle_learning_v1`, an empty
`decision_trace`, and `strategy_or_swap_proof=false`.

## Build and test

Java 17 and Maven are required. XMage artifacts for the pinned commit must be
installed in the local Maven repository before a host build. They are not
published to Maven Central; use the pinned bootstrap instead of relying on a
developer cache.

```bash
services/xmage-sidecar/bin/bootstrap_pinned_xmage_maven.sh
cd services/xmage-sidecar
mvn test -B
mvn package -DskipTests -B
```

CI runs the same bootstrap before the canonical battle gate. Set
`MAVEN_REPO_LOCAL` to an absolute path to prove a clean repository or to
isolate the cache; the canonical gate honors the same variable:

```bash
export MAVEN_REPO_LOCAL=/tmp/manaloom-xmage-m2
services/xmage-sidecar/bin/bootstrap_pinned_xmage_maven.sh
./scripts/manaloom_battle_product_gate.sh
```

The bootstrap records a fingerprint containing `XMAGE_COMMIT`, the XMage
version, and the patched SQLite JDBC version. Cached jars without the matching
fingerprint are rebuilt. CI also includes `XMAGE_COMMIT` in its Maven cache key.

The Docker image clones and verifies the pinned XMage commit, upgrades only the
SQLite JDBC runtime for arm64 compatibility, builds the XMage server, and runs
the server and sidecar in one isolated container.

Heap limits are configurable with `XMAGE_SERVER_JAVA_OPTS` and
`XMAGE_SIDECAR_JAVA_OPTS`; defaults are 2 GiB and 512 MiB respectively.

```bash
docker build -f services/xmage-sidecar/Dockerfile -t manaloom-xmage-sidecar .
docker run --rm -p 8080:8080 manaloom-xmage-sidecar
```

## Backend modes

Configure the ManaLoom server with `XMAGE_SIDECAR_URL` and `BATTLE_ENGINE`:

- `auto`: XMage first, Forge for structured XMage coverage gaps, then explicit
  native residual fallback.
- `xmage`: strict mode; coverage gaps remain HTTP 422.
- `forge`: strict secondary-engine mode; coverage gaps remain HTTP 422.
- `native`: legacy advisory simulator.

Sidecar operational failures return HTTP 502 from ManaLoom and are not
reinterpreted as successful native battles. Explicit engine timeouts remain
HTTP 504. The public route caps the requested engine budget at 40 seconds so
the timeout response can cross the production proxy before its 60-second
deadline; direct sidecar benchmarks retain the wider internal timeout range.

## Benchmark gate

Run a reproducible batch from a valid request fixture:

```bash
bin/benchmark.sh request.json benchmark.tsv 20 30000
```

The TSV keeps every seed, status, duration, winner, event count, snapshot
count, and XMage error count. Timeouts remain visible as failed rows, and the
runner waits for a distinct replacement process before continuing.
