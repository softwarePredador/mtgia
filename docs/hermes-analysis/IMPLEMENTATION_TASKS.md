# Implementation Tasks — Hermes Knowledge ↔ Code Cross-Reference

**Generated:** 2026-06-14T21:00:00Z  
**Source:** Cross-reference of SCOUT_LOG, VALIDATOR_LOG, GAME_CHANGERS.md, THEMES.md, MANA_BASE_VALIDATION_REPORT.md, STRUCTURE_AUDIT.md, LOGIC_COHERENCE_REPORT.md, and live code under `server/lib/`

---

## Task 1 (P1) — Add `combo` case to `_criticalRolesForArchetype`

**Conhecimento MTG:** The learned_decks table shows `combo` is a valid archetype (alongside aggro, control, midrange, etc.). Combo decks are fragile — losing a tutor, protection piece, or combo_piece can make the deck non-functional. A combo deck's critical roles are fundamentally different from midrange or value decks.

**Evidência no código:** `server/lib/ai/optimization_quality_gate.dart:493-500`

```dart
Set<String> _criticalRolesForArchetype(String archetype) {
  return switch (archetype.trim().toLowerCase()) {
    'aggro' => {'creature', 'ramp', 'removal', 'protection', 'wipe', 'wincon'},
    'control' => {'removal', 'draw', 'wipe', 'ramp', 'protection', 'wincon'},
    'midrange' => {'removal', 'ramp', 'draw', 'wipe', 'wincon'},
    _ => {'removal', 'ramp', 'wipe', 'wincon'},  // ← combo falls here
  };
}
```

**Gap:** No `'combo'` case. When `archetype='combo'`, the switch falls to the `_` default which only has `{'removal', 'ramp', 'wipe', 'wincon'}` — missing `tutor`, `protection`, `combo_piece`, `draw`.

**Impacto:** A `combo` deck optimization can lose tutors, protection, or combo pieces without the quality gate flagging it as a critical role loss (line 440-444). This allows harmful swaps to pass validation.

**Risco:** P1 — Incoerência que leva a otimizações nocivas em arquétipos combo.

**Ação recomendada:** Add a `'combo'` case:
```dart
'combo' => {'tutor', 'protection', 'combo_piece', 'wincon', 'ramp', 'draw'},
```

**Validação:** `dart test test/optimization_quality_gate_test.dart`

---

## Task 2 (P1) — Add `combo` case to `_looksLikeOffThemeRoleSwap`

**Conhecimento MTG:** Combo decks rely on specific pieces to execute their win condition. Swapping a combo_piece (e.g., Dualcaster Mage) for a utility card (e.g., an extra land) destroys the deck's game plan. The quality gate's off-theme role swap protection must cover combo decks.

**Evidência no código:** `server/lib/ai/optimization_quality_gate.dart:505-529`

```dart
bool _looksLikeOffThemeRoleSwap({
  required String removedRole,
  required String addedRole,
  required String archetype,
}) {
  final normalized = archetype.trim().toLowerCase();
  if (normalized == 'aggro' && ...) return true;
  if (normalized == 'control' && ...) return true;
  if (normalized == 'midrange' && ...) return true;
  return false;  // ← combo always falls here — no swap flagged as off-theme
}
```

**Gap:** No `combo` archetype handling. For combo decks, ANY role swap passes the off-theme check (always `false`). This means a swap removing `combo_piece` and adding `utility` would not be flagged.

**Impacto:** Same as Task 1 — harmful swaps for combo decks pass without gate protection. The defender (validator via critical roles) catches the delta, but the gate (filter) should also catch it during swap filtering.

**Risco:** P1 — Incoerência que permite trocas off-theme em combo.

**Ação recomendada:** Add `'combo'` branch:
```dart
if (normalized == 'combo' &&
    {'combo_piece', 'tutor', 'wincon', 'protection', 'ramp'}.contains(removedRole) &&
    !{'combo_piece', 'tutor', 'wincon', 'protection', 'ramp', 'draw', 'removal'}
        .contains(addedRole)) {
  return true;
}
```

**Validação:** `dart test test/optimization_quality_gate_test.dart`

---

## Task 3 (P2) — Add `creature` to midrange `_criticalRolesForArchetype`

**Conhecimento MTG:** THEMES.md identifies midrange as an archetype that wins through creature combat and incremental value. Midrange without creatures is just control. The mana base validation report also shows midrange decks needing creature density for board presence. By MTG convention, midrange needs creatures as a critical path to victory.

**Evidência no código:** `server/lib/ai/optimization_quality_gate.dart:497`

```dart
'midrange' => {'removal', 'ramp', 'draw', 'wipe', 'wincon'},
```

Note: `'creature'` is present in the aggro case but absent from midrange.

**Gap:** Midrange optimization can swap out all creatures without the quality gate flagging it as a critical role loss.

**Impacto:** A midrange deck could be optimized to have 0-3 creatures (transforming into draw-go control) without the validator raising a critical role warning. This would violate the deck's intended game plan.

**Risco:** P2 — Melhoria significativa de coerência.

**Ação recomendada:** Add `'creature'` to midrange critical roles:
```dart
'midrange' => {'removal', 'ramp', 'draw', 'wipe', 'wincon', 'creature'},
```

**Validação:** `dart test test/optimization_quality_gate_test.dart`

---

## Task 4 (P2) — Add `wincon` to aggro off-theme role swap protection

**Conhecimento MTG:** Aggro decks need efficient wincons to close games before opponents stabilize. `_criticalRolesForArchetype` already lists `wincon` as critical for aggro. However, the off-theme role swap filter (`_looksLikeOffThemeRoleSwap`) does not protect `wincon` for aggro, creating an inconsistency between the two protection layers.

**Evidência no código:** `server/lib/ai/optimization_quality_gate.dart:509-512`

```dart
if (normalized == 'aggro' &&
    {'creature', 'ramp', 'removal', 'protection', 'wipe'}.contains(removedRole) &&
    !{'creature', 'ramp', 'removal', 'protection', 'wipe'}.contains(addedRole)) {
  return true;
}
```

`wincon` is in the critical roles (line 495) but NOT in the off-theme protection set.

**Gap:** An aggro deck can have a `wincon` swapped out for a non-wincon (`utility` or `engine`) without the gate flagging it as off-theme. The validator can catch this later via critical role delta, but the gate filtering phase should also protect `wincon` for consistency.

**Impacto:** Inconsistência entre gate filtering and validator checking. Aggro wincon swaps may pass initial filtering only to be caught later, wasting compute.

**Risco:** P2 — Melhoria de consistência entre camadas de proteção.

**Ação recomendada:** Add `'wincon'` to both sets in the aggro branch:
```dart
if (normalized == 'aggro' &&
    {'creature', 'ramp', 'removal', 'protection', 'wipe', 'wincon'}.contains(removedRole) &&
    !{'creature', 'ramp', 'removal', 'protection', 'wipe', 'wincon'}.contains(addedRole)) {
  return true;
}
```

**Validação:** `dart test test/optimization_quality_gate_test.dart`

---

## Task 5 (P2) — Implement automatic theme detection from decklist

**Conhecimento MTG:** THEMES.md documents a complete methodology for detecting deck themes:
1. Count tribes (20+ cards of a creature type → TRIBAL)
2. Count mechanics (20+ instants/sorceries + 4+ spell payoffs → SPELLSLINGER)
3. Score confidence (3+ strong signals → CONFIRMED, 2 → PROVABLE, 1 → POSSIBLE)

Currently, this knowledge exists in THEMES.md but is not implemented in code. The optimizer has `keepTheme` and `detectedTheme` fields but relies on external input (user or commander reference profile) for theme detection — it cannot infer a theme from deck card data alone.

**Evidência no código:**
- `server/lib/ai/optimization_validator.dart:55` — `ThemeContextualRulesService.validateDeck()` receives archetype as parameter (already known), does not infer theme
- `server/lib/ai/theme_contextual_rules_service.dart` — reads theme rules from PostgreSQL to validate decks, does not detect themes from card content
- No automatic theme inference step exists in the optimization pipeline

**Gap:** The system cannot detect what theme a deck is built around without explicit user input or a commander reference profile. Swap suggestions may dilute the deck's core theme package because the optimizer doesn't know the theme exists.

**Impacto:** The optimizer may suggest swaps that remove core theme enablers (e.g., removing the 20th instant/sorcery from a spellslinger deck) without understanding it's diluting the theme. Manual commander reference profiles partially mitigate this, but they only cover ~48 commanders.

**Risco:** P2 — Melhoria que adicionaria capacidade significativa ao pipeline.

**Ação recomendada:**
1. Create `server/lib/ai/theme_detector.dart` implementing the THEMES.md methodology
2. 20+ cards of same creature type → detect tribal theme
3. 20+ instants/sorceries + min N spell payoffs → spellslinger
4. 15+ enchantments + N enchantress effects → enchantress
5. Confidence scoring (3+ signals = CONFIRMED)
6. Wire into optimization pipeline (`detectedTheme` field)
7. Update THEMES.md to mark detected themes as VALIDATED

**Validação:** Create `test/theme_detector_test.dart` with known archetype decklists and verify detection accuracy

---

## Summary

| # | Priority | Task | File | Impact |
|:-:|:--------:|:-----|:-----|:-------|
| 1 | **P1** | Add `combo` case to `_criticalRolesForArchetype` | `optimization_quality_gate.dart:493` | Combo decks lose tutors/protection without warning |
| 2 | **P1** | Add `combo` case to `_looksLikeOffThemeRoleSwap` | `optimization_quality_gate.dart:505` | Combo swaps never flagged as off-theme |
| 3 | **P2** | Add `creature` to midrange critical roles | `optimization_quality_gate.dart:497` | Midrange could lose all creatures silently |
| 4 | **P2** | Add `wincon` to aggro off-theme protection | `optimization_quality_gate.dart:509` | Inconsistency between gate and validator |
| 5 | **P2** | Implement automatic theme detection | New file: `theme_detector.dart` | No theme awareness in optimization pipeline |

**Total: 5 tasks (2 P1, 3 P2)**
