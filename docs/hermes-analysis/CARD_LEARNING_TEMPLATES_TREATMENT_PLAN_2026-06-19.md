# ManaLoom Card Learning Templates Treatment Plan - 2026-06-19

Generated from read-only repo, PostgreSQL, focused tests, focused-template
audit, Scryfall API docs, Scryfall bulk metadata, and Wizards rules sources.

## Executive Summary

The current system is functional for card understanding, but it is not yet at a
"100% precision" operating bar for every card and every battle interaction.
The strongest part is the data model: `card_intelligence_snapshot` already gives
one row per card and aggregates functional tags, semantic v2 tags, role scores,
commander synergy, legalities, rulings, and battle rules without row fanout.

The main risk is not absence of learning data. The base currently has:

| Area | Current read-only value |
| --- | ---: |
| `cards` | 34,329 |
| `cards.oracle_id` filled | 34,325 |
| `cards.oracle_text` filled | 33,969 |
| `cards.keywords` filled | 16,589 |
| `cards.layout` null | 33,829 |
| `cards.card_faces_json` filled | 12 |
| `card_function_tags` rows | 112,563 |
| Cards with function tags | 25,363 |
| `card_semantic_tags_v2` rows | 24,181 |
| Cards with semantic v2 | 24,181 |
| `card_battle_rules` rows | 5,188 |
| Cards with any battle rule | 3,152 |
| Cards with verified battle rules | 1,686 |
| Cards with no function, semantic v2, or battle rule | 8,748 |
| `card_intelligence_snapshot` rows | 34,329 |
| `card_identity_bridge` rows | 305,905 |
| `optimize_candidate_quality_summary` rows | 34,329 |
| `commander_learning_snapshot` rows | 106 |

The key conclusion: the backend is structurally ready, but the learning layer
needs a stricter treatment pipeline so every card receives an explicit status:
`fully_understood`, `deckbuilding_understood`, `battle_template_verified`,
`rules_text_only`, `vanilla_or_low_impact`, `blocked_missing_source`, or
`manual_review_required`.

## Sources Checked

- Local backend source:
  - `server/lib/ai/candidate_quality_data_support.dart`
  - `server/lib/ai/functional_card_tags.dart`
  - `server/lib/ai/optimization_functional_roles.dart`
  - `server/lib/ai/optimization_quality_gate.dart`
  - `server/routes/decks/[id]/analysis/index.dart`
  - `server/lib/ai/optimize_request_support.dart`
  - `server/bin/semantic_layer_v2_backfill.dart`
  - `server/bin/manaloom_battle_rule_review_queue.py`
  - `server/bin/manaloom_battle_rule_focused_evidence.py`
- Existing validation docs:
  - `docs/hermes-analysis/DATA_MODEL_FINAL_VALIDATION_2026-06-15.md`
  - `docs/hermes-analysis/IMPLEMENTATION_GAPS.md`
  - `docs/hermes-analysis/PROJECT_LOGIC_FULL_REPORT_2026-06-11.md`
- Live PostgreSQL through the workspace `DATABASE_URL`, read-only queries only.
- Current Scryfall bulk metadata from `https://api.scryfall.com/bulk-data`:
  - `oracle_cards`: updated `2026-06-19T21:03:03.392Z`
  - `default_cards`: updated `2026-06-19T21:09:42.061Z`
  - `all_cards`: updated `2026-06-19T21:26:44.533Z`
  - `rulings`: updated `2026-06-19T21:00:35.682Z`
- External references:
  - Scryfall Card Objects: https://scryfall.com/docs/api/cards
  - Scryfall Bulk Data: https://scryfall.com/docs/api/bulk-data
  - Scryfall Layouts and Faces: https://scryfall.com/docs/api/layouts
  - Wizards Rules page: https://magic.wizards.com/en/rules
  - Wizards Commander format page: https://magic.wizards.com/en/formats/commander

## What Works Today

1. `card_intelligence_snapshot` exists and has exactly one row per card:
   `34,329` rows and `34,329` distinct cards.
2. `card_identity_bridge` exists and provides canonical/localized identity
   resolution across `305,905` rows.
3. `functional_card_tags.dart` encodes a deterministic role taxonomy and the
   analysis priority is explicit:
   `functional_tags_then_semantic_v2_then_heuristic`.
4. `optimization_functional_roles.dart` is now the shared adapter for role
   resolution. It prioritizes:
   1. persisted `card_function_tags`;
   2. persisted `card_semantic_tags_v2`;
   3. local heuristic inference from `oracle_text`, `type_line`, name,
      `mana_cost`, and `cmc`.
5. The optimize quality gate explicitly protects persisted functional tags so a
   weak or drifting semantic v2 row cannot mask a critical role.
6. `GET /decks/:id/analysis` and optimize context loaders prefer
   `card_intelligence_snapshot`, with per-card aggregate fallback only when the
   view is absent.
7. Focused tests passed:
   `dart test test/functional_card_tags_test.dart test/optimization_quality_gate_test.dart test/optimize_functional_role_support_test.dart test/candidate_quality_data_support_test.dart test/data_model_migration_test.dart`
   returned `51` passing tests.
8. Focused battle-template dispatch audit passed:
   - focused template cards: `29`
   - template predicate match: `29`
   - evidence dispatch ready: `29`
   - focused evidence ready: `29`
   - supports templates: `47`
   - missing dispatch: `0`
   - unwaived not-ready items: `0`

## What Is Not Yet 100%

1. `layout` and `card_faces_json` are incomplete.
   - `layout` is null for `33,829` cards.
   - `card_faces_json` is populated for only `12` cards.
   - Multi-face, split, adventure, modal DFC, meld, battle, and alternate-face
     cards cannot be fully understood if the system only has flattened
     `oracle_text`.
2. There are still `8,748` cards without function tags, semantic v2 tags, or
   battle rules in `card_intelligence_snapshot`.
   - Some are harmless vanilla creatures or low-impact cards.
   - They still need an explicit status, not an implicit blank.
3. Battle rules include mixed maturity:
   - `curated/verified/auto`: `1,725` rows
   - `curated/active/auto`: `26` rows
   - `generated/needs_review/auto`: `1,970` rows
   - `generated/needs_review/review_only`: `1,467` rows
   Generated `needs_review` rows must never become trusted execution behavior
   without official source review, focused replay, and promotion gate.
4. Direct joins to multi-row intelligence tables are unsafe.
   - `cards -> card_function_tags` gives `121,529` rows for `34,329` cards.
   - `cards -> card_battle_rules` gives `36,362` rows for `34,329` cards.
   - Consumers must use `card_intelligence_snapshot` or aggregate by `card_id`
     first.
5. Card roles are not the same as executable battle behavior.
   - `draw`, `ramp`, `removal`, `engine`, `payoff`, and `wincon` are
     deckbuilding meaning.
   - `effect_json` in `card_battle_rules` is simulator behavior.
   - A card can be deckbuilding-understood without being battle-executable.
6. `card_function_tags` has useful tags, but some taxonomy names still need
   stricter normalization at the consumer boundary.
   - Example: `board_wipe` is canonical in functional tags, while the gate maps
     it to legacy `wipe` internally.
   - The legacy label can remain as compatibility, but new artifacts should use
     canonical names and expose any mapping explicitly.

## Precision Definition

For ManaLoom, "100% precision" should not mean pretending every Magic card can
be simulated perfectly from keywords. It should mean:

1. Every card has authoritative identity and source lineage.
2. Every card has an explicit understanding status.
3. Deckbuilding roles are multi-tag, confidence-scored, and source-backed.
4. Battle execution only uses verified, tested templates.
5. Unsupported complexity is blocked and queued, not guessed.
6. Every promoted understanding is reproducible from official/Scryfall source,
   deterministic parser output, focused tests, and audit artifacts.

## Target Card Understanding Model

Every card should resolve into this normalized object:

```json
{
  "card_id": "uuid printing row",
  "oracle_id": "uuid canonical playable identity",
  "identity_status": "exact | fallback_name | blocked",
  "source": {
    "scryfall_bulk_type": "default_cards | all_cards | oracle_cards",
    "scryfall_updated_at": "timestamp",
    "oracle_hash": "hash of official oracle/faces payload",
    "rulings_hash": "hash of rulings payload if present"
  },
  "faces": [
    {
      "name": "face name",
      "type_line": "face type line",
      "mana_cost": "face mana cost",
      "oracle_text": "face oracle text"
    }
  ],
  "deckbuilding": {
    "functional_tags": [],
    "semantic_v2": [],
    "confidence": 0.0,
    "source_priority": "persisted -> semantic_v2 -> heuristic"
  },
  "battle": {
    "rules": [],
    "verified_rules": [],
    "execution_status": "verified | active | review_only | unsupported"
  },
  "coverage_status": "fully_understood"
}
```

## Step-by-Step Treatment Plan

### Step 1 - Refresh card source data from Scryfall

Use Scryfall bulk metadata as the ingestion anchor.

- Use `default_cards` for app-facing default printings.
- Use `all_cards` when printing-specific rows must be preserved.
- Use `oracle_cards` to validate canonical Oracle identity.
- Use `rulings` to enrich decisions and rule review.
- Keep rate-aware card API lookups only for fresh individual cards or repair
  cases.

Output:

- `cards.scryfall_id` remains printing id.
- `cards.oracle_id` remains canonical identity id.
- `cards.layout`, `cards.card_faces_json`, `cards.keywords`, `power`,
  `toughness`, `color_identity`, `produced_mana` or equivalent metadata are
  filled from source data where available.
- `oracle_hash` or `source_payload_hash` is stored or derivable for drift
  detection.

Acceptance:

- `cards.oracle_id` is filled for all legal source-backed cards except
  documented exclusions such as Alchemy rebalances or malformed legacy rows.
- `layout` is not null for source-backed Scryfall rows.
- Multi-face layouts have `card_faces_json`.

### Step 2 - Normalize identity before learning

Do not learn from raw names alone.

Order:

1. Resolve by `oracle_id`.
2. Resolve by `scryfall_id` only for concrete printing behavior.
3. Resolve localized names through `card_identity_bridge`.
4. Fall back to normalized name only when source IDs are absent, and mark the
   row `identity_status=fallback_name`.

Acceptance:

- `card_identity_bridge` stays one of the only approved sources for
  canonical/localized name resolution.
- Import, save, validate, generate, and optimize use the same identity rule.
- Commander singleton checks use identity, not only physical name.

### Step 3 - Classify low-level source coverage

For every card in `card_intelligence_snapshot`, compute and persist or expose:

- `has_oracle_id`
- `has_oracle_text`
- `has_faces`
- `has_layout`
- `has_legalities`
- `has_rulings`
- `has_function_tags`
- `has_semantic_v2`
- `has_verified_battle_rules`
- `has_any_battle_rules`

Acceptance:

- Blank source fields become explicit states.
- Vanilla creatures and simple lands are classified as low-impact or vanilla,
  not left as unexplained blanks.

### Step 4 - Generate functional tags for deckbuilding

Use deterministic functional tags first. The target taxonomy should remain
multi-tag and should not collapse a card to one role.

Current useful tags include:

- `draw`: 5,787 cards
- `removal`: 5,142 cards
- `graveyard_synergy`: 4,781 cards
- `engine`: 4,018 cards
- `token_maker`: 3,959 cards
- `ramp`: 3,254 cards
- `protection`: 2,382 cards
- `board_wipe`: 688 cards
- `tutor`: 488 cards
- `combo_piece`: 150 cards

Rules:

- Persist tags with source, confidence, evidence, and schema version.
- Keep low-confidence heuristic combo tags below operational threshold unless
  confirmed by curated source such as Commander Spellbook or manual review.
- Separate `token` from `token_maker` and `graveyard` from
  `graveyard_synergy`; do not flatten them in storage.

Acceptance:

- No card is counted in analysis by heuristics if a valid persisted tag exists.
- Every consumer receives arrays/JSON, not a single role string.

### Step 5 - Generate semantic v2 only as richer signal

Semantic v2 should enrich, not replace, functional tags.

Use it for:

- speed;
- mana efficiency;
- card advantage type;
- interaction scope;
- combo/wincon/engine/payoff/enabler flags;
- protection and recursion type;
- explanation reason.

Rules:

- Persist `schema_version`, `source`, `role_confidence`, and `tags`.
- Enforce confidence threshold before it affects optimization.
- If persisted functional tags disagree with semantic v2, functional tags win.

Acceptance:

- `functional_tags -> semantic_v2 -> heuristic` remains visible in JSON output.
- Quality gate tests continue proving that semantic v2 drift cannot mask a
  critical persisted role.

### Step 6 - Separate deckbuilding tags from battle rules

Do not derive executable battle behavior from a deckbuilding role directly.

Use this separation:

| Layer | Question answered | Table/view |
| --- | --- | --- |
| Identity | Which card is this? | `cards`, `card_identity_bridge` |
| Deckbuilding | What function does it serve in a deck? | `card_function_tags`, `card_semantic_tags_v2` |
| Candidate quality | How good/contextual is it? | `card_role_scores`, `commander_card_synergy`, `optimize_candidate_quality_summary` |
| Battle behavior | What can the simulator execute? | `card_battle_rules` |
| Safe consumer view | What should app/backend join to? | `card_intelligence_snapshot` |

Acceptance:

- No product SQL should join raw `deck_cards` or `cards` directly into
  `card_battle_rules`, `card_function_tags`, or `card_semantic_tags_v2` unless
  it aggregates by `card_id` first.
- `card_battle_rules` is never used as the primary source of deckbuilding roles.

### Step 7 - Promote battle rules through template gates

The current focused-template stack is the right shape:

1. `manaloom_battle_rule_review_queue.py`
   - reads review queue;
   - creates drafts only;
   - never writes PostgreSQL;
   - never promotes to verified.
2. `manaloom_battle_rule_focused_evidence.py`
   - consumes drafts;
   - only supports narrow low-risk templates;
   - emits focused evidence;
   - never writes PostgreSQL.
3. `manaloom_battle_rule_promotion_gate.py`
   - should be the only path to reviewed promotion;
   - requires official source review, focused replay, audit pass, and operator
     approval.

Current validation:

- `47` focused template support functions.
- `47` evaluate dispatch routes.
- `47` evidence builders.
- Latest dispatch audit: `29/29` focused-template cards evidence-ready.

Acceptance:

- `generated/needs_review` stays review-only.
- `curated/verified` means official text checked and focused evidence passed.
- `curated/active` must have an explicit reason if it is executable before
  `verified`; otherwise normalize it to `review_only` or `verified`.
- Complex cards without focused templates remain `unsupported` with backlog
  reason.

### Step 8 - Backfill the 8,748 unexplained cards

The current blank group should be split, not blindly tagged.

Buckets:

1. `vanilla_or_french_vanilla_creature`
   - no oracle text or only evergreen keywords;
   - understood for deckbuilding as low-impact creature/body.
2. `source_gap`
   - missing oracle/layout/faces/rulings unexpectedly.
3. `new_or_unusual_layout`
   - cards with layout/faces not modeled yet.
4. `non_commander_or_funny_card`
   - Un-set, attraction, sticker, plane, scheme, or unsupported casual product.
5. `manual_review_required`
   - relevant Commander card with unclear semantics and no template.

Acceptance:

- `no_function_or_semantic_or_battle` goes to `0` only after each blank card has
  a deliberate coverage status.
- Do not invent tags for vanilla cards just to inflate coverage.

### Step 9 - Fix face/layout completeness

This is the biggest source-data gap.

Actions:

- Update card sync to persist `layout` for all Scryfall-backed rows.
- Persist `card_faces_json` for all multi-face objects.
- Add tests for:
  - split cards;
  - transform DFC;
  - modal DFC;
  - adventure;
  - meld;
  - reversible cards;
  - battle cards.
- Compute color identity from source payload and validate against Commander
  rules.

Acceptance:

- Multi-face cards never rely only on parent flattened text.
- Commander color identity includes back faces and alternate characteristics
  as required by current rules.

### Step 10 - Add quality scorecards

Every batch should produce:

- total cards scanned;
- cards by coverage status;
- cards with source gaps;
- cards with tag conflicts;
- cards with semantic drift;
- cards with generated battle rules;
- cards with verified battle rules;
- cards blocked by unsupported template;
- cards promoted;
- cards reverted or stale-cleaned.

Acceptance:

- A batch cannot call itself successful if it only increases row count but
  increases false positives or generated executable behavior.

### Step 11 - Keep Hermes as lab/cache, not product truth

Hermes is useful for audits, replays, focused evidence, and queue generation.
PostgreSQL/backend remains the product source of truth.

Rules:

- Hermes may propose.
- Hermes may audit.
- Hermes may generate artifacts.
- PostgreSQL promotion requires reviewed backend-owned path.
- App users should not see raw Hermes metadata unless the API contract exposes a
  safe aggregate.

Acceptance:

- All app-facing behavior can be explained from backend views/tables.
- Hermes artifacts are cited as evidence, not as final truth.

### Step 12 - Continuous validation

Run these checks before treating a card batch as trusted:

```bash
cd server
dart test test/functional_card_tags_test.dart \
  test/optimization_quality_gate_test.dart \
  test/optimize_functional_role_support_test.dart \
  test/candidate_quality_data_support_test.dart \
  test/data_model_migration_test.dart

python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_focused_template_dispatch_audit.py \
  --json-output server/test/artifacts/card_learning_template_dispatch_audit_latest.json \
  --output server/test/artifacts/card_learning_template_dispatch_audit_latest.md
```

Add DB checks:

```sql
SELECT count(*) FROM card_intelligence_snapshot;
SELECT count(DISTINCT card_id) FROM card_intelligence_snapshot;

SELECT count(*)
FROM cards c
LEFT JOIN card_battle_rules br ON br.card_id = c.id;

SELECT count(*)
FROM cards c
LEFT JOIN card_function_tags cft ON cft.card_id = c.id;
```

The first two counts must equal `cards`. The direct joins are expected to fan
out and are only diagnostic warnings; product consumers must not use them raw.

## Prioritized Improvements

### P0 - Preserve the safe aggregate path

Keep `card_intelligence_snapshot` as the default read surface for analysis,
optimize, recommendations, weakness analysis, and Hermes sync.

### P0 - Block generated battle rules from execution

Audit all `generated/needs_review/auto` rows and make execution impossible until
reviewed. A generated row can inform backlog, but not product behavior.

### P1 - Complete Scryfall layout and face ingestion

This is required for accurate understanding of split, adventure, transform,
modal DFC, meld, battle, and other special layouts.

### P1 - Add explicit coverage status for every card

The goal is not forcing every card into a strong role. The goal is making every
card explainable.

### P1 - Normalize taxonomy at API boundaries

Expose canonical role names such as `board_wipe`; keep legacy aliases like
`wipe` only internally and document the mapping.

### P2 - Expand focused battle templates by frequency and risk

Use effect coverage and replay blockers to choose the next templates. Good
template candidates are narrow, testable, and common. Bad candidates are broad
"AI understood this card" buckets without a focused replay fixture.

### P2 - Store source hashes and freshness

Track when a card understanding was last derived from Scryfall/Wizards source,
and mark stale rows when source payload changes.

## Done Criteria For "All Cards Treated"

The system can be considered operationally complete when all are true:

1. `card_intelligence_snapshot` row count equals `cards` and has one row per
   card.
2. `oracle_id` coverage is complete except documented exclusions.
3. `layout` and `card_faces_json` are source-complete for all relevant layouts.
4. Every card has a coverage status.
5. Every Commander-relevant card has either:
   - persisted functional tags;
   - semantic v2 tags;
   - verified battle rule;
   - explicit low-impact/vanilla status;
   - or manual-review status.
6. No generated `needs_review` battle rule is executable.
7. Every promoted battle template has:
   - official/Scryfall source reference;
   - focused evidence artifact;
   - replay/audit pass;
   - promotion gate record.
8. Product SQL does not join raw multi-row intelligence tables without
   aggregation.
9. Focused tests and focused-template dispatch audit pass.
10. The report for each batch lists remaining gaps instead of hiding them behind
    a single coverage percentage.

## Current Verdict

The system is functional and already has the right core architecture. It is not
yet complete for 100% card precision because source metadata for layouts/faces is
incomplete, 8,748 cards still lack any explicit intelligence signal, and many
battle rules are generated `needs_review` rows. The correct next move is not a
new broad AI classifier. The correct move is a source-backed, status-driven
treatment pipeline that completes identity/faces first, preserves multi-tag
deckbuilding roles, promotes battle behavior only through narrow templates, and
keeps every unsupported case visible until reviewed.
