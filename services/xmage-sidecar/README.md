# ManaLoom XMage Sidecar

Executes Commander battles with the official XMage runtime pinned by
[`XMAGE_COMMIT`](XMAGE_COMMIT). The service is strict: unresolved cards are
reported and are never removed from a deck.

## HTTP contract

- `GET /health`: engine version and pinned commit.
- `POST /coverage`: validates two 100-card, one-commander decks and returns
  `ready` plus structured `unsupported_cards`.
- `POST /cards/coverage`: batch-checks arbitrary catalog rows without requiring
  decks; this is the queue gate for the global card corpus.
- `POST /simulate`: runs a covered battle. Coverage failures return HTTP 422;
  execution timeouts return HTTP 504.

The request contains `request_id`, `seed`, `timeout_ms`, `deck_a`, and `deck_b`.
Each deck contains `id`, `name`, and card rows with `name`, `set_code`,
`collector_number`, `quantity`, and `is_commander`.

The result includes engine provenance, seed, winner, turns, normalized events,
visual snapshots, final state, and compact metrics. XMage rules execution does
not by itself prove deck legality or deck-building quality.

## Build and test

Java 17 and Maven are required. XMage artifacts for the pinned commit must be
installed in the local Maven repository before a host build.

```bash
mvn test -B
mvn package -DskipTests -B
```

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
reinterpreted as successful native battles.

## Benchmark gate

Run a reproducible batch from a valid request fixture:

```bash
bin/benchmark.sh request.json benchmark.tsv 20 30000
```

The TSV keeps every seed, status, duration, winner, event count, snapshot
count, and XMage error count. Timeouts remain visible as failed rows.
