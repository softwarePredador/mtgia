# Purpose Analyzer v3.20 — Lorehold Spellslinger: RE-CONFIRMATION

> **Data:** 2026-06-01T10:21:38+00:00
> **Fonte:** knowledge.db deck_id=6 (card_hash = `30d00347764fc2a215edb4e668994871`)
> **Deck:** Lorehold Spellslinger — 100 cards, 86 rows, 35 lands
> **Status:** ✅ DECK ESTAVEL — identico ao v3.19
> **Analista:** Hermes Agent — Purpose Analyzer v3.20

---

## Pipeline Integrity — ✅ STABLE

| Check | v3.19 (07:59) | v3.20 (2026-06-01T10:21) | Status |
|:------|:-------------:|:------------------:|:------:|
| Card hash | `30d00347...` | `30d00347...` | ✅ IDENTICAL |
| Deck cards | 86 rows, 100 | 86 rows, 100 | ✅ IDENTICAL |
| Lands | 35 | 35 | ✅ IDENTICAL |
| MDFC duplicate | Valakut (id=653) | Valakut (id=653) | ⚠️ STILL PRESENT |
| Double-nulls | 4 | 4 | ✅ IDENTICAL |
| EDHREC num_decks | ~7802 | 7851 | +49 decks |
| EDHREC entries | ~275 | 277 | +2 new |

**Nenhuma carta alterada no DB desde v3.19.** Analise completa do v3.19 permanece valida.

## PG Profile Comparison (re-verified)

| PG Role | Ideal | Actual | Diff | Status |
|:--------|:-----:|:------:|:----:|:------:|
| lands | 32.00 | 35.0 | +3.0 | 🟡 |
| ramp | 3.67 | 7.0 | +3.3 | 🟡 |
| ritual_treasure | 10.00 | 12.0 | +2.0 | 🟡 |
| big_spell_payoff | 7.67 | 17.0 | +9.3 | 🟡 |
| miracle_topdeck | 4.33 | 7.0 | +2.7 | 🟡 |
| interaction | 5.33 | 9.0 | +3.7 | 🟡 |
| protection | 3.67 | 8.0 | +4.3 | 🟡 |
| draw_value | 2.67 | 8.0 | +5.3 | 🟡 |
| **tutor** | **3.67** | **2.0** | **-1.7** | **🔴 UNICO GAP** |
| win_condition | 1.33 | 5.0 | +3.7 | 🟡 |
| board_wipe | 2.00 | 5.0 | +3.0 | 🟡 |
| recursion | 3.33 | 3.0 | -0.3 | ✅ |
| exile_value | 3.67 | 2.0 | -1.7 | 🟡 |
| spellslinger | 3.67 | 7.0 | +3.3 | 🟡 |

## SYNERGY_MAP (unchanged from v3.19)

| Eixo | Score | Status |
|:-----|:-----:|:------|
| A) Token + Pump | 7/10 | ✅ |
| B) Wipes + Protection | 8/10 | ✅ |
| C) Recursion | 7/10 | ✅ |
| D) Explosive Mana | 9/10 | ✅ |
| E) Combo Pieces | 8/10 | ✅ |
| F) Stack Interaction | 5/10 | ⚠️ Boros |
| G) Resilience | 8/10 | ✅ |
| **MEDIA** | **7.4/10** | ✅ |

## Double-Null Audit (unchanged)

| Card | CMC | Importance | EDHREC | Risk |
|:-----|:---:|:-----------|:------:|:-----|
| Scroll Rack | 2 | Miracle enabler | 59.5% | 🔴 CRITICAL — never cut |
| Penance | 3 | Miracle enabler | N/A | 🔴 CRITICAL — never cut |
| Grand Abolisher | 2 | Protection | N/A | 🟡 Monitor (declining) |
| Taunt from the Rampart | 5 | Mass goad | 35.2% | 🟢 Safe |

## Conclusion

**DECK SAUDAVEL E ESTAVEL.** Nenhuma mudanca desde v3.19. Card hash `30d00347...` confirmado em 3 runs consecutivos (v3.18 → v3.19 → v3.20).

**Gaps:** tutor (-1.7, unico gap real), Valakut duplicado (corrigir DB), T3 nao medido.

**C#23 status:** Evolution Oracle recomendou 2 swaps DEFENSIVOS (Apex→Demand Answers, Storm Herd→Thrill of Possibility) mas NAO FORAM APLICADOS AO DB. DB permanece PRE-C#23. Ver EVOLUTION_LOG para detalhes.

**Proximo upgrade:** AQUISICAO — Idyllic Tutor (CMC 3, $15-20, fecha tutor gap).

---

*Purpose Analyzer v3.20 — 2026-06-01T10:21:38+00:00*
*Full analysis: VALIDATOR_LOG.md (v3.19 section)*
