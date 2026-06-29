# Commander Deckbuilding Contract - 2026-06-29

Status: `frozen_operating_contract`.

This file freezes the operating contract for ManaLoom Commander deckbuilding.
It is separate from `XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md` and
`BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md`.

Card-rule work answers: "can the battle runtime execute this card correctly?"
Deckbuilding work answers: "does this commander deck have the right plan,
package density, legality, source provenance, and battle proof?"

## Frozen Decision

Do not optimize every commander by copying the current Lorehold deck 607 flow.
Use one Commander deckbuilding pipeline for all commanders:

1. official format and card-data validation;
2. commander intent profile;
3. external/reference corpus;
4. learned deck and local usage evidence;
5. deterministic legal shell;
6. optimizer or AI proposal;
7. validation, strategy matrix, and battle gate.

For Lorehold specifically, deck `607` is the current protected structural
baseline, not universal truth. A future Lorehold candidate can replace it only
when it ties or beats the protected baseline under the same strategy and battle
gate rules.

## Source Hierarchy

| Source lane | Use for | Must not be used for |
| --- | --- | --- |
| Official Commander rules | 100-card shape, commander requirement, singleton, color identity, ban/legal framing | Card popularity or strategic package proof |
| Scryfall and MTGJSON | Identity, Oracle text, layout, legality, rulings, hashes, resolver inputs | Commander-specific strategic quality by itself |
| EDHREC | Commander-specific popular cards, themes, role expectations, aggregate strategy signals | Exact deck copying or executable battle-rule truth |
| Moxfield, Archidekt, public decklists | Reference corpus, recurring package choices, sample shells, bracket/style clues | Automatic promotion without legality/source validation |
| Commander Spellbook | Combo package discovery and deterministic synergy candidates | General deck balance or rule execution by itself |
| Local learned decks | Product-specific successful candidates and prior promoted shells | Replacing source provenance or current legality checks |
| ManaLoom battles/replays | Outcome proof, pressure matchup proof, drawn/cast/used evidence for chosen cards | Card-level rule proof unless the card was exercised |
| XMage | Runtime/rule behavior reference for cards used by decks | Deck popularity, intent, or metagame quality |

## Required Contract Per Commander

Before a commander is considered deckbuilder-ready, the project must have:

- a resolved commander identity and legal color identity;
- a usable commander profile or a documented fallback reason;
- role targets for land, ramp, draw, removal, protection, board wipes,
  recursion, tutors, win conditions, and commander-specific packages;
- at least one source-backed reference lane:
  `commander_reference_card_stats`, `commander_reference_deck_analysis`,
  EDHREC/cache, public corpus, or active learned deck;
- a deterministic fallback that produces a legal deck without unresolved cards;
- validation through `GeneratedDeckValidationService`;
- provenance diagnostics that show which source lane placed each important
  card;
- a strategy matrix or equivalent scorer before battle;
- battle gate proof for promoted structural changes.

If a commander has no reliable external/reference corpus, the deckbuilder must
return a conservative legal deck with diagnostics instead of pretending that
generic Commander heuristics are commander-specific proof.

## Lorehold Current Contract

Current commander intent:

> Use topdeck setup, hand filtering, and Lorehold's commander discount to cast
> high-impact instant/sorcery spells ahead of curve, then convert that window
> into a deterministic finisher while surviving fast combat pressure.

Required Lorehold package lanes:

| Lane | Meaning |
| --- | --- |
| `early_plan` | early mana, low-cost setup, cheap protection, early interaction |
| `topdeck_miracle_setup` | topdeck control and first-draw setup for miracle timing |
| `hand_filter` | rummage, wheels, discard/draw setup, hand smoothing |
| `spell_chain_conversion` | instants/sorceries, copy engines, cost reducers, ritual turns |
| `protection_window` | cards that keep the critical spell turn from being stopped |
| `pressure_absorber` | cards that stop fast combat decks from killing Lorehold first |
| `graveyard_recursion` | secondary value from discarded or used spells |
| `deterministic_finisher` | clear ways to close after the discounted spell window |

Current Lorehold evidence generated on 2026-06-29:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260629_deckbuilding_contract.md`
- `server/test/artifacts/commander_generate_provenance_20260629_deckbuilding_contract/commander_generate_provenance_summary.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_artifact_contract_audit_20260629_current.md`

The current canonical Lorehold strategy matrix JSON schema is
`decks[] + ranked_deck_keys`. Historical `ranked_decks` reports are supported
only through `lorehold_artifact_contract_audit.py` as legacy artifacts; they
must not be consumed directly by continuation gates or deck-change logic.

Current structural ranking from decks `607-616`:

1. `607`: score `141.2`, intent `100.0`, rule-ready `100.0%`.
2. `615`: score `134.8`, intent `97.2`, rule-ready `98.8%`.
3. `614`: score `131.7`, intent `95.6`, rule-ready `100.0%`.

Interpretation:

- `607` remains the protected baseline because it is structurally aligned and
  fully rule-ready.
- `615` and `614` are close enough to keep as serious candidates, especially
  because they contain strong package signals such as Birgi/Mana Vault and
  Aetherflux-style spell conversion.
- None of these three is final from structure alone. The next decision must use
  an equal battle gate and decision trace inspection.

## General Deckbuilding Gate

Every generated or optimized Commander deck must pass:

1. exact commander and deck-size validation;
2. singleton and Commander legality validation;
3. color identity validation, including split/MDFC/back-face/adventure cards;
4. unresolved-card count equals zero;
5. role/package target check;
6. source provenance check;
7. no raw multi-row rule/tag fanout in deck joins;
8. artifact-contract check for every matrix, gate, exposure, replay, and
   historical Lorehold report consumed by the decision;
9. battle gate for any structural promotion;
10. drawn/cast/used or focused-test evidence for any card-specific conclusion.

## Lorehold Promotion Gate

A Lorehold candidate can replace `607` only when all are true:

- it passes the structural strategy matrix;
- it keeps land/ramp/draw/removal/protection/wincon counts inside the frozen
  profile ranges unless a documented battle result justifies the deviation;
- it does not cut protected anchors without same-lane replacement proof;
- it ties or beats `607` in the same opponent set and seed window;
- it does not regress the fast pressure matchup, especially Winota-style
  combat pressure;
- decision traces show Lorehold actually uses topdeck/miracle setup and
  discounted spell-chain conversion before the game is decided.

## Current Validation Commands

Read-only provenance audit:

```bash
cd server && dart run bin/commander_generate_provenance_audit.dart \
  --commander="Lorehold, the Historian" \
  --artifact-dir=test/artifacts/commander_generate_provenance_20260629_deckbuilding_contract
```

Lorehold variant strategy matrix:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_strategy_matrix.py \
  --deck-ids 607,608,609,610,611,612,613,614,615,616 \
  --out-prefix docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260629_deckbuilding_contract
```

Lorehold artifact contract audit:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_artifact_contract_audit.py \
  --out-prefix docs/hermes-analysis/master_optimizer_reports/lorehold_artifact_contract_audit_20260629_current
```

Focused backend tests:

```bash
cd server && dart test \
  test/commander_reference_readiness_support_test.dart \
  test/optimize_swap_candidate_support_test.dart \
  test/generated_deck_validation_service_test.dart
```

External source availability check used for this contract:

```bash
curl -L -s -o /tmp/manaloom_ext_check.html -w "%{http_code}" \
  https://magic.wizards.com/en/formats/commander
curl -L -s -o /tmp/manaloom_ext_check.html -w "%{http_code}" \
  https://edhrec.com/commanders/lorehold-the-historian
curl -L -s -o /tmp/manaloom_ext_check.html -w "%{http_code}" \
  https://edhrec.com/guides/edhrec-guide-to-spellslinger-in-commander
curl -L -s -o /tmp/manaloom_ext_check.html -w "%{http_code}" \
  https://edhrec.com/articles/how-to-build-a-commander-deck
curl -L -s -o /tmp/manaloom_ext_check.html -w "%{http_code}" \
  https://archidekt.com/commanders/Lorehold%2C%20the%20Historian
curl -L -s -o /tmp/manaloom_ext_check.html -w "%{http_code}" \
  https://commanderspellbook.com/
```

All returned HTTP `200` on 2026-06-29.

## Stop Rules

Stop and fix the deckbuilder contract before promoting a deck if any of these
happen:

- a deck is called better only because it has strong individual cards;
- a battle aggregate is treated as card-level proof without drawn/cast/used
  evidence;
- a candidate replaces a protected baseline without equal opponent and seed
  comparison;
- external popularity is treated as legality or battle-rule proof;
- XMage rule availability is treated as proof that the card belongs in the
  deck;
- a generic Commander ratio overrides a commander-specific intent profile;
- unresolved/off-color cards are repaired silently without diagnostics;
- raw multi-row intelligence tables are joined into deck rows without
  aggregation.
- a historical Lorehold artifact is consumed as if it had the current schema
  without first passing `lorehold_artifact_contract_audit.py`.

## Next Product Step

For Lorehold, first run the artifact contract audit. Then continue from `607`
as protected baseline, keep `615` and `614` as live challengers, and run an
equal battle gate that records:

- opening-hand/mulligan quality;
- whether topdeck/miracle setup was drawn and used;
- whether Lorehold cast discounted high-impact instants/sorceries;
- whether protection was available during the conversion turn;
- whether finishers closed the game or only produced value;
- which candidate cards were drawn, cast, activated, or stranded.

For other commanders, first create the same commander intent profile and source
provenance layer, then use the same gate.
