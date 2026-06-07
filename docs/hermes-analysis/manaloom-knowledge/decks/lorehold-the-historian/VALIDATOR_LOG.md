# Lorehold Validator — Purpose Analyzer v3.25 (Reconfirmação + Resolução de Classificador)

**Data:** 2026-06-03T23:00:00+00:00
**Deck:** Lorehold Best-of Learned No Premium Mox 2026-06-02 (id=6)
**Archetype:** fast-mana-copy-combo-big-spells-no-premium-mox
**Card Hash:** `8b9c643c84825a4436d33b7f1616fa5f` ← ALTERADO (v3.24: `f2241d994743e8142396c0f846917fde`)
**Hash anterior:** `f2241d994743e8142396c0f846917fde` (v3.24, 2026-06-02T22:00)
**Delta hash:** 🔴 **MUDOU** — deck foi modificado externamente entre v3.24 e v3.25

---

## ✅ STEP 0: Pipeline Integrity Check (Hash Verification)

```
SELECT card_name FROM deck_cards WHERE deck_id=6 ORDER BY card_name
→ MD5: 8b9c643c84825a4436d33b7f1616fa5f

v3.24 hash: f2241d994743e8142396c0f846917fde
→ HASH DIVERGENTE. Deck foi alterado externamente.
→ Logs anteriores (v3.24) são STALE.
→ Métricas recalculadas DO ZERO a partir do DB.
```

---

## ✅ CORREÇÃO v3.24 → v3.25: Banlist

**v3.24 afirmou:** Worldfire está BANIDO em Commander.
**Realidade (PG + Scryfall):** Worldfire é `commander=legal`.

**Errata v3.24:** O banlist check da v3.24 usou memória de modelo (desatualizada). A fonte de verdade é `card_legalities` sincronizada do PostgreSQL. Worldfire foi banida em 2013 e desbanida em 2017. O modelo "lembrou" do estado pré-2017.

**0 cartas banidas** no deck atual. Validação de legalidade: ✅ LIMPO.

---

## ✅ CORREÇÃO v3.24 → v3.25: Classificador Resolvido

**v3.24:** 20 cartas com `functional_tag='unknown'` — classificador nunca executou.
**v3.25:** Apenas **3 cartas** com `functional_tag='unknown'` (↓ 85%)

**17 cartas reclassificadas:** 5 Moxen, Sol Ring, Mana Vault, Boros Signet, Talisman, Rite of Flame, Seething Song, Mana Geyser, Jeska's Will, Grand Abolisher, Drannith Magistrate → todos com tags corretas.

**Ramp tag count:** 6 (v3.24) → **19** (v3.25). Classificador funcional.
**0 double-nulls.**

---

## 📊 Deck State — Métricas Reais

| Métrica | DB Tag Count | PG Ideal (spellslinger) | Delta | Flag |
|:--------|:------------:|:-----------------------:|:-----:|:----:|
| Lands | 31 | 32 | -1 | 🔵 OK |
| Ramp | 19 | 3.67 | +15.33 | 🔴 CRIT* |
| Ritual/Treasure | 7 | 10 | -3 | 🟡 WARN |
| Big Spell Payoff | 8 (CMC≥6) | 7.67 | +0.33 | ✅ OK |
| Miracle/Topdeck | 4 | 4.33 | -0.33 | ✅ OK |
| Removal | 3 | 5.33 | -2.33 | 🟡 WARN |
| Protection | 10 | 3.67 | +6.33 | 🔴 CRIT* |
| Draw/Value | 9 | 2.67 | +6.33 | 🔴 CRIT* |
| Tutor | 5 | 3.67 | +1.33 | 🔵 OK |
| Win Condition | 10 | 1.33 | +8.67 | 🔴 CRIT* |

*CRITs são devido à mudança de arquétipo (spellslinger → cEDH combo), não problemas reais.

⚠️ O perfil PG foi construído para spellslinger. O deck atual é cEDH fast-mana-combo.

---

## 🎯 Game Changer Analysis

**11 Game Changers:** Ancient Tomb, Chrome Mox, Mox Diamond, Mox Opal, Mana Vault, The One Ring, Urza's Saga, Enlightened Tutor, Gamble, Drannith Magistrate, Gemstone Caverns.

→ **Bracket 4 (cEDH)** — máximo B3 = 3 GCs.

---

## 🔍 SYNERGY_MAP — 7 Eixos

| Axis | Score | Key Finding |
|:-----|:-----:|:------------|
| A) Token Makers + Pump | 4/10 | Weak token strategy |
| B) Board Wipes + Protection | 6/10 | 10 protection, only 1 wipe |
| C) Recursion Chains | 5/10 | Strong spell recursion, no permanent |
| D) Explosive Mana | 9/10 | 5 Moxen + Sol Ring + Mana Vault |
| E) Combo Pieces | 8/10 | 5 combos, Approach+Topdeck best |
| F) Stack Interaction | 7/10 | Strong for Boros, no universal counter |
| G) Resilience | 6/10 | CMC 5 commander vulnerable |

---

## 🧠 Motor cEDH: 5/5 COMPLETO

Fast Mana (8+ fontes T1) → Tutor (5) → Combo (5 linhas) → Proteção (5 slots) → Recursion (Past in Flames + Mizzix's)

---

## 🔴 PROBLEMAS

1. **Bracket Mismatch** — 11 GCs = Bracket 4, não Bracket 3
2. **1 Board Wipe** — só Blasphemous Act
3. **3 Unknown Tags** — Inventors' Fair, Prismatic Vista, Reforge the Soul
4. **CMC 5 Commander** — vulnerável a remoção repetida

---

## 🎯 TOP 5 SWAPS (cEDH otimization, NOT PG profile)

1. Rite of the Dragoncaller → Underworld Breach (ΔCMC -4, score 9)
2. Storm Herd → Dockside Extortionist (ΔCMC -8, score 10)
3. Rise of the Eldrazi → Emrakul, the Promised End (ΔCMC +3, score 7) *only if T3<8%*
4. Rite of the Dragoncaller → Skullclamp (ΔCMC -5, score 9)
5. Land Tax → Talisman of Hierarchy (ΔCMC +1, score 5) *sidegrade*

---

## 📊 NOVIDADES v3.25

1. ✅ Hash alterado — deck modificado
2. ✅ Worldfire é LEGAL (correção v3.24)
3. ✅ Classificador resolvido — 20→3 unknown (85%)
4. ✅ Ramp classificado — 6→19 tags
5. ✅ 0 double-nulls, 0 banned
6. 🔴 11 Game Changers — Bracket 4
7. 🟡 Archetype mismatch — perfil PG inaplicável

---

*Full details: VALIDATOR_LOG_v3.25.md*
*Próximo (v3.26): verificar hash, refazer SYNERGY_MAP se alterado, fetch EDHREC, considerar novo perfil PG cEDH.*
