# External Battle Execution Contract

Status: `current_operating_standard`.

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
internal health endpoints, and only then enables `auto` on the backend.

## Source And Product Boundaries

- Scryfall/MTGJSON/PostgreSQL remain card identity, Oracle, legality, and
  product-data sources.
- XMage is the primary executable rules engine where it resolves the deck.
- Forge is the secondary executable rules engine for XMage coverage gaps.
- PostgreSQL remains the product source of truth for native ManaLoom rules and
  metadata. External execution does not create `card_battle_rules` rows.
- Hermes remains cache/laboratory/audit evidence and cannot overwrite
  PostgreSQL truth.
- A completed battle proves the engine ran the two decks. It proves an
  individual card only when the event log shows that card drawn/used or a
  focused scenario exercises it.
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

Forge has additional guards because its official CLI can exit `0` after
omitting an unsupported card or failing to load a deck:

- every card is pre-resolved against the pinned Forge script inventory;
- Forge's runtime unsupported-card message is converted to `422`;
- process exit `0` is insufficient without an actual `Game Result`;
- a completed result with internal engine errors is rejected;
- each game runs in an isolated process and is killed on outer timeout;
- the requested seed is installed before Forge starts;
- simulations are serialized.

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

## Executed Proof

- XMage completed Korvold vs Krenko in 11 turns with 262 events, 158 snapshots,
  and zero engine errors.
- A 20-seed XMage sample completed 9 games within a 30-second cap; completed
  games had 8,919 ms median and 24,368 ms p95. Timeouts remain explicit.
- XMage rejected deck 607 with exactly three unresolved entries:
  `Improvisation Capstone`, `Molecule Man`, and `Lorehold, the Historian`.
- Forge resolved all 100 cards of deck 607 and completed Commander against
  Korvold. The final sidecar E2E won with deck 607 in 11 turns, emitting 615
  events and 22 snapshots with zero runtime errors in 11,967 ms.
- A separate full Forge log exercised both `Lorehold, the Historian` and
  `Improvisation Capstone`; `Molecule Man` is resolution-proven but still needs
  a focused-use trace before claiming card-level battle proof.

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
