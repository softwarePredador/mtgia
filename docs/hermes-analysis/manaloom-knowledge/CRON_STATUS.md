# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-27T15:02Z**

## Resumo

| Métrica | Valor |
|:--|:--:|
| Total de crons (`include_disabled=True`) | 16 |
| Habilitados | 16/16 |
| Desabilitados | 0 |
| `last_status=error` | **9** ⚠️ (↑ de 4 desde 13:34Z) |
| Nunca executaram (`last_run_at=null`) | 0 |
| Stale (>120min atras, `enabled=true`) | 2 |
| Triggers aceitos nesta rodada | 2 (stale crons) |
| Resumes nesta rodada | 0 (nenhum desabilitado) |
| Branch do workdir | `codex/hermes-analysis-docs` |
| HEAD da branch de análise | `9a1ee1410858` |

**Estado geral:** 16/16 habilitados ✅, mas **9 crons em status=error** 🔴 — aumento significativo em relação às 4 da última rodada (13:34Z). Os triggers de `master-watchdog` e `lorehold-deck-scout` foram enviados. 2 triggers `run` aceitos para crons stale.

> ⚠️ **Alerta:** Desde o último relatório, 5 crons que estavam mostrando `last_status=ok` (mas com last_run_at do dia anterior) executaram e agora mostram `error`. Isso indica que os crons ESTÃO rodando novamente (as `next_run_at` estão avançando), mas TODOS consistentemente falham. O problema parece sistêmico, não de branch ou scheduler.

## Crons de Auditoria / Gerenciais

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--|
| `757eefb8738b` | manaloom-master-watchdog | `every 30m` | ✅ | 2026-05-27 12:10Z | 2h52min | 🟢 ok | 2026-05-27 15:03Z | ⚠️ stale (172min) → trigger `run` aceito |
| `660397bb97e1` | manaloom-hermes-normal-audit | `0 16,21 * * *` | ✅ | 2026-05-27 12:19Z | 2h43min | 🟢 ok | 2026-05-27 16:00Z | agendado para 16:00 — normal |
| `07346720b753` | manaloom-hermes-daily-deep-audit | `30 11 * * *` | ✅ | 2026-05-27 11:42Z | 3h20min | 🔴 error | 2026-05-28 11:30Z | erro anterior; próximo ciclo amanhã |
| `3542b818f8b3` | manaloom-hermes-weekly-memory-cleanup | `0 12 * * 0` | ✅ | 2026-05-27 12:31Z | 2h31min | 🔴 error | 2026-05-31 12:00Z | erro anterior; próximo domingo |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | `30 12 * * 0` | ✅ | 2026-05-27 12:56Z | 2h06min | 🟢 ok | 2026-05-31 12:30Z | aguardando domingo |
| `2d436c71bbf7` | manaloom-manager-watchdog | `every 30m` | ✅ | 2026-05-27 13:35Z | 1h27min | 🟢 ok | 2026-05-27 15:32Z | **esta execução** |

## Crons de Conhecimento Commander

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--|
| `75eed994c103` | manaloom-commander-knowledge-deep | `every 20m` | ✅ | 2026-05-27 14:56Z | 6min | 🔴 error | 2026-05-27 15:22Z | ⚠️ error recente; o trigger da rodada 13:34Z funcionou (last_run avançou de 22:35→14:56Z) mas job erro |
| `7915cc2377a0` | manaloom-gamechanger-research | `every 20m` | ✅ | 2026-05-27 15:01Z | 1min | 🔴 error | 2026-05-27 15:23Z | 🔴 NOVO erro (era ok na rodada 13:34Z) |
| `5fe699ed7ff2` | manaloom-themes-research | `every 20m` | ✅ | 2026-05-27 14:49Z | 13min | 🔴 error | 2026-05-27 15:09Z | 🔴 NOVO erro (era ok na rodada 13:34Z) |
| `4430f8384ce4` | manaloom-missing-gc-filler | `every 20m` | ✅ | 2026-05-27 14:51Z | 11min | 🔴 error | 2026-05-27 15:11Z | 🔴 NOVO erro (era ok na rodada 13:34Z) |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | `every 360m` | ✅ | 2026-05-27 13:05Z | 1h57min | 🟢 ok | 2026-05-27 19:05Z | próximo ciclo às 19:05Z |
| `444aa9510c2c` | manaloom-mana-base-validator | `every 60m` | ✅ | 2026-05-27 14:40Z | 22min | 🔴 error | 2026-05-27 15:40Z | 🔴 NOVO erro (era ok na rodada 13:34Z) |

## Lorehold Knowledge Pipeline

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--|
| `f20ac299992b` | lorehold-deck-scout | `every 30m` | ✅ | 2026-05-27 11:56Z | 3h06min | 🔴 error | 2026-05-27 15:03Z | ⚠️ stale (186min) → trigger `run` aceito |
| `712579b15767` | lorehold-deck-validator | `every 60m` | ✅ | 2026-05-27 14:44Z | 18min | 🔴 error | 2026-05-27 15:44Z | 🔴 NOVO erro (era ok na rodada 13:34Z) |
| `08468451a06a` | lorehold-mulligan-analyst | `every 120m` | ✅ | 2026-05-27 13:15Z | 1h47min | 🟢 ok | 2026-05-27 15:15Z | sem ação |
| `a50bef4c2a59` | lorehold-evolution-oracle | `every 360m` | ✅ | 2026-05-27 13:22Z | 1h40min | 🟢 ok | 2026-05-27 19:22Z | sem ação |

## Ações da Rodada Atual (2026-05-27T15:02Z)

| # | ID | Cron | Ação | Motivo | Resultado |
|:-:|:--|:--|:--|:--|:--|
| 1 | `757eefb8738b` | manaloom-master-watchdog | `run` | stale: last_run_at 172min atrás (>120min), every 30m | ✅ trigger aceito; next_run_at ajustado para 2026-05-27T15:03:47Z |
| 2 | `f20ac299992b` | lorehold-deck-scout | `run` | stale: last_run_at 186min atrás (>120min), every 30m | ✅ trigger aceito; next_run_at ajustado para 2026-05-27T15:03:47Z |

**Total:** 2 ações — 0 `resume`, 2 `run`.

## Alertas Pendentes

### 🔴 9 crons com `last_status=error` — padrão sistêmico suspeito

A contagem de erros subiu de **4 → 9** desde o último relatório (13:34Z). 5 crons que estavam mostrando `last_status=ok` (com last_run_at do dia anterior) executaram e agora mostram `error`:

| Cron | Último run | Era ok em | Causa provável |
|:-----|:----------:|:----------|:---------------|
| manaloom-commander-knowledge-deep | 14:56Z | — | já estava error desde o início |
| manaloom-gamechanger-research | 15:01Z | 13:34Z | erro de execução nos últimos 90min |
| manaloom-themes-research | 14:49Z | 13:34Z | erro de execução |
| manaloom-missing-gc-filler | 14:51Z | 13:34Z | erro de execução |
| manaloom-mana-base-validator | 14:40Z | 13:34Z | erro de execução |
| lorehold-deck-scout | 11:56Z | — | já estava stale desde 11:56 |
| lorehold-deck-validator | 14:44Z | 13:34Z | erro de execução |
| manaloom-hermes-daily-deep-audit | 11:42Z | — | erro anterior; próximo ciclo amanhã |
| manaloom-hermes-weekly-memory-cleanup | 12:31Z | — | erro anterior; próximo domingo |

**Hipótese:** O scheduler está funcionando (next_run_at avança, last_run_at se atualiza), mas os jobs estão falhando consistentemente. Possíveis causas:
- Model/provider desatualizado ou não disponível (alguns usam `gpt-5.5`/`copilot` que pode ter mudado)
- Dependências de API que mudaram (Scryfall, EDHREC)
- Problema de permissão no .git/objects que afeta commits dos jobs de conhecimento
- Runtime error de script Python que não foi corrigido

### ⚠️ 2 crons stale com trigger enviado (aguardando scheduler)

| Cron | ID | Status antes | Trigger enviado às |
|:-----|:---|:------------:|:-----------------:|
| manaloom-master-watchdog | `757eefb8738b` | ok (mas 172min sem exec) | 15:02Z |
| lorehold-deck-scout | `f20ac299992b` | error (186min sem exec) | 15:02Z |

Ambos tiveram `next_run_at` reprogramado. Verificar na próxima rodada se `last_run_at` avançou.

## Notas

- Branch confirmada: `codex/hermes-analysis-docs` ✅ (HEAD `9a1ee1410858`)
- `cronjob(action="list", include_disabled=True)` retornou 16 jobs sem `enabled=false`.
- Working tree contém artefatos não relacionados (decks lorehold, scripts de scout, `__pycache__`) — apenas `CRON_STATUS.md` será comitado.
- Nenhum token/secret registrado neste relatório.
- O `master-watchdog` (script-based, `no_agent=true`) é susceptível ao Pattern B (ciclos pulados silenciosamente). O trigger enviado deve resetar o scheduler.

## Recomendação

**Prioridade P1:** Investigar por que 7/7 crons de conhecimento Commander executaram e todos falharam nas últimas 2h. Sugiro:

1. Capturar o output de erro de um cron específico (ex: `manaloom-commander-knowledge-deep` que roda a cada 20min) — verificar logs de erro na interface de crons ou no diretório `/opt/data/cron/output/75eed994c103/`
2. Verificar se `copilot` provider ainda está funcional para os crons que usam `gpt-5.5` + `copilot` (themes-research, lorehold scout/validator/analyst/oracle)
3. Verificar se `deepseek/deepseek-v4-flash` ainda é um provider/model válido

Se os erros forem de provedor/modelo, o fix é simples: atualizar o model/provider nos crons afetados.

---

<!-- commit nonce: 1 -->
