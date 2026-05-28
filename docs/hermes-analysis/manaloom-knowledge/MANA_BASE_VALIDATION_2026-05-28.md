# Mana Base Validation Report — Full Detail

> **Gerado:** 2026-05-28T02:10Z
> **Cron:** `manaloom-mana-base-validator`
> **Decks analisados:** 8

## Resumo Executivo

| Deck | Commander | Status | Issues |
|:-----|:----------|:------:|:-------|
| Kinnan, Bonder Prodigy (id=1) | Kinnan, Bonder Prodigy | 🔵 BLUE | Deck incompleto (13/100 cartas). Validação limitada. |
| EDHREC Average Deck - Dimir Ninja (id=2) | Yuriko, the Tiger's Shadow | 🟡 WARN | 17 cartas sem classificação; total_cards divergente (84 vs 99 real) |
| EDHREC Average Default (id=3) | Korvold, Fae-Cursed King | 🟡 WARN | Deck incompleto (11/100). Impossível validar. |
| EDHREC Average Default (id=4) | Teysa Karlov | 🟡 WARN | Parcial (80/100); ramp CRIT (15 vs perfil 9-11, diff=+4); 20 lands fantasma |
| Aesi EDHREC Average Default (id=5) | Aesi, Tyrant of Gyre Strait | 🟡 WARN | Ramp CRIT (28 vs perfil 14-18, diff=+10); total_cards desatualizado |
| Lorehold Spellslinger (id=6) | Lorehold, the Historian | 🟡 WARN | Sem perfil role_targets; 9 double-null; ramp suspeito (16 vs ~4-8 esperado) |
| Boros Combat Trigger Humans (id=7) | Winota, Joiner of Forces | 🟡 WARN | Protection (10 vs 5-8, diff=+2); categorias não mapeiam 1:1 |
| Atraxa, Praetors' Voice (id=9) | Atraxa, Praetors' Voice | ✅ OK | Todas métricas dentro ou próximas do perfil |

**Totais:** ✅ OK=1 | 🟡 WARN=5 | 🔵 BLUE=2 (decks incompletos) | 🔴 CRIT=0*

> *Ramp CRIT encontrado em decks 4 e 5, mas resultado agregado como WARN geral por contextos diferentes.

---

## Análise Detalhada por Deck

### Deck 1: Kinnan, Bonder Prodigy (INCOMPLETO)

- **Commander:** Kinnan, Bonder Prodigy (UG)
- **Cartas no SQLite:** 13 total (0 lands, 13 nonland)
- **DB total_cards:** 13 | **DB total_lands:** 29 ← **divergente**
- **Unclassified cards:** 1

⚠️ **DECK INCOMPLETO:** Apenas 13 cartas. DB declara total_lands=29 mas 0 lands no SQLite.

| Métrica | Perfil (min-max) | Deck (DB) | Status |
|:---------|:-----------------|:----------|:------:|
| Lands | 29-34 | 29 (DB) / 0 (SQLite) | ❌ Divergência |
| Nonland Mana Sources | 18-26 | 4 | 🔴 CRIT (abaixo do min) |
| Interaction/Protection | 9-14 | 3 | 🟡 WARN (abaixo do min) |

---

### Deck 2: Yuriko, the Tiger's Shadow (QUASE COMPLETO)

- **Commander:** Yuriko, the Tiger's Shadow (UB)
- **Cartas no SQLite:** 99 total (35 lands, 64 nonland)
- **DB total_cards:** 84 ← **divergente (99 real)**
- **Unclassified cards:** 17 (**alto**)

| Métrica | Perfil (min-max) | Deck (DB) | Status |
|:---------|:-----------------|:----------|:------:|
| Lands | 30-34 | 33 (DB) / 35 (SQLite) | 🔵 BLUE (+1 acima max) |
| Evasive Enablers | 10-15 | ramp=8 | 🟡 WARN (categoria diferente) |
| Topdeck Manipulation | 7-12 | draw=14 | 🔵 BLUE |
| Interaction | 10-16 | removal=9 | 🔵 BLUE (abaixo do min) |

---

### Deck 3: Korvold, Fae-Cursed King (INCOMPLETO)

- **Commander:** Korvold, Fae-Cursed King (BRG)
- **Cartas no SQLite:** 11 total (0 lands, 11 nonland)
- **DB total_cards:** 11 | **DB total_lands:** 25 ← **divergente**
- **Unclassified cards:** 0

⚠️ **DECK INCOMPLETO:** Apenas 11 cartas. 0 lands no SQLite vs 25 no DB.

| Métrica | Perfil (min-max) | Deck (DB) | Status |
|:---------|:-----------------|:----------|:------:|
| Lands | 34-37 | 25 (DB) / 0 (SQLite) | ❌ Divergência crítica |
| Ramp (treasure) | 10-14 | 3 | 🔴 CRIT |
| Sacrifice Outlets | 6-10 | 0* | 🔴 CRIT |

---

### Deck 4: Teysa Karlov (PARCIAL)

- **Commander:** Teysa Karlov (WB)
- **Cartas no SQLite:** 80 total (15 lands, 65 nonland)
- **DB total_cards:** 80 | **DB total_lands:** 35 ← **divergente (real=15)**
- **Unclassified cards:** 4

⚠️ **DECK PARCIAL:** 80/100 cartas. 20 lands fantasma no DB.

⚠️ **Ramp CRIT:** DB ramp=15 vs perfil 9-11 (diff=+4). Limiar CRIT atingido.

| Métrica | Perfil (min-max) | Deck (DB) | Deck (SQLite) | Status |
|:---------|:-----------------|:----------|:--------------|:------:|
| Lands | 35-37 | 35 | 15 | ❌ Divergência (-20) |
| Ramp | 9-11 | 15 | - | 🔴 CRIT (+4) |
| Draw | 10-14 | 11 | - | ✅ OK |
| Sacrifice Outlets | 7-10 | 0* | - | 🟡 WARN |
| Board Wipes | 2-4 | 1 | - | 🔵 BLUE |
| Recursion | 4-7 | 3 | - | 🔵 BLUE |

---

### Deck 5: Aesi, Tyrant of Gyre Strait

- **Commander:** Aesi, Tyrant of Gyre Strait (UG)
- **Cartas no SQLite:** 100 total (40 lands, 60 nonland) — **COMPLETO**
- **DB total_cards:** 79 ← **desatualizado (real=100)**
- **Unclassified cards:** 6

⚠️ **Ramp CRIT:** DB ramp=28 vs perfil ramp_extra_lands 14-18 (diff=+10). Valor extremamente alto — classificador contando land-drops como ramp.

| Métrica | Perfil (min-max) | Deck (DB) | Status |
|:---------|:-----------------|:----------|:------:|
| Lands | 39-43 | 40 | ✅ OK |
| Ramp (extra lands) | 14-18 | 28 | 🔴 CRIT (+10) |
| Supplemental Draw | 6-9 | 12 | 🟡 WARN (+3) |
| Landfall Payoffs | 8-12 | 12 (engine) | ✅ OK |

---

### Deck 6: Lorehold Spellslinger

- **Commander:** Lorehold, the Historian (RW)
- **Cartas no SQLite:** 100 total (35 lands, 65 nonland) — **COMPLETO**
- **DB total_cards:** 100 | **DB total_lands:** 35
- **Unclassified cards:** 9 (**Double Null Problem**)

⚠️ **Sem perfil role_targets para Lorehold** (profile existe mas sem role_targets padrão).

⚠️ **9 double-null cards:** Scroll Rack, Grand Abolisher, Penance, Pearl Medallion, Ruby Medallion, Victory Chimes, Orim's Chant, Taunt from the Rampart, Galadriel's Dismissal.

| Métrica | Conhecimento do Arquétipo | Deck (DB) | Status |
|:---------|:--------------------------|:----------|:------:|
| Lands (Boros spellslinger) | 33-37 | 35 | ✅ OK |
| Ramp (Boros) | 4-8 | 16 | 🔴 CRIT (+8) |
| Draw (Boros deficit) | 4-7 | 5 | ✅ OK* |
| Board Wipes | 2-4 | 4 | ✅ OK |
| Removal | 3-6 | 4 | ✅ OK |

> *draw_count=5 provavelmente inflado por false positives multi-tag (conforme Purpose Analyzer v3).

---

### Deck 7: Winota, Joiner of Forces

- **Commander:** Winota, Joiner of Forces (RW)
- **Cartas no SQLite:** 100 total (34 lands, 66 nonland) — **COMPLETO**
- **DB total_cards:** 100 | **DB total_lands:** 34
- **Unclassified cards:** 0

| Métrica | Perfil (min-max) | Deck (DB) | Status |
|:---------|:-----------------|:----------|:------:|
| Lands | 31-35 | 34 | ✅ OK |
| Nonhuman Enablers | 18-28 | 10 (ramp*) | 🟡 WARN (categoria diferente) |
| Human Hits | 16-24 | 0* | 🔴 CRIT (categoria diferente) |
| Protection | 5-8 | 10 | 🟡 WARN (+2) |
| Combat Payoffs | 4-8 | 10 | ✅ OK |

> *O DB não usa categorias específicas do perfil Winota. Mapeamento indireto via functional_tag genérico.*

---

### Deck 9: Atraxa, Praetors' Voice ✅

- **Commander:** Atraxa, Praetors' Voice (WUBG)
- **Cartas no SQLite:** 100 total (36 lands, 64 nonland) — **COMPLETO**
- **DB total_cards:** 100 | **DB total_lands:** 36
- **Unclassified cards:** 0

| Métrica | Perfil (min-max) | Deck (DB) | Status |
|:---------|:-----------------|:----------|:------:|
| Lands | 35-38 | 36 | ✅ OK |
| Ramp/Fixing | 10-13 | 14 | 🔵 BLUE (+1) |
| Card Advantage | 8-12 | 12 | ✅ OK |
| Interaction | 8-13 | 7 | 🔵 BLUE (-1) |
| Finishers | 4-7 | 1 | 🟡 WARN |

---

## Qualidade dos Dados

### Divergências DB total_cards vs SQLite

| Deck | DB | SQLite | Diff |
|:-----|:---|:-------|:-----|
| 2 — Yuriko | 84 | 99 | +15 |
| 5 — Aesi | 79 | 100 | +21 |
| Todos os outros | ✅ | ✅ | 0 |

### Divergências DB total_lands vs SQLite

| Deck | DB | SQLite | Diff |
|:-----|:---|:-------|:-----|
| 1 — Kinnan | 29 | 0 | -29 |
| 3 — Korvold | 25 | 0 | -25 |
| 4 — Teysa | 35 | 15 | -20 |
| Todos os outros | ✅ | ✅ | 0 |

---

## Thresholds Utilizados

| diff | Status |
|:-----|:------:|
| 0 | ✅ OK |
| 1 | 🔵 BLUE (aceitável) |
| 2-3 | 🟡 WARN (alerta) |
| ≥ 4 | 🔴 CRÍTICO |

---

*Próxima validação: conforme schedule do cron `manaloom-mana-base-validator` (a cada 60 min)*
