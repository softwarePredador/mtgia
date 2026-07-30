# ManaLoom XMage Sidecar

Executes Commander battles with the official XMage baseline pinned by
[`XMAGE_COMMIT`](XMAGE_COMMIT), plus the exact governed runtime patch pinned by
[`XMAGE_PATCH_COMMIT`](XMAGE_PATCH_COMMIT). The service is strict: unresolved
cards are reported and are never removed from a deck. Cards with a confirmed
defect in the pinned engine are also rejected by a pin-scoped qualification
policy.

## HTTP contract

- `GET /health`: engine version, pinned commit, `catalog_ready=true`, indexed
  name count, bounded Live buffer metrics, `sidecar_process_id`, and
  `sidecar_started_at` after the card catalog has been loaded, plus the card
  qualification policy commit, the 169-card transition inventory, and its
  restriction counts.
- `POST /coverage`: validates two 100-card, one-commander decks and returns
  `ready` plus structured `unsupported_cards`.
- `POST /cards/coverage`: batch-checks arbitrary catalog rows without requiring
  decks; this is the queue gate for the global card corpus. It uses XMage's
  in-memory name index; deck validation and simulation still resolve concrete
  `CardInfo` objects. Full multi-face names use exact repository resolution as
  a compatibility fallback because XMage's name index stores individual faces.
- `POST /simulate`: runs a covered battle. Coverage failures return HTTP 422;
  execution timeouts return HTTP 504.
- `GET /live/<request_id>`: internal, read-only polling source for a simulation
  already running in this process. It returns a bounded
  `external_battle_live_source_v1` record stream; it is not an action or pause
  endpoint. `after=<sequence>&limit=<1..500>` provides monotonic source
  pagination (default 200) so polling never downloads the full buffer.

Simulation timeout is a hard process boundary. The HTTP watchdog allows a
five-second cleanup grace, returns `504`, and exits the sidecar so the container
restarts both XMage processes. A timed-out engine state is never reused.
The timeout body identifies the contaminated process and sets
`restart_required=true`. Batch runners must wait until `/health` exposes a
different process ID before sending another game.

Request bodies are capped at 8 MiB. This supports one full current card-corpus
coverage request while retaining a bounded memory contract.

### Pin-scoped card qualification

`XmageCardQualificationPolicy` is tied to the exact `XMAGE_COMMIT`. A pin
change without reviewing the policy fails closed. The versioned activation
resource is also bound to the prior pin, the current pin, and the SHA-256
digests of the read-only PostgreSQL reconciliation. At the current pin:

- `Planetarium of Wan Shi Tong` is quarantined with
  `reason_code=xmage_pin_semantic_defect` because a mandatory trigger action is
  incorrectly optional;
- `Prudent Fateseer` is quarantined with
  `reason_code=xmage_upstream_mechanic_unfinished` because Prepare is
  unfinished and upstream removes the card from its catalog;
- `Mandate of Peace` is quarantined with
  `reason_code=xmage_upstream_copy_lki_gap` while copied-spell
  last-known-information handling remains an open upstream gap;
- 133 transition cards not exposed by current PostgreSQL product truth remain
  activation-blocked until a new identity, legality, and semantic review is
  versioned. This includes 45 future cards and 88 released names absent from
  the product catalog.

The complete transition probe therefore resolves 34 product-in-scope cards
and rejects 135 rows fail-closed: the 133 activation restrictions plus the
Planetarium and Mandate quarantines. Catalog presence or absence is never
treated as gameplay proof.

Coverage responses preserve the submitted card row and add
`support_status=quarantined`, the reason, upstream reference, qualification
commit, and release condition. In `auto` mode this is a structured XMage
coverage gap, so the reviewed Forge/native order may still handle the complete
deck; strict `xmage` mode remains blocked.

Application surfaces must translate this internal provenance into
engine-neutral Battle language; external engine names and technical reason
tokens are not player-facing copy.

The pin-scoped product review tests are stored as two full-index patches and
can be reproduced without modifying this repository's runtime sources:

```bash
services/xmage-sidecar/bin/verify_product_scope_semantic_tests.sh
```

The verifier checks both patch digests, the versioned evidence digest, the
exact pin, and the two-file test-only scope before running all 37 focused
scenarios. It refuses a changed pin or any non-test source mutation.

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

The Live source retains at most 20,000 records per request, 64 recent streams,
and 15 minutes of process-local history. It removes hand/library contents,
decision options, prompts, rationale and credentials before buffering. The
authenticated ManaLoom backend applies a second public allowlist, persists the
incremental cursor records, and owns reconnection. A sidecar restart therefore
converges to the durable replay instead of claiming that this buffer survived.

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

The free local release gate runs the same bootstrap before the canonical Battle
gate. Set
`MAVEN_REPO_LOCAL` to an absolute path to prove a clean repository or to
isolate the cache; the canonical gate honors the same variable:

```bash
export MAVEN_REPO_LOCAL=/tmp/manaloom-xmage-m2
services/xmage-sidecar/bin/bootstrap_pinned_xmage_maven.sh
./scripts/manaloom_battle_product_gate.sh
```

The bootstrap records a fingerprint containing `XMAGE_COMMIT`, the XMage
version, and the patched SQLite JDBC version. Cached jars without the matching
fingerprint are rebuilt. The local gate validates `XMAGE_COMMIT` before reusing
the Maven cache.

### Governed Lorehold runtime patch

Lorehold is not present in the canonical upstream pin. The minimal patch
contains the public dynamic-Miracle and Lorehold changes from XMage PR 15591
plus three direct tests; it deliberately excludes the unrelated cards in that
PR. Its exact resulting tree is published as commit
`95f0ff69968159025998dcbecb59be5f3c1b67e2` in the governed
`softwarePredador/mage` fork, with the canonical pin as its direct parent.

Run the isolated verifier with Java 17:

```bash
services/xmage-sidecar/bin/verify_lorehold_candidate_patch.sh
```

The verifier fetches the official canonical pin into a temporary checkout,
checks the patch digest, applies it and runs `MiracleTest`. The separate
governance auditor binds the published commit, parent, tree, complete 14-path
diff, six focused tests and read-only PostgreSQL product scope:

```bash
python3 \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_governed_patch_audit.py \
  --require-deployable
```

The image build independently reapplies the versioned patch, verifies the
resulting Git tree, fetches the governed commit and rejects any parent or tree
divergence. Runtime health and replays expose `engine_patch_commit`; player
copy remains engine-neutral.

The Docker image clones and verifies the pinned XMage commit, upgrades only the
SQLite JDBC runtime for arm64 compatibility, builds the XMage server, and runs
the server and sidecar in one isolated container.

Heap limits are configurable with `XMAGE_SERVER_JAVA_OPTS` and
`XMAGE_SIDECAR_JAVA_OPTS`; defaults are 2 GiB and 512 MiB respectively.

```bash
docker build -f services/xmage-sidecar/Dockerfile -t manaloom-xmage-sidecar .
docker run --rm -p 8080:8080 manaloom-xmage-sidecar
```

## Human-vs-AI spike (GO for default-off BL8 engineering)

The BL7 human seat experiment remains test-only and is not reachable through
the sidecar HTTP contract. Its pinned-bytecode harness now validates typed
responses for `GAME_CHOOSE_ABILITY`, `GAME_CHOOSE_PILE`,
`GAME_CHOOSE_CHOICE`, `GAME_PLAY_MANA`, `GAME_PLAY_XMANA`,
`GAME_GET_AMOUNT`, and `GAME_GET_MULTI_AMOUNT`. The `GAME_PLAY_MANA` adapter
accepts only server-provided playable object IDs from `GameView`, mana types
that are present in the private player's pool, the explicitly advertised
special action, or cancellation. XMage still performs the final mana-ability
validation.

Prompt and option tokens are HMAC-bound to the callback game ID and message
version, remain opaque, and can be resolved and dispatched only once.

Timeout does not attempt an unavailable HUMAN-to-AI takeover. It tries
`CONCEDE` and terminates the isolated process even when concede is rejected or
throws. Three loopback runtime matches completed with 251/251 accepted
responses, zero deadlock and zero identifiable opponent-hand objects. A
separate forced-timeout run received a concede acknowledgement and
`GAME_OVER`. ADR 0004 therefore grants GO only to implement BL8 locally behind
a default-off gate; it is not release or rollout authority.

Run the bytecode audit/focused tests, then the loopback runtime gate with:

```bash
services/xmage-sidecar/bin/human_vs_ai_spike.sh
XMAGE_SERVER_PORT=17171 \
  services/xmage-sidecar/bin/human_vs_ai_runtime_spike.sh
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
