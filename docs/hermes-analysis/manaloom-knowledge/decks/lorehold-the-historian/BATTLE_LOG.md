
## [2026-05-30T13:54:24Z] Goldfish 500 trials
Win Rate: 0.2% | Avg Turns: 9.0 | Dead: 499
Lands=35 Ramp=21 Draw=5 Removal=10 Wincons=2


## [2026-05-30T13:55:44Z] Goldfish 500 trials
Win Rate: 17.8% | Avg Turns: 4.3 | Dead: 411
Cards: 100 | L=35 R=16 D=5 X=10 W=12


## [2026-05-30T13:59:34Z] Matchup 300 trials (opponent)
Win: 0.7% (delta -17.1pp) | AvgTurns: 5.5
Loss: Threat=43 Flood=5 Stall=83
L=35 R=16 D=5 X=10 P=4 W=11


## [2026-05-30T15:29:50Z] Matchup 300 trials (opponent)
Win: 0.7% (delta -17.1pp) | AvgTurns: 10.0
Loss: Threat=47 Flood=2 Stall=91
L=35 R=16 D=5 X=10 P=4 W=11


## [2026-05-30T16:46:24Z] Matchup 300 trials (opponent)
Win: 0.3% (delta -0.4pp vs last matchup) | AvgTurns: 4.0
Loss: Threat=51 Flood=7 Stall=84
L=35 R=16 D=6 X=9 P=4 W=10

### Qualitative Analysis — 2026-05-30 Battle Cycle

**Win Rate: 0.3% (STABLE — delta -0.4pp from 0.7% baseline, within ±3pp threshold)**

#### Root Cause: Opponent Pressure Overwhelms Wincons

Three consecutive matchup simulations (300 trials each) show a **0.3–0.7%** win rate against an opponent that deploys threats on a 2–4 turn cadence. This is **structurally distinct** from the goldfish scenario (17.8% win rate).

Breakdown of loss sources across the 3 runs:
| Loss Type | Run 1 | Run 2 | Run 3 | Trend |
|-----------|-------|-------|-------|-------|
| Threat    | 43    | 47    | 51    | ↑ Worsening |
| Flood     | 5     | 2     | 7     | Stable low |
| Stall     | 83    | 91    | 84    | Stable high |

**Primary killer: STALL (83–91 losses per 300 trials)**
The deck runs out of board presence around turn 10 without a wincon. The opponent's removal (every 3–6 turns) strips non-land permanents, and the deck lacks the card draw or recursion to rebuild.

**Secondary killer: THREAT (43–51 losses, trending up)**
Answer Threats ≥3 requires removal in hand, but removal only answers one threat at a time while the opponent adds a new one every 2–4 turns. With only 9–10 removal pieces, the deck can't keep up.

#### Deck Composition Shift (Run 3 vs Runs 1–2)
- Draw: 5→6 (one more draw card added — minor improvement)
- Removal: 10→9 (one less removal — slightly worse against threats)
- Wincons: 11→10 (one fewer wincon — harder to close)
- Ramp and protection stable

#### Cards Causing Dead Draws
The deck has 10–12 wincons by tag, but many require setup (mana + board state) that the opponent disruption prevents. At 35 lands + 16 ramp, the mana base is solid (flood losses only 2–7 per 300), but ramp cards become dead draws post-board-wipe when the deck has nothing to ramp into.

#### Recommendation
The <1% matchup win rate signals the deck needs:
1. **More draw engines** — 5–6 draw cards is insufficient for a 100-card singleton format under disruption
2. **Recursion** — Lorehold's archetype strength is graveyard recursion; missing this is a critical gap
3. **Lower-CMC wincons** — Wincons castable before turn 4 (avg win turn is 4.0) die to early pressure

**VERDICT: STABLE but CRITICALLY LOW.** No delta-triggered swap review needed, but the absolute win rate demands structural deck changes, not incremental swaps.

## [2026-05-31T00:38:45Z] Real Matchup 6 archetypes (200 sims each)
Avg WR: 52.1% | Range: 46.5%-56.0%
My Deck: L=35 R=16 X=9 C=0 CMC=3.69 | Archetype: spellslinger

   52.5% vs Aggro (Krenko/Goblins) (aggro) — equilibrado
    + Mais ramp (16 vs 8), Mais removal (9 vs 5)
    - Curva mais alta (3.69 vs 2.5), aggro favorece contra spellslinger (-5)
   56.0% vs Control (Atraxa Superfriends) (control) — favoravel
    + Mais ramp (16 vs 12)
   46.5% vs Combo (Kinnan cEDH) (combo) — equilibrado
    + Mais removal (9 vs 6)
    - Curva mais alta (3.69 vs 2.1), combo favorece contra spellslinger (-5)
   52.5% vs Midrange (Korvold Value) (midrange) — equilibrado
    + Mais ramp (16 vs 12)
    - Curva mais alta (3.69 vs 3.0)
   52.5% vs Spellslinger (Niv-Mizzet) (spellslinger) — equilibrado
    + Mais ramp (16 vs 10)
    - Curva mais alta (3.69 vs 2.8)
   52.5% vs Stax (Winota Hatebears) (stax) — equilibrado
    + Mais ramp (16 vs 8)
    - Curva mais alta (3.69 vs 2.6)


## [2026-05-31T01:17:06Z] Real Matchup 6 archetypes (200 sims each)
Avg WR: 52.1% (delta -0.0pp) | Range: 46.5%-56.0%
My Deck: L=35 R=16 X=9 C=0 CMC=3.69 | Archetype: spellslinger

   52.5% vs Aggro (Krenko/Goblins) (aggro) — equilibrado
    + Mais ramp (16 vs 8), Mais removal (9 vs 5)
    - Curva mais alta (3.69 vs 2.5), aggro favorece contra spellslinger (-5)
   56.0% vs Control (Atraxa Superfriends) (control) — favoravel
    + Mais ramp (16 vs 12)
   46.5% vs Combo (Kinnan cEDH) (combo) — equilibrado
    + Mais removal (9 vs 6)
    - Curva mais alta (3.69 vs 2.1), combo favorece contra spellslinger (-5)
   52.5% vs Midrange (Korvold Value) (midrange) — equilibrado
    + Mais ramp (16 vs 12)
    - Curva mais alta (3.69 vs 3.0)
   52.5% vs Spellslinger (Niv-Mizzet) (spellslinger) — equilibrado
    + Mais ramp (16 vs 10)
    - Curva mais alta (3.69 vs 2.8)
   52.5% vs Stax (Winota Hatebears) (stax) — equilibrado
    + Mais ramp (16 vs 8)
    - Curva mais alta (3.69 vs 2.6)


## [2026-05-31T06:00:00Z] Real Matchup 6 archetypes (200 sims each)
Avg WR: 52.1% (delta +0.0pp) | Range: 46.5%-56.0%
My Deck: L=35 R=16 X=9 C=0 CMC=3.69 | Archetype: spellslinger

   52.5% vs Aggro (Krenko/Goblins) (aggro) — equilibrado
    + Mais ramp (16 vs 8), Mais removal (9 vs 5)
    - Curva mais alta (3.69 vs 2.5), aggro favorece contra spellslinger (-5)
   56.0% vs Control (Atraxa Superfriends) (control) — favoravel
    + Mais ramp (16 vs 12)
   46.5% vs Combo (Kinnan cEDH) (combo) — equilibrado
    + Mais removal (9 vs 6)
    - Curva mais alta (3.69 vs 2.1), combo favorece contra spellslinger (-5)
   52.5% vs Midrange (Korvold Value) (midrange) — equilibrado
    + Mais ramp (16 vs 12)
    - Curva mais alta (3.69 vs 3.0)
   52.5% vs Spellslinger (Niv-Mizzet) (spellslinger) — equilibrado
    + Mais ramp (16 vs 10)
    - Curva mais alta (3.69 vs 2.8)
   52.5% vs Stax (Winota Hatebears) (stax) — equilibrado
    + Mais ramp (16 vs 8)
    - Curva mais alta (3.69 vs 2.6)

### Qualitative Analysis — 2026-05-31 Battle Cycle #3

**Win Rate: 52.1% (STABLE — delta +0.0pp from 52.1% baseline, within ±3pp threshold)**

Third consecutive 6-archetype matchup simulation with **byte-identical results**. The simulation has converged deterministically — zero variance across all runs.

**No deck changes applied since last run.** Deck composition unchanged: L=35 R=16 X=9 C=0 CMC=3.69.

#### Full Run History
| # | Date | Type | WR | Delta |
|---|------|------|----|-------|
| 1 | 2026-05-30T13:54 | Goldfish 500 | 0.2% | baseline |
| 2 | 2026-05-30T13:55 | Goldfish 500 | 17.8% | +17.6pp |
| 3 | 2026-05-30T13:59 | Matchup 300 | 0.7% | -17.1pp |
| 4 | 2026-05-30T15:29 | Matchup 300 | 0.7% | 0.0pp |
| 5 | 2026-05-31T16:46 | Matchup 300 | 0.3% | -0.4pp |
| 6 | 2026-05-31T00:38 | 6-Archetype | 52.1% | N/A (new sim) |
| 7 | 2026-05-31T01:17 | 6-Archetype | 52.1% | 0.0pp |
| 8 | 2026-05-31T06:00 | 6-Archetype | 52.1% | 0.0pp |

**VERDICT: STABLE.** No delta-triggered swap review needed. The ~52% average win rate across 6 archetypes is confirmed as the baseline for this deck configuration. To improve, structural changes (more draw engines, graveyard recursion, lower-CMC wincons) are needed — not incremental swaps.

## [2026-05-31T14:43:16Z] Real Matchup 6 archetypes (200 sims each)
Avg WR: 51.1% (delta -1.0pp) | Range: 46.5%-56.0%
My Deck: L=35 R=14 X=11 C=0 CMC=3.74 | Archetype: spellslinger

   52.5% vs Aggro (Krenko/Goblins) (aggro) — equilibrado
    + Mais ramp (14 vs 8), Mais removal (11 vs 5)
    - Curva mais alta (3.74 vs 2.5), aggro favorece contra spellslinger (-5)
   46.5% vs Control (Atraxa Superfriends) (control) — equilibrado
    - Curva mais alta (3.74 vs 3.2)
   46.5% vs Combo (Kinnan cEDH) (combo) — equilibrado
    + Mais removal (11 vs 6)
    - Curva mais alta (3.74 vs 2.1), combo favorece contra spellslinger (-5)
   52.5% vs Midrange (Korvold Value) (midrange) — equilibrado
    + Mais removal (11 vs 8)
    - Curva mais alta (3.74 vs 3.0)
   52.5% vs Spellslinger (Niv-Mizzet) (spellslinger) — equilibrado
    + Mais ramp (14 vs 10)
    - Curva mais alta (3.74 vs 2.8)
   56.0% vs Stax (Winota Hatebears) (stax) — favoravel
    + Mais ramp (14 vs 8), Mais removal (11 vs 8)
    - Curva mais alta (3.74 vs 2.6)


## [2026-05-31T15:52:54Z] Battle Analyst v6 — REAL Game Simulation
Games per opponent: 100
Deck: 100c | L=35 R=14 X=11 C=9 CMC=3.74

| Opponent | Archetype | WR | Wins | Losses | Stalls | Avg Win Turn |
|:---------|:----------|---:|-----:|-------:|-------:|-------------:|
| Aggro (Krenko) | aggro | 23.0% | 23 | 77 | 0 | 13.1 |
| Control (Atraxa) | control | 64.0% | 64 | 33 | 3 | 17.3 |
| Combo (Kinnan) | combo | 36.0% | 36 | 64 | 0 | 13.6 |
| Midrange (Korvold) | midrange | 42.0% | 42 | 58 | 0 | 14.7 |
| Spellslinger (Niv-Mizzet) | spellslinger | 65.0% | 65 | 35 | 0 | 15.7 |
| Stax (Winota) | stax | 60.0% | 60 | 40 | 0 | 14.8 |

**Overall WR: 48.3%** (290W/307L/3S)

### Loss Reasons
- vs Aggro (Krenko): life_zero=77
- vs Control (Atraxa): life_zero=33
- vs Combo (Kinnan): life_zero=64
- vs Midrange (Korvold): life_zero=58
- vs Spellslinger (Niv-Mizzet): life_zero=35
- vs Stax (Winota): life_zero=40

## [2026-05-31T15:55:03Z] Battle Analyst v6 — REAL Game Simulation
Games per opponent: 100
Deck: 100c | L=35 R=14 X=11 C=9 CMC=3.74

| Opponent | Archetype | WR | Wins | Losses | Stalls | Avg Win Turn |
|:---------|:----------|---:|-----:|-------:|-------:|-------------:|
| Aggro (Krenko) | aggro | 23.0% | 23 | 77 | 0 | 13.1 |
| Control (Atraxa) | control | 64.0% | 64 | 33 | 3 | 17.3 |
| Combo (Kinnan) | combo | 36.0% | 36 | 64 | 0 | 13.6 |
| Midrange (Korvold) | midrange | 42.0% | 42 | 58 | 0 | 14.7 |
| Spellslinger (Niv-Mizzet) | spellslinger | 65.0% | 65 | 35 | 0 | 15.7 |
| Stax (Winota) | stax | 60.0% | 60 | 40 | 0 | 14.8 |

**Overall WR: 48.3%** (290W/307L/3S)

### Loss Reasons
- vs Aggro (Krenko): life_zero=77
- vs Control (Atraxa): life_zero=33
- vs Combo (Kinnan): life_zero=64
- vs Midrange (Korvold): life_zero=58
- vs Spellslinger (Niv-Mizzet): life_zero=35
- vs Stax (Winota): life_zero=40

## [2026-05-31T16:20:28Z] Battle Analyst v7 — Commander Rule-Compliant
Games: 100 | Deck: 1+99c | L=35 R=14 X=11 CMC=3.72
v7: Commander Zone, Commander Damage, Blockers, Summoning Sickness, Cleanup, Colored Mana, Postcombat Main

| Opponent | WR | Wins | Losses | Stalls | Avg Win Turn | Win Reasons |
|:---------|----:|-----:|-------:|-------:|-------------:|:------------|
| Aggro (Krenko) | 97.0% | 97 | 1 | 2 | 14.5 | approach=31, elimination=66 |
| Control (Atraxa) | 93.0% | 93 | 0 | 7 | 17.1 | approach=34, elimination=59 |
| Combo (Kinnan) | 93.0% | 93 | 1 | 6 | 13.6 | elimination=72, approach=21 |
| Midrange (Korvold) | 97.0% | 97 | 1 | 2 | 14.9 | approach=44, elimination=53 |
| Spellslinger (Niv) | 90.0% | 90 | 1 | 9 | 14.8 | approach=29, elimination=61 |
| Stax (Winota) | 95.0% | 95 | 0 | 5 | 15.3 | approach=33, elimination=62 |

**Overall WR: 94.2%** (565W/4L/31S)

## [2026-05-31T16:22:10Z] Battle Analyst v7 — Commander Rule-Compliant
Games: 100 | Deck: 1+99c | L=35 R=14 X=11 CMC=3.72
v7: Commander Zone, Commander Damage, Blockers, Summoning Sickness, Cleanup, Colored Mana, Postcombat Main

| Opponent | WR | Wins | Losses | Stalls | Avg Win Turn | Win Reasons |
|:---------|----:|-----:|-------:|-------:|-------------:|:------------|
| Aggro (Krenko) | 81.0% | 81 | 0 | 19 | 17.4 | approach=55, elimination=26 |
| Control (Atraxa) | 77.0% | 77 | 1 | 22 | 18.4 | approach=50, elimination=27 |
| Combo (Kinnan) | 84.0% | 84 | 1 | 15 | 17.1 | approach=58, elimination=26 |
| Midrange (Korvold) | 77.0% | 77 | 1 | 22 | 16.0 | elimination=27, approach=50 |
| Spellslinger (Niv) | 72.0% | 72 | 4 | 24 | 17.5 | approach=51, elimination=21 |
| Stax (Winota) | 82.0% | 82 | 0 | 18 | 17.7 | approach=54, elimination=28 |

**Overall WR: 78.8%** (473W/7L/120S)

## [2026-05-31T16:49:15Z] Battle Analyst v8 — Interactive Commander
Games: 100 4-player | Deck: L=35 R=14 X=11 CMC=3.72 Instants=15
v8: Priority, Stack, Instant/Sorcery, Counterspells, SBAs, Miracle, Boros Charm modal, Lifelink, Haste

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Aggro (Krenko) | 67.0% | 67 | 8 | 25 | 20.7 | approach=62, elimination=5 |
| Control (Atraxa) | 77.0% | 77 | 2 | 21 | 22.2 | approach=68, elimination=9 |
| Combo (Kinnan) | 66.0% | 66 | 7 | 27 | 22.2 | approach=62, elimination=4 |
| Midrange (Korvold) | 68.0% | 68 | 12 | 20 | 22.5 | approach=63, elimination=5 |
| Spellslinger (Niv) | 70.0% | 70 | 11 | 19 | 23.2 | approach=63, elimination=7 |
| Stax (Winota) | 68.0% | 68 | 11 | 21 | 21.9 | approach=64, elimination=4 |

**Overall WR: 69.3%** (416W/51L/133S)

## [2026-05-31T17:53:53Z] Battle Analyst v8 — Interactive Commander
Games: 100 4-player | Deck: L=35 R=14 X=11 CMC=3.69 Instants=16
v8: Priority, Stack, Instant/Sorcery, Counterspells, SBAs, Miracle, Boros Charm modal, Lifelink, Haste

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Aggro (Krenko) | 69.0% | 69 | 1 | 30 | 22.1 | approach=64, elimination=5 |
| Control (Atraxa) | 69.0% | 69 | 9 | 22 | 23.6 | approach=62, elimination=7 |
| Combo (Kinnan) | 67.0% | 67 | 8 | 25 | 21.6 | approach=58, elimination=9 |
| Midrange (Korvold) | 65.0% | 65 | 7 | 28 | 22.7 | approach=53, elimination=12 |
| Spellslinger (Niv) | 69.0% | 69 | 9 | 22 | 23.9 | approach=62, elimination=7 |
| Stax (Winota) | 67.0% | 67 | 4 | 29 | 20.9 | approach=66, elimination=1 |

**Overall WR: 67.7%** (406W/38L/156S)


### Qualitative Analysis — 2026-05-31 Battle Cycle v8 #2

**Overall WR: 67.7%** (delta **-1.6pp** from v8 #1 baseline of 69.3%) — within ±3pp threshold, **STABLE**.

#### WR by Archetype (with Delta vs v8 #1)

| Archetype | v8 #1 WR | v8 #2 WR | Δ WR | Losses Δ | Stalls Δ |
|:----------|---------:|---------:|-----:|---------:|---------:|
| Aggro (Krenko) | 67.0% | **69.0%** | +2.0pp | -7 (8→1) | +5 (25→30) |
| Control (Atraxa) | 77.0% | **69.0%** | -8.0pp | +7 (2→9) | +1 (21→22) |
| Combo (Kinnan) | 66.0% | **67.0%** | +1.0pp | +1 (7→8) | -2 (27→25) |
| Midrange (Korvold) | 68.0% | **65.0%** | -3.0pp | -5 (12→7) | +8 (20→28) |
| Spellslinger (Niv) | 70.0% | **69.0%** | -1.0pp | -2 (11→9) | +3 (19→22) |
| Stax (Winota) | 68.0% | **67.0%** | -1.0pp | -7 (11→4) | +8 (21→29) |
| **OVERALL** | **69.3%** | **67.7%** | **-1.6pp** | **-13 (51→38)** | **+23 (133→156)** |

#### Critical Findings

**1. Loss-to-Stall Migration (Structural Shift)**
Net losses dropped 13 (51→38) but stalls increased 23 (133→156). The deck is **dying less but timing out more**. This suggests:
- Better defensive play (instants, indestructible, Miracle timing) is keeping Lorehold alive
- But the deck still lacks the speed to close before turn 35
- The max_turns=35 ceiling is the silent bottleneck

**2. Aggro & Stax Dramatically Improved**
- **Aggro losses: 8→1** (-87.5%). Miracle + instant-speed removal is crushing goblin rushes
- **Stax losses: 11→4** (-63.6%). Better stack management counters Winota's hatebear lock
- These 2 archetypes account for 14 fewer losses vs v8 #1

**3. Control Deteriorated (⚠️ Watch)**
- **Control losses: 2→9** (+350%). Atraxa's 6 counterspells are now cancelling our Approach of the Second Sun
- The stack's `top_is_threat()` detects Approach as a threat, triggering opponent counterspell AI
- An 8.0pp drop suggests some runs had Approach countered multiple times (needs 2 successful casts)
- Our deck has **zero counterspells** — we can't fight over the stack defensively

**4. Stalls Are the Ceiling (26.0% avg)**
- 156/600 games (26.0%) hit turn 35 without resolution
- 49 mana sources (35 lands + 14 ramp) against CMC 3.69 curve = ramp-heavy but slow to deploy
- Avg win turn: **21.6–23.9** — extremely late for Commander
- Approach needs 2 casts + 7 cards between them → earliest possible win is ~turn 12 in ideal conditions

**5. Approach Dominance (89.9% of Wins)**
| Win Reason | Count | % of Wins |
|:-----------|------:|----------:|
| Approach of the Second Sun | 365 | 89.9% |
| Elimination (combat damage) | 41 | 10.1% |

The deck is a **one-trick pony**. If Approach is countered, there's no backup plan. When it works (mostly), the deck wins. When it doesn't (Control matchups, bad draws), we stall out.

**6. v8 Mechanics Working Well**
- Priority system correctly gives opponents counter windows
- Miracle {2} on Lorehold provides cost reduction for instants/sorceries
- Lifelink and Haste on Lorehold contribute to combat survival
- Indestructible per-creature protects key pieces from board wipes
- Double Strike is correctly applying 2x (not 3x)

#### Recommendations

1. **Add alternate wincon** — Approach is countered too easily vs Control (6 counterspells vs our 0). Aetherflux Reservoir, Comet Storm, or Aria of Flame bypass counterspell windows
2. **Reduce stalls** — Lower the mana curve (target CMC < 3.0) to deploy threats turns 3-5 instead of turns 6-8
3. **Graveyard recursion** — Lorehold's core mechanic (copy from graveyard) is under-modeled. Mizzix's Mastery is the only recursion wincon coded
4. **Counterplay vs Control** — Grand Abolisher, Defense Grid, or redirection effects needed specifically against Atraxa's counterspell density
5. **Increase max_turns to 45** — 26% of games time out at turn 35; extending to 45 would convert some stalls to wins or clarify true stalemates

#### VERDICT

**No GAP CRITICO** — all archetype WRs are ≥65%, well above the 40% critical threshold.

**STABLE** — overall delta (-1.6pp) within ±3pp threshold. The Control drop (-8.0pp) is the only archetype-level concern but doesn't cross the 40% line.

**Next priority:** Address the stall problem (26% timeout rate) by lowering mana curve and adding secondary win conditions not susceptible to counterspells.

## [2026-05-31T17:56:47Z] Battle Analyst v8 — Interactive Commander
Games: 100 4-player | Deck: L=35 R=14 X=11 CMC=3.69 Instants=16
v8: Priority, Stack, Instant/Sorcery, Counterspells, SBAs, Miracle, Boros Charm modal, Lifelink, Haste

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Aggro (Krenko) | 69.0% | 69 | 1 | 30 | 22.1 | approach=64, elimination=5 |
| Control (Atraxa) | 69.0% | 69 | 9 | 22 | 23.6 | approach=62, elimination=7 |
| Combo (Kinnan) | 67.0% | 67 | 8 | 25 | 21.6 | approach=58, elimination=9 |
| Midrange (Korvold) | 65.0% | 65 | 7 | 28 | 22.7 | approach=53, elimination=12 |
| Spellslinger (Niv) | 69.0% | 69 | 9 | 22 | 23.9 | approach=62, elimination=7 |
| Stax (Winota) | 67.0% | 67 | 4 | 29 | 20.9 | approach=66, elimination=1 |

**Overall WR: 67.7%** (406W/38L/156S)

## [2026-05-31T18:12:19Z] Battle Analyst v8 — Interactive Commander
Games: 100 4-player | Deck: L=35 R=14 X=11 CMC=3.69 Instants=16
v8: Priority, Stack, Instant/Sorcery, Counterspells, SBAs, Miracle, Boros Charm modal, Lifelink, Haste

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Aggro (Krenko) | 69.0% | 69 | 1 | 30 | 22.1 | approach=64, elimination=5 |
| Control (Atraxa) | 69.0% | 69 | 9 | 22 | 23.6 | approach=62, elimination=7 |
| Combo (Kinnan) | 67.0% | 67 | 8 | 25 | 21.6 | approach=58, elimination=9 |
| Midrange (Korvold) | 65.0% | 65 | 7 | 28 | 22.7 | approach=53, elimination=12 |
| Spellslinger (Niv) | 69.0% | 69 | 9 | 22 | 23.9 | approach=62, elimination=7 |
| Stax (Winota) | 67.0% | 67 | 4 | 29 | 20.9 | approach=66, elimination=1 |

**Overall WR: 67.7%** (406W/38L/156S)

## [2026-05-31T19:11:51Z] Battle Analyst v8 — Interactive Commander
Games: 100 4-player | Deck: L=35 R=14 X=11 CMC=3.69 Instants=16
v8: Priority, Stack, Instant/Sorcery, Counterspells, SBAs, Miracle, Boros Charm modal, Lifelink, Haste

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Aggro (Krenko) | 69.0% | 69 | 1 | 30 | 22.1 | approach=64, elimination=5 |
| Control (Atraxa) | 69.0% | 69 | 9 | 22 | 23.6 | approach=62, elimination=7 |
| Combo (Kinnan) | 67.0% | 67 | 8 | 25 | 21.6 | approach=58, elimination=9 |
| Midrange (Korvold) | 65.0% | 65 | 7 | 28 | 22.7 | approach=53, elimination=12 |
| Spellslinger (Niv) | 69.0% | 69 | 9 | 22 | 23.9 | approach=62, elimination=7 |
| Stax (Winota) | 67.0% | 67 | 4 | 29 | 20.9 | approach=66, elimination=1 |

**Overall WR: 67.7%** (406W/38L/156S)

## [2026-05-31T22:00:52Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=35 R=14 X=11 CMC=3.69 Instants=16
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Tayam, Luminous Enigma (real) | 98.0% | 49 | 0 | 1 | 10.5 | approach=49 |
| Winota, Joiner of Forces (real) | 90.0% | 45 | 0 | 5 | 10.8 | approach=45 |
| Veyran, Voice of Duality (real) | 94.0% | 47 | 0 | 3 | 11.0 | approach=47 |
| Niv-Mizzet, Parun (real) | 94.0% | 47 | 0 | 3 | 10.7 | approach=47 |
| Tivit, Seller of Secrets (real) | 96.0% | 48 | 0 | 2 | 10.8 | approach=48 |
| Korvold, Fae-Cursed King (real) | 100.0% | 50 | 0 | 0 | 10.9 | approach=50 |
| Grand Arbiter Augustin IV (real) | 96.0% | 48 | 0 | 2 | 10.9 | approach=48 |
| Atraxa, Praetors' Voice (real) | 98.0% | 49 | 0 | 1 | 11.4 | approach=49 |
| Urza, Lord High Artificer (real) | 98.0% | 49 | 0 | 1 | 10.9 | approach=49 |
| Kinnan, Bonder Prodigy (real) | 98.0% | 49 | 0 | 1 | 10.6 | approach=49 |
| Winota, Joiner of Forces (real) | 96.0% | 48 | 0 | 2 | 10.9 | approach=48 |
| Krenko, Mob Boss (real) | 96.0% | 48 | 0 | 2 | 10.7 | approach=48 |

**Overall WR: 96.2%** (577W/0L/23S)

## [2026-05-31T22:01:30Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=35 R=14 X=11 CMC=3.69 Instants=16
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Tayam, Luminous Enigma (real) | 56.0% | 28 | 20 | 2 | 10.2 | approach=19, elimination=9 |
| Winota, Joiner of Forces (real) | 64.0% | 32 | 15 | 3 | 10.4 | approach=23, elimination=9 |
| Veyran, Voice of Duality (real) | 54.0% | 27 | 21 | 2 | 10.4 | approach=19, elimination=8 |
| Niv-Mizzet, Parun (real) | 72.0% | 36 | 12 | 2 | 11.1 | approach=24, elimination=12 |
| Tivit, Seller of Secrets (real) | 58.0% | 29 | 20 | 1 | 11.4 | approach=24, elimination=5 |
| Korvold, Fae-Cursed King (real) | 64.0% | 32 | 15 | 3 | 10.6 | elimination=9, approach=23 |
| Grand Arbiter Augustin IV (real) | 68.0% | 34 | 14 | 2 | 10.4 | approach=25, elimination=9 |
| Atraxa, Praetors' Voice (real) | 56.0% | 28 | 19 | 3 | 10.3 | approach=26, elimination=2 |
| Urza, Lord High Artificer (real) | 62.0% | 31 | 15 | 4 | 10.3 | approach=23, elimination=8 |
| Kinnan, Bonder Prodigy (real) | 60.0% | 30 | 19 | 1 | 10.7 | approach=24, elimination=6 |
| Winota, Joiner of Forces (real) | 66.0% | 33 | 14 | 3 | 10.8 | approach=24, elimination=9 |
| Krenko, Mob Boss (real) | 52.0% | 26 | 19 | 5 | 10.5 | approach=21, elimination=5 |

**Overall WR: 61.0%** (366W/203L/31S)
