# ManaLoom Forge Sidecar

Secondary rules executor for cards that the pinned XMage runtime cannot resolve.
It wraps Forge's official headless Commander simulator at the commit recorded in
`FORGE_COMMIT`.

The service is strict:

- both decks must contain exactly 100 cards and exactly one commander;
- every card must have a Forge script before the process starts;
- Forge's own `unsupported card` output becomes HTTP `422`;
- process exit `0` is insufficient: a real `Game Result` line is required;
- each game runs in an isolated Java process and is killed on outer timeout;
- a small bootstrap applies the requested deterministic seed before Forge starts;
- Linux runs the desktop CLI under `xvfb`; `java.awt.headless=true` is unsupported;
- simulations are serialized because Forge uses global profile/runtime state.
- the container caps the Forge JVM at 2 GiB by default through
  `FORGE_JAVA_COMMAND`.

Endpoints:

- `GET /health`
- `POST /cards/coverage`
- `POST /coverage`
- `POST /simulate`

Request bodies are capped at 8 MiB so the current global card corpus can be
checked in one bounded call. Every response exposes `sidecar_process_id` and
`sidecar_started_at`.

Forge logs expose visible casts and activations but do not provide AI rationale
or a trustworthy named-draw trace. Results therefore publish
`external_battle_learning_v1`, an empty `decision_trace`, and
`strategy_or_swap_proof=false`.

Local unit tests:

```bash
python3 -m unittest services/forge-sidecar/test_sidecar.py
```

Build from the repository root:

```bash
docker build -f services/forge-sidecar/Dockerfile -t manaloom-forge-sidecar .
```

Forge is a secondary canonical rules executor. Deck quality, Commander
legality, and strategic card value remain separate contracts.
