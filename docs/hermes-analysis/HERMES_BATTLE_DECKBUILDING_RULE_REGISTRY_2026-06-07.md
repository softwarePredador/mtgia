# Hermes Battle + Deckbuilding Rule Registry

> Status: canonical design for card semantics in battle and optimizer.
> Goal: stop encoding trusted card behavior directly in one Python dict.

## Why this exists

The battle simulator and deck optimizer need the same card understanding.
Before this registry, the system mixed:

- manual `KNOWN_CARDS`;
- generated `known_cards_generated.json`;
- deck functional tags;
- oracle-text heuristics;
- hardcoded optimizer category maps.

That makes results hard to trust because battle and deckbuilding can disagree
about the same card.

## Correct model

Hermes should separate raw facts from interpreted behavior:

| Layer | Source | Purpose | Trust |
| --- | --- | --- | --- |
| Raw card facts | Postgres `cards` -> SQLite `card_oracle_cache` | Mana cost, type line, oracle text, power/toughness, keywords | Fact source |
| Battle/deck rule | Postgres `card_battle_rules` -> SQLite `battle_card_rules` | What Hermes believes the card does in simulation and deckbuilding | Reviewable source |
| Battle engine | `battle_analyst_v9.py` | Executes supported effects and phases | Deterministic simulator |
| Deck optimizer | `slot_optimizer.py` and gates | Chooses candidates/cuts using rule categories | Evidence consumer |
| Audits | `battle_effect_coverage_audit.py`, replay auditor | Shows unknowns, heuristics and mismatches | Trust gate |

## Tables: `card_battle_rules` and `battle_card_rules`

`card_battle_rules` is the PostgreSQL target source of truth. It stores the
reviewed card semantics that should be shared by Hermes, backend services and
admin/review tooling.

`battle_card_rules` is the SQLite runtime cache. Hermes battle jobs read it for
speed, determinism and isolation from production latency. Crons must refresh it
from Postgres before running battles or optimizer scans.

Important drift note:

- PostgreSQL can hold multiple logical rules per card while the migration from
  code overrides to canonical rows is still in progress.
- SQLite `battle_card_rules` is the normalized runtime cache that Hermes reads
  during battles.
- Any remaining handwritten override in `battle_analyst_v9.py` must be treated
  as temporary technical debt unless it is an engine primitive.

| Column | Meaning |
| --- | --- |
| `normalized_name` | Lowercase canonical lookup key. |
| `card_name` | Display/original card name. |
| `effect_json` | Battle behavior, for example `{"effect":"counter","instant":true}`. |
| `deck_role_json` | Deckbuilding role, for example `{"category":"protection","effect":"counter"}`. |
| `source` | `manual`, `curated`, `generated`, `imported` or `heuristic`. |
| `confidence` | Numeric confidence from 0 to 1. |
| `review_status` | `verified`, `needs_review`, `active`, `rejected` or `deprecated`. |
| `rule_version` | Future migration/version control for semantics. |
| `oracle_hash` | Future guard against stale oracle interpretations. |
| `notes` | Human reason/limitation. |
| `created_at` / `updated_at` / `last_seen_at` | Operational audit fields. |

## Resolution priority

Battle effect lookup in the current runtime follows this order:

1. Handwritten `KNOWN_CARDS`.
2. `battle_card_rules` / registry row, if present.
3. `known_cards_generated.json`.
4. Functional tag (`TAG_EFFECTS`).
5. Imported effect map.
6. Type fallbacks such as `land` or `creature`.
7. `unknown`.

Target architecture:

1. `battle_card_rules` / PostgreSQL-reviewed semantics.
2. Handwritten overrides only for engine primitives and documented temporary
   hotfixes.
3. Generated and heuristic fallbacks.

Oracle normalization still runs after lookup to prevent dangerous mistakes like:

- target removal being treated as silence;
- counterspells being treated as draw;
- lands being treated as free removal instead of lands.

## Deckbuilding behavior

`slot_optimizer.py` now merges `battle_card_rules` over `known_cards_generated.json`.
If a row has `deck_role_json.category`, that category is used before the legacy
effect/category map.

Important policy:

- plain `creature` is `unknown` for deckbuilding until a real role is assigned;
- lands are primarily lands;
- utility land abilities are audit gaps, not free spell effects;
- generated rules are usable but remain `needs_review`.

## Sync command

Canonical PG seed/update:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --apply-pg \
  --report /opt/data/artifacts/hermes_master_optimizer/card_battle_rules_pg_sync.json
```

Runtime SQLite refresh:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --apply-sqlite-from-pg \
  --include-needs-review \
  --report /opt/data/artifacts/hermes_master_optimizer/battle_card_rules_cache_sync.json
```

Manual rules are seeded as `verified`.
Generated rules are seeded as `needs_review`.
Generated rows never overwrite higher-priority manual rows.

`--include-needs-review` preserves broad current battle coverage while the rule
set is being audited. For strict release validation, omit it and require
optimizer-impacting cards to be `verified` or `active`.

## External data policy

Do not scrape random web pages directly into executable battle semantics.
Use controlled sources first:

- Postgres `cards` for mana, type line, oracle text, power/toughness and keywords.
- Postgres `card_rulings` for official/curated ruling evidence.
- Postgres `card_function_tags`, `card_role_scores` and `card_semantic_tags_v2`
  for deckbuilding interpretation.
- Postgres `card_combos` and `edhrec_card_snapshots` for synergy evidence.

If a website, model or heuristic suggests behavior, insert it as
`review_status='needs_review'` until replay tests or human review verify it.

## Release rule

Do not claim the battle is "complete for all cards" until:

- the coverage audit has no relevant `unknown_effect`;
- `battle_forensic_audit.py` has no `critical`/`high` finding on fresh fixed-seed
  replays for the target deck;
- oracle mismatches are zero or manually waived;
- candidates selected by optimizer are backed by `manual` or `curated` rules;
- replay audit remains clean after any new rule category is introduced.

Until then, Hermes is an evidence-based simulator, not a full MTG rules engine.

## Forensic replay command

If local `knowledge.db` does not have the target deck, seed it from Postgres:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_target_deck_to_hermes.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --deck-name-like "%Runtime Lorehold Learned%" \
  --target-deck-id 6 \
  --apply
```

Use this when validating whether the flow is coherent turn by turn:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --seed 42 \
  --generate 1 \
  --report
```

The report shows:

- which rule source each card event used;
- whether any event depended on `needs_review`, heuristic or unknown semantics;
- timing/state violations such as bad miracle timing, cleanup failures or turns
  after a win;
- the exact card/turn/phase to fix before trusting optimizer output.

## Fresh forensic proof, 2026-06-07

Validated locally after syncing PG `card_battle_rules` into SQLite:

```powershell
$env:MANALOOM_KNOWLEDGE_DB=(Resolve-Path "docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db").Path
$env:MANALOOM_KNOWLEDGE_DIR=(Resolve-Path "docs/hermes-analysis/manaloom-knowledge").Path
python docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py --generate 5 --seed 100 --report --json-report docs/hermes-analysis/master_optimizer_reports/battle_forensic_audit_local_20260607_seeds100_104_zero.json
python docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py --generate 5 --seed 200 --report --json-report docs/hermes-analysis/master_optimizer_reports/battle_forensic_audit_local_20260607_seeds200_204_zero.json
```

Result:

- seed `42`: zero findings;
- seeds `100-104`: zero findings;
- seeds `200-204`: zero findings;
- `python docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`: all checks passed.

Operational note added in the 2026-06-16 canonicalization slice:

- `battle_analyst_v9.py` now resolves `MANALOOM_KNOWLEDGE_DB` /
  `MANALOOM_KNOWLEDGE_DIR` first, then `/opt/data/workspace/...` when present,
  and finally falls back to the local repo `scripts/knowledge.db`.
- This removed a false negative where local Mac runs would miss the SQLite rule
  cache and incorrectly conclude that PG-promoted rules still depended on
  handcrafted overrides.
- The runtime lookup order is now waiver manual-first -> SQLite/PG
  `card_battle_rules` -> handcrafted fallback -> generated fallback. The waiver
  set is explicit and empty by default.
- After the final active-runtime cleanup on 2026-06-16, the handcrafted
  inventory used by the running engine dropped to `0`. Canonized card-specific
  rules now resolve only through PostgreSQL/SQLite unless an explicit temporary
  waiver is injected into `HANDCRAFTED_KNOWN_CARDS`.

Do not interpret this as a full MTG rules-engine proof. It proves that the
current Lorehold forensic replay batches no longer depend on unknown,
heuristic, `needs_review` or unsupported battle semantics.
