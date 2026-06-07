# Lorehold Hermes Master Optimizer — Handoff Report

**Generated:** Sun Jun  7 14:00:20 2026
**Branch:** codex/hermes-analysis-docs
**Server:** 3.16.217.179 / container d5fe57bf9de2

---

## 1. Baseline Deck

**WR:** 86.0% (258W/10L/32S)

**Stats:** 32 lands, 19 ramp, 4 removal, avg CMC 2.84

**Commander:** Lorehold, the Historian (Miracle {2} to instants/sorceries)

## 2. Slot Scan Results

**Tested:** 160 candidates at 25 games each (isolated swaps)

**Confirmed at 50 games:** 7 | **Rejected:** 1

### Confirmed Improvements

| # | Card In | Card Out | WR | Delta | Category |
|---|---------|----------|-----|-------|----------|
| 1 | Decree of Pain | Blasphemous Act | 91.0% | +5.0pp | wipe ✅ |
| 2 | Academy Manufactor | Mana Geyser | 89.7% | +3.7pp | ramp ✅ |
| 3 | Assassin's Trophy | Mana Geyser | 89.7% | +3.7pp | ramp ✅ |
| 4 | Adrix and Nev, Twincasters // Adrix and Nev, Twincasters | Rise of the Eldrazi | 88.7% | +2.7pp | wincon ✅ |
| 5 | Altar of the Brood | Mana Geyser | 86.7% | +0.7pp | ramp ⬆ |
| 6 | Ankh of Mishra | Mana Geyser | 86.3% | +0.3pp | ramp ⬆ |
| 7 | Damning Verdict | Blasphemous Act | 86.3% | +0.3pp | wipe ⬆ |

### Rejected

- ❌ Agate Instigator (cut Rise of the Eldrazi): 86.0% (+0.0pp)

## 3. Quality Gate

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Cards | 100 | 100 | ✅ |
| Lands | 32 | 33-37 | ⚠️ Low |
| Ramp | 19 | 15-20 | ✅ |
| Draw/Tutor | 14 | 12-16 | ✅ |
| Removal/Wipe | 4 | 6-10 | ⚠️ Low |
| Protection | 10 | 8-12 | ✅ |
| Wincons | 14 | 6-10 | ⚠️ High |
| Avg CMC | 2.84 | 2.0-3.0 | ✅ |
| Bracket | 4 | — | 14 Game Changers |

## 4. Known Issues & Risks

### Battle Simulator
- 🐛 Cleanup/discard to 7 may not work correctly (hands grow, replay-v4 injection replaced turn function)
- 🐛 Swap targets may be stale (cards already cut by previous optimizations)
- ⚠️ Opponent AI not using counters on key threats (Approach, board wipes)
- ⚠️ Card classifications: some counters classified as creatures, ramp as rituals

### Deck
- ⚠️ Only 4 removal/wipe cards — vulnerable to creature-heavy opponents
- ⚠️ 14 wincons — some are CMC 9-10 (too slow)
- ⚠️ 14 Game Changers — bracket 4, some metas restrict to 3
- ✅ Approach of the Second Sun is primary win condition
- ✅ Strong protection package (Silence, Grand Abolisher, Teferi's)

## 5. Recommended Next Tests

1. **Fix swap targets**: re-freeze deck with correct current composition
2. **Rerun slot scan** against corrected swap targets
3. **Test opponent AI fix**: ensure counters target Approach
4. **Add +2 removal** and retest (cut 2 slowest wincons)
5. **Generate working replay**: fix replay-v4 injection to preserve game logic
6. **Full optimizer run**: let 1,856 candidates run overnight against real opponents

## 6. Files

- Baseline freeze: `/opt/data/workspace/mtgia/docs/hermes-analysis/master_optimizer_reports/baseline_freeze.json`
- Phase 2 results: `/opt/data/workspace/mtgia/docs/hermes-analysis/master_optimizer_reports/phase2_confirmation.json`
- Quality gate: `/opt/data/workspace/mtgia/docs/hermes-analysis/master_optimizer_reports/quality_gate.md`
- This report: `/opt/data/workspace/mtgia/docs/hermes-analysis/master_optimizer_reports/handoff_report.md`
- Battle script: `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v8.py`
- Optimizer: `docs/hermes-analysis/manaloom-knowledge/scripts/slot_optimizer.py`
