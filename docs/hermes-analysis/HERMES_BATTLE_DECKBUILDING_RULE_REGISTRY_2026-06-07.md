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
| Battle/deck rule | SQLite `battle_card_rules` | What Hermes believes the card does in simulation and deckbuilding | Reviewable source |
| Battle engine | `battle_analyst_v8.py` | Executes supported effects and phases | Deterministic simulator |
| Deck optimizer | `slot_optimizer.py` and gates | Chooses candidates/cuts using rule categories | Evidence consumer |
| Audits | `battle_effect_coverage_audit.py`, replay auditor | Shows unknowns, heuristics and mismatches | Trust gate |

## Table: `battle_card_rules`

One row per card name.

| Column | Meaning |
| --- | --- |
| `normalized_name` | Lowercase canonical lookup key. |
| `card_name` | Display/original card name. |
| `effect_json` | Battle behavior, for example `{"effect":"counter","instant":true}`. |
| `deck_role_json` | Deckbuilding role, for example `{"category":"protection","effect":"counter"}`. |
| `source` | `manual`, `curated`, `generated` or `heuristic`. |
| `confidence` | Numeric confidence from 0 to 1. |
| `review_status` | `verified`, `needs_review` or `active`. |
| `rule_version` | Future migration/version control for semantics. |
| `oracle_hash` | Future guard against stale oracle interpretations. |
| `notes` | Human reason/limitation. |
| `created_at` / `updated_at` / `last_seen_at` | Operational audit fields. |

## Resolution priority

Battle effect lookup now follows this order:

1. `battle_card_rules` row, if present.
2. Handwritten `KNOWN_CARDS`.
3. `known_cards_generated.json`.
4. Functional tag (`TAG_EFFECTS`).
5. Imported effect map.
6. Type fallbacks such as `land` or `creature`.
7. `unknown`.

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

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --apply \
  --report /opt/data/artifacts/hermes_master_optimizer/battle_card_rules_sync.json
```

Manual rules are seeded as `verified`.
Generated rules are seeded as `needs_review`.
Generated rows never overwrite higher-priority manual rows.

## Release rule

Do not claim the battle is "complete for all cards" until:

- the coverage audit has no relevant `unknown_effect`;
- oracle mismatches are zero or manually waived;
- candidates selected by optimizer are backed by `manual` or `curated` rules;
- replay audit remains clean after any new rule category is introduced.

Until then, Hermes is an evidence-based simulator, not a full MTG rules engine.
