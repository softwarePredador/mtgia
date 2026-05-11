# Lorehold, the Historian - external reference profile

Date: 2026-05-11

Result: **PASS WITH RISKS**

Scope: external/agregado reference profile only. No runtime code, no decklist
promotion, and no complete decklist copied from any public source.

## Source and ToS limits

- EDHREC was used only as a low-scale aggregate/manual reference. No official
  EDHREC API was assumed, no private endpoint was used, and no full list was
  copied.
- Archidekt, MTGGoldfish and Playgroup were treated as public low-scale source
  checks, not as canonical training data.
- Scryfall and the local ManaLoom backend were used for card identity, color
  identity, type/print validation and Commander legality context.
- No secrets, JWTs, tokens, DSNs, database URLs, real user emails, private
  payloads or raw authorization headers were recorded.

## Sources consulted

| Source | URL / query | What was proven | Use in this profile |
| --- | --- | --- | --- |
| Scryfall named card | `https://api.scryfall.com/cards/named?exact=Lorehold,%20the%20Historian` | Card exists; `Legendary Creature - Elder Dragon`; mana cost `{3}{R}{W}`; color identity `R/W`; Commander legal; set `SOS`; EDHREC rank present. | High-confidence identity/legal baseline. |
| Scryfall prints | `oracleid:61a41cf1-60cc-45ba-aa98-493c14e87d9d&unique=prints` | Three public prints: `PSOS #201p`, `SOS #284`, `SOS #201`; all Commander legal and `R/W`. | Print completeness check; local DB gap marker. |
| Local backend `/cards/printings` | `name=Lorehold, the Historian&limit=50&sync=true` on temporary local server | Two local prints returned: `PSOS #201p`, `SOS #284`; both `R/W`, mythic, legendary creature. | Local database fact for current ManaLoom behavior. |
| Local docs/tests | `server/manual-de-instrucao.md`, `docs/qa/manaloom_card_entry_qa_2026-05-08.md`, `server/test/decks_incremental_add_test.dart` | Existing live regression requires multiple Lorehold print options, commander eligibility, `R/W` identity, visible edition metadata, and no extra commander copy in `main_board`. | Confirms local product contract around commander/edition handling. |
| EDHREC | `https://edhrec.com/commanders/lorehold-the-historian` | External Commander context exists as aggregate commander page. | Theme/staple signal only; not a canonical decklist source. |
| Archidekt | `https://archidekt.com/search/decks?commanderName=Lorehold%2C%20the%20Historian&deckFormat=3&orderBy=-updatedAt&page=1` | Public Commander deck search context exists; observed examples are not uniformly complete or competitive. | Low-scale public deck-host corroboration. |
| MTGGoldfish | `https://www.mtggoldfish.com/archetype/commander-lorehold-the-historian/decks` | Public Commander deck hub exists for this commander. | Low-scale public deck-host corroboration. |
| Playgroup | `site:playgroup.gg/decks "Lorehold, the Historian"` and direct public check | Public indexed Lorehold deck evidence was **not proven**; direct deck URL check redirected to sign-in. | Do not count as strategic proof. |

## Local code/database facts

- ManaLoom already treats Lorehold as a commander-edition QA target.
- The local backend currently exposes two Lorehold printings via
  `/cards/printings`: `PSOS #201p` and `SOS #284`.
- Scryfall exposes a third public print, `SOS #201`, so local print coverage is
  **not proven complete** for this card.
- Local card responses used in this pass included `name`, `set_code`,
  `collector_number`, `rarity`, `color_identity` and `type_line`; Commander
  legality was confirmed through Scryfall and existing local commander-slot
  regression, not through a legality field returned by `/cards`.

## Web-derived findings

- Commander context is proven by Scryfall legality plus EDHREC/Archidekt/
  MTGGoldfish Commander labeling.
- The dominant public pattern is **Boros miracle big-spells**:
  Lorehold gives every instant/sorcery in hand miracle `{2}`, so lists bias
  toward expensive, high-impact instants/sorceries that become under-costed when
  drawn as the first card of a turn.
- The important enabler pattern is **topdeck/draw timing control**, especially
  artifact-based tools that Boros can legally play.
- Public deck hosts show casual/high-power experimentation, not a proven cEDH
  shell. Playgroup evidence is not proven.

## Interpretation: player intent and "malicia"

The player incentive is to convert Boros's usual card-advantage weakness into
opponent-turn miracle pressure. Lorehold's upkeep rummage on each opponent's
turn means the deck wants the first draw of each turn cycle to reveal a spell
that is normally too expensive to cast fairly.

The "malicia" is not simply "play big spells"; it is:

1. Keep expensive instants/sorceries in hand instead of ramping to their full
   cost.
2. Use topdeck replacement or draw timing to make the right card become the
   first draw on an opponent's turn.
3. Convert miracle `{2}` into tempo swings, board wipes, token bursts, copy
   turns or finishers before the table can untap.
4. Avoid filling the list with random haymakers that cannot be found, set up or
   protected.

## Strategic themes

| Theme | Confidence | Notes |
| --- | --- | --- |
| Miracle big spells | High | Directly implied by commander text and repeated across aggregate/deck-host signals. |
| Topdeck manipulation | High | Required to make miracle deterministic enough for optimization/generation. |
| Opponent-turn draw/rummage | Medium-high | Lorehold supplies discard/draw; support cards should increase first-draw opportunities. |
| Spellslinger/copy payoffs | Medium | Useful, but should not crowd out setup and interaction. |
| Token burst finishers | Medium | Common payoff route for discounted white/red sorceries. |
| Graveyard/flashback recursion | Medium-low | Some public lists lean here, but it is secondary unless the list deliberately supports discard value. |
| cEDH shell | Low / not proven | No credible cEDH source context was proven in this pass. Do not inject cEDH assumptions. |

## Candidate staples and packages

These are role candidates, not a final decklist.

### Topdeck and miracle setup

- `Sensei's Divining Top`
- `Scroll Rack`
- `Library of Leng`
- `Brainstone`
- `Temple Bell`
- `Mikokoro, Center of the Sea`
- `Victory Chimes`

Why: they either arrange the top card, draw on non-own turns, or exploit
Lorehold's discard-then-draw timing. `Library of Leng` is especially important
because discard replacement can turn the upkeep rummage into a same-card miracle
setup.

### Miracle payoffs / expensive spells

- `Approach of the Second Sun`
- `Storm Herd`
- `Rise of the Eldrazi`
- `Soulfire Eruption`
- `Apex of Power`
- `Volcanic Vision`
- `Creative Technique`
- `Dance with Calamity`
- `Call Forth the Tempest`
- `Brass's Bounty`
- `Hit the Mother Lode`
- `Mizzix's Mastery`

Why: these are high-impact instants/sorceries or mana/value explosions that are
materially different when cast for miracle `{2}`. They should be bracket/budget
aware because too many haymakers make early hands clunky.

### Interaction and reset package

- `Swords to Plowshares`
- `Path to Exile`
- `Blasphemous Act`
- `Austere Command`
- `Terminus`
- `Bonfire of the Damned`

Why: the deck needs real defensive texture while waiting to assemble miracle
turns. White/red miracle-adjacent sweepers are more transferable than blue
miracle cards.

### Spell payoff / copy package

- `Storm-Kiln Artist`
- `Monastery Mentor`
- `Young Pyromancer`
- `Primal Amulet // Primal Wellspring`
- `Pyromancer's Goggles`
- `Double Vision`
- `Sunbird's Invocation`
- `Arcane Bombardment`
- `Chandra, Hope's Beacon`

Why: these convert discounted spells into mana, bodies or copied effects. They
are useful after the deck has enough setup, but should not be treated as the
primary engine.

## Role targets for ManaLoom reference use

| Role | Suggested target | Evaluation note |
| --- | --- | --- |
| Lands | 36-38 | Lorehold costs five and the deck has expensive spells even when miracle is not available. |
| Mana rocks/treasure ramp | 10-13 | Prioritize two-mana rocks plus treasure spells that are useful before/after Lorehold. |
| Topdeck/miracle setup | 6-9 | Below this, miracle becomes random spectacle instead of a plan. |
| Draw/rummage/opponent-turn draw | 8-12 | Count Lorehold as engine access, but do not rely only on the commander. |
| Miracle haymakers | 10-16 | Scale down for lower brackets; avoid hands with only seven-plus mana spells. |
| Spot interaction | 4-6 | Must include efficient white/red answers. |
| Board wipes / resets | 3-5 | Prefer wipes that are acceptable when hard-cast or miracle-discounted. |
| Spell payoffs/copy engines | 5-8 | Add after setup/ramp/interaction are satisfied. |
| Graveyard recursion | 2-5 | Optional; only increase if discard value is a declared subtheme. |
| Dedicated win conditions | 4-7 | Include token burst, burn/exile big spells or second-spell finish lines. |

## Suspect cards and avoid patterns

| Pattern/card | Reason |
| --- | --- |
| `Temporal Mastery`, `Devastation Tide`, `Mystical Tutor`, `Brainstorm` | Legal in Commander generally, but blue color identity makes them illegal in Lorehold `R/W`. These can leak in from generic miracle heuristics. |
| `Mana Crypt`, `Jeweled Lotus`, `Dockside Extortionist` | Scryfall marks them banned in Commander; do not recommend for normal Commander output. |
| Full cEDH fast-mana/stax assumptions | Competitive relevance for Lorehold was not proven; cEDH logic must not collapse into casual Commander. |
| Too many uncategorized haymakers | Makes the list spectacular but not functional; every expensive spell should map to payoff/removal/mana/refill/win. |
| Blue miracle package import | Generic miracle pages overrepresent blue cards; filter by `R/W` color identity before ranking. |
| Copying a public decklist as the profile | Violates the aggregate-reference goal and creates poor product fit. |
| Treating EDHREC rank as truth | Useful aggregate signal, but not a design authority or official API. |
| Treating Playgroup as evidence here | Public Lorehold deck evidence was not proven in this pass. |

## Confidence and source count

| Claim | Confidence | Source count | Basis |
| --- | --- | ---: | --- |
| Lorehold is a legal `R/W` Commander | High | 2 | Scryfall legality plus local commander-edition regression context. |
| Public Commander interest exists | High | 3 | EDHREC, Archidekt and MTGGoldfish all expose Commander context. |
| Local DB has multiple prints | High | 1 local backend + docs/tests | `/cards/printings` returned two printings; local tests require multiple picker options. |
| Local DB is print-complete | Low | 2 conflicting | Scryfall has three prints, local backend returned two. |
| Miracle/topdeck big-spell plan is the core pattern | High | 4 | Commander text, EDHREC aggregate, Archidekt and MTGGoldfish signals. |
| Playgroup supports the same profile | Not proven | 0 usable | Public indexed evidence was not found; direct check redirected to sign-in. |
| Lorehold has cEDH relevance | Low / not proven | 0 credible cEDH | No credible cEDH event/database context was proven. |

## Useful patterns to absorb into optimize/generate later

- Commander-specific miracle package tag:
  `boros_miracle_big_spells`.
- Hard legality filter before miracle recommendations:
  `commander == legal`, `color_identity subset of {R,W}` and banned-card
  exclusion.
- Setup-before-haymaker scoring:
  topdeck/draw timing cards should raise confidence for expensive instant/
  sorcery additions; without setup, penalize extra haymakers.
- Role-aware package balancing:
  ramp + topdeck setup + interaction must be satisfied before suggesting more
  seven-plus mana spells.
- Casual/high-power separation:
  this profile can inform Commander brackets 2-3 and tuned/high-power casual,
  but should not feed competitive Commander references without separate cEDH
  proof.

## Patterns risky or not transferable

- Do not stage EDHREC/Archidekt/MTGGoldfish/Playgroup data directly into
  `external_commander_meta_candidates` from this pass. This was aggregate
  research, not a 100-card legality-validated import.
- Do not add cEDH labels or competitive weights to Lorehold from this profile.
- Do not assume every popular expensive spell is correct; ManaLoom should score
  by role and setup availability.
- Do not use Playgroup as source evidence for Lorehold until a public, accessible
  deck page is proven.

## Evaluation criteria for future generated/optimized Lorehold lists

1. Commander list has 100 cards including exactly one Lorehold commander.
2. All non-commander cards are Commander legal and color identity is within
   `R/W` or colorless.
3. No banned Commander cards are recommended.
4. At least six credible topdeck/draw timing enablers exist before the deck is
   given more than twelve expensive miracle payoffs.
5. The list has enough ramp to cast Lorehold and recover when miracle is not
   available.
6. Interaction is not sacrificed for spectacle.
7. The output explains why each haymaker is present by role, not merely because
   it is expensive.
8. Any external public list is used only as a signal, never as a copied final
   deck.

## Smallest next technical actions

1. Add a non-runtime fixture/profile entry for `boros_miracle_big_spells` if the
   deck engine later accepts reference profiles.
2. Audit local card sync for the missing `SOS #201` Lorehold print before using
   print completeness as a product promise.
3. Add a targeted candidate-quality test that rejects off-color blue miracle
   staples and banned Commander fast mana for Lorehold recommendations.
4. Keep this profile out of cEDH/competitive meta promotion until a credible
   Commander event or cEDH database source proves relevance.
