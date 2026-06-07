# Mana Base Validation Report — Full Detail

> **Data:** 2026-05-28T04:51Z
> **Cron:** `manaloom-mana-base-validator`
> **Decks analisados:** 8

## Resumo

| Deck | Commander | Status | Total Cards | DB Lands | SQLite Lands | Profile Range | Issues |
|------|-----------|--------|-------------|----------|--------------|---------------|--------|
| 1 — Kinnan, Bonder Prodigy | Kinnan, Bonder Pro | 🔴 CRIT | 13 | 29 | 0 | 29-34 | lands 🔴 CRIT (0 vs 29-34); mana_dorks 🔴 CRIT (4 vs 10-16); interaction_protection 🔴 CRIT (3 vs 9-14) |
| 2 — EDHREC Average Deck - Dimir Ni | Yuriko, the Tiger' | 🟡 WARN | 99 | 33 | 35 | 30-34 | lands 🔵 BLUE (35 vs 30-34); interaction 🔵 BLUE (9 vs 10-16); Total Cards 🟡 WARN (99/100) |
| 3 — EDHREC Average Default | Korvold, Fae-Curse | 🔴 CRIT | 11 | 25 | 0 | 34-37 | lands 🔴 CRIT (0 vs 34-37); ramp_treasure 🔴 CRIT (3 vs 10-14); draw_value 🔴 CRIT (1 vs 6-10) |
| 4 — EDHREC Average Default | Teysa Karlov | 🔴 CRIT | 80 | 35 | 15 | 35-37 | lands 🔴 CRIT (15 vs 35-37); ramp 🔴 CRIT (15 vs 9-11); recursion 🔵 BLUE (3 vs 4-7) |
| 5 — Aesi EDHREC Average Default | Aesi, Tyrant of Gy | 🔴 CRIT | 100 | 40 | 40 | 39-43 | ramp_extra_lands 🔴 CRIT (28 vs 14-18); supplemental_draw 🟡 WARN (12 vs 6-9); protection 🟡 WARN (7 vs 2-4) |
| 6 — Lorehold Spellslinger | Lorehold, the Hist | ✅ OK | 100 | 35 | 35 | N/A | (sem perfil de referência) |
| 7 — EDHREC Average Default | Winota, Joiner of  | 🟡 WARN | 100 | 34 | 34 | 31-35 | protection 🟡 WARN (10 vs 5-8) |
| 9 — Atraxa, Praetors' Voice | Atraxa, Praetors'  | 🟡 WARN | 100 | 36 | 36 | 35-38 | ramp_fixing 🔵 BLUE (14 vs 10-13); counter_payoffs 🔵 BLUE (7 vs 8-14); interaction 🔵 BLUE (7 vs 8-13) |

### Contadores
- ✅ OK: 1
- 🔵 BLUE: 0
- 🟡 WARN: 3
- 🔴 CRIT: 4

## Análise Detalhada por Deck

### Deck 1: Kinnan, Bonder Prodigy
- **Commander:** Kinnan, Bonder Prodigy
- **Status:** 🔴 CRIT
- **Total cards (SQLite):** 13
- **Total cards (DB):** 13
- **Lands (DB):** 29 | **Lands (SQLite):** 0
- **Role Targets:**
  - 🔴 `lands` (lands): 0 vs [29-34] (diff=29)
  - 🔴 `mana_dorks` (mana_dorks): 4 vs [10-16] (diff=6)
  - 🔴 `interaction_protection` (interaction_protection): 3 vs [9-14] (diff=6)
- **Issues:**
  - lands 🔴 CRIT (0 vs 29-34)
  - mana_dorks 🔴 CRIT (4 vs 10-16)
  - interaction_protection 🔴 CRIT (3 vs 9-14)
  - Total Cards 🔴 CRIT (13/100)
  - Lands DB vs SQLite 🔴 CRIT (DB=29, SQLite=0, Diff=-29)

### Deck 2: EDHREC Average Deck - Dimir Ninja Topdeck Tempo
- **Commander:** Yuriko, the Tiger's Shadow
- **Status:** 🟡 WARN
- **Total cards (SQLite):** 99
- **Total cards (DB):** 84
- **Lands (DB):** 33 | **Lands (SQLite):** 35
- **Role Targets:**
  - 🔵 `lands` (lands): 35 vs [30-34] (diff=1)
  - 🔵 `interaction` (interaction): 9 vs [10-16] (diff=1)
- **Issues:**
  - lands 🔵 BLUE (35 vs 30-34)
  - interaction 🔵 BLUE (9 vs 10-16)
  - Total Cards 🟡 WARN (99/100)
  - Lands DB vs SQLite 🟡 WARN (DB=33, SQLite=35, Diff=2)

### Deck 3: EDHREC Average Default
- **Commander:** Korvold, Fae-Cursed King
- **Status:** 🔴 CRIT
- **Total cards (SQLite):** 11
- **Total cards (DB):** 11
- **Lands (DB):** 25 | **Lands (SQLite):** 0
- **Role Targets:**
  - 🔴 `lands` (lands): 0 vs [34-37] (diff=34)
  - 🔴 `ramp_treasure` (ramp_treasure): 3 vs [10-14] (diff=7)
  - 🔴 `draw_value` (draw_value): 1 vs [6-10] (diff=5)
  - 🔴 `interaction` (interaction): 1 vs [8-12] (diff=7)
- **Issues:**
  - lands 🔴 CRIT (0 vs 34-37)
  - ramp_treasure 🔴 CRIT (3 vs 10-14)
  - draw_value 🔴 CRIT (1 vs 6-10)
  - interaction 🔴 CRIT (1 vs 8-12)
  - Total Cards 🔴 CRIT (11/100)
  - Lands DB vs SQLite 🔴 CRIT (DB=25, SQLite=0, Diff=-25)

### Deck 4: EDHREC Average Default
- **Commander:** Teysa Karlov
- **Status:** 🔴 CRIT
- **Total cards (SQLite):** 80
- **Total cards (DB):** 80
- **Lands (DB):** 35 | **Lands (SQLite):** 15
- **Role Targets:**
  - 🔴 `lands` (lands): 15 vs [35-37] (diff=20)
  - 🔴 `ramp` (ramp): 15 vs [9-11] (diff=4)
  - ✅ `draw_value` (draw_value): 11 vs [10-14] (diff=0)
  - ✅ `interaction` (interaction): 8 vs [8-11] (diff=0)
  - ✅ `protection` (protection): 3 vs [2-4] (diff=0)
  - 🔵 `recursion` (recursion): 3 vs [4-7] (diff=1)
- **Issues:**
  - lands 🔴 CRIT (15 vs 35-37)
  - ramp 🔴 CRIT (15 vs 9-11)
  - recursion 🔵 BLUE (3 vs 4-7)
  - Total Cards 🔴 CRIT (80/100)
  - Lands DB vs SQLite 🔴 CRIT (DB=35, SQLite=15, Diff=-20)

### Deck 5: Aesi EDHREC Average Default
- **Commander:** Aesi, Tyrant of Gyre Strait
- **Status:** 🔴 CRIT
- **Total cards (SQLite):** 100
- **Total cards (DB):** 79
- **Lands (DB):** 40 | **Lands (SQLite):** 40
- **Role Targets:**
  - ✅ `lands` (lands): 40 vs [39-43] (diff=0)
  - 🔴 `ramp_extra_lands` (ramp_extra_lands): 28 vs [14-18] (diff=10)
  - 🟡 `supplemental_draw` (supplemental_draw): 12 vs [6-9] (diff=3)
  - 🟡 `protection` (protection): 7 vs [2-4] (diff=3)
  - 🟡 `finishers` (finishers): 0 vs [3-5] (diff=3)
- **Issues:**
  - ramp_extra_lands 🔴 CRIT (28 vs 14-18)
  - supplemental_draw 🟡 WARN (12 vs 6-9)
  - protection 🟡 WARN (7 vs 2-4)
  - finishers 🟡 WARN (0 vs 3-5)

### Deck 6: Lorehold Spellslinger
- **Commander:** Lorehold, the Historian
- **Status:** ✅ OK
- **Total cards (SQLite):** 100
- **Total cards (DB):** 100
- **Lands (DB):** 35 | **Lands (SQLite):** 35
- **Issues:**
  - (sem perfil de referência)

### Deck 7: EDHREC Average Default — Boros Combat Trigger Humans
- **Commander:** Winota, Joiner of Forces
- **Status:** 🟡 WARN
- **Total cards (SQLite):** 100
- **Total cards (DB):** 100
- **Lands (DB):** 34 | **Lands (SQLite):** 34
- **Role Targets:**
  - ✅ `lands` (lands): 34 vs [31-35] (diff=0)
  - 🟡 `protection` (protection): 10 vs [5-8] (diff=2)
  - ✅ `interaction` (interaction): 8 vs [6-10] (diff=0)
- **Issues:**
  - protection 🟡 WARN (10 vs 5-8)

### Deck 9: Atraxa, Praetors' Voice — EDHREC Average (41k decks)
- **Commander:** Atraxa, Praetors' Voice
- **Status:** 🟡 WARN
- **Total cards (SQLite):** 100
- **Total cards (DB):** 100
- **Lands (DB):** 36 | **Lands (SQLite):** 36
- **Role Targets:**
  - ✅ `lands` (lands): 36 vs [35-38] (diff=0)
  - 🔵 `ramp_fixing` (ramp_fixing): 14 vs [10-13] (diff=1)
  - ✅ `proliferate_engines` (proliferate_engines): 7 vs [6-10] (diff=0)
  - 🔵 `counter_payoffs` (counter_payoffs): 7 vs [8-14] (diff=1)
  - ✅ `planeswalkers_superfriends` (planeswalkers_superfriends): 7 vs [4-9] (diff=0)
  - ✅ `card_advantage` (card_advantage): 12 vs [8-12] (diff=0)
  - 🔵 `interaction` (interaction): 7 vs [8-13] (diff=1)
  - 🟡 `finishers` (finishers): 1 vs [4-7] (diff=3)
- **Issues:**
  - ramp_fixing 🔵 BLUE (14 vs 10-13)
  - counter_payoffs 🔵 BLUE (7 vs 8-14)
  - interaction 🔵 BLUE (7 vs 8-13)
  - finishers 🟡 WARN (1 vs 4-7)

## Achados Críticos

### Decks com status CRIT (4)
- **Deck 1 (Kinnan, Bonder Prodigy):** lands 🔴 CRIT (0 vs 29-34), mana_dorks 🔴 CRIT (4 vs 10-16), interaction_protection 🔴 CRIT (3 vs 9-14), Total Cards 🔴 CRIT (13/100), Lands DB vs SQLite 🔴 CRIT (DB=29, SQLite=0, Diff=-29)
- **Deck 3 (EDHREC Average Default):** lands 🔴 CRIT (0 vs 34-37), ramp_treasure 🔴 CRIT (3 vs 10-14), draw_value 🔴 CRIT (1 vs 6-10), interaction 🔴 CRIT (1 vs 8-12), Total Cards 🔴 CRIT (11/100), Lands DB vs SQLite 🔴 CRIT (DB=25, SQLite=0, Diff=-25)
- **Deck 4 (EDHREC Average Default):** lands 🔴 CRIT (15 vs 35-37), ramp 🔴 CRIT (15 vs 9-11), recursion 🔵 BLUE (3 vs 4-7), Total Cards 🔴 CRIT (80/100), Lands DB vs SQLite 🔴 CRIT (DB=35, SQLite=15, Diff=-20)
- **Deck 5 (Aesi EDHREC Average Default):** ramp_extra_lands 🔴 CRIT (28 vs 14-18), supplemental_draw 🟡 WARN (12 vs 6-9), protection 🟡 WARN (7 vs 2-4), finishers 🟡 WARN (0 vs 3-5)

### Decks Incompletos (4)
- **Deck 1 (Kinnan, Bonder Prodigy):** 13/100 (87 carta(s) faltando), DB total_cards=13
- **Deck 2 (EDHREC Average Deck - Dimir Ninja Topdeck Tempo):** 99/100 (1 carta(s) faltando), DB total_cards=84
- **Deck 3 (EDHREC Average Default):** 11/100 (89 carta(s) faltando), DB total_cards=11
- **Deck 4 (EDHREC Average Default):** 80/100 (20 carta(s) faltando), DB total_cards=80

### Divergências Lands DB vs SQLite
| Deck | DB total_lands | SQLite lands | Diferença |
|------|----------------|--------------|-----------|
| 1 — Kinnan, Bonder Prodigy | 29 | 0 | ❌ -29 |
| 2 — EDHREC Average Deck - Dim | 33 | 35 | ⚠️ +2 |
| 3 — EDHREC Average Default | 25 | 0 | ❌ -25 |
| 4 — EDHREC Average Default | 35 | 15 | ❌ -20 |

## Mudanças desde última validação (03:25Z)

- **Sem mudanças estruturais**: todos os decks mantêm os mesmos totais de cartas e lands.
- **Decks 1, 3, 4** continuam com dados incompletos nas tabelas (inserts parciais durante import).
- **Deck 2 (Yuriko):** total_cards no DB=84 vs SQLite=99.
- **Deck 5 (Aesi):** ramp_count=ramp_extra_lands reportado como 28 vs perfil 14-18 (CRIT +10 acima).
- **Deck 9 (Atraxa):** finishers=1 vs perfil 4-7 (WARN -3 abaixo) — nova flag desde validação anterior.
- **Nenhum novo deck inserido ou removido**.

---
*Próxima validação: conforme schedule do cron `manaloom-mana-base-validator` (a cada 60 min)*