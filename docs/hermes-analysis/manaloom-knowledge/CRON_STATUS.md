# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-27T16:59Z**

## Resumo

| Métrica | Valor |
|:--|:--:|
| Total de crons (`include_disabled=True`) | 12 |
| Habilitados | 12/12 |
| Desabilitados | 0 |
| `last_status=error` | **2** 🔴 (mesmo total desde 16:22Z, mas composição mudou) |
| Nunca executaram (`last_run_at=null`) | 0 |
| Stale (>120min atrás, `enabled=true`) | 0 |
| Fleet removidos desde última rodada | 4 (daily-deep-audit, weekly-memory-cleanup, themes-research, missing-gc-filler) |
| Recuperados desde 16:22Z | 1 (lorehold-deck-validator) |
| Regredidos desde 16:22Z | 1 (commander-knowledge-deep) |
| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** 12/12 habilitados ✅. Fleet consolidado em 12 crons. 2 crons em `status=error` 🔴 (mesmo total que 16:22Z, mas composição mudou — deck-validator recuperou, commander-knowledge-deep regrediu).

**Mudanças desde 16:22Z:**
- `lorehold-deck-validator` 🔴→✅ **RECUPERADO** — 16:42Z rodou com sucesso 🎉
- `commander-knowledge-deep` ✅→🔴 **REGREDIU** — 16:36Z falhou. Workdir estava errado.
- `lorehold-deck-scout` executou 16:52Z ✅
- `manaloom-master-watchdog` executou 16:26Z ✅
- Workdir do commander-knowledge-deep **CORRIGIDO** → `/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge` ✅

## Crons de Auditoria / Gerenciais

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--|
| `757eefb8738b` | manaloom-master-watchdog | `every 30m` | ✅ | 2026-05-27 16:26Z | 33min | 🟢 ok | 2026-05-27 17:27Z | sem ação — rodando normalmente |
| `660397bb97e1` | manaloom-hermes-normal-audit | `0 16,21 * * *` | ✅ | 2026-05-27 16:09Z | 50min | 🟢 ok | 2026-05-27 21:00Z | executou às 16:09Z ✅, próxima às 21:00Z |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | `30 12 * * 0` | ✅ | 2026-05-27 12:56Z | 4h03min | 🟢 ok | 2026-05-31 12:30Z | aguardando domingo |
| `2d436c71bbf7` | manaloom-manager-watchdog | `every 30m` | ✅ | 2026-05-27 16:26Z | 33min | 🟢 ok | 2026-05-27 17:27Z | **esta execução** |

## Crons de Conhecimento Commander

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--|
| `75eed994c103` | manaloom-commander-knowledge-deep | `every 20m` | ✅ | 2026-05-27 16:36Z | 23min | 🔴 error | 2026-05-27 17:00Z | ❌ **REGREDIU** — 16:36Z falhou (`agent reported failure`, combinação de HTTP 429 + gpt-5.5 residuals + workdir errado). Workdir **CORRIGIDO** nesta rodada → `/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge`. Próximo run iminente (~17:00Z). |
| `7915cc2377a0` | manaloom-gamechanger-research | `every 20m` | ✅ | 2026-05-27 16:22Z | 37min | 🟢 ok | 2026-05-27 17:00Z | ✅ rodando com deepseek funcional |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | `every 360m` | ✅ | 2026-05-27 13:05Z | 3h54min | 🟢 ok | 2026-05-27 19:05Z | próximo ciclo às 19:05Z |
| `444aa9510c2c` | manaloom-mana-base-validator | `every 60m` | ✅ | 2026-05-27 16:11Z | 48min | 🟢 ok | 2026-05-27 17:11Z | ✅ rodando com deepseek funcional |

## Lorehold Knowledge Pipeline

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--|
| `f20ac299992b` | lorehold-deck-scout | `every 30m` | ✅ | 2026-05-27 16:52Z | 7min | 🟢 ok | 2026-05-27 17:22Z | ✅ rodando normalmente |
| `712579b15767` | lorehold-deck-validator | `every 60m` | ✅ | 2026-05-27 16:42Z | 17min | 🟢 ok | 2026-05-27 17:42Z | ✅ **RECUPERADO** — 16:42Z rodou com sucesso! |
| `08468451a06a` | lorehold-mulligan-analyst | `every 120m` | ✅ | 2026-05-27 15:21Z | 1h38min | 🔴 error | 2026-05-27 17:29Z | ❌ Model `gpt-5.5` no último run (config copilot anterior). Config já corrigida para deepseek ✅. Aguardando scheduler (~17:29Z) |
| `a50bef4c2a59` | lorehold-evolution-oracle | `every 360m` | ✅ | 2026-05-27 13:22Z | 3h37min | 🟢 ok | 2026-05-27 21:29Z | normal para schedule 6h |

## Ações da Rodada Atual (2026-05-27T16:59Z)

| # | ID | Cron | Ação | Motivo | Resultado |
|:-:|:--|:--|:--|:--|:--|
| 1 | — | **mestre** | `git fetch/pull` | Branch `codex/hermes-analysis-docs` já atualizada | ✅ ff-only aplicado |
| 2 | — | **diagnóstico** | diagnosticou 12 crons | 2 erros (commander-knowledge-deep + mulligan-analyst) | 🔍 dados coletados |
| 3 | `75eed994c103` | **commander-knowledge-deep** | `cronjob(update, workdir=...)` | Workdir `/opt/data/workspace/mtgia` → `/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge` | ✅ workdir corrigido |
| 4 | — | **observação** | deck-validator recuperou 🔴→✅ | rodada 16:42Z executou com sucesso | ✅ recuperação natural via scheduler |
| 5 | — | **observação** | commander-knowledge-deep regrediu ✅→🔴 | rodada 16:36Z falhou (workdir errado + config residual) | 🔴 workdir corrigido, aguardando scheduler |

## Mudanças desde o Último Relatório (2026-05-27T16:22Z)

| Mudança | Detalhe |
|:--------|:--------|
| Lorehold-deck-validator | **RECUPERADO** ✅ 🔴→✅ — 16:42Z rodou com deepseek funcional |
| Commander-knowledge-deep | **REGREDIU** 🔴 ✅→🔴 — 16:36Z falhou. Workdir CORRIGIDO nesta rodada |
| Lorehold-deck-scout | **EXECUTOU** ✅ — 16:52Z completada |
| Manaloom-master-watchdog | **EXECUTOU** ✅ — 16:26Z completada |
| Commander-knowledge-deep workdir | **CORRIGIDO** ✅ → `/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge` |
| Erros totais | 2 (mesmo total, composição mudou) |

## Alertas Pendentes

### 🔴 2 crons com `last_status=error`

| Cron | Último run | Erro | Provider | Model | Workdir |
|:-----|:----------:|:----|:--------:|:-----:|:-------:|
| commander-knowledge-deep | 16:36Z | agent reported failure (429 + gpt-5.5 residuals + workdir) | `deepseek` | `deepseek-v4-flash` | ✅ **CORRIGIDO** agora |
| mulligan-analyst | 15:21Z | gpt-5.5 not accessible | `deepseek` | `deepseek-v4-flash` | ✅ já correto |

**Próximo ciclo previsto:** commander-knowledge-deep ~17:00Z, mulligan-analyst ~17:29Z.

### 1 cron que se recuperou nesta rodada:
- lorehold-deck-validator: 🔴 (14:44Z, HTTP 429) → 🟢 (16:42Z) ✅

### 1 cron que regrediu nesta rodada:
- commander-knowledge-deep: 🟢 (15:38Z) → 🔴 (16:36Z, agent reported failure) — workdir corrigido

## Notas

- Branch confirmada: `codex/hermes-analysis-docs` ✅
- `cronjob(action="list", include_disabled=True)` retornou 12 jobs, todos `enabled=true`.
- **Nenhum `run` ou `resume` foi disparado** — os critérios da PASSO 2 não foram atendidos (todos enabled=true, nenhum stale >120min, nenhum never-run). As correções foram estruturais (workdir).
- 2 crons em `last_status=error` (mesmo total desde 16:22Z, mas composição mudou).
- 1 cron recuperou (deck-validator), 1 cron regrediu (commander-knowledge-deep) — agora com workdir corrigido.
- Working tree contém artefatos de cron não relacionados (decks lorehold, scripts de scout, `__pycache__`) — apenas `CRON_STATUS.md` será comitado.
- Nenhum token/secret registrado neste relatório.
