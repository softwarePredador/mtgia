# Commander Deep Knowledge Report

> **Generated:** 2026-06-01 ~14:20 UTC
> **Commander:** Lorehold, the Historian
> **Color Identity:** Boros (RW)
> **Archetype:** Spellslinger / Treasure Ramp / Copy Engine
> **Source Agent:** Commander Knowledge Deep Cron Job
> **Evidence Base:** 35+ Scout executions, 23+ Evolution Oracle cycles, 7 Battle runs (goldfish + matchup), 13+ Mulligan simulations, Wincon Diversity Oracle (2 executions), EDHREC 7,851 decks snapshot, card_deck_analysis PostgreSQL
> **Deck State:** 100 cards (86 unique rows, 35 lands), deck_id=6, card hash `30d00347764fc2a215edb4e668994871`

---

## 1. Archetype Overview

```
Treasure Ramp → Big Spell Free → Lorehold Copy → Treasure Payoff
```

Lorehold, the Historian is a Boros spellslinger commander that generates explosive mana through treasure tokens, casts massive game-defining spells, and copies them to multiply value. The deck operates in a "slow burn" rhythm: survive early turns with spot removal and board wipes, ramp into treasures mid-game, then close with deterministic combos or combat-based finishers.

### Deck Skeleton (Current State)

| Category | Count | Key Cards |
|:---------|:-----:|:----------|
| Lands | 35 | Ancient Tomb, Boseiju, Cavern of Souls, 5+ fetches, Sacred Foundry, Kor Haven |
| Ramp | 16 | Sol Ring, Arcane Signet, Fellwar Stone, Talisman of Conviction, Smothering Tithe, Storm-Kiln Artist, Jeska's Will, Big Score, Unexpected Windfall, Hit the Mother Lode, Brass's Bounty |
| Draw (tagged) | 5 | Faithless Looting, Windfall, Valakut Awakening, Dance with Calamity, Dragon's Rage Channeler |
| Draw (real) | ~8 | tagged + Weathered Wayfarer, Land Tax, Sensei's Divining Top (selection) |
| Removal | 9 | Path to Exile, Swords to Plowshares, Abrade, Chaos Warp, Generous Gift, Blasphemous Act, Austere Command, Fated Clash, Volcanic Vision |
| Board Wipe | 5 | Blasphemous Act, Austere Command, Call Forth the Tempest, Worldfire, Volcanic Vision |
| Protection | 9 | Mother of Runes, Grand Abolisher, Boros Charm, Flawless Maneuver, Teferi's Protection, Deflecting Swat, Akroma's Will, Lightning Greaves, Hexing Squelcher |
| Copy Engine | 5 | Lorehold (commander), Double Vision, Arcane Bombardment, Primal Amulet, Dawning Archaic |
| Wincon (scored) | 7 | Approach of the Second Sun, Worldfire, Mizzix's Mastery, Rite of the Dragoncaller, Apex of Power, Call Forth the Tempest, Storm Herd |

**CMC bands (nonland):** 0=3, 1=11, 2=8, 3=13, 4=9, 5=3, 6-7=7, 8+=6
**Average CMC (nonland):** 3.61

---

## 2. Ramp Patterns

### Treasure-Centric Ramp Engine

Lorehold's ramp strategy is fundamentally different from traditional green-based land ramp. Instead of fetching lands, the deck generates **treasure tokens** that double as spell-casting resources and copy-engine fuel.

**Core Treasure Generators (8+ sources):**

| Carta | CMC | Mechanism | Output |
|:------|:---:|:----------|:-------|
| Storm-Kiln Artist | 4 | Treasure per instant/sorcery cast or copied | Scales with copy engines (1 spell × 3 copies = 3 treasures) |
| Smothering Tithe | 4 | Treasure per opponent draw (unless they pay 2) | ~3 treasures per turn cycle |
| Big Score | 4 | Draw 2 + create 2 treasures | Net: 2 cards, 2 treasures |
| Unexpected Windfall | 4 | Draw 2 + create 2 treasures | Same as Big Score (functional twin) |
| Hit the Mother Lode | 7 | Discover 10 + treasures equal to discovered card CMC | High variance, 79.3% EDHREC inclusion |
| Brass's Bounty | 7 | Treasure per land you control | ~7 treasures with 7 lands in play |
| Jeska's Will | 3 | Add R per card in target opponent's hand | 5-7 red mana typical |

**Ritual support (artifacts):**
- Sol Ring, Arcane Signet, Fellwar Stone, Talisman of Conviction
- Ancient Tomb (sol land)

**Pattern:** The ramp curve follows a 3-stage progression:
1. **T1-T2:** Signets, Sol Ring, Land Tax, Weathered Wayfarer (land smoothing)
2. **T3-T4:** Storm-Kiln Artist, Smothering Tithe, Big Score, Jeska's Will (treasure generation begins)
3. **T5+:** Hit the Mother Lode, Brass's Bounty (explosive treasure bursts → cast 8+ CMC spells)

**Anti-Pattern:** Desperate Ritual and Seething Song were both cut in early cycles (C#3, C#6). Pure rituals without treasure synergy proved to be dead draws — the deck needs ramp that also draws cards (Big Score) or generates permanent value (Smothering Tithe), not single-shot red mana.

**Signal for App/Backend Logic:**
- Ramp cards should be scored not just by CMC but by **synergy depth**: treasure-generating ramp > ritual ramp > fetch-ramp in a spellslinger treasure deck.
- Deck without treasure generators should not score highly on "Explosive Mana" synergy axis.

---

## 3. Draw Patterns

### The Draw Gap

The deck has a **critical draw gap**: only 5 cards tagged as `functional_tag='draw'` in PostgreSQL, though actual effective draw is closer to 8 when including cards like Dance with Calamity, Valakut Awakening, and Weathered Wayfarer.

**Tagged Draw Sources:**

| Carta | CMC | Draw Output | Condition |
|:------|:---:|:------------|:----------|
| Faithless Looting | 1 | Draw 2, discard 2 (flashback: +2 more) | None |
| Windfall | 3 | Each player discards hand, draws equal to greatest discarded | Symmetrical (risky) |
| Valakut Awakening | 3 | Put any number of cards from hand on bottom, draw that many +1 | Hand reset |
| Dance with Calamity | 8 | Exile top N, cast any among them total CMC ≤ mana spent | Topdeck dependent |
| Dragon's Rage Channeler | 1 | Surveil 1 per upkeep (effectively draw smoothing) | Delirium conditional |

**Untagged but Functional Draw:**
| Carta | CMC | Mechanism |
|:------|:---:|:----------|
| Weathered Wayfarer | 1 | Land tutor (thins deck, improves draws) |
| Land Tax | 1 | 3 basics to hand per turn (deck thinning + hand size) |
| Sensei's Divining Top | 1 | Top 3 selection (draw smoothing) |
| Scroll Rack | 2 | Hand → top swap (virtual draw) |

**The Lorehold Looting Principle:**
Draw that puts cards in the graveyard is **superior** to pure draw in Lorehold. Every card discarded by Faithless Looting is a target for:
- Lorehold's triggered ability (cast from graveyard)
- Mizzix's Mastery overload (flashback ALL instants/sorceries)
- Arcane Bombardment (exile and copy each turn)
- Restoration Seminar (permanent recursion)

**Anti-Pattern:** The deck's 5 tagged draw cards place it at the bottom of the recommended range (8-12 per the Validator profile). The deck compensates with topdeck manipulation and treasure-based "free" spells that don't consume hand resources, but this makes the deck vulnerable to disruption — if the topdeck/manipulation engine is removed, the deck quickly runs out of gas.

**Signal for App/Backend Logic:**
- A deck's "effective draw" should be computed as: `tagged_draw + untagged_selection + graveyard_recursion_potential`
- Lorehold's draw efficiency multiplier should be >1.0 because graveyard-bound draws become recursion targets
- Draw count mismatch between DB tags and real sources should trigger a `tag_completeness` audit

---

## 4. Removal Patterns

### Spot Removal Suite (5 cards)

| Carta | CMC | Target | EDHREC% |
|:------|:---:|:-------|:-------:|
| Swords to Plowshares | 1 | Any creature (exile) | 69.0% |
| Path to Exile | 1 | Any creature (exile) | 57.4% |
| Abrade | 2 | Artifact or 3 damage | 9.9% |
| Chaos Warp | 3 | Any permanent (shuffle → flip) | 38.8% |
| Generous Gift | 3 | Any permanent (destroy → 3/3 elephant) | 32.4% |

### Board Wipes (5 cards)

| Carta | Effective CMC | Scope |
|:------|:-------------:|:------|
| Blasphemous Act | ~1 (reduction per creature) | All creatures: 13 damage |
| Austere Command | 6 | Modular: choose 2 modes |
| Call Forth the Tempest | 8 | Cascade + damage + board wipe hybrid |
| Worldfire | 9 | Total reset: exile all permanents, hands, graveyards; life=1 |
| Volcanic Vision | 7 | Return instant/sorcery + deal damage = CMC to all opp creatures |

**Pattern:** The removal suite follows a "low CMC spot removal for early threats, high CMC mass removal for mid-game stabilization" pattern. Blasphemous Act is the most efficient board wipe (often costing just R), while Volcanic Vision doubles as recursion.

**Anti-Pattern:** The deck's removal density is adequate (9 pieces) but removal is purely reactive. There's no proactive stax or tax effect (except Smothering Tithe which generates mana, not removal). Against go-wide strategies, the deck relies on drawing one of 5 board wipes. The BATTLE_LOG shows **Stall as the primary loss mode** (83-91 losses per 300 trials) — the deck runs out of board presence when removal can't keep pace with multiple threats per turn cycle.

**Signal for App/Backend Logic:**
- A `removal_to_threat_ratio` metric: if opponent deploys threats at rate X/turn and you have Y removal cards, can you sustain?
- Board wipe density below 5 in a non-creature-heavy deck should trigger a warning

---

## 5. Win Condition Patterns

### Wincon Scorecard (from card_deck_analysis)

| Carta | CMC | Total | Speed | Resilience | Stealth | EDHREC% | Category |
|:------|:---:|:-----:|:-----:|:----------:|:-------:|:-------:|:---------|
| Mizzix's Mastery | 4 | 16 | 4 | 6 | 6 | 57.4% | Wincon-enabler (GY flashback) |
| Rite of the Dragoncaller | 6 | 15 | 5 | 4 | 6 | N/A | Wincon (dragons per spell) |
| Worldfire | 9 | 14 | 2 | **7** | 5 | 7.3% | **RESILIENTE** ✅ |
| Apex of Power | 10 | 13 | 4 | 4 | 5 | 54.9% | Wincon-enabler (exile + mana) |
| Approach of the Second Sun | 7 | 12 | **6** | 5 | 1 | 63.8% | **RÁPIDA** ✅ |
| Call Forth the Tempest | 8 | 12 | 4 | 3 | 5 | 65.3% | Hybrid (wipe + cascade + damage) |
| Storm Herd | 10 | 9 | 3 | 3 | 3 | 75.0% | Combat wincon (token swarm) |

### Wincon Diversity Audit (from Wincon Diversity Oracle)

| Category | Threshold | Best Card | Score | Status |
|:---------|:---------:|:----------|:-----:|:------:|
| **RÁPIDA** | speed ≥ 6 | Approach of the Second Sun | speed=6 | ✅ COBERTA |
| **RESILIENTE** | resilience ≥ 7 | Worldfire | res=7 | ✅ COBERTA (⚠️ post-resolution gap) |
| **STEALTH** | stealth ≥ 7 | Mizzix's Mastery | stealth=6 | ❌ VAZIA — GAP crítico |

### Main Win Lines

**A) APPROACH + TOPDECK MANIPULATION (Primary — 63.8% EDHREC)**
```
Turn 7-9: Cast Approach of the Second Sun (goes 7 from top)
         → Manipulate top with Top/Scroll Rack/Penance
         → Cast Approach again → Win
```
- **With Flare of Duplication (NOT in deck):** Cast Approach → hold priority → Flare copy → Approach resolves, copy resolves → Win same turn. This eliminates the "ARQUI-INIMIGO" problem (stealth=1 → stealth effectively 7+ because it happens at instant speed with no warning).

**B) TWINFLAME + DUALCASTER MAGE (Stealth — NOT in deck)**
```
2RR + creature: Cast Twinflame targeting Dualcaster Mage
                → Dualcaster ETB trigger copies Twinflame
                → Loop: create hasty Dualcaster token → token ETB copies Twinflame → infinite
```
- CMC 4 total. Instant speed. Nobody expects infinite combo in Boros.
- **System blindspot:** card_deck_analysis gives Twinflame default 5/5/5 (never enriched as wincon).

**C) MIZZIX'S MASTERY OVERLOAD (GY Value)**
```
Turn 8-10: Overload Mizzix's Mastery (8 mana)
          → Exile all instants/sorceries from graveyard
          → Copy and cast each for free
          → Can chain Approach, Call Forth, Big Score, etc.
```

**D) STORM HERD + AKROMA'S WILL (Combat)**
```
Turn 9+: Cast Storm Herd (CMC 10) → X pegasus tokens (X = life, typically 35-40)
        → Next turn: Akroma's Will → double strike + flying + lifelink + vigilance
        → Attack with 35+ 2/2 flyers = lethal
```
- **Vulnerability:** Requires surviving one full turn cycle. Most fragile wincon (score=9).

**E) WORLDFIRE RESET (Resilient but Impractical)**
```
Turn 10+: Cast Worldfire (CMC 9) → exile everything, life=1, empty hands
         → Need wincon on stack or phased creature to close
```
- **Anti-Pattern:** Worldfire is RESILIENT (R=7, nearly impossible to interact with), but the deck has **no reliable plan to win after resolving it**. Simian Spirit Guide can provide R post-Worldfire but there's no spell in hand to cast (hands are exiled). This is a "symbolic wincon" — intimidating but rarely game-ending.

### Wincon Anti-Patterns Observed

1. **High-CMC bloat:** 3 wincons at CMC 9+ (Worldfire, Apex of Power, Storm Herd). These cards sit dead in hand for 7+ turns and contribute to the deck's elevated T3 rate (13.3% — defensive zone).

2. **Stealth vacuum:** No wincon with stealth ≥ 7 despite having viable stealth options in collection (Twinflame + Dualcaster). The system failed to classify these because Twinflame was never scored beyond default 5/5/5.

3. **Approach visibility:** Without Flare of Duplication, Approach has stealth=1 (everyone sees it coming). The 7-card gap gives opponents a full turn cycle to find an answer.

4. **Post-Worldfire gap:** A "resilient" wincon that can't actually close games is not a real wincon. Post-resolution closing needs to be scored as part of the wincon package.

### Signal for App/Backend Logic
- **Combo recognition:** `card_deck_analysis` should detect known combos from a combo-pattern table (e.g., Twinflame+Dualcaster, Approach+Flare) and adjust scores accordingly. Default 5/5/5 for combo pieces that have known deterministic win lines is a classification gap.
- **Wincon diversity score:** A deck should have coverage in all 3 axes (RAPIDA, RESILIENTE, STEALTH). Missing one axis → soft warning. Missing two → hard warning.
- **Post-resolution viability:** A wincon's resilience score should be weighted by whether the deck can actually close after resolving it. Worldfire's 7 resilience means nothing if the deck has 0 post-Worldfire win lines.

---

## 6. Copy Engine Synergy

The deck's engine stack is its true strength. With 5+ copy engines, any spell can become 3-4 copies:

| Engine | CMC | Mechanism | Reliability |
|:-------|:---:|:----------|:-----------:|
| Lorehold, the Historian | 6 | Trigger: cast from graveyard → copy | Commander (always accessible) |
| Double Vision | 5 | First sorcery each turn → copy | Enchantment (hard to remove) |
| Arcane Bombardment | 6 | Exile + copy 1 spell/turn from GY | Enchantment, cumulative |
| Primal Amulet // Primal Wellspring | 4 | Spell counter → flip → copy + mana | Artifact, 4 spells to flip |
| Dawning Archaic | 10 | Copy opponent's first spell each turn | Artifact (free value) |

**Engine multiplication example:**
```
Cast Big Score (4 mana) →
  Lorehold trigger: copy Big Score (free)
  Double Vision: copy Big Score (free)
  Arcane Bombardment: exile Big Score, copy it (free)
  Result: 1 Big Score → 3 copies = draw 6, create 6 treasures
```

With 2 additional engines available in collection but not in deck (Twinflame CMC 2, Flare of Duplication CMC 3), the engine count could reach 7 — a **9/10 synergy score** per SYNERGY_MAP.

---

## 7. Performance Metrics

### Mulligan Simulation (Exec#13, N=1000, seed=42, rigorous)

| Metric | Value | Threshold | Zone |
|:-------|:-----:|:---------:|:----:|
| **Sem Play T3** | **13.3%** | < 12% target | 🔴 DEFENSIVA |
| Mulligan rate | 30.1% | — | 🟡 Acceptable |
| Jogável | 66.0% | — | 🟢 Good |
| Ramp T1 (Sol Ring) | 8.5% | — | Baseline |
| Free Mulligan | 4.6% | — | Low |

### Battle Simulation (most recent: 2026-06-01T06:59, 4-player, 12 real opponents)

| Archetype | Win Rate | Δ vs Goldfish |
|:----------|:--------:|:-------------:|
| Overall | **47.7%** | — |
| vs. Derevi (control) | 56.0% | Favorable |
| vs. Lier (spellslinger) | 64.0% | Favorable |
| vs. Aragorn (midrange) | 64.0% | Favorable |
| vs. Tasigur (control) | 64.0% | Favorable |
| vs. Cloud (aggro) | 68.0% | Favorable |
| vs. Deadpool (midrange) | 72.0% | Favorable |

**6-archetype averaged matchup (2026-05-31): 52.1% WR** (range 46.5%-56.0%)
- Best: 56.0% vs Control (Atraxa Superfriends)
- Worst: 46.5% vs Combo (Kinnan cEDH)

**Goldfish win rate:** 17.8% (500 trials, avg turn 4.3) — low because goldfish win detection requires Approach cast twice, which takes 7+ turns in goldfish environment without opponents.

### Primary Loss Modes

| Loss Type | Frequency | Root Cause |
|:----------|:---------:|:-----------|
| **Stall** | 83-91/300 | Deck runs out of gas without drawing wincon or draw engine |
| **Threat** | 43-51/300 | Opponent deploys threats faster than deck draws removal |
| **Flood** | 2-7/300 | Minimal — mana base is solid |

---

## 8. Pipeline Integrity Crisis

### The Hash-Fake Incident (C#17-C#22)

**Timeline:**
1. **C#10 (2026-05-31):** Twinflame and Flare of Duplication added to deck via Evolution Oracle swaps
2. **C#17:** Deck state changes — Twinflame and Flare silently removed (manabase upgrade + card changes)
3. **C#18-C#22:** 5 consecutive Evolution Oracle cycles use hash `a440c497da4280d6769238737062b3dd` as "verified". All report "MATCH" and "0 swaps". Reality: hash is stale, deck has changed.
4. **SCOUT #34 (2026-06-01):** First agent to recompute hash from DB → discovers mismatch. Real hash: `30d00347764fc2a215edb4e668994871`
5. **MULLIGAN Exec#13:** Confirms T3 worsened from 11.3% to 13.3% (crossed defensive threshold) because Demand Answers (CMC 2) and Ashling (CMC 4) were lost in the reversion.

**Impact:** 5+ cycles operated with incorrect deck state. Swaps recommended and "applied" in Evolution Oracle logs were never actually written to PostgreSQL. 6+ agents (SCOUT #30-#33, VALIDATOR v3.17-v3.18, MULLIGAN verification) copied the stale hash without recomputing.

**Root Cause:** Agents trust the previous agent's hash instead of recomputing from `deck_cards WHERE deck_id=X` on each execution. This is a systemic trust-propagation bug.

---

## 9. Swap-Execution Gap

A persistent pattern across the last 3+ verification cycles: Evolution Oracle recommends swaps, documents them in EVOLUTION_LOG, but **swaps never get applied to PostgreSQL**.

**C#23 Swaps (documented 2026-06-01T08:23, still not applied as of 14:16):**
- OUT: Apex of Power (CMC 10) → IN: Demand Answers (CMC 2, draw)
- OUT: Storm Herd (CMC 10) → IN: Thrill of Possibility (CMC 2, draw)
- Net ΔCMC: -16
- Projected T3 improvement: 13.3% → ~9-10%

**C#10 Lost Cards (Lost during hash-fake, still not recovered):**
- Twinflame (CMC 2) — copy engine + combo piece
- Flare of Duplication (CMC 3) — free copy + Approach combo enabler

**MULLIGAN_LOG has flagged this 3 times consecutively** (09:26, 10:32, 14:16) with the same message: "O gargalo não é a qualidade do deck — é a execução dos swaps no DB."

---

## 10. Concrete Tasks

### Task 1: Pipeline Integrity — Agent Hash Verification Fix
- **Evidence:** Hash `a440c497...` was trusted by 6+ agents across 5+ cycles without recomputation. SCOUT #34 discovered the mismatch only by recomputing from DB. Two critical cards (Twinflame, Flare of Duplication) were silently lost from the deck.
- **What to change:** Every agent that reads a card hash from a previous agent's log must recompute `md5(sorted(card_names))` against `deck_cards WHERE deck_id=X` before declaring "MATCH". Trust no stored hash.
- **Impact:** Prevents silent card loss and ensures all agents operate on real deck state.
- **Risk:** Low — simply adding a recomputation step to existing integrity check.
- **Validation:** Next SCOUT execution should show hash computed fresh, with a new field `hash_source: 'db_computed'` vs `hash_source: 'log_copied'`.

### Task 2: Combo Recognition in card_deck_analysis
- **Evidence:** Twinflame (CMC 2) + Dualcaster Mage (CMC 3) = infinite hasty tokens, yet `card_deck_analysis` gives Twinflame default 5/5/5 score. Approach + Flare of Duplication = deterministic same-turn win, yet Flare isn't scored as wincon piece. Wincon Diversity Oracle confirmed STEALTH gap despite viable stealth combo in collection.
- **What to change:** Add a `combo_patterns` table or static config mapping card pairs to adjusted scores. When both cards exist in a deck, boost their stealth/resilience scores and tag them as `combo_piece`.
- **Impact:** Enables automatic detection of stealth wincons, closes classification gap.
- **Risk:** Medium — pattern matching needs to avoid false positives (e.g., Kiki-Jiki + Restoration Angel is a known combo in any deck with both, but Twinflame + Dualcaster is specific to spellslinger).
- **Validation:** After implementation, a deck scan with both Twinflame and Dualcaster should show Twinflame with stealth ≥ 7 and functional_tag='wincon_combo'.

### Task 3: Draw Tag Completeness Audit
- **Evidence:** Deck has 5 tagged draw cards in PostgreSQL (`functional_tag='draw'`) but ~7-8 real draw sources when including Weathered Wayfarer (land tutor → deck thinning), Land Tax (3 cards to hand), Sensei's Divining Top (selection), Scroll Rack (virtual draw), Valakut Awakening (hand reset tagged differently). This mismatch causes automated analysis to underestimate draw density by 40-60%.
- **What to change:** Create a periodic `tag_completeness` audit that compares DB tags against oracle text keyword scan for each deck. Cards with draw/selection mechanics but no draw tag should be flagged for manual review or auto-tagging.
- **Impact:** More accurate draw density metrics → better Evolution Oracle swap decisions.
- **Risk:** Low — read-only audit. No deck modifications.
- **Validation:** Audit report should identify Weathered Wayfarer, Land Tax, Top, Scroll Rack as "untagged draw sources" with recommendation to add `secondary_tag='draw_selection'` or similar.

### Task 4: Wincon Post-Resolution Viability Check
- **Evidence:** Worldfire has resilience=7 (IMBATÍVEL) but the deck has no reliable plan to win after resolving it. Hands are exiled, permanents are exiled, life is 1. The only post-Worldfire option is Simian Spirit Guide, but there's no spell to cast. Worldfire is a "symbolic wincon" — high resilience score but zero practical closing capability.
- **What to change:** Add a `post_resolution_viability` check for wincons that reset the game state. If a wincon exiles hands/graveyards/permanents, verify the deck has at least one way to close post-resolution (phasing, suspend, commander with haste, etc.).
- **Impact:** Prevents decks from relying on "resilient" wincons that can't actually win.
- **Risk:** Low — purely analytical. Does not modify deck or DB.
- **Validation:** Re-score Worldfire on this deck. Its effective resilience should drop from 7 to ~2-3 due to post-resolution failure. Flag as `viability_warning: true`.

### Task 5: Stealth Wincon Coverage Requirement
- **Evidence:** Wincon Diversity Oracle identified a persistent STEALTH gap (no wincon with stealth ≥ 7) across 23+ Evolution Oracle cycles. The deck's wincons are all highly visible: Approach (stealth=1, "ARQUI-INIMIGO"), Storm Herd (stealth=3), Worldfire (stealth=5). Meanwhile, a CMC 4 deterministic stealth combo (Twinflame + Dualcaster) exists in collection but was never scored properly.
- **What to change:** Add a `wincon_coverage` metric to the Validator profile requiring at least 1 wincon in each of the 3 axes (speed ≥ 6, resilience ≥ 7, stealth ≥ 7). Missing an axis triggers a `wincon_gap` alert with priority over incremental swaps.
- **Impact:** Ensures decks have diverse win conditions that can't all be answered by the same interaction type.
- **Risk:** Medium — changes the Validator scoring model. Needs testing on other deck archetypes to ensure it doesn't over-prioritize stealth in decks that don't need it (e.g., stax).
- **Validation:** After implementation, Lorehold's Validator report should flag "STEALTH_GAP: No wincon with stealth ≥ 7. Consider Twinflame (CMC 2, in collection) for Twinflame+Dualcaster combo."

---

## 11. Acquisition Wishlist (Not Yet in Collection)

| Priority | Card | CMC | Est. Cost | Why |
|:--------:|:-----|:---:|:---------:|:----|
| 1 | **Skullclamp** | 1 | $5-8 | Draw engine with token makers (Twinflame, Storm Herd, Rite, Call Forth). CMC 1. |
| 2 | **Underworld Breach** | 2 | $10-15 | Explosive GY recursion for spellslinger. Combo with Faithless Looting + rituals. |
| 3 | **Enlightened Tutor** | 1 | $15-20 | Tutor for Top, Scroll Rack, Arcane Bombardment, Skullclamp. |
| 4 | **Impact Tremors** | 2 | $3-5 | Pinger per ETB. With Twinflame infinite tokens = instant win. Fills stealth gap. |
| 5 | **Idyllic Tutor** | 3 | $15-20 | Tutor for Arcane Bombardment, Double Vision, Smothering Tithe. |

---

## 12. Key Signals for App/Backend Logic

| Signal | Source | What It Would Power |
|:-------|:-------|:--------------------|
| **Combo pair detection** | task #2 evidence | Auto-score combo pieces as wincons, fill stealth gap |
| **Draw tag completeness** | task #3 evidence | Accurate draw density → better mulligan projections |
| **Post-resolution viability** | task #4 evidence | Filter "fake resilient" wincons from recommendations |
| **Wincon axis coverage** | task #5 evidence | Prevent single-axis vulnerability in constructed decks |
| **Ramp synergy depth** | §2 pattern | Score treasure-ramp higher than ritual-ramp in spellslinger decks |
| **Hash integrity recomputation** | task #1 evidence | Pipeline trust — prevents silent state drift |
| **Swap execution verification** | §9 pattern | Cross-check Evolution Oracle logs against actual DB state to detect unapplied swaps |

---

## Appendix: Data Sources

| Source | Date Range | Records |
|:-------|:-----------|:-------|
| SCOUT_LOG | 2026-05-28 to 2026-06-01 | 35+ executions |
| EVOLUTION_LOG | 2026-05-28 to 2026-06-01 | 23+ cycles |
| BATTLE_LOG | 2026-05-30 to 2026-06-01 | 7 simulation runs (goldfish + matchup) |
| MULLIGAN_LOG | 2026-05-28 to 2026-06-01 | 13 executions |
| VALIDATOR_LOG | 2026-05-28 to 2026-06-01 | v3.5 through v3.21 |
| wincon-patterns.md | 2026-05-31 | 7 patterns documented |
| card_deck_analysis (PG) | 2026-06-01 | 1,495 entries across multiple decks |
| EDHREC JSON API | ~2026-05-31 | 7,851 decks snapshot (stable 36h+) |
| real-decklists.md | 2026-05-27 | 5 real Lorehold decks analyzed |
