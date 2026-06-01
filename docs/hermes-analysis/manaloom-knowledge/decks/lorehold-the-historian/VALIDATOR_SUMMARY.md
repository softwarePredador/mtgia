# Lorehold Spellslinger — Executive Summary (v3.19 + C#23)

> **Data:** 2026-06-01T08:23Z | **Hash:** `30d00347764fc2a215edb4e668994871`
> **Status:** 🚨 DECK MUDOU desde v3.17. Pipeline integrity quebrado por 5 ciclos.
> **Ciclo atual:** C#23 — 2 SWAPS DEFENSIVOS RECOMENDADOS

## PG Reference Profile Comparison

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

## SYNERGY_MAP 7 Eixos

| Eixo | Score |
|:-----|:-----:|
| A) Token + Pump | 7/10 |
| B) Wipes + Protection | 8/10 |
| C) Recursion | 7/10 |
| D) Explosive Mana | 9/10 |
| E) Combo Pieces | 8/10 |
| F) Stack Interaction | 5/10 |
| G) Resilience | 8/10 |
| **MEDIA** | **7.4/10** |

## Mudancas vs C#17

- **8 cartas removidas:** Ashling, Austere Command, Demand Answers, Flare of Duplication, Surge to Victory, Thrill of Possibility, Twinflame, Weathered Wayfarer
- **5 cartas adicionadas:** Dualcaster Mage, Fellwar Stone, Flawless Maneuver, Primal Amulet, Valakut Awakening
- **Manabase refeita:** 8 fetches + utility lands (Ancient Tomb, Boseiju, Cavern, Kor Haven)
- **T3 piorou: 11.3% → 13.3%** (Exec#13, N=1000, seed=42)

## C#23 Swaps Recomendados (DEFENSIVO, net ΔCMC = -16)

| # | OUT | CMC | IN | CMC | ΔCMC |
|:-:|:-----|:---:|:----|:---:|:----:|
| 1 | Apex of Power | 10 | Demand Answers | 2 | -8 |
| 2 | Storm Herd | 10 | Thrill of Possibility | 2 | -8 |
| **Total** | | | | | **-16** |

**T3 projetado pos-C#23: ~9-10%** (BALANCED).

## Gaps Prioritarios

1. **🔴 tutor -1.7** — Aquisicao: Idyllic Tutor ($15-20). Unico gap real.
2. **🟡 exile_value -1.7** — Capstone + Dance cobrem. Monitorar.
3. **🟡 stack interaction 5/10** — Flare perdida. Dualcaster ajuda.
4. **🟢 Valakut duplicado** — Corrigir DB (2 rows MDFC).

## Checklist

| Item | Status |
|:-----|:------:|
| 100 cartas | ✅ |
| 35 lands | ✅ |
| Motor 4/4 | ✅ |
| Copy engines 7 | ✅ |
| **T3 Sem Play** | **13.3% → 🔴 DEFENSIVO** |
| **Estrategia C#23** | **DEFENSIVO (2 swaps)** |
| Pipeline Integrity | 🚨 Quebrado 5 ciclos — Corrigido C#23 |
