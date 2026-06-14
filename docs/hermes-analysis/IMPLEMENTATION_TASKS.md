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


---

## Tasks Novas (2026-06-14 @ Cron #12 — Synthesis)

> **Gerado:** 2026-06-14 por ManaLoom Knowledge Synthesis (Cron #12)
> **Branch:** codex/hermes-analysis-docs
> **Metodo:** Cruzamento do conhecimento MTG (Domain Skill Gaps 3, 25, 28; GAMECHANGER_RESEARCH_REPORT Exec #14 — 54 official GCs, 20 missing 37.0%; edh_bracket_policy.dart analysis — 11 categories, curated name lists incomplete) com codigo Dart (edh_bracket_policy.dart, optimization_quality_gate.dart)
> **Novas tasks nesta execucao:** 5 (4xP2, 1xP3) — Underworld Breach missing infiniteCombo, Orcish Bowmasters undetected cardAdvantage/stax, Narset/Notion Thief undetected stax, Bolas's Citadel missing infiniteCombo, tagCardForBracket warning for empty oracle GCs

### [P2] Underworld Breach — official GC missing from `_knownInfiniteComboPieces` (Gap 28, Domain Skill §13)

**Conhecimento MTG:** The Domain Skill explicitly documents Gap 28: "Underworld Breach em `officialGameChangerNamesForBracketPolicy` mas NÃO em `_knownInfiniteComboPieces`". Underworld Breach is an official Game Changer AND a well-known infinite combo piece. Its oracle text enables infinite combos with Lion's Eye Diamond + Grinding Station, or Brain Freeze, or any source of self-mill + mana-positive artifact. In Commander cEDH, it is a cornerstone of the turbo-combo archetype alongside Thassa's Oracle.

**Evidencia no codigo:**
- `server/lib/edh_bracket_policy.dart:347-351` — `_knownInfiniteComboPieces` has only 3 entries: `thassa's oracle`, `demonic consultation`, `tainted pact`.
- `server/lib/edh_bracket_policy.dart:405` — `officialGameChangerNamesForBracketPolicy` includes `underworld breach`.
- `server/lib/edh_bracket_policy.dart:125-127` — `_isOfficialGameChangerName` adds `gameChanger` category.
- `server/lib/edh_bracket_policy.dart:162-164` — `_knownInfiniteComboPieces` check is independent, so Underworld Breach enters only as `gameChanger`, never as `infiniteCombo`.

**Gap:** Underworld Breach is tagged only as `gameChanger`, not as `infiniteCombo`. In bracket 3 (max 2 infinite combos), a deck could have Underworld Breach + Thassa's Oracle + Demonic Consultation = 3 infinite combo sources. The system counts: 2 combo pieces (Thassa's + Demonic) + 3 GCs consumed. The Underworld Breach does NOT consume infiniteCombo budget, allowing a deck to exceed the intended combo density.

**Impacto:** `P2` — Bracket compliance checking is incomplete for one of the most common cEDH combo engines. Affects bracket 3 decks running Underworld Breach lines. The `applyBracketPolicyToAdditions()` gate may approve swaps that add Underworld Breach on top of an already-combo-saturated deck.

**Risco:** P2 — Real gap for cEDH decks at bracket 3. Not critical for casual brackets (1-2) where GCs are banned anyway.

**Acao recomendada:**
1. Add `'underworld breach'` to `_knownInfiniteComboPieces` in `server/lib/edh_bracket_policy.dart:347-351`.
2. Verify that Underworld Breach now returns both `gameChanger` and `infiniteCombo` in `tagCardForBracket()`.
3. Update bracket_category in SQLite game_changers table if applicable.
4. Add test case: `tagCardForBracket(name: 'Underworld Breach', oracleText: '...')` returns `{gameChanger, infiniteCombo}`.

**Validacao:**
```bash
cd server && dart analyze lib/edh_bracket_policy.dart
cd server && dart test test/edh_bracket_policy_test.dart --reporter compact
```

---

### [P2] Orcish Bowmasters — official GC not detected as cardAdvantage or stax

**Conhecimento MTG:** Orcish Bowmasters is an official Game Changer and one of the most played cards in Commander (2023-2024 meta). Its effect is dual-purpose: it punishes opponents for drawing cards (stax/draw-hate) and generates card advantage (causes opponents to lose life while you get a creature). In the Commander banlist discourse, it is frequently cited alongside Rhystic Study and The One Ring as a "card advantage engine" that distorts games.

**Evidencia no codigo:**
- `server/lib/edh_bracket_policy.dart:469-491` — `_looksLikeGameChangerCardAdvantage()` checks:
  1. Curated names: 7 cards (Rhystic, Mystic Remora, The One Ring, Smothering Tithe, Necropotence, Ad Nauseam, Consecrated Sphinx) — **Orcish Bowmasters NOT included**.
  2. Tax-based: "unless" + "pays" + ("draw" | "create") — Oracle text: "Whenever an opponent draws a card, you may have ~ deal 1 damage to that player and you create a Food token" — **no match**.
  3. Necropotence-style: "pay" + "life" + "draw" + "card" + "skip your draw step" — **no match**.
- `server/lib/edh_bracket_policy.dart:493-518` — `_looksLikeGameChangerStax()` checks:
  1. Curated names: Drannith, Opposition Agent, Grand Abolisher, Winter Orb, Static Orb, Torpor Orb, Rule of Law, Deafening Silence, etc. — **Orcish Bowmasters NOT included**.
  2. Oracle text patterns: **Oracle text doesn't match any** (no "can't cast more than one spell", no "search...library...control", no "creatures entering...don't cause").
- Result: `tagCardForBracket()` returns ONLY `{gameChanger}`, missing both `cardAdvantage` and `stax` secondary categories.

**Gap:** One of the most impactful GCs in the format lacks any secondary categorization. The `applyBracketPolicyToAdditions()` system cannot distinguish Orcish Bowmasters (draw-hate stax) from a generic GC — it only knows it's a game changer. Budget planning for stax/cardAdvantage categories completely ignores this card.

**Impacto:** `P2` — Secondary categories are used for bracket budget enforcement. A deck in bracket 3 could add Orcish Bowmasters (consumes 1 GC slot) without consuming its `stax` or `cardAdvantage` budget. If the same deck already has 4 other cardAdvantage GCs, the system doesn't flag Orcish Bowmasters as exceeding the `cardAdvantage` budget.

**Risco:** P2 — Affects bracket budget tracking for one of the most prevalent GCs. The impact is hidden because this card is most often played in bracket 4 (unlimited budget).

**Acao recomendada:**
1. Add `'orcish bowmasters'` to `_looksLikeGameChangerCardAdvantage` curated names in `edh_bracket_policy.dart:469-491`.
2. Optionally add draw-hate pattern to `_looksLikeGameChangerStax()`: `oracleLower.contains('whenever') && oracleLower.contains('opponent') && oracleLower.contains('draws a card') && oracleLower.contains('lose life')`.
3. Verify Orcish Bowmasters returns `{gameChanger, cardAdvantage}` (and optionally `stax`).
4. Add test: `tagCardForBracket(name: 'Orcish Bowmasters', oracleText: 'Whenever an opponent draws a card...')`.

**Validacao:**
```bash
cd server && dart analyze lib/edh_bracket_policy.dart
cd server && dart test test/edh_bracket_policy_test.dart --reporter compact
```

---

### [P2] Narset, Parter of Veils and Notion Thief — official GCs missing from stax detection

**Conhecimento MTG:** Narset, Parter of Veils and Notion Thief are official Game Changers that function as draw-restriction stax pieces. Narset's ability "Each opponent can't draw more than one card each turn" is a classic stax effect that shuts down wheels, Rhystic Study, and other draw engines. Notion Thief replaces opponents' draws with your own. Both are classified as stax by the Commander community.

**Evidencia no codigo:**
- `server/lib/edh_bracket_policy.dart:493-518` — `_looksLikeGameChangerStax()` checks:
  1. Curated names: 11 stax pieces — **Narset NOT included**, **Notion Thief NOT included**.
  2. "Can't cast more than one spell" pattern: Narset — "can't draw more than one card" = no match.
  3. "Search library control" pattern: no match.
  4. "Creatures entering don't cause" pattern: no match.
- Result: Both return ONLY `{gameChanger}`, missing the `stax` secondary category.

**Gap:** Two official GCs with clear stax/draw-restriction effects are invisible to the stax detection.

**Impacto:** `P2` — In bracket 3 (max 3 stax), a deck could have Drannith Magistrate + Narset + Notion Thief = 3 stax pieces but the system would count only 1 (Drannith).

**Risco:** P2 — Affects bracket budget for draw-restriction stax.

**Acao recomendada:**
1. Add `'narset, parter of veils'` and `'notion thief'` to curated names in `_looksLikeGameChangerStax()`.
2. Add oracle text pattern for draw restriction: `oracleLower.contains('can\'t draw more than')`.
3. Add test: `tagCardForBracket(name: 'Narset, Parter of Veils', ...)` returns `{gameChanger, stax}`.

**Validacao:**
```bash
cd server && dart analyze lib/edh_bracket_policy.dart
cd server && dart test test/edh_bracket_policy_test.dart --reporter compact
```

---

### [P2] Bolas's Citadel — in `_knownValueEngineNames` but not `_knownInfiniteComboPieces`

**Conhecimento MTG:** Bolas's Citadel is an official Game Changer AND a well-known infinite combo piece. Its ability combines with Sensei's Divining Top and Aetherflux Reservoir to create deterministic infinite life/casts. The Domain Skill (Gap 25) documents incorrect categorization.

**Evidencia no codigo:**
- `server/lib/edh_bracket_policy.dart:541-547` — `_knownValueEngineNames` includes `'bolas\'s citadel'` → tagged as `valueEngine` ✅.
- `server/lib/edh_bracket_policy.dart:347-351` — `_knownInfiniteComboPieces` does NOT include Bolas's Citadel → NOT tagged as `infiniteCombo` ❌.
- Result: `tagCardForBracket()` returns `{gameChanger, valueEngine}` but should return `{gameChanger, valueEngine, infiniteCombo}`.

**Gap:** Bolas's Citadel is correctly detected as a value engine but not as an infinite combo piece.

**Impacto:** `P2` — Bracket budget for infinite combos is under-counted when Bolas's Citadel is present.

**Risco:** P2 — Affects bracket compliance for Top/Reservoir/Citadel combo decks at bracket 3.

**Acao recomendada:**
1. Add `'bolas\'s citadel'` to `_knownInfiniteComboPieces` in `server/lib/edh_bracket_policy.dart:347-351`.
2. Keep Bolas's Citadel in `_knownValueEngineNames` — it functions as BOTH categories.
3. Verify `tagCardForBracket()` returns `{gameChanger, valueEngine, infiniteCombo}`.
4. Add test: `tagCardForBracket(...)` returns all three categories.

**Validacao:**
```bash
cd server && dart analyze lib/edh_bracket_policy.dart
cd server && dart test test/edh_bracket_policy_test.dart --reporter compact
```

---

### [P3] `tagCardForBracket()` should emit developer warning when official GC has empty oracle_text

**Conhecimento MTG:** The Gamechanger Research Report Exec #14 (2026-06-14) confirms that 20 of 54 official GCs (37.0%) are missing from `card_oracle_cache` in the SQLite. Their `oracle_text` is NULL or empty. When `tagCardForBracket()` is called for these cards, heuristic functions receive empty strings and silently return false. Only `gameChanger` is detected — all secondary categorization is lost.

**Evidencia no codigo:**
- `server/lib/edh_bracket_policy.dart:115-191` — `tagCardForBracket()` silently returns `false` for all heuristic checks when oracle text is empty.
- No debug log/warning is emitted when an official GC has no oracle text.
- `server/lib/edh_bracket_policy.dart:411-417` — `_isOfficialGameChangerName()` works independently of oracle text.

**Gap:** No diagnostic feedback when official GCs lack oracle text.

**Impacto:** `P3` — Currently diagnostic only. Secondary category budgets are under-counted for 37% of GCs silently.

**Risco:** P3 — Improves operator awareness. The 20 missing GCs are covered by separate existing tasks.

**Acao recomendada:**
1. In `tagCardForBracket()`, after official GC name check passes, add developer log warning when oracle text is empty.
2. Add test: verify that calling `tagCardForBracket(name: 'Expropriate', oracleText: '')` returns only `{gameChanger}`.

**Validacao:**
```bash
cd server && dart analyze lib/edh_bracket_policy.dart
cd server && dart test test/edh_bracket_policy_test.dart --reporter compact
```

---

## Resumo de Tasks Novas (2026-06-14 — Cron #12)

| # | Prioridade | Task | Origem |
|:-:|:----------|:-----|:-------|
| 1 | P2 | Underworld Breach — add to `_knownInfiniteComboPieces` (Gap 28) | Domain Skill §13 Gap 28 + edh_bracket_policy.dart analysis |
| 2 | P2 | Orcish Bowmasters — detect as cardAdvantage (and optionally stax) | edh_bracket_policy.dart secondary category gaps |
| 3 | P2 | Narset, Parter of Veils / Notion Thief — detect as stax | edh_bracket_policy.dart stax curated list incomplete |
| 4 | P2 | Bolas's Citadel — add to `_knownInfiniteComboPieces` (preserve valueEngine) | Domain Skill §13 Gap 25 + combo piece classification |
| 5 | P3 | `tagCardForBracket()` — developer warning when official GC has empty oracle_text | GAMECHANGER_RESEARCH_REPORT Exec #14 (20/54 GCs missing, 37.0%) |

> **Nota:** Tasks #1 e #4 sao complementares — ambas adicionam cartas a `_knownInfiniteComboPieces`, que atualmente tem apenas 3 entradas. Isso desbloqueia a correta categorizacao de infinite combo no bracket budget.
> **Nota:** Tasks #2, #3 abordam GCs que perderam categorizacao secundaria — todos estao em `officialGameChangerNamesForBracketPolicy` mas faltam das listas curadas de `cardAdvantage`, `stax`, e `infiniteCombo`.
> **Nota:** Task #5 e preventiva/diagnostica — nao corrige as 20 cartas faltantes (isso e coberto pela task "GC MDFC oracle_text auto-heal" existente), mas adiciona visibilidade para o operador quando GCs secundarias estao desabilitadas.
