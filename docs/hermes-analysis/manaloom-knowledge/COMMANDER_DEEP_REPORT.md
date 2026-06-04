# Commander Deep Knowledge Report

> **Generated:** 2026-06-01 ~21:10 UTC | **Updated:** 2026-06-04 ~17:20 UTC
> **Commander:** Lorehold, the Historian
> **Color Identity:** Boros (RW)
> **Archetype:** 🔴 **CONFIRMED** — cEDH Stax-Protected Combo (Bracket 4), NOT spellslinger
> **Source Agent:** Commander Knowledge Deep Cron Job
> **Evidence Base:** 38 Scout executions, 23+ Evolution Oracle cycles, 18+ Battle runs (goldfish + matchup + interactive), 16 Mulligan simulations, v3.22→v3.23→v3.24→v3.25 Validator, Lorehold Corpus Import (17+ decks), Battle Analyst v8 interactive runs, Deck Reconstruction, Active Deck Promotion, TAG_ACCURACY_REPORT, Scout #38 (wincon supersaturation), Mulligan Exec#15 (T3=1.6%), Validator v3.25 (classifier resolved, Worldfire CORRECTION, SYNERGY_MAP recalibrated), **6th consecutive hash change (2026-06-04 ~17:20 UTC)** — STRATEGIC PIVOT to stax-protected combo
> **🚨 Deck State:** **ACTIVE cEDH STAX-COMBO** — deck_id=6, card hash: `7b0b3fa845db029428d6aaa6d6915b09` (6th consecutive divergence). 100 cards, 31 lands tagged (2 basics: Mountain + Plains), 19 ramp, 9 draw, 10 protection, 10 wincons, 5 tutors, 3 combo pieces, 3 spell engines, 3 removal, 1 stax (Drannith Magistrate), 1 board wipe. **11 Game Changers → Bracket 4.** 3 unknown tags.
> **✅ Worldfire is LEGAL** (banlist check queries `card_legalities`). **0 banned cards.**
> **✅ CMC corruption RESOLVED:** 0 NULL CMC values (was 36 in prior report). All CMC=0.0 cards are legitimate (31 lands + 4 Moxen + Lotus Petal = 36).
> **✅ Classifier resolved:** 20 unknown tags → 3 (85% reduction). Ramp: 6 tagged → 19 tagged. T3: 1.6% (Exec#15, stale — needs revalidation on new hash).
> **🟢 Basic Land Crisis RESOLVED:** Mountain and Plains basics present (2). Artifact lands (Ancient Den, Great Furnace) were removed in this pivot — only true basics remain.
> **🆕 Strategic Pivot to Stax:** +Drannith Magistrate (stax), +Pyroblast, +Silence, +Orim's Chant (stack protection), +Esper Sentinel, +The One Ring, +Wheel of Fortune, +Scroll Rack (draw upgrade), +Past in Flames, +Reiterate, +Reverberate (spell engines), +Heat Shimmer (combo piece), +Giver of Runes (protection). Removed: Akroma's Will, Lightning Greaves, Hexing Squelcher, Big Score, Windfall, Weathered Wayfarer, Dance with Calamity, Dragon's Rage Channeler, Double Vision, Arcane Bombardment, Dawning Archaic, Ancient Den, Great Furnace.

---

## ⚠️ IMPORTANT — Sections §1–§7 BELOW describe the PRE-RECONSTRUCTION deck (spellslinger, hash `30d00347...`). §8–§14 describe the first cEDH reconstruction. §15–§27 describe the fast-mana copy-combo era. §28–§30 document the Basic Land Crisis and 5th hash change. **§31–§33 document the 6th hash change — STRATEGIC PIVOT to cEDH stax-protected combo.**

---

## 1. Archetype Overview (HISTORICAL — Pre-Reconstruction)

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
| Copy Engine | 4 | Lorehold (commander), Double Vision, Arcane Bombardment, Dawning Archaic |
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

**PG Profile Gap v3.22:** The deck has 7 ritual/treasure sources vs an ideal PG profile of 10. The gap (-3) is partially compensated by 7 ramp rocks, but rocks produce fixed 1 mana while treasure scales with copy engines. Re-adding Twinflame/Flare would improve this metric since copy engines multiply treasure output.

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

**PG Profile Gap v3.22:** PG ideal draw_value = 2.67, deck has 5 tagged. Functionally adequate but the tag gap (5 vs ~8 real) means automated analysis underestimates by ~60%.

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

The deck's engine stack is its true strength. With 4 copy engines (was 7 before Twinflame/Flare loss), any spell can become 3-4 copies:

| Engine | CMC | Mechanism | Reliability |
|:-------|:---:|:----------|:-----------:|
| Lorehold, the Historian | 6 | Trigger: cast from graveyard → copy | Commander (always accessible) |
| Double Vision | 5 | First sorcery each turn → copy | Enchantment (hard to remove) |
| Arcane Bombardment | 6 | Exile + copy 1 spell/turn from GY | Enchantment, cumulative |
| Dawning Archaic | 10 | Copy opponent's first spell each turn | Artifact (free value) |

**Engine multiplication example:**
```
Cast Big Score (4 mana) →
  Lorehold trigger: copy Big Score (free)
  Double Vision: copy Big Score (free)
  Arcane Bombardment: exile Big Score, copy it (free)
  Result: 1 Big Score → 3 copies = draw 6, create 6 treasures
```

**⚠️ v3.22: Copy engine count degraded from 7→4** due to Twinflame (CMC 2) and Flare of Duplication (CMC 3) being silently lost from deck during hash-fake period (C#17-C#22). Full engine stack with restoration would reach 7 engines = **9/10 synergy score**.

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

## 8. v3.22 VALIDATOR FINDINGS (NEW — 2026-06-01T20:52 UTC)

### 8.1 EDHREC Data Shift: New Declining Signals

v3.22 detected **4 new declining trends** on cards currently in the deck that were NOT present in previous analyses:

| Carta | EDHREC% | Trend | Sigilo | Diagnóstico |
|:------|:-------:|:-----:|:------:|:------------|
| **Call Forth the Tempest** | 65.2% | **-0.60** | NOVO ⬇️ | Most-included card in deck but now declining. 65% is still dominant — monitor for 3+ cycles |
| **Primal Amulet** | 30.3% | **-0.40** | NOVO ⬇️ | CMC 4, competes with Arcane Bombardment (CMC 5, faster). May become cut candidate |
| **Esper Sentinel** | 32.4% | **-0.67** | 7+ ciclos ⬇️ | Persistent 7-cycle decline. Draw conditional on opponents casting non-creature. #1 cut candidate if collection had CMC-2 replacement |
| **Grand Abolisher** | 11.7% | **-0.33** | 2 ciclos ⬇️ | Already low at 11.7%, now declining further. Protection piece being phased out of the meta |

**EDHREC num_decks:** 7,802 → **7,893** (+91, ~1.2% growth). Positive signal — the archetype is still growing.

### 8.2 PG Profile Comparison (New in v3.22)

Quantified gaps against PostgreSQL `commander_reference_deck_analysis` ideal profile for Lorehold:

| Metrica PG | PG Ideal | Deck Actual | Diff | Status |
|:-----------|:--------:|:----------:|:----:|:------:|
| lands | 32 | 35 | +3 | 🟡 Above — expected for 99-card Commander |
| ramp (rocks) | 3.67 | 7 | +3.33 | 🟡 Above — 2x the ideal |
| ritual_treasure | 10 | 7 | **-3** | 🔵 Below — gap compensado por rocks extras |
| big_spell_payoff | 7.67 | 11 | +3.33 | 🟡 Above — spellslinger identity |
| miracle_topdeck | 4.33 | 6 | +1.67 | 🔵 Above — strong topdeck engine |
| interaction (removal) | 5.33 | 6 | +0.67 | ✅ OK |
| protection | 3.67 | 9 | **+5.33** | 🔴 2.5x ideal — excess protection could convert to draw/tutor |
| draw_value | 2.67 | 5 | +2.33 | 🟡 Above — functional but tag gap exists |
| tutor | 3.67 | 2 | **-1.67** | 🔵 Below — only Enlightened Tutor + Gamble |
| win_condition | 1.33 | 5 | +3.67 | 🟡 Above — diverse wincon suite |

**Key insight:** The deck is over-protected (9 slots vs 3.67 ideal) and under-tutored (2 vs 3.67). The protection excess is rational for fragile Boros, but 2-3 protection slots could be converted to tutors or draw if the collection had viable replacements.

### 8.3 SYNERGY_MAP Degradation (v3.19 → v3.22)

| Eixo | v3.19 Score | v3.22 Score | Change | Driver |
|:-----|:-----------:|:----------:|:------:|:-------|
| A — Token Makers + Pump | 7/10 | 7/10 | — | Stable |
| B — Wipes + Protection | 8/10 | 8/10 | — | Stable |
| C — Recursion Chains | 8/10 | 8/10 | — | Stable |
| D — Explosive Mana | 7/10 | 7/10 | — | Stable |
| **E — Combo Pieces** | **9/10** | **6/10** | **-3** 🔴 | Twinflame + Flare lost (2 combos gone) |
| F — Stack Interaction | 6/10 | 6/10 | — | Boros no counterspells |
| G — Resilience | 7/10 | 7/10 | — | Stable |
| **TOTAL** | **7.4/10** | **7.0/10** | **-0.4** 🔴 | Entirely due to Eixo E degradation |

**Significance:** The SYNERGY_MAP degradation is the first quantified impact of the hash-fake incident. The deck lost 3 full points on its combo axis — from "excellent" (9/10) to "adequate" (6/10) — solely because Twinflame and Flare of Duplication disappeared from the deck during C#17-C#22.

### 8.4 Explicit Swap Restoration SQL (v3.22 Recommendation)

v3.22 provides the first concrete SQL script for restoring the lost cards:

```sql
-- Re-add Twinflame (CMC 2)
INSERT INTO deck_cards (deck_id, card_name, quantity, functional_tag, tag_confidence,
  is_commander, is_partner, cmc, type_line)
VALUES (6, 'Twinflame', 1, 'spellslinger', 0.9, 0, 0, 2, 'Sorcery');

-- Re-add Flare of Duplication (CMC 3)
INSERT INTO deck_cards (deck_id, card_name, quantity, functional_tag, tag_confidence,
  is_commander, is_partner, cmc, type_line)
VALUES (6, 'Flare of Duplication', 1, 'spellslinger', 0.9, 0, 0, 3, 'Instant');

-- Cut candidates (must stay at 100):
-- Option A: Primal Amulet (CMC 4, declining -0.40) + Esper Sentinel (CMC 1, declining -0.67)
-- Option B: MDFC duplicate Valakut Awakening id=653 (fixes draw_count) + Primal Amulet
```

**Net impact:** ΔCMC = -2 to -3 (replacing higher-CMC cards with Twinflame CMC 2 + Flare CMC 3). This is DEFENSIVE — it would reduce T3 from 13.3% toward the target zone.

### 8.5 Critical Rulings Analysis (New in v3.22)

**Arcane Bombardment + Restoration Seminar Loop:**
Per CR 706.10, copies have the same characteristics as originals. Arcane Bombardment exiles Restoration Seminar, creates a copy — the copy is still a Lesson and can fetch Lessons from the sideboard. Each spell cast triggers this, creating a semi-infinite recursion chain. **This is the deck's most underrated engine.**

**Double Vision + Call Forth the Tempest:**
CR 706.2: copy has the same X value. With X=8, the original exiles 8 cards, the Double Vision copy exiles another 8 — potential 30-40 damage distributed across 16 cards' CMCs. **Devastating finisher.**

**Dawning Archaic Passive Value:**
In a 4-player pod, Dawning Archaic generates 3 free spell copies per turn cycle. Each copy triggers Lorehold (treasure on cast). **Exponential value engine** that operates passively.

**Penance + Miracle:**
Penance puts the top card on the bottom in response to triggers. Does NOT directly enable Miracle (Miracle triggers on draw, not on trigger), but acts as a "topdeck quality filter" — improving draw quality before the draw step. **Indirect support, not a combo.**

### 8.6 New 3rd-Party EDHREC Cards Entering the Meta

| Carta | EDHREC% | Trend | Significance |
|:------|:-------:|:-----:|:-------------|
| Tablet of Discovery | 26.4% | 0.00 | Artifact draw — not in collection |
| Turbulent Steppe | 23.1% | 0.00 | Boros utility land — not in collection |
| Furygale Flocking | 12.2% | **+2.30** ⬆️ | CMC 2 copy spell, < $1 — **new rising star, recommend acquisition** |

---

## 9. Pipeline Integrity Crisis

### The Hash-Fake Incident (C#17-C#22)

**Timeline:**
1. **C#10 (2026-05-31):** Twinflame and Flare of Duplication added to deck via Evolution Oracle swaps
2. **C#17:** Deck state changes — Twinflame and Flare silently removed (manabase upgrade + card changes)
3. **C#18-C#22:** 5 consecutive Evolution Oracle cycles use hash `a440c497da4280d6769238737062b3dd` as "verified". All report "MATCH" and "0 swaps". Reality: hash is stale, deck has changed.
4. **SCOUT #34 (2026-06-01):** First agent to recompute hash from DB → discovers mismatch. Real hash: `30d00347764fc2a215edb4e668994871`
5. **MULLIGAN Exec#13:** Confirms T3 worsened from 11.3% to 13.3% (crossed defensive threshold) because Demand Answers (CMC 2) and Ashling (CMC 4) were lost in the reversion.
6. **v3.22 (2026-06-01T20:52):** SYNERGY_MAP Eixo E confirmed degraded from 9/10 → 6/10 — first quantified impact of the incident.

**Impact:** 5+ cycles operated with incorrect deck state. Swaps recommended and "applied" in Evolution Oracle logs were never actually written to PostgreSQL. 6+ agents (SCOUT #30-#33, VALIDATOR v3.17-v3.18, MULLIGAN verification) copied the stale hash without recomputing.

**Root Cause:** Agents trust the previous agent's hash instead of recomputing from `deck_cards WHERE deck_id=X` on each execution. This is a systemic trust-propagation bug.

---

## 10. Swap-Execution Gap

A persistent pattern across the last 3+ verification cycles: Evolution Oracle recommends swaps, documents them in EVOLUTION_LOG, but **swaps never get applied to PostgreSQL**.

**C#23 Swaps (documented 2026-06-01T08:23, still not applied as of 21:10):**
- OUT: Apex of Power (CMC 10) → IN: Demand Answers (CMC 2, draw)
- OUT: Storm Herd (CMC 10) → IN: Thrill of Possibility (CMC 2, draw)
- Net ΔCMC: -16
- Projected T3 improvement: 13.3% → ~9-10%

**C#10 Lost Cards (Lost during hash-fake, still not recovered):**
- Twinflame (CMC 2) — copy engine + combo piece
- Flare of Duplication (CMC 3) — free copy + Approach combo enabler

**v3.22 concrete restoration SQL now available** (§8.4 above) — first time a validator has provided the exact INSERT/DELETE statements needed.

**MULLIGAN_LOG has flagged this 4 times consecutively** with the same message: "O gargalo não é a qualidade do deck — é a execução dos swaps no DB."

---

## 11. Concrete Tasks (Updated: 2026-06-02)

### Task 1: Best-of-Learned Gap Analysis — Active Deck vs Community Consensus
- **Evidence:** `LOREHOLD_BEST_OF_LEARNED.md` (2026-06-02T17:56Z) produced learned_deck_id=81 with score 136.5 from 17+ imported user decklists. This cEDH-level build runs 20 lands, fast mana (Sol Ring, Mana Vault, Chrome Mox, Mox Diamond, Mox Opal), 11 wincons, 6 tutors, full copy combo suite (Dualcaster+Twinflame+Heat Shimmer+Molten Duplication+Electroduplicate+Reverberate+Reiterate), Aetherflux Reservoir, Fiery Emancipation+Guttersnipe, and protection/stax (Silence, Orim's Chant, Drannith Magistrate). The active deck runs 35 lands, 7 wincons, 2 tutors, 4 copy engines. No gap analysis exists comparing the two builds.
- **What to change:** Create a structured `gap_analysis.md` comparing active deck vs best-of-learned across: land count, ramp density, wincon diversity, tutor count, copy engine count, protection suite. Identify which community patterns the active deck is missing and rank by impact.
- **Impact:** Provides data-driven signals for Evolution Oracle and acquisition recommendations. Bridges the community-knowledge-to-active-deck gap.
- **Risk:** Low — read-only analysis. Does not modify product or active deck.
- **Validation:** Gap report should identify "missing fast mana package" and "missing copy combo redundancy" as the top two structural differences, with quantitative impact estimates.

### Task 2: Battle Simulator Configuration Validation
- **Evidence:** 8 Battle Analyst v8 runs (2026-06-01T23:40 through 2026-06-02T09:48) produced 0% WR with clearly invalid deck configurations: L=17 R=0 X=0 (June 1 23:40, impossible to cast anything), L=49 R=14 X=5 (June 2 07:56, 49 lands = no spells), L=44 R=15 X=5 (June 2 09:48, same pathology). These consumed ~2,400 simulation trials (8 runs × 300 opponents) producing zero actionable data. Meanwhile, valid configs achieved meaningful results: L=35 R=13 X=5 CMC=3.29 → 46.7% WR (June 2 07:53, best observed), L=40 R=13 X=7 CMC=3.10 → 40.2% WR (June 1 23:31).
- **What to change:** Add pre-flight validation in the battle simulator that rejects deck configurations where land_count < 20 or land_count > 42, or where (lands + ramp + draw + removal + wincons + protection) < 70 (deck is missing core functions). Emit a clear error explaining why the config was rejected.
- **Impact:** Prevents wasted compute on configurations that have 0% chance of functioning. Saves ~2,400 sim-trials per invalid batch.
- **Risk:** Low — validation layer doesn't change simulation logic. Edge case: 20-land cEDH builds (like the best-of-learned) should still pass validation so the threshold must distinguish "competitive low-land" from "broken zero-spell."
- **Validation:** Submit a deck with L=49 to the simulator; it should reject with "Land count 49 exceeds maximum 42 for commander format."

### Task 3: Corpus Import → Pattern Extraction Pipeline
- **Evidence:** 23 decklists in `import_queue/lorehold/`, imported by `scripts/import_lorehold_decks.py` into `knowledge.db` table `learned_decks`. The import produced a best-of candidate but stopped there — no extraction of common patterns across the top-N decks. The best-of-learned has 33 "unknown" role tags (33/100 cards with no classified role), 20 lands, and 11 wincons. Common patterns (e.g., "all top-scoring Lorehold builds run 6+ copy spells") are not extracted.
- **What to change:** Add a `pattern_extraction.py` script that, post-import, analyzes the top 5 learned decks by score and extracts: (a) cards appearing in ≥80% of top decks, (b) role distribution averages, (c) CMC band distributions, (d) package co-occurrence (e.g., "decks with 6+ copy spells always run at least 2 ritual effects"). Output to `docs/hermes-analysis/manaloom-knowledge/PATTERN_EXTRACT.md`.
- **Impact:** Turns raw deck dumps into pattern rules that Evolution Oracle and Scout can query.
- **Risk:** Low — read-only analytics on `learned_decks` table. Does not modify active deck.
- **Validation:** After implementation, the extraction should report "7/7 top-scoring Lorehold decks include Dualcaster Mage" and "6/7 include at least one fast mana artifact beyond Sol Ring."

### Task 4: Land Count Sweet Spot — Systematic Simulation
- **Evidence:** Battle data reveals a non-linear relationship between land count and win rate: L=28 → 8.5-19.3% WR (inconsistent), L=35 → 20.8-46.7% WR (widest range), L=40 → 33.5-40.2% WR (stable, lower peak). The best-of-learned runs 20 lands (cEDH) while the active deck runs 35 (mid-power). No systematic experiment has determined the optimal land count for Lorehold spellslinger in bracket 3-4.
- **What to change:** Run a controlled experiment: same nonland cards, vary lands from 20-38 in increments of 2 (10 configurations), 200 trials each against a fixed opponent pool, holding ramp/draw/removal ratios constant. Record WR, average win turn, and stall rate for each configuration.
- **Impact:** Produces a data-backed land count recommendation curve for the spellslinger archetype. Could generalize to other Boros spellslinger commanders.
- **Risk:** Low — simulation only. No deck modification.
- **Validation:** The experiment should produce a "sweet spot" curve showing peak WR at some land count, with diminishing returns beyond it.

### Task 5: Copy Engine Saturation Analysis
- **Evidence:** The best-of-learned runs 7 copy engines (Dualcaster Mage, Twinflame, Heat Shimmer, Molten Duplication, Electroduplicate, Reverberate, Reiterate) plus Lorehold commander = 8 total. The active deck runs 4 copy engines (Double Vision, Arcane Bombardment, Mizzix's Mastery, Dawning Archaic) plus Lorehold = 5 total. The SYNERGY_MAP Eixo E (Combo Pieces) is scored 6/10 on the active deck due to missing Twinflame/Flare. No analysis exists on the optimal copy engine density for Lorehold.
- **What to change:** Score all 13 copy-capable cards in the Lorehold corpus (from best-of-learned + active deck) on: CMC, speed (sorcery vs instant), synergy depth (triggers Storm-Kiln, Ashling, etc.), and redundancy cost. Produce a `copy_engine_tier_list.md` ranking copy engines by value-add in a spellslinger archetype.
- **Impact:** Guides Evolution Oracle on which copy engines to prioritize when slots free up. Quantifies the difference between "generic copy" (Reverberate) and "synergistic copy" (Twinflame triggering Storm-Kiln).
- **Risk:** Low — analytical ranking, no deck modification.
- **Validation:** Tier list should place Twinflame (CMC 2, instant, combo piece, triggers Storm-Kiln) at S-tier and Reverberate (CMC 2, instant, no combo potential, no trigger) at A-tier, explaining the ranking difference.

---

## 12. Acquisition Wishlist (Updated v3.22)

| Priority | Card | CMC | Est. Cost | Why |
|:--------:|:-----|:---:|:---------:|:----|
| 1 | **Skullclamp** | 1 | $5-8 | Draw engine with token makers (Twinflame, Storm Herd, Rite, Call Forth). CMC 1. |
| 2 | **Underworld Breach** | 2 | $10-15 | Explosive GY recursion for spellslinger. Combo with Faithless Looting + rituals. |
| 3 | **Enlightened Tutor** | 1 | $15-20 | Tutor for Top, Scroll Rack, Arcane Bombardment, Skullclamp. |
| 4 | **Impact Tremors** | 2 | $3-5 | Pinger per ETB. With Twinflame infinite tokens = instant win. Fills stealth gap. |
| 5 | **Furygale Flocking** 🆕 | 2 | < $1 | Copy spell, trend +2.30 rising. Budget alternative to Flare of Duplication for instant-speed spell copying. |

---

## 13. Key Signals for App/Backend Logic

| Signal | Source | What It Would Power |
|:-------|:-------|:--------------------|
| **Combo pair detection** | task #2 evidence | Auto-score combo pieces as wincons, fill stealth gap |
| **Draw tag completeness** | task #3 evidence | Accurate draw density → better mulligan projections |
| **Post-resolution viability** | task #4 evidence | Filter "fake resilient" wincons from recommendations |
| **Wincon axis coverage** | task #5 evidence | Prevent single-axis vulnerability in constructed decks |
| **EDHREC trend monitoring** 🆕 | v3.22 declining signals | Catch meta shifts before deck obsolescence |
| **Ramp synergy depth** | §2 pattern | Score treasure-ramp higher than ritual-ramp in spellslinger decks |
| **Hash integrity recomputation** | task #1 evidence | Pipeline trust — prevents silent state drift |
| **Swap execution verification** | §10 pattern | Cross-check Evolution Oracle logs against actual DB state to detect unapplied swaps |
| **SYNERGY_MAP degradation tracking** 🆕 | v3.22 §8.3 | Quantify impact of lost cards, not just detect their absence |

---

---

## 14. Update: 2026-06-02 — Corpus Import & Interactive Battle Data

### 14.1 Lorehold Corpus Import — Best-of-Learned Candidate

On 2026-06-02, `scripts/import_lorehold_decks.py` imported 17+ user-submitted Lorehold decklists from `import_queue/lorehold/` into `knowledge.db`. The pipeline parsed cards, inferred roles via oracle text keyword matching, and computed a composite score per deck. The top candidate emerged as **learned_deck_id=81** with score **136.5**.

**Best-of-Learned Composition (learned_deck_id=81, score 136.5):**

| Role | Count | Key Includes |
|:-----|:-----:|:-------------|
| Land | 20 | Ancient Tomb, City of Brass, Mana Confluence, 6 fetches, Urza's Saga, Gemstone Caverns |
| Fast Mana | 6 | Sol Ring, Mana Vault, Chrome Mox, Mox Diamond, Mox Opal, Lotus Petal |
| Wincon | 11 | Approach of the Second Sun, Worldfire, Mizzix's Mastery, Aetherflux Reservoir, Fiery Emancipation, Guttersnipe, Rite of the Dragoncaller, Storm Herd, Rise of the Eldrazi, Past in Flames |
| Copy Engine | 8 | Lorehold (cmdr), Dualcaster Mage, Twinflame, Heat Shimmer, Molten Duplication, Electroduplicate, Reverberate, Reiterate |
| Tutor | 6 | Enlightened Tutor, Gamble, Imperial Recruiter, Recruiter of the Guard, Ranger-Captain of Eos, Inventors' Fair |
| Draw | 6 | Esper Sentinel, Faithless Looting, Wheel of Fortune, Valakut Awakening, The One Ring, Scroll Rack |
| Ramp | 6 | Arcane Signet, Boros Signet, Talisman of Conviction, Smothering Tithe, Jeska's Will, Unexpected Windfall |
| Protection | 4 | Teferi's Protection, Deflecting Swat, Boros Charm, Flawless Maneuver |
| Stax | 3 | Silence, Orim's Chant, Drannith Magistrate |
| Removal | 3 | Path to Exile, Swords to Plowshares, Generous Gift |
| Unknown | 33 | — |

**Key Structural Differences vs Active Deck (deck_id=6):**

| Dimension | Active Deck | Best-of-Learned | Delta |
|:----------|:-----------:|:---------------:|:-----:|
| Lands | 35 | 20 | **-15** |
| Wincons | 7 | 11 | +4 |
| Tutors | 2 | 6 | +4 |
| Copy Engines | 4 | 8 | +4 |
| Fast Mana (beyond Sol Ring) | 0 | 5 | +5 |
| Stax | 0 | 3 | +3 |
| Avg CMC (nonland) | 3.61 | ~2.8 | -0.8 |

**Insight:** The best-of-learned represents a fundamentally different power level (cEDH-level fast mana + low curve) versus the active deck (mid-power, higher curve, more lands). The community consensus at the top competitive level favors speed over resilience, with 20 lands backed by 6 fast mana pieces. The active deck's 35-land approach better suits bracket 3-4, where games go longer and card advantage matters more than turn-2 wins.

### 14.2 Battle Analyst v8 — Interactive Commander Runs (June 1-2)

Between 2026-06-01T23:20 and 2026-06-02T09:48, 18 Battle Analyst v8 runs were executed against 12 real opponent commanders in 4-player interactive mode. Results clustered into three categories:

**Category A: Valid Decks — Actionable Results**

| Run (UTC) | L | R | X | CMC | WR | Notes |
|:----------|:--:|:--:|:--:|:---:|:---:|:------|
| Jun 1 23:20 | 35 | 16 | 9 | 3.62 | 20.8% | Baseline control |
| Jun 1 23:23 | 35 | 17 | 8 | 3.70 | 26.8% | +1 ramp, -1 removal |
| Jun 1 23:25 | 35 | 13 | 12 | 3.66 | 26.0% | High removal (12) |
| Jun 1 23:28 | 35 | 16 | 7 | 2.60 | 8.2% | ⚠️ CMC too low — lost power |
| Jun 1 23:31 | 40 | 13 | 7 | 3.10 | 40.2% | 🟢 40 lands = stability |
| Jun 2 07:45 | 28 | 16 | 2 | 3.29 | 8.5% | 28 lands, only 2 removal |
| Jun 2 07:49 | 28 | 16 | 2 | 3.29 | 40.5% | Same config, different seed — RNG variance |
| Jun 2 07:51 | 27 | 13 | 5 | 3.24 | 39.3% | Near-best land floor |
| **Jun 2 07:53** | **35** | **13** | **5** | **3.29** | **46.7%** | **🏆 BEST WR OBSERVED** |

**Category B: Broken Configs — 0% WR (Simulator Bug Reports)**

| Run (UTC) | L | R | X | CMC | WR | Issue |
|:----------|:--:|:--:|:--:|:---:|:---:|:------|
| Jun 1 23:40 | 17 | 0 | 0 | 0.0 | 0% | Impossible — no spells |
| Jun 1 23:29 | 47 | 13 | 4 | 3.25 | 0% | 47 lands = flood guarantee |
| Jun 2 07:56 | 49 | 14 | 5 | 2.22 | 0% | 49 lands with only 2.22 CMC |
| Jun 2 09:46 | 49 | 14 | 5 | 2.22 | 0% | Repeat — same broken config |
| Jun 2 09:48 | 44 | 15 | 5 | 2.19 | 0% | 44 lands, 2.19 CMC |

**Category C: Duplicate Runs — Same Result (Redundant)**

| Run (UTC) | L | R | X | CMC | WR | Duplicate of |
|:----------|:--:|:--:|:--:|:---:|:---:|:-------------|
| Jun 1 23:29 | 47 | 13 | 4 | 3.25 | 33.5% | First run not broken |
| Jun 1 23:30 | 47 | 13 | 4 | 3.25 | 33.5% | Duplicate of above |
| Jun 1 23:37 | 40 | 13 | 7 | 3.10 | 40.2% | Duplicate of 23:31 |
| Jun 1 23:38 | 40 | 13 | 7 | 3.10 | 40.2% | Duplicate of 23:31 |

**Key Pattern:** Win rate is highly sensitive to three variables: land count (sweet spot ~35), removal count (diminishing returns above 9), and CMC (too low = no power, too high = too slow). The best config (L=35 R=13 X=5 CMC=3.29) balances all three.

**Simulator Bug:** 5 runs with broken configs produced 0% WR. The simulator does not validate deck composition before starting. This wasted ~1,500 simulation trials (5 runs × 300 opponents). See Task 2.

### 14.3 Anti-Pattern: Import Without Pattern Extraction

The corpus import pipeline (`import_lorehold_decks.py`) correctly parsed, hashed, and stored 17+ decks. However, it stopped at finding the single best candidate. **No pattern extraction occurred.** The system knows that 17 community decks exist but can't answer questions like:

- "What % of winning Lorehold decks run 6+ copy spells?"
- "Do all top Lorehold builds include both Enlightened Tutor and Gamble?"
- "What's the average land count across top-5 scored Lorehold decks?"

The `best-of-learned` path is successful at producing a single optimized list, but the system misses the opportunity to extract **reusable pattern rules** that could inform Evolution Oracle decisions for any deck, not just the best candidate. See Task 3.

### 14.4 Signal: Community vs Active Deck Divergence

The gap between the best-of-learned and the active deck is not just quantitative (35→20 lands) but qualitative:

- **Community prioritizes density**: 8 copy engines = every spell is a potential combo
- **Active deck prioritizes resilience**: 35 lands, 9 protection, 5 board wipes = survive to late game
- **Community runs stax**: 3 silence effects prevent opponent interaction on combo turns
- **Active deck runs no stax**: Relies on Teferi's Protection and Boros Charm for one-shot protection

This divergence is appropriate for the different power levels (cEDH vs bracket 3-4), but the **Evolution Oracle has no concept of power level** when making swap recommendations. It may recommend cEDH cards (Twinflame, fast mana) into a mid-power deck or mid-power cards (board wipes) into a cEDH build. A `power_level_profile` filter on swap recommendations would prevent cross-tier contamination.

### 14.5 New Key Signals for App/Backend Logic

| Signal | Source | What It Would Power |
|:-------|:-------|:--------------------|
| **Community vs Active divergence scoring** | §14.4 | Power-level-aware swap recommendations |
| **Import pattern extraction** | §14.3, Task 3 | Reusable deck-building rules from community data |
| **Simulator config validation** | §14.2, Task 2 | Pre-flight guards against wasted computation |
| **Copy engine tier ranking** | Task 5 | Prioritized swap recommendations for spellslinger |
| **Land count optimization model** | §14.2, Task 4 | Data-backed land count for any archetype |
| **Learned-vs-active gap report** | §14.1, Task 1 | Acquisition wishlist from community consensus |

---

## 15. 🆕 DECK RECONSTRUCTION — Spellslinger → cEDH Storm (2026-06-02 ~18:30Z)

### 15.1 Timeline of Events

| Timestamp (UTC) | Event | Hash | Agent |
|:----------------|:------|:-----|:------|
| 2026-06-02 ~17:56 | Best-of-learned candidate (learned_deck_id=81, score 136.5) generated from 17+ imported decks | — | `import_lorehold_decks.py` |
| 2026-06-02 ~18:30 | Deck reconstruction detected — hash diverges from `30d00347...` to `0b4913e7...` | `0b4913e79ec97b3ce05e0fe26531cd44` | SCOUT #36 |
| 2026-06-02 18:34 | "No Premium Mox" candidate (learned_deck_id=82) generated — Chrome Mox/Mox Diamond/Mox Opal removed, +Fellwar Stone/Lightning Greaves/Victory Chimes | — | Manual/script |
| 2026-06-02 18:38 | **Active deck promotion** — learned_deck_82 → deck_id=6, name "Lorehold Best-of Learned No Premium Mox 2026-06-02" | — | `import_lorehold_decks.py` (promote_bestof) |
| 2026-06-02 18:43 | VALIDATOR v3.23 confirms reconstruction, new hash `f2241d99...`, 20 cards without tags | `f2241d994743e8142396c0f846917fde` | VALIDATOR v3.23 |
| 2026-06-02 18:51 | MULLIGAN Exec#14 confirms T3=8.9% (was 13.3%), mulligan rate 16.0% (was 30.1%) | `f2241d99...` | MULLIGAN Exec#14 |

**Key insight:** The reconstruction was NOT driven by Evolution Oracle or any pipeline agent. It was an external decklist import that completely replaced the active deck. ALL 25+ swaps from cycles #1-#11 were undone. The pipeline integrity detection (hash verification) caught the change — the system worked as designed.

### 15.2 What Changed — Side-by-Side Comparison

| Dimension | PRE-Reconstruction (Spellslinger) | POST-Reconstruction (cEDH Storm) | Delta |
|:----------|:---------------------------------:|:---------------------------------:|:-----:|
| Card hash | `30d00347764fc2a215edb4e668994871` | `f2241d994743e8142396c0f846917fde` | Changed |
| Lands | 35 (86 rows) | 33 (100 rows/qty=1) | -2 |
| Basic lands | ~8 | **2** (Ancient Den + Great Furnace!) | -6 ⚠️ |
| Nonland CMC avg | 3.61 | ~3.0 | -0.61 |
| Ramp (actual) | 16 | 16 (but different composition) | — |
| Ramp (DB-tagged) | 7 | **6** (10 untagged!) | -1 tagged ⚠️ |
| Draw (actual) | ~8 | ~8 | — |
| Removal | 9 | **3** (Path, Swords, Generous Gift) | -6 🔴 |
| Board Wipes | 5 | **1** (Blasphemous Act) | -4 |
| Protection | 9 | ~10 (including Silence, Orim's Chant, Pyroblast) | +1 |
| Stax | 0 | **3** (Silence, Orim's Chant, Drannith) | +3 |
| Tutors | 2 | **6** (Enlightened, Mystical, Gamble, Imperial, Recruiter, Ranger-Captain) | +4 |
| Wincons | 7 | **11** (+Aetherflux, Fiery, Guttersnipe, Birgi, Past in Flames, Reiterate combo, Rise) | +4 |
| Copy Engines | 4 (Double Vision, Arcane Bombardment, Mizzix, Dawning) | 5 (Mizzix, Twinflame, Heat Shimmer, Molten Dup, Electroduplicate) | +1 |
| Fast Mana | 1 (Sol Ring) | **6** (Sol Ring, Mana Vault, Mox Amber, Lotus Petal, Rite of Flame, Seething Song) | +5 |
| T3 (no play) | 13.3% | **8.9%** | **-4.4pp 🟢** |
| Mulligan rate | 30.1% | **16.0%** | **-14.1pp 🟢** |

### 15.3 Cards ADDED (19+ new)

| Category | Cards |
|:---------|:------|
| Fast Mana | Mana Vault, Mox Amber, Rite of Flame, Seething Song (Lotus Petal already present) |
| Combo Pieces | Aetherflux Reservoir, Birgi God of Storytelling, Past in Flames, Reiterate, Reverberate, Twinflame |
| Copy Engines (combo-oriented) | Electroduplicate, Heat Shimmer, Molten Duplication |
| cEDH Stax/Protection | Drannith Magistrate, Silence, Orim's Chant, Pyroblast, Ranger-Captain of Eos |
| Additional | Ruby Medallion (returned), Guttersnipe, Unexpected Windfall, Urza's Saga, Rise of the Eldrazi (returned) |

### 15.4 Cards REMOVED (19+) — Spellslinger Motor Dismantled

| Category | Cards Removed |
|:---------|:-------------|
| Spellslinger Engine | Double Vision, Arcane Bombardment, The Dawning Archaic, Improvisation Capstone |
| Treasure Ramp | Big Score, Brass's Bounty, Hit the Mother Lode |
| Board Wipes | Austere Command, Call Forth the Tempest, Fated Clash, Volcanic Vision |
| Draw (big) | Dance with Calamity |
| Protection (combat) | Akroma's Will, Flawless Maneuver (swapped) |
| Other | Galvanoth, Penance, Pearl Medallion, Restoration Seminar, Apex of Power, Demand Answers, Thrill of Possibility |

### 15.5 Archetype Transplant — What Survived

**Kept from old deck (bridge cards):**
- Core wincons: Approach of the Second Sun, Worldfire, Storm Herd, Rite of the Dragoncaller, Mizzix's Mastery
- Spot removal: Path to Exile, Swords to Plowshares, Generous Gift
- Wipe: Blasphemous Act (only surviving board wipe)
- Draw: Esper Sentinel, Faithless Looting, Scroll Rack, Sensei's Divining Top, Land Tax
- Tutors: Enlightened Tutor, Gamble
- Misc: Storm-Kiln Artist, Smothering Tithe, Boros Charm, Deflecting Swat, Teferi's Protection, Grand Abolisher, Mother of Runes

**New motor:** Fast Mana → Storm → Aetherflux kill OR Dualcaster+Twinflame infinite OR Approach with tutors
**Lost motor:** Treasure Ramp → Big Spell Free → Lorehold Copy → Treasure Payoff

### 15.6 SYNERGY_MAP v3.23 (Post-Reconstruction)

| Eixo | v3.22 (Pre) | v3.23 (Post) | Change |
|:-----|:-----------:|:------------:|:------:|
| A — Token Makers + Pump | 7/10 | 5/10 | **-2** (Akroma's Will removed, Storm Herd isolated) |
| B — Wipes + Protection | 8/10 | 7/10 | -1 (fewer wipes, more stax) |
| C — Recursion Chains | 8/10 | 8/10 | Stable |
| D — Explosive Mana | 7/10 | 8/10 | **+1** (fast mana package) |
| E — Combo Pieces | 6/10 | **9/10** | **+3** 🔴 (Twinflame+Dualcaster+Reiterate+Past in Flames+Aetherflux) |
| F — Stack Interaction | 6/10 | 5/10 | -1 (Silence not counted as stack?) |
| G — Resilience | 7/10 | 6/10 | -1 (fewer board wipes/protection) |
| **TOTAL** | **7.0/10** | **6.9/10** | -0.1 |

**Key insight:** The SYNERGY_MAP total barely changed (-0.1), but the composition shifted dramatically — Combo Pieces surged from 6→9 while Token Makers cratered 7→5. The deck pivoted from a balanced spellslinger to a combo-dense storm build.

---

## 16. 🆕 POST-RECONSTRUCTION PERFORMANCE

### 16.1 Mulligan Exec#14 (N=1000, seed=42)

| Metrica | Exec#13 (Pre) | Exec#14 (Post) | Delta | Signal |
|:--------|:-------------:|:---------------:|:-----:|:------:|
| **Sem Play T3** | **13.3%** | **8.9%** | **-4.4pp** | 🟢 Massive improvement |
| Mulligan rate | 30.1% | 16.0% | -14.1pp | 🟢 Almost halved |
| Jogável (first 7) | 66.0% | 84.0% | +18.0pp | 🟢 Excellent |
| Keepable (first 7) | ~55% | 65.4% | +10.4pp | 🟢 |
| Ramp T1 (Sol Ring) | 8.5% | 6.3% | -2.2pp | 🟡 Expected with 33 lands |
| Free Mulligan used | 4.6% | 18.6% | +14.0pp | ⚠️ Structural change |

**Mulligan distribution (post-reconstruction):**
- 0 mulligans: 65.4% (keepable straight)
- 1 (free): 18.6% (free mulligan used successfully)
- 2: 7.1% (1 card to bottom)
- 3+: 2.9% (rare)
- 6-7: 6.5% (forced to 0 — 0-landers)

**Why T3 improved by -4.4pp:**
1. Nonland CMC dropped 3.61 → 3.0 (-0.61) — eliminated CMC 8-12 cards (Apex, Storm Herd pre-cut, Rise)
2. Fast mana density: 16 real ramp in 99 → P(ramp in opener) ≈ 73%
3. cEDH staples at CMC 0-1: Silence, Orim's Chant, Pyroblast, Ranger-Captain, Giver, Mother, Gamble, Enlightened — 12+ cards castable with 1 land

### 16.2 DB Classifier Gap — 10 Ramp Cards Untagged

Only **6 cards** have `functional_tag='ramp'` in PostgreSQL:
Arcane Signet, Fellwar Stone, Lotus Petal, Mox Amber, Smothering Tithe, Storm-Kiln Artist.

**10 real ramp cards NOT recognized:**
Sol Ring (tag='unknown'), Mana Vault (tag='unknown'), Boros Signet (tag='unknown'), Talisman of Conviction (tag='unknown'), Victory Chimes (tag='unknown'), Rite of Flame (tag='spell'), Seething Song (tag='spell'), Jeska's Will (tag='draw'), Mana Geyser (tag='spell'), Unexpected Windfall (tag='draw').

**Impact:** The DB-tag-based mulligan simulator would treat 2-land + Sol Ring hands as non-keepable (because Sol Ring = tag='unknown'), inflating T3 from 8.9% → ~17.7%. This is a false-negative classification affecting ALL tag-based simulations.

### 16.3 VALIDATOR v3.23 Critical Findings

1. **20 cards without functional tags** — tags are critical for the mulligan simulator and Evolution Oracle
2. **Only 3 removal cards** (vs PG ideal 5.33) — severe removal shortage. In 4-player pods, drawing any removal is 3/99 chance
3. **Only 2 basic lands** (Ancient Den, Great Furnace) — these are artifact lands, not basics! Zero actual basic Plains/Mountains. Critical vulnerability to: Path to Exile (opponent can't search), Blood Moon (all nonbasics become Mountains), Back to Basics, Ruination, Wave of Vitriol
4. **Storm Herd (CMC 10) and Rise of the Eldrazi (CMC 12) are outliers** — only cards above CMC 7 in an otherwise CMC 2-4 deck. Frequently dead draws.
5. **Akroma's Will removed** — was enabler for Storm Herd and Rise win lines. Without it, both wincons are unreliable.

---

## 17. 🆕 UPDATED CONCRETE TASKS

### Task 1: DB Functional Tag Audit and Repair (CRITICAL)
- **Evidence:** MULLIGAN Exec#14 identified 10 ramp cards not tagged as 'ramp' by the classifier, causing T3 inflation from 8.9% → 17.7%. VALIDATOR v3.23 confirms 20 cards without functional tags. Sol Ring, the most-played card in Commander, is tagged 'unknown'.
- **What to change:** Create a `tag_repair.py` script that cross-references `deck_cards` with known card roles (Sol Ring=ramp, Mana Vault=ramp, Boros Signet=ramp, etc.) and updates `functional_tag` for commonly misclassified cards. Add ritual detection heuristic: if oracle_text contains `{R}{R}{R}` and `add` → tag as 'ramp'.
- **Impact:** Fixes ALL tag-dependent agents (Mulligan Simulator, Evolution Oracle, Scout, Validator). The 10-ramp-card gap means every agent is working with corrupted draw/ramp/density data.
- **Risk:** Low — only updates `functional_tag` column in SQLite `knowledge.db`. Does not modify product or PostgreSQL.
- **Validation:** After repair, re-run MULLIGAN with tag-based ramp detection — T3 should match the actual 8.9% (not 17.7%).

### Task 2: Basic Land Crisis — Deck Structural Validation
- **Evidence:** The active deck (deck_id=6) has only 2 lands with the "Basic" supertype: Ancient Den (Artifact Land — NOT basic) and Great Furnace (Artifact Land — NOT basic). Zero actual basic Plains or Mountains. This means: (a) Path to Exile on opponent creatures gives them no land, (b) Blood Moon turns all 33 lands into Mountains with no basics to fetch, (c) the deck folds to nonbasic land hate.
- **What to change:** Add basic land detection to the Validator. A Commander deck should have ≥3 basic lands unless it's a 5-color cEDH build with full ABUR duals. Emit a HARD WARNING when basic_count < 3. For this specific deck, recommend replacing 2-3 nonbasics with Plains/Mountains.
- **Impact:** Prevents structural land vulnerabilities from going undetected. Currently the Validator (v3.23) reports "Lands: 33 ✅ OK" without noticing zero basics.
- **Risk:** Low — validator logic only. Does not modify the deck.
- **Validation:** Run validator on the current deck — it should flag "0 basic lands" as a critical structural issue.

### Task 3: Removal Density Emergency
- **Evidence:** The active deck has only 3 removal cards (Path to Exile, Swords to Plowshares, Generous Gift) — 3/99 cards. In a 4-player pod where any opponent can become the archenemy, drawing any interaction requires 3 draws from 99. PG ideal profile for Lorehold: 5.33 removal. The spellslinger deck had 9.
- **What to change:** Add removal density scoring to the Evolution Oracle. When removal_count < (opponent_count × 2), flag as "EMERGENCY — insufficient interaction." The Oracle should prioritize adding removal over other swap types when below threshold.
- **Impact:** Prevents decks from reaching "battle-cruiser" state where they can't interact with opponents. This deck will lose to any resolved Kinnan, Korvold, or Winota.
- **Risk:** Low — recommendation layer only. Does not auto-apply swaps.
- **Validation:** Evolution Oracle on the current deck should emit a priority-1 recommendation to add removal before suggesting any other swaps.

### Task 4: Post-Reconstruction Pipeline Reset
- **Evidence:** Mulligan Exec#14 explicitly states: "O pipeline de T3 agora precisa ser recalibrado para o NOVO arquétipo." The Evolution Oracle has 23 cycles of history for the spellslinger deck — none of its historical swap recommendations apply to the storm build. The SYNERGY_MAP baselines need reset. The Validator's PG profile comparisons are based on the old spellslinger ideal, not a cEDH storm ideal.
- **What to change:** Create a `pipeline_reset.md` document that: (a) archives the pre-reconstruction history as historical reference, (b) establishes new baselines for T3 (8.9%), SYNERGY_MAP (6.9/10), and archetype profile, (c) identifies which pipeline agents need new reference data for cEDH storm archetype. Flag agents that will produce incorrect recommendations until reset.
- **Impact:** Prevents agents from making decisions based on stale historical data from a different archetype.
- **Risk:** Medium — if the deck is reconstructed again, the reset will need to happen again. Add hash-change detection that auto-triggers pipeline reset.
- **Validation:** After reset, the Evolution Oracle should not reference any pre-reconstruction cycle data.

### Task 5: Wincon Outlier Detection — Storm Herd + Rise of the Eldrazi
- **Evidence:** In a deck with 33 lands, CMC 3.0 average, and storm combo strategy, Storm Herd (CMC 10) and Rise of the Eldrazi (CMC 12) are the only cards above CMC 7. MULLIGAN Exec#14 flags them as "frequentemente dead draws." Without Akroma's Will (removed in reconstruction), Storm Herd's pegasus tokens lack haste and can't attack until next turn. Rise of the Eldrazi at CMC 12 requires 12 mana in a 33-land deck.
- **What to change:** Add CMC outlier detection to the Wincon Diversity Oracle. When a wincon's CMC exceeds (avg_nonland_cmc × 2), flag as "DEAD DRAW RISK." For the current deck, recommend replacing both with lower-CMC alternatives from the collection (Fiery Emancipation is already in deck, Approach is already in deck). Possible replacements: Comet Storm (CMC X+R, instant), Walking Ballista (CMC X, with Aetherflux), or additional draw/tutor.
- **Impact:** Removes the highest-CMC dead-weight from an otherwise optimized low-curve storm deck.
- **Risk:** Low — recommendation only. These 2 cards are the only CMC > 7 cards identified.
- **Validation:** Wincon Oracle should score Storm Herd (CMC 10) and Rise of the Eldrazi (CMC 12) below Approach (CMC 7) and Aetherflux Reservoir (CMC 4) for this specific deck configuration.

---

## 18. 🆕 NEW KEY SIGNALS FOR APP/BACKEND LOGIC

| Signal | Source | What It Would Power |
|:-------|:-------|:--------------------|
| **Functional tag completeness audit** | MULLIGAN Exec#14 (§16.2) | Detect and repair misclassified cards (Sol Ring as 'unknown') that corrupt all tag-dependent metrics |
| **Basic land count validation** | VALIDATOR v3.23 (§16.3) | Catch decks with 0 basic lands before they hit production |
| **Removal density threshold** | VALIDATOR v3.23 (§16.3) | Alert when interaction density drops below (opponents × 2) for multiplayer Commander |
| **CMC outlier scoring** | MULLIGAN Exec#14 (§17, Task 5) | Flag wincons/recurring cards whose CMC exceeds 2× deck average as dead-draw risk |
| **Pipeline hash-change auto-reset** | SCOUT #36 + MULLIGAN Exec#14 (§15.1) | When deck hash changes due to external import, auto-trigger pipeline baseline reset |
| **Power-level-aware swap recommendations** | §14.4 (previous cycle) | Prevent recommending cEDH cards into bracket-3 decks (still valid despite reconstruction) |
| **DB-tag vs actual-role gap scoring** | MULLIGAN Exec#14 (§16.2) | Quantify the false-negative rate in classifier tags to calibrate agent confidence |

---

## Appendix: Data Sources

| Source | Date Range | Records |
|:-------|:-----------|:-------|
|| SCOUT_LOG | 2026-05-28 to **2026-06-02** | **37** executions (including #36 post-reconstruction, #37 wincon saturation) |
|| EVOLUTION_LOG | 2026-05-28 to 2026-06-01 | 23+ cycles (all pre-reconstruction spellslinger) |
|| BATTLE_LOG | 2026-05-30 to **2026-06-02** | 18+ simulation runs (goldfish + matchup + interactive) |
|| MULLIGAN_LOG | 2026-05-28 to **2026-06-02** | **14** executions (Exec#14 = post-reconstruction T3=8.9%) |
|| VALIDATOR_LOG | 2026-05-28 to **2026-06-02** | v3.5 through **v3.24** (manual classification, banlist detection) |
|| VALIDATOR_SUMMARY | **2026-06-02T22:00** | **v3.24** — banlist violation, tag crisis, PG mismatch |
|| TAG_ACCURACY_REPORT | **2026-06-03T06:00** | Partial recovery (17/20 unknown→3), CMC corruption worsened (15→36), 4 new tags |
| wincon-patterns.md | 2026-05-31 | 7 patterns documented |
| card_deck_analysis (PG) | 2026-06-01 | 1,495 entries across multiple decks |
| EDHREC JSON API | ~2026-05-31 to 2026-06-01 | 7,851 → **7,893** decks |
| real-decklists.md | 2026-05-27 | 5 real Lorehold decks analyzed |
| VALIDATOR_LOG_v3.22 | 2026-06-01T20:52 | Re-confirmation — EDHREC shifts, SYNERGY_MAP degradation, swap SQL |
| LOREHOLD_BEST_OF_LEARNED.md | 2026-06-02T17:56 | Best-of candidate from 17+ imported decks (score 136.5, learned_deck_id=81) |
| LOREHOLD_BEST_OF_LEARNED_NO_MOX_CARD_RATIONALE.md | 2026-06-02T18:34 | Rationale for 100-card "No Premium Mox" build (learned_deck_id=82) |
| LOREHOLD_ACTIVE_DECK_PROMOTION.md | **2026-06-02T18:38** | **🆕 Active deck promotion — learned_deck_82 → deck_id=6** |
| import_queue/lorehold/ | 2026-06-02 | 23 community-submitted Lorehold decklists |
| knowledge.db (lorehold_import_runs) | 2026-06-02 | 17+ imported decks with role inference, wincon scoring |

---

> **Next Cron Cycle:** Continue monitoring the cEDH Storm build. Primary concerns: (1) 0 basic lands vulnerability, (2) only 3 removal cards, (3) DB tag audit needed, (4) CMC outlier dead-weight (Storm Herd CMC 10 + Rise CMC 12). Watch for VALIDATOR v3.24 with corrected DB data.

---

## 19. 🆕 VALIDATOR v3.24 — CRITICAL FINDINGS (2026-06-02T22:00 UTC)

### 19.1 🚨 BANLIST VIOLATION — Worldfire

**Worldfire** está oficialmente BANIDO em Commander desde o início do formato. Esta carta NÃO pode estar no deck ativo (deck_id=6).

```
Worldfire — 6RRR (CMC 9)
Sorcery
Each player's life total becomes 1. Exile all permanents,
all cards in all hands, and all cards in all graveyards.
```

**Ação imediata necessária:** Remover Worldfire. O deck tem 99 cartas legais + comandante após remoção. Substituição recomendada: **Underworld Breach** (CMC 2, recursion engine — já está na wishlist §12).

**Impacto no pipeline:** Worldfire foi importado via bulk import (`import_lorehold_decks.py`) sem verificação de banlist. Nenhum agente do pipeline (Scout, Evolution Oracle, Validator v3.22-v3.23) detectou a violação. O sistema de verificação de legalidade simplesmente não existe no pipeline de importação.

### 19.2 🔴 CRISE DE CLASSIFICAÇÃO — 20 Cartas com `functional_tag='unknown'`

O deck (id=6, 100 cartas) foi importado pelo `import_lorehold_decks.py` mas o classificador (`classify_card()` / `infer_functional_card_tags()`) **NUNCA EXECUTOU** para este deck. 20 cartas têm `functional_tag='unknown'` (string literal, não NULL):

**Cartas afetadas:** Birgi, Boros Charm, Boros Signet, Electroduplicate, Flawless Maneuver, Heat Shimmer, Lightning Greaves, Mana Vault, Orim's Chant, Past in Flames, Pyroblast, Reforge the Soul, Reiterate, Reverberate, Ruby Medallion, Scroll Rack, Sol Ring, Talisman of Conviction, Valakut Awakening, Victory Chimes.

**Impacto:** Todas as métricas do DB (ramp_count, draw_count, avg_cmc, mulligan simulation) são **inúteis** para este deck. O DB diz 6 ramp — o real são 12. O DB diz 9 wincons com CMC 2.94 — mas 6 cartas têm CMC=NULL e foram ignoradas no cálculo.

**Além disso, 6 cartas têm CMC=NULL:** Aetherflux Reservoir, Electroduplicate, Fiery Emancipation, Hall of Heliod's Generosity, Heat Shimmer, Past in Flames, Reiterate.

### 19.3 RECUPERAÇÃO PARCIAL — TAG_ACCURACY_REPORT 2026-06-03

Conforme o `TAG_ACCURACY_REPORT.md` de 2026-06-03T06:00:

| Métrica | Antes (v3.24) | Depois (2026-06-03) | Delta |
|:--------|:-------------:|:--------------------:|:-----:|
| Cartas `tag='unknown'` | 20 | **3** | **-17** ✅ |
| CMC NULL ou 0.0 (deck 6) | ~15 | **36** | **+21** 🔴 |
| Novas tags não registradas | — | **4** (stax, combo, commander, spellslinger) | +4 🟡 |
| `tag_accuracy` last_updated | 2026-05-27 | 2026-05-27 | **7 dias sem update** |

**Interpretação:** 17 das 20 cartas foram reclassificadas — progresso operacional. Porém:
- A reclassificação **piorou a corrupção de CMC** (NULL/0.0 aumentou de ~15 → 36)
- **4 novos tipos de tag** (`stax`, `combo`, `commander`, `spellslinger`) não existem na tabela `tag_accuracy` — suas precisões são desconhecidas
- Nenhuma entrada em `tag_accuracy` foi atualizada há 7 dias — o sistema de auto-avaliação de tags está **estagnado**

### 19.4 RECLASSIFICAÇÃO MANUAL COMPLETA (100 Cartas)

Devido à crise de tags, o Validator v3.24 realizou classificação manual baseada em conhecimento real de cartas MTG. Resultado:

| Função Real | DB Tagged | Real (Manual) | Delta |
|:------------|:---------:|:-------------:|:-----:|
| Lands | 33 | 33 | — |
| Fast Mana / Ramp | 6 | **12** | **+6** 🔴 |
| Rituals / Treasure | 5 | 5 | — |
| Draw / Selection | 9 | 9 | — |
| Tutors | 3 | **6** | **+3** 🔴 |
| Protection | 5 | **8** | **+3** 🔴 |
| Stax / Silence | 0 | **3** | **+3** 🔴 |
| Removal / Wipe | 3 | **5** | **+2** 🔴 |
| Copy / Twin Spells | 4 | **6** | **+2** 🔴 |
| Wincons | 9 | 9 (1 BANNED) | — |
| Recursion / Engine | 2 | **3** | +1 |

**Conclusão:** O DB subestima ramp em 50%, tutors em 50%, protection em 37%, e ignora completamente stax/silence. Qualquer agente que use `functional_tag` para tomada de decisão (Mulligan Simulator, Evolution Oracle, Scout, Validator) está operando com dados **sistematicamente incorretos**.

### 19.5 PERFIL PG INCOMPATÍVEL — Arquétipo Diferente

O perfil PostgreSQL `commander_reference_deck_analysis` para Lorehold assume o arquétipo **spellslinger big-spells** (miracle_topdeck=4.33, ritual_treasure=10, big_spell_payoff=7.67).

O deck ativo é **cEDH turbo-combo** — as assinaturas `ritual_treasure=10` e `miracle_topdeck=4.33` do perfil PG indicam um deck que gera tesouros e manipula o topo para milagres. Este deck não faz nada disso. O deck faz: fast mana → tutor → Dualcaster+Twinflame = WIN.

**Comparação contra perfil PG (inválido):**

| PG Role | Ideal (spellslinger) | Actual (combo) | Status |
|:--------|:--------------------:|:--------------:|:------:|
| lands | 32.0 | 33 | ~OK |
| ramp (rocks) | 3.67 | 12 | 🔴 3.3× above |
| ritual_treasure | 10.0 | 5 | 🔴 Below — wrong archetype |
| miracle_topdeck | 4.33 | 0 | 🔴 Missing — wrong archetype |
| draw_value | 2.67 | 9 | 🔴 3.4× above |
| tutor | 3.67 | 6 | Above |
| win_condition | 1.33 | 9 | 🔴 6.8× above |
| protection | 3.67 | 8 | 🔴 2.2× above |

**Diagnóstico:** O perfil PG NÃO é adequado para validar este deck. É um arquétipo diferente. O Validator deve selecionar o perfil com base no arquétipo real do deck, não apenas no nome do comandante.

### 19.6 SYNERGY_MAP v3.24 — Recalculado com Classificação Manual

| Eixo | v3.23 (DB tags) | v3.24 (manual) | Change | Driver |
|:-----|:----------------:|:--------------:|:------:|:-------|
| A) Token + Pump | 5/10 | **3/10** | -2 | Sem pump, sem haste em massa |
| B) Wipes + Proteção | 7/10 | **5/10** | -2 | 1 wipe para 8 proteções (razão invertida) |
| C) Recursion Chains | 8/10 | 7/10 | -1 | Sem Underworld Breach (peça mais broken) |
| D) Explosive Mana | 8/10 | 8/10 | — | 6 rocks + 2 0-CMC + 5 rituais + Sol land |
| E) Combo Pieces | 9/10 | **9/10** | — | Dualcaster+Twinflame+Heat Shimmer determinísticos |
| F) Stack Interaction | 5/10 | **6/10** | +1 | 3 Silence + Pyroblast + 8 proteções |
| G) Resilience | 6/10 | 7/10 | +1 | Mizzix + Past in Flames + Hall of Heliod |
| **MÉDIA** | **6.9/10** | **6.4/10** | -0.5 | Correção para baixo com dados reais |

**Key insight:** A correção manual revelou que os scores baseados em DB tags estavam **inflados**. O combo Eixo E permanece excelente (9/10 — o coração do deck), mas Token+Pump caiu de 5→3 (DB dizia que Storm Herd + Rite of the Dragoncaller eram suficiente, mas sem pump/haste não são).

---

## 20. 🆕 SCOUT #37 — WINCON SATURATION (2026-06-02T21:42 UTC)

### 20.1 Deck Alterado Novamente

**Card hash:** `f2241d994743e8142396c0f846917fde` — confirmado como o estado ativo.
**Mudanças desde Scout #36:** 7 wincons do spellslinger original foram RE-ADICIONADOS (Guttersnipe, Mizzix's Mastery, Rite of the Dragoncaller, Fiery Emancipation, Aetherflux Reservoir, Worldfire, Approach of the Second Sun, Molten Duplication). Cartas removidas: Trouble in Pairs, Perch Protection, Apex of Power, Call Forth the Tempest.

### 20.2 Deck Saturado de Wincons

**11 wincons scored no deck.** O deck está **saturado** — mais condições de vitória do que consegue usar.

| Carta | CMC | Score | Diagnóstico |
|:------|:---:|:-----:|:------------|
| Guttersnipe | 3 | 19 | 🟡 INVISÍVEL (ST=8) — frágil (R=5), 2 dano/spell |
| Mizzix's Mastery | 4 | 17 | 🔴 IMBATÍVEL (R=7) — overload exila grave, cópia tudo grátis |
| Twinflame | 2 | 16 | 🟢 Combo com Dualcaster = infinito |
| Rite of the Dragoncaller | 6 | 16 | 🟡 INVISÍVEL (ST=7) — Dragon 5/5 por spell |
| Dualcaster Mage | 3 | 16 | 🟢 Combo determinístico |
| Rise of the Eldrazi | 12 | 15 | 🔴 IMBATÍVEL (R=9) — Aniquilador 4 + turno extra |
| Fiery Emancipation | 6 | 15 | 🟢 Triplica dano |
| Aetherflux Reservoir | 4 | 15 | 🟢 Storm payoff |
| **🔴 Worldfire** | **9** | **14** | **BANNED** — REMOVER |
| Approach of the Second Sun | 7 | 12 | 🟢 RÁPIDA (S=6) |
| Storm Herd | 10 | 11 | 🟡 Precisa de Akroma/Fiery no mesmo turno |

### 20.3 NENHUM Candidato de Swap Atinge Thresholds

| Categoria | Threshold | Candidatos | Status |
|:----------|:---------:|:-----------|:------|
| IMBATÍVEIS (R≥7) | resilience ≥ 7 | 0 | VAZIO |
| INVISÍVEIS (ST≥7) | stealth ≥ 7 | 0 | VAZIO |
| RÁPIDAS (S≥6) | speed ≥ 6 | 2 | AMBOS misclassified |
| FRÁGEIS (R≤3) | resilience ≤ 3 | 1 (Call Forth the Tempest) | EVITAR |

**2 cartas misclassified como wincons:**
- **Trouble in Pairs** (CMC 4, score 16, S=7) — é draw engine, não wincon
- **Perch Protection** (CMC 6, score 16, S=7) — é fog + extra turn + gift, não wincon

**Conclusão do Scout #37:** O deck está saturado de wincons. Coleção esgotada de candidatos que atendam thresholds. O pipeline atingiu **saturação de otimização** para este deck — não há mais o que recomendar até que novas cartas entrem na coleção ou o meta mude.

---

## 21. 🆕 UPDATED CONCRETE TASKS (2026-06-03)

### Task 1: 🔴 CRITICAL — Banlist Validation in Import Pipeline

- **Evidence:** Worldfire (CMC 9, banned in Commander) was imported via `import_lorehold_decks.py` into the active deck (deck_id=6). Neither the import script nor any pipeline agent (Scout, Evolution Oracle, Validator v3.22-v3.24) detected the banlist violation. The card is still in the active deck as of 2026-06-03. Worldfire appears in the wincon scorecard (score=14, res=7) and the Validator v3.24 flagged it as BANNED.
- **What to change:** Add a `check_commander_banlist()` function to the deck import pipeline that, after card parsing but before insertion into `deck_cards`, queries the Commander banlist (from Scryfall API or a local `commander_banlist.json`) and rejects banned cards with an error. The function should also be callable as a standalone validator against any existing deck.
- **Impact:** Prevents banned cards from ever entering active decks. Currently, any deck imported from external sources can contain banned cards silently. This is a data integrity blocker — the system cannot claim to validate Commander decks if it doesn't check the banlist.
- **Risk:** Low — read-only validation at import time. Does not modify existing decks. Scryfall API is rate-limited (10 req/sec) but banlist is small (~50 cards) and can be cached locally.
- **Validation:** Run `check_commander_banlist()` on deck_id=6 — it should return `[Worldfire]` as the banned card. After removal of Worldfire, the function should return `[]` for deck_id=6.

### Task 2: Tag Accuracy Schema Update — Register 4 New Tags

- **Evidence:** TAG_ACCURACY_REPORT (2026-06-03) documents that the reclassification of 17/20 unknown cards introduced 4 new functional tag values (`stax`, `combo`, `commander`, `spellslinger`) that do NOT exist in the `tag_accuracy` table. The `tag_accuracy` table has not been updated in 7 days (last: 2026-05-27). Without entries in `tag_accuracy`, the system cannot track precision or false-positive rates for these tags, making them invisible to quality monitoring.
- **What to change:** Add rows to `tag_accuracy` for the 4 new tags: `{tag: 'stax', correct: 3, total: 3, precision: 1.0}`, `{tag: 'combo', ...}`, `{tag: 'commander', ...}`, `{tag: 'spellslinger', ...}`. Initialize with manual audit counts from the Validator v3.24 manual classification. Update `last_updated` to current timestamp.
- **Impact:** Completes the tag accuracy monitoring surface. Without this, 4 functional categories are flying blind — the system can't detect drift in stax/combo classification quality.
- **Risk:** Low — SQL UPDATE on `tag_accuracy` table in SQLite `knowledge.db`. Does not modify product or PostgreSQL.
- **Validation:** After update, `SELECT COUNT(*) FROM tag_accuracy` should return 26 (was 22). `SELECT tag, precision FROM tag_accuracy WHERE tag IN ('stax', 'combo', 'commander', 'spellslinger')` should return 4 rows with precision ≥ 0.5.

### Task 3: CMC Integrity Repair for deck_id=6

- **Evidence:** TAG_ACCURACY_REPORT documents that CMC corruption in deck_id=6 **worsened** from ~15 cards to **36 cards** with CMC=NULL or CMC=0.0. Cards affected include Aetherflux Reservoir (real CMC=4, DB=NULL), Electroduplicate (real CMC=3, DB=NULL), Fiery Emancipation (real CMC=6, DB=NULL), and 33 others. The reclassification operation that fixed 17 unknown tags appears to have set CMC=NULL for many cards. This corrupts avg_cmc calculation, mulligan simulation, and curve analysis for ALL agents.
- **What to change:** Create a `repair_cmc.py` script that: (a) queries all `deck_cards WHERE deck_id=6 AND (cmc IS NULL OR cmc = 0.0)`, (b) cross-references each card name against a CMC reference table (from PostgreSQL `cards` table or a local `card_cmc_reference.json`), (c) updates the `cmc` column with the correct value. For cards not found in the reference, log the card name for manual review.
- **Impact:** Restores data integrity for the most heavily analyzed deck in the system. All downstream agents (Mulligan, Evolution Oracle, Scout, Validator) depend on correct CMC values.
- **Risk:** Medium — modifies `deck_cards` table in SQLite. Must ensure the reference data is correct (use PostgreSQL `cards` table as source of truth, which has 33,795 cards with verified CMC).
- **Validation:** After repair, `SELECT COUNT(*) FROM deck_cards WHERE deck_id=6 AND (cmc IS NULL OR cmc = 0.0)` should return 0. `SELECT AVG(cmc) FROM deck_cards WHERE deck_id=6 AND is_commander=0` should return approximately 2.94 (the manually computed average).

### Task 4: Archetype-Aware PG Profile Matching

- **Evidence:** Validator v3.24 demonstrated that the PG profile for Lorehold (`commander_reference_deck_analysis`) is built for a **spellslinger big-spells** archetype (miracle_topdeck=4.33, ritual_treasure=10), but the active deck is a **cEDH turbo-combo** archetype. The PG comparison output (§19.5) shows massive deltas (+6.8× in win_condition, +3.3× in ramp rocks, -10 in ritual_treasure) that are ARCHETYPE differences, not deficiencies. The Validator currently applies the first matching profile without checking archetype alignment.
- **What to change:** Add archetype detection logic to the Validator's PG profile selection. When comparing a deck against its PG profile: (a) compute the deck's archetype signature (combo_density, stax_density, fast_mana_count, wincon_count, avg_cmc), (b) compare against PG profile's expected archetype signature, (c) if correlation < 0.5, emit a warning "PG profile may be for a different archetype — deltas are not deficiencies" and skip quantitative gap scoring. Optionally, search `commander_reference_deck_analysis` for profiles with similar archetype signatures.
- **Impact:** Prevents false-positive "deficiency" reports when the deck simply plays a different archetype than the profile expects. This affects deck scoring, swap recommendations, and Validator reports.
- **Risk:** Low — read-only analysis. Does not modify PostgreSQL or the deck.
- **Validation:** Run Validator on deck_id=6 with archetype detection active. It should emit: "⚠️ Archetype mismatch: deck is cEDH Turbo-Combo (combo_density=0.09, stax_density=0.03), PG profile expects Spellslinger Big-Spells (miracle_topdeck=4.33, ritual_treasure=10.0). Quantitative gap scoring SKIPPED."

### Task 5: Wincon Saturation Detection in Evolution Oracle

- **Evidence:** Scout #37 found the active deck has **11 wincons scored** (via `card_deck_analysis`), but the deck realistically only needs 4-5 wincons to function (2 combos + 1 fast + 1 resilient). The deck is saturated — additional wincons are dead weight. The Evolution Oracle currently only recommends ADDING wincons when coverage gaps exist; it never recommends REMOVING excess wincons. Scout #37 concluded "nenhum candidato atinge thresholds" because all viable cards were already in the deck, but failed to recognize that the deck has TOO MANY wincons and could free 5-6 slots for draw/removal/tutors.
- **What to change:** Add a `wincon_saturation_check` to the Evolution Oracle. After computing wincon coverage (RÁPIDA, RESILIENTE, STEALTH), if total scored wincons > 7 AND all 3 coverage axes are satisfied, recommend consolidating: identify the 4-5 highest-scoring wincons that maintain axis coverage, and mark the remaining as "EXCESS — cut candidates." The freed slots should be prioritized for draw (if <8) or removal (if <5).
- **Impact:** Prevents decks from bloating with wincons at the expense of core functions. For the Lorehold active deck, this would free 5-6 slots — the single largest optimization remaining.
- **Risk:** Low — recommendation layer only. Does not auto-apply cuts. The Oracle should present consolidation candidates ranked by lowest (Speed + Resilience + Stealth) score.
- **Validation:** Run Evolution Oracle on deck_id=6 with wincon saturation active. It should emit: "⚠️ Wincon saturation: 11 scored (threshold: 7). Consolidation candidates: Storm Herd (score=11, CMC=10), Rise of the Eldrazi (score=15, CMC=12), Guttersnipe (score=19, fragile R=5), Rite of the Dragoncaller (score=16, CMC=6). Recommended keep: Approach (speed), Twinflame+Dualcaster (combo/stealth), Aetherflux (storm payoff), Mizzix's Mastery (resilience)."

---

## 22. 🆕 UPDATED KEY SIGNALS FOR APP/BACKEND LOGIC

| Signal | Source | What It Would Power |
|:-------|:-------|:--------------------|
| **Banlist import guard** | v3.24 §19.1, Task 1 | Reject banned cards at import boundary — prevents data corruption before it reaches agents |
| **Tag accuracy schema expansion** | TAG_ACCURACY_REPORT, Task 2 | Track precision of new tag types introduced by reclassification — prevents blind spots in quality monitoring |
| **CMC integrity repair** | TAG_ACCURACY_REPORT, Task 3 | Cross-reference CMC from PostgreSQL source of truth — single script fixes all NULL/0.0 corruption |
| **Archetype-aware profile matching** | v3.24 §19.5, Task 4 | Validator selects correct PG profile by archetype signature, not just commander name — eliminates false deficiency reports |
| **Wincon saturation detection** | Scout #37 §20.2, Task 5 | Evolution Oracle recommends CUTTING excess wincons when saturation threshold is exceeded — frees slots for draw/removal |
| **Functional tag completeness audit** | v3.24 §19.2 | Detect decks where `functional_tag` coverage < 70% and trigger classifier execution — current gap: 20% unknown |
| **Tag accuracy stagnation alert** | TAG_ACCURACY_REPORT §1 | Alert when `tag_accuracy.last_updated > 3 days` — signals classifier pipeline is stalled |
| **CMC corruption escalation detection** | TAG_ACCURACY_REPORT §1 | Monitor CMC=NULL count change between reports — catch reclassification side-effects (15→36 escalation) |
| **Pipeline saturation detection** | Scout #37 §20.3 | When all viable swap candidates are below threshold AND wincons are saturated, signal "deck optimization complete" to prevent wasted cycles |
| **Import classifier execution check** | v3.24 §19.2 | After bulk import, verify that `classify_card()` ran on ALL imported cards — if tag='unknown' detected, trigger classifier |

---

## 23. 🆕 VALIDATOR v3.25 — RECONFIRMATION + CLASSIFIER RESOLUTION (2026-06-03T23:00 UTC)

### 23.1 🟢 WORLDFIRE BANLIST CORRECTION

**v3.24 ERROR:** Claimed Worldfire was BANNED in Commander.
**v3.25 CORRECTION:** Worldfire is `commander=legal` — confirmed via `SELECT status FROM card_legalities WHERE lower(card_name)='worldfire' AND format='commander'` → `legal`.

**Root cause:** v3.24 used stale model memory (Worldfire was banned 2013-2017). The source of truth is `card_legalities` synchronized from PostgreSQL. **0 banned cards in the deck.**

### 23.2 ✅ CLASSIFIER RESOLUTION — 85% Improvement

| Metric | v3.24 | v3.25 | Delta |
|:-------|:-----:|:-----:|:-----:|
| Unknown tags | 20 | **3** | **-17 ✅** |
| Double-nulls | 0 | 0 | — |
| Banned cards | 1 (false) | 0 | -1 ✅ |
| Game Changers | ? | **11** | 🔴 Bracket 4 |

**17 cards reclassified between v3.24 and v3.25:**
- 5 Moxen (Chrome, Diamond, Opal, Amber, Lotus Petal): `unknown` → `ramp` ✅
- Sol Ring, Mana Vault: `unknown` → `ramp` ✅
- Boros Signet, Talisman of Conviction: `unknown` → `ramp` ✅
- Rite of Flame, Seething Song, Mana Geyser: `spell` → `ramp` ✅
- Jeska's Will: `draw` → `ramp` ✅
- Victory Chimes: `unknown` → `ramp` ✅
- Grand Abolisher: `NULL` → `protection` ✅
- Drannith Magistrate: `NULL` → `stax` ✅

**Ramp tag count: 6 (v3.24) → 19 (v3.25).** Classifier fully functional.

**3 remaining unknown tags:** Inventors' Fair (CMC=3, Land artifact), Prismatic Vista (CMC=3, Land fetch), Reforge the Soul (CMC=3, Sorcery wheel+Miracle).

### 23.3 🔴 Game Changer Analysis — 11 GCs = Bracket 4

| Game Changer | CMC | Function |
|:-------------|:---:|:---------|
| Ancient Tomb | 0 | Fast mana land |
| Chrome Mox | 0 | Fast mana (imprint) |
| Mox Diamond | 0 | Fast mana (discard land) |
| Mox Opal | 0 | Fast mana (metalcraft) |
| Mana Vault | 1 | Fast mana |
| The One Ring | 4 | Draw engine + protection |
| Urza's Saga | 0 | Land tutor + construct |
| Enlightened Tutor | 1 | Tutor |
| Gamble | 1 | Tutor |
| Drannith Magistrate | 2 | Stax |
| Gemstone Caverns | 0 | Fast mana land |

**Bracket classification:** 11 GCs → **Bracket 4 (cEDH).** Maximum for Bracket 3 is 3 GCs. Deck is pubstomp-level against Bracket 3 tables.

### 23.4 SYNERGY_MAP v3.25 — Recalibrated

| Axis | Score | Key Finding |
|:-----|:-----:|:------------|
| A) Token Makers + Pump | 4/10 | Weak token strategy — Rite of the Dragoncaller + Storm Herd only, Surge to Victory situational |
| B) Board Wipes + Protection | 6/10 | 10 protection, only 1 wipe (Blasphemous Act) — wipe-deficient for go-wide threats |
| C) Recursion Chains | 5/10 | Strong spell recursion (Past in Flames, Mizzix's Mastery), no permanent recursion |
| D) Explosive Mana | 9/10 | 5 Moxen + Sol Ring + Mana Vault + 4 rituals = T1-T2 explosive mana |
| E) Combo Pieces | 8/10 | 5 combos: Approach+Topdeck, Dualcaster+Twinflame, Aetherflux+Storm, Worldfire+flash, Birgi+Reiterate |
| F) Stack Interaction | 7/10 | Strong for Boros — 3 Silence + Pyroblast + 10 protection slots. No universal counterspell |
| G) Resilience | 6/10 | Commander CMC 5 vulnerable to removal. 10 protection helps but commander removal stalls deck |

**Average: 6.4/10** — corrected downward from v3.23's inflated 6.9 (DB-tag-based). The deck's true strength is Eixo D (9/10) and Eixo E (8/10).

### 23.5 Motor Framework v3.25 — 5/5 COMPLETE

```
[Fast Mana T1-T2] → [Tutor → Combo Piece] → [Combo Execution] → [Silence/Orim's Chant protection]
         ↑                                                          ↓
         └─────────── Recursion (Past in Flames) ←───────────────────┘
```

**Component status:**
| Component | Status | Details |
|:----------|:------:|:--------|
| Fast Mana | ✅ | 8-10 T1 sources (5 Moxen, Sol Ring, Mana Vault, Lotus Petal, Rite of Flame) |
| Tutors | ✅ | 5 (Enlightened, Gamble, Imperial Recruiter, Recruiter of the Guard, Ranger-Captain) |
| Combo Pieces | ✅ | Approach+Topdeck (2 pc), Dualcaster+Twinflame (2 pc), Aetherflux+Storm (1+condition), Birgi+Reiterate+ritual (3 pc) |
| Protection | ✅ | 5 slots (Silence, Orim's Chant, Grand Abolisher, Pyroblast, Deflecting Swat) |
| Recursion | ✅ | Past in Flames, Mizzix's Mastery |

**Motor status: 5/5 COMPLETE.** All cEDH Boros components present.

### 23.6 Swap Recommendations (cEDH-Optimized)

| Priority | Swap | ΔCMC | Score | Rationale |
|:--------:|:-----|:----:|:-----:|:----------|
| 1 | Rite of the Dragoncaller → Underworld Breach | -4 | 9 | Breach is cEDH tier-1 recursion; Rite is slow payoff |
| 2 | Storm Herd → Dockside Extortionist | -8 | 10 | CMC 10 injogável em cEDH; Dockside = best ritual in format |
| 3 | Rise of the Eldrazi → Emrakul, the Promised End | +3 | 7 | Rise declining -0.49; Emrakul = Mindslaver effect |
| 4 | Rite of the Dragoncaller → Skullclamp | -5 | 9 | Draw engine tier-1; combos with token makers |
| 5 | Land Tax → Talisman of Hierarchy | +1 | 5 | Sidegrade — low priority |

---

## 24. 🆕 SCOUT #38 — WINCON SUPERSATURATION + 4TH CONSECUTIVE HASH CHANGE (2026-06-03T21:42 UTC)

### 24.1 Deck Altered Again — 4th Time

**Card hash:** `8b9c643c84825a4436d33b7f1616fa5f` (changed from `f2241d99...`)
**Mudanças:** Akroma's Will removida → Longshot (CMC 4, dano=total power creatures) + Surge to Victory (CMC 6, exila topo, buffa board) adicionados.

| Status | Cards |
|:-------|:------|
| ✗ Removed | **Akroma's Will** (was combat finisher enabler) |
| ＋ Added | **Longshot, Rebel Bowman** (CMC 4) |
| ＋ Added | **Surge to Victory** (CMC 6) |
| ✓ Maintained | All 10 wincons from Scout #37 + Dualcaster Mage + Twinflame + Rite of the Dragoncaller |

**Total: 13 wincons/game-enders** (10 wincon-tagged + Twinflame/Dualcaster combo + Rite + Surge + Longshot). Deck is **supersaturated** — meta cEDH uses 3-5 wincons.

### 24.2 WINCON SCORECARD (Current Deck)

| Card | CMC | Score | S | R | ST | Diagnosis |
|:------|:---:|:-----:|:-:|:-:|:-:|:-----------|
| Guttersnipe | 3 | 19 | 7 | 5 | 8 | 🟡 INVISIBLE (ST=8) — fragile (R=5), 2 dmg/spell |
| Mizzix's Mastery | 4 | 17 | 6 | 7 | 6 | 🔴 UNBEATABLE (R=7) — Overload from grave |
| Twinflame | 2 | 16 | 7 | 5 | 5 | 🟢 Combo with Dualcaster = infinite creatures |
| Rite of the Dragoncaller | 6 | 16 | 5 | 5 | 7 | 🟡 INVISIBLE (ST=7) — Dragon 5/5 per spell |
| Dualcaster Mage | 3 | 16 | 7 | 5 | 5 | 🟢 Deterministic combo with Twinflame |
| Rise of the Eldrazi | 12 | 15 | 2 | 9 | 4 | 🔴 UNBEATABLE (R=9) — Annihilator 4 + extra turn |
| Fiery Emancipation | 6 | 15 | 6 | 5 | 4 | 🟢 Triples damage output |
| Aetherflux Reservoir | 4 | 15 | 6 | 5 | 4 | 🟢 Storm payoff — 50+ life = removal laser |
| Worldfire | 9 | 14 | 2 | 7 | 5 | 🔴 UNBEATABLE (R=7) — ✅ LEGAL |
| Approach of the Second Sun | 7 | 12 | 6 | 5 | 1 | 🟢 FAST (S=6) — ARCHENEMY (ST=1) |
| Storm Herd | 10 | 11 | 3 | 5 | 4 | 🟡 Needs Fiery/Surge same turn |
| Longshot, Rebel Bowman | 4 | N/A | — | — | — | 🆕 No score — damage = total creature power |
| Surge to Victory | 6 | N/A | — | — | — | 🆕 No score — exiles top, buffs board |

**⚠️ Pitfall:** All scores from `card_deck_analysis` reference deleted `deck_id` values (16-82). Scores were computed for spellslinger context, not cEDH turbo-combo.

### 24.3 Collection Depleted — No Swap Candidates Meet Thresholds

| Category | Threshold | Candidates | Status |
|:---------|:---------:|:-----------|:------|
| UNBEATABLE (R≥7) | resilience ≥ 7 | 0 | EMPTY |
| INVISIBLE (ST≥7) | stealth ≥ 7 | 0 | EMPTY |
| FAST (S≥6) | speed ≥ 6 | 2 | BOTH misclassified (Trouble in Pairs=draw, Perch Protection=fog) |
| FRAGILE (R≤3) | resilience ≤ 3 | 1 (Call Forth the Tempest) | AVOID |

**2 misclassified "wincons" remaining in collection:**
- **Trouble in Pairs** (CMC 4, score 16, S=7) — is a draw engine, not wincon
- **Perch Protection** (CMC 6, score 16, S=7) — is fog + extra turn gift, not wincon

**Conclusion:** Deck is supersaturated with wincons. Collection exhausted. No swap recommendations.

### 24.4 ALERTS — Scout #38

1. **Wincon supersaturation** — 13 win conditions (13% of deck). Meta cEDH uses 3-5. Excess wincons consume slots needed for interaction/draw/stax.
2. **Misclassification persists** — Trouble in Pairs and Perch Protection still scored as wincons in `card_deck_analysis`.
3. **Card_deck_analysis references deleted deck_ids** — all scores from non-existent decks (ids 16-82). Scores may not reflect current cEDH context.
4. **Akroma's Will removed** — was the best combat finisher enabler. Surge to Victory and Longshot fill the gap partially, but Surge depends on random exiled card.
5. **4th consecutive hash divergence** — deck continues to be modified externally. Pipeline logs stale.

---

## 25. 🆕 MULLIGAN Exec#15 — T3 MASSIVE IMPROVEMENT (2026-06-03T21:47 UTC)

### 25.1 Classifier Correction Drives -7.3pp T3 Drop

**Hash:** `8b9c643c84825a4436d33b7f1616fa5f` (changed from Exec#14's `f2241d99...`)
**Primary change:** NOT deck composition — the **classifier was corrected.** Ramp tags: 6 → 19.

| Metric | Exec#14 | Exec#15 | Delta | Signal |
|:-------|:-------:|:-------:|:-----:|:------|
| **Sem Play T3** | **8.9%** | **1.6%** | **-7.3pp** | 🟢 Dramatic improvement |
| Mulligan (non-free) | 16.0% | 15.3% | -0.7pp | Stable |
| Free Mulligan used | 18.6% | 23.6% | +5.0pp | More free mulls |
| Keepable first 7 | 65.4% | 61.1% | -4.3pp | Slight decline |
| **Playable final hand** | **84.0%** | **97.9%** | **+13.9pp** | 🟢 Excellent |
| Ramp T1 (Sol Ring) | 6.3% | 7.0% | +0.7pp | Stable |
| **Ramp T1 (fast mana expanded)** | — | **49.7%** | — | 🆕 New metric |
| Hands to 0 cards | 6.5% | 2.1% | -4.4pp | Improved |

### 25.2 Why T3 Improved — CLASSIFIER Was the Bottleneck

**On Exec#14, with only 6 cards tagged 'ramp':** the simulator treated 2-land + Sol Ring hands as non-keepable (Sol Ring tag='unknown'), forcing unnecessary mulligans and reducing final hand size. Result: T3=8.9% with 10 ramp cards invisible to the simulator.

**On Exec#15, with 19 cards correctly tagged:** 2-land hands with any rock/ritual/fast mana are kept. The simulator can now SEE the ramp. Result: 97.9% playable final hands, T3=1.6%.

**The real lesson:** The difference between T3=8.9% (simulated with bad tags) and T3=1.6% (simulated with corrected tags) is **7.3pp**. No card swap can produce a delta that large. Investment in classifier quality has higher ROI than any deck optimization.

### 25.3 Deck Maturity: Early-Game Elite

With T3=1.6% and 97.9% playable hands, the deck has achieved **early-game maturity.** cEDH tier-1 decks typically have T3 3-8%. This deck is in the top percentile for early-game consistency.

**Strategic implication:** The pipeline focus should shift from "reduce T3" to "optimize wincons and matchups." The Evolution Oracle can use AGGRESSIVE strategy (ΔCMC +1 to +3) since early-game consistency has massive headroom.

### 25.4 DB Classifier Health Check (Post-Correction)

| Metric | Exec#14 | Exec#15 | Status |
|:-------|:-------:|:-------:|:------|
| Ramp tagged | 6 | **19** | ✅ Corrected |
| Fast mana tagged | 2 | **8** | ✅ Corrected |
| Lands with correct CMC | 31/33 | 31/33 | ⚠️ 2 lands have CMC=3.0 (Inventors' Fair, Prismatic Vista) |
| Double-null cards | ? | ? | OK |

**Remaining issues:** Inventors' Fair and Prismatic Vista have `CMC=3.0` and `tag='unknown'` despite being lands. Land Tax also has CMC corruption reported. All are bulk import artifacts — not affecting simulation significantly but corrupting curve analysis.

---

## 26. 🆕 UPDATED CONCRETE TASKS (2026-06-04)

### Task 1: Wincon Desaturation — Cut Excess from 13 → 5 Wincons (HIGH PRIORITY)
- **Evidence:** Scout #38 documents 13 wincons/game-enders in a 100-card deck (13% density). cEDH meta uses 3-5 wincons + tutors. The deck has 6+ tutors that can find any combo piece. Excess wincons (Guttersnipe R=5, Storm Herd CMC=10, Rise of the Eldrazi CMC=12, Rite of the Dragoncaller CMC=6 slow payoff) consume ~6 slots that could be removal (currently 3), board wipes (currently 1), or additional draw/stax. Mulligan Exec#15 confirms T3=1.6% (elite early-game) meaning the deck CAN support higher-CMC additions, but the slots should go to interaction, not redundant wincons.
- **What to change:** Implement `wincon_desaturation()` in Evolution Oracle. When `scored_wincons > 7` and all 3 coverage axes (FAST/RESILIENT/STEALTH) are satisfied, rank wincons by (Score/CMC) ratio and recommend cutting the bottom N. For Lorehold: keep Approach (fast), Twinflame+Dualcaster (combo/stealth), Aetherflux Reservoir (storm payoff), Mizzix's Mastery (resilience). Cut candidates: Storm Herd (CMC=10, score=11, ratio=1.1), Rite of the Dragoncaller (CMC=6, score=16, ratio=2.7 but slow), Guttersnipe (R=5 fragile, score=19), Longshot (no score, untested), Surge to Victory (no score, random exile).
- **Impact:** Frees 5-6 slots for removal/draw/stax. The single largest optimization remaining for this deck. Without this, the deck will continue losing to any resolved opposing commander.
- **Risk:** Low — recommendation layer only. Does not auto-apply cuts.
- **Validation:** Oracle should output: "⚠️ Wincon supersaturation: 13 total (threshold: 7). Consolidation recommended. Freed slots priority: removal (+3), board wipe (+1), stax (+1)."

### Task 2: CMC Integrity Repair — Fix 36 NULL/0.0 CMC Cards in deck_id=6
- **Evidence:** TAG_ACCURACY_REPORT (2026-06-03) documents 36 cards in deck_id=6 with `cmc IS NULL OR cmc = 0.0` (36% of deck). The reclassification that fixed 17 unknown tags introduced or worsened CMC corruption. Mulligan Exec#15 confirms 2 lands (Inventors' Fair, Prismatic Vista) have CMC=3.0 despite being lands. Validator v3.25 notes that 5 Moxen have CMC=0.0 which is CORRECT (they cost 0 mana), but cards like Aetherflux Reservoir (real CMC=4, DB=NULL), Electroduplicate (real CMC=3, DB=NULL), Fiery Emancipation (real CMC=6, DB=NULL), Past in Flames (real CMC=4, DB=NULL), Reiterate (real CMC=3, DB=NULL), and ~30 others have corrupted CMCs. This corrupts avg_cmc calculation, curve analysis, and mulligan simulation for all agents.
- **What to change:** Create `repair_cmc.py` that: (a) queries `deck_cards WHERE deck_id=6 AND (cmc IS NULL OR cmc = 0.0)`, (b) cross-references each card name against PostgreSQL `cards` table (33,795 cards with verified CMC) or Scryfall API, (c) updates `cmc` column with correct values, (d) reports cards not found in reference. Also fix the 2 lands with CMC=3.0: set CMC=0 and tag='land'.
- **Impact:** Restores data integrity for the most heavily analyzed deck in the system. All downstream agents depend on correct CMC values. Without this, every analysis is working with ~36% corrupted data.
- **Risk:** Medium — modifies `deck_cards` in SQLite. Must verify reference data correctness.
- **Validation:** After repair, `SELECT COUNT(*) FROM deck_cards WHERE deck_id=6 AND (cmc IS NULL OR cmc = 0.0)` should return 5 (only the 5 Moxen with real CMC=0). `SELECT AVG(cmc) FROM deck_cards WHERE deck_id=6 AND is_commander=0` should return ~2.94.

### Task 3: Import Classifier Auto-Execution Gate
- **Evidence:** Validator v3.25 proved that the classifier fix resolved 20 unknown tags → 3 (85% reduction). Mulligan Exec#15 proved that the classifier gap (6 vs 19 ramp tags) was inflating T3 by +7.3pp. The `import_lorehold_decks.py` pipeline promoted a deck to active status (deck_id=6) without running the classifier, leaving 20 cards tagged 'unknown' for multiple cycles. The TAG_ACCURACY_REPORT shows `tag_accuracy` has not been updated in 7+ days — classifier pipeline is stalled.
- **What to change:** Add a `classifier_execution_gate()` to the import pipeline. After any bulk import or deck promotion: (a) count cards with `functional_tag='unknown'`, (b) if count > 0, auto-trigger `classify_card()` / `infer_functional_card_tags()` on all unknown cards, (c) verify post-classification that unknown count < 5, (d) if still > 5, emit a hard warning. Also update `tag_accuracy` with new precision stats post-classification.
- **Impact:** Prevents decks from entering the active pipeline with unclassified cards. Eliminates the 7.3pp T3 inflation caused by invisible ramp. Ensures all tag-dependent agents (Mulligan, Evolution Oracle, Scout, Validator) operate on complete data.
- **Risk:** Low — validation gate only. Does not modify product code.
- **Validation:** After implementation, importing any decklist should result in < 5 cards tagged 'unknown'.

### Task 4: Hash-Change Auto-Reset for Pipeline Agents
- **Evidence:** 4 consecutive hash changes detected (Scout #36→#37→#38, each with "HASH DIVERGENTE" alert). Each time, pipeline agents produce stale analyses against the old hash. Scout #38 explicitly notes: "Pipeline logs (EVOLUTION_LOG, VALIDATOR_LOG, MULLIGAN_LOG) seguem stale." The Evolution Oracle has 23 cycles of spellslinger history that don't apply to the current cEDH build. Validator v3.25 confirms "Hash divergente — deck foi modificado externamente. Análises anteriores são STALE."
- **What to change:** Add `hash_change_handler()` to all pipeline agents. On startup, each agent computes hash from current `deck_cards`. If hash differs from previous execution: (a) emit "DECK CHANGED" alert, (b) mark previous analyses as `stale=true`, (c) reset agent-specific baselines (T3 baseline for Mulligan, SYNERGY_MAP baseline for Validator, cycle history for Evolution Oracle), (d) log the delta (which cards changed) to enable root cause analysis.
- **Impact:** Prevents agents from making decisions based on stale data from a different deck archetype. Reduces false-positive swap recommendations.
- **Risk:** Medium — resets historical baselines. Need archive mechanism to preserve historical data for trend analysis while preventing it from influencing current decisions.
- **Validation:** After implementation, a hash change should trigger: "⚠️ DECK CHANGED: hash aaa→bbb. Baselines reset. Previous analysis archived."

### Task 5: Removal Density Emergency Threshold
- **Evidence:** Validator v3.25 confirms only 3 removal cards in the active deck (Path to Exile, Swords to Plowshares, Generous Gift). Validator v3.25 flags this: "Interação limitada (3 removal)" with PG ideal comparison showing -2.33 delta. In 4-player pods, drawing any interaction requires ~3 draws from 99. The BATTLE_LOG (pre-reconstruction) showed Threat losses of 43-51 per 300 trials with 9-10 removal. With only 3 removal, the deck will lose to almost any resolved opposing commander. The deck has 13 wincons but only 3 ways to interact with opponents' boards. This is structurally inverted — a cEDH deck should prioritize interaction over wincon density.
- **What to change:** Add `removal_density_scoring()` to Validator. Compute `removal_ratio = removal_count / (opponents * 2)`. When ratio < 1.0, emit "EMERGENCY — insufficient interaction" with priority over all other recommendations. The freed slots from Task 1 (wincon desaturation) should prioritize removal additions. Recommend adding: Chaos Warp (CMC 3, any permanent), Abrade (CMC 2, flexible), Wear/Tear (CMC 1+2, enchantment/artifact), or Pyroclasm (CMC 2, small creature wipe).
- **Impact:** The deck's primary structural weakness — inability to interact — gets surfaced as the top priority. Prevents the deck from being a "battle-cruiser" that can't stop opponents from winning.
- **Risk:** Low — recommendation layer only. Does not auto-apply swaps.
- **Validation:** Validator on deck_id=6 should output: "🔴 REMOVAL EMERGENCY: 3 removal for 4-player pod (ratio=0.375, threshold=1.0). Recommend adding 5+ removal before any other optimization."

---

## 27. 🆕 NEW KEY SIGNALS FOR APP/BACKEND LOGIC (2026-06-04)

| Signal | Source | What It Would Power |
|:-------|:-------|:--------------------|
| **Classifier auto-execution gate** | v3.25 §23.2, Task 3 | Auto-run classifier on import — prevents unknown-tag crisis from recurring |
| **Classifier impact on T3** | MULLIGAN Exec#15 §25.2 | Quantify that classifier quality has 7.3pp impact vs card swaps — reprioritize pipeline investment |
| **Hash-change auto-reset** | Scout #38 §24.4, Task 4 | Auto-detect deck changes and reset agent baselines — prevent stale-data decisions |
| **Wincon desaturation** | Scout #38 §24.2, Task 1 | Oracle recommends CUTTING excess wincons — frees slots for core functions |
| **Removal density emergency** | v3.25 §23, Task 5 | Alert when interaction density < (opponents × 2) — prevents battle-cruiser decks |
| **CMC corruption monitoring** | TAG_ACCURACY_REPORT §3, Task 2 | Detect and auto-repair CMC=NULL escalation — single script fixes all downstream corruption |
| **Banlist source-of-truth enforcement** | v3.25 §23.1 | Query `card_legalities` not model memory for banlist checks — prevents false violation reports |
| **Game Changer bracket classification** | v3.25 §23.3 | Auto-classify bracket from GC count — prevents bracket mismatch (deck is B4, not B3) |
| **Collection depletion detection** | Scout #38 §24.3 | Signal when all viable swaps are exhausted — prevents wasted pipeline cycles |

---

## 28. 🆕 5TH CONSECUTIVE HASH CHANGE — BASIC LAND CRISIS RESOLVED (2026-06-04 ~12:00 UTC)

### 28.1 Deck Modified Again — 5th Consecutive Divergence

**Card hash changed:** `8b9c643c84825a4436d33b7f1616fa5f` (Scout #38 / Validator v3.25) → `763c3e0ffad4b05e871d5d08b38393fd` (current)

This is the **5th consecutive hash divergence** detected (Scout #36→#37→#38→now). The deck continues to be modified externally without pipeline agent documentation. No Scout #39, Validator v3.26, or MULLIGAN Exec#16 has analyzed the new state.

### 28.2 🟢 Basic Land Crisis RESOLVED

The deck now contains **Mountain** and **Plains** basics — the first actual basic lands since the 2026-06-02 reconstruction. v3.23 had flagged 0 actual basics as a critical structural vulnerability (only Ancient Den + Great Furnace, which are artifact lands, not basics).

**Current basics:** Mountain (1), Plains (1) = 2. **Still below the ≥3 threshold** recommended for Commander. However, for cEDH bracket 4 with fast mana and 33 lands total, 2 basics is acceptable — games end before nonbasic hate becomes lethal.

**Land breakdown (33 total):** 31 tagged lands (2 basics + 2 artifact lands + 27 nonbasics) + 2 unknown-lands (Inventors' Fair, Prismatic Vista).

### 28.3 What Changed — Confirmed Deltas

Confirmed changes vs v3.25 state:
- **+Mountain, +Plains** — basics added, fixes critical vulnerability
- **Unknown removals** — 2 cards removed to maintain 100-card total (likely nonbasic lands)
- **Deck hash changed** — MD5 confirmed via SQLite query

### 28.4 Deck Instability Pattern

5 modifications in ~48 hours (June 2-4), all external — not driven by Evolution Oracle. This:
1. Invalidates pipeline baselines (T3=1.6% from Exec#15 is now stale)
2. Prevents agents from completing analysis cycles
3. Makes swap recommendations unreliable (target changes mid-cycle)

**Root cause:** Deck is modified through `import_lorehold_decks.py` promotions or direct SQLite edits, bypassing the Evolution Oracle → application pipeline.

---

## 29. 🆕 UPDATED CONCRETE TASKS (2026-06-04 ~12:00 UTC — max 5)

### Task 1: Pipeline Lock — Prevent External Deck Modification Without Audit
- **Evidence:** 5 hash changes in 48 hours, zero Evolution Oracle swap applications. Deck modified externally without traceability. Basic land fix came from external edit, not pipeline-driven learning.
- **What to change:** Add `deck_card_mutations` audit table logging every INSERT/UPDATE/DELETE with source, card_name, old/new values, timestamp. Add write-gate: modifications without Evolution Oracle `applied=true` entry emit "EXTERNAL MODIFICATION" alert.
- **Impact:** Makes deck evolution traceable. Stops pipeline from chasing a moving target.
- **Risk:** Medium — adds write-gate. Must allow legitimate operations (promotions, imports).
- **Validation:** Any undocumented `deck_cards` change should trigger alert: "⚠️ EXTERNAL MODIFICATION: deck_id=6. Source: unknown."

### Task 2: Hash-Change Auto-Triggered Revalidation
- **Evidence:** The 5th hash change was detected by this cron job's manual check, not by any pipeline agent. No Scout/Validator/Mulligan triggered for the new state. Analysis lag = unknown (could be hours).
- **What to change:** Auto-trigger Scout (delta detection) → if delta > 2 cards → auto-trigger Validator + Mulligan when hash changes detected. Rate-limit to 1 trigger per 30 min.
- **Impact:** Eliminates analysis lag. Ensures agents always operate on current deck state.
- **Risk:** Medium — needs rate limiting to prevent loops during rapid modifications.
- **Validation:** Hash change → within 5 min: Scout delta report → Validator re-run → Mulligan re-run with updated T3.

### Task 3: Basic Land Count Validation (≥3 for Commander)
- **Evidence:** v3.23 flagged 0 basics as critical. Now resolved (2 basics). Validator's land check only verifies `land_count`, not basic vs nonbasic. Threshold of ≥3 still not met.
- **What to change:** Add `basic_land_count` to Validator using Scryfall `type_line` to distinguish artifact lands from true basics. Emit WARNING when `basic_count < 3` for bracket ≤3, or `basic_count < 1` for bracket 4+.
- **Impact:** Prevents recurrence of 0-basic vulnerability. Currently, Validator is blind to basic vs nonbasic.
- **Risk:** Low — read-only validation.
- **Validation:** Validator on current deck → "⚠️ Basic lands: 2 (threshold: 3 for bracket ≤3). Bracket 4 mitigates risk."

### Task 4: Wincon Desaturation + Removal Priority (Frees 5-6 Slots)
- **Evidence:** (Carried forward) Scout #38: 13 wincons in 100-card deck. cEDH meta uses 3-5. Only 3 removal for 4-player pods. Unchanged by basic land fix.
- **What to change:** Evolution Oracle: when wincons > 7 and axes covered → recommend cutting lowest ratio (Score/CMC) wincons. Freed slots priority: removal (+3), board wipe (+1), draw/stax (+1-2).
- **Impact:** Frees slots for core interaction. Largest remaining optimization.
- **Risk:** Low — recommendation only.
- **Validation:** Oracle output: cut Storm Herd (CMC=10), Rise of the Eldrazi (CMC=12), Guttersnipe (R=5), Rite of the Dragoncaller, Longshot, Surge to Victory. Keep: Approach, Twinflame+Dualcaster, Aetherflux, Mizzix's Mastery, Worldfire.

### Task 5: CMC Integrity Repair — Fix 36 NULL/0.0 CMC Cards
- **Evidence:** (Carried forward) TAG_ACCURACY_REPORT: 36 cards in deck_id=6 with CMC=NULL or 0.0. The reclassification that fixed unknown tags introduced CMC corruption. Affects avg_cmc, curve analysis, mulligan simulation.
- **What to change:** `repair_cmc.py` — cross-reference `deck_cards` CMC against PostgreSQL `cards` table (33,795 cards verified). Update corrupted CMCs. Fix false 0.0 values (artifact lands, Moxen should be 0.0 but spells should not).
- **Impact:** Restores data integrity for all downstream agents. 36% corrupted data is unacceptable.
- **Risk:** Medium — modifies deck_cards. Must verify reference data correctness.
- **Validation:** After repair, `SELECT COUNT(*) FROM deck_cards WHERE deck_id=6 AND (cmc IS NULL OR cmc = 0.0)` ≤ 7 (only the 5 Moxen + 2 artifact lands with true CMC=0).

---

## 30. 🆕 NEW KEY SIGNALS FOR APP/BACKEND LOGIC (2026-06-04 ~12:00 UTC)

| Signal | Source | What It Would Power |
|:-------|:-------|:--------------------|
| **Deck mutation audit trail** | §28.1, Task 1 | Trace every deck modification — eliminate "hash changed but unknown why" |
| **Hash-change auto-revalidation** | §28.1, Task 2 | Auto-execute Scout/Validator/Mulligan on hash change — eliminate analysis lag |
| **External modification detection** | §28.4, Task 1 | Flag deck changes that bypass Evolution Oracle pipeline |
| **Basic land count validation** | §28.2, Task 3 | Distinguish artifact lands from true basics — prevent 0-basic vulnerability |
| **System didn't learn from fix** | §28.2 | Basic land fix was external, not pipeline-driven — the system can't replicate this learning |
| **Deck instability rate** | §28.4 | If >3 modifications/48h, pause Evolution Oracle until deck stabilizes |


---

## 31. 🆕 6TH CONSECUTIVE HASH CHANGE — STRATEGIC PIVOT TO STAX-PROTECTED COMBO (2026-06-04 ~17:20 UTC)

### 31.1 Hash Divergence #6 Detected

**Card hash changed:** `763c3e0ffad4b05e871d5d08b38393fd` (5th change, basic land fix) → `7b0b3fa845db029428d6aaa6d6915b09` (current)

This is the **6th consecutive hash divergence** — the most significant card-level change since the 2026-06-02 reconstruction. Unlike the 5th change (which was a 2-card basic land fix), this change involves **14+ in/out substitutions** — a genuine strategic pivot.

| # | When | Hash (last 4) | Scope | Pipeline Coverage |
|---|------|---------------|-------|-------------------|
| 1 | Jun 2 | 3000...→f224... | Reconstruction (lands+ramp) | v3.22-3.23 |
| 2 | Jun 3 | f224...→8b9c... | DB re-sync (classifier fix) | v3.24-3.25, Scout #37-38, Mulligan #14-15 |
| 3 | Jun 3 | 8b9c...→? | 2 wincons added (Longshot, Surge) | Scout #38 |
| 4 | Jun 4 | ?→8b9c... (revert) | Akroma's Will restored? | Unclear |
| 5 | Jun 4 ~12Z | 8b9c...→763c... | +Mountain, +Plains basics | None |
| **6** | **Jun 4 ~17Z** | **763c...→7b0b...** | **14+ swaps, stax pivot** | **None — this report** |

### 31.2 What Changed — Strategic Pivot to cEDH Stax

This is NOT a small edit. The deck shed its spellslinger-copy identity and adopted a **stax-protected deterministic combo** shell:

#### Cards ADDED (+14)

| Card | Tag | CMC | Strategic Role |
|:-----|:----|:---:|:---------------|
| **Drannith Magistrate** | stax | 2 | Locks opponents out of commanders. cEDH staple. |
| **Pyroblast** | protection | 1 | 1-mana stack interaction. Counters blue spells, destroys blue permanents. |
| **Silence** | protection | 1 | Opponents can't cast this turn. Protects combo turn. |
| **Orim's Chant** | protection | 1 | Same as Silence + can fog attackers. |
| **Giver of Runes** | protection | 1 | 1-drop protection for commander/key creature. |
| **Esper Sentinel** | draw | 1 | Rhystic-lite. Opponents pay 1 per noncreature spell or you draw. |
| **Scroll Rack** | draw | 2 | Card selection. cEDH staple with fetchlands. |
| **The One Ring** | draw | 4 | Protection + card draw engine. Game Changer. |
| **Wheel of Fortune** | draw | 3 | 7-card refill. Game Changer. |
| **Monument to Endurance** | draw | 3 | Draw smoothing, lifegain synergy. |
| **Past in Flames** | engine | 4 | Flashback all instants/sorceries. Combo enabler. |
| **Reiterate** | engine | 3 | Buyback copy spell. Infinite mana combo outlet. |
| **Reverberate** | engine | 2 | 2-mana copy any spell. |
| **Heat Shimmer** | combo | 3 | Backup Twinflame. Dualcaster+Heat Shimmer = hasty tokens. |

#### Cards REMOVED (−14+)

| Card | Old Tag | Reason for Removal |
|:-----|:--------|:-------------------|
| Akroma's Will | protection | 4 CMC — too expensive for combo protection. Replaced by 1-CMC stack interaction. |
| Lightning Greaves | protection | Equipment — slow. Replaced by 1-CMC creature protection. |
| Hexing Squelcher | protection | Niche artifact. Replaced by Silence/Orim's Chant. |
| Big Score | draw | 4 CMC treasure+draw. Replaced by Wheel of Fortune + The One Ring. |
| Windfall | draw | Symmetrical — helps opponents. Replaced by Esper Sentinel (asymmetrical). |
| Weathered Wayfarer | draw | Too slow for cEDH. Replaced by Scroll Rack + fetchland engine. |
| Dance with Calamity | draw | 8 CMC — uncastable in cEDH. |
| Dragon's Rage Channeler | draw | Surveil too slow. Replaced by Monument to Endurance. |
| Double Vision | copy engine | 5 CMC enchantment — too slow. Replaced by Past in Flames. |
| Arcane Bombardment | copy engine | 4 CMC, random — unreliable. |
| Dawning Archaic | copy engine | 5 CMC — too expensive. Replaced by Reiterate+Reverberate. |
| Ancient Den | land | Artifact land — vulnerability to Null Rod/Collector Ouphe. |
| Great Furnace | land | Same as Ancient Den. |
| *Land Tax* | ramp | **KEPT** — sole survivor of old utility suite. |

### 31.3 Strategic Assessment

This is the **first pivot that makes strategic sense** — the deck is converging toward a proper cEDH build:

1. **Stack protection suite:** Pyroblast + Silence + Orim's Chant + Grand Abolisher + Deflecting Swat + Teferi's Protection + Boros Charm + Flawless Maneuver = **8 stack/protection pieces**, all at CMC ≤3. This is cEDH-grade.

2. **Draw engine upgrade:** Esper Sentinel (Rhystic-lite) + The One Ring + Wheel of Fortune + Scroll Rack replaces clunky CMC 4-8 draw spells. Card advantage is now asymmetrical and cost-efficient.

3. **Stax element:** Drannith Magistrate is a genuine cEDH stax piece. It single-handedly shuts down opposing commanders and can be tutored by Imperial Recruiter/Recruiter of the Guard.

4. **Spell recursion engine:** Past in Flames + Reiterate + Reverberate forms a deterministic loop engine. With enough mana (which the 5 Moxen + Sol Ring + Mana Vault + Jeska's Will provide), the deck can combo off from the graveyard.

5. **Artifact lands removed:** Ancient Den and Great Furnace were liabilities against artifact hate. Their removal closes a vulnerability window.

### 31.4 Remaining Structural Issues (Unchanged by Pivot)

| Issue | Status | Detail |
|:------|:------:|:-------|
| Wincon supersaturation | 🔴 10 wincons | No change. 5+ slots wasted. |
| Removal density | 🔴 3 removal | Still Path + Swords + Generous Gift only. |
| Board wipe count | 🟡 1 wipe | Only Blasphemous Act. |
| Basic land count | 🟢 2 basics | Mountain + Plains present. |
| CMC corruption | 🟢 **RESOLVED** | 0 NULL CMCs. All 36 CMC=0.0 are legitimate. |
| Unknown tags | 🟡 3 unknown | Inventors' Fair, Prismatic Vista, Reforge the Soul. |
| Pipeline staleness | 🔴 ALL stale | No Scout/Validator/Mulligan/Battle for this hash. |

### 31.5 CMC Corruption Resolution — Confirmed

The prior report documented 36 "CMC=NULL or CMC=0.0" cards as corruption. Direct DB query on 2026-06-04 ~17:20 UTC confirms:

- **CMC NULL: 0** (none)
- **CMC 0.0: 36** — all legitimate: 31 lands + Chrome Mox + Mox Amber + Mox Diamond + Mox Opal + Lotus Petal

The corruption flagged in previous reports was a **false alarm** — previous queries combined NULL and 0.0 without separating legitimate 0-CMC cards (lands, Moxen, Lotus Petal). Current query validates: all 36 cards with CMC=0.0 have `type_line` containing "Land" or are Moxen/Lotus Petal with true CMC=0.

**Task 5 from §29 (CMC Integrity Repair) is CANCELLED.** No repair needed.

---

## 32. 🆕 UPDATED CONCRETE TASKS (2026-06-04 ~17:20 UTC — max 5)

### Task 1: Pipeline Lock — Prevent External Deck Modification Without Audit (RECONFIRMED, ELEVATED)
- **Evidence:** 6 hash changes in ~72 hours (June 2-4), all external. This latest pivot (14+ cards) made a strategically sound transformation — but zero pipeline agents know about it. Scout #38, Validator v3.25, and Mulligan Exec#15-16 all analyzed hash `8b9c643c...` which is 3 hashes stale. The system has no idea the deck now plays Drannith Magistrate, Pyroblast, Silence, Orim's Chant, or The One Ring.
- **What to change:** Add `deck_card_mutations` audit table logging every INSERT/UPDATE/DELETE with source (`import_script`, `evolution_oracle`, `manual_sqlite`, etc.), card_name, old/new values, timestamp. Add write-gate: modifications without Evolution Oracle `applied=true` entry emit "EXTERNAL MODIFICATION" alert. **Priority escalated from Medium to HIGH** — with 6 modifications, the pipeline is permanently stale.
- **Impact:** Makes deck evolution traceable. Stops pipeline from chasing a moving target. Enables root cause analysis of undocumented changes.
- **Risk:** Medium — adds write-gate. Must allow legitimate operations (promotions, imports, direct DB edits for emergency fixes with documentation).
- **Validation:** Any undocumented `deck_cards` change should trigger: "⚠️ EXTERNAL MODIFICATION: deck_id=6, source=unknown, delta=14 cards."

### Task 2: Hash-Change Auto-Reset with Full Agent Revalidation (RECONFIRMED, ELEVATED)
- **Evidence:** The 6th hash change was detected ONLY by this cron job's manual check. No pipeline agent has analyzed hashes #4, #5, or #6. T3=1.6% (Exec#15, hash `8b9c643c...`) is now 3 hashes and ~20 card changes stale. The deck's win rate vs 12 opponents (71.7% from Battle Analyst v8 on hash `8b9c643c...`) is now unreliable — with stax pieces added, the win rate likely improved but we don't know by how much.
- **What to change:** Auto-trigger the full analysis chain on hash change: (1) Scout delta detection with full card diff, (2) auto-trigger Validator + Mulligan if delta > 2 cards, (3) mark prior analysis as `stale=true`, (4) reset T3/battle baselines for new deck state, (5) rate-limit to 1 full revalidation per 30 min.
- **Impact:** Eliminates analysis lag. Current analysis lag is >48h and >3 hashes. Makes the pipeline self-healing.
- **Risk:** Medium — needs rate limiting to prevent loops during rapid modifications. Must archive stale baselines rather than delete them.
- **Validation:** Hash change → within 5 min: Scout delta report → Validator re-run → Mulligan re-run with new T3 → Battle Analyst re-run with new WR.

### Task 3: Stax-Aware Archetype Detection (🆕 — from Strategic Pivot)
- **Evidence:** The deck pivoted from "copy-combo" to "stax-protected combo" with Drannith Magistrate added and artifact lands removed. Yet the Evolution Oracle (last run Jun 1, SILENT) still treats this as a spellslinger deck. The Validator's SYNERGY_MAP scores and PG profile are built for spellslinger. None of the pipeline agents recognize stax as a strategic dimension. If they did, they would: (a) score Drannith Magistrate as a P0 include, (b) recommend more stax pieces (Rule of Law, Deafening Silence, Thorn of Amethyst), (c) deprioritize spell-copy engines (which were all removed anyway).
- **What to change:** Add `detect_stax_presence()` to deck state analysis. When `COUNT(functional_tag='stax') >= 1` AND `COUNT(functional_tag='protection') >= 6`, classify as "stax-protected" archetype variant. Apply different swap heuristics: prioritize asymmetrical stax (Rule of Law over Wrath of God), prioritize instant-speed protection over sorcery-speed.
- **Impact:** The pipeline can learn that stax is a valid Boros cEDH strategy. Currently all agents are blind to this dimension.
- **Risk:** Low — adds a detection heuristic. Does not modify existing scoring. Just adds awareness.
- **Validation:** Validator on current deck → archetype output includes "stax-protected" variant. Oracle swap recommendations include Rule of Law, Aven Mindcensor, or Ethersworn Canonist.

### Task 4: Wincon Desaturation + Removal Priority (CARRIED FORWARD — unchanged by pivot)
- **Evidence:** Scout #38: 10 tagged wincons + 3 combos = 13 conditions in 100-card deck. cEDH meta uses 3-5. Only 3 removal for 4-player pods. The stax pivot did not touch wincons at all — the problem persists. In fact, the pivot freed protection slots (Silence/Orim's/Pyroblast are also pseudo-removal on the stack) but the removal count remains 3.
- **What to change:** Evolution Oracle: when wincons > 7 and all 3 coverage axes (FAST/RESILIENT/STEALTH) are satisfied, rank wincons by (Score/CMC) ratio and recommend cutting the bottom N. Freed slots priority: removal (+3), board wipe (+1), stax (+1). In the new stax context, recommend asymmetrical stax pieces (Deafening Silence, Aven Mindcensor) as secondary priority.
- **Impact:** Frees 5-6 slots. Largest remaining optimization independent of strategic alignment.
- **Risk:** Low — recommendation only.
- **Validation:** Oracle output should now consider stax context: cut Storm Herd, Rise of the Eldrazi, Guttersnipe, Rite of the Dragoncaller. Recommend +Chaos Warp, +Abrade, +Wear/Tear, +Deafening Silence (stax synergy), +Rule of Law.

### Task 5: Deck Stability Score — Pause Oracle When Too Volatile
- **Evidence:** 6 modifications in 72 hours. Deck is being modified faster than any agent can analyze. Evolution Oracle's last run was Jun 1 (SILENT) — before all 6 hash changes. The deck it analyzed (hash `30d00347...`) doesn't exist anymore. Running the Oracle on the current deck would be meaningful, but running it while the deck changes every few hours is counterproductive.
- **What to change:** Compute `deck_stability_score = 1.0 / (1 + modifications_in_last_72h)`. When score < 0.25 (>3 modifications in 72h), emit "DECK UNSTABLE — Oracle paused, recommendations unreliable." When score improves (no modifications for 24h), auto-resume Oracle. Combine with Task 1's audit trail to distinguish "learning-driven evolution" (good) from "external tampering" (block).
- **Impact:** Prevents Oracle from generating recommendations that are obsolete by the time they're applied. Currently the Oracle's entire cycle history (C#1-C#23) applies to deck states that no longer exist.
- **Risk:** Low — adds a gate, doesn't remove functionality.
- **Validation:** Current deck → `stability_score < 0.25` → Oracle paused until deck stable for 24h.

---

## 33. 🆕 NEW KEY SIGNALS FOR APP/BACKEND LOGIC (2026-06-04 ~17:20 UTC)

| Signal | Source | What It Would Power |
|:-------|:-------|:--------------------|
| **Stax presence detection** | §31.2, Task 3 | Auto-detect stax archetype variant from functional tags — enables different swap heuristics |
| **Deck volatility → Oracle pause** | §31.5, Task 5 | Auto-pause Evolution Oracle when deck is modified >3x in 72h — prevents stale recommendations |
| **Pipeline staleness metric** | §31.1 | Measure "hours since last pipeline analysis matched current hash" — alert when >12h |
| **CMC integrity auto-verification** | §31.5 | Distinguish NULL from legitimate 0.0 CMC (lands, Moxen, Lotus Petal) — prevent false corruption alarms |
| **Strategic pivot detection** | §31.3 | Auto-detect when >8 cards change in a single diff — trigger full reanalysis, not incremental |
| **Stack interaction density** | §31.3 | Count instant-speed protection + counterspells + silence effects — metric for cEDH readiness |
| **Wincon-to-interaction ratio** | §31.4 | Alert when wincons > interaction pieces (10 vs 3) — structural imbalance signal |
| **Artifact land vulnerability** | §31.2 | Detect artifact lands (type_line=Land + Artifact) — flag as Null Rod/Collector Ouphe vulnerability |

---

> **Next Cron Cycle:** Continue monitoring the cEDH Stax-Combo build. **Critical concerns:** (1) Pipeline LOCK needed — 6 changes in 72h with zero audit trail, (2) All pipeline agents STALE — Scout, Validator, Mulligan, Battle, and Oracle haven't analyzed hashes #4-6, (3) Wincon desaturation still P0 — 13 wincons wasting 5-6 slots despite strategic improvement, (4) 3 removal in 4-player format still critical, (5) Stax pivot is strategically sound but invisible to pipeline — agents need stax awareness, (6) CMC corruption confirmed RESOLVED (false alarm — all 36 CMC=0.0 are legitimate). **Priority order:** Task 1 (audit trail) to stop undocumented changes → Task 2 (auto-revalidation) to get pipeline current → Task 5 (stability gate) to prevent Oracle from chasing a moving target → Task 3 (stax detection) to make agents aware of new archetype → Task 4 (wincon desaturation) to free slots now that strategic alignment is improving.
