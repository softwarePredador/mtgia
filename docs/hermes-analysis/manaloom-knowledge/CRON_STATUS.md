# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-26T21:42Z**

## Resumo

| Tipo | Total | Ativos | Instância |
|:-----|:-----:|:------:|:----------|
| Conhecimento | 3 | 3 | a cada 20min |
| Auditoria | 5 | 5 | variável |
| Preenchimento GC | 1 | 1 | a cada 20min |
| Precisão Tags | 1 | 1 | a cada 6h |
| Mana Base | 1 | 1 | a cada 60min |
| Gerencial | 1 | 1 | a cada 30min |

**Estado geral:** 12/12 habilitados ✅ — 2 com last_status=error (recuperados via resume, aguardando scheduler).

## Crons de Conhecimento (20min)

| Cron | Última exec | Status | Observação |
|:-----|:-----------:|:------:|:----------|
| manaloom-commander-knowledge-deep | 21:00 | 🔴 error | Resumido nesta rodada — estava disabled+error |
| manaloom-gamechanger-research | 21:12 | 🟢 ok | Resumido — desabilitado por troca de branch |
| manaloom-themes-research | 21:32 | 🟢 ok | Resumido — desabilitado por troca de branch |

## Crons de Auditoria

| Cron | Schedule | Status | Observação |
|:-----|:--------:|:------|:----------|
| manaloom-master-watchdog | 30min | 🟢 OK | Script-based (no agent) |
| manaloom-hermes-normal-audit | 16h,21h | 🟢 trigger manual | 21:00 foi perdido; trigger enviado |
| manaloom-hermes-daily-deep-audit | 11:30 | 🟡 Pendente | Próximo: 2026-05-27 11:30 |
| manaloom-hermes-weekly-memory-cleanup | Dom 12h | 🟡 Pendente | Próximo: 2026-05-31 |
| manaloom-hermes-weekly-parallel-audit | Dom 12:30 | 🟡 Pendente | Próximo: 2026-05-31 |

## Novos Crons (criados 2026-05-26)

| Cron | Schedule | Função | Status |
|:-----|:--------:|:-------|:------|
| manaloom-missing-gc-filler | 20min | Preenche análise dos 32 GCs faltantes | 🟢 Resumido (estava error) |
| manaloom-manager-watchdog | 30min | Monitora e recupera crons | 🟢 Primeira execução |
| manaloom-tag-accuracy-reporter | 6h | Relatório de precisão das tags | 🟡 Aguardando 01:55 |
| manaloom-mana-base-validator | 60min | Valida base de mana vs EDHREC | 🟢 Trigger manual enviado |

## Ações da Rodada Atual (2026-05-26T21:40Z)

| # | Cron | Ação | Resultado |
|:-:|:-----|:----|:----------|
| 1 | manaloom-commander-knowledge-deep | resume (disabled+error) | ✅ Ativado |
| 2 | manaloom-gamechanger-research | resume (branch switch) | ✅ Ativado |
| 3 | manaloom-themes-research | resume (branch switch) | ✅ Ativado |
| 4 | manaloom-missing-gc-filler | resume (disabled+error) | ✅ Ativado |
| 5 | manaloom-hermes-normal-audit | trigger (janela 21:00 perdida) | ✅ Disparado |
| 6 | manaloom-mana-base-validator | trigger (nunca rodou, atrasado) | ✅ Disparado |

**Total:** 6 ações de recuperação — 4 resumes, 2 triggers.

## Notas

- **commander-knowledge-deep** e **missing-gc-filler** terminaram com status=error. Após resume, seus `next_run_at` estão como None — o scheduler deve recalcular na próxima verificação.
- **master-watchdog** (script-based) está funcional mas tem 1h53min desde última execução (próximo: 21:07) — dentro da janela de 30min mas pode estar atrasado.
- Nenhum cron com token/secret exposto. Nenhuma branch errada detectada.

## Scorecard de Otimização

| Tentativa | Alvo | Resultado |
|:----------|:-----|:----------|
| 1 | produção --limit 10 | Timeout 120s |
| 2 | produção --limit 5 | Timeout 207s |
| 3 | localhost:8084 --limit 5 | Rodando... |

## Precisão das Functional Tags (último relatório)

*Atualizado pelo cron manaloom-tag-accuracy-reporter*