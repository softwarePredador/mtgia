# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-26T22:04Z**

## Resumo

| Tipo | Total | Ativos | Instância |
|:-----|:-----:|:------:|:----------|
| Conhecimento | 3 | 3 | a cada 20min |
| Auditoria | 5 | 5 | variável |
| Preenchimento GC | 1 | 1 | a cada 20min |
| Precisão Tags | 1 | 1 | a cada 6h |
| Mana Base | 1 | 1 | a cada 60min |
| Gerencial | 1 | 1 | a cada 30min |

**Estado geral:** 12/12 habilitados ✅ — 2 com last_status=error (recuperados via resume, aguardando scheduler).

## Crons de Conhecimento (20min)

| Cron | Última exec | Status | Observação |
|:-----|:-----------:|:------:|:----------|
| manaloom-commander-knowledge-deep | 21:00 | 🔴 error | Resumido nesta rodada — estava disabled+error |
| manaloom-gamechanger-research | 21:12 | 🟢 ok | Resumido — desabilitado por troca de branch |
| manaloom-themes-research | 21:32 | 🟢 ok | Resumido — desabilitado por troca de branch |

## Crons de Auditoria

| Cron | Schedule | Status | Observação |
|:-----|:--------:|:------|:----------|
| manaloom-master-watchdog | 30min | 🟢 OK | Script-based (no agent) |
| manaloom-hermes-normal-audit | 16h,21h | 🟢 trigger manual | 21:00 foi perdido; trigger enviado |
| manaloom-hermes-daily-deep-audit | 11:30 | 🟡 Pendente | Próximo: 2026-05-27 11:30 |
| manaloom-hermes-weekly-memory-cleanup | Dom 12h | 🟡 Pendente | Próximo: 2026-05-31 |
| manaloom-hermes-weekly-parallel-audit | Dom 12:30 | 🟡 Pendente | Próximo: 2026-05-31 |

## Novos Crons (criados 2026-05-26)

| Cron | Schedule | Função | Status |
|:-----|:--------:|:-------|:------|
| manaloom-missing-gc-filler | 20min | Preenche análise dos 32 GCs faltantes | 🟢 Resumido (estava error) |
| manaloom-manager-watchdog | 30min | Monitora e recupera crons | 🟢 Primeira execução |
| manaloom-tag-accuracy-reporter | 6h | Relatório de precisão das tags | 🟡 Aguardando 01:55 |
| manaloom-mana-base-validator | 60min | Valida base de mana vs EDHREC | 🟢 Trigger manual enviado |

## Ações da Rodada Atual (2026-05-26T21:40Z)

| # | Cron | Ação | Resultado |
|:-:|:-----|:----|:----------|
| 1 | manaloom-commander-knowledge-deep | resume (disabled+error) | ✅ Ativado |
| 2 | manaloom-gamechanger-research | resume (branch switch) | ✅ Ativado |
| 3 | manaloom-themes-research | resume (branch switch) | ✅ Ativado |
| 4 | manaloom-missing-gc-filler | resume (disabled+error) | ✅ Ativado |
| 5 | manaloom-hermes-normal-audit | trigger (janela 21:00 perdida) | ✅ Disparado |
| 6 | manaloom-mana-base-validator | trigger (nunca rodou, atrasado) | ✅ Completo — 3 críticos, 3 moderados |

**Total:** 6 ações de recuperação — 4 resumes, 2 triggers.

|## Notas
|
|- **commander-knowledge-deep** e **missing-gc-filler** terminaram com status=error. Após resume, seus `next_run_at` estavam como None — scheduler recalculou, crons re-agendados via trigger manual.
|- **master-watchdog** (script-based) está funcional mas tem delay no scheduler.
|- Nenhum cron com token/secret exposto. Branch: codex/hermes-analysis-docs ✅. knowledge.db writable (hermes:hermes).

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

*Atualizado pelo cron manaloom-tag-accuracy-reporter*

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