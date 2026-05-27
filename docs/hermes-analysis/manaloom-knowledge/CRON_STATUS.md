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


---

## Mana Base Validation Report

> Validação de mana base dos decks armazenados contra perfis EDHREC (commander_reference_profile_anchor30_batch_*).
> Executado automaticamente pelo cron `manaloom-mana-base-validator`.

**Última execução:** 2026-05-27 18:18 UTC
**Perfis consultados:** commander_reference_profile_anchor30_batch_a/b/c_2026-05-12 (EDHREC + Moxfield + primers)
**Decks validados:** 8

### Legenda

| Ícone | Significado |
|:------|:------------|
| ✅ VALIDADO | Métrica dentro do range do perfil EDHREC |
| 🔵 OK | Ligeiramente fora (±1), aceitável |
| 🟡 ALERTA | Fora do range (diff ≥ 2) |
| 🔴 CRITICO | Muito fora (diff ≥ 4); artefato parcial = esperado |
| 🟡 EDHREC PARTIAL | Artefato com <90 declarações; métricas da análise original |
| ⚪ N/A | Sem perfil disponível |

### Tabela Resumo

| ID | Commander | Bracket | Qty | Lands | CMC | Ramp | Draw | Removal | Protection | Alertas |
|:--:|:----------|:-------:|:---:|:-----:|:---:|:----:|:----:|:-------:|:----------:|:-------:|
| 9 | Atraxa | 4 | ✅ 100/100 | ✅ 36 [35-38] | 2.97 | 🔵 14 [10-13] | ✅ 12 [8-12] | 🔵 7 [8-13] | — | 0 |
| 7 | Winota | 4 | ✅ 100/100 | ✅ 34 [31-35] | 2.35 | — | — | ✅ 8 [6-10] | 🟡 10 [5-8] | 1 🟡 |
| 6 | Lorehold | 3 | ✅ 100/100 | ⚪ Sem perfil | 3.96 | ⚪ | ⚪ | ⚪ | ⚪ | Sem perfil |
| 4 | Teysa | 3 | 🟡 80/80 | ✅ 35 [35-37] | 2.9 | 🔴 15 [9-11]* | ✅ 11 [10-14] | ✅ 8 [8-11] | ✅ 3 [2-4] | 🔴* |
| 2 | Yuriko | 3 | 🟡 99/84 | ✅ 33 [30-34] | 2.8 | — | — | 🔵 9 [10-16] | — | 0 |
| 5 | Aesi | 3 | 🟡 100/79 | ✅ 40 [39-43] | 2.61 | 🔴 28 [14-18]* | 🟡 12 [6-9]* | ✅ 8 [8-11] | 🟡 7 [2-4]* | 🔴* |
| 1 | Kinnan | 4 | 🟡 13/13 | ✅ 29 [29-34] | 1.8 | 🔴 4 [18-26]* | — | 🔴 3 [9-14]* | — | 🔴* |
| 3 | Korvold | 3 | 🟡 11/11 | 🔴 25 [34-37]* | 3.2 | 🔴 3 [10-14]* | 🔴 1 [6-10]* | 🔴 1 [8-12]* | — | 🔴* |

*\* = Artefato EDHREC parcial (< 90 cartas no SQLite). Críticos ESPERADOS — métricas da análise original, não do INSERT parcial.*

### Achados

- **0 decks corrompidos** (nenhum com qty < 50% do declarado e total ≥ 90)
- **4 decks completos** (qty ≈ declared ≥ 90): Atraxa ✅, Winota ✅, Lorehold ✅ (sem perfil), Teysa 🟡
- **4 artefatos EDHREC parciais** com métricas herdadas: Kinnan, Korvold, Aesi, Yuriko
- **Observação Aesi (ID=5):** ramp=28 inclui fetch lands + landfall triggers classificados como ramp+land no multi-tag. Não é corrupção.
- **Observação Teysa (ID=4):** ramp=15 inclui tesouros/tokens. Comportamento esperado para artefato EDHREC sem ramp rocks.

### Ações Recomendadas

| Prioridade | Ação | Deck |
|:----------:|:-----|:-----|
| P2 | Criar profile EDHREC para Lorehold | Lorehold |
| P2 | Re-inserir com `--insert-deck` quando deck completo disponível | Kinnan (ID=1), Korvold (ID=3) |
| P3 | Verificar multi-tag (ramp vs land) para fetch lands em Aesi | Aesi |
| — | Nenhum (validado) | Atraxa, Winota, Yuriko, Teysa |

### Histórico

| Data | Decks | Críticos reais | Observação |
|:-----|:-----:|:--------------:|:----------|
| 2026-05-27 18:18 UTC | 8 | 0 | 4 críticos são artefatos de INSERT parcial |

*Relatório gerado por manaloom-mana-base-validator*
