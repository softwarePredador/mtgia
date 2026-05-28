# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-28T00:22Z**

## Resumo

| Métrica | Valor |
|:--|:--:|
| Total de crons (`include_disabled=True`) | 15 |
| Habilitados | 15/15 |
| Desabilitados | 0 |
| `last_status=error` | **5** 🔴 |
| Nunca executaram (`last_run_at=null`) | 0 |
| Stale (>120min atrás, `enabled=true`) | 0 |
| Fleet removidos desde 2026-05-27 | 4 (daily-deep-audit, weekly-memory-cleanup, themes-research, missing-gc-filler) |
| Recuperados nesta sessão | 5 |
| Regredidos nesta sessão | 1 novo (`lorehold-mulligan-analyst`) |
| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** 15/15 habilitados ✅. **5 crons em `last_status=error`** na fotografia desta execução. Houve **5 recuperações observáveis** desde a rodada anterior (`manaloom-hermes-weekly-parallel-audit`, `manaloom-tag-accuracy-reporter`, `manaloom-mana-base-validator`, `manaloom-code-structure-auditor` semanal e `manaloom-code-structure-auditor` 4h), enquanto **1 cron regrediu** (`lorehold-mulligan-analyst`) após executar às 00:07Z e falhar com HTTP 402. O padrão de falha remanescente é agora totalmente concentrado em crons OpenRouter/free-model: 5 jobs com `HTTP 402: Insufficient Balance`. Nenhum `resume` ou novo `run` foi necessário nesta execução.

**Mudanças desta rodada:**
- `manaloom-hermes-weekly-parallel-audit` — recuperado: executou às 23:59Z e voltou para `ok`.
- `manaloom-tag-accuracy-reporter` — recuperado: executou às 00:00Z e voltou para `ok`.
- `manaloom-mana-base-validator` — recuperado: executou às 00:07Z e voltou para `ok`.
- `manaloom-code-structure-auditor` (577a0a669714) — recuperado: executou às 00:03Z e publicou o relatório de estrutura com `last_status=ok`.
- `manaloom-code-structure-auditor` (bb03201b8911) — recuperado: executou às 00:06Z e publicou a rotação de foco com `last_status=ok`.
- `lorehold-mulligan-analyst` — regrediu: executou às 00:07Z e falhou por HTTP 402 / `Insufficient Balance`.
- Demais crons permaneceram habilitados; nenhum `enabled=false`, nenhum `never-run` e nenhum job stale >120min no momento da inspeção.

## Crons de Auditoria / Gerenciais

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `757eefb8738b` | manaloom-master-watchdog | `every 30m` | ✅ | 2026-05-28 00:08Z | 13min | 🟢 ok | 2026-05-28 00:38Z | ✅ execução no-agent mais recente silenciosa e saudável |
| `660397bb97e1` | manaloom-hermes-normal-audit | `0 16,21 * * *` | ✅ | 2026-05-27 23:40Z | 41min | 🟢 ok | 2026-05-28 16:00Z | ✅ continua saudável após o [SILENT] do audit normal |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | `30 12 * * 0` | ✅ | 2026-05-27 23:59Z | 22min | 🟢 ok | 2026-05-31 12:30Z | ✅ recuperado — execução mais recente terminou em [SILENT] |
| `2d436c71bbf7` | manaloom-manager-watchdog | `every 30m` | ✅ | 2026-05-27 23:50Z | 31min | 🟢 ok | 2026-05-28 00:51Z | ✅ última execução concluiu `ok`; esta rodada apenas consolidou novo snapshot |
| `577a0a669714` | manaloom-code-structure-auditor | `0 6 * * 0` | ✅ | 2026-05-28 00:03Z | 18min | 🟢 ok | 2026-05-31 06:00Z | ✅ recuperado — publicou atualização do audit estrutural (`ae0cb93c`) |
| `bb03201b8911` | manaloom-code-structure-auditor | `0 20,0,4,8,12,16 * * *` | ✅ | 2026-05-28 00:06Z | 16min | 🟢 ok | 2026-05-28 04:00Z | ✅ recuperado — publicou rotação "Classes Não Usadas" (`60b52cb9`) |

## Crons de Conhecimento Commander

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `75eed994c103` | manaloom-commander-knowledge-deep | `every 20m` | ✅ | 2026-05-28 00:19Z | 2min | 🔴 error | 2026-05-28 00:39Z | 🔴 erro recente; OpenRouter free-model devolveu HTTP 429 / free-models-per-day |
| `7915cc2377a0` | manaloom-gamechanger-research | `every 20m` | ✅ | 2026-05-28 00:19Z | 2min | 🔴 error | 2026-05-28 00:39Z | 🔴 erro recente; OpenRouter free-model devolveu HTTP 429 / free-models-per-day |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | `every 360m` | ✅ | 2026-05-28 00:00Z | 22min | 🟢 ok | 2026-05-28 06:00Z | ✅ recuperado — publicou atualização de precisão (`36fbe0a6`) |
| `444aa9510c2c` | manaloom-mana-base-validator | `every 60m` | ✅ | 2026-05-28 00:07Z | 14min | 🟢 ok | 2026-05-28 01:07Z | ✅ recuperado — short-circuit funcionou e cron voltou para `ok` |
| `b2f5c21ce2d7` | manaloom-knowledge-import | `every 30m` | ✅ | 2026-05-28 00:20Z | 1min | 🟢 ok | 2026-05-28 00:50Z | ✅ saudável; continua bloqueado apenas por ausência de `psql`, sem drift de configuração |

## Lorehold Knowledge Pipeline

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--|:--|
| `f20ac299992b` | lorehold-deck-scout | `every 30m` | ✅ | 2026-05-28 00:07Z | 14min | 🔴 error | 2026-05-28 00:37Z | 🔴 erro recente; OpenRouter/deck-analysis falhou por HTTP 402 / `Insufficient Balance` |
| `712579b15767` | lorehold-deck-validator | `every 60m` | ✅ | 2026-05-28 00:08Z | 13min | 🔴 error | 2026-05-28 01:08Z | 🔴 erro recente; OpenRouter/deck-analysis falhou por HTTP 402 / `Insufficient Balance` |
| `08468451a06a` | lorehold-mulligan-analyst | `every 120m` | ✅ | 2026-05-28 00:07Z | 14min | 🔴 error | 2026-05-28 02:07Z | 🔴 regrediu nesta rodada; execução mais recente falhou por HTTP 402 / `Insufficient Balance` |
| `a50bef4c2a59` | lorehold-evolution-oracle | `every 360m` | ✅ | 2026-05-27 21:41Z | 2h40min | 🟢 ok | 2026-05-28 03:41Z | ✅ sem ação — intervalo de 6h ainda dentro do esperado para este schedule |

## Ações da Rodada Atual (2026-05-28T00:22Z)

| # | ID | Cron | Ação | Motivo | Resultado |
|:-:|:--|:--|:--|:--|:--|
| 1 | — | **cronjob(action='list', include_disabled=True)** | inspeção completa | verificar frota atual | ✅ 15 jobs listados; nenhum `enabled=false` |
| 2 | — | **branch check** | `git branch --show-current` | verificar branch do workdir | ✅ `codex/hermes-analysis-docs` — sem ação |
| 3 | — | **git status --short** | sanity check | confirmar worktree limpo antes do patch | ✅ limpo nesta execução |
| 4 | `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | validação pós-run | confirmar recuperação | ✅ `last_run_at` avançou para 23:59Z e `last_status=ok` |
| 5 | `b340374bc4e7` | manaloom-tag-accuracy-reporter | validação pós-run | confirmar recuperação | ✅ `last_run_at` avançou para 00:00Z e `last_status=ok` |
| 6 | `444aa9510c2c` | manaloom-mana-base-validator | validação pós-run | confirmar recuperação | ✅ `last_run_at` avançou para 00:07Z e `last_status=ok` |
| 7 | `577a0a669714` + `bb03201b8911` | manaloom-code-structure-auditor | validação pós-run | confirmar que ambos saíram de erro/stale | ✅ ambos executaram à meia-noite e ficaram `ok` |
| 8 | `75eed994c103`, `7915cc2377a0`, `f20ac299992b`, `712579b15767`, `08468451a06a` | diagnóstico de outputs | validar causa dos erros remanescentes | 🔍 2× HTTP 429 free-models-per-day + 3× HTTP 402 / `Insufficient Balance` |
| 9 | — | **ações corretivas novas** | nenhuma | não havia jobs desabilitados/stale/never-run | ℹ️ nenhuma chamada `resume`/`run` adicional necessária nesta execução |

## Alertas Pendentes

### 🔴 Crons com `last_status=error`

| Cron | Último run | Erro | Provider | Model | Workdir | Tipo |
|:-----|:----------:|:----|:--------:|:-----:|:-------:|:----:|
| manaloom-commander-knowledge-deep | 00:19Z | HTTP 429: free-models-per-day | openrouter | nvidia/nemotron-3-super-120b-a12b:free | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge | Rate limit / créditos |
| manaloom-gamechanger-research | 00:19Z | HTTP 429: free-models-per-day | openrouter | nvidia/nemotron-3-super-120b-a12b:free | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge | Rate limit / créditos |
| lorehold-deck-scout | 00:07Z | HTTP 402: Insufficient Balance | openrouter | nvidia/nemotron-3-super-120b-a12b:free | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge | Saldo/provider |
| lorehold-deck-validator | 00:08Z | HTTP 402: Insufficient Balance | openrouter | nvidia/nemotron-3-super-120b-a12b:free | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge | Saldo/provider |
| lorehold-mulligan-analyst | 00:07Z | HTTP 402: Insufficient Balance | openrouter | nvidia/nemotron-3-super-120b-a12b:free | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge | Saldo/provider |

### ✅ Recuperados nesta janela

| Cron | Último run | Evidência | Provider | Model | Workdir | Tipo |
|:-----|:----------:|:---------|:--------:|:-----:|:-------:|:----:|
| manaloom-hermes-weekly-parallel-audit | 23:59Z | última execução terminou `[SILENT]` e voltou para `ok` | copilot | gpt-5.4 | /opt/data/workspace/mtgia | Recuperado |
| manaloom-tag-accuracy-reporter | 00:00Z | publicou `feat: tag accuracy report` (`36fbe0a6`) | copilot | gpt-5.4 | /opt/data/workspace/mtgia | Recuperado |
| manaloom-mana-base-validator | 00:07Z | última execução terminou `[SILENT]` e voltou para `ok` | copilot | gpt-5.4 | /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge | Recuperado |
| manaloom-code-structure-auditor (weekly) | 00:03Z | publicou `docs: atualização do audit de estrutura — 2026-05-28` (`ae0cb93c`) | copilot | gpt-5.4 | /opt/data/workspace/mtgia | Recuperado |
| manaloom-code-structure-auditor (4h) | 00:06Z | publicou `docs: audit estrutura classes não usadas — 2026-05-28` (`60b52cb9`) | default | default | /opt/data/workspace/mtgia | Recuperado |

**Leitura operacional:**
- O estado atual melhorou para **5/15 crons em erro**.
- Todos os erros remanescentes estão concentrados no cluster **OpenRouter `nvidia/nemotron-3-super-120b-a12b:free`**.
- O subgrupo `manaloom-commander-knowledge-deep` + `manaloom-gamechanger-research` agora falha por **HTTP 429 free-models-per-day**, enquanto o pipeline Lorehold (`scout`, `validator`, `mulligan`) falha por **HTTP 402 / Insufficient Balance**.
- Os crons Copilot que estavam em erro na rodada passada efetivamente se recuperaram após a janela/scheduler e não exigem ação corretiva adicional agora.
- Como os jobs em erro continuam `enabled=true`, com `workdir` correto e `last_run_at` muito recente, **não** apliquei `resume`, `run` nem mudanças de configuração cegas; o bloqueio atual é externo ao repositório (quota/crédito do provider).
## Observações Importantes

- **Branch confirmada:** `codex/hermes-analysis-docs` ✅
- **`cronjob(action="list", include_disabled=True)`** retornou 15 jobs; nenhum desabilitado.
- **Ações corretivas aplicadas nesta execução:** 0 triggers novos; 0 resumes. Esta rodada foi de reamostragem/diagnóstico após as execuções da meia-noite.
- **Sem correções estruturais locais seguras para aplicar** nos erros atuais HTTP 402/429 do OpenRouter free-model; são falhas externas de crédito/quota/provider.
- Working tree estava limpo no início desta execução; apenas `docs/hermes-analysis/manaloom-knowledge/CRON_STATUS.md` foi alterado intencionalmente.
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
