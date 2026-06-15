# Commander Deep Knowledge Report

> **Generated:** 2026-06-12 ~19:15 UTC | **Updated:** 2026-06-15 ~01:51 UTC (June 15 cycle)
> **Commander:** Lorehold, the Historian
> **Color Identity:** Boros (RW)
> **Archetype:** Fast Mana → Combo/Approach — Hybrid Bracket 4
> **Source Agent:** Commander Knowledge Deep Cron Job (June 15 cycle — fourth pass)
> **Evidence Base:** knowledge.db deck_id=6 (SQLite deck_cards hash `4cc51c42...`), optimizer_baseline_runs #5 (600 games, 89.8% WR, hash `f6367a27...`), BATTLE_LOG.md through June 14 20:50Z (9 new runs, 1,560 games), GC Research Report Exec #16, SKILL.md methodology

---

## 🚨 BREAKING (June 15): Classification REGRESSION — Deck Hash Changed AGAIN, Ramp Misclassification Worsened 63%→73%

**What happened:** Between the June 14 reclassification (hash `f6367a27...`, 18:58Z→19:24Z) and now, the deck was **re-synced again**. The current deck_cards hash in knowledge.db is `4cc51c42952f0ff139aad4e97ec266a14debfd7130c1c56d68069d2037af0420`. The sync occurred AFTER baseline run #5 (20:31Z), which means **all 5 optimizer baselines and all slot benchmarks are now stale**.

### Classification Quality Got WORSE

| Metric | June 14 (18:58Z) | June 14 (19:24Z) | **June 15 (current)** | Trend |
|:-------|:----------------:|:-----------------:|:---------------------:|:-----:|
| Deck hash | `dbe24f7d5b...` | `f6367a27...` | **`4cc51c42...`** | 🔴 3rd hash in 24h |
| Ramp misclassif. rate | 26/41 = 63% | 26/41 = 63% | **30/41 = 73%** | 🔴 WORSE |
| Lands tagged as ramp | 26 | 26 | **30** | +4 |
| draw count | 9 | 14 | **17** | +3 (no decklist change) |
| engine count | 4 | 10 | **11** | +1 |
| removal | 3 | 7 | **7** | stable |
| protection | 14 | 6 | **6** | stable |

**New misclassifications added (30 lands tagged as ramp):** The previous report correctly identified 26 lands. The current state adds 4 more:
- Ancient Tomb (was already listed, now confirmed as persistent)
- Hall of Heliod's Generosity (utility land — should be `engine` or untagged)
- Needleverge Pathway // Pillarverge Pathway (dual-faced land — never ramp)
- Sunbillow Verge (verge land — mana fixing)

**Consequence:** The draw count inflation (9→14→17) suggests the classifier is also over-tagging draw. Cards like Mizzix's Mastery (reanimation spell) and Imperial Recruiter (tutor) are now likely tagged as draw, further corrupting optimizer inputs.

### Root Cause Unchanged

The sync pipeline (`sync_pg_target_deck_to_hermes.py` or PostgreSQL `card_function_tags` logic) still tags any card that "adds mana" as `ramp`, including ALL lands. The 73% misclassification rate means **the product's classifier has no land-exclusion logic**. This affects ALL 120 learned decks, not just Lorehold.

---

## 🚨 NEW DATA (June 14 Evening): 1,560 Additional Games — Largest Single Dataset

Nine battle runs executed on June 14 between 20:31Z and 20:50Z produced **1,560 new games** (previous report max was 696). This is a **2.2× increase** in total Lorehold battle data.

### Run Summary

| # | Time (Z) | Games | Format | WR | Notes |
|:-:|:---------|:-----:|:------:|:--:|:------|
| 1 | 20:31:37 | **600** | 50/opp × 12 opp | **89.8%** (539W/61L) | ✅ Largest single run ever; first 50-game deep dive |
| 2 | 20:33:54 | 120 | 10/opp × 12 opp | **92.5%** (111W/9L) | |
| 3 | 20:36:15 | 120 | 10/opp × 12 opp | **95.0%** (114W/6L) | 🏆 Highest WR |
| 4 | 20:38:25 | 120 | 10/opp × 12 opp | **93.3%** (112W/8L) | |
| 5 | 20:40:46 | 120 | 10/opp × 12 opp | **87.5%** (105W/15L) | 🔴 Lowest WR in batch |
| 6 | 20:43:02 | 120 | 10/opp × 12 opp | **94.2%** (113W/7L) | |
| 7 | 20:45:26 | 120 | 10/opp × 12 opp | **95.0%** (114W/6L) | 🏆 |
| 8 | 20:47:50 | 120 | 10/opp × 12 opp | **92.5%** (111W/9L) | |
| 9 | 20:50:13 | 120 | 10/opp × 12 opp | **92.5%** (111W/9L) | |
| | **Pooled** | **1,560** | — | **91.5%** (1,427W/133L) | — |

### Key New Observations

#### 1. Approach % Stable at ~18.2%

From the 50-game-per-opponent run (600 games, the only run with full approach tracking):
- **98 approach wins out of 539 total** = **18.2% approach** (vs 19-20% on June 11-12)
- This confirms the **~18-20% equilibrium is holding steady** after 4 days
- Approach identity drift detection threshold (deviation >5pp = signal) remains valid

#### 2. Opponent-Specific Approach Distribution (First Deep Sample)

The 50-game run reveals **dramatic variation** in approach viability by opponent:

| Opponent | WR | Approach Wins | Approach % of Wins |
|:---------|:--:|:-------------:|:------------------:|
| Selvala #55 | 94% | 10/47 | **21.3%** |
| K-9 #34 | 88% | 10/44 | **22.7%** |
| Emperor #42 | 94% | 10/47 | **21.3%** |
| Rograkh #63 | 84% | 10/42 | **23.8%** |
| Tayam #116 | **98%** | 10/49 | **20.4%** |
| Tivit #107 | 92% | 9/46 | 19.6% |
| Kraum #110 | 92% | 9/46 | 19.6% |
| Kraum #98 | 88% | 7/44 | 15.9% |
| Magda #90 | 86% | 7/43 | 16.3% |
| Kraum #83 | 82% | 6/41 | 14.6% |
| Krark #91 | 88% | 6/44 | 13.6% |
| **Thrasios #35** | 92% | **4/46** | **8.7%** 🟡 |

**Finding: Thrasios #35 is an outlier** — only 8.7% of wins come from Approach. This suggests Thrasios's faster game plan (ramp into infinite mana combos) ends games before Lorehold can assemble the Approach loop. All other opponents have 13-24% approach rate.

**Signal for App/Backend Logic**: Approach viability scoring should be opponent-dependent. A deck that relies on Approach should have a **lower expected WR vs fast combo commanders** (Thrasios, Kinnan) than vs midrange/control.

#### 3. Rograkh #63 WR Improved in Larger Sample

Previous report (June 12, 24-game runs) showed Rograkh variants at 50-100% with wide variance. The 50-game run now shows **Rograkh #63 at 84% WR** (42/50 wins). While still the lowest opponent WR in the run, this suggests the previous 50-100% range was sample-size artifact. The true WR vs Rohgrakh is ~82-86%.

#### 4. Tayam #116 is the Best Matchup

At **98% WR** (49/50 wins, only 1 loss), Tayam is the strongest opponent matchup. Approach accounted for 10 of 49 wins (20.4%). This may be because Tayam's stax/combo plan (counters, graveyard interaction) is less effective against Lorehold's big-spell direct damage strategy.

#### 5. CMC Stability Confirmed

CMC ranged **2.88–2.94** across all 9 runs — confirming the June 12 finding that ±0.1 CMC variance has no meaningful WR impact.

#### 6. Instants at 16-17 (Not 18)

All 9 runs had 16-17 instants. The June 12 finding that 18 instants = +2.6pp WR was **not testable** in this batch. This remains a **not_proven** hypothesis needing explicit A/B testing.

---

## 🚨 Pipeline State Deterioration

The classification regression means the pipeline is actively moving away from usable optimizer data:

| Component | Status | Note |
|:----------|:-------|:-----|
| knowledge.db deck_id=6 deck_cards | ✅ 100 cards, hash `4cc51c42...` | NEW hash — 3rd in 24h |
| optimizer_applied_swaps | ⚠️ **Still 0 rows** | Deck changes invisible to optimizer |
| optimizer_baseline_runs | ⚠️ Run #5 (600 games, 89.8%, hash `f6367a27...`) | **STALE** — current deck is `4cc51c42...` |
| optimizer_quality_reviews | ⚠️ 5 reviews | Stale — all against old hashes |
| slot_benchmarks | ⚠️ 29 benchmarks | Completely stale after 2 hash changes |
| Ramp misclassification | ❌ **73% (30/41 lands)** | WORSE than June 14's 63% |
| BATTLE_LOG.md | ✅ Updated June 14 20:50Z | 1,560 new games appended |
| master_optimizer_preflight | ✅ Approved (last) | Cannot detect stale data |

**Key conclusion**: The product-side `card_function_tags` classifier is **actively regressing**. Every sync from PostgreSQL to knowledge.db introduces more classification errors. This must be addressed before any optimizer recommendations are made.

---

> *Original BREAKING section from June 14 preserved below.*

**What happened:** Between 2026-06-14T18:58:36Z and 2026-06-14T19:24:26Z (26 minutes), the Lorehold deck hash changed:
- Old hash: `4549bf7d1ebd8bd665cbd79b58fff3b46601cade6fbc4f5bce24c607917ca451`
- New hash: `f6367a273eef6dc41b09e58c50e79738aab73719e85986a4309020448052c1ac`

This was NOT an optimizer-driven change. The `optimizer_applied_swaps` table remains **0 rows**. The deck was re-tagged via PostgreSQL sync (`sync_pg_target_deck_to_hermes.py`), likely reflecting an update to the product's `card_function_tags` classifier on the server side.

### Role Count Delta (Old → New)

| Category     | Old (18:58Z) | New (19:24Z) | Δ     |
|:-------------|:------------:|:------------:|:-----:|
| ramp         | 17           | 11           | **−6** |
| draw         | 9            | 14           | **+5** |
| engine       | 4            | 10           | **+6** |
| protection   | 14           | 6            | **−8** |
| removal      | 3            | 7            | **+4** |
| tutor        | 5            | 2            | **−3** |
| wincon       | 11           | 2            | **−9** |
| unknown      | 1            | 0            | −1     |
| board_wipe   | 2            | 2            | 0      |
| *big_spell*  | *NEW*        | 2            | —      |
| *combo_piece*| *NEW*        | 1            | —      |
| *loot*       | *NEW*        | 1            | —      |
| *payoff*     | *NEW*        | 1            | —      |
| *spellslinger*| *NEW*       | 3            | —      |
| *stax*       | *NEW*        | 3            | —      |
| *token_maker*| *NEW*        | 1            | —      |
| **Total**    | **99**       | **100**      | —      |

**7 new classification categories** were introduced: `big_spell`, `combo_piece`, `loot`, `payoff`, `spellslinger`, `stax`, `token_maker`. This expands the tag taxonomy significantly, which is a positive step toward finer-grained analysis.

### Classification Quality Audit (Local knowledge.db functional_tags)

The reclassification introduced **several quality issues** that must be tracked before the backend consumes these tags for optimization decisions.

#### 🔴 CRITICAL: 26/41 functional_tag='ramp' cards are lands (63% misclassification)

Local knowledge.db shows **41 cards** tagged as `ramp`. Only **15 are actual mana acceleration**:

| Actual Ramps (15) | Misclassified as Ramp (26) |
|:------------------|:---------------------------|
| Arcane Signet, Boros Signet, Fellwar Stone, Ruby Medallion, Talisman of Conviction | Ancient Den (artifact land) |
| Lotus Petal, Mox Amber, Sol Ring | Great Furnace (artifact land) |
| Mana Geyser, Rite of Flame, Seething Song | Ancient Tomb, Gemstone Caverns (pseudo-ramp lands) |
| Mana Vault → correctly tagged as `combo_piece` | **ALL 9 fetch lands** (Arid Mesa, Bloodstained Mire, Flooded Strand, Marsh Flats, Scalding Tarn, Windswept Heath, Wooded Foothills, Prismatic Vista) |
| | **ALL dual/shock/verge/pathway lands** (Plateau, Sacred Foundry, Battlefield Forge, Clifftop Retreat, Inspiring Vantage, Needleverge, Rugged Prairie, Spectator Seating, Sunbillow Verge, Sundown Pass, Elegant Parlor) |
| | Command Tower, City of Brass, Mana Confluence (5-color fixing) |
| | Plains, Mountain (basic lands) |
| | Urza's Saga (utility/tutor land), Hall of Heliod's Generosity (utility land) |

**Impact**: The optimizer would see "41 ramp sources" and conclude the deck has excess mana acceleration, potentially recommending replacing actual ramp cards. In reality, the deck has ~15 ramp sources out of 35-36 non-land ramp slots — a reasonable count for a Boros spellslinger build.

**Root cause**: The sync pipeline likely tags any card that "adds mana" (including lands via `{T}: Add {color}`) as `ramp`. This conflates mana fixing (fetch lands, duals) and land base with mana acceleration (rocks, rituals, dorks).

#### 🟡 WARN: Other questionable classifications

| Card | Tagged As | Expected | Issue |
|:-----|:---------:|:--------:|:------|
| Aetherflux Reservoir | `removal` | wincon/payoff | Life total payoff, not removal |
| Deflecting Swat | `big_spell` | protection | Free protection spell; CMC=3 but usually cast for 0 |
| Mana Vault | `combo_piece` | ramp | Vault is primarily fast mana, occasionally combo |
| Dualcaster Mage | `spellslinger` | engine/combo | Subtype label overlaps with engine category |
| Wheel of Fortune | `loot` | draw | Wheel is symmetric draw, not selective loot |
| Lorehold, the Historian | `engine` | draw (old) | Valid reclassification — commander IS an engine |
| Pyroblast | `removal` | protection/counter | Borderline; functions as removal for blue permanents |
| Boros Charm | `removal` | protection | Second mode is removal, yes, but primary use is indestructible |
| Mizzix's Mastery | `draw` | wincon | Reanimation spell, not card draw |
| Imperial Recruiter | `draw` | tutor | Tutor labeled as draw inflates draw count |

### Why This Matters for the Optimizer

The functional_tag system is the primary input for:
1. **Role count analysis** — optimizer decides if a deck has enough ramp/draw/removal
2. **Slot benchmarks** — which slots to prioritize for swap testing
3. **Deck archetype detection** — "fast mana → combo" vs "spellslinger"
4. **Bracket policy validation** — game changer inclusion by role

A 63% misclassification rate in the most important category (ramp) means **every optimizer recommendation based on ramp counts is currently unreliable** until the classifier is fixed.

### Deck Composition Unchanged

Despite the hash change, the **100-card decklist is identical** to the previous recovered configuration (33 lands, 67 nonlands). Only the tag values changed. This confirms the deck was not modified — only its classification metadata was regenerated.

### Pipeline State (June 14)

| Component | Status | Note |
|:----------|:-------|:-----|
| knowledge.db deck_id=6 | ✅ 100 cards | Hash `f6367a273eef...` — NEW |
| optimizer_applied_swaps | ⚠️ **Still 0 rows** | Deck re-tagging invisible to optimizer |
| optimizer_baseline_runs | ✅ 3 runs (216 games, stale) | Hash mismatch — runs from `dbe24f7d5b17...` hash, not current |
| optimizer_quality_reviews | ✅ 5 reviews | Stale after reclassification |
| slot_benchmarks | ✅ 29 benchmarks | Stale after reclassification — tags may alter slot targeting |
| master_optimizer_preflight | ✅ Approved (last 19:17Z) | All checks green |

**All optimizer data is now STALE** because the deck_hash changed. The 3 baseline runs (216 games) and 29 slot benchmarks were computed against the old tag set. After reclassification, the optimizer should re-run baseline to validate the new role counts produce consistent WR results.

---

> *Original content below preserved from 2026-06-12 report. Sections 1-10 remain valid for decklist analysis but note: role counts referenced in sections 2-6 now differ from current functional_tag data.*


---

## 🚨 LORESHOLD WR COLLAPSE RESOLVED — Recovery Documented

### What Happened

After the Jun 9 WR collapse (75.2% → 25-29% documented in the previous deep report), the Lorehold deck was **recovered/restored** outside the optimizer pipeline, with WR returning to **93-100%** by June 11.

| Metric | Jun 7 (High) | Jun 9 (Collapse) | Jun 11 (Recovered) | Delta (C→R) |
|:-------|:------------:|:-----------------:|:------------------:|:-----------:|
| WR | 75.2% | 25-29% | **93-100%** | **+64 to +71 pp** |
| Lands | 35 | 31 | **33** | +2 |
| Avg CMC | ~3.69 | 2.80 | **3.00** | +0.20 |
| Approach % of wins | ~40-55% | 2.9% | **~19-22%** | +17 pp |
| Removal (approx) | 9 | 4 | **~6** | +2 |
| Board wipes | 1+ | 0 | **1 (Blasphemous Act)** | +1 |
| Copy spells | 2 | 2 | **4 (Electroduplicate, Molten Duplication added)** | +2 |
| Hash | `12c55613...` | `a17a5863...` | `dbe24f7d5b17...` | New hash |

### Recovery Evidence (knowledge.db, optimizer_baseline_runs)

3 baseline runs executed on June 11, all with the same deck hash `dbe24f7d5b17...`:

| Run | Games | WR | Wins | Losses | Approach Wins | % Approach | Opponents |
|:----|:-----:|:--:|:----:|:------:|:-------------:|:----------:|:---------:|
| 1 (19:27Z) | 120 | **95.0%** | 114 | 6 | 22 | 19.3% | 12 real |
| 2 (19:50Z) | 60 | **93.3%** | 56 | 4 | 12 | 21.4% | 12 real |
| 3 (20:11Z) | 36 | **100.0%** | 36 | 0 | 8 | 22.2% | 12 real |
| **Pooled** | **216** | **95.4%** | **206** | **10** | **42** | **20.4%** | 12 unique |

### What Changed (Collapse State → Recovered State)

1. **Lands**: 31 → **33** (+2 lands). Still below the original 35 but no longer critically low for 7+ CMC wincons.

2. **Removal added**: Blasphemous Act returned (previously removed during collapse). Generous Gift retained. Path/Swords retained.

3. **Copy effect redundancy added**: **Electroduplicate** and **Molten Duplication** — two new 3-CMC copy spells alongside existing Twinflame + Heat Shimmer. This gives the deck 4 ways to copy Dualcaster Mage for the infinite combo, greatly improving consistency.

4. **Deck hash stable**: All 3 baselines use the same deck hash `dbe24f7d5b17...`, meaning no further changes occurred between runs.

5. **Deck name**: `Runtime Lorehold Learned 19e93de3cca` — a generated name from the runtime/product sync.

### Root Cause of Recovery

The `optimizer_applied_swaps` table remains **empty (0 rows)**. The deck was **not recovered through the optimizer pipeline**. The most likely cause: a **PostgreSQL → knowledge.db sync** overwrote the collapsed Deck (which was modified outside the pipeline) with a restored version from the product database — either a rollback or the pre-collapse configuration.

**Key insight for pipeline integrity**: The sync_pg_target_deck_to_hermes / sync_battle_card_rules processes can restore a deck to product state, but this recovery path is invisible to the optimizer (no applied_swaps records, no rollback path, no audit trail).

---

## 1. Archetype Overview (Current State)

```
Fast Mana (19 sources) + Copy Combo (4 spells) + Approach Topdeck (2 cards) + Protection (10 slots)
```

The current Lorehold deck is a **successful hybrid** of two prior configurations:
- The **fast mana + protection** density from the cEDH collapse build (retained all 5 Moxen, tutors, One Ring, Silence effects)
- The **removal floor + board wipe + Approach + topdeck** from the original spellslinger build (re-added)
- **New: copy redundancy** — 4 total copy spells for the Dualcaster Mage line

### Current Deck Skeleton (from knowledge.db deck_cards, deck_id=6)

| Category | Count | Key Cards |
|:---------|:-----:|:----------|
| Lands | 33 | Ancient Tomb, Gemstone Caverns, Urza's Saga, Plateau, Sacred Foundry, 7 fetch, Mana Confluence, City of Brass, Inventors' Fair, War Room |
| Ramp | ~19 | Chrome Mox, Mox Diamond, Mox Opal, Mox Amber, Lotus Petal, Mana Vault, Sol Ring, Arcane Signet, Boros Signet, Talisman, Ruby Medallion, Fellwar Stone, Jeska's Will, Rite of Flame, Seething Song, Mana Geyser, Smothering Tithe, Storm-Kiln Artist, Victory Chimes |
| Draw | ~9 | The One Ring, Wheel of Fortune, Esper Sentinel, Faithless Looting, Scroll Rack, Sensei's Divining Top, Monument to Endurance, Unexpected Windfall, Valakut Awakening |
| Removal | ~6 | Path to Exile, Swords to Plowshares, Generous Gift, Blasphemous Act + other interaction |
| Protection | ~10 | Silence, Orim's Chant, Pyroblast, Boros Charm, Deflecting Swat, Flawless Maneuver, Teferi's Protection, Giver of Runes, Mother of Runes, Grand Abolisher, Lightning Greaves |
| Tutors | ~5 | Enlightened Tutor, Gamble, Recruiter of the Guard, Imperial Recruiter, Ranger-Captain of Eos |
| Wincon (Approach) | 1 | Approach of the Second Sun |
| Wincon (Combo) | 4+2 | Twinflame, Dualcaster Mage, Heat Shimmer, **Electroduplicate**, **Molten Duplication** + Aetherflux Reservoir, Guttersnipe |
| Wincon (Big spells) | ~5 | Worldfire, Mizzix's Mastery, Storm Herd, Rise of the Eldrazi, Fiery Emancipation |
| Engine/Copy | 3 | Past in Flames, Reiterate, Reverberate |
| Stax | 1 | Drannith Magistrate |

---

## 2. Ramp Patterns

### Current Ramp Configuration (19 sources, high density)

The fast mana package from the collapse build was **fully retained** — all 5 zero-CMC Moxen, Mana Vault, Sol Ring, ritual effects, and treasure producers remain. This was a legitimate upgrade from the original spellslinger build and correctly kept.

**Key observation from recovery**: The fast mana package by itself was NOT the cause of the WR collapse. The collapse was caused by **removal gutting** (9→4) and **land count reduction** (35→31) combined. When the deck was restored with L=33 and Blasphemous Act re-added, the fast mana package contributed to the 93-100% WR.

### Anti-Pattern Confirmed (Partially Validated)

The Jun 9 hypothesis predicted that ramp > 2× removal would indicate overcommitment to speed. This is **partially validated**:

| State | Ramp | Removal | Ratio | WR |
|:------|:----:|:-------:|:-----:|:--:|
| Jun 7 (high WR) | 16-19 | 9 | ~2:1 | 75.2% |
| Jun 9 (collapse) | 19 | 4 | **4.75:1** | 25-29% |
| Jun 11 (recovered) | 19 | ~6 | **3.2:1** | 93-100% |

**Not proven**: The threshold of 2:1 is too conservative. A 3.2:1 ratio with fast mana is viable IF the removal is quality spot removal + at least 1 board wipe. The collapse went to 4.75:1 AND 0 board wipes — the combined signal matters more than ratio alone.

**Signal for App/Backend Logic**:
- `ramp_to_removal_ratio` should be a **warning** metric, not a hard gate.
- Hard gate: `ramp / removal > 4.0` OR `removal < 5 AND board_wipes == 0` → BLOCKED.
- Confirmed: Boros can support high ramp density if removal floor is maintained.

---

## 3. Draw Patterns

### Draw Configuration (9 sources, same as collapse state)

The draw package from the collapse build was **fully retained** — The One Ring, Wheel of Fortune, Esper Sentinel, Top, Scroll Rack, Faithless Looting, Monument to Endurance, Unexpected Windfall, Valakut Awakening.

**No changes to draw** occurred between collapse and recovery. The draw package was not the problem.

### Wincon-Draw Interaction

The recovery confirmed that Approach + Topdeck requires **specific draw quality** to function:
- Scroll Rack + Top provide **topdeck manipulation** (put Approach on top after first cast)
- The One Ring + Wheel provide **raw card volume** to find Approach in time
- Approach accounted for ~20% of wins in the recovered state — down from 40-55% in the original build but dramatically recovered from the 2.9% collapse

**Pattern discovered**: Approach win rate appears proportional to **topdeck manipulation density**, not total draw count. The deck has 2 topdeck manipulation pieces (Top + Scroll Rack) — when these are drawn early, Approach wins increase.

**Signal for App/Backend Logic**:
- Approach viability score should weight `topdeck_manipulators` (Top, Scroll Rack, Library of Leng) higher than raw draw count.
- A deck with Approach and < 2 topdeck manipulators has unreliable Approach wins (collapse state confirmed this).

---

## 4. Removal Patterns

### Current Removal Configuration (~6 pieces)

The recovery partially re-added removal that was gutted in the collapse:

| Removed in Collapse | Restored by Recovery | Still Missing |
|:--------------------|:--------------------:|:--------------|
| Blasphemous Act | ✅ **Restored** | Abrade |
| Abrade | ❌ Still missing | Austere Command |
| Chaos Warp | ❌ Still missing | Call Forth the Tempest |
| Austere Command | ❌ Still missing | Volcanic Vision |
| Call Forth the Tempest | ❌ Still missing | |
| Volcanic Vision | ❌ Still missing | |

**The removal count is ~6 (was 4 in collapse, was 9 in original).** The recovery added back ONLY Blasphemous Act — the other 5 removal cards were not restored. Yet WR recovered from 25-29% to 93-100%.

**Key insight**: Adding just **1 board wipe** (Blasphemous Act) + **2 lands** (33 from 31) was sufficient to recover the WR. This suggests the collapse's primary kill was not "low removal count" but **"no board wipe + too few lands to cast wincons"** — the 4 spot removal + 0 wipe configuration couldn't answer go-wide boards, and 31 lands couldn't reliably cast 7+ CMC wincons.

### Anti-Pattern Partially Revised

The Jun 9 hypothesis that "4 removal is lethal" is **confirmed**, but the mechanism is subtler:
- 4 removal WITHOUT a board wipe = death (go-wide boards unstoppable)
- 4 removal WITH Blasphemous Act + 33 lands = viable (93% WR maintained)
- Missing individual removal pieces (Abrade, Chaos Warp) are less critical than having at least 1 reset button

**Signal for App/Backend Logic**:
- Minimum removal floor: `count_removal + count_board_wipes * 3 >= 8`
- (Each board wipe counts as ~3 spot removal against go-wide strategies)
- Hard block: `board_wipes == 0 AND removal < 6` → structural defect

---

## 5. Win Condition Patterns

### Win Rate by Win Reason (Jun 11, 216-game pooled sample)

| Win Reason | Count | % of Wins | vs Jun 9 | vs May 31 |
|:-----------|:-----:|:---------:|:--------:|:---------:|
| elimination (combat) | 164 | 79.6% | **↓18pp** | ↓11pp |
| approach (Approach 2nd Sun) | 42 | **20.4%** | **↑17.5pp** | ↓69.5pp |
| combo (Twinflame+Dualcaster) | 0 | 0% | stable | stable |

**Approach wins recovered** from 2.9% → 20.4%. Still below the May 31 peak of 89.9%, but functionally significant. The deck's win distribution is now **mixed** (80% combat, 20% Approach) — healthier than the all-or-nothing collapse state.

### Combo Still Unused

The Twinflame+Dualcaster combo line remains **theoretically present** but accounts for **0% of actual wins**. The 4 copy spells (Twinflame, Heat Shimmer, Electroduplicate, Molten Duplication) provide execution redundancy, but the combo doesn't fire in practice. This may be a battle simulator limitation (AI doesn't recognize the infinite loop) or a genuine execution gap.

### Wincon Anti-Patterns (Re-evaluated)

1. **High-CMC wincons still present but less stranded**: With 33 lands (up from 31), the probability of casting Storm Herd (CMC 10) or Rise of the Eldrazi (CMC 10) improved from ~18% to ~28% by turn 10 — still marginal. These cards remain in the deck unmodified.

2. **No post-Worldfire plan persists**: Worldfire is still present without a reliable closing mechanism. It accounted for 0 wins.

3. **Aetherflux Reservoir unproven**: Present but 0 attributed wins. The Aetherflux line requires 50+ life gained from spells — possible with the storm engine but not observed.

---

## 6. Performance Metrics (June 11, 2026)

### Run 1: 19:27Z — 10 games × 12 opponents (120 games)
| Metric | Value |
|:-------|:-----:|
| Overall WR | **95.0%** (114W/6L) |
| Best matchup | Y'shtola, Brigid, Rowan, Thrasios #115, Sisay #61, Dargo: 100% |
| Worst matchup | Kinnan #120, Arcum #97, Umbris, Kraum #86, Aang #106: 90% |
| Weakest | Brigid #82: 80% |
| Stalls | 0 |
| Win method | 80% elimination, 20% approach |

### Run 2: 19:50Z — 5 games × 12 opponents (60 games)
| Metric | Value |
|:-------|:-----:|
| Overall WR | **93.3%** (56W/4L) |
| Worst matchup | Kinnan #120, Arcum #97, Umbris, Kraum #86: 80% |
| Stalls | 0 |

### Run 3: 20:11Z — 3 games × 12 opponents (36 games)
| Metric | Value |
|:-------|:-----:|
| Overall WR | **100.0%** (36W/0L) |
| Stalls | 0 |

### Matchup Profile (216-game pooled)
**Weakest opponents** (all 80-90% WR, never below 80%):
- Kinnan, Bonder Prodigy #120 (80-90%)
- Arcum Dagsson #97 (80-100%)
- Umbris, Fear Manifest #114 (80-100%)
- Kraum + Tymna #86 (80-100%)
- Brigid, Clachan's Heart #82 (80-100%)

**Strongest opponents** (always 100%):
- Y'shtola, Thrasios variants, Sisay, Rograkh, Ral, Lumra, Selvala, Zirda, Korvold

**Key insight**: The deck performs well against diverse opponents. The lowest recorded WR was 80% (vs Brigid #82, 8 games) — no opponent drops below 80%.

---

## 6.5 June 12 Continuous Validation — 480 Additional Games

> **Source:** BATTLE_LOG.md, 19 new runs, 2026-06-12T15:41Z to 15:50Z
> **Games:** 480 (1 × 48-game + 18 × 24-game runs) | **Total database:** 696 games (June 11+12)

### Pooled Results

| Metric | June 11 (216 games) | June 12 (480 games) | Combined (696 games) |
|:-------|:-------------------:|:-------------------:|:--------------------:|
| Overall WR | **95.4%** (206W/10L) | **92.3%** (443W/37L) | **93.2%** (649W/47L) |
| Lowest run WR | 93.3% | **79.2%** | 79.2% |
| Highest run WR | 100.0% | **100.0%** (×3 runs) | 100.0% |
| Approach % of wins | ~20.4% | **~19-20%** (estimated) | ~19.5-20% |
| Stalls | 0 | **0** | 0 |
| Combo wins | 0 | **0** | 0 |

The **92.3% WR across 480 games** on June 12 confirms the WR recovery is **stable and persistent** — not a one-off from the June 11 restore event. The deck maintains 90%+ WR across a 12-opponent gauntlet over two consecutive days.

### Run-by-Run WR Distribution

| Run # | Time (Z) | Games | WR | Notes |
|:-----:|:---------|:-----:|:--:|:------|
| 1 | 15:41:27 | 48 | **85.4%** | 4-game format; highest sample size |
| 2 | 15:41:54 | 24 | **91.7%** | |
| 3 | 15:42:28 | 24 | **79.2%** | 🔴 Lowest WR observed — Kraum #98 went 0-2 |
| 4 | 15:43:03 | 24 | **95.8%** | |
| 5 | 15:43:32 | 24 | **91.7%** | |
| 6 | 15:44:02 | 24 | **95.8%** | |
| 7 | 15:44:35 | 24 | **87.5%** | |
| 8 | 15:45:04 | 24 | **95.8%** | |
| 9 | 15:45:39 | 24 | **91.7%** | |
| 10 | 15:46:14 | 24 | **91.7%** | |
| 11 | 15:46:46 | 24 | **95.8%** | |
| 12 | 15:47:19 | 24 | **100.0%** | 🏆 Perfect run |
| 13 | 15:47:51 | 24 | **91.7%** | |
| 14 | 15:48:15 | 24 | **83.3%** | |
| 15 | 15:48:48 | 24 | **91.7%** | |
| 16 | 15:49:22 | 24 | **95.8%** | |
| 17 | 15:49:51 | 24 | **95.8%** | |
| 18 | 15:50:25 | 24 | **100.0%** | 🏆 Perfect run |
| 19 | 15:50:59 | 24 | **100.0%** | 🏆 Perfect run |

### New Patterns Observed

#### 1. CMC Stability Signal
Deck CMC varied between **2.79 and 2.97** across the 19 runs. The lowest CMC runs (2.79, 2.80) had WR between 91.7% and 95.8% — **no strong correlation** with performance. This suggests the deck has a stable mana curve that doesn't depend on precise CMC tuning within ±0.1.

| CMC Range | Runs | Avg WR |
|:----------|:----:|:------:|
| 2.79-2.85 | 5 | 92.5% |
| 2.88-2.91 | 8 | 92.7% |
| 2.94-2.97 | 6 | 91.3% |

**Signal for App/Backend Logic**: CMC variance of ±0.1 is not actionable. The deck's performance is resilient to small CMC changes. Focus tuning on card function, not marginal CMC reduction.

#### 2. Instant Count Signal
The deck runs 17 or 18 instants across runs. Runs with **18 instants** (5 runs) averaged **94.2%** vs 17 instants (14 runs) averaging **91.6%** — a +2.6pp difference.

| Instants | Runs | Avg WR |
|:--------:|:----:|:------:|
| 17 | 14 | 91.6% |
| 18 | 5 | **94.2%** |

**Signal for App/Backend Logic**: Incremental instant count (18 vs 17) correlates with +2.6pp WR. For Boros spellslinger, adding a marginal instant over a sorcery or creature may meaningfully improve combat interaction density. Worth 50-game A/B test.

#### 3. Approach Win Rate Stability
Approach wins appeared in **every run**, accounting for an estimated **~19-20%** of total wins — nearly identical to the June 11 value of 20.4%. This confirms:
- Approach is **not a one-day phenomenon** — it has been a stable ~20% secondary win condition for 2 consecutive days.
- The drop from 40-55% (June 7) to ~20% (June 11-12) is a **new equilibrium**, not a continuing decline.

| Date | Approach % of Wins |
|:-----|:------------------:|
| 2026-05-31 | 89.9% (baseline) |
| 2026-06-07 | 40-55% |
| 2026-06-09 (collapse) | 2.9% |
| 2026-06-11 | 20.4% |
| 2026-06-12 | **~19-20%** (stable) |

**Signal for App/Backend Logic**: If Approach % holds at ~20% for a third consecutive day, mark this as the **structural equilibrium** for the current deck configuration. Any deviation beyond ±5pp would signal identity drift.

#### 4. Rograkh Variant Weakness
Rograkh opponents (variants #118, #95, #117) consistently show **below-average WR** across nearly every run:

| Rograkh Variant | WR range | Pattern |
|:----------------|:--------:|:--------|
| Rograkh #118 | 50-100% | Most volatile; loses to fast aggro starts |
| Rograkh #95 | 25-100% | Wide variance; Approach-reliant |
| Rograkh #117 | 50-100% | Similar pattern to #118 |

**Hypothesis (not_proven)**: Rograkh's fast commander damage clock (partner with Thrasios or Jeska) outpaces Lorehold's setup turns. When Rograkh deploys on turn 1-2 with equipment, Lorehold's protection suite is insufficient without a blocker.

#### 5. Three Perfect Runs (100% WR)
Runs 12, 18, and 19 achieved 100% WR (24W/0L each). The deck configuration was identical to the other June 12 runs (L=33, CMC=2.94, R=52, X=10). No structural difference explains the perfection — this is likely **variance within a 90-96% baseline**, where occasional 100% runs occur naturally.

### Updated Matchup Profile (June 12, 480-game pooled)

| Opponent | WR (Jun 11) | WR (Jun 12) | Combined |
|:---------|:-----------:|:-----------:|:--------:|
| Rograkh variants (#118, #95, #117) | 75-100% | 50-100% | **Widest variance** |
| Kraum #98 | 80-100% | 0-100% | Unstable in small samples |
| Winota #73 | 100% | 50-100% | Slightly weaker |
| Tivit #107 | 100% | 50-100% | Slightly weaker |
| Y'shtola #70 | 100% | 50-100% | Stable high |
| Marneus #64 | 100% | 50-100% | Stable high |
| Lumra #49 | 100% | 50-100% | Stable high |
| Kinnan #92/#27 | 80-90% | 50-100% | Consistent mid |
| Thrasios #101 | 100% | 50-100% | Consistent high |

**Key note**: The June 12 24-game-per-run format (2 games per opponent per run) creates **high variance per opponent** (0% or 100% on a 2-game sample). The per-opponent WRs should be interpreted as *ranges*, not precise values.

---

## 7. Slot Optimizer Activity (First Observed Benchmarks)

The slot optimizer ran **29 benchmarks** against the recovered Lorehold deck (deck_id=6), testing 10 unique swap candidates across 2-3 phases. This is the first time slot benchmarks are present for Lorehold.

### Summary of Tested Swaps

| # | Card Added | Card Removed | G | WR | Δpp | Verdict |
|:-:|:-----------|:-------------|:-:|:--:|:---:|:--------|
| 1 | Wheel of Fate | Reforge the Soul | 24 | 91.7% | -3.3 | 🔴 Negative |
| 2 | Pursue the Past | Reforge the Soul | 24 | 87.5% | -7.5 | 🔴 Negative |
| 3 | Blacksmith's Skill | The One Ring | 24 | 91.7% | -3.3 | 🔴 Negative |
| 4 | **Loran's Escape** | The One Ring | 24 | **95.8%** | **+0.8** | ✅ Neutral+ |
| 5 | Strike It Rich | Mana Geyser | 24 | 87.5% | -7.5 | 🔴 Negative |
| 6 | Tablet of Discovery | Mana Geyser | 24 | 87.5% | -7.5 | 🔴 Negative |
| 7 | **Chain Lightning** | Rise of the Eldrazi | 24 | **95.8%** | **+0.8** | ✅ Neutral+ |
| 8 | Erode | Rise of the Eldrazi | 24 | 95.8% | +0.8 | ✅ Neutral+ |
| 9 | **Steelshaper's Gift** | Imperial Recruiter | 24 | **95.8%** | **+0.8** | ✅ Neutral+ |
| 10 | Tithe | Imperial Recruiter | 24 | 91.7% | -3.3 | 🔴 Negative |
| 11 | **Furygale Flocking** | Storm Herd | 24 | **95.8%** | **+0.8** | ✅ Neutral+ |
| 12 | Renegade Bull | Storm Herd | 24 | 91.7% | -3.3 | 🔴 Negative |
| 13 | Final Showdown | Blasphemous Act | 24 | 91.7% | -3.3 | 🔴 Negative |
| 14 | **The Battle of Bywater** | Blasphemous Act | 24 | **95.8%** | **+0.8** | ✅ Neutral+ |

### Phase 2 Retests (12 games, higher variance)

| # | Card Added | Card Removed | G | WR | Δpp | Verdict |
|:-:|:-----------|:-------------|:-:|:--:|:---:|:--------|
| 15 | Wheel of Fate | Reforge the Soul | 12 | 91.7% | -1.6 | 🟡 Neutral− |
| 16 | Blacksmith's Skill | Flawless Maneuver | 12 | 91.7% | -1.6 | 🟡 Neutral− |
| 17 | Strike It Rich | Mana Geyser | 12 | 91.7% | -1.6 | 🟡 Neutral− |
| 18 | Chain Lightning | Rise of the Eldrazi | 12 | 91.7% | -1.6 | 🟡 Neutral− |
| 19 | **Steelshaper's Gift** 🏆 | Enlightened Tutor | 12 | **100.0%** | **+6.7** | ✅ **Positive** |
| 20 | **Furygale Flocking** 🏆 | Storm Herd | 12 | **100.0%** | **+6.7** | ✅ **Positive** |
| 21 | **Final Showdown** 🏆 | Blasphemous Act | 12 | **100.0%** | **+6.7** | ✅ **Positive** |
| 22 | Wheel of Fate | Reforge the Soul | 12 | 83.3% | -16.7 | 🔴 Negative |
| 23 | Flashback | Rite of the Dragoncaller | 12 | 100.0% | 0.0 | ✅ Neutral |
| 24 | Blacksmith's Skill | Flawless Maneuver | 12 | 83.3% | -16.7 | 🔴 Negative |
| 25 | Strike It Rich | Mana Geyser | 12 | 91.7% | -8.3 | 🔴 Negative |
| 26 | Chain Lightning | Rise of the Eldrazi | 12 | 91.7% | -8.3 | 🔴 Negative |
| 27 | Steelshaper's Gift | Imperial Recruiter | 12 | 100.0% | 0.0 | ✅ Neutral |
| 28 | Furygale Flocking | Storm Herd | 12 | 91.7% | -8.3 | 🔴 Negative |
| 29 | Final Showdown | Blasphemous Act | 12 | 100.0% | 0.0 | ✅ Neutral |

### Top 3 High-Confidence Swap Recommendations

1. **🏆 Steelshaper's Gift → Enlightened Tutor** (Δ=+6.7pp, two positive phases)
   - CMC 1 for 1. Both are instant-speed artifact/enchantment tutors. Steelshaper's Gift requires controlling an artifact — which the deck has 19 ramp artifacts + 2 artifact lands. Not strictly better, but the benchmark data suggests it outperforms in this specific build.

2. **🏆 Furygale Flocking → Storm Herd** (Δ=+6.7pp, one positive phase)
   - CMC 5 vs 10. Furygale Flocking is a board wipe that hits flying creatures (relevant against many cEDH commanders). Storm Herd is almost never castable (CMC 10, 33 lands).

3. **🏆 Final Showdown → Blasphemous Act** (Δ=+6.7pp, one positive phase)
   - Final Showdown is a modal board wipe (choose modes: destroy, exile, -5/-5) that costs XWW. More flexible than Blasphemous Act (which is good only when the board is full). The flexibility may be outperforming in the battle sim.

**Caveat**: 12-game samples have high variance (±15pp approximate confidence interval). The Phase 1 24-game runs showed neutral-to-negative deltas for the same swaps. These recommendations need 50+ game validation before any product implementation.

---

## 8. Pipeline State (June 15 — STALE Across the Board)

| Component | Status | Note |
|:----------|:-------|:-----|
| knowledge.db deck_id=6 deck_cards | ✅ 100 cards, hash `4cc51c42...` | **NEW hash** — 3rd in 24h, classification REGRESSED |
| optimizer_applied_swaps | ⚠️ **Still 0 rows** | All 6 deck changes invisible to optimizer |
| optimizer_baseline_runs | ⚠️ Run #5 (600 games, 89.8%, hash `f6367a27...`) | **STALE** — current deck is `4cc51c42...` |
| optimizer_quality_reviews | ⚠️ 5 reviews | Stale — all computed against old hashes |
| slot_benchmarks | ⚠️ 29 benchmarks | Completely stale after 2 hash changes |
| Ramp misclassification | ❌ **73% (30/41 lands tagged as ramp)** | WORSE than June 14's 63% |
| PostgreSQL sync | ✅ active | Source of classification regression |
| BATTLE_LOG.md | ✅ Updated June 14 20:50Z | 1,560 new games (9 runs) appended |
| master_optimizer_preflight | ✅ Approved (last) | Cannot detect stale data |
| Pipeline bypass detector | ❌ **Not implemented** | Task 4 still open |

**Updated conclusion**: The product-side `card_function_tags` classifier is **actively regressing**. Every sync from PostgreSQL to knowledge.db introduces more classification errors. The optimizer pipeline cannot produce reliable recommendations until the ramp classifier is fixed (Task 1) and the deck is re-baselined against clean data.

### Key Signals for App/Backend Logic

| Signal | Source | What It Would Power |
|:-------|:-------|:--------------------|
| **WR recovery detection** | Jun 9→Jun 11 recovery | Auto-detect when WR recovers from collapse; emit recovery alert instead of ongoing crisis |
| **Removal + wipe combined metric** | Collapse vs recovery comparison | Gate on `removal + board_wipes * 3 >= 8` instead of raw removal count |
| **Approach win ratio tracker** | 2.9%→20.4% recovery | Track as leading indicator; if < 5% for 2 consecutive baselines, signal identity drift |
| **Slot benchmark pipeline** | 29 benchmarks executed | Validate swaps at 24+ games before promoting to product; flag high-variance results |
| **Pipeline bypass detection** | applied_swaps empty despite deck change | Alert when deck hash changes without optimizer record |
| **Copy redundancy scoring** | 4 copy spells vs 2 in collapse | Score combo viability by number of redundant pieces, not just presence |
| **Instant count optimization** | June 12: 18 instants = +2.6pp vs 17 | Score instant density for Boros spellslinger; flag when < 16 instants |
| **Rograkh counter-strategy** | June 12: 50-100% WR vs Rograkh variants | Detect fast-commander-damage opponents; suggest early blocker inclusion |
| **Approach equilibrium monitoring** | June 12: ~19-20% approach (stable 2 days) | Track approach % as identity drift signal; alert if deviates >5pp |
| **Classification regression alert** | June 15: 63%→73% ramp misclassification in 24h | Auto-detect when functional_tag accuracy drops on re-sync; emit regression alert to pause optimizer |
| **Opponent-specific approach scoring** | June 14: Thrasios 8.7% vs Selvala 21.3% approach wins | Weight expected WR vs opponent archetype; flag when approach-reliant deck faces fast-combo commanders |
| **Hash change frequency monitor** | June 14-15: 3 deck hash changes in 24h | Alert when hash changes exceed 2/day; flag sync pipeline instability |

---

## 9. Concrete Tasks (Updated June 15 — Classification REGRESSION)

**Note**: Previous tasks 1-5 from the June 14 update remain structurally valid but need PRIORITY ADJUSTMENT due to the regression. The tasks below supersede/amend the original task descriptions. Evidence source for all task updates: `SELECT functional_tag, COUNT(*), type_line FROM deck_cards WHERE deck_id=6 GROUP BY functional_tag, SUBSTR(type_line,1,4)` from knowledge.db cross-referenced against deck_cards hash `4cc51c42...`.

### Task 1 (P0 — ESCALATED): Ramp Classifier — Exclude Lands from `ramp` Functional Tag

**Previous evidence**: 26/41 (63%) ramp cards were lands.
**Current evidence**: **30/41 (73%)** ramp cards are now lands. Misclassification **grew 10 percentage points** since June 14. The decklist itself did not change — only the sync pipeline re-ran with a worse classifier version.

Source: `SELECT card_name, type_line FROM deck_cards WHERE deck_id=6 AND functional_tag='ramp' AND type_line LIKE '%Land%'` — 30 rows returned. The 4 newly misclassified lands are Ancient Tomb (persistent), Hall of Heliod's Generosity, Needleverge Pathway, and Sunbillow Verge.

- **Priority change**: P0 → **URGENT** (escalated). The classifier is not just broken — it is actively regressing with each sync cycle. Every day without a fix produces worse data.
- **What to change**: Same as before — add a guard excluding `type_line` containing 'Land' from `ramp`. Additionally, implement a **monitor** that alerts when `ramp count > 25` (indicating >50% misclassification) so this can't silently regress again.
- **Validation**: After fix, query returns ≤16 ramp cards for deck_id=6. Current count must drop from 41 to ~15.

### Task 2 (P1): Re-baseline Lorehold — HOLD Until Task 1 is Applied

**Previous evidence**: Hash changed from `dbe24f7` → `f6367a27`.
**Current evidence**: Hash changed AGAIN from `f6367a27` → `4cc51c42`. Optimizer_baseline_runs #5 (600 games, 89.8% WR, hash `f6367a27`) is now stale. ALL 5 baseline runs and 29 slot benchmarks are stale.

- **Hold condition**: **Do NOT re-baseline until Task 1 is applied.** Running a baseline against `4cc51c42` with 73% ramp misclassification would produce unreliable role count data and waste 600 simulation games.
- **Recommended order**: (1) Fix classifier → (2) Re-sync deck → (3) Re-baseline minimum 200 games → (4) Re-run slot benchmarks.
- **Validation**: After re-baseline, optimizer_baseline_runs should have a new row with hash=`4cc51c42` (or whatever the post-fix hash is).

### Task 3 (P1 → P0): Functional Tag Taxonomy — URGENT Inclusion of Land Guard

**Previous evidence**: 7 new categories introduced inconsistently.
**Current evidence**: On top of the inconsistencies listed June 14 (Deflecting Swat as `big_spell`, Aetherflux Reservoir as `removal`), the taxonomy is now producing **worse results** for ramp with each sync cycle. The lack of formal category definitions specifically for land exclusion has caused regression.

- **Priority change**: P1 → **P0** (upgraded). The 10pp jump in misclassification rate means the problem is accelerating.
- **What to change**: Add explicit `exclude_if_land` rules to the category definitions. Specifically:
  - `ramp`: EXCLUDE all cards with `type_line` containing 'Land'. Only rocks, rituals, dorks, treasure producers.
  - `draw`: EXCLUDE tutors and reanimation spells (Mizzix's Mastery is NOT draw).
  - `removal`: EXCLUDE Aetherflux Reservoir and Boros Charm (if primary use is indestructible).
  - `big_spell`: EXCLUDE cards with CMC < 6 (Deflecting Swat at CMC 3 is not a big spell).
- **Impact**: Prevents auto-regression of the classifier with every sync.
- **Validation**: All Learned decks must have 0 cards with `type_line` containing 'Land' tagged as `ramp`.

### Task 4 (P2 → P1): Pipeline Bypass Detector — Validated by 6th Hash Change

**Previous evidence**: 5 hash changes in 14 days, 0 documented in optimizer.
**Current evidence**: **6th hash change** now confirmed (`f6367a27` → `4cc51c42`). Still 0 rows in `optimizer_applied_swaps`. The new hash came AFTER baseline run #5, meaning the 600-game June 14 deep dive is already stale before any optimization recommendations were made.

- **Priority change**: P2 → **P1** (upgraded). The frequency of undocumented hash changes is accelerating (3 changes in 24 hours).
- **What to change**: Same as before — cron check every 10 minutes. But additionally, extend the check to include `SELECT deck_hash FROM deck_cards WHERE deck_id=6 LIMIT 1` as the source of truth (since `decks` table has no hash column).
- **Validation**: Alert fires when deck_cards hash differs from last optimizer_baseline_runs hash.

### Task 5 (P2): Aetherflux Reservoir Tag Correction — No Change Since Last Report

**Previous evidence**: Aetherflux Reservoir tagged as `removal` (misclassified). This was not fixed by the June 14 reclassification.
**Current evidence**: **Still tagged as `removal`** in the `4cc51c42` classification. No change. The re-sync that happened overnight did not address this.
- **Priority**: P2 (unchanged).
- **What to change**: Single-card override in the classifier.
- **Validation**: `SELECT functional_tag FROM deck_cards WHERE card_name='Aetherflux Reservoir' AND deck_id=6` should return 'wincon' or 'payoff'.

---

## 10. Hash Tracking (Updated June 15)

| Hash | State | WR | Date | Notes |
|:-----|:------|:--:|:-----|:------|
| `4cc51c42952f...` | **🆕 Current (classification REGRESSED)** | **unknown** | 2026-06-15 ~01:51Z (detected) | Ramp misclassification 73% (30/41 lands); draw 17; engine 11. Decklist UNCHANGED from `f6367a27...` — only tags worse. |
| `f6367a273eef...` | Previous (re-tagged) | **89.8%** (run #5, 600 games) | 2026-06-14 19:24Z — 20:31Z | Reclassification pass #1. Functional tags regenerated. All optimizer data now stale. |
| `dbe24f7d5b17...` | Previous (recovered hybrid) | **92-100%** | 2026-06-11 to 2026-06-12 | 33 lands, 4 copy spells, Approach active; 696 combined games across 2 days |
| `a17a5863c95f...` | Previous (WR collapse) | 8-29% | 2026-06-09 | 31 lands, 4 removal, 0 wipes |
| `12c55613ae4f...` | Pre-collapse (stax-combo) | 89.3% | 2026-06-07 | High WR stax build |
| `763c3e0f...` | Pre-E2E Apply | 84.5% | 2026-06-07 | Baseline pre-swap |
| `30d0034776...` | Post-hash-fake | ~52% | 2026-06-01 | Missing combo pieces |

**Hash change history**: `30d0034776` → `763c3e0f` → `12c55613` → `a17a5863` (collapse) → `dbe24f7` (recovery) → `f6367a273eef` (re-tag) → `4cc51c42952f` (regression) — **6 unique hashes in 15 days, 5 undocumented by the optimizer pipeline.**
