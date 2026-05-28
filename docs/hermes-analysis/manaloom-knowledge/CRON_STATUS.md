# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-28T01:26Z**

## Resumo

| Métrica | Valor |
|:--|:--:|
| Total de crons (`include_disabled=True`) | 15 |
| Habilitados | 15/15 |
| Desabilitados | 0 |
| `last_status=error` | **5** |
| Nunca executaram (`last_run_at=null`) | 0 |
| Stale (>120min atrás, `enabled=true`) | 1 |
| Ações de recuperação nesta execução | 0 |
| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** nenhum cron estava desabilitado, stale (>120min) ou never-run no momento desta inspeção; portanto **nenhum `resume`/`run` foi necessário**. Permanecem **5 crons em `last_status=error`**, todos concentrados no provedor/modelo OpenRouter `nvidia/nemotron-3-super-120b-a12b:free`, com sinais de esgotamento de cota/free tier (`HTTP 429 free-models-per-day`).

## Ações da Rodada Atual

| # | Ação | Resultado |
|:-:|:-----|:----------|
| 1 | `cronjob(action='list', include_disabled=True)` | ✅ 15 jobs listados |
| 2 | Verificação de branch (`git branch --show-current`) | ✅ `codex/hermes-analysis-docs` |
| 3 | Verificação do worktree (`git status --short`) | ✅ limpo antes da atualização do relatório |
| 4 | Avaliação das regras gerenciais (`enabled=false`, stale>120m, never-run) | ✅ nenhuma ação corretiva requerida |
| 5 | Diagnóstico dos `last_status=error` por outputs recentes | 🔍 falhas agrupadas em quota/rate-limit do OpenRouter free-model |

## Crons de Auditoria / Gerenciais

| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação |
|---|---|---|---|---|---|---|---|---|
| `757eefb8738b` | manaloom-master-watchdog | every 30m | sim | 2026-05-28T01:09:56.818896+00:00 | 16min | ok | scheduled | sem ação |
| `660397bb97e1` | manaloom-hermes-normal-audit | 0 16,21 * * * | sim | 2026-05-27T23:40:25.566001+00:00 | 1h45min | ok | scheduled | sem ação |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | 30 12 * * 0 | sim | 2026-05-27T23:59:20.454444+00:00 | 1h26min | ok | scheduled | sem ação |
| `2d436c71bbf7` | manaloom-manager-watchdog | every 30m | sim | 2026-05-28T00:55:22.824630+00:00 | 30min | ok | scheduled | sem ação |
| `577a0a669714` | manaloom-code-structure-auditor | 0 6 * * 0 | sim | 2026-05-28T00:03:26.329052+00:00 | 1h22min | ok | scheduled | sem ação |
| `bb03201b8911` | manaloom-code-structure-auditor | 0 20,0,4,8,12,16 * * * | sim | 2026-05-28T00:06:10.228128+00:00 | 1h20min | ok | scheduled | sem ação |

## Crons de Conhecimento Commander

| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação |
|---|---|---|---|---|---|---|---|---|
| `75eed994c103` | manaloom-commander-knowledge-deep | every 20m | sim | 2026-05-28T01:21:07.280893+00:00 | 5min | error | scheduled | erro pendente; provider=openrouter model=nvidia/nemotron-3-super-120b-a12b:free |
| `7915cc2377a0` | manaloom-gamechanger-research | every 20m | sim | 2026-05-28T01:21:15.616814+00:00 | 5min | error | scheduled | erro pendente; provider=openrouter model=nvidia/nemotron-3-super-120b-a12b:free |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | every 360m | sim | 2026-05-28T00:00:12.315371+00:00 | 1h26min | ok | scheduled | sem ação |
| `444aa9510c2c` | manaloom-mana-base-validator | every 60m | sim | 2026-05-28T01:08:39.858635+00:00 | 17min | ok | scheduled | sem ação |
| `b2f5c21ce2d7` | manaloom-knowledge-import | every 30m | sim | 2026-05-28T01:22:33.645107+00:00 | 3min | ok | scheduled | sem ação |

## Lorehold Knowledge Pipeline

| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação |
|---|---|---|---|---|---|---|---|---|
| `f20ac299992b` | lorehold-deck-scout | every 30m | sim | 2026-05-28T01:09:47.312892+00:00 | 16min | error | scheduled | erro pendente; provider=openrouter model=nvidia/nemotron-3-super-120b-a12b:free |
| `712579b15767` | lorehold-deck-validator | every 60m | sim | 2026-05-28T01:09:56.620728+00:00 | 16min | error | scheduled | erro pendente; provider=openrouter model=nvidia/nemotron-3-super-120b-a12b:free |
| `08468451a06a` | lorehold-mulligan-analyst | every 120m | sim | 2026-05-28T00:07:27.751599+00:00 | 1h18min | error | scheduled | erro pendente; provider=openrouter model=nvidia/nemotron-3-super-120b-a12b:free |
| `a50bef4c2a59` | lorehold-evolution-oracle | every 360m | sim | 2026-05-27T21:41:36.343883+00:00 | 3h44min | ok | scheduled | sem ação |

## Alertas Pendentes

| Cron | Job ID | Último run | Erro observado | Impacto | Próxima ação recomendada |
|---|---|---|---|---|---|
| manaloom-commander-knowledge-deep | `75eed994c103` | 2026-05-28T01:21:07.280893+00:00 | HTTP 429 / free-models-per-day | cron continua habilitado mas não conclui a tarefa | revisar provider/modelo/cota fora desta execução; não há fix local seguro sem instrução explícita |
| manaloom-gamechanger-research | `7915cc2377a0` | 2026-05-28T01:21:15.616814+00:00 | HTTP 429 / free-models-per-day | cron continua habilitado mas não conclui a tarefa | revisar provider/modelo/cota fora desta execução; não há fix local seguro sem instrução explícita |
| lorehold-deck-scout | `f20ac299992b` | 2026-05-28T01:09:47.312892+00:00 | HTTP 429 / free-models-per-day | cron continua habilitado mas não conclui a tarefa | revisar provider/modelo/cota fora desta execução; não há fix local seguro sem instrução explícita |
| lorehold-deck-validator | `712579b15767` | 2026-05-28T01:09:56.620728+00:00 | HTTP 429 / free-models-per-day | cron continua habilitado mas não conclui a tarefa | revisar provider/modelo/cota fora desta execução; não há fix local seguro sem instrução explícita |
| lorehold-mulligan-analyst | `08468451a06a` | 2026-05-28T00:07:27.751599+00:00 | erro recente no mesmo cluster OpenRouter/free-model; output atual não resumido automaticamente | cron continua habilitado mas não conclui a tarefa | revisar provider/modelo/cota fora desta execução; não há fix local seguro sem instrução explícita |

## Observações Importantes

- O critério operacional desta execução era apenas **manter a frota viva**: reativar desabilitados, disparar stale/never-run e registrar o snapshot.
- Como nenhum job atendia aos gatilhos de `resume`/`run`, a execução correta foi **não aplicar ações destrutivas/cegas**.
- Os 5 erros remanescentes são **sistêmicos no mesmo provider/modelo** e não indicam workdir incorreto nem cron desabilitado.
- `dart` e `flutter` continuam presentes no ambiente (`/opt/data/tools/flutter/bin/`), então a baseline de tooling segue responsiva.
- Apenas este arquivo foi atualizado intencionalmente nesta rodada.

