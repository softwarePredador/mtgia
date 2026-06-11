# Battle/AI/Hermes - Decisoes e Duvidas Para Validacao Do Produto

Status: owner defaults approved on 2026-06-11.

Purpose: list the project/product/logistics decisions that must be confirmed
before implementation changes schema, Hermes sync, battle rules, learned decks
or AI optimization behavior.

Use this document to answer what should be true for ManaLoom before Codex or
Hermes starts coding the next phase.

For a direct owner-response checklist, use:

- `docs/hermes-analysis/BATTLE_AI_OWNER_VALIDATION_QUESTIONS_2026-06-11.md`

This file keeps the broader policy context; the owner validation file keeps the
short list of questions, holes, logistics and ideas to answer before promoting
new behavior.

## Owner-approved defaults

Approved on 2026-06-11:

- release stability first;
- no global Mox ban;
- learned decks only for single commander until partner corpus exists;
- duplicate Commander singleton identity blocks save/import;
- Hermes metadata hidden from normal users;
- Hermes proposes, backend owns;
- `needs_review` battle rules do not execute hard behavior;
- `card_battle_rules` can derive tags only when trusted and traceable;
- first coding slice limited to aggregation + Hermes snapshot + tests.

These defaults unblock the first implementation slice. Anything outside this
policy still needs explicit owner validation.

## 1. Product decisions

### 1.1 Lorehold no-mox policy

Current documented state:

- active learned Lorehold deck uses the no-premium-Mox candidate;
- `Chrome Mox`, `Mox Diamond`, `Mox Opal` are excluded from that learned deck.

Decision needed:

- Is this only a Lorehold learned-deck policy?
- Or should some budget/bracket profiles globally avoid premium Mox cards?

Recommended default:

- Keep it only as Lorehold learned-deck/product policy until broader bracket
  rules are defined.

### 1.2 Learned deck visibility

Current behavior:

- app shows learned deck availability when a supported commander is typed.

Decision needed:

- Should learned decks be shown only when `legal_status=commander_legal`?
- Should lower-confidence learned decks be hidden or shown with a warning?
- Should learned decks from Hermes require manual approval before appearing?

Recommended default:

- Show only active, commander-legal, high-confidence learned decks.

### 1.3 AI vs deterministic logic

Decision needed:

- When Hermes learns a strong pattern, should it become:
  - prompt context only;
  - ranking weight;
  - hard rule;
  - UI recommendation;
  - hidden backend policy?

Recommended default:

- Start as prompt/context/report.
- Promote to ranking after scorecard.
- Promote to hard rule only with tests and product sign-off.

## 2. Commander and deck legality decisions

### 2.1 Partner/background support

Current implementation:

- learned deck validation expects 1 commander and 99 main cards.

Decision needed:

- Do we need learned decks for partner/background/two-commanders in the next 20
  days?

Recommended default:

- No. Keep as documented gap unless a real commander/customer case requires it.

### 2.2 Singleton identity

Current concern:

- PostgreSQL `deck_cards` is keyed by `deck_id/card_id`.
- Commander singleton should not be validated only by printing id.

Decision needed:

- Should duplicate singleton identity be a hard error at import/save?
- Or should it be warning + auto-merge?

Recommended default:

- For Commander/Brawl: hard validation error or guided resolution.
- Do not silently merge distinct printings if legality could change.

### 2.3 Localized names

Decision needed:

- Should localized import aliases become official persisted aliases?
- Or remain resolver-only support?

Recommended default:

- Persist resolver evidence/aliases where safe, but keep canonical card identity
  in English/oracle fields.

## 3. Data model decisions

### 3.1 Card identity fields

Need validation:

- Add `oracle_id`?
- Add `layout`?
- Add `card_faces_json`?
- Add normalized English singleton identity?

Recommended default:

- Yes, plan migration. This is required before strong split/MDFC/DFC/adventure
  automation.

### 3.2 `card_battle_rules` expansion

Need validation:

- Add face/timing/target/cost metadata now or later?

Recommended default:

- Add in phases. First preserve multi-rule arrays. Then add fields required by
  real failing battle cases.

### 3.3 Review and execution status

Current issue:

- `source` and `review_status` are separate, but execution enablement is not
  explicit.

Decision needed:

- Add `is_enabled` or `execution_status`?

Recommended default:

- Add explicit execution status before rules become hard battle automation.

## 4. Hermes logistics

### 4.1 Source of truth

Decision needed:

- Can Hermes ever directly alter production behavior?

Recommended default:

- No. Hermes can propose, score, sync read models and promote approved learned
  decks through PostgreSQL/backend contracts only.

### 4.2 Cron promotion rules

Decision needed:

- Which cron outputs can become automatic implementation tasks?

Recommended default:

- Only reports with:
  - file/line evidence;
  - reproducible command;
  - no generic "improve" task;
  - scorecard or test evidence when behavior changes.

### 4.3 Report-only vs apply

Decision needed:

- Should every semantic/battle change run report-only before apply?

Recommended default:

- Yes. Report-only first, apply only after totals/hashes match expectations.

## 5. Battle simulator scope decisions

### 5.1 Judge engine ambition

Decision needed:

- Are we trying to implement a complete judge engine?

Recommended default:

- No. Implement practical Commander simulation for product decisions, driven by
  tested card-specific and mechanic-specific cases.

### 5.2 Backend simulator vs Hermes simulator

Decision needed:

- Should `/decks/:id/simulate` become the same engine as Hermes?

Recommended default:

- Not now. Keep backend simulator light. Migrate only proven Hermes outputs into
  backend APIs when performance and contracts are ready.

### 5.3 Replay fidelity

Decision needed:

- How much replay detail is needed for product decisions?

Recommended default:

- Enough to explain why a swap was accepted/rejected, not a full tournament log.

## 6. AI generation and optimize decisions

### 6.1 Optimization gates

Decision needed:

- Which semantic losses should block optimize suggestions?

Recommended default:

- Hard block losses in `draw`, `removal`, `ramp`, `wipe` only after scorecard.
- Keep `protection` and extended roles review-only until more corpus.

### 6.2 ML feedback

Decision needed:

- When can `ml_prompt_feedback` change ranking/prompt policy?

Recommended default:

- Only after scorecard comparing before/after on representative commanders.

### 6.3 Learned deck save flow

Decision needed:

- Should learned deck save always preserve exact 100-card list?
- Should users be allowed to edit before save?

Recommended default:

- Preview exact list first. Edits should trigger validation before save.

## 7. UX/product questions

1. Should learned deck preview show internal source names like
   `Hermes learned_deck:82`, or should this be hidden behind friendly copy?
2. Should score/confidence be visible to normal users or only QA/dev mode?
3. Should no-mox policy be described to users?
4. Should optimize explain role losses using `functional_tags_json` samples?
5. Should Deck Analysis show both function tags and battle rule diagnostics, or
   keep battle diagnostics hidden?

Recommended default:

- Normal users see friendly copy.
- QA/dev mode sees source ids, score, confidence and diagnostics.

## 8. Implementation order for owner approval

Please validate this order before coding:

1. Canonical PG aggregation contract.
2. Hermes SQLite snapshot with `card_id` and arrays.
3. Hermes consumers set-based.
4. Tag namespace cleanup.
5. Semantic identity schema planning.
6. Battle rule metadata expansion.
7. Learned deck partner support.
8. ML feedback promotion.

If you want faster delivery, approve only steps 1-3 for the first slice.

## 9. Open questions to answer

1. Is the 20-day goal focused on release stability or deeper battle accuracy?
2. Should Lorehold remain the only commander with manual learned-deck policy?
3. Are premium budget exclusions a product feature or just a Lorehold exception?
4. Should partner/background learned decks be postponed?
5. Should duplicate singleton identity block save/import immediately?
6. Should internal Hermes metadata be visible in the app?
7. Should Hermes crons ever auto-apply to PostgreSQL, or always propose?
8. Should battle rules with `needs_review` be visible to analysis but ignored by
   execution?
9. Should we create a public-facing "why this card" explanation from
   `functional_tags_json`?
10. Should `card_battle_rules` be allowed to derive deckbuilding tags only from
    `verified/active` rules?

## 10. Approved answer set

Use this approved policy:

- release stability first;
- no global Mox ban;
- learned decks only for single commander until partner corpus exists;
- duplicate Commander singleton identity blocks save/import;
- Hermes metadata hidden from normal users;
- Hermes proposes, backend owns;
- `needs_review` battle rules do not execute hard behavior;
- `card_battle_rules` can derive tags only when trusted and traceable;
- first coding slice limited to aggregation + Hermes snapshot + tests.
