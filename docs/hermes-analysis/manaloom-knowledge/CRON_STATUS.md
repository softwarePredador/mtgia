# ManaLoom Cron Status

> Relatorio gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.

## Resumo

| Tipo | Total | Ativos | Instancia |
|:-----|:-----:|:------:|:----------|
| Conhecimento | 3 | 3 | a cada 20min |
| Auditoria | 5 | 5 | variavel |
| Preenchimento GC | 1 | 1 | a cada 20min |
| Precisao Tags | 1 | 1 | a cada 6h |
| Mana Base | 1 | 1 | a cada 60min |
| Gerencial | 1 | 1 | a cada 30min |

## Crons de Conhecimento (20min)

| Cron | Ultima exec | Status | Observacao |
|:-----|:-----------:|:------:|:----------|
| manaloom-commander-knowledge-deep | 18:19 | reativado | Erro ao trocar branch - resolvido |
| manaloom-gamechanger-research | 17:22 | reativado | Foi bem, parou ao trocar branch |
| manaloom-themes-research | 17:51 | reativado | Erro ao trocar branch - resolvido |

## Crons de Auditoria

| Cron | Schedule | Status |
|:-----|:--------:|:------|
| manaloom-master-watchdog | 30min | OK |
| manaloom-hermes-normal-audit | 16h,21h | OK |
| manaloom-hermes-daily-deep-audit | 11:30 | Pendente |
| manaloom-hermes-weekly-memory-cleanup | Dom 12h | Pendente |
| manaloom-hermes-weekly-parallel-audit | Dom 12:30 | Pendente |

## Novos Crons (criados 2026-05-26)

| Cron | Schedule | Funcao |
|:-----|:--------:|:-------|
| manaloom-missing-gc-filler | 20min | Preenche analise dos 32 GCs faltantes |
| manaloom-manager-watchdog | 30min | Monitora e recupera crons |
| manaloom-tag-accuracy-reporter | 6h | Relatorio de precisao das tags |
| manaloom-mana-base-validator | 60min | Valida base de mana vs EDHREC |

## Scorecard de Otimizacao

| Tentativa | Alvo | Resultado |
|:----------|:-----|:----------|
| 1 | producao --limit 10 | Timeout 120s |
| 2 | producao --limit 5 | Timeout 207s |
| 3 | localhost:8084 --limit 5 | Rodando... |

## Precisao das Functional Tags (ultimo relatorio)

*Atualizado pelo cron manaloom-tag-accuracy-reporter*