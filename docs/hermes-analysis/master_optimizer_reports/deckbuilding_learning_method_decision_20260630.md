# Deckbuilding Learning Method Decision - 2026-06-30

- generated_at: `2026-06-30`
- scope: Commander deckbuilding learning method for ManaLoom, with Lorehold as
  the current proof case.
- postgres_writes: `false`
- source_db_mutated: `false`

## Decision

ManaLoom should not learn Commander deckbuilding by generating many whole decks
and battling until one wins. That approach is too noisy, too slow, and too easy
to overfit to the current simulator or opponent sample.

ManaLoom also should not persist only on the current champion deck. That is
safer than random search, but it traps the optimizer in local improvements and
misses packages that only make sense when several cards move together.

The most effective method is a constrained active-learning loop:

1. build a commander-specific intent model and role/package targets from rules,
   card data, reference decks, combos, learned decks, and local usage;
2. generate a small Pareto frontier of coherent shells and package hypotheses;
3. reject candidates through cheap legality, role-density, curve, source, and
   runtime-readiness gates before battle;
4. use battle as the expensive final evaluator, with equal seeds/opponents and
   direct card-exposure traces;
5. learn at package/card/function level from every run, then recut same-lane
   hypotheses into the champion shell only when the package actually fired.

For Lorehold today, this means `607` remains the protected champion, while
from-scratch challenger shells remain an exploration source. A challenger must
tie or beat `607` under the same battle gate before whole-deck promotion.

## Method Comparison

| Method | Use | Strength | Failure Mode | Decision |
| --- | --- | --- | --- | --- |
| Random/mass whole-deck generation plus battles | Explore unknown space | Finds surprises if the simulator is cheap and reliable | Commander search space is enormous; battle variance dominates; poor decks waste simulation time | Do not use as primary method |
| Persist only on champion deck | Hill-climb protected baseline | Lowest risk and easy to reason about cuts | Local optimum; misses package-level synergies and alternative shells | Use for confirmation and safe promotion |
| Pure reference-copy strategy | Start from EDHREC/Moxfield/public decks | Fast initial quality and real-human priors | Popularity is not proof for this commander, budget, bracket, or runtime | Use as source lane only |
| Pure structural scorer | Cheap ranking before battle | Scales well and catches bad role/curve shells | Can rate a deck highly even when battle execution fails | Use as pre-battle gate |
| Constrained active learning with successive halving | Generate structured candidates, prune, then battle top hypotheses | Balances exploration and proof; learns reusable package signals | Requires disciplined registry and trace telemetry | Adopt as the default |

## External Evidence Imported

The external sources agree on the planning order: legal format first, commander
intent next, then mana/ramp/draw/interaction/package balance, then validation.

- Wizards Commander format page:
  `https://magic.wizards.com/en/formats/commander`
  - Official format shape, singleton/color-identity constraints, and power
    framing belong at the first gate.
- EDHREC Commander deckbuilding guide:
  `https://edhrec.com/articles/how-to-build-a-commander-deck`
  - Public Commander guidance starts from categories and then asks whether the
    deck plays the intended way.
- Command Zone deckbuilding template via EDHREC:
  `https://edhrec.com/articles/the-command-zone-commander-deckbuilding-template-for-the-new-era-the-command-zone-658-mtg-edh-magic-gathering`
  - Ramp, draw, interaction, wipes, and engines are planning lanes, not
    automatic card choices.
- Commander Spellbook:
  `https://commanderspellbook.com/`
  - Combo relations and deterministic lines are useful package evidence, but
    they do not prove full-deck balance.
- MTGJSON:
  `https://mtgjson.com/api/v5/`
  - Card identity, legalities, types, and Oracle-style data are data-input
    lanes, not strategic quality by themselves.
- Frank Karsten land/probability work:
  `https://www.channelfireball.com/article/How-Many-Lands-Do-You-Need-in-Your-Deck-An-Updated-Analysis/`
  - Mana-base choices need probability/curve thinking before game simulation.
- CCG deck recommendation/optimization research such as Q-DeckRec:
  `https://arxiv.org/abs/1806.09771`
  - Algorithmic deck construction benefits from recommendation/constraint
    models before evaluation; evaluation alone does not make the search cheap.

## Internal Evidence

Current ManaLoom evidence points to the same conclusion.

- `COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md` already separates Commander
  strategy quality from executable card-rule truth.
- The current contract protects Lorehold deck `607`, but explicitly says it is
  not universal truth.
- Decks `614` and `615` were close structurally and produced useful package
  signals, but equal battle gates did not justify replacing `607`.
- The repaired `Mana Vault` one-card swap had direct card-use evidence and
  still lost to `607`; therefore "more raw mana" is not automatically better.
- The `The One Ring` retest also had real exposure and still lost; a generally
  powerful staple is not automatically correct in the current Lorehold shell.
- The from-scratch challenger builder generated three coherent shells from
  corpus `607-616`. None beat `607`, but the recursion/discard shell produced
  useful package telemetry for `Squee`, `Library of Leng`, `Sensei's Divining
  Top`, and `Birgi`.

The important learning is that failed challengers are still valuable when they
expose a reusable package. Failed challengers are not valuable when they only
return aggregate win/loss without card exposure.

## Adopted ManaLoom Loop

### Stage 0 - Source And Intent Model

Build or refresh these facts before candidate generation:

- official legality, color identity, singleton, commander count, and deck size;
- commander intent sentence, primary plan, backup plan, and failure modes;
- target role lanes: lands, ramp, draw/selection, tutors, removal, wipes,
  protection, recursion, finishers, commander-specific enablers/payoffs;
- reference corpus: EDHREC-style stats, public decklists, learned decks,
  local successful variants, Commander Spellbook combo lines, card data;
- runtime readiness: cards that can be executed by battle versus cards that are
  only strategic candidates.

### Stage 1 - Candidate Frontier

Generate a small frontier instead of a mass of random decks:

- champion package variants: 60%-70% of effort;
- from-scratch coherent shells: 20%-30% of effort;
- novelty/meta/adversarial probes: 5%-10% of effort.

Each candidate must declare:

- experiment type;
- source lanes used;
- expected win plan;
- package additions and same-lane cuts;
- protected anchors;
- expected telemetry;
- runtime/card-rule risk.

### Stage 2 - Cheap Gates

Reject before battle when any of these fail:

- legal deck shape and commander identity;
- unresolved cards or identity aliases;
- role/package density outside target ranges;
- mana curve or color-source imbalance;
- package overfill;
- protected-anchor violation;
- runtime-critical cards without executable battle support;
- direct fanout-prone joins or stale artifact input.

### Stage 3 - Successive Battle Halving

Battle only candidates that pass cheap gates.

Recommended progression:

1. smoke: one game per selected opponent and fixed champion opponent when
   applicable;
2. confirmation: multiple seeds and the same opponent set for champion and
   candidate;
3. promotion: larger equal gate only for candidates that tied or beat the
   champion and showed the expected card/package telemetry.

Promotion requires:

- candidate win rate ties or beats champion under equal seeds/opponents;
- no regression in required pressure matchup;
- key candidate cards were drawn/cast/used or focused tests exercised them;
- the expected commander plan appeared in traces;
- cuts are same-lane or have explicit package-level evidence.

### Stage 4 - Learning Registry

Every candidate, win or loss, should write a durable learning row/report with:

- candidate id and champion reference;
- hypothesis and source lanes;
- cards added/cut and lanes affected;
- structural score and role/package deltas;
- battle result by opponent/seed;
- card exposure: drawn, cast, resolved, activated, trigger, zone transitions;
- failure mode;
- decision: reject, retest, package-learn, promote-to-deeper-gate, promote.

This prevents the same weak hypotheses from being retested and lets failed
shells contribute useful package priors.

## Practical Lorehold Next Move

Do not create dozens of new Lorehold decks and battle them blindly.

The next effective Lorehold work is:

1. keep `607` as champion and fixed opponent;
2. extract only the package that fired from the recursion/discard challenger:
   `Squee + Library of Leng + Sensei's Divining Top + Birgi/recursion support`;
3. build one or two same-lane package variants against `607`;
4. run smoke, then confirmation only if smoke ties or wins;
5. store card-exposure evidence so the result teaches future deckbuilding even
   if the exact candidate fails.

From-scratch building remains useful, but only as controlled exploration. The
champion shell is the confirmation surface.

## Guardrails

- Never promote a card because it is a staple without lane fit and exposure
  evidence.
- Never compare unrelated cuts such as value engine versus runtime/commander
  synergy unless the candidate declares an explicit package tradeoff.
- Never let raw EDHREC/public-list inclusion become an automatic score.
- Never treat battle aggregate wins as card-level proof when the card was not
  accessed.
- Never let `607` become universal truth for other commanders.
- Never let from-scratch failures disappear without package-level learning.

## Final Answer

The best method is not "many random decks until one wins" and not "only keep
polishing 607". The default should be constrained active learning:
source-backed commander model -> small coherent candidate frontier -> cheap
structural gates -> equal battle gates -> package/card telemetry -> same-lane
promotion only when evidence holds.

