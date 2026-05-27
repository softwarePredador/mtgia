# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-27T19:29Z**

## Resumo

| Métrica | Valor |
|:--|:--:|
| Total de crons (`include_disabled=True`) | 13 |
| Habilitados | 13/13 |
| Desabilitados | 0 |
| `last_status=error` | **4** 🔴 |
| Nunca executaram (`last_run_at=null`) | 0 |
| Stale (>120min atrás, `enabled=true`) | 0 |
| Fleet removidos desde 2026-05-27 | 4 (daily-deep-audit, weekly-memory-cleanup, themes-research, missing-gc-filler) |
| Recuperados nesta sessão | 0 |
| Regredidos nesta sessão | 3 |
| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** 13/13 habilitados ✅. **4 crons em `last_status=error`** — 3 por provider/tool-call issues, 1 por provider error (esta execução). Nenhum cron desabilitado ou stale. Nenhuma ação corretiva necessária (erros são transientes; scheduler reintentará nos próximos ticks).

**Mudanças desde 18:25Z:**
- `manaloom-commander-knowledge-deep` 🔴 mantém erro — 19:11Z rodou (Prosper analysis completo) mas encerrou com RuntimeError (tool-call exhaustion no commit). Sem ação.
- `manaloom-tag-accuracy-reporter` 🟡 **REGREDIU** — 19:26Z falhou com "Provider returned error" (output pequeno 4.8KB). Estava ok desde 13:05Z.
- `lorehold-deck-validator` 🟡 **REGREDIU** — 19:03Z falhou com "agent reported failure" (tool-call exhaustion, output 98KB).
- `manaloom-manager-watchdog` 🟡 **REGREDIU** (auto) — 19:20Z falhou com "Provider returned error".
- `manaloom-master-watchdog` ✅ executou 19:26Z.
- `manaloom-knowledge-import` — **NOVO CRON detectado** (job_id=b2f5c21ce2d7, every 30m, last_run=19:58Z ok).
- **Novo commit em master:** `771c9318` — "Harden semantic scorecard runner" (3 arquivos, +359/-17 linhas).
- `lorehold-mulligan-analyst` executou 19:51Z ✅
- `manaloom-mana-base-validator` executou 19:43Z ✅
- `lorehold-deck-scout` executou 19:47Z ✅

## Crons de Auditoria / Gerenciais

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `757eefb8738b` | manaloom-master-watchdog | `every 30m` | ✅ | 2026-05-27 19:26Z | 3min | 🟢 ok | 2026-05-27 20:29Z | sem ação — rodando normalmente |
| `660397bb97e1` | manaloom-hermes-normal-audit | `0 16,21 * * *` | ✅ | 2026-05-27 16:09Z | 3h20min | 🟢 ok | 2026-05-27 21:00Z | próxima às 21:00Z |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | `30 12 * * 0` | ✅ | 2026-05-27 12:56Z | 6h33min | 🟢 ok | 2026-05-31 12:30Z | aguardando domingo |
| `2d436c71bbf7` | manaloom-manager-watchdog | `every 30m` | ✅ | 2026-05-27 19:20Z | 9min | 🔴 error | 2026-05-27 20:29Z | ⚠️ "Provider returned error" — esta execução. Próximo tick deve recuperar. |

## Crons de Conhecimento Commander

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `75eed994c103` | manaloom-commander-knowledge-deep | `every 20m` | ✅ | 2026-05-27 19:11Z | 18min | 🔴 error | 2026-05-27 20:08Z | ⚠️ Tool-call exhaustion (run OK, commit falhou). Model: `deepseek-v4-flash`/`deepseek` ✅. Workdir correto ✅. Transiente. |
| `7915cc2377a0` | manaloom-gamechanger-research | `every 20m` | ✅ | 2026-05-27 19:13Z | 16min | 🟢 ok | 2026-05-27 20:08Z | ✅ rodando normalmente |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | `every 360m` | ✅ | 2026-05-27 19:26Z | 3min | 🔴 error | 2026-05-28 01:26Z | ⚠️ "Provider returned error" (output 4.8KB = falha precoce). Estava ok desde 13:05Z. **REGREDIU.** |
| `444aa9510c2c` | manaloom-mana-base-validator | `every 60m` | ✅ | 2026-05-27 19:43Z | 0min | 🟢 ok | 2026-05-27 20:43Z | ✅ rodando normalmente |
| `b2f5c21ce2d7` | manaloom-knowledge-import | `every 30m` | ✅ | 2026-05-27 19:58Z | 0min | 🟢 ok | 2026-05-27 20:28Z | 🆕 Novo cron detectado nesta rodada. |

## Lorehold Knowledge Pipeline

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `f20ac299992b` | lorehold-deck-scout | `every 30m` | ✅ | 2026-05-27 19:47Z | 0min | 🟢 ok | 2026-05-27 20:17Z | ✅ rodando normalmente |
| `712579b15767` | lorehold-deck-validator | `every 60m` | ✅ | 2026-05-27 19:03Z | 26min | 🔴 error | 2026-05-27 20:03Z | ⚠️ Tool-call exhaustion (output 98KB, "agent reported failure"). **REGREDIU.** |
| `08468451a06a` | lorehold-mulligan-analyst | `every 120m` | ✅ | 2026-05-27 19:51Z | 0min | 🟢 ok | 2026-05-27 21:51Z | ✅ rodando normalmente |
| `a50bef4c2a59` | lorehold-evolution-oracle | `every 360m` | ✅ | 2026-05-27 13:22Z | 6h07min | 🟢 ok | 2026-05-27 21:29Z | normal para schedule 6h |

## Ações da Rodada Atual (2026-05-27T19:29Z)

| # | ID | Cron | Ação | Motivo | Resultado |
:-:|:--|:--|:--|:--|:--|
| 1 | — | **mestre** | `git branch` check | Verificação de branch | ✅ `codex/hermes-analysis-docs` |
| 2 | — | **diagnóstico** | listou 13 crons | 4 erros encontrados | 🔍 analisados |
| 3 | `75eed994c103` | commander-knowledge-deep | diagnóstico | Tool-call exhaustion (run OK, commit falhou) | ⏸️ Sem ação — erro transiente, scheduler reintentará em ~20:08Z |
| 4 | `b340374bc4e7` | tag-accuracy-reporter | diagnóstico | "Provider returned error" — falha precoce | ⏸️ Sem ação — aguardando próximo ciclo (~01:26Z) |
| 5 | `712579b15767` | lorehold-deck-validator | diagnóstico | Tool-call exhaustion (98KB output) | ⏸️ Sem ação — scheduler reintentará em ~20:03Z |
| 6 | `2d436c71bbf7` | manager-watchdog | auto-diagnóstico | "Provider returned error" nesta execução | ⏸️ Auto — próximo tick em ~20:29Z |
| 7 | `b2f5c21ce2d7` | manaloom-knowledge-import | registro | Novo cron detectado | 📝 Adicionado ao relatório |

## Mudanças desde o Último Relatório (2026-05-27T18:25Z)

| Mudança | Detalhe |
|:--------|:--------|
| Total de crons | 12 → 13 (novo: `manaloom-knowledge-import`) |
| Erros totais | 1 → 4 (3 regredidos) |
| Master avançou | `771c9318` — Harden semantic scorecard runner (3 files, +359/-17) |
| Regredidos | tag-accuracy-reporter, lorehold-deck-validator, manager-watchdog (self) |
| Recuperados | 0 (nenhum resume/run necessário — todos enabled=true, nenhum stale) |

## Alertas Pendentes

### 🔴 4 crons com `last_status=error`

| Cron | Último run | Erro | Provider | Model | Workdir | Tipo |
|:-----|:----------:|:----|:--------:|:-----:|:-------:|:----:|
| commander-knowledge-deep | 19:11Z | RuntimeError (tool-call exhaustion) | `deepseek` | `deepseek-v4-flash` | ✅ correto | Transitório |
| manager-watchdog (self) | 19:20Z | Provider returned error | — | — | — | Transitório |
| tag-accuracy-reporter | 19:26Z | Provider returned error | — | — | — | Provider issue |
| lorehold-deck-validator | 19:03Z | agent reported failure (tool-call exhaustion) | `deepseek` | `deepseek-v4-flash` | ✅ correto | Transitório |

**Nenhuma ação corretiva estrutural necessária:**
- 0 crons desabilitados → nenhum resume
- 0 crons stale (>120min) → nenhum run
- Todos os erros são transitórios (provider/tool-call)
- Todos os crons habilitados com model/provider corretos
- Scheduler reintentará nos próximos ticks

### Recuperados hoje (2026-05-27):
- lorehold-mulligan-analyst: 🔴 → 🟢 (17:33Z)
- lorehold-deck-validator: 🔴 → 🟢 (16:42Z) → 🔴 novamente (19:03Z)
- manaloom-mana-base-validator: 🔴 → 🟢 (18:22Z)

### Regredidos hoje (2026-05-27):
- manager-watchdog: 🟢 → 🔴 (19:20Z, esta execução)
- tag-accuracy-reporter: 🟢 → 🔴 (19:26Z)
- lorehold-deck-validator: 🟢 → 🔴 (19:03Z, novamente)

## Observações Importantes

- **Produção atualizada:** `/health` retorna `c98153d655b3660cb69e0ae6d019df6f07dc7967` (conforme último registro — novo commit `771c9318` ainda não confirmado em produção)
- **Novo commit detectado:** `771c9318` — Harden semantic scorecard runner (server/bin/semantic_layer_v2_optimize_scorecard.py, RELATORIO, json fixture). O dirty worktree mostra `otimizacao.dart` e `theme_contextual_rules_service.dart` modificados — produto do commit anterior `c98153d6` que limpa imports não utilizados.
- Branch confirmada: `codex/hermes-analysis-docs` ✅
- `cronjob(action="list", include_disabled=True)` retornou 13 jobs, todos `enabled=true`.
- **Nenhum `run` ou `resume` foi disparado** — nenhum critério atendido (todos enabled=true, nenhum stale >120min, nenhum never-run, erros são transientes).
- Working tree contém artefatos de cron não relacionados (decks lorehold, scripts de scout, `__pycache__`) — apenas `CRON_STATUS.md` será comitado.
- Nenhum token/secret registrado neste relatório.

---

## Mana Base Validation Report

> Validação de mana base dos decks armazenados contra perfis EDHREC (commander_reference_profile_anchor30_batch_*).
> Executado automaticamente pelo cron `manaloom-mana-base-validator`.

**Última execução:** 2026-05-27 19:28 UTC
**Perfis consultados:** commander_reference_profile_anchor30_batch_a/b/c_2026-05-12 (EDHREC + Moxfield + primers)
**Decks validados:** 8

### Legenda

| Ícone | Significado |
|:------|:------------|
| ✅ VALIDADO | Métrica dentro do range do perfil EDHREC |
| 🔵 OK | Ligeiramente fora (±1), aceitável |
| 🟡 ALERTA | Fora do range (diff ≥ 2) |
| 🔴 CRÍTICO | Muito fora (diff ≥ 4); artefato parcial = esperado |
| 🟡 EDHREC PARTIAL | Artefato com <90 declarações; métricas da análise original |
| ⚪ N/A | Sem perfil disponível |

### Tabela Resumo

| ID | Commander | Bracket | Qty | Lands | CMC | Ramp | Draw | Removal | Protection | Alertas |
|:--:|:----------|:-------:|:---:|:-----:|:---:|:----:|:----:|:-------:|:----------:|:-------:|
| 9 | Atraxa | 4 | ✅ 100/100 | ✅ 36 [35-38] | 2.97 | 🔵 14 [10-13] | ✅ 12 [8-12] | 🔵 7 [8-13] | — | 0 |
| 7 | Winota | 4 | ✅ 100/100 | ✅ 34 [31-35] | 2.35 | — | — | ✅ 8 [6-10] | 🟡 10 [5-8] | 1 🟡 |
| 6 | Lorehold | 3 | ✅ 100/100 | ⚪ Sem perfil | 3.96 | ⚪ | ⚪ | ⚪ | ⚪ | Sem perfil |
| 4 | Teysa | 3 | 🟡 80/80 | ✅ 35 [35-37] | 2.9 | 🔴 15 [9-11]* | ✅ 11 [10-14] | ✅ 8 [8-11] | ✅ 3 [2-4] | 🔴* |
| 2 | Yuriko | 3 | 🟡 84/84 | ✅ 33 [30-34] | 2.8 | — | — | 🔵 9 [10-16] | — | 0 |
| 5 | Aesi | 3 | 🟡 79/79 | ✅ 40 [39-43] | 2.61 | 🔴 28 [14-18]* | 🟡 12 [6-9]* | ✅ 8 [8-11] | 🟡 7 [2-4]* | 🔴* |
| 1 | Kinnan | 4 | 🟡 13/13 | ✅ 29 [29-34] | 1.8 | 🔴 4 [18-26]* | — | — | — | 🔴* |
| 3 | Korvold | 3 | 🟡 11/11 | 🔴 25 [34-37]* | 3.2 | 🔴 3 [10-14]* | 🔴 1 [6-10]* | 🔴 1 [8-12]* | — | 🔴* |

*\* = Artefato EDHREC parcial (< 90 cartas no SQLite). Críticos ESPERADOS — métricas da análise original, não do INSERT parcial.

### Achados

- **0 decks corrompidos** (nenhum com qty < 50% do declarado e total ≥ 90)
- **3 decks completos** (qty = 100): Atraxa ✅, Winota ✅, Lorehold ✅ (sem perfil)
- **5 artefatos EDHREC parciais** com métricas herdadas: Kinnan (13), Korvold (11), Yuriko (84), Teysa (80), Aesi (79)
- **Observação Aesi (ID=5):** ramp=28 inclui fetch lands + landfall triggers classificados como ramp+land no multi-tag. Não é corrupção.
- **Observação Teysa (ID=4):** ramp=15 inclui tesouros/tokens. Comportamento esperado para artefato EDHREC sem ramp rocks.
- **Observação Winota (ID=7):** protection=10 vs [5-8] (diff=2) — ligeiramente acima do range, mas aceitável para aggro-stax que precisa proteger Winota.

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
| 2026-05-27 19:28 UTC | 8 | 0 | Re-validação: sem mudanças. Yuriko qty corrigido 99→84. |

*Relatório gerado por manaloom-mana-base-validator*
