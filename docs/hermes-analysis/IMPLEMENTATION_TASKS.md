# Implementation Tasks — Synthesis Cron 2026-06-13

> **Synthesis run:** 2026-06-13T08:00:00+00:00
> **Sources:** SCOUT_LOG (#29), VALIDATOR_LOG (v3.23), GAMECHANGER_RESEARCH_REPORT (Exec #13), THEMES.md, STRUCTURE_AUDIT.md (revalidated), MANA_BASE_VALIDATION_REPORT.md, LOGIC_COHERENCE_REPORT.md
> **Branch:** codex/hermes-analysis-docs
> **HEAD:** 6caa21c0
> **Cross-referenced:** edh_bracket_policy.dart (v8+), functional_card_tags.dart, optimization_functional_roles.dart, optimization_quality_gate.dart
> **Evidence verification:** All gaps confirmed against live code in HEAD checkout.

---

## Summary

| # | Priority | Title | Type |
|:-:|:--------:|:------|:-----|
| 1 | **P1** | 12+ official Game Changers missing from `officialGameChangerNamesForBracketPolicy` — bracket evasion | Incomplete detection |
| 2 | **P1** | `'combo'` archetype missing from quality gate `_criticalRolesForArchetype` — swaps degrade combo decks | Logic gap |
| 3 | **P1** | No post-sync GC integrity check — 15/53 GCs missing from `card_oracle_cache` (28.3%) without alert | Pipeline gap |
| 4 | **P1** | Quality gate critical roles are archetype-only, not theme-aware — misses theme-specific requirements | Logic gap |
| 5 | **P1** | Auto-detection of deck theme from card data does not exist — theme is only a pass-through parameter | Missing feature |

---

### [P1] 12+ official Game Changers missing from `officialGameChangerNamesForBracketPolicy`

**Conhecimento MTG:** The official Game Changer list (Scryfall `is:gamechanger`) defines 53 cards that "distorcem o jogo ao redor delas" — they are limited to 3 in bracket 3, unlimited in bracket 4, and prohibited in brackets 1-2. GAME_CHANGERS.md documents that these cards belong to 9 impact categories (fast_mana, tutor, card_advantage, free_interaction, board_wipe, stax, value_engine, combo_piece, protection). GAMECHANGER_RESEARCH_REPORT Exec #13 confirms 38/53 GCs present in `card_oracle_cache` including Armageddon, Cryptic Command, Demonic Consultation, Mana Crypt, Mox Opal, Mystic Remora, Palinchron, Personal Tutor, Ravages of War, Sneak Attack, Timetwister — yet these 11 (plus Expropriate which is also missing from cache) are NOT in the code's official Game Changer name list.

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

**Gap:** 11 legal official GCs (plus Expropriate, also missing from cache) are not in the curated name list. Some are partially detected by other heuristic categories (e.g., Mana Crypt → fastMana, Mystic Remora → cardAdvantage, Demonic Consultation → infiniteCombo), but NONE get the `gameChanger` tag. This means a bracket-3 deck can include Armageddon, Sneak Attack, and Timetwister without consuming any of the 3 game changer slots.

**Impacto:** Bracket enforcement for game changers is compromised. Decks can include high-impact GCs without bracket budget tracking. The "3 game changers max" rule for bracket 3 is unenforceable for these cards.

**Risco:** P1 — Systematic bracket enforcement gap affecting 12+ of the most powerful cards in the format.

**Acao recomendada:** Add all missing legal GCs to `officialGameChangerNamesForBracketPolicy`:
- armageddon, cryptic command, demonic consultation, expropriate (also fix PG→SQLite sync), mana crypt, mox opal, mystic remora, palinchron, personal tutor, ravages of war, sneak attack, timetwister

Also broaden `_looksLikeGameChangerBoardWipe` to detect symmetric mass destruction (e.g., "destroy all lands", "destroy all creatures" without the "opponents control" guard). Add curated names for Armageddon/Ravages.

**Validacao:**
```bash
cd server && dart test test/edh_bracket_policy_test.dart
# Verify gameChanger category is returned for each added name
# Verify Armageddon returns at least boardWipe category
```

---

### [P1] `'combo'` archetype missing from quality gate critical roles

**Conhecimento MTG:** Combo decks in Commander rely on assembling specific card combinations. Their critical needs differ from aggro/control/midrange:
- **Protection:** Combo turns need protection (Silence/Orim's Chant/Deflecting Swat/Flawless Maneuver)
- **Tutor:** Finding combo pieces requires tutors (Enlightened, Mystical, Gamble, Demonic)
- **Draw:** Digging for pieces needs efficient card draw (Rhystic Study, Mystic Remora, impulse draw)
- **Ramp:** Accelerating to the combo turn is critical
- **Removal/Wipe:** Combo decks typically run minimal removal (3-5 pieces) — they race to combo, not control the board

GAMECHANGER_RESEARCH_REPORT confirms 38 GCs include 4+ combo-centric GCs (Demonic Consultation, Palinchron, Bolas's Citadel, Thassa's Oracle) that are core to combo archetypes.

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

**Gap:** A combo deck optimized through the pipeline can lose protection spells, tutors, and draw engines without the quality gate raising an alarm, as long as removal/ramp/wipe/wincon are preserved.

**Impacto:** Systematic quality degradation for combo archetype decks. The optimizer can replace Silence/Orim's Chant (protection) with a generic removal spell, or cut Mystical Tutor (tutor) for a ramp piece, and the gate won't flag it.

**Risco:** P1 — Archetype-specific logic hole affecting all combo decks (a significant portion of the Commander meta, especially bracket 3-4).

**Acao recomendada:** Add `'combo'` case to `_criticalRolesForArchetype`:
```dart
'combo' => {'tutor', 'protection', 'draw', 'ramp', 'wincon'},
```
And add `'combo'` case to `_looksLikeOffThemeRoleSwap` with combo-appropriate role mapping.

**Validacao:**
```bash
cd server && dart test test/optimization_quality_gate_test.dart
# Test: combo archetype deck swapping protection for removal should be blocked
# Test: combo deck swapping tutor for ramp should be blocked
```

---

### [P1] No post-sync GC integrity check — 15/53 GCs missing from card_oracle_cache (28.3%)

**Conhecimento MTG:** The 53 official Game Changers define bracket boundaries. If GCs are missing from local analysis cache, the ManaLoom cannot detect them in decks during optimization, bracket enforcement, or deck analysis. GAMECHANGER_RESEARCH_REPORT Exec #13 documents a **regression** from 47 to 38 GCs present (Exec #12→Exec #13), with 9 additional GCs lost in one sync cycle.

**Evidencia no pipeline:** `docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_target_deck_to_hermes.py` — The PG→SQLite sync script imports card data but has no post-import integrity check. The `card_oracle_cache` table shows 3,217 rows.

Direct verification of missing GCs (2026-06-13):
```bash
python3 -c "
import sqlite3
c = sqlite3.connect('docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db')
for g in ['expropriate','panoptic mirror','serra\'s sanctum','tergrid']:
    r = c.execute('SELECT COUNT(*) FROM card_oracle_cache WHERE LOWER(name) LIKE ?', [f'%{g}%']).fetchone()[0]
    print(f\"{'MISSING' if r==0 else 'OK'}: {g}\")
"
# → MISSING: expropriate, panoptic mirror, serra's sanctum, tergrid
```

Missing GCs by category (from GAMECHANGER_RESEARCH_REPORT Exec #13):

| Reason | Count | Examples |
|:-------|:-----:|:---------|
| Banned cards excluded | 8 | Channel, Dockside, Emrakul Aeons, Fastbond, Hermit Druid, Jeweled Lotus, Tinker, Tolarian Academy |
| DFC handling broken | 1 | Tergrid, God of Fright |
| Unknown cause | 6 | Expropriate (legal!), Biorhythm, Braids, Coalition Victory, Panoptic Mirror, Serra's Sanctum |
| **Total** | **15** | **28.3% of official GCs** |

**Gap:** No validation step runs after PG→SQLite sync to confirm all 53 GC names are present. Regressions (47→38 GCs) go undetected until the next GAMECHANGER_RESEARCH_REPORT cron run, which is a reporting tool, not an alerting system.

**Impacto:** 28.3% of GCs cannot be analyzed locally. Decks containing Expropriate, Tergrid, Panoptic Mirror, or Serra's Sanctum will have incomplete bracket assessment. The detection rate (24/53 ≈ 45%) cannot be improved locally without restoring these cards.

**Risco:** P1 — Data pipeline regression silently degrades all downstream analysis (scout, validator, optimizer, mulligan tester, battle analyst).

**Acao recomendada:**
1. **Create post-sync integrity check:** After `sync_pg_target_deck_to_hermes.py` completes, verify all 53 GC names exist in `card_oracle_cache`. Log warning to a dedicated alert file (e.g., `GC_SYNC_ALERT.md`).
2. **Fix the sync script:** Investigate the 3 causes (banned filter, DFC handling, unknown) and fix to include all legal GCs. Banned cards should still be imported with a `banned=true` flag.
3. **Add DFC normalizer:** Normalize `//` in card names during sync (Tergrid, God of Fright // Tergrid's Lantern).
4. **Hotfix Expropriate:** Insert Expropriate manually via Scryfall API as a temporary measure.

**Validacao:**
```bash
cd docs/hermes-analysis/manaloom-knowledge/scripts
python3 -c "
import sqlite3
c = sqlite3.connect('knowledge.db')
for g in ['expropriate','panoptic mirror','serra\'s sanctum','tergrid','biorhythm','braids','coalition victory']:
    r = c.execute('SELECT COUNT(*) FROM card_oracle_cache WHERE LOWER(name) LIKE ?', [f'%{g}%']).fetchone()[0]
    assert r > 0, f'GC {g} still missing after fix'
print('All 53 GCs present')
"
```

---

### [P1] Quality gate critical roles are archetype-only, not theme-aware

**Conhecimento MTG:** Different Commander themes have vastly different critical role requirements. Examples from THEMES.md (validated against EDHREC live data and commander profiles):

| Theme | Critical Roles | Source |
|:------|:---------------|:-------|
| Goblins | haste_enabler (6-10), ramp (8-11), goblins density (25-38) | Profile Krenko |
| Dragons | ramp (12-16), copy_enabler (5-9), ETB_damage_payoff (5-8) | Profile Miirym |
| Spellslinger | draw (12-16), instants/sorceries (25+) | EDHREC corpus |
| Vampires | vampire_density (24-34), lord/drain_payoffs (7-11), interaction (8-11) | Profile Edgar Markov (46,541 decks) |
| Voltron | protection (8-10), equipment_reducers | EDHREC corpus |
| Aristocrats | sacrifice_outlet, drain_payoff, recursion | EDHREC corpus |

Full documentation in THEMES.md "Metricas Ideais por Tema" (lines 78-125) and validated themes (lines 227-308).

**Evidencia no codigo:** `server/lib/ai/optimization_quality_gate.dart:493-500`:
```dart
Set<String> _criticalRolesForArchetype(String archetype) {
  return switch (archetype.trim().toLowerCase()) {
    'aggro' => {'creature', 'ramp', 'removal', 'protection', 'wipe', 'wincon'},
    'control' => {'removal', 'draw', 'wipe', 'ramp', 'protection', 'wincon'},
    'midrange' => {'removal', 'ramp', 'draw', 'wipe', 'wincon'},
    _ => {'removal', 'ramp', 'wipe', 'wincon'},
  };
}
```
Only 4 patterns. No `detectedTheme` parameter used. The function signature takes `String archetype` only — no theme argument exists.

Additionally, `server/lib/ai/otimizacao.dart:44-49` passes `detectedTheme` as a nullable string that flows through to `optimize_runtime_support.dart` but is never consumed for role enforcement.

**Gap:** The quality gate enforces critical roles by archetype only. When `detectedTheme` is present (e.g., 'goblins', 'spellslinger', 'dragons'), the gate should also enforce theme-specific critical roles. Without this, the optimizer can remove theme-critical pieces (e.g., Goblin Warchief as haste enabler, Arcane Signet as ramp in spellslinger) without the gate flagging it.

**Impacto:** Systematic quality gap for theme-focused decks. Optimization quality varies by theme because the gate doesn't know which roles to protect.

**Risco:** P1 — Migration from codex. The product ships with theme-blind optimization quality enforcement.

**Acao recomendada:** Extend `_criticalRolesForArchetype` to accept optional `String? detectedTheme`. Add theme-critical role mappings derived from THEMES.md validated data:
- `goblins` → add `haste_enabler`
- `spellslinger` → add `draw`, prioritize `instants/sorceries`
- `dragons` → add `ramp`, add `copy_enabler`
- `voltron` → add `protection`, `equipment`
- `aristocrats` → add `sacrifice_outlet`, `drain`
- `enchantress` → add `enchantment` count
- `artifact` → add `artifact` synergy

**Validacao:**
```bash
cd server && dart test test/optimization_quality_gate_test.dart
# Test: goblins deck swapping Goblin Warchief (haste enabler) should be blocked
# Test: spellslinger deck removing draw engine should be blocked
```

---

### [P1] Auto-detection of deck theme from card data does not exist

**Conhecimento MTG:** THEMES.md documents detailed, validated rules for detecting deck themes from card data. Each theme has specific detection thresholds validated against EDHREC live data:

| Theme | Detection Threshold | Source |
|:------|:--------------------|:-------|
| Goblins | 25+ goblins + 5+ haste/untap + 4+ sacrifice | Profile Krenko (4 fontes) |
| Spellslinger | 20+ instants/sorceries + 4+ spell payoffs | EDHREC corpus |
| Enchantress | 15+ enchantments + 4+ enchantress effects | Profile Sythis |
| Artifacts | 20+ artifacts + 4+ artifact payoffs | Profile Urza |
| Vampires | 24-34 vampires + 7-11 lord/drain payoffs | Profile Edgar Markov (46,541 decks) |
| Dragons | 18-24 dragons + 5-9 copy enablers + 5-8 ETB payoffs | Profile Miirym (27k+ decks) |

See THEMES.md lines 129-151 for full detection rules, including the 3-step process (tribal count → mechanic count → confidence score).

**Evidencia no codigo:** `server/lib/ai/otimizacao.dart:44-49` — `detectedTheme` is a nullable `String?` parameter. It flows as a pass-through:
- `otimizacao.dart:44-49` → `otimizacao.dart:254-259` → `optimize_runtime_support.dart` → never computed.
- `optimize_analysis_support.dart:16` — `detectedTheme` is logged as received from the caller.
- `optimize_route_suggestion_filter_support.dart:48-54` — `keepTheme` only protects `coreCards` (user-provided list), does not auto-detect.
- Search for `autoDetectTheme|detectDeckTheme|inferTheme|themeFromDeck` returns **0 results** in `server/lib/ai/`.

Cross-reference with functional tags: `server/lib/ai/functional_card_tags.dart:7-36` defines 28 functional tags including `spellslinger`, `artifact_synergy`, `enchantment_synergy`, `graveyard_synergy`, `token_maker`, `sacrifice_outlet`, `aristocrat_payoff`, `drain` — all can serve as theme detection signals but are not aggregated into a theme detection function.

**Gap:** The code treats `detectedTheme` as user input. There is no function that analyzes a decklist and determines its theme(s) programmatically. The `THEMES.md` knowledge documents specific detection heuristics that are not implemented anywhere.

**Impacto:** The optimizer cannot:
1. Adapt swap suggestions to theme-specific requirements (no theme-critical role enforcement)
2. Warn when a deck has insufficient theme enablers (e.g., 15 goblins instead of 25+)
3. Score swaps for "theme purity" (as noted in THEMES.md line 182)
4. Automatically populate `keepTheme` with theme-relevant cards
5. The `targetArchetype` (aggro/control/midrange) fills part of this gap at the archetype level, but themes operate at a finer granularity

**Risco:** P1 — Migration from codex. The product ships with theme-blind optimization.

**Acao recomendada:** Create a new module `server/lib/ai/theme_detection_service.dart` that:
1. Takes `List<Map<String, dynamic>>` cards and computes theme scores using the heuristics from THEMES.md lines 130-151
2. Returns a `DetectedTheme` result with `primaryTheme`, `secondaryTheme`, `confidence` and `signals`
3. Integrates into `otimizacao.dart`'s pre-processing step before filler loading
4. Populates `detectedTheme` automatically when user doesn't provide it
5. Feeds theme-specific `coreCards` into `keepTheme` logic
6. Uses existing functional tags (`spellslinger`, `artifact_synergy`, `token_maker`, etc.) as detection signals where available

**Validacao:**
```bash
cd server && dart test test/optimization_pipeline_integration_test.dart test/ai_optimize_flow_test.dart
# Test: goblins deck with 28 goblins → detectedTheme = 'goblins' (confidence high)
# Test: spellslinger deck with 25 instants/sorceries → detectedTheme = 'spellslinger'
# Test: generic goodstuff deck → detectedTheme = null (confidence low)
```

---

## Appendix: Prior tasks superseded

The following tasks from the 2026-06-12 synthesis were evaluated against current code and superseded by higher-priority findings in this run:

| Old Task | Priority | Reason for replacement |
|:---------|:--------:|:-----------------------|
| `_knownValueEngineNames` only 5 entries | P1 | Superseded by broader gap: 12+ official GCs missing from the entire GC list (P1 task #1 above). The value-engine gap is a subset. Fixing the GC list will automatically fix the value engine gap. |
| Stax detection misses common pieces | P2 | Downgraded: still valid but lower priority than the P1 GC list gap which affects 12+ cards. Stax expansion is P2 refinement. |
| No theme-specific profile validation | P2 | Partial overlap with task #4 (quality gate theme-aware) — both are about theme-specific thresholds. Kept the broader P1 version. |
