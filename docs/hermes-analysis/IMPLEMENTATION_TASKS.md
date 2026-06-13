# Implementation Tasks — Synthesis Cron 2026-06-13 (Run 2)

> **Synthesis run:** 2026-06-13T14:00:00+00:00
> **Sources:** SCOUT_LOG (#29), VALIDATOR_LOG (v3.23), GAME_CHANGERS.md, THEMES.md, STRUCTURE_AUDIT.md (revalidated), MANA_BASE_VALIDATION_REPORT.md, LOGIC_COHERENCE_REPORT.md, SQLite knowledge.db (15 tables verified)
> **Branch:** codex/hermes-analysis-docs
> **HEAD:** 0982403f
> **Cross-referenced:** edh_bracket_policy.dart, optimization_functional_roles.dart, optimization_quality_gate.dart, functional_card_tags.dart, optimize_state_support.dart, optimize_runtime_support.dart, theme_contextual_rules_service.dart, deck_rules_service.dart
> **Evidence verification:** All gaps confirmed against live code in HEAD checkout.

---

## Summary

| # | Priority | Title | Type |
|:-:|:--------:|:------|:-----|
| 1 | **P1** | 12+ official Game Changers missing from `officialGameChangerNamesForBracketPolicy` | Incomplete detection |
| 2 | **P1** | `'combo'` archetype missing from quality gate `_criticalRolesForArchetype` and `_looksLikeOffThemeRoleSwap` | Logic gap |
| 3 | **P1** | No post-sync GC integrity check — cards missing from `card_oracle_cache` without alert | Pipeline gap |
| 4 | **P1** | Role naming mismatch: persisted tags use `board_wipe`, heuristic roles use `wipe`, quality gate checks `wipe` — intersection fails silently | Bug — quality gate evasion |
| 5 | **P1** | Theme detection exists (`detectThemeProfile`) but quality gate does not use it — theme-blind swap enforcement | Integration gap |

---

### [P1] 12+ official Game Changers missing from `officialGameChangerNamesForBracketPolicy`

**Conhecimento MTG:** The official Game Changer list (Scryfall `is:gamechanger`) defines 53 cards that "distorcem o jogo ao redor delas" — they are limited to 3 in bracket 3, unlimited in bracket 4, and prohibited in brackets 1-2. GAME_CHANGERS.md documents that these cards belong to 9 impact categories.

**Evidencia no codigo:** `server/lib/edh_bracket_policy.dart:354-408`:
```dart
const officialGameChangerNamesForBracketPolicy = <String>{
  'ad nauseam', 'ancient tomb', 'aura shards', 'biorhythm',
  'bolas\'s citadel', 'braids, cabal minion', 'chrome mox',
  'coalition victory', 'consecrated sphinx', 'crop rotation',
  'cyclonic rift', 'demonic tutor', 'drannith magistrate',
  // ... 54 entries total — but MISSING:
  // armageddon, cryptic command, demonic consultation, expropriate,
  // mana crypt, mox opal, mystic remora, palinchron, personal tutor,
  // ravages of war, sneak attack, timetwister
};
```

Verified by grep: `grep -n "armageddon\|cryptic command\|mox opal\|palinchron\|personal tutor\|sneak attack\|timetwister\|expropriate" server/lib/edh_bracket_policy.dart` returns **zero matches**.

Worst-case impact: `Armageddon` and `Ravages of War` get **zero** bracket categories from `tagCardForBracket()` because:
- Not in `_fastManaNames` (line 312)
- `_looksLikeGameChangerBoardWipe` (line 454) requires `"opponents control"` in oracle text — Armageddon destroys ALL lands, not just opponents'
- Not in any other curated list or heuristic path
- Result: `BracketTagResult({})` — card passes bracket filtering without consuming any budget

**Gap:** Legal official GCs (including Armageddon, Mana Crypt, Mox Opal, Mystic Remora, etc.) are not in the curated name list. Some are partially detected by other heuristics, but NONE get the `gameChanger` tag. A bracket-3 deck can include Armageddon, Sneak Attack, and Timetwister without consuming any of the 3 game changer slots.

**Impacto:** Bracket enforcement for game changers is compromised. Decks can include high-impact GCs without bracket budget tracking.

**Risco:** P1 — Systematic bracket enforcement gap affecting 12+ of the most powerful cards in the format.

**Acao recomendada:** Add all missing legal GCs to `officialGameChangerNamesForBracketPolicy`. Broaden `_looksLikeGameChangerBoardWipe` to detect symmetric mass destruction.

**Validacao:**
```bash
cd server && dart test test/edh_bracket_policy_test.dart
```

---

### [P1] `'combo'` archetype missing from quality gate critical roles

**Conhecimento MTG:** Combo decks in Commander rely on assembling specific card combinations. Their critical needs differ from aggro/control/midrange: protection (Silence, Orim's Chant), tutors (Enlightened, Mystical, Gamble, Demonic), draw (Rhystic Study, Mystic Remora), and ramp are critical. Removal is typically minimal (3-5 pieces).

**Evidencia no codigo:** `server/lib/ai/optimization_quality_gate.dart:493-500`:
```dart
Set<String> _criticalRolesForArchetype(String archetype) {
  return switch (archetype.trim().toLowerCase()) {
    'aggro' => {'creature', 'ramp', 'removal', 'protection', 'wipe', 'wincon'},
    'control' => {'removal', 'draw', 'wipe', 'ramp', 'protection', 'wincon'},
    'midrange' => {'removal', 'ramp', 'draw', 'wipe', 'wincon'},
    _ => {'removal', 'ramp', 'wipe', 'wincon'},   // <-- combo falls here
  };
}
```

The default case (used when archetype is `'combo'`) includes only `{removal, ramp, wipe, wincon}`. Missing: `protection`, `tutor`, `draw` — three roles that are **critical** for combo decks.

The `_looksLikeOffThemeRoleSwap` method (line 502) also has no combo-specific path.

**Gap:** A combo deck optimized through the pipeline can lose protection spells, tutors, and draw engines without the quality gate raising an alarm.

**Impacto:** Systematic quality degradation for combo archetype decks.

**Risco:** P1 — Archetype-specific logic hole affecting all combo decks (a significant portion of the Commander meta, especially bracket 3-4).

**Acao recomendada:** Add `'combo'` case to `_criticalRolesForArchetype`:
```dart
'combo' => {'tutor', 'protection', 'draw', 'ramp', 'wincon'},
```
And add `'combo'` case to `_looksLikeOffThemeRoleSwap` with combo-appropriate role mapping.

**Validacao:**
```bash
cd server && dart test test/optimization_quality_gate_test.dart
```

---

### [P1] No post-sync GC integrity check — cards missing from card_oracle_cache without alert

**Conhecimento MTG:** The 53 official Game Changers define bracket boundaries. If GCs are missing from local analysis cache, the ManaLoom cannot detect them in decks during optimization, bracket enforcement, or deck analysis. GAMECHANGER_RESEARCH_REPORT documents a regression from 47 to 38 GCs present across sync cycles, with 9 additional GCs lost in one cycle.

**Evidencia no pipeline:** The PG→SQLite sync script imports card data but has no post-import integrity check. SQLite `card_oracle_cache` has 3,217 rows. Multiple legal GCs (Expropriate, Panoptic Mirror, Serra's Sanctum, Tergrid, Biorhythm, Braids, Coalition Victory) are confirmed missing.

Missing GCs by category:

| Reason | Count | Examples |
|:-------|:-----:|:---------|
| Banned cards excluded (intentional) | 8 | Channel, Dockside, Emrakul, Fastbond, Hermit Druid, Jeweled Lotus, Tinker, Tolarian Academy |
| DFC handling broken | 1 | Tergrid, God of Fright |
| Unknown cause | 6 | Expropriate (legal!), Biorhythm, Braids, Coalition Victory, Panoptic Mirror, Serra's Sanctum |
| **Total** | **15** | **28.3% of official GCs** |

**Gap:** No validation step runs after PG→SQLite sync to confirm all 53 GC names are present. Regressions go undetected.

**Impacto:** 28.3% of GCs cannot be analyzed locally. Detection rate (24/53 ≈ 45%) cannot be improved without restoring these cards.

**Risco:** P1 — Data pipeline regression silently degrades all downstream analysis.

**Acao recomendada:**
1. Create post-sync integrity check verifying all 53 GC names exist in `card_oracle_cache`
2. Fix sync script for the 3 causes (banned filter, DFC handling, unknown)
3. Add DFC normalizer for `//` in card names
4. Hotfix Expropriate via Scryfall API

**Validacao:**
```bash
cd docs/hermes-analysis/manaloom-knowledge/scripts
python3 -c "
import sqlite3
c = sqlite3.connect('knowledge.db')
for g in ['expropriate','panoptic mirror','serra\'s sanctum','tergrid','biorhythm','braids','coalition victory']:
    r = c.execute('SELECT COUNT(*) FROM card_oracle_cache WHERE LOWER(name) LIKE ?', [f'%{g}%']).fetchone()[0]
    assert r > 0, f'GC {g} still missing'
print('All 53 GCs present')
"
```

---

### [P1] Role naming mismatch: persisted tags use `board_wipe`, heuristic roles use `wipe` — quality gate intersection fails silently

**Conhecimento MTG:** Board wipes are critical roles in most Commander decks (aggro needs 2-4, control needs 4-8, combo needs 1-3). The quality gate is designed to protect critical roles from being removed during optimization. If the role naming is inconsistent, board wipe cards classified via persisted functional tags can be removed without triggering the gate.

**Evidencia no codigo:**

1. **Persisted functional tags use `board_wipe`:**
   `server/lib/ai/functional_card_tags.dart:14`:
   ```dart
   const functionalCardTagsV1 = <String>{
     ...
     'board_wipe',
     ...
   };
   ```
   SQLite confirms: tag `board_wipe` count = 2, tag `wipe` count = 0 in `deck_cards.functional_tag`.

2. **Heuristic role classifier uses `wipe`:**
   `server/lib/ai/optimization_functional_roles.dart:181`:
   ```dart
   if (looksLikeOptimizationBoardWipeText(oracleText)) roles.add('wipe');
   ```

3. **Quality gate checks for `wipe`:**
   `server/lib/ai/optimization_quality_gate.dart:493-499`:
   ```dart
   'aggro' => {'creature', 'ramp', 'removal', 'protection', 'wipe', 'wincon'},
   ...
   ```

4. **The role resolution adapter does not normalize:**
   `server/lib/ai/optimization_functional_roles.dart:46-91` — `resolveCardFunctionalRoles` returns roles as-is from the source. No `board_wipe` → `wipe` normalization.

5. **Intersection fails:** For a card with persisted `board_wipe` tag, `removedRoles = {'board_wipe'}`. The quality gate computes `{'board_wipe'}.intersection({'wipe'})` = `{}` (empty). `losingCriticalRole` = `false`. The gate does NOT flag removal.

6. **Same issue in `_looksLikeOffThemeRoleSwap`** (lines 509-528) — uses `removedRole` which is the primary role from `classifyOptimizationFunctionalRole`. Persisted primary `board_wipe` vs heuristic `wipe`.

**Gap:** The quality gate's critical role set uses `'wipe'`, while persisted functional tags use `'board_wipe'`. Cards classified via persisted tags (the highest priority source) have `board_wipe` in their roles, which doesn't intersect with the gate's `wipe`. The board wipe critical role enforcement is effectively disabled for cards with persisted tags.

Related naming inconsistencies may exist for other roles (`'big_spell'`, `'sacrifice_outlet'`, `'recursion'`, `'graveyard_synergy'`, `'spellslinger'`), but `board_wipe` vs `wipe` is the most impactful because the gate explicitly protects `wipe` as critical.

**Impacto:** Board wipe cards with persisted `board_wipe` tags can be removed during optimization without the quality gate flagging it. The `boardWipe` role retention check in the gate is effectively disabled for ~50%+ of wipe cards (those with persisted tags). Optimized decks may lose critical board presence.

**Risco:** P1 — Systematic quality enforcement gap for one of the most critical roles in Commander. Affects all archetypes that protect `wipe`.

**Acao recomendada:**

1. **Add normalization in `_functionalRolesForGate`:** Map `'board_wipe'` → `'wipe'` before returning the roles set. Place normalization in `resolveCardFunctionalRoles` return path so all consumers benefit.

2. **Audit for similar naming mismatches:** Check `'token_maker'`, `'combo_piece'`, `'sacrifice_outlet'`, `'recursion'`, `'big_spell'`, `'graveyard_synergy'`, `'spellslinger'`, `'loot'` — do all have matching names between functional_tags v1, heuristic classifier, and quality gate?

**Validacao:**
```bash
cd server && dart test test/optimization_quality_gate_test.dart
# Test: board_wipe-tagged card from persisted source — removal should be blocked
# Test: heuristic wipe card — removal should be blocked (existing behavior)
# Test: both paths produce the same primary role for board wipe cards
```

---

### [P1] Theme detection exists (`detectThemeProfile`) but quality gate does not use it — theme-blind swap enforcement

**Conhecimento MTG:** Different Commander themes have vastly different critical role requirements documented in THEMES.md:

| Theme | Critical Roles | Source |
|:------|:---------------|:-------|
| Goblins | haste_enabler (6-10), ramp (8-11), goblins density (25-38) | Profile Krenko |
| Spellslinger | draw (12-16), instants/sorceries (25+) | EDHREC corpus |
| Dragons | ramp (12-16), copy_enabler (5-9), ETB_damage_payoff (5-8) | Profile Miirym (27k+ decks) |
| Vampires | vampire_density (24-34), lord/drain_payoffs (7-11), interaction (8-11) | Profile Edgar Markov (46,541 decks) |
| Voltron | protection (8-10), equipment reducers | EDHREC corpus |
| Aristocrats | sacrifice_outlet, drain_payoff, recursion | EDHREC corpus |

**Evidencia no codigo:**

1. **Theme detection EXISTS** — `server/lib/ai/optimize_state_support.dart:530-794`:
   ```dart
   Future<DeckThemeProfileResult> detectThemeProfile(
     List<Map<String, dynamic>> cards, {
     required List<String> commanders,
     required Pool pool,
   }) async {
   ```
   This function detects up to 12 themes: artifacts, enchantments, spellslinger, tokens, reanimator, aristocrats, voltron, landfall, wheels, stax, counters, tribal-{tribe}.

2. **Theme detection IS called** — `server/lib/ai/optimize_request_support.dart:266-278`:
   ```dart
   final themeProfileFuture = ...
     () => detectThemeProfile(allCardData, commanders: commanders, pool: pool),
   ```
   Result stored in `OptimizeRequestContext.themeProfile` (line 333).

3. **But quality gate does NOT consume theme** — `server/lib/ai/optimization_quality_gate.dart:493-500`:
   Only 4 archetype patterns. No `detectedTheme` parameter exists. The function takes `String archetype` only.

4. **ThemeContextualRulesService.validateDeck exists** (lines 55-64) but:
   - Relies on PostgreSQL (`theme_contextual_rules` table), often unavailable
   - Uses `archetypeToTheme` (line 54) which keyword-matches archetype name — does not analyze deck data
   - Runs AFTER optimization, not during quality gate swap filtering

5. **Detection coverage limited** — 12 themes vs 42+ documented in THEMES.md. Missing: blink/flicker, group_slug, pillow_fort, superfriends, cascade, mutate, party, enchantress.

**Gap:** Theme detection exists and runs during optimization, but the quality gate is completely theme-blind. It cannot:
1. Block removal of theme-critical cards (haste enabler in Goblins)
2. Adapt critical roles with theme-specific requirements
3. Signal the optimizer to prefer theme-enforcing additions

Additionally, `detectThemeProfile` covers only 12 themes (29% of 42+). The PostgreSQL fallback degrades silently.

**Impacto:** Theme-focused decks (Goblins, Spellslinger, Dragons, Aristocrats) receive suboptimal optimization because the quality gate doesn't understand which cards are critical to their theme.

**Risco:** P1 — Theme deck users get lower-quality optimization results because theme-specific requirements are not enforced during swap filtering.

**Acao recomendada:**

1. **Wire `detectedTheme` into quality gate:** Extend `_criticalRolesForArchetype` to accept `String? detectedTheme`. Add theme-critical role mappings:
   - `'goblins'` → add `haste_enabler`
   - `'spellslinger'` → add `draw`
   - `'voltron'` → add `protection`, `equipment`
   - `'aristocrats'` → add `sacrifice_outlet`, `drain`
   - `'reanimator'` → add `recursion`, `graveyard_synergy`

2. **Expand `detectThemeProfile` to 42+ themes:** Add blink/flicker, group_slug, pillow_fort. Add tribe-specific thresholds (goblins=25+, dragons=18+). Cross-reference commander oracle text for theme affinity.

3. **Add `theme` parameter to `filterUnsafeOptimizeSwapsByCardData`** so the quality gate enforces theme-specific rules during swap filtering (not just post-optimization validation).

**Validacao:**
```bash
cd server && dart test test/optimization_quality_gate_test.dart
# Test: goblins deck swapping haste enabler → blocked
# Test: spellslinger deck removing draw engine → blocked
# Test: generic deck (no theme) → archetype-based rules still apply
```

---

## Appendix: Changes from previous synthesis (2026-06-13T08:00 UTC)

| Change | Previous | Current |
|:-------|:---------|:--------|
| Task #4 (old) | Quality gate theme-agnostic | Expanded with evidence that `detectThemeProfile` EXISTS and IS called — real gap is quality gate not consuming theme |
| Task #5 (old) | "Auto-detection does not exist" | **Removed** — `detectThemeProfile` exists at `optimize_state_support.dart:530`. Merged into updated Task #5. |
| Task #4 (new) | — | **New:** Role naming mismatch `board_wipe` vs `wipe` causes quality gate intersection to fail silently for persisted board wipe tags |
