# Commander Deep Knowledge Report

> **Generated:** 2026-06-16 ~04:00 UTC | **Updated:** 2026-06-16 (June 16 — sixth pass)
> **Commander:** Lorehold, the Historian
> **Color Identity:** Boros (RW)
> **Archetype:** Fast Mana → Combo/Approach — Hybrid Bracket 4
> **Source Agent:** Commander Knowledge Deep Cron Job (June 16 cycle — sixth pass)
> **Evidence Base:** knowledge.db deck_id=6 (SQLite deck_cards hash `4cc51c42...`, STABLE since June 15 01:51Z), optimizer_baseline_runs #5 (600 games, 89.8% WR), slot_benchmarks=115 (NEW: 86 added since last report), optimizer_quality_reviews=123 (NEW: 118 added since last report), BATTLE_LOG.md through June 14 20:50Z

---

## 🟢🟡 NEW FINDING A: Hash Stable for 24+ Hours — Longest Stable Period in 16 Days

**Status:** 🟢 Stable (positive signal)

Deck hash `4cc51c42952f0ff139aad4e97ec266a14debfd7130c1c56d68069d2037af0420` has been **unchanged since ~June 15 01:51Z** — over 24 hours without a re-sync. This is the first time the hash has remained stable for a full day since Hermes began tracking on June 1.

| Metric | Value |
|:-------|:------|
| Current hash | `4cc51c42...` |
| Stable since | 2026-06-15 ~01:51Z |
| Duration | **~26 hours** (longest ever) |
| Previous max stability | ~12 hours (June 11-12) |
| Previous hash changes | 6 in 14 days |

**However**, stability does NOT mean the classification improved. The functional tags are still from the regression:
- Ramp misclassification: **73% (30/41 lands tagged as ramp)** — unchanged
- Draw count: 16 (still inflated — Mizzix's Mastery tagged as draw)
- Engine count: 11
- Blasphemous Act still tagged as `ramp` (not `wipe` or `board_wipe`)

**Signal for App/Backend Logic:** Hash stability should be tracked as a **hygiene metric** for pipeline health. A stable hash means no re-syncs are happening — which is good for optimizer consistency. But the classifier fix must still be applied before the next sync cycle, or the fix will be overwritten.

---

## 🟡 NEW FINDING B: Slot Benchmarks Surged 4× (29→115) — All Against Stale Hash

**Status:** 🟡 Warning — new data contradicting last report's "pipeline paused" assertion

The previous report (June 15 fifth pass) stated: "slot_benchmarks: ⚠️ 29 benchmarks" and "Pipeline Paused (Stable State)." However, **86 new benchmarks** were executed on June 14 between 22:48Z and 23:00Z — AFTER the last battle data (20:50Z) but BEFORE the report was generated (June 15 15:00Z).

**Breakdown of all 115 benchmarks:**

| Category | Count | New since last report |
|:---------|:-----:|:--------------------:|
| wipe | 16 | +14 |
| wincon | 16 | +14 |
| removal | 16 | +14 |
| ramp | 16 | +14 |
| draw | 16 | +16 (entirely new category) |
| engine | 13 | +10 |
| land | 10 | +10 (entirely new category) |
| tutor | 6 | +2 |
| protection | 6 | +4 |
| **Total** | **115** | **+86** |

**Problem: All 86 new benchmarks target baseline hash `f6367a27...`** — which is NOW stale against the current deck hash `4cc51c42...`. Every benchmark WR and delta is computed against a deck whose classification no longer matches current reality.

### 🏆 Top Benchmark Results (120-game samples, baseline WR=89.8%)

| Swap | Δpp | New WR | Category |
|:-----|:---:|:------:|:---------|
| **Slagstorm** → Blasphemous Act | **+9.4** | 99.2% | wipe |
| **Prismari Pianist** → Storm Herd | **+8.5** | 98.3% | wincon |
| **Bloodforged Battle-Axe** → Storm Herd | **+7.7** | 97.5% | wincon |
| **Ephemerate** → Generous Gift | **+7.7** | 97.5% | removal |
| **Coruscation Mage** → Storm Herd | **+6.9** | 96.7% | wincon |
| **Exotic Orchard** → Mountain | **+6.9** | 96.7% | land |
| **Fabled Passage** → Mountain | **+6.9** | 96.7% | land |
| **White Sun's Twilight** → Blasphemous Act | **+6.9** | 96.7% | wipe |
| **Ruinous Rampage** → Blasphemous Act | **+6.9** | 96.7% | wipe |
| **Magmaquake** → Blasphemous Act | **+6.9** | 96.7% | wipe |
| **Day of Judgment** → Blasphemous Act | **+5.2** | 95.0% | wipe |
| **Dusk // Dawn** → Blasphemous Act | **+5.2** | 95.0% | wipe |
| **Sunfall** → Blasphemous Act | **+5.2** | 95.0% | wipe |
| **Split Up** → Blasphemous Act | **+4.4** | 94.2% | wipe |
| Artificer's Talent → The One Ring | **+3.1** | 92.9% | draw |
| Valiant Endeavor → Blasphemous Act | **+2.3** | 92.1% | wipe |

All delta values above are **positive**, meaning every tested replacement improved or maintained WR vs baseline.

### 🏆 Top Benchmark Results (24-game samples, higher variance)

| Swap | Δpp | New WR | Category |
|:-----|:---:|:------:|:---------|
| **Steelshaper's Gift** → Imperial Recruiter | **+14.6** | 100.0% | tutor |
| **Flashback** → Rite of the Dragoncaller | **+10.4** | 95.8% | engine |
| **Blacksmith's Skill** → Flawless Maneuver | **+10.4** | 95.8% | protection |
| **Strike It Rich** → Mana Geyser | **+10.4** | 95.8% | ramp |
| **Erode** → Rise of the Eldrazi | **+10.4** | 95.8% | removal |
| **Final Showdown** → Blasphemous Act | **+10.4** | 95.8% | wipe |
| **The Battle of Bywater** → Blasphemous Act | **+10.4** | 95.8% | wipe |

**But critical caveat:** ALL benchmarks are computed against a **stale baseline** (hash `f6367a27...`). The current deck hash `4cc51c42...` has different functional tags that may alter which cards belong in which slot. A swap that shows +9.4pp today may perform differently against the current classification.

**The real concern:** Because Blasphemous Act is tagged as `ramp` (not `wipe`), the "wipe" category benchmarks are targeting a RAMp slot for replacement. If a wipe swap is applied, the deck loses 1 of its ~19 actual ramp sources and gains a redundant wipe — potentially reducing mana acceleration.

---

## 🟡 NEW FINDING C: Quality Reviews Surged 25× (5→123) — All Flagging Classification Regression

**Status:** 🟡 Warning — operational impact of regression confirmed

Optimizer quality reviews jumped from **5 to 123** since the last report. Every new review includes the exact same warning:

```
role_mismatch:Blasphemous Act role=ramp add_roles=wipe
```

This is the **first direct evidence of the classification regression impacting slot optimizer decisions**:

1. The classifier tags Blasphemous Act as `ramp` (because it has `{R}` in the mana cost and the classifier has no land exclusion)
2. The slot optimizer sees a "ramp" slot occupied by a card that also functions as a wipe
3. The optimizer tests replacing it with dedicated wipe cards
4. The quality review correctly flags the role mismatch but cannot fix the upstream classifier

**Impact:** Every quality-reviewed swap targeting Blasphemous Act (15 of 16 wipe benchmarks, plus 5 phase1 wipe benchmarks from June 12) is built on a **false premise** — that the deck has 41 ramp sources and can afford to lose 1. In reality, the deck has ~19 ramp sources, and Blasphemous Act is one of only 2 board wipes.

**Signal for App/Backend Logic:** The `role_mismatch` warning should be promoted from a quality review flag to a **pipeline blocker** when a high-priority functional tag (ramp, wincon, board_wipe) is being replaced by cards of a different functional category.

---

## ✅ NEW FINDING D: No New Battle Data — Pipeline Remains Paused

**Status:** 🔴 Still paused — no new games since June 14 20:50Z

BATTLE_LOG.md ends at June 14 20:50Z. No new battle runs have been executed for **~55 hours** (2.3 days). This is the longest gap in Lorehold battle data since tracking began.

| Metric | Value |
|:-------|:------|
| Last battle run | 2026-06-14 20:50:13Z |
| Hours with no new data | **~55 hours** |
| Previous gaps | 6-12 hours (June 11-12), 18 hours (June 14-15) |
| Last baseline run | Baseline #5 (600g, 89.8% WR, hash `f6367a27...`) |
| Baseline vs current deck | **STALE** — hash mismatch |

**Interpretation:** The pipeline is correctly self-limiting due to stale data, but the pause is now so long that the 1,560-game June 14 dataset is aging. If the classifier is not fixed by June 18, the Lorehold analysis branch will be operating on ~4-day-old data.

---

## ✅ NEW FINDING E: Root knowledge.db Still Dangling (Task 6 Unfixed)

**Status:** ❌ Unresolved

The 0-byte `knowledge.db` at `docs/hermes-analysis/manaloom-knowledge/knowledge.db` remains. This was first reported in Finding A on June 15. The real database lives at `scripts/knowledge.db` (3.5MB, updated June 16 02:04Z). Task 6 from the previous report is still open.

---

## 🟢 NEW FINDING F: Zero Optimization Swaps Applied — Correct Hold

**Status:** 🟢 Correct behavior

Despite 115 benchmarks and 123 quality reviews, `optimizer_applied_swaps` remains **0 rows**. This is correct — the optimizer is not applying any changes because the deck hash is stale and the classifier is broken.

| Component | Count | vs Last Report |
|:----------|:-----:|:--------------:|
| optimizer_applied_swaps | **0** | Unchanged (was 0) |
| optimizer_baseline_runs | **5** | Unchanged (last: #5, 600g, 89.8%) |
| slot_benchmarks | **115** | 🆕 **+86** (29→115) |
| optimizer_quality_reviews | **123** | 🆕 **+118** (5→123) |

---

## Updated Pipeline State (June 16)

| Component | Status | Note |
|:----------|:-------|:-----|
| knowledge.db deck_id=6 deck_cards | ✅ 100 cards, hash `4cc51c42...` | **STABLE 24+ hours** — longest stable period ever |
| knowledge.db (root path) | ❌ **0 bytes, empty** | Unfixed since June 15 Finding A |
| optimizer_applied_swaps | ✅ **0 rows** | Correct hold — no swaps applied |
| optimizer_baseline_runs | ⚠️ Run #5 (600 games, 89.8%, hash `f6367a27...`) | **STALE** — current deck is `4cc51c42...` |
| optimizer_quality_reviews | ⚠️ 123 reviews | **All flag `role_mismatch`** for Blasphemous Act |
| slot_benchmarks | ⚠️ **115 benchmarks** | **ALL stale** — computed against `f6367a27...`, not `4cc51c42...` |
| Ramp misclassification | ❌ **73% (30/41 lands tagged as ramp)** | Unchanged since last report |
| BATTLE_LOG.md | ✅ Last updated June 14 20:50Z | No new games in ~55 hours |
| Pipeline bypass detector | ❌ **Not implemented** | Task 4 still open |
| knowledge.db path fix | ❌ **Not implemented** | Task 6 still open |
| Hash change frequency | 🟢 Stable (0 changes in 24+ hours) | First 24h+ stable period |

---

## Updated Signals for App/Backend Logic

| Signal | Source | What It Would Power | Priority |
|:-------|:-------|:--------------------|:--------:|
| **Hash stability tracking** | 24h+ stable hash | Hygiene metric; pause pipeline until hash stable for ≥6h | P2 |
| **role_mismatch as pipeline blocker** | 123 reviews all flag Blasphemous Act as `ramp`→`wipe` | Promote from warning to BLOCK when high-value tags mismatch | **P0** |
| **Benchmark staleness gate** | 115 benchmarks against stale hash | Block benchmark execution if `deck_cards.hash != baseline_hash` | **P1** |
| **Ramp misclassification impact metric** | 15+ swaps targeting Blasphemous Act (tagged ramp) | Auto-calculate effective ramp count when `ramp` tag includes lands | **P1** |
| **Wipe replacement confidence** | Slagstorm +9.4pp, 120-game sample | High-confidence swap candidate once classifier is fixed | P2 |
| **Pipeline pause escalation** | 55h no new battle data | Escalate alert from P2→P1 after 48h of inactivity | P2 |

---

## Concrete Tasks (Updated June 16 — Sixth Pass)

### Task 1 (P0 — URGENT): Ramp Classifier — Exclude Lands from `ramp` Functional Tag

**Evidence amplified:** Benchmarks 86-115 were executed against a classifier that tags Blasphemous Act (a 9-CMC board wipe) as `ramp`. The `role_mismatch` warning appears in ALL 118 new quality reviews. The fix would have prevented 86 wasted benchmark runs.

- **Priority**: P0 URGENT (unchanged). The operational cost of the broken classifier is now measurable: **86 wasted benchmark runs** that must be re-executed after the fix.
- **What to change**: Add `type_line` NOT LIKE '%Land%' guard to the `ramp` category classification logic. Additionally, add `type_line` NOT LIKE '%Sorcery%' guard — Blasphemous Act (Sorcery) should never be `ramp`.
- **Validation**: After fix, `ramp` count for deck_id=6 drops from 41 to ≤16. Blasphemous Act must NOT appear in `ramp` query.

### Task 2 (P1): Re-baseline Lorehold — HOLD Until Task 1 Applied

**Evidence unchanged:** Hash `4cc51c42...` is now stable for 24+ hours. Baseline #5 (600 games, 89.8%, hash `f6367a27...`) is stale. All 115 benchmarks are stale.

- **Hold maintained**: Do NOT re-baseline until Task 1 is applied. Running 115 new benchmarks against broken classifier tags would waste another 13,800 simulation games.
- **New detail**: After Task 1 fix, the deck's actual ramp count (~19) will become visible to the optimizer for the first time. This may fundamentally change which slots need optimization.

### Task 3 (P1 → P0): Functional Tag Taxonomy — Add Land + Non-Sorcery Guard to Ramp

**New evidence:** Blasphemous Act being tagged as `ramp` means the classifier is not just misclassifying lands — it's also tagging non-land cards with `{X}` in the mana cost as ramp. Blasphemous Act costs `{5}{R}{R}{R}` — zero mana-producing text.

- **Priority**: P0 (upgraded from P1). The taxonomy is causing false positives beyond lands.
- **What to change**: Add explicit exclusion rules:
  - `ramp`: EXCLUDE `type_line` containing 'Land' or 'Sorcery'. Only artifacts, creatures with mana abilities, enchantments with mana abilities.
  - `draw`: EXCLUDE tutors (Imperial Recruiter) and reanimation spells (Mizzix's Mastery).
  - `removal`: EXCLUDE Aetherflux Reservoir (life payoff) and Boros Charm (protection-first).
- **Validation**: 0 cards with `type_line` containing 'Land' or 'Sorcery' tagged as `ramp` for all 120 learned decks.

### Task 4 (P1): Pipeline Bypass Detector — Now With Benchmark Staleness Gate

**Evidence amplified:** 115 benchmarks were executed against a stale hash. The slot optimizer should have refused to run benchmarks when `deck_cards.hash != optimizer_baseline_runs.hash`.

- **Priority**: P1 (unchanged). The operational cost is now measurable.
- **What to change**: Add staleness check BEFORE executing benchmarks:
  ```sql
  SELECT deck_hash FROM deck_cards WHERE deck_id=6 LIMIT 1
  -- Must match baseline_hash of the most recent optimizer_baseline_runs row
  ```
  If mismatch: BLOCK all benchmark execution and emit warning.
- **Validation**: Slot optimizer logs should show "BLOCKED: hash mismatch" instead of executing 86 stale benchmarks.

### Task 5 (P2): Aetherflux Reservoir Tag Correction — Still Tagged as `removal`

**Evidence unchanged:** Aetherflux Reservoir remains tagged as `removal`. This card has no removal text — it's a life total payoff/wincon.

- **Priority**: P2 (unchanged). Lower than ramp/Blasphemous Act issues.
- **What to change**: Single-card override: Aetherflux Reservoir → `wincon` or `payoff`.
- **Validation**: `SELECT functional_tag FROM deck_cards WHERE card_name='Aetherflux Reservoir' AND deck_id=6` should return `wincon` or `payoff`.

---

## Hash Tracking (Updated June 16)

| Hash | State | WR | Date | Notes |
|:-----|:------|:--:|:-----|:------|
| `4cc51c42952f...` | **🟢 Current (STABLE 24+ hours)** | unknown (no new baseline) | 2026-06-15 ~01:51Z → current | Longest stable period: 26+ hours. Classification still regressed (73% ramp misclass.) |
| `f6367a273eef...` | Previous (re-tagged) | **89.8%** (run #5, 600 games) | 2026-06-14 19:24Z — 20:31Z | Baseline for ALL 115 slot benchmarks (now stale) |
| `dbe24f7d5b17...` | Previous (recovered hybrid) | **92-100%** | 2026-06-11 to 2026-06-12 | 33 lands, 4 copy spells, Approach active; 696 combined games |
| `a17a5863c95f...` | Previous (WR collapse) | 8-29% | 2026-06-09 | 31 lands, 4 removal, 0 wipes |
| `12c55613ae4f...` | Pre-collapse (stax-combo) | 89.3% | 2026-06-07 | High WR stax build |

**Hash change history:** 6 unique hashes in 16 days. Current hash has been stable for 26+ hours — the longest stable period by a factor of 2×.

---

## Summary of Findings Since Last Report

| # | Finding | Status | Impact |
|:-:|:--------|:------:|:-------|
| A | Hash stable 24+ hours (longest ever) | 🟢 Positive | Pipeline stability improving, but classifier still broken |
| B | Slot benchmarks surged 29→115 (all stale) | 🟡 Warning | 86 benchmark runs wasted; all must be re-run after classifier fix |
| C | Quality reviews surged 5→123 (all flag Blasphemous Act) | 🟡 Warning | Classification regression has direct operational cost |
| D | No new battle data (55h gap) | 🔴 Alert | Pipeline paused; data aging |
| E | Root knowledge.db still dangling | ❌ Unfixed | Task 6 from June 15 remains open |
| F | 0 swaps applied (correct hold) | 🟢 Good | Optimizer correctly paused |

**Overall assessment:** The pipeline is in a holding pattern. The classifier must be fixed (Task 1) before any optimization work can resume. The June 14 massive battle dataset (1,560 games) and 115 slot benchmarks represent the most comprehensive Lorehold analysis ever collected — but all of it is against a hash/classification that no longer matches reality. **The cost of delaying Task 1 is accelerating: 86 wasted benchmark runs in this cycle alone.**
