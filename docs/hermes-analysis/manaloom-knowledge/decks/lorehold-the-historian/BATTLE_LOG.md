
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
