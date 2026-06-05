
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

## [2026-06-01T00:00:03Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=35 R=14 X=11 CMC=3.69 Instants=16
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Lorehold, the Historian (real) | 50.0% | 25 | 24 | 1 | 9.9 | approach=20, elimination=5 |
| Lorehold, the Historian (real) | 52.0% | 26 | 23 | 1 | 9.4 | approach=23, elimination=3 |
| Lorehold, the Historian (real) | 38.0% | 19 | 31 | 0 | 9.8 | approach=17, elimination=2 |
| Lorehold, the Historian (real) | 48.0% | 24 | 25 | 1 | 9.2 | elimination=4, approach=20 |
| Lorehold, the Historian (real) | 44.0% | 22 | 28 | 0 | 10.6 | approach=19, elimination=3 |
| Lorehold, the Historian (real) | 54.0% | 27 | 23 | 0 | 10.4 | approach=22, elimination=5 |
| Lorehold, the Historian (real) | 42.0% | 21 | 29 | 0 | 9.4 | approach=16, elimination=5 |
| Lorehold, the Historian (real) | 44.0% | 22 | 28 | 0 | 9.8 | approach=19, elimination=3 |
| Lorehold, the Historian (real) | 48.0% | 24 | 24 | 2 | 11.4 | approach=19, elimination=5 |
| Lorehold, the Historian (real) | 38.0% | 19 | 31 | 0 | 10.4 | approach=16, elimination=3 |
| Lorehold, the Historian (real) | 50.0% | 25 | 25 | 0 | 10.4 | approach=17, elimination=8 |
| Lorehold, the Historian (real) | 48.0% | 24 | 26 | 0 | 10.5 | approach=20, elimination=4 |

**Overall WR: 46.3%** (278W/317L/5S)

## [2026-06-01T02:46:56Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=35 R=14 X=10 CMC=3.61 Instants=17
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Lorehold, the Historian (real) | 46.0% | 23 | 25 | 2 | 10.3 | approach=17, elimination=6 |
| Lorehold, the Historian (real) | 50.0% | 25 | 25 | 0 | 10.2 | approach=23, elimination=2 |
| Lorehold, the Historian (real) | 54.0% | 27 | 22 | 1 | 9.5 | approach=26, elimination=1 |
| Lorehold, the Historian (real) | 44.0% | 22 | 27 | 1 | 10.1 | approach=21, elimination=1 |
| Lorehold, the Historian (real) | 50.0% | 25 | 25 | 0 | 9.8 | approach=22, elimination=3 |
| Lorehold, the Historian (real) | 44.0% | 22 | 27 | 1 | 9.5 | approach=21, elimination=1 |
| Lorehold, the Historian (real) | 48.0% | 24 | 26 | 0 | 9.8 | approach=21, elimination=3 |
| Lorehold, the Historian (real) | 52.0% | 26 | 23 | 1 | 9.4 | approach=26 |
| Lorehold, the Historian (real) | 46.0% | 23 | 27 | 0 | 9.3 | approach=22, elimination=1 |
| Lorehold, the Historian (real) | 52.0% | 26 | 22 | 2 | 10.5 | approach=23, elimination=3 |
| Lorehold, the Historian (real) | 52.0% | 26 | 23 | 1 | 10.0 | approach=24, elimination=2 |
| Lorehold, the Historian (real) | 34.0% | 17 | 32 | 1 | 9.5 | elimination=3, approach=14 |

**Overall WR: 47.7%** (286W/304L/10S)

## [2026-06-01T06:59:59Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=35 R=16 X=9 CMC=3.61 Instants=14
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 56.0% | 28 | 20 | 2 | 10.4 | approach=27, elimination=1 |
| Lier, Disciple of the Drowned (real) | 64.0% | 32 | 15 | 3 | 9.6 | approach=31, elimination=1 |
| Aragorn, King of Gondor (real) | 64.0% | 32 | 15 | 3 | 10.0 | approach=27, elimination=5 |
| Tasigur, the Golden Fang (real) | 64.0% | 32 | 17 | 1 | 10.0 | approach=31, elimination=1 |
| Cloud, Midgar Mercenary (real) | 68.0% | 34 | 15 | 1 | 10.0 | approach=32, elimination=2 |
| Deadpool, Trading Card (real) | 72.0% | 36 | 14 | 0 | 10.2 | approach=31, elimination=5 |
|  (real) | 70.0% | 35 | 15 | 0 | 10.6 | approach=33, elimination=2 |
| Malcolm, Keen-Eyed Navigator (real) | 66.0% | 33 | 13 | 4 | 10.2 | approach=28, elimination=5 |
| Slimefoot and Squee (real) | 72.0% | 36 | 8 | 6 | 9.6 | elimination=4, approach=32 |
| Rograkh, Son of Rohgahh (real) | 58.0% | 29 | 19 | 2 | 10.6 | approach=28, elimination=1 |
| Kenrith, the Returned King (real) | 68.0% | 34 | 15 | 1 | 10.4 | approach=32, elimination=2 |
| The Jolly Balloon Man (real) | 68.0% | 34 | 13 | 3 | 9.7 | approach=32, elimination=2 |

**Overall WR: 65.8%** (395W/179L/26S)

## [2026-06-01T23:20:19Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=35 R=16 X=9 CMC=3.62 Instants=14
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 28.0% | 14 | 34 | 2 | 12.1 | elimination=14 |
| Lier, Disciple of the Drowned (real) | 28.0% | 14 | 32 | 4 | 11.9 | elimination=14 |
| Aragorn, King of Gondor (real) | 20.0% | 10 | 38 | 2 | 12.8 | elimination=10 |
| Tasigur, the Golden Fang (real) | 22.0% | 11 | 35 | 4 | 12.1 | elimination=11 |
| Cloud, Midgar Mercenary (real) | 22.0% | 11 | 38 | 1 | 11.6 | elimination=11 |
| Deadpool, Trading Card (real) | 14.0% | 7 | 41 | 2 | 12.1 | elimination=7 |
|  (real) | 28.0% | 14 | 33 | 3 | 12.1 | elimination=14 |
| Malcolm, Keen-Eyed Navigator (real) | 14.0% | 7 | 39 | 4 | 12.1 | elimination=7 |
| Slimefoot and Squee (real) | 20.0% | 10 | 37 | 3 | 12.4 | elimination=10 |
| Rograkh, Son of Rohgahh (real) | 14.0% | 7 | 42 | 1 | 12.7 | elimination=7 |
| Kenrith, the Returned King (real) | 26.0% | 13 | 33 | 4 | 14.0 | elimination=13 |
| The Jolly Balloon Man (real) | 14.0% | 7 | 42 | 1 | 11.7 | elimination=7 |

**Overall WR: 20.8%** (125W/444L/31S)

## [2026-06-01T23:23:08Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=35 R=17 X=8 CMC=3.70 Instants=13
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 24.0% | 12 | 38 | 0 | 11.9 | elimination=12 |
| Lier, Disciple of the Drowned (real) | 26.0% | 13 | 36 | 1 | 11.4 | elimination=13 |
| Aragorn, King of Gondor (real) | 30.0% | 15 | 30 | 5 | 12.3 | elimination=15 |
| Tasigur, the Golden Fang (real) | 22.0% | 11 | 38 | 1 | 12.3 | elimination=11 |
| Cloud, Midgar Mercenary (real) | 26.0% | 13 | 36 | 1 | 13.2 | elimination=13 |
| Deadpool, Trading Card (real) | 24.0% | 12 | 35 | 3 | 12.4 | elimination=12 |
|  (real) | 26.0% | 13 | 35 | 2 | 11.8 | elimination=13 |
| Malcolm, Keen-Eyed Navigator (real) | 22.0% | 11 | 38 | 1 | 12.8 | elimination=11 |
| Slimefoot and Squee (real) | 36.0% | 18 | 31 | 1 | 12.7 | elimination=18 |
| Rograkh, Son of Rohgahh (real) | 26.0% | 13 | 34 | 3 | 12.8 | elimination=13 |
| Kenrith, the Returned King (real) | 26.0% | 13 | 37 | 0 | 13.2 | elimination=13 |
| The Jolly Balloon Man (real) | 34.0% | 17 | 31 | 2 | 12.5 | elimination=17 |

**Overall WR: 26.8%** (161W/419L/20S)

## [2026-06-01T23:25:58Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=35 R=13 X=12 CMC=3.66 Instants=10
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 22.0% | 11 | 35 | 4 | 11.8 | elimination=11 |
| Lier, Disciple of the Drowned (real) | 28.0% | 14 | 35 | 1 | 12.4 | elimination=14 |
| Aragorn, King of Gondor (real) | 42.0% | 21 | 26 | 3 | 12.1 | elimination=21 |
| Tasigur, the Golden Fang (real) | 38.0% | 19 | 28 | 3 | 12.1 | elimination=19 |
| Cloud, Midgar Mercenary (real) | 24.0% | 12 | 37 | 1 | 12.8 | elimination=12 |
| Deadpool, Trading Card (real) | 24.0% | 12 | 36 | 2 | 12.6 | elimination=12 |
|  (real) | 34.0% | 17 | 32 | 1 | 12.6 | elimination=17 |
| Malcolm, Keen-Eyed Navigator (real) | 20.0% | 10 | 35 | 5 | 11.7 | elimination=10 |
| Slimefoot and Squee (real) | 16.0% | 8 | 41 | 1 | 12.6 | elimination=8 |
| Rograkh, Son of Rohgahh (real) | 22.0% | 11 | 39 | 0 | 12.0 | elimination=11 |
| Kenrith, the Returned King (real) | 20.0% | 10 | 37 | 3 | 13.0 | elimination=10 |
| The Jolly Balloon Man (real) | 22.0% | 11 | 39 | 0 | 13.7 | elimination=11 |

**Overall WR: 26.0%** (156W/420L/24S)

## [2026-06-01T23:28:16Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=35 R=16 X=7 CMC=2.60 Instants=8
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 4.0% | 2 | 48 | 0 | 10.5 | elimination=2 |
| Lier, Disciple of the Drowned (real) | 6.0% | 3 | 45 | 2 | 10.3 | elimination=3 |
| Aragorn, King of Gondor (real) | 14.0% | 7 | 43 | 0 | 10.4 | elimination=7 |
| Tasigur, the Golden Fang (real) | 8.0% | 4 | 44 | 2 | 10.5 | elimination=4 |
| Cloud, Midgar Mercenary (real) | 4.0% | 2 | 48 | 0 | 12.5 | elimination=2 |
| Deadpool, Trading Card (real) | 10.0% | 5 | 44 | 1 | 10.6 | elimination=5 |
|  (real) | 8.0% | 4 | 45 | 1 | 11.5 | elimination=4 |
| Malcolm, Keen-Eyed Navigator (real) | 12.0% | 6 | 42 | 2 | 10.8 | elimination=6 |
| Slimefoot and Squee (real) | 6.0% | 3 | 44 | 3 | 10.7 | elimination=3 |
| Rograkh, Son of Rohgahh (real) | 8.0% | 4 | 46 | 0 | 10.0 | elimination=4 |
| Kenrith, the Returned King (real) | 14.0% | 7 | 43 | 0 | 10.9 | elimination=7 |
| The Jolly Balloon Man (real) | 4.0% | 2 | 48 | 0 | 12.0 | elimination=2 |

**Overall WR: 8.2%** (49W/540L/11S)

## [2026-06-01T23:29:10Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=47 R=13 X=4 CMC=3.25 Instants=6
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 38.0% | 19 | 30 | 1 | 11.6 | elimination=19 |
| Lier, Disciple of the Drowned (real) | 42.0% | 21 | 29 | 0 | 11.3 | elimination=21 |
| Aragorn, King of Gondor (real) | 44.0% | 22 | 27 | 1 | 12.1 | elimination=22 |
| Tasigur, the Golden Fang (real) | 20.0% | 10 | 38 | 2 | 11.8 | elimination=10 |
| Cloud, Midgar Mercenary (real) | 30.0% | 15 | 35 | 0 | 12.7 | elimination=15 |
| Deadpool, Trading Card (real) | 36.0% | 18 | 32 | 0 | 12.1 | elimination=18 |
|  (real) | 18.0% | 9 | 40 | 1 | 12.6 | elimination=9 |
| Malcolm, Keen-Eyed Navigator (real) | 34.0% | 17 | 33 | 0 | 12.3 | elimination=17 |
| Slimefoot and Squee (real) | 36.0% | 18 | 31 | 1 | 12.3 | elimination=18 |
| Rograkh, Son of Rohgahh (real) | 36.0% | 18 | 32 | 0 | 11.3 | elimination=18 |
| Kenrith, the Returned King (real) | 22.0% | 11 | 38 | 1 | 12.1 | elimination=11 |
| The Jolly Balloon Man (real) | 46.0% | 23 | 26 | 1 | 10.7 | elimination=23 |

**Overall WR: 33.5%** (201W/391L/8S)

## [2026-06-01T23:30:17Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=47 R=13 X=4 CMC=3.25 Instants=6
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 38.0% | 19 | 30 | 1 | 11.6 | elimination=19 |
| Lier, Disciple of the Drowned (real) | 42.0% | 21 | 29 | 0 | 11.3 | elimination=21 |
| Aragorn, King of Gondor (real) | 44.0% | 22 | 27 | 1 | 12.1 | elimination=22 |
| Tasigur, the Golden Fang (real) | 20.0% | 10 | 38 | 2 | 11.8 | elimination=10 |
| Cloud, Midgar Mercenary (real) | 30.0% | 15 | 35 | 0 | 12.7 | elimination=15 |
| Deadpool, Trading Card (real) | 36.0% | 18 | 32 | 0 | 12.1 | elimination=18 |
|  (real) | 18.0% | 9 | 40 | 1 | 12.6 | elimination=9 |
| Malcolm, Keen-Eyed Navigator (real) | 34.0% | 17 | 33 | 0 | 12.3 | elimination=17 |
| Slimefoot and Squee (real) | 36.0% | 18 | 31 | 1 | 12.3 | elimination=18 |
| Rograkh, Son of Rohgahh (real) | 36.0% | 18 | 32 | 0 | 11.3 | elimination=18 |
| Kenrith, the Returned King (real) | 22.0% | 11 | 38 | 1 | 12.1 | elimination=11 |
| The Jolly Balloon Man (real) | 46.0% | 23 | 26 | 1 | 10.7 | elimination=23 |

**Overall WR: 33.5%** (201W/391L/8S)

## [2026-06-01T23:31:02Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=40 R=13 X=7 CMC=3.10 Instants=9
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 42.0% | 21 | 27 | 2 | 11.7 | elimination=21 |
| Lier, Disciple of the Drowned (real) | 38.0% | 19 | 31 | 0 | 12.0 | elimination=19 |
| Aragorn, King of Gondor (real) | 36.0% | 18 | 29 | 3 | 11.6 | elimination=18 |
| Tasigur, the Golden Fang (real) | 42.0% | 21 | 28 | 1 | 11.7 | elimination=21 |
| Cloud, Midgar Mercenary (real) | 36.0% | 18 | 31 | 1 | 12.1 | elimination=18 |
| Deadpool, Trading Card (real) | 40.0% | 20 | 26 | 4 | 12.1 | elimination=20 |
|  (real) | 44.0% | 22 | 26 | 2 | 12.4 | elimination=22 |
| Malcolm, Keen-Eyed Navigator (real) | 34.0% | 17 | 31 | 2 | 12.2 | elimination=17 |
| Slimefoot and Squee (real) | 40.0% | 20 | 28 | 2 | 11.7 | elimination=20 |
| Rograkh, Son of Rohgahh (real) | 38.0% | 19 | 31 | 0 | 12.5 | elimination=19 |
| Kenrith, the Returned King (real) | 52.0% | 26 | 24 | 0 | 11.8 | elimination=26 |
| The Jolly Balloon Man (real) | 40.0% | 20 | 29 | 1 | 11.8 | elimination=20 |

**Overall WR: 40.2%** (241W/341L/18S)

## [2026-06-01T23:37:37Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=40 R=13 X=7 CMC=3.10 Instants=9
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 42.0% | 21 | 27 | 2 | 11.7 | elimination=21 |
| Lier, Disciple of the Drowned (real) | 38.0% | 19 | 31 | 0 | 12.0 | elimination=19 |
| Aragorn, King of Gondor (real) | 36.0% | 18 | 29 | 3 | 11.6 | elimination=18 |
| Tasigur, the Golden Fang (real) | 42.0% | 21 | 28 | 1 | 11.7 | elimination=21 |
| Cloud, Midgar Mercenary (real) | 36.0% | 18 | 31 | 1 | 12.1 | elimination=18 |
| Deadpool, Trading Card (real) | 40.0% | 20 | 26 | 4 | 12.1 | elimination=20 |
|  (real) | 44.0% | 22 | 26 | 2 | 12.4 | elimination=22 |
| Malcolm, Keen-Eyed Navigator (real) | 34.0% | 17 | 31 | 2 | 12.2 | elimination=17 |
| Slimefoot and Squee (real) | 40.0% | 20 | 28 | 2 | 11.7 | elimination=20 |
| Rograkh, Son of Rohgahh (real) | 38.0% | 19 | 31 | 0 | 12.5 | elimination=19 |
| Kenrith, the Returned King (real) | 52.0% | 26 | 24 | 0 | 11.8 | elimination=26 |
| The Jolly Balloon Man (real) | 40.0% | 20 | 29 | 1 | 11.8 | elimination=20 |

**Overall WR: 40.2%** (241W/341L/18S)

## [2026-06-01T23:38:11Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=40 R=13 X=7 CMC=3.10 Instants=9
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 42.0% | 21 | 27 | 2 | 11.7 | elimination=21 |
| Lier, Disciple of the Drowned (real) | 38.0% | 19 | 31 | 0 | 12.0 | elimination=19 |
| Aragorn, King of Gondor (real) | 36.0% | 18 | 29 | 3 | 11.6 | elimination=18 |
| Tasigur, the Golden Fang (real) | 42.0% | 21 | 28 | 1 | 11.7 | elimination=21 |
| Cloud, Midgar Mercenary (real) | 36.0% | 18 | 31 | 1 | 12.1 | elimination=18 |
| Deadpool, Trading Card (real) | 40.0% | 20 | 26 | 4 | 12.1 | elimination=20 |
|  (real) | 44.0% | 22 | 26 | 2 | 12.4 | elimination=22 |
| Malcolm, Keen-Eyed Navigator (real) | 34.0% | 17 | 31 | 2 | 12.2 | elimination=17 |
| Slimefoot and Squee (real) | 40.0% | 20 | 28 | 2 | 11.7 | elimination=20 |
| Rograkh, Son of Rohgahh (real) | 38.0% | 19 | 31 | 0 | 12.5 | elimination=19 |
| Kenrith, the Returned King (real) | 52.0% | 26 | 24 | 0 | 11.8 | elimination=26 |
| The Jolly Balloon Man (real) | 40.0% | 20 | 29 | 1 | 11.8 | elimination=20 |

**Overall WR: 40.2%** (241W/341L/18S)

## [2026-06-01T23:40:37Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=17 R=0 X=0 CMC=0.00 Instants=2
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 0.0% | 0 | 40 | 10 | 0.0 |  |
| Lier, Disciple of the Drowned (real) | 0.0% | 0 | 33 | 17 | 0.0 |  |
| Aragorn, King of Gondor (real) | 0.0% | 0 | 33 | 17 | 0.0 |  |
| Tasigur, the Golden Fang (real) | 0.0% | 0 | 41 | 9 | 0.0 |  |
| Cloud, Midgar Mercenary (real) | 0.0% | 0 | 35 | 15 | 0.0 |  |
| Deadpool, Trading Card (real) | 0.0% | 0 | 35 | 15 | 0.0 |  |
|  (real) | 0.0% | 0 | 40 | 10 | 0.0 |  |
| Malcolm, Keen-Eyed Navigator (real) | 0.0% | 0 | 39 | 11 | 0.0 |  |
| Slimefoot and Squee (real) | 0.0% | 0 | 36 | 14 | 0.0 |  |
| Rograkh, Son of Rohgahh (real) | 0.0% | 0 | 35 | 15 | 0.0 |  |
| Kenrith, the Returned King (real) | 0.0% | 0 | 35 | 15 | 0.0 |  |
| The Jolly Balloon Man (real) | 0.0% | 0 | 37 | 13 | 0.0 |  |

**Overall WR: 0.0%** (0W/439L/161S)

## [2026-06-01T23:41:17Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=28 R=13 X=6 CMC=3.39 Instants=2
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 26.0% | 13 | 35 | 2 | 11.2 | elimination=13 |
| Lier, Disciple of the Drowned (real) | 16.0% | 8 | 38 | 4 | 11.5 | elimination=8 |
| Aragorn, King of Gondor (real) | 16.0% | 8 | 36 | 6 | 11.1 | elimination=8 |
| Tasigur, the Golden Fang (real) | 18.0% | 9 | 40 | 1 | 11.7 | elimination=9 |
| Cloud, Midgar Mercenary (real) | 12.0% | 6 | 38 | 6 | 11.0 | elimination=6 |
| Deadpool, Trading Card (real) | 18.0% | 9 | 38 | 3 | 11.2 | elimination=9 |
|  (real) | 16.0% | 8 | 36 | 6 | 11.6 | elimination=8 |
| Malcolm, Keen-Eyed Navigator (real) | 20.0% | 10 | 36 | 4 | 11.3 | elimination=10 |
| Slimefoot and Squee (real) | 22.0% | 11 | 33 | 6 | 11.1 | elimination=11 |
| Rograkh, Son of Rohgahh (real) | 16.0% | 8 | 35 | 7 | 11.8 | elimination=8 |
| Kenrith, the Returned King (real) | 26.0% | 13 | 32 | 5 | 11.1 | elimination=13 |
| The Jolly Balloon Man (real) | 26.0% | 13 | 35 | 2 | 11.6 | elimination=13 |

**Overall WR: 19.3%** (116W/432L/52S)

## [2026-06-02T07:45:19Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=28 R=16 X=2 CMC=3.29 Instants=4
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 12.0% | 6 | 39 | 5 | 14.0 | elimination=6 |
| Lier, Disciple of the Drowned (real) | 6.0% | 3 | 41 | 6 | 13.0 | elimination=3 |
| Aragorn, King of Gondor (real) | 8.0% | 4 | 40 | 6 | 13.0 | elimination=4 |
| Tasigur, the Golden Fang (real) | 12.0% | 6 | 39 | 5 | 11.3 | elimination=6 |
| Cloud, Midgar Mercenary (real) | 8.0% | 4 | 43 | 3 | 14.2 | elimination=4 |
| Deadpool, Trading Card (real) | 12.0% | 6 | 40 | 4 | 12.5 | elimination=6 |
|  (real) | 2.0% | 1 | 42 | 7 | 12.0 | elimination=1 |
| Malcolm, Keen-Eyed Navigator (real) | 8.0% | 4 | 42 | 4 | 14.0 | elimination=4 |
| Slimefoot and Squee (real) | 8.0% | 4 | 42 | 4 | 15.2 | elimination=4 |
| Rograkh, Son of Rohgahh (real) | 6.0% | 3 | 41 | 6 | 17.7 | elimination=3 |
| Kenrith, the Returned King (real) | 20.0% | 10 | 35 | 5 | 13.9 | elimination=10 |
| The Jolly Balloon Man (real) | 0.0% | 0 | 45 | 5 | 0.0 |  |

**Overall WR: 8.5%** (51W/489L/60S)

## [2026-06-02T07:49:19Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=28 R=16 X=2 CMC=3.29 Instants=4
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 34.0% | 17 | 26 | 7 | 13.8 | elimination=17 |
| Lier, Disciple of the Drowned (real) | 42.0% | 21 | 27 | 2 | 15.6 | elimination=21 |
| Aragorn, King of Gondor (real) | 30.0% | 15 | 29 | 6 | 15.1 | elimination=15 |
| Tasigur, the Golden Fang (real) | 48.0% | 24 | 22 | 4 | 15.8 | elimination=24 |
| Cloud, Midgar Mercenary (real) | 32.0% | 16 | 28 | 6 | 15.6 | elimination=16 |
| Deadpool, Trading Card (real) | 46.0% | 23 | 24 | 3 | 15.1 | elimination=23 |
|  (real) | 42.0% | 21 | 23 | 6 | 16.5 | elimination=21 |
| Malcolm, Keen-Eyed Navigator (real) | 40.0% | 20 | 26 | 4 | 15.2 | elimination=20 |
| Slimefoot and Squee (real) | 44.0% | 22 | 23 | 5 | 15.8 | elimination=22 |
| Rograkh, Son of Rohgahh (real) | 48.0% | 24 | 24 | 2 | 15.5 | elimination=24 |
| Kenrith, the Returned King (real) | 44.0% | 22 | 21 | 7 | 15.5 | elimination=22 |
| The Jolly Balloon Man (real) | 36.0% | 18 | 29 | 3 | 14.5 | elimination=18 |

**Overall WR: 40.5%** (243W/302L/55S)

## [2026-06-02T07:51:46Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=27 R=13 X=5 CMC=3.24 Instants=7
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 38.0% | 19 | 29 | 2 | 17.3 | elimination=19 |
| Lier, Disciple of the Drowned (real) | 48.0% | 24 | 25 | 1 | 16.3 | elimination=24 |
| Aragorn, King of Gondor (real) | 52.0% | 26 | 19 | 5 | 15.7 | elimination=26 |
| Tasigur, the Golden Fang (real) | 30.0% | 15 | 29 | 6 | 14.8 | elimination=15 |
| Cloud, Midgar Mercenary (real) | 44.0% | 22 | 27 | 1 | 15.5 | elimination=22 |
| Deadpool, Trading Card (real) | 30.0% | 15 | 28 | 7 | 15.1 | elimination=15 |
|  (real) | 36.0% | 18 | 30 | 2 | 16.5 | elimination=18 |
| Malcolm, Keen-Eyed Navigator (real) | 42.0% | 21 | 23 | 6 | 16.8 | elimination=21 |
| Slimefoot and Squee (real) | 38.0% | 19 | 25 | 6 | 16.0 | elimination=19 |
| Rograkh, Son of Rohgahh (real) | 28.0% | 14 | 26 | 10 | 16.5 | elimination=14 |
| Kenrith, the Returned King (real) | 44.0% | 22 | 25 | 3 | 16.0 | elimination=22 |
| The Jolly Balloon Man (real) | 42.0% | 21 | 27 | 2 | 15.3 | elimination=21 |

**Overall WR: 39.3%** (236W/313L/51S)

## [2026-06-02T07:53:30Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=35 R=13 X=5 CMC=3.29 Instants=7
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 50.0% | 25 | 21 | 4 | 16.2 | elimination=25 |
| Lier, Disciple of the Drowned (real) | 52.0% | 26 | 23 | 1 | 16.8 | elimination=26 |
| Aragorn, King of Gondor (real) | 40.0% | 20 | 28 | 2 | 17.6 | elimination=20 |
| Tasigur, the Golden Fang (real) | 50.0% | 25 | 22 | 3 | 16.3 | elimination=25 |
| Cloud, Midgar Mercenary (real) | 58.0% | 29 | 21 | 0 | 16.9 | elimination=29 |
| Deadpool, Trading Card (real) | 50.0% | 25 | 19 | 6 | 16.6 | elimination=25 |
|  (real) | 50.0% | 25 | 24 | 1 | 17.6 | elimination=25 |
| Malcolm, Keen-Eyed Navigator (real) | 38.0% | 19 | 29 | 2 | 16.3 | elimination=19 |
| Slimefoot and Squee (real) | 38.0% | 19 | 28 | 3 | 17.1 | elimination=19 |
| Rograkh, Son of Rohgahh (real) | 48.0% | 24 | 23 | 3 | 16.1 | elimination=24 |
| Kenrith, the Returned King (real) | 46.0% | 23 | 25 | 2 | 16.3 | elimination=23 |
| The Jolly Balloon Man (real) | 40.0% | 20 | 28 | 2 | 18.0 | elimination=20 |

**Overall WR: 46.7%** (280W/291L/29S)

## [2026-06-02T07:56:27Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=49 R=14 X=5 CMC=2.22 Instants=8
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 0.0% | 0 | 49 | 1 | 0.0 |  |
| Lier, Disciple of the Drowned (real) | 0.0% | 0 | 49 | 1 | 0.0 |  |
| Aragorn, King of Gondor (real) | 0.0% | 0 | 50 | 0 | 0.0 |  |
| Tasigur, the Golden Fang (real) | 0.0% | 0 | 50 | 0 | 0.0 |  |
| Cloud, Midgar Mercenary (real) | 0.0% | 0 | 50 | 0 | 0.0 |  |
| Deadpool, Trading Card (real) | 0.0% | 0 | 50 | 0 | 0.0 |  |
|  (real) | 0.0% | 0 | 50 | 0 | 0.0 |  |
| Malcolm, Keen-Eyed Navigator (real) | 0.0% | 0 | 50 | 0 | 0.0 |  |
| Slimefoot and Squee (real) | 0.0% | 0 | 50 | 0 | 0.0 |  |
| Rograkh, Son of Rohgahh (real) | 0.0% | 0 | 50 | 0 | 0.0 |  |
| Kenrith, the Returned King (real) | 0.0% | 0 | 49 | 1 | 0.0 |  |
| The Jolly Balloon Man (real) | 0.0% | 0 | 50 | 0 | 0.0 |  |

**Overall WR: 0.0%** (0W/597L/3S)

## [2026-06-02T09:46:41Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=49 R=14 X=5 CMC=2.22 Instants=8
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 0.0% | 0 | 49 | 1 | 0.0 |  |
| Lier, Disciple of the Drowned (real) | 0.0% | 0 | 49 | 1 | 0.0 |  |
| Aragorn, King of Gondor (real) | 0.0% | 0 | 50 | 0 | 0.0 |  |
| Tasigur, the Golden Fang (real) | 0.0% | 0 | 50 | 0 | 0.0 |  |
| Cloud, Midgar Mercenary (real) | 0.0% | 0 | 50 | 0 | 0.0 |  |
| Deadpool, Trading Card (real) | 0.0% | 0 | 50 | 0 | 0.0 |  |
|  (real) | 0.0% | 0 | 50 | 0 | 0.0 |  |
| Malcolm, Keen-Eyed Navigator (real) | 0.0% | 0 | 50 | 0 | 0.0 |  |
| Slimefoot and Squee (real) | 0.0% | 0 | 50 | 0 | 0.0 |  |
| Rograkh, Son of Rohgahh (real) | 0.0% | 0 | 50 | 0 | 0.0 |  |
| Kenrith, the Returned King (real) | 0.0% | 0 | 49 | 1 | 0.0 |  |
| The Jolly Balloon Man (real) | 0.0% | 0 | 50 | 0 | 0.0 |  |

**Overall WR: 0.0%** (0W/597L/3S)

## [2026-06-02T09:48:51Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=44 R=15 X=5 CMC=2.19 Instants=8
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 0.0% | 0 | 47 | 3 | 0.0 |  |
| Lier, Disciple of the Drowned (real) | 0.0% | 0 | 48 | 2 | 0.0 |  |
| Aragorn, King of Gondor (real) | 0.0% | 0 | 49 | 1 | 0.0 |  |
| Tasigur, the Golden Fang (real) | 0.0% | 0 | 49 | 1 | 0.0 |  |
| Cloud, Midgar Mercenary (real) | 0.0% | 0 | 50 | 0 | 0.0 |  |
| Deadpool, Trading Card (real) | 0.0% | 0 | 49 | 1 | 0.0 |  |
|  (real) | 0.0% | 0 | 48 | 2 | 0.0 |  |
| Malcolm, Keen-Eyed Navigator (real) | 0.0% | 0 | 48 | 2 | 0.0 |  |
| Slimefoot and Squee (real) | 0.0% | 0 | 48 | 2 | 0.0 |  |
| Rograkh, Son of Rohgahh (real) | 0.0% | 0 | 48 | 2 | 0.0 |  |
| Kenrith, the Returned King (real) | 0.0% | 0 | 50 | 0 | 0.0 |  |
| The Jolly Balloon Man (real) | 0.0% | 0 | 49 | 1 | 0.0 |  |

**Overall WR: 0.0%** (0W/583L/17S)

## [2026-06-02T22:40:18Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=0 R=19 X=4 CMC=2.88 Instants=7
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 0.0% | 0 | 0 | 50 | 0.0 |  |
| Lier, Disciple of the Drowned (real) | 0.0% | 0 | 0 | 50 | 0.0 |  |
| Aragorn, King of Gondor (real) | 0.0% | 0 | 0 | 50 | 0.0 |  |
| Tasigur, the Golden Fang (real) | 0.0% | 0 | 0 | 50 | 0.0 |  |
| Cloud, Midgar Mercenary (real) | 0.0% | 0 | 0 | 50 | 0.0 |  |
| Deadpool, Trading Card (real) | 0.0% | 0 | 0 | 50 | 0.0 |  |
|  (real) | 0.0% | 0 | 0 | 50 | 0.0 |  |
| Malcolm, Keen-Eyed Navigator (real) | 0.0% | 0 | 0 | 50 | 0.0 |  |
| Slimefoot and Squee (real) | 0.0% | 0 | 0 | 50 | 0.0 |  |
| Rograkh, Son of Rohgahh (real) | 0.0% | 0 | 0 | 50 | 0.0 |  |
| Kenrith, the Returned King (real) | 0.0% | 0 | 0 | 50 | 0.0 |  |
| The Jolly Balloon Man (real) | 0.0% | 0 | 0 | 50 | 0.0 |  |

**Overall WR: 0.0%** (0W/0L/600S)

## [2026-06-02T22:40:53Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=31 R=19 X=4 CMC=2.82 Instants=7
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 60.0% | 30 | 14 | 6 | 9.2 | approach=28, elimination=2 |
| Lier, Disciple of the Drowned (real) | 72.0% | 36 | 11 | 3 | 9.4 | approach=34, elimination=2 |
| Aragorn, King of Gondor (real) | 80.0% | 40 | 8 | 2 | 9.1 | approach=39, elimination=1 |
| Tasigur, the Golden Fang (real) | 72.0% | 36 | 10 | 4 | 9.8 | approach=29, elimination=7 |
| Cloud, Midgar Mercenary (real) | 84.0% | 42 | 4 | 4 | 9.4 | approach=36, elimination=6 |
| Deadpool, Trading Card (real) | 80.0% | 40 | 8 | 2 | 9.4 | approach=33, elimination=7 |
|  (real) | 68.0% | 34 | 11 | 5 | 10.3 | approach=29, elimination=5 |
| Malcolm, Keen-Eyed Navigator (real) | 76.0% | 38 | 9 | 3 | 10.6 | elimination=13, approach=25 |
| Slimefoot and Squee (real) | 76.0% | 38 | 8 | 4 | 10.2 | approach=33, elimination=5 |
| Rograkh, Son of Rohgahh (real) | 76.0% | 38 | 10 | 2 | 9.9 | approach=35, elimination=3 |
| Kenrith, the Returned King (real) | 72.0% | 36 | 11 | 3 | 10.0 | approach=31, elimination=5 |
| The Jolly Balloon Man (real) | 80.0% | 40 | 5 | 5 | 9.1 | approach=36, elimination=4 |

**Overall WR: 74.7%** (448W/109L/43S)

## [2026-06-02T22:48:43Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=33 R=19 X=4 CMC=2.88 Instants=15
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 70.0% | 35 | 11 | 4 | 9.1 | approach=34, elimination=1 |
| Lier, Disciple of the Drowned (real) | 68.0% | 34 | 11 | 5 | 9.8 | elimination=5, approach=29 |
| Aragorn, King of Gondor (real) | 72.0% | 36 | 12 | 2 | 8.9 | approach=33, elimination=3 |
| Tasigur, the Golden Fang (real) | 58.0% | 29 | 19 | 2 | 9.6 | approach=23, elimination=6 |
| Cloud, Midgar Mercenary (real) | 78.0% | 39 | 10 | 1 | 9.5 | approach=36, elimination=3 |
| Deadpool, Trading Card (real) | 72.0% | 36 | 12 | 2 | 9.4 | approach=32, elimination=4 |
|  (real) | 66.0% | 33 | 12 | 5 | 8.9 | approach=32, elimination=1 |
| Malcolm, Keen-Eyed Navigator (real) | 72.0% | 36 | 11 | 3 | 9.7 | approach=30, elimination=6 |
| Slimefoot and Squee (real) | 68.0% | 34 | 13 | 3 | 9.4 | approach=31, elimination=3 |
| Rograkh, Son of Rohgahh (real) | 74.0% | 37 | 12 | 1 | 10.3 | approach=32, elimination=5 |
| Kenrith, the Returned King (real) | 80.0% | 40 | 8 | 2 | 9.5 | approach=36, elimination=4 |
| The Jolly Balloon Man (real) | 82.0% | 41 | 9 | 0 | 8.9 | approach=39, elimination=2 |

**Overall WR: 71.7%** (430W/140L/30S)

## [2026-06-02T23:19:45Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=33 R=19 X=4 CMC=2.88 Instants=15
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 70.0% | 35 | 11 | 4 | 9.1 | approach=34, elimination=1 |
| Lier, Disciple of the Drowned (real) | 68.0% | 34 | 11 | 5 | 9.8 | elimination=5, approach=29 |
| Aragorn, King of Gondor (real) | 72.0% | 36 | 12 | 2 | 8.9 | approach=33, elimination=3 |
| Tasigur, the Golden Fang (real) | 58.0% | 29 | 19 | 2 | 9.6 | approach=23, elimination=6 |
| Cloud, Midgar Mercenary (real) | 78.0% | 39 | 10 | 1 | 9.5 | approach=36, elimination=3 |
| Deadpool, Trading Card (real) | 72.0% | 36 | 12 | 2 | 9.4 | approach=32, elimination=4 |
|  (real) | 66.0% | 33 | 12 | 5 | 8.9 | approach=32, elimination=1 |
| Malcolm, Keen-Eyed Navigator (real) | 72.0% | 36 | 11 | 3 | 9.7 | approach=30, elimination=6 |
| Slimefoot and Squee (real) | 68.0% | 34 | 13 | 3 | 9.4 | approach=31, elimination=3 |
| Rograkh, Son of Rohgahh (real) | 74.0% | 37 | 12 | 1 | 10.3 | approach=32, elimination=5 |
| Kenrith, the Returned King (real) | 80.0% | 40 | 8 | 2 | 9.5 | approach=36, elimination=4 |
| The Jolly Balloon Man (real) | 82.0% | 41 | 9 | 0 | 8.9 | approach=39, elimination=2 |

**Overall WR: 71.7%** (430W/140L/30S)

## [2026-06-02T23:27:34Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=33 R=19 X=4 CMC=2.88 Instants=15
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 70.0% | 35 | 11 | 4 | 9.1 | approach=34, elimination=1 |
| Lier, Disciple of the Drowned (real) | 68.0% | 34 | 11 | 5 | 9.8 | elimination=5, approach=29 |
| Aragorn, King of Gondor (real) | 72.0% | 36 | 12 | 2 | 8.9 | approach=33, elimination=3 |
| Tasigur, the Golden Fang (real) | 58.0% | 29 | 19 | 2 | 9.6 | approach=23, elimination=6 |
| Cloud, Midgar Mercenary (real) | 78.0% | 39 | 10 | 1 | 9.5 | approach=36, elimination=3 |
| Deadpool, Trading Card (real) | 72.0% | 36 | 12 | 2 | 9.4 | approach=32, elimination=4 |
|  (real) | 66.0% | 33 | 12 | 5 | 8.9 | approach=32, elimination=1 |
| Malcolm, Keen-Eyed Navigator (real) | 72.0% | 36 | 11 | 3 | 9.7 | approach=30, elimination=6 |
| Slimefoot and Squee (real) | 68.0% | 34 | 13 | 3 | 9.4 | approach=31, elimination=3 |
| Rograkh, Son of Rohgahh (real) | 74.0% | 37 | 12 | 1 | 10.3 | approach=32, elimination=5 |
| Kenrith, the Returned King (real) | 80.0% | 40 | 8 | 2 | 9.5 | approach=36, elimination=4 |
| The Jolly Balloon Man (real) | 82.0% | 41 | 9 | 0 | 8.9 | approach=39, elimination=2 |

**Overall WR: 71.7%** (430W/140L/30S)

## [2026-06-03T09:47:09Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=33 R=19 X=4 CMC=2.88 Instants=15
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 72.0% | 36 | 11 | 3 | 8.6 | approach=36 |
| Lier, Disciple of the Drowned (real) | 64.0% | 32 | 13 | 5 | 9.3 | approach=30, elimination=2 |
| Aragorn, King of Gondor (real) | 80.0% | 40 | 7 | 3 | 8.6 | approach=39, elimination=1 |
| Tasigur, the Golden Fang (real) | 60.0% | 30 | 16 | 4 | 9.1 | approach=26, elimination=4 |
| Cloud, Midgar Mercenary (real) | 84.0% | 42 | 3 | 5 | 9.5 | approach=35, elimination=7 |
| Deadpool, Trading Card (real) | 68.0% | 34 | 11 | 5 | 9.0 | approach=31, elimination=3 |
|  (real) | 74.0% | 37 | 8 | 5 | 9.6 | approach=33, elimination=4 |
| Malcolm, Keen-Eyed Navigator (real) | 74.0% | 37 | 10 | 3 | 10.2 | elimination=6, approach=31 |
| Slimefoot and Squee (real) | 80.0% | 40 | 8 | 2 | 10.2 | elimination=9, approach=31 |
| Rograkh, Son of Rohgahh (real) | 66.0% | 33 | 11 | 6 | 8.8 | approach=33 |
| Kenrith, the Returned King (real) | 78.0% | 39 | 10 | 1 | 9.5 | approach=35, elimination=4 |
| The Jolly Balloon Man (real) | 84.0% | 42 | 6 | 2 | 9.1 | approach=37, elimination=5 |

**Overall WR: 73.7%** (442W/114L/44S)

## [2026-06-05T22:06:30Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=33 R=19 X=4 CMC=2.88 Instants=14
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 68.0% | 34 | 11 | 5 | 9.3 | approach=30, elimination=4 |
| Lier, Disciple of the Drowned (real) | 66.0% | 33 | 15 | 2 | 8.8 | approach=33 |
| Aragorn, King of Gondor (real) | 84.0% | 42 | 6 | 2 | 9.5 | approach=38, elimination=4 |
| Tasigur, the Golden Fang (real) | 74.0% | 37 | 9 | 4 | 9.3 | approach=35, elimination=2 |
| Cloud, Midgar Mercenary (real) | 90.0% | 45 | 4 | 1 | 9.3 | approach=39, elimination=6 |
| Deadpool, Trading Card (real) | 82.0% | 41 | 5 | 4 | 9.7 | approach=36, elimination=5 |
|  (real) | 66.0% | 33 | 10 | 7 | 9.3 | approach=27, elimination=6 |
| Malcolm, Keen-Eyed Navigator (real) | 82.0% | 41 | 8 | 1 | 9.5 | approach=34, elimination=7 |
| Slimefoot and Squee (real) | 80.0% | 40 | 6 | 4 | 8.8 | approach=38, elimination=2 |
| Rograkh, Son of Rohgahh (real) | 86.0% | 43 | 6 | 1 | 9.3 | approach=40, elimination=3 |
| Kenrith, the Returned King (real) | 84.0% | 42 | 4 | 4 | 9.0 | approach=40, elimination=2 |
| The Jolly Balloon Man (real) | 70.0% | 35 | 12 | 3 | 9.1 | elimination=3, approach=32 |

**Overall WR: 77.7%** (466W/96L/38S)

## [2026-06-05T22:14:33Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=33 R=19 X=4 CMC=2.87 Instants=13
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 76.0% | 38 | 11 | 1 | 9.4 | approach=33, elimination=5 |
| Lier, Disciple of the Drowned (real) | 78.0% | 39 | 8 | 3 | 9.4 | elimination=4, approach=35 |
| Aragorn, King of Gondor (real) | 84.0% | 42 | 7 | 1 | 9.3 | approach=40, elimination=2 |
| Tasigur, the Golden Fang (real) | 82.0% | 41 | 8 | 1 | 9.1 | approach=36, elimination=5 |
| Cloud, Midgar Mercenary (real) | 70.0% | 35 | 14 | 1 | 9.6 | approach=32, elimination=3 |
| Deadpool, Trading Card (real) | 68.0% | 34 | 12 | 4 | 9.7 | approach=31, elimination=3 |
|  (real) | 74.0% | 37 | 10 | 3 | 9.2 | approach=35, elimination=2 |
| Malcolm, Keen-Eyed Navigator (real) | 68.0% | 34 | 15 | 1 | 9.6 | approach=31, elimination=3 |
| Slimefoot and Squee (real) | 72.0% | 36 | 12 | 2 | 9.2 | approach=34, elimination=2 |
| Rograkh, Son of Rohgahh (real) | 74.0% | 37 | 10 | 3 | 9.8 | approach=34, elimination=3 |
| Kenrith, the Returned King (real) | 82.0% | 41 | 7 | 2 | 8.7 | approach=37, elimination=4 |
| The Jolly Balloon Man (real) | 80.0% | 40 | 9 | 1 | 9.0 | approach=39, elimination=1 |

**Overall WR: 75.7%** (454W/123L/23S)

## [2026-06-05T22:16:27Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=33 R=19 X=4 CMC=2.82 Instants=12
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 78.0% | 39 | 10 | 1 | 8.4 | approach=38, elimination=1 |
| Lier, Disciple of the Drowned (real) | 82.0% | 41 | 4 | 5 | 9.2 | approach=37, elimination=4 |
| Aragorn, King of Gondor (real) | 80.0% | 40 | 6 | 4 | 9.8 | approach=33, elimination=7 |
| Tasigur, the Golden Fang (real) | 72.0% | 36 | 11 | 3 | 9.3 | elimination=4, approach=32 |
| Cloud, Midgar Mercenary (real) | 64.0% | 32 | 13 | 5 | 9.8 | approach=28, elimination=4 |
| Deadpool, Trading Card (real) | 86.0% | 43 | 7 | 0 | 9.1 | approach=40, elimination=3 |
|  (real) | 80.0% | 40 | 8 | 2 | 9.7 | approach=35, elimination=5 |
| Malcolm, Keen-Eyed Navigator (real) | 74.0% | 37 | 11 | 2 | 9.1 | approach=31, elimination=6 |
| Slimefoot and Squee (real) | 74.0% | 37 | 11 | 2 | 9.4 | approach=32, elimination=5 |
| Rograkh, Son of Rohgahh (real) | 78.0% | 39 | 10 | 1 | 10.0 | approach=34, elimination=5 |
| Kenrith, the Returned King (real) | 76.0% | 38 | 12 | 0 | 9.1 | elimination=4, approach=34 |
| The Jolly Balloon Man (real) | 82.0% | 41 | 4 | 5 | 8.9 | approach=38, elimination=3 |

**Overall WR: 77.2%** (463W/107L/30S)

## [2026-06-05T22:24:14Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=33 R=19 X=4 CMC=2.85 Instants=12
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 74.0% | 37 | 10 | 3 | 9.5 | approach=33, elimination=4 |
| Lier, Disciple of the Drowned (real) | 78.0% | 39 | 7 | 4 | 9.1 | elimination=4, approach=35 |
| Aragorn, King of Gondor (real) | 82.0% | 41 | 8 | 1 | 9.6 | elimination=3, approach=38 |
| Tasigur, the Golden Fang (real) | 74.0% | 37 | 10 | 3 | 9.1 | approach=33, elimination=4 |
| Cloud, Midgar Mercenary (real) | 90.0% | 45 | 3 | 2 | 9.6 | approach=38, elimination=7 |
| Deadpool, Trading Card (real) | 74.0% | 37 | 11 | 2 | 8.8 | approach=34, elimination=3 |
|  (real) | 68.0% | 34 | 11 | 5 | 9.5 | approach=29, elimination=5 |
| Malcolm, Keen-Eyed Navigator (real) | 68.0% | 34 | 14 | 2 | 9.1 | approach=29, elimination=5 |
| Slimefoot and Squee (real) | 76.0% | 38 | 7 | 5 | 8.9 | approach=35, elimination=3 |
| Rograkh, Son of Rohgahh (real) | 80.0% | 40 | 8 | 2 | 10.3 | approach=35, elimination=5 |
| Kenrith, the Returned King (real) | 68.0% | 34 | 10 | 6 | 8.4 | approach=32, elimination=2 |
| The Jolly Balloon Man (real) | 72.0% | 36 | 10 | 4 | 8.5 | approach=33, elimination=3 |

**Overall WR: 75.3%** (452W/109L/39S)

## [2026-06-05T22:59:35Z] Battle Analyst v8 — Interactive Commander
Games: 50 4-player | Deck: L=33 R=19 X=4 CMC=2.82 Instants=20
Opponents: 12 (real)

| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |
|:---------|----:|-----:|-------:|-------:|------:|:--------|
| Derevi, Empyrial Tactician (real) | 66.0% | 33 | 13 | 4 | 9.2 | approach=29, elimination=4 |
| Lier, Disciple of the Drowned (real) | 62.0% | 31 | 16 | 3 | 9.2 | approach=27, elimination=4 |
| Aragorn, King of Gondor (real) | 62.0% | 31 | 18 | 1 | 9.2 | elimination=3, approach=28 |
| Tasigur, the Golden Fang (real) | 64.0% | 32 | 16 | 2 | 8.4 | approach=31, elimination=1 |
| Cloud, Midgar Mercenary (real) | 66.0% | 33 | 15 | 2 | 9.8 | approach=31, elimination=2 |
| Deadpool, Trading Card (real) | 72.0% | 36 | 12 | 2 | 9.3 | approach=34, elimination=2 |
|  (real) | 68.0% | 34 | 14 | 2 | 9.9 | approach=31, elimination=3 |
| Malcolm, Keen-Eyed Navigator (real) | 80.0% | 40 | 9 | 1 | 9.0 | elimination=2, approach=38 |
| Slimefoot and Squee (real) | 66.0% | 33 | 14 | 3 | 10.1 | elimination=5, approach=28 |
| Rograkh, Son of Rohgahh (real) | 76.0% | 38 | 9 | 3 | 9.4 | approach=37, elimination=1 |
| Kenrith, the Returned King (real) | 76.0% | 38 | 12 | 0 | 9.2 | approach=36, elimination=2 |
| The Jolly Balloon Man (real) | 78.0% | 39 | 10 | 1 | 9.8 | approach=34, elimination=5 |

**Overall WR: 69.7%** (418W/158L/24S)
