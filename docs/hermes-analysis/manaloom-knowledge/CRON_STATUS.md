# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-28T04:21Z** (manager-watchdog — snapshot rotineiro)

## Resumo

|| Métrica | Valor |
||:--|:--:|
||| Total de crons (`include_disabled=True`) | 15 |
||| Habilitados | 15/15 |
||| Desabilitados | 0 |
||| `last_status=error` | **3** |
||| Nunca executaram (`last_run_at=null`) | 0 |
||| Stale (>120min atrás, `enabled=true`) | 0 |
||| Ações de recuperação nesta execução | 0 (erros transitórios — ver abaixo) |
||| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** todos os 15 crons habilitados e scheduled. **3 crons com `last_status=error`** — todos erros transitórios HTTP 502 (provider outage às 02:22Z). Desde o último snapshot (03:10Z), 3 crons se recuperaram: `commander-knowledge-deep`, `knowledge-import` e `structure-auditor (4h)`. Nenhum cron desabilitado, stale (>120min) ou never-run; portanto **nenhum `resume`/`run` foi necessário** — os erros são de runtime (provider 502), não de configuração.

## Ações da Rodada Atual

|| # | Ação | Resultado ||
||:--|:-----|:----------||
||| 1 | `cronjob(action='list', include_disabled=True)` | ✅ 15 jobs listados |
||| 2 | Verificação de branch (`git branch --show-current`) | ✅ `codex/hermes-analysis-docs` |
||| 3 | Verificação do worktree (`git status --short`) | ✅ worktree limpo |
||| 4 | Avaliação das regras gerenciais (`enabled=false`, stale>120m, never-run) | ✅ nenhuma ação corretiva requerida |
||| 5 | Verificação de `last_status=error` | ⚠️ 3 erros encontrados (todos HTTP 502 transitório — ver detalhes abaixo) |
||| 6 | Atualização do CRON_STATUS.md | ✅ snapshot 2026-05-28T04:21Z |

## Crons de Auditoria / Gerenciais

|| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação ||
||---|---|---|---|---|---|---|---|---||
||| `757eefb8738b` | manaloom-master-watchdog | every 30m | sim | 2026-05-28T03:57Z | 24min | 🟢 ok | scheduled | sem ação ||
||| `660397bb97e1` | manaloom-hermes-normal-audit | 0 16,21 * * * | sim | 2026-05-28T01:30Z | 171min | 🟢 ok | scheduled | próxima: 16:00Z ||
||| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | 30 12 * * 0 | sim | 2026-05-28T01:36Z | 166min | 🟢 ok | scheduled | próxima: dom 12:30Z ||
||| `2d436c71bbf7` | manaloom-manager-watchdog | every 30m | sim | 2026-05-28T03:48Z | 33min | 🟢 ok | scheduled | **esta execução** ||
||| `577a0a669714` | manaloom-code-structure-auditor (weekly) | 0 6 * * 0 | sim | 2026-05-28T02:22Z | 119min | 🔴 error | scheduled | **HTTP 502** — provider error transitório, próxima: dom 06:00Z ||
||| `bb03201b8911` | manaloom-code-structure-auditor (4h) | 0 20,0,4,8,12,16 * * * | sim | 2026-05-28T04:17Z | 4min | 🟢 ok | scheduled | ✅ recuperado do HTTP 502 ||

## Crons de Conhecimento Commander

|| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação ||
||---|---|---|---|---|---|---|---|---||
||| `75eed994c103` | manaloom-commander-knowledge-deep | every 20m | sim | 2026-05-28T04:06Z | 15min | 🟢 ok | scheduled | ✅ recuperado do truncated response ||
||| `7915cc2377a0` | manaloom-gamechanger-research | every 20m | sim | 2026-05-28T04:08Z | 14min | 🟢 ok | scheduled | ✅ recuperado do HTTP 502 ||
||| `b340374bc4e7` | manaloom-tag-accuracy-reporter | every 360m | sim | 2026-05-28T02:05Z | 137min | 🟢 ok | scheduled | sem ação ||
||| `444aa9510c2c` | manaloom-mana-base-validator | every 60m | sim | 2026-05-28T03:28Z | 54min | 🟢 ok | scheduled | sem ação ||
||| `b2f5c21ce2d7` | manaloom-knowledge-import | every 30m | sim | 2026-05-28T04:03Z | 18min | 🟢 ok | scheduled | ✅ recuperado do HTTP 429 ||

## Lorehold Knowledge Pipeline

|| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação ||
||---|---|---|---|---|---|---|---|---||
||| `f20ac299992b` | lorehold-deck-scout | every 30m | sim | 2026-05-28T03:57Z | 24min | 🟢 ok | scheduled | sem ação ||
||| `712579b15767` | lorehold-deck-validator | every 60m | sim | 2026-05-28T03:42Z | 39min | 🟢 ok | scheduled | sem ação ||
||| `08468451a06a` | lorehold-mulligan-analyst | every 120m | sim | 2026-05-28T02:22Z | 119min | 🔴 error | scheduled | **HTTP 502** — provider error transitório, próxima: ~04:22Z ||
||| `a50bef4c2a59` | lorehold-evolution-oracle | every 360m | sim | 2026-05-28T02:22Z | 119min | 🔴 error | scheduled | **HTTP 502** — provider error transitório, próxima: ~08:22Z ||

## Alertas Pendentes

**3 crons com `last_status=error` nesta rodada** — todos classificados como erros transitórios de runtime, não requerendo ação de `resume` ou `run`:

| Job ID | Nome | Erro | Tipo | Ação |
|:-------|:-----|:-----|:-----|:-----|
| `08468451a06a` | lorehold-mulligan-analyst | `HTTP 502: Provider returned error` | Provider outage transitório (02:22Z) | Auto-recupera na próxima tick (~04:22Z) |
| `a50bef4c2a59` | lorehold-evolution-oracle | `HTTP 502: Provider returned error` | Provider outage transitório (02:22Z) | Auto-recupera na próxima tick (~08:22Z) |
| `577a0a669714` | structure-auditor (weekly) | `HTTP 502: Provider returned error` | Provider outage transitório (02:22Z) | Auto-recupera na próxima tick (dom 06:00Z) |

**Recuperações desde snapshot anterior (03:10Z):**

| Job ID | Nome | Erro anterior | Status atual |
|:-------|:-----|:-------------|:-------------|
| `75eed994c103` | commander-knowledge-deep | Truncated response | ✅ OK (04:06Z) |
| `b2f5c21ce2d7` | manaloom-knowledge-import | HTTP 429 | ✅ OK (04:03Z) |
| `bb03201b8911` | structure-auditor (4h) | HTTP 502 | ✅ OK (04:17Z) |

**Nenhuma ação corretiva aplicada** — os 3 erros são de runtime (provider 502), não de configuração (disabled, stale, never-run). Todos os crons com erro continuam `enabled=true` e `state=scheduled`, sendo reexecutados automaticamente pelo scheduler.

## Precisão das Functional Tags (tag_accuracy)

> Última verificação: **2026-05-28T02:00Z** (cron `manaloom-tag-accuracy-reporter`)

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

> **Última execução:** 2026-05-28T04:51Z (cron `manaloom-mana-base-validator`)
> **Decks analisados:** 8
> **Nota:** Lorehold (deck 6) não possui perfil de referência no diretório de artifacts — sem validação de role_targets.

### Resumo

| Deck | Commander | Status | Total Cards | DB Lands | SQLite Lands | Profile Lands | Problemas |
|-----|:----------|:------:|:-----------:|:--------:|:------------:|:--------------:|:----------|
| 1 — Kinnan, Bonder Prodigy | Kinnan, Bonder Prodi | 🔴 CRIT | 13 | 29 | 0 | 29-34 | lands 🔴 CRIT (0 vs 29-34); mana_dorks 🔴 CRIT (4 vs 10-16); interaction_protection 🔴 CRIT (3 vs 9-14) |
| 2 — EDHREC Average Deck - Dim | Yuriko, the Tiger's  | 🟡 WARN | 99 | 33 | 35 | 30-34 | lands 🔵 BLUE (35 vs 30-34); interaction 🔵 BLUE (9 vs 10-16); Total Cards 🟡 WARN (99/100) |
| 3 — EDHREC Average Default | Korvold, Fae-Cursed  | 🔴 CRIT | 11 | 25 | 0 | 34-37 | lands 🔴 CRIT (0 vs 34-37); ramp_treasure 🔴 CRIT (3 vs 10-14); draw_value 🔴 CRIT (1 vs 6-10) |
| 4 — EDHREC Average Default | Teysa Karlov | 🔴 CRIT | 80 | 35 | 15 | 35-37 | lands 🔴 CRIT (15 vs 35-37); ramp 🔴 CRIT (15 vs 9-11); recursion 🔵 BLUE (3 vs 4-7) |
| 5 — Aesi EDHREC Average Defau | Aesi, Tyrant of Gyre | 🔴 CRIT | 100 | 40 | 40 | 39-43 | ramp_extra_lands 🔴 CRIT (28 vs 14-18); supplemental_draw 🟡 WARN (12 vs 6-9); protection 🟡 WARN (7 vs 2-4) |
| 6 — Lorehold Spellslinger | Lorehold, the Histor | ✅ OK | 100 | 35 | 35 | N/A | (sem perfil de referência) |
| 7 — EDHREC Average Default | Winota, Joiner of Fo | 🟡 WARN | 100 | 34 | 34 | 31-35 | protection 🟡 WARN (10 vs 5-8) |
| 9 — Atraxa, Praetors' Voice | Atraxa, Praetors' Vo | 🟡 WARN | 100 | 36 | 36 | 35-38 | ramp_fixing 🔵 BLUE (14 vs 10-13); counter_payoffs 🔵 BLUE (7 vs 8-14); interaction 🔵 BLUE (7 vs 8-13) |

### Achados Críticos

1. **4 decks incompletos/parciais:** Deck 1 (Kinnan, Bonder Prodigy): 13/100; Deck 2 (EDHREC Average Deck - Dimir Ninja Topdeck Tempo): 99/100; Deck 3 (EDHREC Average Default): 11/100; Deck 4 (EDHREC Average Default): 80/100
2. **3 decks com divergência grave DB vs SQLite lands:** Deck 1 (Kinnan): DB=29, SQLite=0, Diff=-29; Deck 3 (Korvold): DB=25, SQLite=0, Diff=-25; Deck 4 (Teysa): DB=35, SQLite=15, Diff=-20
3. **Deck 5 (Aesi):** ramp_count=28 vs perfil 14-18 (CRIT +10 acima do max), draw_count=12 vs perfil 6-9 (WARN +3 acima do max), protection_count=7 vs perfil 2-4 (WARN +3 acima do max)
4. **Deck 7 (Winota):** protection_count=10 vs perfil 5-8 (WARN +2 acima do max)
5. **Deck 6 (Lorehold):** único deck completo sem perfil de referência — não é possível validar role_targets contra EDHREC
6. **Deck 9 (Atraxa):** finishers=1 vs perfil 4-7 (WARN -3 abaixo) — nova flag; ramp_fixing, counter_payoffs, interaction todos 🔵 BLUE (-1 cada)

### Divergências Lands DB vs SQLite

| Deck | DB total_lands | SQLite lands | Diferença | Status |
|-----|:---------------|:-------------|:----------|:-------|
| 1 — Kinnan, Bonder Prodi | 29 | 0 | -29 | ❌ |
| 2 — EDHREC Average Deck  | 33 | 35 | +2 | ⚠️ |
| 3 — EDHREC Average Defau | 25 | 0 | -25 | ❌ |
| 4 — EDHREC Average Defau | 35 | 15 | -20 | ❌ |
| 5 — Aesi EDHREC Average  | 40 | 40 | 0 | ✅ |
| 6 — Lorehold Spellslinge | 35 | 35 | 0 | ✅ |
| 7 — EDHREC Average Defau | 34 | 34 | 0 | ✅ |
| 9 — Atraxa, Praetors' Vo | 36 | 36 | 0 | ✅ |

### Mudanças desde última validação (03:25Z)

- **Sem mudanças estruturais**: todos os decks mantêm os mesmos totais de cartas e lands desde a validação anterior.
- **Decks 1, 3, 4** continuam com dados incompletos nas tabelas (insert parcial durante import anterior).
- **Deck 2 (Yuriko):** total_cards no DB permanece 84 vs 99 real no SQLite — dado desatualizado desde import.
- **Deck 9 (Atraxa):** nova flag em finishers (1 vs perfil 4-7, WARN) — anteriormente reportado como 🔵 BLUE apenas.
- **Nenhum novo deck inserido ou removido** desde última validação.

---

## Observações Importantes

- **3 crons com erro** (todos `enabled=true`, `state=scheduled`): 3× HTTP 502 (provider outage transitório às 02:22Z). **Nenhum requeriu `resume`/`run`** — todos são erros de runtime transitórios.
- `lorehold-mulligan-analyst` e `lorehold-evolution-oracle` falharam com HTTP 502 no mesmo momento (02:22Z) — provider outage, não bug no código. Próximas ticks: ~04:22Z e ~08:22Z.
- `manaloom-code-structure-auditor (weekly)` em HTTP 502 — próxima execução: domingo 06:00Z.
- **3 crons recuperados** desde snapshot anterior: `commander-knowledge-deep` (truncated→OK), `knowledge-import` (429→OK), `structure-auditor (4h)` (502→OK).
- `origin/master` estável sem novos commits desde a última análise (HEAD: 771c9318).
- `dart` e `flutter` continuam presentes (`/opt/data/tools/flutter/bin/`).
- Apenas este arquivo (`CRON_STATUS.md`) foi atualizado intencionalmente nesta rodada.

