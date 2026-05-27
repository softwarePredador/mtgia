# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-27T17:50Z**

## Resumo

| Métrica | Valor |
|:--|:--:|
| Total de crons (`include_disabled=True`) | 12 |
| Habilitados | 12/12 |
| Desabilitados | 0 |
| `last_status=error` | **2** 🔴 |
| Nunca executaram (`last_run_at=null`) | 0 |
| Stale (>120min atrás, `enabled=true`) | 0 |
| Fleet removidos desde 2026-05-27 | 4 (daily-deep-audit, weekly-memory-cleanup, themes-research, missing-gc-filler) |
| Recuperados nesta sessão | 1 (lorehold-deck-validator, mulligan-analyst) |
| Regredidos nesta sessão | 0 |
| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** 12/12 habilitados ✅. Fleet consolidado em 12 crons. 2 crons em `status=error` (transientes — git push branch-behind + HTTP 502).

**Mudanças desde 16:59Z:**
- `manaloom-commander-knowledge-deep` 🔴 **mantém erro** — 17:46Z falhou (git push branch-behind no final de run que completou com sucesso). Model/provider corretos. Sem ação necessária.
- `manaloom-mana-base-validator` ✅→🔴 **REGREDIU** — 17:24Z falhou com `HTTP 502: Provider returned error`. Erro transitório de provider. Sem ação necessária.
- `manaloom-gamechanger-research` executou 17:48Z ✅
- `manaloom-master-watchdog` executou 17:00Z ✅
- `lorehold-deck-scout` executou 17:29Z ✅
- `lorehold-mulligan-analyst` executou 17:33Z ✅
- **Product code modificado no worktree:** `server/lib/ai/optimization_functional_roles.dart` e `server/lib/edh_bracket_policy.dart` — alterações de session anterior. Branch pode estar behind.

## Crons de Auditoria / Gerenciais

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `757eefb8738b` | manaloom-master-watchdog | `every 30m` | ✅ | 2026-05-27 17:00Z | 50min | 🟢 ok | 2026-05-27 18:04Z | sem ação — rodando normalmente |
| `660397bb97e1` | manaloom-hermes-normal-audit | `0 16,21 * * *` | ✅ | 2026-05-27 16:09Z | 1h41min | 🟢 ok | 2026-05-27 21:00Z | próxima às 21:00Z |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | `30 12 * * 0` | ✅ | 2026-05-27 12:56Z | 4h54min | 🟢 ok | 2026-05-31 12:30Z | aguardando domingo |
| `2d436c71bbf7` | manaloom-manager-watchdog | `every 30m` | ✅ | 2026-05-27 17:00Z | 50min | 🟢 ok | 2026-05-27 18:04Z | **esta execução** |

## Crons de Conhecimento Commander

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `75eed994c103` | manaloom-commander-knowledge-deep | `every 20m` | ✅ | 2026-05-27 17:46Z | 4min | 🔴 error | 2026-05-27 18:06Z | ⚠️ Run completou análise Atraxa mas errou no git push (branch behind). Model: `deepseek-v4-flash`/`deepseek` ✅. Workdir correto ✅. Erro transiente, sem ação. Próximo run em ~18:06Z. |
| `7915cc2377a0` | manaloom-gamechanger-research | `every 20m` | ✅ | 2026-05-27 17:48Z | 2min | 🟢 ok | 2026-05-27 18:08Z | ✅ rodando normalmente |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | `every 360m` | ✅ | 2026-05-27 13:05Z | 4h45min | 🟢 ok | 2026-05-27 19:05Z | próximo ciclo às 19:05Z |
| `444aa9510c2c` | manaloom-mana-base-validator | `every 60m` | ✅ | 2026-05-27 17:24Z | 26min | 🔴 error | 2026-05-27 18:24Z | ⚠️ **REGREDIU** — `HTTP 502: Provider returned error`. Erro transitório de provider. Config OK (model default). Sem ação. Próximo run em ~18:24Z. |

## Lorehold Knowledge Pipeline

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `f20ac299992b` | lorehold-deck-scout | `every 30m` | ✅ | 2026-05-27 17:29Z | 21min | 🟢 ok | 2026-05-27 17:59Z | ✅ rodando normalmente |
| `712579b15767` | lorehold-deck-validator | `every 60m` | ✅ | 2026-05-27 16:42Z | 1h08min | 🟢 ok | 2026-05-27 17:42Z | ✅ estável |
| `08468451a06a` | lorehold-mulligan-analyst | `every 120m` | ✅ | 2026-05-27 17:33Z | 17min | 🟢 ok | 2026-05-27 19:33Z | ✅ **RECUPERADO** — rodando com deepseek |
| `a50bef4c2a59` | lorehold-evolution-oracle | `every 360m` | ✅ | 2026-05-27 13:22Z | 4h28min | 🟢 ok | 2026-05-27 21:29Z | normal para schedule 6h |

## Ações da Rodada Atual (2026-05-27T17:50Z)

| # | ID | Cron | Ação | Motivo | Resultado |
:-:|:--|:--|:--|:--|:--|
| 1 | — | **mestre** | `git branch` check | Branch já correta | ✅ `codex/hermes-analysis-docs` |
| 2 | — | **diagnóstico** | listou 12 crons | 2 erros encontrados | 🔍 analisados |
| 3 | `75eed994c103` | commander-knowledge-deep | diagnóstico | Erro = git push branch-behind (run bem-sucedido, push falhou) | ⏸️ Sem ação — erro transiente, scheduler reintentará em 18:06Z |
| 4 | `444aa9510c2c` | mana-base-validator | diagnóstico | Erro = HTTP 502 provider transiente | ⏸️ Sem ação — scheduler reintentará em 18:24Z |
| 5 | — | observação | mulligan-analyst recuperou | 17:33Z rodou com sucesso | ✅ recuperou naturalmente |
| 6 | — | observação | gamechanger-research rodou | 17:48Z com sucesso | ✅ natural |

## Mudanças desde o Último Relatório (2026-05-27T16:59Z)

| Mudança | Detalhe |
|:--------|:--------|
| Lorehold-mulligan-analyst | **RECUPERADO** ✅ 🔴→✅ — 17:33Z rodou com deepseek sem erro |
| Manaloom-mana-base-validator | **REGREDIU** 🔴 ✅→🔴 — 17:24Z falhou com HTTP 502 (transitório) |
| Manaloom-commander-knowledge-deep | **MANTÉM 🔴** — 17:46Z completou run mas push falhou (branch behind) |
| Manaloom-gamechanger-research | **EXECUTOU** ✅ — 17:48Z |
| Erros totais | 2 (mesmo total, composição mudou: mulligan recuperou, mana-base regrediu) |

## Alertas Pendentes

### 🔴 2 crons com `last_status=error`

| Cron | Último run | Erro | Provider | Model | Workdir | Transiente? |
|:-----|:----------:|:----|:--------:|:-----:|:-------:|:-----------:|
| commander-knowledge-deep | 17:46Z | git push branch-behind (run OK) | `deepseek` | `deepseek-v4-flash` | ✅ correto | ✅ Sim |
| mana-base-validator | 17:24Z | HTTP 502 provider | default | default | ✅ correto | ✅ Sim |

**Nenhuma ação corretiva necessária** — ambos os erros são transitórios. Os crons rodarão novamente em seus próximos ticks (18:06Z e 18:24Z).

### Recuperados hoje (2026-05-27):
- lorehold-mulligan-analyst: 🔴 → 🟢 (17:33Z)
- lorehold-deck-validator: 🔴 → 🟢 (16:42Z, rodada anterior)

### Regredidos hoje (2026-05-27):
- manaloom-mana-base-validator: 🟢 → 🔴 (17:24Z, HTTP 502)

## Observações Importantes

- **Product code modificado no worktree:** `server/lib/ai/optimization_functional_roles.dart` e `server/lib/edh_bracket_policy.dart` apresentam alterações não commitadas (eds de session anterior). Isso causa o branch-behind no commander-knowledge-deep que tenta `git push`. Sem ação do manager — responsabilidade da session que editou.
- Branch confirmada: `codex/hermes-analysis-docs` ✅
- `cronjob(action="list", include_disabled=True)` retornou 12 jobs, todos `enabled=true`.
- **Nenhum `run` ou `resume` foi disparado** — nenhum critério atendido (todos enabled=true, nenhum stale >120min, nenhum never-run, erros são transitórios).
- 2 crons em `last_status=error` — ambos transientes, sem ação corretiva necessária.
- Working tree contém artefatos de cron não relacionados (decks lorehold, scripts de scout, `__pycache__`) — apenas `CRON_STATUS.md` será comitado.
- Nenhum token/secret registrado neste relatório.
