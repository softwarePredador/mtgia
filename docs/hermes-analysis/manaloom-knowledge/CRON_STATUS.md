# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-27T23:49Z**

## Resumo

| Métrica | Valor |
|:--|:--:|
| Total de crons (`include_disabled=True`) | 15 |
| Habilitados | 15/15 |
| Desabilitados | 0 |
| `last_status=error` | **7** 🔴 |
| Nunca executaram (`last_run_at=null`) | 0 |
| Stale (>120min atrás, `enabled=true`) | 0 |
| Fleet removidos desde 2026-05-27 | 4 (daily-deep-audit, weekly-memory-cleanup, themes-research, missing-gc-filler) |
| Recuperados nesta sessão | 3 |
| Regredidos nesta sessão | 0 novos após a rodada anterior |
| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** 15/15 habilitados ✅. **7 crons em `last_status=error`** após os triggers da rodada anterior serem parcialmente consumidos pelo scheduler. Houve **3 recuperações observáveis** (`manaloom-master-watchdog`, `manaloom-hermes-normal-audit`, `manaloom-knowledge-import`) e o auditor estrutural semanal saiu de `never-run` para erro real de rate limit, permitindo diagnóstico concreto. O padrão remanescente segue sistêmico por provider/crédito: 4 crons com HTTP 402/`Insufficient Balance` e 3 com HTTP 429 (`free-models-per-day-stealth`). Nenhum `resume` ou novo `run` foi necessário nesta execução.

**Mudanças desta rodada:**
- `manaloom-master-watchdog` — recuperado: `last_run_at` avançou para 23:45Z e `last_status=ok`.
- `manaloom-hermes-normal-audit` — recuperado após trigger anterior: executou às 23:40Z e voltou para `ok`.
- `manaloom-knowledge-import` — recuperado: executou às 23:47Z e voltou para `ok`.
- `manaloom-code-structure-auditor` (577a0a669714) — deixou de ser `never-run`; executou às 23:20Z e falhou por HTTP 429, o que confirma rate limit em vez de problema de agendamento.
- `manaloom-hermes-weekly-parallel-audit` — trigger anterior foi consumido, mas a execução de 23:19Z falhou por HTTP 429; permanece em erro aguardando janela/provider.
- Demais crons permaneceram habilitados; nenhum `enabled=false` foi encontrado e nenhum job estava stale >120min no momento da inspeção.

## Crons de Auditoria / Gerenciais

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `757eefb8738b` | manaloom-master-watchdog | `every 30m` | ✅ | 2026-05-27 23:45Z | 4min | 🟢 ok | 2026-05-28 00:15Z | ✅ recuperado naturalmente após atraso anterior; rodando/agendado normalmente |
| `660397bb97e1` | manaloom-hermes-normal-audit | `0 16,21 * * *` | ✅ | 2026-05-27 23:40Z | 9min | 🟢 ok | 2026-05-28 16:00Z | ✅ trigger anterior validado — cron executou e voltou para `ok` |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | `30 12 * * 0` | ✅ | 2026-05-27 23:19Z | 30min | 🔴 error | 2026-05-31 12:30Z | 🔴 trigger anterior consumido; output mais recente indica HTTP 429 / free-model rate limit |
| `2d436c71bbf7` | manaloom-manager-watchdog | `every 30m` | ✅ | 2026-05-27 23:18Z | 31min | 🟢 ok | 2026-05-28 00:18Z | ✅ esta execução anterior concluiu `ok`; seguir monitorando próxima janela |
| `577a0a669714` | manaloom-code-structure-auditor | `0 6 * * 0` | ✅ | 2026-05-27 23:20Z | 29min | 🔴 error | 2026-05-31 06:00Z | 🔴 saiu de `never-run`; execução confirmou rate limit HTTP 429 |
| `bb03201b8911` | manaloom-code-structure-auditor | `0 20,0,4,8,12,16 * * *` | ✅ | 2026-05-27 21:34Z | 2h15min | 🟢 ok | 2026-05-28 00:00Z | ✅ sem ação — próximo tick iminente, status ainda saudável |

## Crons de Conhecimento Commander

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `75eed994c103` | manaloom-commander-knowledge-deep | `every 20m` | ✅ | 2026-05-27 23:40Z | 9min | 🔴 error | 2026-05-28 00:00Z | 🔴 erro recente; configuração parece correta, falha externa de saldo/provider (HTTP 402) |
| `7915cc2377a0` | manaloom-gamechanger-research | `every 20m` | ✅ | 2026-05-27 23:40Z | 9min | 🔴 error | 2026-05-28 00:00Z | 🔴 erro recente; configuração parece correta, falha externa de saldo/provider (HTTP 402) |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | `every 360m` | ✅ | 2026-05-27 23:19Z | 30min | 🔴 error | 2026-05-28 05:19Z | 🔴 execução pós-trigger falhou por HTTP 429 / free-model rate limit |
| `444aa9510c2c` | manaloom-mana-base-validator | `every 60m` | ✅ | 2026-05-27 23:15Z | 34min | 🔴 error | 2026-05-28 00:15Z | 🔴 erro recente; rate limit de modelo free (HTTP 429) |
| `b2f5c21ce2d7` | manaloom-knowledge-import | `every 30m` | ✅ | 2026-05-27 23:47Z | 2min | 🟢 ok | 2026-05-28 00:17Z | ✅ recuperado — execução mais recente concluiu `ok` |

## Lorehold Knowledge Pipeline

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `f20ac299992b` | lorehold-deck-scout | `every 30m` | ✅ | 2026-05-27 23:15Z | 2min | 🔴 error | 2026-05-27 23:45Z | 🔴 erro recente; configuração parece correta, falha externa de saldo/provider (HTTP 402) |
| `712579b15767` | lorehold-deck-validator | `every 60m` | ✅ | 2026-05-27 22:38Z | 39min | 🔴 error | 2026-05-27 23:38Z | 🔴 erro recente; configuração parece correta, falha externa de saldo/provider (HTTP 402) |
| `08468451a06a` | lorehold-mulligan-analyst | `every 120m` | ✅ | 2026-05-27 21:56Z | 1h20min | 🟢 ok | 2026-05-27 23:56Z | ✅ sem ação — rodando/agendado normalmente |
| `a50bef4c2a59` | lorehold-evolution-oracle | `every 360m` | ✅ | 2026-05-27 21:41Z | 1h35min | 🟢 ok | 2026-05-28 03:41Z | ✅ sem ação — rodando/agendado normalmente |

## Ações da Rodada Atual (2026-05-27T23:49Z)

| # | ID | Cron | Ação | Motivo | Resultado |
|:-:|:--|:--|:--|:--|:--|
| 1 | — | **cronjob(action='list', include_disabled=True)** | inspeção completa | verificar frota atual | ✅ 15 jobs listados; nenhum `enabled=false` |
| 2 | — | **branch check** | `git branch --show-current` | verificar branch do workdir | ✅ `codex/hermes-analysis-docs` — sem ação |
| 3 | `660397bb97e1` | manaloom-hermes-normal-audit | validação pós-trigger anterior | confirmar execução | ✅ `last_run_at` avançou para 23:40Z e `last_status=ok` |
| 4 | `577a0a669714` | manaloom-code-structure-auditor (weekly) | validação pós-trigger anterior | confirmar saída de `never-run` | ✅ executou às 23:20Z; falha agora diagnosticada como HTTP 429 |
| 5 | `b2f5c21ce2d7` | manaloom-knowledge-import | validação de recuperação | checar se erro anterior persistia | ✅ executou às 23:47Z e voltou para `ok` |
| 6 | — | **diagnóstico sistêmico** | inspeção de outputs recentes | 7 crons em erro | 🔍 4× HTTP 402 / saldo insuficiente + 3× HTTP 429 / rate limit |
| 7 | — | **ações corretivas novas** | nenhuma | não havia jobs desabilitados/stale/never-run | ℹ️ nenhuma chamada `resume`/`run` adicional necessária nesta execução |

## Alertas Pendentes

### 🔴 Crons com `last_status=error`

| Cron | Último run | Erro | Provider | Model | Workdir | Tipo |
|:-----|:----------:|:----|:--------:|:-----:|:-------:|:----:|
| manaloom-commander-knowledge-deep | 23:40Z | HTTP 402: Insufficient Balance | deepseek | deepseek-v4-flash | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge | Saldo/provider |
| manaloom-gamechanger-research | 23:40Z | HTTP 402: Insufficient Balance | deepseek | deepseek-v4-flash | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge | Saldo/provider |
| manaloom-tag-accuracy-reporter | 23:19Z | HTTP 429: Rate limit exceeded: free-models-per-day-stealth | copilot | gpt-5.4 | /opt/data/workspace/mtgia | Rate limit |
| manaloom-mana-base-validator | 23:15Z | HTTP 429: Rate limit exceeded: free-models-per-day-stealth | copilot | gpt-5.4 | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge | Rate limit |
| lorehold-deck-scout | 23:45Z | HTTP 402 / Insufficient Balance | deepseek | deepseek-v4-flash | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge | Saldo/provider |
| lorehold-deck-validator | 23:41Z | HTTP 402: Insufficient Balance | deepseek | deepseek-v4-flash | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge | Saldo/provider |
| manaloom-hermes-weekly-parallel-audit | 23:19Z | HTTP 429: Rate limit exceeded: free-models-per-day-stealth | copilot | gpt-5.4 | /opt/data/workspace/mtgia | Rate limit |
| manaloom-code-structure-auditor (weekly) | 23:20Z | HTTP 429: Rate limit exceeded: free-models-per-day-stealth | copilot | gpt-5.4 | /opt/data/workspace/mtgia | Rate limit |

### ✅ Recuperados nesta janela

| Cron | Último run | Evidência | Provider | Model | Workdir | Tipo |
|:-----|:----------:|:---------|:--------:|:-----:|:-------:|:----:|
| manaloom-manager-watchdog | 23:18Z | última execução concluiu `ok` | copilot | gpt-5.4 | /opt/data/workspace/mtgia | Recuperado |
| manaloom-knowledge-import | 23:47Z | última execução concluiu `ok` | copilot | gpt-5.4 | — | Recuperado |

**Leitura operacional:**
- O estado atual caiu para **7/15 crons em erro** após o scheduler consumir parte dos triggers anteriores e confirmar algumas recuperações.
- Grupo DeepSeek/Crédito afetado: `manaloom-commander-knowledge-deep`, `manaloom-gamechanger-research`, `lorehold-deck-scout`, `lorehold-deck-validator`.
- Grupo Copilot/free-model rate limit afetado: `manaloom-hermes-weekly-parallel-audit`, `manaloom-tag-accuracy-reporter`, `manaloom-mana-base-validator`, `manaloom-code-structure-auditor` semanal.
- `manaloom-manager-watchdog` e `manaloom-knowledge-import` mostraram recuperação observável nesta janela; não precisam ação imediata.
- O trigger anterior do auditor estrutural semanal foi útil: agora sabemos que o problema é **rate limit HTTP 429**, não agendamento/never-run.
- Como as configurações principais parecem corretas nos crons DeepSeek (`provider=deepseek`, `model=deepseek-v4-flash`, workdir certo onde aplicável), **não** reconfigurei model/workdir cegamente; o bloqueio segue parecendo financeiro/infra externo e precisa correção fora do watchdog.

## Observações Importantes

- **Branch confirmada:** `codex/hermes-analysis-docs` ✅
- **`cronjob(action="list", include_disabled=True)`** retornou 15 jobs; nenhum desabilitado.
- **Ações corretivas aplicadas nesta execução:** 0 triggers novos; 0 resumes. Esta rodada foi de validação pós-trigger e consolidação do diagnóstico.
- **Sem correções estruturais locais seguras para aplicar** nos erros HTTP 402/429 observados; são falhas externas de crédito/rate-limit/provider.
- Working tree local segue com artefatos não relacionados (`scripts/knowledge.db`, mudanças em `docs/hermes-analysis/manaloom-knowledge/scripts/import_card_profiles.py` e `import_knowledge.py`); eles não fazem parte deste commit.
- Apenas `docs/hermes-analysis/manaloom-knowledge/CRON_STATUS.md` deve ser commitado pelo watchdog.
- Nenhum token/secret foi registrado neste relatório.

---

## Relatório de Precisão das Functional Tags

> Snapshot acumulado da tabela SQLite `tag_accuracy`.
> Consulta executada em `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`.

**Última consulta:** 2026-05-27 23:49 UTC  
**Precisão total acumulada:** **378/454 = 83.3%**

### Tags com pior precisão (prioridade de correção)

| Tag | Acertos | Total | Precisão | Leitura |
|:----|--------:|------:|---------:|:--------|
| `ninja` | 0 | 17 | 0.0% | Colapso total — o classificador não está reconhecendo o eixo principal de Yuriko. |
| `stax_disruption` | 0 | 3 | 0.0% | Hate/stax ainda invisível para a taxonomia atual. |
| `ramp + combo_piece` | 0 | 1 | 0.0% | Multi-função de mana + combo não está sobrevivendo à validação. |
| `recursion + wincon` | 0 | 1 | 0.0% | Papel híbrido não está sendo preservado. |
| `ramp + payoff` | 0 | 1 | 0.0% | Tag composta sem acerto acumulado. |
| `payoff + removal` | 0 | 1 | 0.0% | Tag composta sem acerto acumulado. |
| `payoff + token_maker` | 0 | 1 | 0.0% | Tag composta sem acerto acumulado. |
| `payoff` | 11 | 31 | 35.5% | Grande fonte de ambiguidade semântica; hoje a categoria é ampla demais. |
| `combo_piece` | 1 | 2 | 50.0% | Base pequena, mas instável. |
| `enabler` | 21 | 42 | 50.0% | Categoria excessivamente genérica; metade das classificações acumuladas falha. |

### Tags medianas

| Tag | Acertos | Total | Precisão |
|:----|--------:|------:|---------:|
| `other` | 1 | 2 | 50.0% |
| `protection` | 9 | 13 | 69.2% |
| `wincon` | 6 | 8 | 75.0% |
| `engine` | 6 | 8 | 75.0% |

### Tags estáveis (100%)

`ramp` (53/53), `draw` (32/32), `tutor` (6/6), `removal` (30/30), `land` (87/87), `board_wipe` (3/3), `sacrifice_outlet` (1/1), `finisher` (2/2), `recursion` (3/3), `wipe` (1/1), `utility` (76/76), `creature` (22/22), `planeswalker` (2/2), `artifact` (2/2), `enchantment` (3/3).

### Leitura operacional

- O classificador está **forte nas funções tradicionais** (ramp, draw, removal, land), mas ainda **fraco em papéis contextuais e híbridos**.
- O maior problema estrutural continua sendo **taxonomia contextual**: `ninja`, `stax_disruption`, `payoff` e `enabler` dependem mais do plano de jogo do deck do que do texto isolado da carta.
- As **tags compostas** com 0% ainda têm amostra pequena; não provam bug sozinhas, mas sinalizam que o sistema ainda não representa bem cartas multi-papel.
- Como a precisão global já está em **83.3%**, o ganho marginal mais importante agora não vem de mexer em `ramp/draw/removal`, e sim de corrigir os **falsos negativos de archetype/contexto**.

### Próximas prioridades sugeridas

1. Auditar a família `ninja` com foco em Yuriko e evasão/connectors.
2. Refinar `payoff` vs `engine` vs `enabler`, hoje excessivamente sobrepostos.
3. Criar heurísticas explícitas para `stax_disruption` e outros efeitos proativos não-destrutivos.
4. Decidir se tags compostas devem continuar como classes finais ou virar metadados auxiliares.

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
