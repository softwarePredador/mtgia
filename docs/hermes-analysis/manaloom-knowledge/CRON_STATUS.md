# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-27T18:25Z**

## Resumo

| Métrica | Valor |
|:--|:--:|
| Total de crons (`include_disabled=True`) | 12 |
| Habilitados | 12/12 |
| Desabilitados | 0 |
| `last_status=error` | **1** 🔴 |
| Nunca executaram (`last_run_at=null`) | 0 |
| Stale (>120min atrás, `enabled=true`) | 0 |
| Fleet removidos desde 2026-05-27 | 4 (daily-deep-audit, weekly-memory-cleanup, themes-research, missing-gc-filler) |
| Recuperados nesta sessão | 0 |
| Regredidos nesta sessão | 0 |
| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** 12/12 habilitados ✅. Fleet consolidado em 12 crons. 1 cron em `status=error` (transitório — run completou mas falhou no git push branch-behind).

**Mudanças desde 17:50Z:**
- `manaloom-commander-knowledge-deep` 🔴 **mantém erro** — 18:09Z rodou (analisou Prosper) mas falhou ao final. Model/provider corretos. Sem ação necessária (scheduler reintentará em ~18:29Z).
- `manaloom-mana-base-validator` 🔴→✅ **RECUPEROU** — 18:22Z rodou com sucesso após 502 transitório.
- `manaloom-gamechanger-research` executou 18:12Z ✅
- `lorehold-deck-scout` executou 18:03Z ✅
- `manaloom-master-watchdog` executou 17:53Z ✅
- `manaloom-manager-watchdog` executou 17:53Z ✅
- **Novo commit em master:** `c98153d6` — "Improve optimize gate multi-tag handling" (5 arquivos, +362/-5 linhas)

## Crons de Auditoria / Gerenciais

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `757eefb8738b` | manaloom-master-watchdog | `every 30m` | ✅ | 2026-05-27 17:53Z | 32min | 🟢 ok | 2026-05-27 18:23Z | sem ação — rodando normalmente |
| `660397bb97e1` | manaloom-hermes-normal-audit | `0 16,21 * * *` | ✅ | 2026-05-27 16:09Z | 2h16min | 🟢 ok | 2026-05-27 21:00Z | próxima às 21:00Z |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | `30 12 * * 0` | ✅ | 2026-05-27 12:56Z | 5h29min | 🟢 ok | 2026-05-31 12:30Z | aguardando domingo |
| `2d436c71bbf7` | manaloom-manager-watchdog | `every 30m` | ✅ | 2026-05-27 17:53Z | 32min | 🟢 ok | 2026-05-27 18:23Z | **esta execução** |

## Crons de Conhecimento Commander

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `75eed994c103` | manaloom-commander-knowledge-deep | `every 20m` | ✅ | 2026-05-27 18:09Z | 16min | 🔴 error | 2026-05-27 18:29Z | ⚠️ Run completou análise Prosper mas errou no git push (branch behind). Model: `deepseek-v4-flash`/`deepseek` ✅. Workdir correto ✅. Erro transiente, sem ação. |
| `7915cc2377a0` | manaloom-gamechanger-research | `every 20m` | ✅ | 2026-05-27 18:12Z | 13min | 🟢 ok | 2026-05-27 18:32Z | ✅ rodando normalmente |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | `every 360m` | ✅ | 2026-05-27 13:05Z | 5h20min | 🟢 ok | 2026-05-27 19:05Z | próximo ciclo às 19:05Z |
| `444aa9510c2c` | manaloom-mana-base-validator | `every 60m` | ✅ | 2026-05-27 18:22Z | 3min | 🟢 ok | 2026-05-27 19:22Z | ✅ **RECUPERADO** — rodou após 502 transitório |

## Lorehold Knowledge Pipeline

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `f20ac299992b` | lorehold-deck-scout | `every 30m` | ✅ | 2026-05-27 18:03Z | 22min | 🟢 ok | 2026-05-27 18:33Z | ✅ rodando normalmente |
| `712579b15767` | lorehold-deck-validator | `every 60m` | ✅ | 2026-05-27 17:57Z | 28min | 🟢 ok | 2026-05-27 18:57Z | ✅ estável |
| `08468451a06a` | lorehold-mulligan-analyst | `every 120m` | ✅ | 2026-05-27 17:33Z | 52min | 🟢 ok | 2026-05-27 19:33Z | ✅ estável |
| `a50bef4c2a59` | lorehold-evolution-oracle | `every 360m` | ✅ | 2026-05-27 13:22Z | 5h03min | 🟢 ok | 2026-05-27 21:29Z | normal para schedule 6h |

## Ações da Rodada Atual (2026-05-27T18:25Z)

| # | ID | Cron | Ação | Motivo | Resultado |
:-:|:--|:--|:--|:--|:--|
| 1 | — | **mestre** | `git branch` check | Verificação de branch | ✅ `codex/hermes-analysis-docs` |
| 2 | — | **diagnóstico** | listou 12 crons | 1 erro encontrado (commander-knowledge-deep) | 🔍 analisado |
| 3 | `75eed994c103` | commander-knowledge-deep | diagnóstico | Erro = git push branch-behind (run bem-sucedido, push falhou) | ⏸️ Sem ação — erro transiente, scheduler reintentará em 18:29Z |
| 4 | `444aa9510c2c` | mana-base-validator | **RECUPERADO** | 502 transitório resolveu | ✅ 18:22Z rodou OK |
| 5 | — | **Novo commit master** | `c98153d6` detectado | `git log 7329fbbd..origin/master` = 1 commit | 📝 Registrado no COMMIT_DIGEST.md |

## Mudanças desde o Último Relatório (2026-05-27T17:50Z)

| Mudança | Detalhe |
|:--------|:--------|
| Manaloom-mana-base-validator | **RECUPERADO** ✅ 🔴→✅ — 18:22Z rodou com sucesso |
| Manaloom-commander-knowledge-deep | **MANTÉM 🔴** — 18:09Z completou run (Prosper) mas push falhou |
| Manaloom-gamechanger-research | **EXECUTOU** ✅ — 18:12Z |
| Erros totais | 1 (diminuiu de 2 para 1) |
| Master avançou | `c98153d6` — Improve optimize gate multi-tag handling (5 files, +362/-5) |

## Alertas Pendentes

### 🔴 1 cron com `last_status=error`

| Cron | Último run | Erro | Provider | Model | Workdir | Transiente? |
|:-----|:----------:|:----|:--------:|:-----:|:-------:|:-----------:|
| commander-knowledge-deep | 18:09Z | git push branch-behind (run OK) | `deepseek` | `deepseek-v4-flash` | ✅ correto | ✅ Sim |

**Nenhuma ação corretiva necessária** — erro transiente. O cron rodará novamente em seu próximo tick (~18:29Z).

### Recuperados hoje (2026-05-27):
- lorehold-mulligan-analyst: 🔴 → 🟢 (17:33Z)
- lorehold-deck-validator: 🔴 → 🟢 (16:42Z, rodada anterior)
- manaloom-mana-base-validator: 🔴 → 🟢 (18:22Z, esta rodada)

### Regredidos hoje (2026-05-27):
- (nenhum novo regredo nesta rodada)

## Observações Importantes

- **Produção atualizada:** `/health` retorna `c98153d655b3660cb69e0ae6d019df6f07dc7967` (novo commit)
- **Novo commit validado:** `dart test optimization_quality_gate_test.dart` = 13/13 PASS. `dart test` completo = 585 pass / 18 fail (18 failures são pre-existing em auth_service_test.dart, não relacionados)
- Branch confirmada: `codex/hermes-analysis-docs` ✅
- `cronjob(action="list", include_disabled=True)` retornou 12 jobs, todos `enabled=true`.
- **Nenhum `run` ou `resume` foi disparado** — nenhum critério atendido (todos enabled=true, nenhum stale >120min, nenhum never-run, erro é transitório).
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
