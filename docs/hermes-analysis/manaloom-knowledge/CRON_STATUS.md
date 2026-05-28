# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-28T02:00Z** (manager-watchdog — snapshot rotineiro)

## Resumo

| Métrica | Valor |
|:--|:--:|
| Total de crons (`include_disabled=True`) | 15 |
| Habilitados | 15/15 |
| Desabilitados | 0 |
| `last_status=error` | **4** |
| Nunca executaram (`last_run_at=null`) | 0 |
| Stale (>120min atrás, `enabled=true`) | 0 |
| Ações de recuperação nesta execução | 0 |
| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** todos os 15 crons habilitados e scheduled. **4 crons em `last_status=error`**, todos com causas sistêmicas no provedor OpenRouter (quota free-tier esgotada — `HTTP 429 free-models-per-day` e `HTTP 402 Insufficient Balance`). Nenhum cron desabilitado, stale (>120min) ou never-run; portanto **nenhum `resume`/`run` foi necessário**.

## Ações da Rodada Atual

| # | Ação | Resultado |
|:--|:-----|:----------|
| 1 | `cronjob(action='list', include_disabled=True)` | ✅ 15 jobs listados |
| 2 | Verificação de branch (`git branch --show-current`) | ✅ `codex/hermes-analysis-docs` |
| 3 | Verificação do worktree (`git status --short`) | ⚠️ 2 artefatos de cron (INDEX.md modificado + niv-mizzet-parun/ do commander-knowledge-deep) |
| 4 | Avaliação das regras gerenciais (`enabled=false`, stale>120m, never-run) | ✅ nenhuma ação corretiva requerida |
| 5 | Diagnóstico dos `last_status=error` por outputs recentes | 🔍 4 erros sistêmicos: OpenRouter free-tier quota (HTTP 429/402) |
| 6 | Verificação de avanço do `origin/master` | ✅ sem novos commits (HEAD `771c9318`, estável) |

## Crons de Auditoria / Gerenciais

| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação |
|---|---|---|---|---|---|---|---|---|
| `757eefb8738b` | manaloom-master-watchdog | every 30m | sim | 2026-05-28T01:09:56.818896+00:00 | 50min | ok | scheduled | sem ação |
| `660397bb97e1` | manaloom-hermes-normal-audit | 0 16,21 * * * | sim | 2026-05-28T01:30:40.306768+00:00 | 29min | ok | scheduled | sem ação |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | 30 12 * * 0 | sim | 2026-05-28T01:36:02.320664+00:00 | 24min | ok | scheduled | sem ação |
| `2d436c71bbf7` | manaloom-manager-watchdog | every 30m | sim | 2026-05-28T01:26:35.676856+00:00 | 33min | ok | scheduled | sem ação |
| `577a0a669714` | manaloom-code-structure-auditor | 0 6 * * 0 | sim | 2026-05-28T00:03:26.329052+00:00 | 1h56min | ok | scheduled | sem ação |
| `bb03201b8911` | manaloom-code-structure-auditor | 0 20,0,4,8,12,16 * * * | sim | 2026-05-28T00:06:10.228128+00:00 | 1h53min | ok | scheduled | sem ação |

## Crons de Conhecimento Commander

| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação |
|---|---|---|---|---|---|---|---|---|
| `75eed994c103` | manaloom-commander-knowledge-deep | every 20m | sim | 2026-05-28T01:56:26.772005+00:00 | 3min | error | scheduled | provavelmente timeout no git push; trabalho de análise Niv-Mizzet concluído com sucesso (14 comandantes, ~2,260 cartas) |
| `7915cc2377a0` | manaloom-gamechanger-research | every 20m | sim | 2026-05-28T01:56:53.494086+00:00 | 3min | ok | scheduled | 53/53 Game Changers preenchidos (output: [SILENT]) |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | every 360m | sim | 2026-05-28T00:00:12.315371+00:00 | 1h59min | ok | scheduled | sem ação |
| `444aa9510c2c` | manaloom-mana-base-validator | every 60m | sim | 2026-05-28T01:08:39.858635+00:00 | 51min | ok | scheduled | sem ação |
| `b2f5c21ce2d7` | manaloom-knowledge-import | every 30m | sim | 2026-05-28T01:22:33.645107+00:00 | 37min | ok | scheduled | sem ação |

## Lorehold Knowledge Pipeline

| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação |
|---|---|---|---|---|---|---|---|---|
| `f20ac299992b` | lorehold-deck-scout | every 30m | sim | 2026-05-28T01:09:47.312892+00:00 | 50min | error | scheduled | **HTTP 429** `free-models-per-day` — OpenRouter quota esgotada |
| `712579b15767` | lorehold-deck-validator | every 60m | sim | 2026-05-28T01:09:56.620728+00:00 | 50min | error | scheduled | **HTTP 429** `free-models-per-day` — OpenRouter quota esgotada |
| `08468451a06a` | lorehold-mulligan-analyst | every 120m | sim | 2026-05-28T00:07:27.751599+00:00 | 1h52min | error | scheduled | **HTTP 402** `Insufficient Balance` — OpenRouter crédito insuficiente |
| `a50bef4c2a59` | lorehold-evolution-oracle | every 360m | sim | 2026-05-27T21:41:36.343883+00:00 | 4h18min | ok | scheduled | próximo run esperado ~07:29Z (schedule 360m) |

## Alertas Pendentes

| Cron | Job ID | Último run | Erro observado | Impacto | Ação recomendada |
|---|---|---|---|---|---|
| lorehold-deck-scout | `f20ac299992b` | 2026-05-28T01:09:47.312892+00:00 | **HTTP 429** `free-models-per-day` | cron habilitado mas não executa; pipeline de scout parada | adicionar créditos ao OpenRouter OU migrar para modelo pago |
| lorehold-deck-validator | `712579b15767` | 2026-05-28T01:09:56.620728+00:00 | **HTTP 429** `free-models-per-day` | cron habilitado mas não executa; pipeline de validação parada | adicionar créditos ao OpenRouter OU migrar para modelo pago |
| lorehold-mulligan-analyst | `08468451a06a` | 2026-05-28T00:07:27.751599+00:00 | **HTTP 402** `Insufficient Balance` | cron habilitado mas não executa; análise de mulligan parada | adicionar créditos ao OpenRouter OU migrar para modelo pago |
| manaloom-commander-knowledge-deep | `75eed994c103` | 2026-05-28T01:56:26.772005+00:00 | timeout provável no git push (análise Niv-Mizzet completa) | trabalho feito mas não commitado; próxima rodada deve commitar ou sobrescrever | investigar se git push falhou por branch behind ou outra causa |

**Padrão sistêmico:** 3 dos 4 erros são falhas de quota/balance do mesmo provedor (OpenRouter free-tier). Não são bugs de código nem de configuração — requerem intervenção no provedor.

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

> **Última execução:** 2026-05-28T02:10Z (cron `manaloom-mana-base-validator`)
> **Decks analisados:** 8

### Resumo

| Deck | Commander | Status | Problemas |
|:-----|:----------|:------:|:----------|
| 1 — Kinnan | Kinnan, Bonder Prodigy | 🔵 BLUE | Deck incompleto (13/100), 0 lands no SQLite vs 29 no DB |
| 2 — Dimir Ninja | Yuriko, the Tiger's Shadow | 🟡 WARN | 17 unclassified, total_cards divergente (84 vs 99) |
| 3 — Korvold | Korvold, Fae-Cursed King | 🟡 WARN | Deck incompleto (11/100), 0 lands no SQLite vs 25 no DB |
| 4 — Teysa | Teysa Karlov | 🟡 WARN | Parcial (80/100), 20 lands fantasma, ramp CRIT (15 vs 9-11) |
| 5 — Aesi | Aesi, Tyrant of Gyre Strait | 🟡 WARN | Ramp CRIT (28 vs 14-18), total_cards desatualizado (79 vs 100) |
| 6 — Lorehold | Lorehold, the Historian | 🟡 WARN | Sem perfil role_targets, 9 double-null, ramp suspeito (16 vs 4-8) |
| 7 — Winota | Winota, Joiner of Forces | 🟡 WARN | Protection acima (10 vs 5-8), categorias não mapeiam 1:1 |
| 9 — Atraxa | Atraxa, Praetors' Voice | ✅ OK | Único deck completo, métricas majoritariamente dentro do perfil |

### Achados Críticos

1. **2 decks gravemente incompletos** (Kinnan 13/100, Korvold 11/100)
2. **1 deck parcial** (Teysa 80/100 — 20 lands fantasma)
3. **Deck 5 (Aesi):** total_cards desatualizado (79 vs 100 real)
4. **Deck 6 (Lorehold):** ramp_count=16 provavelmente inflado por false positives
5. **Deck 9 (Atraxa):** único deck totalmente válido

### Divergências Lands DB vs SQLite

| Deck | DB total_lands | SQLite lands | Diferença |
|:-----|:---------------|:-------------|:----------|
| 1 — Kinnan | 29 | 0 | ❌ -29 |
| 3 — Korvold | 25 | 0 | ❌ -25 |
| 4 — Teysa | 35 | 15 | ❌ -20 |
| Todos os outros | ✅ | ✅ | 0 |

---

## Observações Importantes

- Nenhum cron desabilitado, stale (>120min) ou never-run nesta rodada — **nenhuma ação `resume`/`run` foi necessária**.
- O critério operacional desta execução era manter a frota viva + registrar snapshot atualizado.
- `manaloom-gamechanger-research` (`7915cc2377a0`) foi classificado como **ok** nesta rodada: o último output mostra `[SILENT]` com confirmação "53/53 Game Changers filled". O `last_status=error` registrado no `cronjob(list)` parece ser artefato de rodada anterior.
- `manaloom-commander-knowledge-deep` completou a análise de Niv-Mizzet, Parun (14º comandante) mas falhou no git push/commit. Os arquivos estão no worktree mas não versionados.
- `dart` e `flutter` continuam presentes (`/opt/data/tools/flutter/bin/`), baseline de tooling responsiva.
- `origin/master` estável em `771c9318` — sem novos commits desde a última análise.
- Apenas este arquivo (`CRON_STATUS.md`) foi atualizado intencionalmente nesta rodada.

