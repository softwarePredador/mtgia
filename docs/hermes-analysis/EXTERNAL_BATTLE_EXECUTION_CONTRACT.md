# External Battle Execution Contract

Status: `current_operating_standard`.

Operational closure, residual compaction, and resumable mass-battle commands
are defined in
`docs/hermes-analysis/GLOBAL_BATTLE_RULES_AND_LEARNING_CLOSURE_2026-07-15.md`.
The supported entrypoint is `scripts/manaloom_global_battle_closure.sh`; local
Java source candidates require live catalog reconciliation before they count
as executable coverage.

This contract separates global battle execution from ManaLoom's native
`card_battle_rules` adaptation. The product no longer needs to translate every
card into a native family before it can run a battle.

## Engine Order

For `BATTLE_ENGINE=auto`:

1. pinned XMage is the primary rules executor;
2. pinned Forge is tried only when XMage returns a structured coverage gap;
3. `manaloom_native_legacy` is the explicit residual fallback;
4. an operational failure from XMage or Forge returns an error and is never
   reinterpreted as a successful native battle.

`auto` is the default and requires both sidecar URLs. Strict modes are `xmage`,
`forge`, and `native`. Missing required configuration returns `503`; it cannot
silently select an old runner. Only explicit `native` works without a sidecar.

Required environment:

```text
BATTLE_ENGINE=auto
XMAGE_SIDECAR_URL=http://xmage-sidecar:8080
FORGE_SIDECAR_URL=http://forge-sidecar:8080
```

Production deploy is coordinated by
`scripts/manaloom_deploy_battle_sidecars.sh`. It builds both pinned images on
the new server, registers or updates the EasyPanel services, verifies both
internal health endpoints, synchronizes the backend PostgreSQL target from
`server/.env`, and only then enables `auto` on the backend. The backend image
deploy refuses to run when the service spec does not point to the internal
new-server PostgreSQL target. Both deploy paths require the expected image in
the service spec and in the running task, a completed update state, and `1/1`
replicas; an old healthy task cannot satisfy deployment success. Host-port
services use `stop-first` for update and rollback.

The PostgreSQL-writing scheduler is deployed separately with
`scripts/manaloom_deploy_ops_image.sh`. That deploy is SHA-pinned, preserves
the existing `/data/manaloom-ops` volume, refuses an old or external database
target, and verifies inside the running container that rule synchronization
cannot replace a trusted `oracle_hash` with an empty cache value. The
`manaloom-ops` runtime must never remain on an older repository SHA after a
rule-sync contract change.

## Source And Product Boundaries

- Scryfall/MTGJSON/PostgreSQL remain card identity, Oracle, legality, and
  product-data sources.
- XMage is the primary executable rules engine where it resolves the deck.
- Forge is the secondary executable rules engine for XMage coverage gaps.
- PostgreSQL remains the product source of truth for native ManaLoom rules and
  metadata. External execution does not create `card_battle_rules` rows.
- Hermes remains cache/laboratory/audit evidence and cannot overwrite
  PostgreSQL truth. Cache refreshes re-read existing PostgreSQL-backed aliases
  and derive a missing cache hash from the current PostgreSQL Oracle text.
- A completed battle proves the engine ran the two decks. It proves visible
  activity for an individual card only when a typed event names that card or a
  focused scenario exercises it. XMage's watcher cannot expose named hidden
  draws, so hand-count changes are never promoted to named-card evidence.
- Rules execution is not Commander legality, deck quality, strategy, or swap
  proof.

## Strict Sidecar Requirements

Both sidecars expose:

- `GET /health`
- `POST /cards/coverage`
- `POST /coverage`
- `POST /simulate`

Both require exact 100-card Commander decks with one commander. Unsupported
cards return HTTP `422`; timeouts return `504`.

Both accept at most 8 MiB per request. The limit is intentionally above the
current full-corpus coverage payload and below an unbounded bulk-upload
contract.

The public `/ai/simulate` battle route caps `timeout_ms` at 40 seconds and
allows eight seconds for sidecar cleanup and HTTP delivery. This keeps the
worst-case response below the production proxy deadline. Direct sidecar calls
retain their wider timeout range for controlled offline benchmarks.

XMage runs in-process beside its server, so timeout handling has two layers:

- the sidecar indexes its card catalog before opening the HTTP port, so
  `GET /health` with `catalog_ready=true` is a readiness signal rather than a
  process-only liveness signal;
- bulk `/cards/coverage` uses XMage's loaded name index instead of issuing one
  H2 lookup per input row; deck validation and simulation still resolve real
  `CardInfo` objects;
- the battle loop stops at the requested timeout without waiting on synchronous
  table/session cleanup;
- an HTTP watchdog cancels any execution that does not return within a
  five-second cleanup grace, sends `504`, and exits the sidecar so the container
  restarts both XMage processes from a clean state.

Every response exposes `sidecar_process_id` and `sidecar_started_at`. XMage
timeouts also expose `restart_required=true`. A batch runner must observe a
different healthy process ID after a timeout; a health response from the old
process during its one-second shutdown window is not recovery proof.

A timed-out XMage process is therefore never reused for another battle.
The combined XMage server and sidecar container keeps its Java heaps capped at
2.5 GiB and has a 4 GiB service limit, leaving explicit room for native JVM,
SQLite, metaspace, and replay-buffer overhead.

Forge has additional guards because its official CLI can exit `0` after
omitting an unsupported card or failing to load a deck:

- every card is pre-resolved against the pinned Forge script inventory;
- Forge's runtime unsupported-card message is converted to `422`;
- process exit `0` is insufficient without an actual `Game Result`;
- a completed result with internal engine errors is rejected;
- each game runs in an isolated process and is killed after at most five
  seconds of process-startup grace beyond the requested engine budget;
- the Forge process, Java child, and Xvfb descendants share an isolated process
  group that is killed as one unit on timeout;
- the requested seed is installed before Forge starts;
- simulations are serialized.

## Replay And Learning Contract

External results publish `learning_contract.schema_version` as
`external_battle_learning_v1` and keep `decision_trace` explicit. The signals
have these meanings:

| Signal | XMage | Forge | Safe conclusion |
| --- | --- | --- | --- |
| Completed game/winner | yes | yes | canonical engine execution completed |
| Visible stack entry | typed from state | parsed from engine log | named spell/ability became visible |
| Battlefield/zone transition | typed from state | partial | visible state changed; hidden origin/destination may remain unknown |
| Attack/block declaration | typed from combat state | not guaranteed | named visible combat participation only when emitted |
| Tap/damage/counter transition | typed from permanent state | not guaranteed | state changed; the causal choice is not inferred |
| Named card draw from hidden library | no | not trusted | unavailable |
| AI alternatives, scores, rationale | no | no | unavailable |
| Strategy or add/cut superiority | no | no | requires a separate controlled comparison |

`visible_activity_only` is sufficient for card exposure and rules-execution
evidence. It is insufficient for a deck promotion. A swap comparison requires:

1. legal equal-cardinality base and candidate decks;
2. same commander, opponents, engine version, timeout policy, and seed set;
3. typed exposure of the added and removed lane, or a separately labelled
   forced-access diagnostic;
4. enough completed natural games to avoid deciding from timeout selection;
5. strategy/role metrics in addition to win rate;
6. no promotion when the candidate merely avoided drawing or using its changed
   card.

The event stream is a best-effort visible-state lower bound. A typed event is
positive evidence that the named activity occurred. Missing events are not
proof that a card was not drawn or used: hidden information is unavailable and
the asynchronous XMage watcher can coalesce visible transitions. The response
therefore publishes:

- `seed_semantics=engine_random_seed_not_event_replay`;
- `event_stream_completeness=best_effort_visible_state_lower_bound` for XMage
  or `best_effort_engine_log_lower_bound` for Forge;
- `absence_proves_nonuse=false`.

XMage stack abilities are identified from the actual `MageObjectType` or
`StackAbilityView`, not from `CardView.isAbility()` alone. The event keeps the
stack object and also publishes `source_card_id` and `source_card_name` when
XMage exposes them. This prevents activated abilities such as Krenko's from
being counted as spells.

The backend also persists `battle_positive_evidence_v1`. It accepts only typed,
named positive activity under `external_battle_learning_v1`, never infers
non-use from absence, and always keeps `promotion_allowed=false`. Offline mass
batches use `external_battle_async_registry_v1` and atomic
`external_battle_async_checkpoint_v1`; full replay payloads are retained as
compressed `.json.gz` files.

## Measured Catalog Baseline

Live PostgreSQL read-only inventory on 2026-07-14:

| Lane | Cards | Catalog coverage |
| --- | ---: | ---: |
| PostgreSQL `cards` | 34,331 | 100% |
| XMage direct resolution | 31,208 | 90.9033% |
| XMage residual | 3,123 | 9.0967% |
| Forge resolution inside XMage residual | 1,872 | 5.4528% |
| XMage + Forge external execution resolution | 33,080 | 96.3561% |
| Native executable rules inside final external residual | 39 | 0.1136% |
| Current operational union | 33,119 | 96.4697% |
| Explicit residual | 1,212 | 3.5303% |

These are resolution counts, not 34,331 focused card-use tests. The remaining
1,212 cards are the only global family/manual/product-exclusion queue; the
31,208 XMage-resolved cards must not be translated card by card merely to make
the launch battle runtime work.

### Current adaptation-queue pilot

The 2026-07-14 queue rebuild covered 26,890 current target identities in 35.94
seconds. Local XMage source resolved 23,955 identities (89.09%), leaving 2,935
without local source and 11,344 adapter work units after family grouping. The
exact native split considered 6,960 residual rows and produced only three safe
native proposals in 9.07 seconds. This demonstrates that the broad simple
native families are largely exhausted; the remaining native work is long-tail
family/manual work, not 26,890 independent card implementations.

Production XMage `/cards/coverage` processed those 23,955 source-resolved rows
in one 2.49 MiB request under the new 8 MiB limit: 23,823 supported, 132
unsupported, 99.44% coverage, and 3,808 ms wall time. Under the former 2 MiB
cap the same rows required four requests and 4,394 ms aggregate service time.

## Executed Proof

- XMage completed Korvold vs Krenko in 11 turns with 262 events, 158 snapshots,
  and zero engine errors.
- A 20-seed XMage sample completed 9 games within a 30-second cap; completed
  games had 8,919 ms median and 24,368 ms p95. Timeouts remain explicit.
- A fresh three-seed Miirym-versus-Meren pilot at the same 30-second cap
  completed 0/3: two explicit `504` timeouts and one request that reached the
  restart window. This does not invalidate the completed sample, but proves
  that 30-second synchronous runs are not a reliable mass-learning SLA. The
  process-identity gate now prevents the restart-window race.
- XMage rejected deck 607 with exactly three unresolved entries:
  `Improvisation Capstone`, `Molecule Man`, and `Lorehold, the Historian`.
- Forge resolved all 100 cards of deck 607 and completed Commander against
  Korvold. The final sidecar E2E won with deck 607 in 11 turns, emitting 615
  events and 22 snapshots with zero runtime errors in 11,967 ms.
- A separate full Forge log exercised both `Lorehold, the Historian` and
  `Improvisation Capstone`; `Molecule Man` is resolution-proven but still needs
  a focused-use trace before claiming card-level battle proof.
- Production timeout validation returned HTTP `504`, exited the contaminated
  XMage task with code `70`, and recovered with a new healthy task.
- The authenticated production `/ai/simulate` route completed a controlled
  XMage battle in 16 turns and 17,853 ms with 322 events, 192 snapshots, and
  zero engine errors; persisted provenance was
  `canonical_rules_execution`.
- The production Forge sidecar completed Korvold vs Krenko in 8 turns and
  37,226 ms with 404 events, 16 snapshots, 17 cards cast, 4 activations, and
  zero engine errors.
- The only persisted production XMage replay available during the 2026-07-14
  audit had 183 events but no card cast, draw, attack, activation, target, or
  decision event; 179 rows were generic waiting messages. That replay remains
  execution evidence, not strategy-learning evidence. The typed replay
  contract in this revision closes the observability gap for future games; it
  does not retroactively upgrade old rows.
- A fresh production Krenko-versus-Isamaru rules probe completed in 17,554 ms,
  20 turns, and zero engine errors. It emitted 700 events and 225 snapshots,
  including 2 visible spells, 6 Krenko activations, 85 battlefield entries,
  and 65 declared attackers. Every activation carried
  `source_card_name=Krenko, Mob Boss` after the stack-object classification fix.
- Repeating that probe with the same seed and same sidecar process preserved
  winner, turn count, and game cycle but produced 704 events, 244 snapshots,
  and 67 captured attackers. This proves that equal seed controls engine
  randomness but does not make the observer stream a byte-identical replay.
- An A/B using the exact Korvold-versus-Krenko request and seed 10001 timed out
  at 30 seconds on both the pre-telemetry image `d9d6a07b5` and current image.
  The timeout is not a regression caused by enriched replay observation.

## Validation

```bash
python3 -m unittest services/forge-sidecar/test_sidecar.py
cd services/xmage-sidecar && mvn test
cd server && dart test \
  test/xmage_battle_client_test.dart \
  test/forge_battle_client_test.dart \
  test/battle_replay_read_service_test.dart
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_execution_contract_audit.py \
  --output-prefix /tmp/manaloom_external_battle_execution_contract
```

Docker images are reproducible from the commits in
`services/xmage-sidecar/XMAGE_COMMIT` and
`services/forge-sidecar/FORGE_COMMIT`.
