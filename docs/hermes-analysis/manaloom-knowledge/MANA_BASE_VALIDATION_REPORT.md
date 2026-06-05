# Mana Base Validation Report

> **Data:** 2026-06-05T02:36:49Z
> **Cron:** manaloom-mana-base-validator
> **Decks analisados:** 8
> **Fonte profiles:** commander_reference_profile_anchor30_batch_*_2026-05-12/profiles/*.json

## Resumo Geral

| # | Deck | Cards | Status | Lands | Perfil Lands | Principais Deltas |
|---|------|:-----:|:------:|:-----:|:------------:|-------------------|
| 1 | Kinnan, Bonder Prodigy | 13/100 | INCOMPLETE | -- | -- | Apenas 13 cartas (seed parcial) |
| 2 | EDHREC Average Deck - Dimir Ninja Topdeck Tempo | 99/100 | CRIT* | 31 | 30-34 | interaction=6 vs [10-16] (CRIT d=4) |
| 3 | EDHREC Average Default | 11/100 | INCOMPLETE | -- | -- | Apenas 11 cartas (seed parcial) |
| 4 | EDHREC Average Default | 80/100 | CRIT* | 15 | 35-37 | lands=15 vs [35-37] (CRIT d=20); interaction=7 vs [8-11] (BLUE d=1); draw=8 vs [10-14] (WARN d=2); ramp=15 vs [9-11] (CRIT d=4); recursion=3 vs [4-7] (BLUE d=1) |
| 5 | Aesi EDHREC Average Default | 100/100 | CRIT* | 40 | 39-43 | interaction=6 vs [8-11] (WARN d=2); draw=4 vs [6-9] (WARN d=2); ramp=28 vs [14-18] (CRIT d=10); finishers=0 vs [3-5] (WARN d=3) |
| 6 | Lorehold Best-of Learned No Premium Mox 2026-06-02 | 100/100 | NO PROFILE | 31 | -- | Sem perfil EDHREC | 3 cartas "unknown" |
| 7 | EDHREC Average Default — Boros Combat Trigger Humans | 100/100 | WARN* | 34 | 31-35 | protection=3 vs [5-8] (WARN d=2) |
| 9 | Atraxa, Praetors' Voice — EDHREC Average (41k decks) | 100/100 | CRIT* | 36 | 35-38 | interaction=6 vs [8-13] (WARN d=2); draw=13 vs [8-12] (BLUE d=1); finishers=0 vs [4-7] (CRIT d=4) |

*Legenda: OK | BLUE (d=1) | WARN (d=2-3) | CRIT (d>=4) | INCOMPLETE (<50 cards)*
*\* = EDHREC aggregate parcial — metricas podem ser corpus artifacts, nao decks reais*

## Notas de Interpretacao

1. **Decks INCOMPLETE (<50 cards):** Kinnan (#1, 13 cards) e Korvold (#3, 11 cards) sao seeds parciais — metricas nao acionaveis. Nenhuma mudanca desde a validacao anterior.

2. **Lorehold #6 (NO PROFILE):** Sem perfil EDHREC para este commander. 3/100 cartas com tag "unknown" (Inventors Fair, Prismatic Vista, Reforge the Soul). Deck com 31 lands (tags), 19 ramp, 9 draw, 10 protection, 10 wincon.

3. **Teysa (#4):** 80-card aggregate EDHREC incompleto. `total_lands=35` (coluna `decks`) vs `lands_tag=15` — discrepancia de 20 lands. Perfil espera 35-37 lands, mas apenas 15 cartas tem tag='land'. Falso positivo do aggregate incompleto — basic lands nao foram inseridas como `deck_cards`.

4. **Yuriko (#2):** `interaction=6 vs [10-16]` — CRIT d=4. 99/100 cards (1 short). 21 cartas com functional_tag=None (incluindo Misdirection, Lim-Dul's Vault, Commit//Memory que podem ter funcao de interaction). Tags de interaction sub-representadas.

5. **Atraxa (#9):** `finishers=0 vs [4-7]` — CRIT d=4. Natureza 'goodstuff' de Atraxa — finishers menos definidos em aggregates. `interaction=6 vs [8-13]` — WARN d=2.

6. **Winota (#7):** `protection=3 vs [5-8]` — WARN d=2. Aggregate EDHREC — protecao abaixo do perfil possivelmente por sub-representacao de tags de protecao nos dados do corpus.

7. **Aesi (#5):** `ramp=28 vs [14-18]` — CRIT d=10. Tags de ramp super-representadas no aggregate — inclui land ramp spells, extra land drops, e mana dorks no mesmo bucket `functional_tag='ramp'`. `draw=4 vs [6-9]` — WARN d=2.

8. **Metodo:** Validacao usa `SUM(dc.quantity)` com `functional_tag` de `deck_cards`. Colunas da tabela `decks` (total_lands, ramp_count, draw_count, removal_count, etc.) estao stale e NAO sao usadas como fonte primaria. As diferencas entre esta validacao e as anteriores refletem consolidacao progressiva dos dados de tags.

---
*Validacao gerada por manaloom-mana-base-validator em 2026-06-05T02:36:49Z*
