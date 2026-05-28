# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-28T06:21Z** (manager-watchdog — snapshot rotineiro)

## Resumo

|| Métrica | Valor |
||:--|:--:|
||| Total de crons (`include_disabled=True`) | 15 |
|||| Habilitados | 15/15 |
|||| Desabilitados | 0 |
|||| `last_status=error` | **2** |
|||| Nunca executaram (`last_run_at=null`) | 0 |
|||| Stale (>120min atrás, `enabled=true`) | 0 |
|||| Ações de recuperação nesta execução | 0 (erros transitórios — ver abaixo) |
|||| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** todos os 15 crons habilitados e scheduled. **2 crons com `last_status=error`** — ambos erros transitórios HTTP 502 (provider outage às 02:22Z). Desde o último snapshot (04:21Z), 1 cron se recuperou: `lorehold-mulligan-analyst` (HTTP 502 → OK às 05:19Z). Nenhum cron desabilitado, stale (>120min) ou never-run; portanto **nenhum `resume`/`run` foi necessário** — os erros são de runtime (provider 502), não de configuração.

## Ações da Rodada Atual

|| # | Ação | Resultado ||
||:--|:-----|:----------||
| 2026-05-28T06:21Z | `cronjob(action='list', include_disabled=True)` | ✅ 15 jobs listados |
| 2026-05-28T06:21Z | Verificação de branch | ✅ `codex/hermes-analysis-docs` |
| 2026-05-28T06:21Z | Verificação do worktree | ⚠️ artefatos de cron (SCOUT_LOG.md, knowledge.db) — não commitados |
| 2026-05-28T06:21Z | Avaliação das regras gerenciais | ✅ nenhuma ação corretiva requerida |
| 2026-05-28T06:21Z | Verificação de `last_status=error` | ⚠️ 2 erros encontrados (ambos HTTP 502 transitório — ver detalhes) |
| 2026-05-28T06:21Z | Atualização do CRON_STATUS.md | ✅ snapshot 06:21Z |

## Crons de Auditoria / Gerenciais

|| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação ||
||---|---|---|---|---|---|---|---|---||
| `757eefb8738b` | manaloom-master-watchdog | every 30m | sim | 2026-05-28T05:19Z | 62min | 🟢 ok | scheduled | sem ação |
| `660397bb97e1` | manaloom-hermes-normal-audit | 0 16,21 * * * | sim | 2026-05-28T01:30Z | 291min | 🟢 ok | scheduled | próxima: 16:00Z |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | 30 12 * * 0 | sim | 2026-05-28T01:36Z | 286min | 🟢 ok | scheduled | próxima: dom 12:30Z |
| `2d436c71bbf7` | manaloom-manager-watchdog | every 30m | sim | 2026-05-28T04:29Z | 113min | 🟢 ok | scheduled | **esta execução** |
| `577a0a669714` | manaloom-code-structure-auditor (weekly) | 0 6 * * 0 | sim | 2026-05-28T02:22Z | 240min | 🔴 error | scheduled | **HTTP 502** — provider error transitório, próxima: dom 06:00Z |
| `bb03201b8911` | manaloom-code-structure-auditor (4h) | 0 20,0,4,8,12,16 * * * | sim | 2026-05-28T04:17Z | 125min | 🟢 ok | scheduled | ✅ recuperado do HTTP 502 |

## Crons de Conhecimento Commander

|| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação ||
||---|---|---|---|---|---|---|---|---||
| `75eed994c103` | manaloom-commander-knowledge-deep | every 20m | sim | 2026-05-28T05:23Z | 58min | 🟢 ok | scheduled | sem ação |
| `7915cc2377a0` | manaloom-gamechanger-research | every 20m | sim | 2026-05-28T05:23Z | 58min | 🟢 ok | scheduled | sem ação |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | every 360m | sim | 2026-05-28T02:05Z | 256min | 🟢 ok | scheduled | próxima: ~08:05Z |
| `444aa9510c2c` | manaloom-mana-base-validator | every 60m | sim | 2026-05-28T05:00Z | 81min | 🟢 ok | scheduled | sem ação |
| `b2f5c21ce2d7` | manaloom-knowledge-import | every 30m | sim | 2026-05-28T04:03Z | 138min | 🟢 ok | scheduled | sem ação |

## Lorehold Knowledge Pipeline

|| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação ||
||---|---|---|---|---|---|---|---|---||
| `f20ac299992b` | lorehold-deck-scout | every 30m | sim | 2026-05-28T05:15Z | 66min | 🟢 ok | scheduled | sem ação |
| `712579b15767` | lorehold-deck-validator | every 60m | sim | 2026-05-28T03:42Z | 159min | 🟢 ok | scheduled | sem ação |
| `08468451a06a` | lorehold-mulligan-analyst | every 120m | sim | 2026-05-28T05:19Z | 62min | 🟢 ok | scheduled | ✅ recuperado do HTTP 502 |
| `a50bef4c2a59` | lorehold-evolution-oracle | every 360m | sim | 2026-05-28T02:22Z | 240min | 🔴 error | scheduled | **HTTP 502** — provider error transitório, próxima: ~08:22Z |

## Alertas Pendentes

**2 crons com `last_status=error` nesta rodada** — ambos classificados como erros transitórios de runtime, não requerendo ação de `resume` ou `run`:

| Job ID | Nome | Erro | Tipo | Ação |
|:-------|:-----|:-----|:-----|:-----|
| `08468451a06a` | lorehold-mulligan-analyst | ~~HTTP 502~~ → recuperado | Provider outage transitório (02:22Z) | ✅ Auto-recuperado em 05:19Z |
| `a50bef4c2a59` | lorehold-evolution-oracle | `HTTP 502: Provider returned error` | Provider outage transitório (02:22Z) | Auto-recupera na próxima tick (~08:22Z) |
| `577a0a669714` | structure-auditor (weekly) | `HTTP 502: Provider returned error` | Provider outage transitório (02:22Z) | Auto-recupera na próxima tick (dom 06:00Z) |

**Recuperações desde snapshot anterior (04:21Z):**

| Job ID | Nome | Erro anterior | Status atual |
|:-------|:-----|:-------------|:-------------|
| `08468451a06a` | lorehold-mulligan-analyst | HTTP 502 | ✅ OK (05:19Z) |

**Nenhuma ação corretiva aplicada** — os 2 erros são de runtime (provider 502), não de configuração (disabled, stale, never-run). Todos os crons com erro continuam `enabled=true` e `state=scheduled`, sendo reexecutados automaticamente pelo scheduler.

## Precisão das Functional Tags (tag_accuracy)

> Última verificação: **2026-05-28T06:21Z** (cron `manaloom-tag-accuracy-reporter`)

### Resumo Geral

| Métrica | Valor |
|:--|:--:|
| Total de tags avaliadas | 29 |
| Acertos / Total | **378/454** |
| Precisão global | **83.3%** |

### Tags com 100% de Precisão (15 tags)

| Tag | Amostras |
|:--|:--:|
| land | 87 |
| utility | 76 |
| ramp | 53 |
| draw | 32 |
| removal | 30 |
| creature | 22 |
| tutor | 6 |
| board_wipe | 3 |
| recursion | 3 |
| planeswalker | 2 |
| artifact | 2 |
| enchantment | 3 |
| sacrifice_outlet | 1 |
| finisher | 2 |
| wipe | 1 |

### Tags Problemáticas (< 50%)

| Tag | Precisão | Amostras | Problema |
|:--|:--:|:--|:--|
| **ninja** | **0.0%** | 17 | TODAS as 17 classificações como "ninja" estão erradas |
| ramp + combo_piece | 0.0% | 1 | Tag composta rara, sem acerto |
| recursion + wincon | 0.0% | 1 | Tag composta rara, sem acerto |
| ramp + payoff | 0.0% | 1 | Tag composta rara, sem acerto |
| payoff + removal | 0.0% | 1 | Tag composta rara, sem acerto |
| payoff + token_maker | 0.0% | 1 | Tag composta rara, sem acerto |
| stax_disruption | 0.0% | 3 | 3/3 erradas — classificador confunde stax com outras funções |

### Tags Intermediárias (50-75%)

| Tag | Precisão | Amostras |
|:--|:--:|:--:|
| payoff | 35.5% | 31 |
| combo_piece | 50.0% | 2 |
| enabler | 50.0% | 42 |
| other | 50.0% | 2 |
| protection | 69.2% | 13 |
| wincon | 75.0% | 8 |
| engine | 75.0% | 8 |

### Mudanças desde última verificação (02:00Z)

- **Sem mudanças nos dados**: todos os 378/454 acertos e 29 tags permanecem idênticos à última verificação.
- Nenhuma nova avaliação de tag foi inserida no banco desde 02:00Z.
- **Status das tags problemáticas:** inalterado — ninja (0.0%, 17 erros), payoff (35.5%, 31 amostras) e enabler (50%, 42 amostras) continuam sendo as maiores fontes de erro.
- **Recomendação mantida:** revisar heurísticas de `ninja`, `payoff`, `enabler` e `stax_disruption` quando houver bandwidth para ajuste do classificador.

### Análise

**Pontos fortes:**
- Tags fundamentais (land, utility, ramp, draw, removal) estão em 100% — a base do classificador é sólida.
- 15 de 29 tags têm precisão perfeita.

**Pontos fracos críticos:**
1. **ninja (0.0%, 17 erros):** O classificador está atribuindo "ninja" massivamente a cartas que não são ninja. Isso é um viés grave — provavelmente o regex/heurística captura retorno à mão (ninjutsu) mas classifica errado.
2. **stax_disruption (0.0%, 3 erros):** O classificador não consegue diferenciar stax de outras formas de disruption.
3. **Tags compostas (todas 0%):** Tags compostas como `ramp + combo_piece`, `payoff + removal` têm amostras muito pequenas (1 cada) e zero acertos. Ou o classificador não deveria gerá-las golden tags, ou precisa de ajuste.
4. **enabler (50%, 42 amostras):** Metade dos "enablers" estão classificados errados — impacto significativo na análise de decks.
5. **payoff (35.5%, 31 amostras):** A tag mais problemática em volume. 20 das 31 classificações estão erradas.

**Recomendação:** Revisar as heurísticas de ninja, payoff, enabler e stax_disruption. As tags compostas podem ser reviewedas para verificar se os golden labels estão corretos.

## Mana Base Validation Report

> **Última execução:** 2026-05-28T05:45Z (cron `manaloom-mana-base-validator`)
> **Decks analisados:** 8
> **Nota:** Lorehold (deck 6) não possui perfil de referência no diretório de artifacts — sem validação de role_targets.

### Resumo

| Deck | Commander | Status | SQLite Cards | DB Lands | SQLite Lands | Profile Range | Problemas |
|-----|:----------|:------:|:------------:|:--------:|:-------------:|:-------------:|:----------|
| 1 — Kinnan, Bonder Prodigy | Kinnan, Bonder Prodigy | 🔴 CRIT | 13 | 29 | 0 | 29-34 | Total Cards 🔴 CRIT (13/100); Lands DB=29 vs SQLite=0 (diff=-29); lands 🔴 CRIT (0 vs 29-34); mana_dorks 🔴 CRIT (4 vs 10-16); interaction_protection 🔴 CRIT (3 vs 9-14) |
| 2 — EDHREC Average Deck - Dimir Ninja T | Yuriko, the Tiger's Sh | 🟡 WARN | 99 | 33 | 35 | 30-34 | Total Cards 🟡 WARN (99/100); DB total_cards=84 desatualizado vs SQLite=99; lands 🔵 BLUE (35 vs 30-34); interaction 🔵 BLUE (9 vs 10-16) |
| 3 — EDHREC Average Default | Korvold, Fae-Cursed Ki | 🔴 CRIT | 11 | 25 | 0 | 34-37 | Total Cards 🔴 CRIT (11/100); Lands DB=25 vs SQLite=0 (diff=-25); lands 🔴 CRIT (0 vs 34-37); ramp_treasure 🔴 CRIT (3 vs 10-14) |
| 4 — EDHREC Average Default | Teysa Karlov | 🔴 CRIT | 80 | 35 | 15 | 35-37 | Total Cards 🔴 CRIT (80/100); Lands DB=35 vs SQLite=15 (diff=-20); lands 🔴 CRIT (15 vs 35-37); ramp 🔴 CRIT (15 vs 9-11) |
| 5 — Aesi EDHREC Average Default | Aesi, Tyrant of Gyre S | 🔴 CRIT | 100 | 40 | 40 | 39-43 | DB total_cards=79 desatualizado vs SQLite=100; ramp_extra_lands 🔴 CRIT (28 vs 14-18); supplemental_draw 🟡 WARN (12 vs 6-9); protection 🟡 WARN (7 vs 2-4) |
| 6 — Lorehold Spellslinger | Lorehold, the Historia | ✅ OK | 100 | 35 | 35 | N/A | — (sem perfil de referência) |
| 7 — EDHREC Average Default — Boros Comb | Winota, Joiner of Forc | 🟡 WARN | 100 | 34 | 34 | 31-35 | protection 🟡 WARN (10 vs 5-8) |
| 9 — Atraxa, Praetors' Voice — EDHREC Av | Atraxa, Praetor's Voic | 🟡 WARN | 100 | 36 | 36 | 35-38 | ramp_fixing 🔵 BLUE (14 vs 10-13); counter_payoffs 🔵 BLUE (7 vs 8-14); interaction 🔵 BLUE (7 vs 8-13) |

### Achados Críticos

1. **4 decks incompletos/parciais:** Deck 1 (Kinnan, Bonder Prodigy): 13/100; Deck 2 (EDHREC Average Deck - Dimir Ninja): 99/100; Deck 3 (EDHREC Average Default): 11/100; Deck 4 (EDHREC Average Default): 80/100
2. **4 decks com divergência DB vs SQLite lands:** Deck 1 (Kinnan): DB=29, SQLite=0, Diff=-29; Deck 2 (Yuriko): DB=33, SQLite=35, Diff=+2; Deck 3 (Korvold): DB=25, SQLite=0, Diff=-25; Deck 4 (Teysa): DB=35, SQLite=15, Diff=-20
3. **Deck 5 (Aesi):** ramp_extra_lands=28 vs perfil 14-18 (CRIT +10 acima do max); supplemental_draw=12 vs perfil 6-9 (WARN +3 acima); protection=7 vs perfil 2-4 (WARN +3 acima); DB total_cards=79 desatualizado vs SQLite=100
4. **Deck 7 (Winota):** protection_count=10 vs perfil 5-8 (WARN +2 acima do max)
5. **Deck 6 (Lorehold):** único deck completo sem perfil de referência — não é possível validar role_targets contra EDHREC
6. **Deck 9 (Atraxa):** finishers=1 vs perfil 4-7 (WARN -3 abaixo); ramp_fixing, counter_payoffs, interaction todos 🔵 BLUE (-1 cada)

### Divergências Lands DB vs SQLite

| Deck | DB total_lands | SQLite lands | Diferença | Status |
|-----|:---------------|:-------------|:----------|:-------|
| 1 — Kinnan, Bonder Prodigy | 29 | 0 | -29 | ❌ DIVERGENT |
| 2 — EDHREC Average Deck - Dimir Ni | 33 | 35 | +2 | ⚠️ WARN |
| 3 — EDHREC Average Default | 25 | 0 | -25 | ❌ DIVERGENT |
| 4 — EDHREC Average Default | 35 | 15 | -20 | ❌ DIVERGENT |
| 5 — Aesi EDHREC Average Default | 40 | 40 | +0 | ✅ OK |
| 6 — Lorehold Spellslinger | 35 | 35 | +0 | ✅ OK |
| 7 — EDHREC Average Default — Boros | 34 | 34 | +0 | ✅ OK |
| 9 — Atraxa, Praetors' Voice — EDHR | 36 | 36 | +0 | ✅ OK |

### Mudanças desde última validação (04:51Z)

- **Sem mudanças estruturais:** todos os decks mantêm os mesmos totais de cartas e lands desde a validação anterior.
- **Deck 5 (Aesi):** DB total_cards permanece 79 (desatualizado) vs SQLite 100 — não corrigido desde rodada anterior.
- **Deck 2 (Yuriko):** DB total_cards permanece 84 (desatualizado) vs SQLite 99 — não corrigido.
- **Decks 1, 3, 4** continuam com dados incompletos (inserts parciais de imports anteriores).
- **Nenhum novo deck inserido ou removido** desde última validação.
- **Todas as violações de role_targets** (lands CRIT em decks 1,3,4; ramp_extra_lands CRIT em deck 5) **permanecem idênticas**.

---

## Observações Importantes

- **2 crons com erro** (todos `enabled=true`, `state=scheduled`): 2× HTTP 502 (provider outage transitório às 02:22Z). **Nenhum requeriu `resume`/`run`** — todos são erros de runtime transitórios.
- `lorehold-evolution-oracle` falhou com HTTP 502 em 02:22Z — provider outage. Próxima tick: ~08:22Z.
- `manaloom-code-structure-auditor (weekly)` em HTTP 502 — próxima execução: domingo 06:00Z.
- **1 cron recuperado** desde snapshot anterior: `lorehold-mulligan-analyst` (05:19Z → OK).
- `origin/master` estável sem novos commits desde a última análise (HEAD: 771c9318).
- `dart` e `flutter` continuam presentes (`/opt/data/tools/flutter/bin/`).
- Apenas este arquivo (`CRON_STATUS.md`) foi atualizado intencionalmente nesta rodada.

