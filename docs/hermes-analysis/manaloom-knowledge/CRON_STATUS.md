# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-26T23:12Z**

## Resumo

| Tipo | Total | Ativos | Instância |
|:-----|:-----:|:------:|:----------|
| Conhecimento | 3 | 3 | a cada 20min |
| Auditoria | 5 | 5 | variável |
| Preenchimento GC | 1 | 1 | a cada 20min |
| Precisão Tags | 1 | 1 | a cada 6h |
| Mana Base | 1 | 1 | a cada 60min |
| Gerencial | 1 | 1 | a cada 30min |

**Estado geral:** 12/12 habilitados ✅ — 1 com last_status=error (commander-knowledge-deep, recuperado via resume, aguardando próximo ciclo).

## Crons de Conhecimento (20min)

| Cron | Última exec | Status | Observação |
|:-----|:-----------:|:------:|:----------|
| manaloom-commander-knowledge-deep | 22:35 | 🔴 error | Resumido — estava disabled+error por troca de branch |
| manaloom-gamechanger-research | 22:47 | 🟢 ok | Resumido — desabilitado por troca de branch |
| manaloom-themes-research | 23:01 | 🟢 ok | Resumido — desabilitado por troca de branch |

## Crons de Auditoria

| Cron | Schedule | Status | Observação |
|:-----|:--------:|:------|:----------|
| manaloom-master-watchdog | 30min | 🟢 OK | Script-based — trigger manual enviado (3h20min sem exec) |
| manaloom-hermes-normal-audit | 16h,21h | 🟢 OK | Última exec 21:59Z; próximo 16h amanhã |
| manaloom-hermes-daily-deep-audit | 11:30 | 🟡 Pendente | Próximo: 2026-05-27 11:30 |
| manaloom-hermes-weekly-memory-cleanup | Dom 12h | 🟡 Pendente | Próximo: 2026-05-31 |
| manaloom-hermes-weekly-parallel-audit | Dom 12:30 | 🟡 Pendente | Próximo: 2026-05-31 |

## Novos Crons (criados 2026-05-26)

| Cron | Schedule | Função | Status |
|:-----|:--------:|:-------|:------|
| manaloom-missing-gc-filler | 20min | Preenche análise dos 32 GCs faltantes | 🟢 Resumido — último ciclo 23:10Z |
| manaloom-manager-watchdog | 30min | Monitora e recupera crons | 🟢 2ª execução |
| manaloom-tag-accuracy-reporter | 6h | Relatório de precisão das tags | 🟢 OK — 01:55Z — 82.9% geral |
| manaloom-mana-base-validator | 60min | Valida base de mana vs EDHREC | 🟢 Último ciclo 22:08Z |

## Ações da Rodada Atual (2026-05-26T23:12Z)

| # | Cron | Ação | Resultado |
|:-:|:-----|:----|:----------|
| 1 | manaloom-commander-knowledge-deep | resume (disabled+error) | ✅ Reativado — aguardando próximo ciclo |
| 2 | manaloom-gamechanger-research | resume (branch switch) | ✅ Reativado |
| 3 | manaloom-themes-research | resume (branch switch) | ✅ Reativado |
| 4 | manaloom-missing-gc-filler | resume (branch switch) | ✅ Reativado |
| 5 | manaloom-master-watchdog | trigger (3h20min sem execução) | ✅ Disparado — next 23:12Z |

**Total:** 5 ações de recuperação — 4 resumes, 1 trigger.

|## Notas
|
|- **commander-knowledge-deep** manteve last_status=error mas já foi reativado — o próximo ciclo deve resetar o status.
|- **master-watchdog** ficou 3h20min sem executar (19:49→23:12Z). Trigger manual enviado. Possível causa: scheduler perdeu o ciclo durante janela de troca de branch das 20:00.
|- **gamechanger-research**, **themes-research** e **missing-gc-filler** rodaram com sucesso mesmo desabilitados — troca de branch os desabilitou mas os ciclos individuais terminaram OK.
|- Nenhum cron com token/secret exposto. Branch: codex/hermes-analysis-docs ✅.

## Análise de Causa Raiz (2026-05-26 22:25)

### manaloom-commander-knowledge-deep — erro 21:00

**Causa primária: Troca de branch.** O workdir do cron estava em uma branch
que não `codex/hermes-analysis-docs`. Ao executar, todos os arquivos
necessários (INDEX.md, knowledge.db, scripts/, analises markdown) estavam
ausentes ou em caminhos diferentes. O cron não conseguiu encontrar o que
precisava e falhou.

**Causas secundárias (script):** Mesmo na branch correta, `explore_artifacts.py`
tem problemas estruturais:
1. `SyntaxError: unterminated string literal` — escaping Python via terminal
2. `'list' object has no attribute 'get'` — corpus.json pode ser list OU dict
3. `KeyError` em slicing de dados não-list (EDHTop16 expansion files com `NO_CARDS`)
4. Commit final ficou como "pending" — a análise nunca foi finalizada

### manaloom-missing-gc-filler — erro 20:36

**Causa primária: Troca de branch** (mesmo padrão). Como era a PRIMEIRA
execução do cron (nunca rodou antes), ele foi criado e agendado, mas quando
o scheduler tentou executar, o workdir estava em outra branch.

**Causa secundária: Inicialização incompleta.** O cron foi criado na
sessão das 20:00 mas nunca completou uma execução. O skills `manaloom-commander-knowledge`
e `manaloom-mtg-domain` precisam carregar, consultar SQLite, achar o próximo
GC a preencher — qualquer erro de arquivo ou permissão interrompe o fluxo.

### Estado Atual da Correção

| Fator | Status | Evidência |
|:------|:------:|:----------|
| Branch correta | ✅ | codex/hermes-analysis-docs |
| knowledge.db acessível | ✅ | hermes:hermes 644, 237KB |
| Scripts no diretório | ✅ | 20+ scripts presentes |
| Cron re-agendados | ✅ | next_run_at ~22:22 (trigger manual) |
| knowledge.db root-owned | ✅ NÃO | Não é necessário workaround de mv+cp |
| Manager watchdog ativo | ✅ | Próxima exec ~22:23 |

## Scorecard de Otimização

| Tentativa | Alvo | Resultado |
|:----------|:-----|:----------|
| 1 | produção --limit 10 | Timeout 120s |
| 2 | produção --limit 5 | Timeout 207s |
| 3 | localhost:8084 --limit 5 | Rodando... |

## Precisão das Functional Tags (último relatório)

*Atualizado pelo cron manaloom-tag-accuracy-reporter — 2026-05-27T01:55Z*

**Geral:** 155/187 acertos = **82.9%** (187 amostras, 6 decks)

| Tag | Acertos | Total | Precisão | Status |
|:----|:-------:|:-----:|:--------:|:------|
| ramp | 32 | 32 | 100.0% | ✅ |
| draw | 15 | 15 | 100.0% | ✅ |
| tutor | 6 | 6 | 100.0% | ✅ |
| removal | 16 | 16 | 100.0% | ✅ |
| enabler | 12 | 12 | 100.0% | ✅ |
| land | 37 | 37 | 100.0% | ✅ |
| board_wipe | 3 | 3 | 100.0% | ✅ |
| sacrifice_outlet | 1 | 1 | 100.0% | ✅ |
| finisher | 2 | 2 | 100.0% | ✅ |
| recursion | 3 | 3 | 100.0% | ✅ |
| payoff | 11 | 12 | 91.7% | 🟢 |
| engine | 6 | 7 | 85.7% | 🟢 |
| wincon | 6 | 8 | 75.0% | 🟡 |
| other | 1 | 2 | 50.0% | 🟡 |
| combo_piece | 1 | 2 | 50.0% | 🟡 |
| protection | 3 | 7 | 42.9% | 🟠 |
| ninja | 0 | 17 | 0.0% | 🔴 |
| ramp + combo_piece | 0 | 1 | 0.0% | 🔴 |
| recursion + wincon | 0 | 1 | 0.0% | 🔴 |
| ramp + payoff | 0 | 1 | 0.0% | 🔴 |
| payoff + removal | 0 | 1 | 0.0% | 🔴 |
| payoff + token_maker | 0 | 1 | 0.0% | 🔴 |

### Status dos decks no DB
- **6 decks** | **6 comandantes** | **18 discrepâncias** | **187 cartas classificadas**

### Problemas Identificados

1. **🔴 ninja = 0/17 (0%)** — 17 cartas no deck Yuriko com tag esperada "ninja" que o ManaLoom não detecta. A tag `ninja` não existe no classificador atual. Impacto: toda análise de decks ninja perde informação relevante.
2. **🟠 protection = 3/7 (42.9%)** — ManaLoom sub-detecta proteção de comandante e counterspells. 4 cartas classificadas como `other` quando deveriam ser `protection`.
3. **🟡 wincon = 6/8 (75.0%)** — 2 wincons não detectadas. Possível: wincons que dependem de combo não-Thoracle não são capturadas.
4. **🟡 combo_piece = 1/2 (50.0%)** — Faltam heuristicas para peças de combo não-óbvias.
5. **🟡 other = 1/2 (50.0%)** — 1 carta caiu em "other" que tinha tag esperada conhecida.
6. **🔴 Multi-tags (5 casos, 0%)** — Todas as multi-tags registradas são 0% de acerto porque o sistema legacy de `tag_accuracy` só compara contra `functional_tag` (single-tag). Cartas com tags múltiplas (Smothering Tithe = ramp + engine + token_maker) são contadas como erro porque a tag primária não corresponde à tag composta. **Corrigir**: separar medição de multi-tag em coluna própria ou usar `card_tags` para comparação.

### Comparação com Auditoria Anterior (2026-05-26)
- Precisão geral: 82.9% (vs ~61% na auditoria de tags funcionais de 2026-05-26)
- Melhoria: +22pp atribuída à inclusão de tags de alta confiança (ramp, draw, removal)
- Piora aparente: "ninja" e multi-tags puxam a média para baixo

## Mana Base Validation (2026-05-26 22:04)

**Fonte:** EDHREC Profiles (commander_reference_profile) + DB `knowledge.db`

| Deck | Commander | Lands | CMC | Ramp | Bracket | Data Quality | Alertas |
|:-----|:----------|:-----:|:---:|:----:|:-------:|:-------------|:--------|
| Kinnan, Bonder Prodigy | Kinnan | 29 | 1.8 | 24 | 4 | BAIXA (13/100) | ❌ INSERT incompleto; INFO: cEDH ok |
| Dimir Ninja Topdeck Tempo | Yuriko | 33 | 2.8 | 6 | 3 | PARCIAL (99/100) | ✅ Nenhum |
| EDHREC Average Default | Korvold | 25 | 3.2 | 14 | 3 | BAIXA (11/91) | ❌ CRÍTICO: lands=25 < 30 + dados corrompidos |
| EDHREC Average Default | Teysa | 35 | 2.9 | 8 | 3 | PARCIAL (80/99) | ⚠️ Ramp=8 < EDHREC min 9 |

### Alertas Críticos (P0)
1. **Korvold:** Apenas 11/91 cartas no DB — dados de mana base inválidos. Inserção corrompida.
2. **Kinnan:** Apenas 13/100 cartas no DB — INSERT incompleto.

### Ações Recomendadas
- **P0:** Re-inserir Korvold e Kinnan com INSERT completo
- **P2:** Verificar ramp=8 da Teysa (pode ser real, diferença pequena)
- **P2:** Investigar tagging de ninjas no deck Yuriko (0 tagged como 'ninja')