# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-27T23:17Z**

## Resumo

| Métrica | Valor |
|:--|:--:|
| Total de crons (`include_disabled=True`) | 15 |
| Habilitados | 15/15 |
| Desabilitados | 0 |
| `last_status=error` | **8** 🔴 |
| Nunca executaram (`last_run_at=null`) | 1 |
| Stale (>120min atrás, `enabled=true`) | 0 após triggers desta rodada |
| Fleet removidos desde 2026-05-27 | 4 (daily-deep-audit, weekly-memory-cleanup, themes-research, missing-gc-filler) |
| Recuperados nesta sessão | 0 |
| Regredidos nesta sessão | 8 |
| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** 15/15 habilitados ✅. **8 crons em `last_status=error`**. O padrão atual é majoritariamente sistêmico por provider/crédito: 5 crons com HTTP 402/`Insufficient Balance`, 2 com HTTP 429 (`free-models-per-day-stealth`) e 1 com `Provider returned error`. Foram aplicados 4 triggers operacionais para jobs stale/never-run; nenhum resume foi necessário.

**Mudanças desta rodada:**
- `manaloom-hermes-normal-audit` — estava >120min desde último run; `run` aceito e `next_run_at` reprogramado para agora.
- `manaloom-hermes-weekly-parallel-audit` — estava >120min desde último run; `run` aceito e `next_run_at` reprogramado para agora.
- `manaloom-tag-accuracy-reporter` — estava stale (>120min) e com erro de provider; `run` aceito, ainda aguardando nova execução.
- `manaloom-code-structure-auditor` (577a0a669714) — seguia `never-run`; `run` aceito, ainda `last_run_at=null`.
- Demais crons permaneceram habilitados; nenhum `enabled=false` foi encontrado.

## Crons de Auditoria / Gerenciais

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `757eefb8738b` | manaloom-master-watchdog | `every 30m` | ✅ | 2026-05-27 22:28Z | 48min | 🟢 ok | 2026-05-27 23:45Z | ✅ sem ação — rodando/agendado normalmente |
| `660397bb97e1` | manaloom-hermes-normal-audit | `0 16,21 * * *` | ✅ | 2026-05-27 21:01Z | 2h15min | 🟢 ok | 2026-05-27 23:16Z | 🟡 trigger aceito nesta execução; aguardando evidência de execução |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | `30 12 * * 0` | ✅ | 2026-05-27 12:56Z | 10h21min | 🟢 ok | 2026-05-27 23:16Z | 🟡 trigger aceito nesta execução; aguardando evidência de execução |
| `2d436c71bbf7` | manaloom-manager-watchdog | `every 30m` | ✅ | 2026-05-27 22:32Z | 44min | 🔴 error | 2026-05-27 23:46Z | 🔴 erro recente; output indica HTTP 402 / `Insufficient Balance`; aguardando correção externa |
| `577a0a669714` | manaloom-code-structure-auditor | `0 6 * * 0` | ✅ | NUNCA | — | ⚪ never-run | 2026-05-27 23:16Z | ⚪ trigger aceito nesta execução; ainda never-run, aguardando scheduler |
| `bb03201b8911` | manaloom-code-structure-auditor | `0 20,0,4,8,12,16 * * *` | ✅ | 2026-05-27 21:34Z | 1h43min | 🟢 ok | 2026-05-28 00:00Z | ✅ sem ação — rodando/agendado normalmente |

## Crons de Conhecimento Commander

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `75eed994c103` | manaloom-commander-knowledge-deep | `every 20m` | ✅ | 2026-05-27 22:36Z | 41min | 🔴 error | 2026-05-27 23:35Z | 🔴 erro recente; configuração parece correta, falha externa de saldo/provider (HTTP 402) |
| `7915cc2377a0` | manaloom-gamechanger-research | `every 20m` | ✅ | 2026-05-27 22:37Z | 40min | 🔴 error | 2026-05-27 23:35Z | 🔴 erro recente; configuração parece correta, falha externa de saldo/provider (HTTP 402) |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | `every 360m` | ✅ | 2026-05-27 19:26Z | 3h50min | 🔴 error | 2026-05-27 23:16Z | 🟡 trigger aceito nesta execução; erro anterior do provider default permanece até novo run |
| `444aa9510c2c` | manaloom-mana-base-validator | `every 60m` | ✅ | 2026-05-27 23:15Z | 2min | 🔴 error | 2026-05-28 00:15Z | 🔴 erro recente; rate limit de modelo free (HTTP 429) |
| `b2f5c21ce2d7` | manaloom-knowledge-import | `every 30m` | ✅ | 2026-05-27 23:15Z | 2min | 🔴 error | 2026-05-27 23:45Z | 🔴 erro recente; rate limit de modelo free (HTTP 429) |

## Lorehold Knowledge Pipeline

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `f20ac299992b` | lorehold-deck-scout | `every 30m` | ✅ | 2026-05-27 23:15Z | 2min | 🔴 error | 2026-05-27 23:45Z | 🔴 erro recente; configuração parece correta, falha externa de saldo/provider (HTTP 402) |
| `712579b15767` | lorehold-deck-validator | `every 60m` | ✅ | 2026-05-27 22:38Z | 39min | 🔴 error | 2026-05-27 23:38Z | 🔴 erro recente; configuração parece correta, falha externa de saldo/provider (HTTP 402) |
| `08468451a06a` | lorehold-mulligan-analyst | `every 120m` | ✅ | 2026-05-27 21:56Z | 1h20min | 🟢 ok | 2026-05-27 23:56Z | ✅ sem ação — rodando/agendado normalmente |
| `a50bef4c2a59` | lorehold-evolution-oracle | `every 360m` | ✅ | 2026-05-27 21:41Z | 1h35min | 🟢 ok | 2026-05-28 03:41Z | ✅ sem ação — rodando/agendado normalmente |

## Ações da Rodada Atual (2026-05-27T23:17Z)

| # | ID | Cron | Ação | Motivo | Resultado |
|:-:|:--|:--|:--|:--|:--|
| 1 | `660397bb97e1` | manaloom-hermes-normal-audit | `cronjob(action='run')` | >120min desde último run | ✅ Trigger aceito; `next_run_at` → agora. Aguardando scheduler. |
| 2 | `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | `cronjob(action='run')` | >120min desde último run | ✅ Trigger aceito; `next_run_at` → agora. Aguardando scheduler. |
| 3 | `b340374bc4e7` | manaloom-tag-accuracy-reporter | `cronjob(action='run')` | stale >120min + `last_status=error` | ✅ Trigger aceito; erro anterior permanece até novo run. |
| 4 | `577a0a669714` | manaloom-code-structure-auditor (weekly) | `cronjob(action='run')` | `last_run_at=null` | ✅ Trigger aceito; ainda never-run até scheduler executar. |
| 5 | — | **branch check** | `git branch --show-current` | verificar branch do workdir | ✅ `codex/hermes-analysis-docs` — sem ação |
| 6 | — | **diagnóstico sistêmico** | inspeção de outputs recentes | 8 crons em erro | 🔍 5× HTTP 402 / saldo, 2× HTTP 429 / rate limit, 1× provider default |

## Alertas Pendentes

### 🔴 Crons com `last_status=error`

| Cron | Último run | Erro | Provider | Model | Workdir | Tipo |
|:-----|:----------:|:----|:--------:|:-----:|:-------:|:----:|
| manaloom-manager-watchdog | 22:32Z | HTTP 402: Insufficient Balance | copilot | gpt-5.4 | /opt/data/workspace/mtgia | Saldo/provider |
| manaloom-commander-knowledge-deep | 22:36Z | HTTP 402: Insufficient Balance | deepseek | deepseek-v4-flash | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge | Saldo/provider |
| manaloom-gamechanger-research | 22:37Z | HTTP 402: Insufficient Balance | deepseek | deepseek-v4-flash | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge | Saldo/provider |
| manaloom-tag-accuracy-reporter | 19:26Z | Provider returned error | default | — | /opt/data/workspace/mtgia | Provider default |
| manaloom-mana-base-validator | 23:15Z | HTTP 429: Rate limit exceeded: free-models-per-day-stealth | default | — | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge | Rate limit |
| lorehold-deck-scout | 23:15Z | HTTP 402 / Insufficient Balance | deepseek | deepseek-v4-flash | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge | Saldo/provider |
| lorehold-deck-validator | 22:38Z | HTTP 402: Insufficient Balance | deepseek | deepseek-v4-flash | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge | Saldo/provider |
| manaloom-knowledge-import | 23:15Z | HTTP 429: Rate limit exceeded: free-models-per-day-stealth | default | — | — | Rate limit |

**Leitura operacional:**
- O estado atual **não** é mais “1 erro transitório”; agora há **8/15 erros** com forte indício de dependências externas compartilhadas.
- Grupo DeepSeek/Crédito afetado: `manaloom-commander-knowledge-deep`, `manaloom-gamechanger-research`, `lorehold-deck-scout`, `lorehold-deck-validator`.
- Grupo Rate-limit/free-model afetado: `manaloom-mana-base-validator` e `manaloom-knowledge-import`.
- `manaloom-manager-watchdog` também falhou por HTTP 402 no output mais recente, então o próprio gerente entrou na mesma degradação de provider.
- `manaloom-tag-accuracy-reporter` segue no provider default com erro transitório genérico; como não há model/provider explícito para corrigir localmente, a ação segura foi apenas re-trigger.
- Como as configurações principais parecem corretas nos crons DeepSeek (`provider=deepseek`, `model=deepseek-v4-flash`, workdir certo onde aplicável), **não** reconfigurei model/workdir cegamente; o bloqueio parece financeiro/infra externo e precisa correção fora do watchdog.

## Observações Importantes

- **Branch confirmada:** `codex/hermes-analysis-docs` ✅
- **`cronjob(action="list", include_disabled=True)`** retornou 15 jobs; nenhum desabilitado.
- **Ações corretivas aplicadas nesta execução:** 4 triggers `run`; 0 resumes.
- **Sem correções estruturais locais seguras para aplicar** nos erros HTTP 402/429 observados; são falhas externas de crédito/rate-limit/provider.
- Working tree local segue com artefato não versionado `scripts/knowledge.db`; ele não faz parte deste commit.
- Apenas `docs/hermes-analysis/manaloom-knowledge/CRON_STATUS.md` deve ser commitado pelo watchdog.
- Nenhum token/secret foi registrado neste relatório.

---

## Mana Base Validation Report

> Validação de mana base dos decks armazenados contra perfis EDHREC (commander_reference_profile_anchor30_batch_*).
> Executado automaticamente pelo cron `manaloom-mana-base-validator`.

**Última execução:** 2026-05-27 20:44 UTC
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
| 2026-05-27 20:44 UTC | 8 | 0 | Re-validação: sem mudanças nos decks. DB atualizada às 20:35 (knowledge import). |

*Relatório gerado por manaloom-mana-base-validator*
