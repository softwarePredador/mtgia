# Implementation Tasks — Synthesis Cron 2026-06-14 (Run 3)

> **Synthesis run:** 2026-06-14T03:10:00+00:00
> **Sources:** SCOUT_LOG (#29, maturity persistente), VALIDATOR_LOG (v3.23, pipeline integrity crisis), GAME_CHANGERS.md (53 GCs, 24/53 detected previously), THEMES.md (42 themes, 7 validated), STRUCTURE_AUDIT.md (duplicacoes/tabelas/imports revalidados), SQLite knowledge.db (14 tables, no `game_changers` table)
> **Branch:** codex/hermes-analysis-docs
> **HEAD:** 98cabcb4
> **Cross-referenced:** edh_bracket_policy.dart, optimization_functional_roles.dart, optimization_quality_gate.dart, functional_card_tags.dart, optimization_validator.dart, deck_rules_service.dart, optimize_runtime_support.dart
> **Previous runs:** Tasks from 2026-06-13 (P1 x5) remain open — codebase unchanged since 0982403f.
> **Skill(s) not found and skipped:** manaloom-commander-knowledge, manaloom-project-auditor

---

## Summary — NEW tasks this run

| # | Priority | Title | Gap Type |
|:-:|:--------:|:------|:---------|
| 1 | **P1** | Quality gate `_criticalRolesForArchetype` has no test coverage for non-standard archetypes (combo, stax, tribal) | Untested logic |
| 2 | **P2** | `_knownInfiniteComboPieces` only detects 3 of many common deterministic combo pieces | Under-detection |
| 3 | **P2** | `_knownValueEngineNames` only has 5 entries — misses key value-engine game changers | Under-coverage |
| 4 | **P2** | Mystic Remora and Grand Abolisher missing from `officialGameChangerNamesForBracketPolicy` | Incomplete GC detection |
| 5 | **P3** | Heuristic `_looksLikeGameChangerStax` has false-positive risk via broad spell-cast text matching | Heuristic imprecision |

---

### [P1] Test gap: `_criticalRolesForArchetype` and `_looksLikeOffThemeRoleSwap` untested for combo/stax/tribal

**Conhecimento MTG:** Different archetypes have radically different critical roles. Combo decks prioritize tutors, protection, and combo pieces over removal and board wipes. Stax decks prioritize lock pieces over ramp. A quality gate that treats all non-standard archetypes as `{removal, ramp, wipe, wincon}` will incorrectly reject valid archetype-appropriate swaps.

**Evidencia no codigo:** `server/lib/ai/optimization_quality_gate.dart:493-500`:
```
Set<String> _criticalRolesForArchetype(String archetype) {
  return switch (archetype.trim().toLowerCase()) {
    'aggro' => {'creature', 'ramp', 'removal', 'protection', 'wipe', 'wincon'},
    'control' => {'removal', 'draw', 'wipe', 'ramp', 'protection', 'wincon'},
    'midrange' => {'removal', 'ramp', 'draw', 'wipe', 'wincon'},
    _ => {'removal', 'ramp', 'wipe', 'wincon'},  // combo, stax, tribal ALL fall here
  };
}
```

And `_looksLikeOffThemeRoleSwap` (lines 502-529) also lacks cases for combo, stax, tribal.

**Evidencia nos testes:** `server/test/optimization_quality_gate_test.dart` has 13 `archetype:` references, all only testing `'aggro'` (5x), `'control'` (3x), and `'midrange'` (5x). **Zero tests for 'combo', 'stax', 'tribal', or any non-standard archetype.**

Confirmed by grep:
```
$ grep "archetype: '" test/optimization_quality_gate_test.dart | sort | uniq -c
      5 archetype: 'aggro',
      3 archetype: 'control',
      5 archetype: 'midrange',
```

**Gap:** The default fallback assumes combo/stax/tribal need `removal`, `ramp`, `wipe`, and `wincon` as critical roles — but combo needs `tutor` and `protection`, stax needs `stax_piece` and `wincon`, tribal needs `creature` and `tribal_payoff`. A quality gate that blocks swaps losing removal on a combo deck will block valid swaps (removal -> tutor).

**Impacto:** P1 — The quality gate silently applies wrong critical-role logic to ~40%+ of possible archetypes. Combo decks with high tutor density may get their tutor additions rejected because the gate thinks losing `ramp` or `removal` is critical.

**Acao recomendada:**
1. Add `'combo'` case to `_criticalRolesForArchetype` with `{'tutor', 'protection', 'combo_piece', 'wincon', 'ramp'}`
2. Add `'stax'` case with `{'stax', 'wincon', 'protection', 'tutor'}`
3. Add `'tribal'` case with `{'creature', 'ramp', 'removal', 'wincon', 'protection'}`
4. Update `_looksLikeOffThemeRoleSwap` with cases for combo, stax, tribal
5. Add test coverage for all archetype branches

**Validacao:**
```
cd server && dart test test/optimization_quality_gate_test.dart
```
Plus verify that new archetype branches are covered in test assertions.

---

### [P2] `_knownInfiniteComboPieces` only detects 3 of many common deterministic combo pieces

**Conhecimento MTG:** Infinite combos are one of 11 BracketCategory values and have bracket limits (bracket 1: 0, bracket 2: 0, bracket 3: 2, bracket 4: 99). The Commander format has dozens of deterministic infinite combos. Only detecting 3 pieces leaves bracket enforcement with huge blind spots.

**Evidencia no codigo:** `server/lib/edh_bracket_policy.dart:347-351`:
```
const _knownInfiniteComboPieces = <String>{
  'thassa\'s oracle',
  'demonic consultation',
  'tainted pact',
};
```

Only Thoracle + Consult/Tainted Pact combos are detected. Not covered:
- Kiki-Jiki, Mirror Breaker + Pestermite / Restoration Angel / Zealous Conscripts
- Heliod, Sun-Crowned + Walking Ballista
- Devoted Druid + Swift Reconfiguration
- Isochron Scepter + Dramatic Reversal
- Mikaeus, the Unhallowed + Triskelion
- Chain of Smog + Witherbloom Apprentice
- Dualcaster Mage + Twinflame (documentado no VALIDATOR_LOG v3.23 as combo deterministico)

**Gap:** In bracket 2 (infiniteCombo: 0), a deck with Heliod + Ballista or Kiki-Jiki + Pestermite would NOT be detected as having an infinite combo.

**Impacto:** P2 — Bracket policy massively underestimates infinite combo count for bracket validation. Bracket 2 decks are supposed to have "no game changers and no infinite combos" but the system can't detect most combos.

**Acao recomendada:**
1. Expand `_knownInfiniteComboPieces` with curated names of common combo enablers
2. Add test for each new piece to verify tag assignment

**Validacao:**
```dart
final tags = tagCardForBracket(
  name: 'Kiki-Jiki, Mirror Breaker',
  typeLine: 'Legendary Creature - Goblin Shaman',
  oracleText: '{T}: Create a token...',
);
expect(tags.categories, contains(BracketCategory.infiniteCombo));
```

---

### [P2] `_knownValueEngineNames` only has 5 entries — misses key value-engine game changers

**Conhecimento MTG:** GAME_CHANGERS.md categorizes game changers by impact type. The `valueEngine` category describes cards that generate recurring value each turn. Consecrated Sphinx, The One Ring, Smothering Tithe, Field of the Dead are all value engines.

**Evidencia no codigo:** `server/lib/edh_bracket_policy.dart:541-547`:
```
const _knownValueEngineNames = <String>{
  'seedborn muse',
  'tergrid, god of fright',
  'bolas\'s citadel',
  'sensei\'s divining top',
  'aetherflux reservoir',
};
```

Missing entries (all in `officialGameChangerNamesForBracketPolicy`):
- `consecrated sphinx` — draw 2 cards per opponent draw
- `the one ring` — protection + draw each turn
- `smothering tithe` — treasures per opponent draw
- `field of the dead` — zombie per unique land name
- `glacial chasm` — fog every combat phase

**Impacto:** P2 — UX gap: bracket analysis can't tell users which impact axis a GC falls into. Category counters under-report `valueEngine` count.

**Acao recomendada:**
Add missing value-engine GC names to `_knownValueEngineNames`.

**Validacao:**
```bash
cd server && grep -c "consecrated sphinx\|the one ring\|smothering tithe" server/lib/edh_bracket_policy.dart
```

---

### [P2] Mystic Remora and Grand Abolisher missing from GC curated list

**Conhecimento MTG:** Both Mystic Remora (original 36 GC) and Grand Abolisher (added in bracket update) are official game changers per Scryfall `is:gamechanger`.

**Evidencia no codigo:** `server/lib/edh_bracket_policy.dart:354-408` — The set has 53 entries but does NOT include `'mystic remora'` or `'grand abolisher'`. Both ARE partially detected by heuristic paths (cardAdvantage for Mystic Remora, stax for Grand Abolisher) but NEITHER gets the `gameChanger` tag.

```
$ grep -n "mystic remora\|grand abolisher" server/lib/edh_bracket_policy.dart
473:      normalizedName == 'mystic remora' ||   # in _looksLikeGameChangerCardAdvantage, NOT in official list
497:      normalizedName == 'grand abolisher' ||  # in _looksLikeGameChangerStax, NOT in official list
```

**Impacto:** P2 — Both cards can be added in bracket 2 (gameChanger:0) without consuming a slot. In bracket 3, they don't count against the 3-GC limit.

**Acao recomendada:**
Add both names to `officialGameChangerNamesForBracketPolicy`.

**Validacao:**
```dart
final remora = tagCardForBracket(name: 'Mystic Remora', ...);
expect(remora.categories, contains(BracketCategory.gameChanger));
```

---

### [P3] `_looksLikeGameChangerStax` broad text matching may cause false positives

**Conhecimento MTG:** The stax heuristic at `edh_bracket_policy.dart:506-509` matches any card whose oracle text contains both "cast" and "more than one spell". This applies `BracketCategory.stax` to ALL cards matching, including non-GC cards that happen to reference spell-cast restrictions.

**Evidencia no codigo:** Lines 506-509:
```
if (oracleLower.contains('cast') &&
    oracleLower.contains('more than one spell') || ...)
```

This pattern could match non-GC cards that have similar phrasing but aren't stax pieces. In bracket 2 (stax:1), a false positive could consume the only stax budget.

**Impacto:** P3 — Low probability of false positives, but no test coverage. Documented for future refinement. Best mitigation: apply stax heuristic only when `_isOfficialGameChangerName(n)` is true.

**Acao recomendada:**
Consider limiting stax heuristic to known GC names, or add curated exclusion list.

---

## Previous Tasks (2026-06-13) — Still Open

These tasks from the previous run remain open and unfixed (codebase unchanged since 0982403f):

| # | Priority | Title |
|:-:|:--------:|:------|
| 1 | P1 | 12+ official Game Changers missing from `officialGameChangerNamesForBracketPolicy` |
| 2 | P1 | `'combo'` archetype missing from quality gate (overlaps with new Task #1) |
| 3 | P1 | No post-sync GC integrity check — cards missing from `card_oracle_cache` without alert |
| 4 | P1 | Role naming mismatch: persisted tags use `board_wipe`, heuristic roles use `wipe`, quality gate checks `wipe` |
| 5 | P1 | Theme detection exists but quality gate does not use it |

See `docs/hermes-analysis/IMPLEMENTATION_TASKS.md` (version 2026-06-13) for full details.

---

## Running total

- **Previous open tasks:** 5 (all P1, unfixed)
- **New tasks this run:** 5 (1 P1, 3 P2, 1 P3)
- **Total open tasks:** 10 (2 P1 composite, 3 P2, 1 P3 + 4 remaining from previous)
