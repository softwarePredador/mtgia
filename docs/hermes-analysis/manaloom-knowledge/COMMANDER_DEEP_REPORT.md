# Commander Deep Knowledge Report

> **Generated:** 2026-06-09 ~13:30 UTC | **Updated:** 2026-06-09 ~13:30 UTC
> **Commander:** Lorehold, the Historian
> **Color Identity:** Boros (RW)
> **Archetype:** ❌ **WR COLLAPSE DETECTED** — Fast cEDH Combo (Bracket 4). Post-reconstruction WR **25–29%** (600 games, 12 real opponents, 2026-06-09T11:36Z). Quality gate baseline: **8.3%** (12 games, 1/game-per-opponent). Previous state (Jun 7): **75.2%** WR.
> **Source Agent:** Commander Knowledge Deep Cron Job
> **Evidence Base:** BATTLE_LOG (Jun 9 runs), knowledge.db deck_id=6 query, optimizer_baseline_runs (3 baselines today), master_optimizer_quality_gate (Jun 9), optimizer_applied_swaps (empty — no applied swaps found)

## 🚨 CRITICAL: Lorehold WR Collapse — Deck Reconstructed Outside Pipeline

### What Happened

Between **2026-06-07 20:06Z** (last high-WR run: 75.2%, L=33 R=19 X=4 CMC=2.85) and **2026-06-09 09:59Z** (first run today: 29.2%), the Lorehold deck in knowledge.db (deck_id=6) underwent a **radical reconstruction** that decimated its win rate.

**Before (Jun 7, documented in SCOUT/VALIDATOR):**
| Metric | Value |
|:-------|:-----:|
| Lands | 35 |
| Ramp | 16–19 |
| Removal | 9 |
| Protection | 9 |
| Tutors | 2 |
| Wincons | 14 |
| Avg CMC | ~3.69 |
| WR vs Real | 75.2% |

**Current (Jun 9, actual DB state):**
| Metric | Value |
|:-------|:-----:|
| Lands | 31 |
| Ramp | 19 |
| Removal | **4** ⚠️ |
| Protection | 10 |
| Tutors | **5** |
| Wincons | 10 |
| Avg CMC | **2.80** |
| WR vs Real | **25–29%** 🔴 |

**WR Delta: −46 to −50 percentage points** (75% → 25–29%).

### Key Structural Changes

1. **Fast mana package added (cEDH-style):** Chrome Mox, Mox Diamond, Mox Opal, Mox Amber, Lotus Petal, Mana Vault, Mana Geyser, Rite of Flame, Seething Song — 19 ramp slots, highest ever.

2. **Removal gutted from 9→4:** Lost Blasphemous Act, Abrade, Chaos Warp, Austere Command, Call Forth the Tempest, Volcanic Vision. Remaining: Path to Exile, Swords to Plowshares, Generous Gift, Rapid Hybridization (4 total).

3. **Tutors quintupled (2→5):** Added Recruiter of the Guard, Imperial Recruiter, Ranger-Captain of Eos alongside existing Enlightened Tutor and Gamble.

4. **Combo package added:** Twinflame + Dualcaster Mage + Heat Shimmer deterministic line finally present (was documented as "missing" in all previous reports).

5. **Stax trimmed to 1 card:** Only Drannith Magistrate remains. Silence/Orim's Chant moved to protection.

6. **Wincon diversity shifted:** Added Aetherflux Reservoir, Fiery Emancipation, Guttersnipe, Longshot (creature-based), Surge to Victory. Retained Approach, Worldfire, Mizzix's Mastery, Storm Herd, Rise of the Eldrazi.

### Anti-Patterns Observed

1. **Removal starvation (4 pieces is lethal):** The deck has 4 removal cards to answer threats from 3 opponents. The BATTLE_LOG shows **0 stalls** in the June 9 runs — the deck doesn't stall, it **dies outright** to aggressive opponents. Every June 9 opponent that won had 100% "elimination" as win reason.

2. **Low land count (31) with high CMC wincons:** 10 lands were cut (35→31) but wincons like Rise of the Eldrazi (CMC 10), Storm Herd (CMC 10), Worldfire (CMC 9), Approach (CMC 7), and Fiery Emancipation (CMC 6) remain. Fast mana artifacts don't count toward land drops, so the deck has ~8 functionally uncastable hands per 100.

3. **Approach usage cratered:** In June 7 runs, Approach accounted for ~40-55% of wins. In June 9 runs, Approach appears in only 1-2 wins per 50 games (≈3% of wins). The fast mana+combat approach wins via elimination, but the deck lacks the creature density to close consistently.

4. **0 applied swaps in optimizer_applied_swaps:** The deck was modified **outside** the optimizer pipeline. No rollback path exists. The `optimizer_applied_swaps` table is empty.

5. **3 cards tagged 'unknown':** Inventors' Fair, Prismatic Vista, and Reforge the Soul have no functional tag — the tag completeness problem persists.

---

## 1. Archetype Overview (Current State)

```
Fast Mana → Combo/Combat → Mixed Wincon
```

The deck has been rebuilt as a "fast cEDH Boros" list: maximize 0-1 CMC mana artifacts, add the Twinflame+Dualcaster loop, protect with 10 pieces of stack/combat protection, and close with whatever wincon survives. This is the deck configuration the "best-of-learned" corpus recommended (20 lands ideal, fast mana, 6+ tutors, combo lines).

However, the battle sim shows this build **cannot survive** against real opponents in 4-player pods. The removal density is too low, the land count is too low for the 7+ CMC wincons, and the combo line (Twinflame+Dualcaster) requires both pieces + 4 mana at a time when opponents are deploying threats.

### Deck Skeleton (DB State, deck_id=6, hash a17a5863c95fe95eaf3c379708c767f04c9854d131994cc6a92dc512a3ce02c9)

| Category | Count | Key Cards |
|:---------|:-----:|:----------|
| Lands | 31 | Ancient Tomb, Gemstone Caverns, Urza's Saga, 7 fetch, Plateau, Sacred Foundry |
| Ramp | 19 | Chrome Mox, Mox Diamond, Mox Opal, Mox Amber, Lotus Petal, Mana Vault, Sol Ring, Arcane Signet, Boros Signet, Talisman, Ruby Medallion, Fellwar Stone, Birgi, Jeska's Will, Seething Song, Rite of Flame, Mana Geyser, Smothering Tithe, Storm-Kiln Artist |
| Draw | 9 | The One Ring, Wheel of Fortune, Esper Sentinel, Faithless Looting, Scroll Rack, Top, Valakut Awakening, Monument to Endurance, Unexpected Windfall |
| Removal | **4** ❌ | Path to Exile, Swords to Plowshares, Generous Gift, Rapid Hybridization |
| Protection | 10 | Silence, Orim's Chant, Pyroblast, Boros Charm, Deflecting Swat, Flawless Maneuver, Teferi's Protection, Giver of Runes, Mother of Runes, Grand Abolisher |
| Tutors | 5 | Enlightened Tutor, Gamble, Recruiter of the Guard, Imperial Recruiter, Ranger-Captain of Eos |
| Wincon | 10 | Approach, Worldfire, Mizzix's Mastery, Aetherflux Reservoir, Fiery Emancipation, Guttersnipe, Longshot, Storm Herd, Surge to Victory, Rise of the Eldrazi |
| Combo | 3 | Twinflame, Dualcaster Mage, Heat Shimmer |
| Engine | 3 | Past in Flames, Reiterate, Reverberate |
| Stax | 1 | Drannith Magistrate |

**Avg CMC (nonland):** 2.80 — lowest ever recorded for this deck.

---

## 2. Ramp Patterns

### Fast Mana Explosion

The deck now has 19 ramp sources including 5 zero-CMC artifacts (Chrome Mox, Mox Diamond, Mox Opal, Mox Amber, Lotus Petal). This is the densest ramp suite ever attempted for Lorehold.

| Mana Source | CMC | Type | Value |
|:------------|:---:|:----|:------|
| Chrome Mox | 0 | Fast mana | Free mana with card to imprint |
| Mox Diamond | 0 | Fast mana | Free mana with land to discard |
| Mox Opal | 0 | Fast mana | Conditional (need 2 other artifacts) |
| Mox Amber | 0 | Fast mana | Conditional (need legendary) |
| Lotus Petal | 0 | Fast mana | One-shot free mana |
| Mana Vault | 1 | Fast mana | 3 mana for 1, upkeep cost |
| Sol Ring | 1 | Fast mana | 2 for 1 |
| Rite of Flame | 1 | Ritual | RRR for 1 mana |
| Seething Song | 3 | Ritual | RRRRR for 3 mana |
| Mana Geyser | 5 | Ritual | Huge burst in late game |

**PG Profile Gap:** The ideal for Lorehold is 3.67 ramp rocks + 10 ritual/treasure = ~14 total ramp. At 19, the deck is over-ramped by 36% — 5 slots that could be removal, draw, or wincons.

**Anti-Pattern:** 5 zero-CMC artifacts create explosive T1-T2 starts, but after the initial burst the deck lacks the card advantage to recover. The BATTLE_LOG shows no stalls (0/600) — the deck either wins fast or dies fast. This is the hallmark of a glass-cannon build.

**Signal for App/Backend Logic:**
- Ramp should be scored with **diminishing returns**: beyond ~15 ramp sources in Boros, each additional ramp slot has negative marginal value if removal density drops below 8.
- A `ramp_to_removal_ratio` metric: if ramp > 2× removal, the deck is over-committed to speed at the cost of safety.

---

## 3. Draw Patterns

### High-Impact Draw Engine

With 9 tagged draw sources, the deck is better-equipped for card advantage than any previous state.

| Card | CMC | Mechanism |
|:-----|:---:|:----------|
| The One Ring | 4 | Protection + 1 draw per turn (cumulative) |
| Wheel of Fortune | 3 | Wheel (symmetrical, but cheap) |
| Esper Sentinel | 1 | Conditional draw per opponent spell |
| Faithless Looting | 1 | Filter (flashback) |
| Sensei's Divining Top | 1 | Topdeck selection |
| Scroll Rack | 2 | Hand-to-top swap |
| Valakut Awakening | 3 | Hand reset |
| Monument to Endurance | 3 | Conditional draw per damage |
| Unexpected Windfall | 4 | Draw 2 + 2 treasures |

**Draw quality:** The One Ring + Wheel of Fortune + Top + Scroll Rack is a strong draw engine by Boros standards. Previously the deck relied on Windfall (symmetrical), Dance with Calamity (high variance), and Faithless Looting (filter only).

**Anti-Pattern:** 4 of the 9 draw sources (Esper Sentinel, Monument to Endurance, Wheel of Fortune, Unexpected Windfall) are **conditional or symmetrical** — Esper Sentinel dies to removal, Monument requires taking damage, Wheel refills opponents' hands. The deck lacks consistent unconditional draw.

**Signal for App/Backend Logic:**
- Draw quality tier: unconditional > conditional > symmetrical > filter.
- A deck with ≥50% conditional/symmetrical draw sources has unreliable card advantage.
- The One Ring is Boros's best draw engine and should be scored accordingly.

---

## 4. Removal Patterns

### Critical Removal Gap ❌

| Card | CMC | Target | Type |
|:-----|:---:|:------|:----|
| Path to Exile | 1 | Any creature | Exile (gives land) |
| Swords to Plowshares | 1 | Any creature | Exile (gives life) |
| Generous Gift | 3 | Any permanent | Destroy (gives 3/3) |
| Rapid Hybridization | 1 | Any creature | Destroy (gives 3/3) |

**4 removal pieces total.** This is the lowest removal density of any Lorehold build in the historical record (previous lows were 9).

**Missing critical removal that was in previous builds:**
- Blasphemous Act (board wipe, often 1 mana)
- Abrade (artifact + creature)
- Chaos Warp (any permanent, no creature drawback)
- Austere Command (modular board wipe)
- Call Forth the Tempest (board wipe + cascade)

**Impact:** The BATTLE_LOG shows every opponent win is via "elimination" (combat damage). With no board wipes and only 4 spot removal, the deck can't answer a single go-wide strategy. Against Krenko (aggro), the deck went 26-37% WR. Against opponents that flood the board (Thrasios, Rograkh, Kinnan), the deck often goes 0% WR.

**Anti-Pattern:** The 10 protection cards include 4 combat-protection pieces (Teferi's Protection, Flawless Maneuver, Boros Charm, Giver/Mother of Runes) — but protection is reactive, not proactive. Protection saves your pieces; removal removes their pieces. A deck with 10 protection and 4 removal has the priorities inverted for a non-combo meta.

**Signal for App/Backend Logic:**
- A `removal_to_protection_ratio` metric: if protection > removal, the deck is optimizing for survivability over threat management.
- Minimum removal threshold: 8 for Boros, 6 for non-green, 4 for cEDH (but only if a deterministic 2-card combo exists).

---

## 5. Win Condition Patterns

### Wincon Scorecard (from knowledge.db)

| Card | CMC | Category | Reliability |
|:-----|:---:|:---------|:-----------:|
| Approach of the Second Sun | 7 | Primary | ✅ Historic strong (now underperforming) |
| Worldfire | 9 | Reset | ❌ No post-resolution plan |
| Mizzix's Mastery | 4 | GY Value | 🟡 Conditional on GY setup |
| Aetherflux Reservoir | 4 | Combo | 🟡 Needs 50+ life/turns |
| Fiery Emancipation | 6 | Combat | ❌ Only if creatures survive |
| Guttersnipe | 3 | Pinger | 🟡 Needs spells cast pattern |
| Storm Herd | 10 | Token | ❌ CMC prohibitive with 31 lands |
| Surge to Victory | 6 | Combat | ❌ Needs attacking creature |
| Rise of the Eldrazi | 10 | Huge creature | ❌ CMC prohibitive |
| Longshot, Rebel Bowman | 4 | Creature | ❌ Unlikely to close games |

**Win Rate by Win Reason (Jun 9, 600-game run):**
| Win Reason | Count | % of Wins |
|:-----------|:-----:|:---------:|
| elimination (combat) | 169 | 97.1% |
| approach (Approach 2nd Sun) | 5 | 2.9% |

**Key finding:** Approach accounted for 89.9% of wins in May 31 runs. In the current build, it accounts for **2.9%**. The deck abandoned its primary win line without replacing it with an equivalent.

### Main Win Lines

**A) TWINFLAME + DUALCASTER MAGE (New — Combo)**
```
2RR + creature: Cast Twinflame → Dualcaster ETB → Copy Twinflame → Loop
```
- CMC 4 total. Instant speed. First deterministic combo in Lorehold's history.
- **Problem:** Requires both pieces in hand/board + 4 mana + no opponent interaction. With 4 removal pieces, the deck can't protect the combo from opponent disruption.

**B) APPROACH + TOPDECK MANIPULATION (Degraded)**
```
Cast Approach → Manipulate top → Cast Approach again
```
- Previously the primary win line (365/406 wins in May 31). Now almost unused (2.9%).
- **Root cause:** Lower land count (31) + fewer draw/filter pieces tuned for this line + opponents' faster pressure.

**C) AETHERFLUX RESERVOIR (New — Unproven)**
```
Spam spells → Gain life → Activate Reservoir for 50
```
- Theoretically strong with 19 ramp + 10 protection + 3 copy engines.
- **Problem:** 0 wins attributed to Reservoir in June 9 BATTLE_LOG runs.

### Wincon Anti-Patterns

1. **Identity crisis**: The deck has 10 wincons (high quantity) but no coherent plan. Fast mana → combo is contradicted by Approach (needs 2 casts). Combat wincons (Fiery Emancipation, Storm Herd) require surviving board states that 4 removal pieces can't maintain.

2. **CMC mismatch**: 4 wincons at CMC 9+ (Worldfire, Storm Herd, Rise of the Eldrazi) with only 31 lands. The probability of casting a 9+ CMC spell without ramp is approximately 18% by turn 10.

3. **No post-Worldfire plan**: Worldfire remains a "symbolic wincon" — high resilience but no closing mechanism. The deck never won via Worldfire in any BATTLE_LOG run.

4. **Stealth vacuum persists**: Despite adding Twinflame+Dualcaster, the BATTLE_LOG shows 0 combo wins. The combo line exists on paper but doesn't function in practice against real opponents.

---

## 6. Performance Metrics (June 9, 2026)

### Battle Run #1 (09:59Z — 10 games/opponent, 12 opponents, 120 games)
| Metric | Value |
|:-------|:-----:|
| Overall WR | 29.2% (35W/85L) |
| Best matchup | Kefka, Court Mage: 70.0% |
| Worst matchup | Arcum Dagsson & Etali: 0.0% |
| Stalls | 0 |
| Win method | 100% elimination |

### Battle Run #2 (11:36Z — 50 games/opponent, 12 opponents, 600 games)
| Metric | Value |
|:-------|:-----:|
| Overall WR | **29.0%** (174W/426L) |
| Best matchup | Thrasios #159: 38.0% |
| Worst matchup | Sauron: 24.0% |
| Stalls | 0 |
| Win method | 97.1% elimination, 2.9% approach |

### Battle Run #3 (11:48Z — 10 games/opponent, deck_id=14)
| Metric | Value |
|:-------|:-----:|
| Overall WR | 20.8% (25W/95L) |
| Structure | 99 cards, L=31, avg CMC 4.147 |

### Quality Gate Baseline (12:04Z — 1 game/opponent)
| Metric | Value |
|:-------|:-----:|
| Baseline WR | **8.3%** (1W/11L) |

### Primary Loss Modes (600-game sample)

| Loss Type | Count | % of Losses | Root Cause |
|:----------|:-----:|:-----------:|:-----------|
| **life_zero (elimination)** | 426 | 100% | Deck dies before it can execute any wincon |
| stall | 0 | 0% | No stalls — deck either wins or dies fast |

The loss profile has **inverted** from previous reports. In May, stalls were 83-91/300 (primary loss mode). Now, stalls are 0 and elimination is 100%. The deck went from "survives but can't close" to "dies fast, occasionally wins fast."

---

## 7. Key Signals for App/Backend Logic

| Signal | Source | What It Would Power |
|:-------|:-------|:--------------------|
| **Ramp-to-removal ratio guard** | Current crisis | Alert when ramp > 2× removal in non-cEDH builds |
| **Combo viability detection** | Twinflame+Dualcaster added but 0 wins | Score combo lines by likelihood of execution, not just presence |
| **Approach reliance degredation** | 89.9% → 2.9% of wins | Track primary wincon viability across config changes |
| **Land count vs CMC curve mismatch** | 31 lands + 4 wincons at CMC 9+ | Flag when avg CMC drops but high-end wincons remain unchanged |
| **Pipeline bypass detection** | optimizer_applied_swaps empty despite radical changes | Alert when deck hash changes but no optimizer_applied_swaps record exists |

---

## 8. Concrete Tasks

### Task 1 (P0): WR Collapse Root Cause — Rollback or Rebuild
**Evidence:** WR collapsed from 75.2% (Jun 7) to 29.0% (Jun 9, 600 games). The deck was significantly modified without optimizer pipeline tracking (optimizer_applied_swaps empty). The deck needs either a rollback to the Jun 7 state or a targeted rebuild addressing the removal gap.
- **What to change:** Investigate when/how the deck was modified (check sync_pg_target_deck_to_hermes logs, PostgreSQL audit logs). Either restore the pre-reconstruction configuration or run a targeted slot optimizer cycle focused on adding 4-5 removal slots.
- **Impact:** Restores the deck to functioning state. Current WR is critically below the 40% threshold.
- **Risk:** Rollback could lose legitimate improvements (the fast mana + tutor density is a valid upgrade). Targeted rebuild is safer.
- **Validation:** After correction, 600-game WR should recover to ≥50%.

### Task 2 (P1): Optimizer Pipeline Integrity — Hash Change Alert
**Evidence:** optimizer_applied_swaps table is empty (0 rows) despite deck hash changing from `763c3e0f...` to `a17a5863...` and the deck undergoing structural transformation (9 removal → 4 removal, 2 tutors → 5 tutors, 35 lands → 31 lands). The pipeline has no visibility into who or what changed the deck.
- **What to change:** Add a cron/Hermes agent that computes the deck hash before and after every sync_battle_card_rules cycle. If the hash changes without a corresponding optimizer_applied_swaps row, emit a CRITICAL alert.
- **Impact:** Prevents future silent deck mutations.
- **Risk:** Low — read-only alerting.
- **Validation:** After implementation, manually changing a deck card should produce a hash-change alert.

### Task 3 (P1): Removal Floor — Anti-Pattern Guard in Battle Sim
**Evidence:** All 4 builds in June 9 with removal < 5 produced WR < 30%. Previous builds with 9 removal produced WR 67-89%. The 4-removal configuration is structurally incapable of answering 3 opponents' threats.
- **What to change:** Add a `minimum_removal` validation in the slot optimizer and battle deck validator. For non-cEDH Bracket 4, require removal ≥ 8. For cEDH Bracket 4, require removal ≥ 4 AND a deterministic 2-card combo.
- **Impact:** Prevents optimizer from recommending configurations with fatal removal gaps.
- **Risk:** Low — validation layer, no functional change.
- **Validation:** Submitting a deck with 4 removal should reject with "Removal count 4 below minimum 8 for non-cEDH bracket 4."

### Task 4 (P2): Wincon Match Quality — Track Win Method Distribution
**Evidence:** Before: Approach = 89.9% of wins. After: elimination = 97.1%. This 87-point swing is the most sensitive indicator of deck health — more sensitive than raw WR.
- **What to change:** Add win-reason distribution tracking to baseline runs. Compare against the archetype's expected win method profile. Alert when win method distribution shifts > 30pp from historical baseline without a documented archetype change.
- **Impact:** Earlier detection of identity drift. The Approach→elimination swing was visible at 25 games but WR collapse needed 600.
- **Risk:** Low — monitoring only.
- **Validation:** After implementation, the Jun 9 build should trigger an "Approach reliance collapse" alert.

### Task 5 (P2): Land-CMC Mismatch Detector
**Evidence:** 31 lands + 4 wincons at CMC ≥ 9 (Worldfire, Storm Herd, Rise of the Eldrazi, Fiery Emancipation at CMC 6+). Previous successful builds had 35 lands + 2-3 wincons at CMC ≥ 9. The probability of casting a 9+ CMC spell with 31 lands is ~18% by turn 10.
- **What to change:** Add a metric: for lands < 33, compute `high_cmc_risk = count of wincons with cmc > lands - 22`. If high_cmc_risk > 2, emit warning. Scale warning to "CRITICAL" if high_cmc_risk > 4.
- **Impact:** Prevents land-count reductions from leaving high-CMC cards stranded.
- **Risk:** Low — analytical metric.
- **Validation:** The current build (31 lands, 4 wincons CMC ≥ 9) should produce "CRITICAL: 22% of wincons are likely uncastable."

---

## 9. Pipeline State

| Component | Status | Note |
|:----------|:-------|:-----|
| knowledge.db deck_id=6 | ✅ 100 cards | Matches product deck |
| optimizer_applied_swaps | ⚠️ 0 rows | Changes bypassed optimizer |
| optimizer_baseline_runs | ✅ 3 runs today | WR 8.3-29.0% |
| optimizer_candidates | ✅ Quality gate active | 15 candidates reviewed |
| PostgreSQL sync | ✅ active | sync reports present for Jun 9 |
| BATTLE_LOG | ✅ Updated | Jun 9 entries present |

## 10. Hash Tracking

| Hash | State | WR | Date |
|:-----|:------|:--:|:-----|
| `a17a5863c95fe95eaf3c379708c767f04c9854d131994cc6a92dc512a3ce02c9` | **Current (new fast combo build)** | 8.3–29.0% | 2026-06-09 |
| `12c55613ae4f7bcd4c934fae4253cfa75fcc4946352a18a61365835427e90c08` | Previous (stax-combo, Wheel applied) | 89.3% | 2026-06-07 |
| `763c3e0f...` | Pre-E2E Apply | 84.5% | 2026-06-07 |
| `30d00347764fc2a215edb4e668994871` | Post-hash-fake (Twinflame/Flare missing) | ~52% | 2026-06-01 |
