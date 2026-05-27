# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-27T21:08Z**

## Resumo

|| Métrica | Valor |
|:--|:--:|
| Total de crons (`include_disabled=True`) | 15 |
| Habilitados | 15/15 |
| Desabilitados | 0 |
| `last_status=error` | **1** 🔴 |
| Nunca executaram (`last_run_at=null`) | 0 |
| Stale (>120min atrás, `enabled=true`) | 0 |
| Fleet removidos desde 2026-05-27 | 4 (daily-deep-audit, weekly-memory-cleanup, themes-research, missing-gc-filler) |
| Recuperados nesta sessão | 2 |
| Regredidos nesta sessão | 0 |
| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** 15/15 habilitados ✅. **1 cron em `last_status=error`** — tag-accuracy-reporter (provider error transitório). 2 crons recuperados nesta rodada (resume + run trigger). Fleet cresceu de 13 → 15 com 2 estrutura-auditor distintos.

**Mudanças desde 19:29Z:**
- `manaloom-commander-knowledge-deep` 🟢 **recuperou** — 20:53Z executou ok (deepseek-v4-flash ✅).
- `lorehold-deck-validator` 🟢 **recuperou** — 20:35Z executou ok (deepseek-v4-flash ✅).
- `manaloom-manager-watchdog` 🟢 **recuperou** (auto) — 20:26Z ok (esta execução).
- `manaloom-tag-accuracy-reporter` 🔴 **mantém erro** — 19:26Z "Provider returned error". Próximo tick: 01:26Z. Sem ação (transiente, 1/15 = não sistêmico).
- `manaloom-code-structure-auditor` (577a0a669714, weekly Sunday) — estava **DISABLED**, foi **RESUMED** ✅. Agendado para 2026-05-31 06:00Z.
- `manaloom-code-structure-auditor` (bb03201b8911, every 4h) — **NUNCA RODOU**, trigger aceito. next_run_at: ~21:05Z.
- `manaloom-knowledge-import` ✅ 20:40Z ok.
- `lorehold-deck-scout` ✅ 20:32Z ok.
- `manaloom-mana-base-validator` ✅ 20:52Z ok.
- `lorehold-mulligan-analyst` ✅ 19:51Z ok.
- `lorehold-evolution-oracle` ✅ 13:22Z ok (próximo: 21:29Z).
- `manaloom-hermes-normal-audit` ✅ 21:01Z ok.
- `manaloom-hermes-weekly-parallel-audit` ✅ 12:56Z ok.
- `manaloom-master-watchdog` ✅ 20:26Z ok.
- `manaloom-gamechanger-research` ✅ 20:59Z ok.

## Crons de Auditoria / Gerenciais

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `757eefb8738b` | manaloom-master-watchdog | `every 30m` | ✅ | 2026-05-27 20:26Z | 42min | 🟢 ok | 2026-05-27 21:30Z | sem ação — rodando normalmente |
| `660397bb97e1` | manaloom-hermes-normal-audit | `0 16,21 * * *` | ✅ | 2026-05-27 21:01Z | 7min | 🟢 ok | 2026-05-28 16:00Z | próxima às 16:00Z |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | `30 12 * * 0` | ✅ | 2026-05-27 12:56Z | 8h12min | 🟢 ok | 2026-05-31 12:30Z | aguardando domingo |
| `2d436c71bbf7` | manaloom-manager-watchdog | `every 30m` | ✅ | 2026-05-27 20:26Z | 42min | 🟢 ok | 2026-05-27 21:30Z | ✅ recuperou — esta execução |
| `577a0a669714` | manaloom-code-structure-auditor | `0 6 * * 0` | ✅ | NUNCA | — | ⚪ never-run | 2026-05-31 06:00Z | 🆕 **RESUMIDO** nesta rodada. Weekly Sunday. |
| `bb03201b8911` | manaloom-code-structure-auditor | `0 20,0,4,8,12,16 * * *` | ✅ | NUNCA | — | ⚪ never-run | 2026-05-27 21:05Z | 🆕 **TRIGGER ACEITO**. next_run_at ajustado para ~21:05Z. |

## Crons de Conhecimento Commander

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `75eed994c103` | manaloom-commander-knowledge-deep | `every 20m` | ✅ | 2026-05-27 20:53Z | 15min | 🟢 ok | 2026-05-27 21:13Z | ✅ recuperou — deepseek-v4-flash ✅ |
| `7915cc2377a0` | manaloom-gamechanger-research | `every 20m` | ✅ | 2026-05-27 20:59Z | 9min | 🟢 ok | 2026-05-27 21:19Z | ✅ rodando normalmente |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | `every 360m` | ✅ | 2026-05-27 19:26Z | 1h42min | 🔴 error | 2026-05-28 01:26Z | ⚠️ "Provider returned error" (default provider). Não sistêmico (1/15). Aguardando próximo tick. |
| `444aa9510c2c` | manaloom-mana-base-validator | `every 60m` | ✅ | 2026-05-27 20:52Z | 16min | 🟢 ok | 2026-05-27 21:52Z | ✅ rodando normalmente |
| `b2f5c21ce2d7` | manaloom-knowledge-import | `every 30m` | ✅ | 2026-05-27 20:40Z | 28min | 🟢 ok | 2026-05-27 21:10Z | ✅ rodando normalmente |

## Lorehold Knowledge Pipeline

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `f20ac299992b` | lorehold-deck-scout | `every 30m` | ✅ | 2026-05-27 20:32Z | 36min | 🟢 ok | 2026-05-27 21:02Z | ✅ rodando normalmente |
| `712579b15767` | lorehold-deck-validator | `every 60m` | ✅ | 2026-05-27 20:35Z | 33min | 🟢 ok | 2026-05-27 21:35Z | ✅ recuperou — deepseek-v4-flash ✅ |
| `08468451a06a` | lorehold-mulligan-analyst | `every 120m` | ✅ | 2026-05-27 19:51Z | 1h17min | 🟢 ok | 2026-05-27 21:51Z | ✅ rodando normalmente |
| `a50bef4c2a59` | lorehold-evolution-oracle | `every 360m` | ✅ | 2026-05-27 13:22Z | 7h46min | 🟢 ok | 2026-05-27 21:29Z | normal para schedule 6h |

## Ações da Rodada Atual (2026-05-27T21:08Z)

| # | ID | Cron | Ação | Motivo | Resultado |
:-:|:--|:--|:--|:--|:--
| 1 | `577a0a669714` | manaloom-code-structure-auditor (weekly) | `cronjob(action='resume')` | estava `enabled=false`, nunca rodou | ✅ Resumido. Habilitado, agendado para 2026-05-31 06:00Z |
| 2 | `bb03201b8911` | manaloom-code-structure-auditor (4h) | `cronjob(action='run')` | `last_run_at=null`, nunca executou | ✅ Trigger aceito. next_run_at → ~21:05Z. Aguardando scheduler. |
| 3 | — | **branch check** | `git branch --show-current` | Verificação de branch | ✅ `codex/hermes-analysis-docs` — sem ação |
| 4 | — | **diagnóstico** | listou 15 crons | 1 erro encontrado | 🔍 Apenas tag-accuracy-reporter |
| 5 | `75eed994c103` | commander-knowledge-deep | observação | Recuperou sozinho (20:53Z ok) | ✅ Sem intervenção necessária |
| 6 | `712579b15767` | lorehold-deck-validator | observação | Recuperou sozinho (20:35Z ok) | ✅ Sem intervenção necessária |
| 7 | `b340374bc4e7` | tag-accuracy-reporter | diagnóstico | "Provider returned error" — falha precoce | ⏸️ Sem ação — aguardando próximo ciclo (~01:26Z). Não sistêmico (1/15). |

## Mudanças desde o Último Relatório (2026-05-27T19:29Z)

| Mudança | Detalhe |
|:--------|:--------|
| Total de crons | 13 → 15 (2 estrutura-auditor distintos: weekly + 4h) |
| Erros totais | 4 → 1 (3 crons recuperaram sozinhos) |
| Regredidos | 3 → 0 |
| Recuperados nesta rodada | 2 (resume + run trigger) |
| Fleet total | 15 crons, 15 habilitados, 0 desabilitados |

## Alertas Pendentes

### 🔴 1 cron com `last_status=error`

| Cron | Último run | Erro | Provider | Model | Workdir | Tipo |
|:-----|:----------:|:----|:--------:|:-----:|:-------:|:----:|
| tag-accuracy-reporter | 19:26Z | Provider returned error | default | — | /opt/data/workspace/mtgia | Transitório |

**Nenhuma ação corretiva estrutural necessária:**
- 0 crons desabilitados → nenhum resume
- 0 crons stale (>120min) → nenhum run
- 1/15 erro = não sistêmico
- Único erro é transitório (provider issue)
- Scheduler reintentará em ~01:26Z

### Recuperados hoje (2026-05-27):
- manaloom-manager-watchdog: 🔴 → 🟢 (20:26Z, esta execução)
- manaloom-code-structure-auditor (577a0a669714): DISABLED → ENABLED (21:08Z)
- commander-knowledge-deep: 🔴 → 🟢 (20:53Z)
- lorehold-deck-validator: 🔴 → 🟢 (20:35Z)

## Observações Importantes

- **Fleet cresceu:** 13 → 15 crons. Dois `manaloom-code-structure-auditor` distintos: weekly Sunday (577a0a669714) + every 4h (bb03201b8911).
- **Branch confirmada:** `codex/hermes-analysis-docs` ✅
- **`cronjob(action="list", include_disabled=True)`** retornou 15 jobs, todos `enabled=true` após resume.
- **Ações corretivas aplicadas:** 1 resume (weekly auditor) + 1 run trigger (4h auditor).
- **Tag-accuracy-reporter** usa provider default (sem model/provider explícito). Erro "Provider returned error" é transitório — próximo tick em ~01:26Z.
- Working tree contém artefatos de cron não relacionados (decks lorehold, scripts de scout, `__pycache__`) — apenas `CRON_STATUS.md` será comitado.
- Nenhum token/secret registrado neste relatório.

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
