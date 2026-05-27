# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-27T12:01Z**

## Resumo

| Métrica | Valor |
|:--|:--:|
| Total de crons vistos (`include_disabled=True`) | 16 |
| Habilitados | 16/16 |
| Desabilitados | 0 |
| `last_status=error` | 6 |
| Nunca executaram (`last_run_at=null`) | 2 |
| Triggers aceitos nesta rodada | 11 |
| Branch do workdir | `codex/hermes-analysis-docs` |
| HEAD da branch de análise | `06e992f9b401` |

**Estado geral:** 16/16 habilitados ✅. Nenhum cron precisou de `resume`. Foram emitidos triggers manuais para crons com `last_run_at` antigo (>120min) e para crons habilitados que nunca tinham rodado, conforme a rotina gerencial.

**Observação operacional:** `cronjob(action="run")` aceitou os disparos e ajustou `next_run_at` para o horário da rodada. O campo `last_run_at/last_status` só muda quando o scheduler efetivamente conclui a execução; por isso alguns jobs ainda exibem status antigo imediatamente após o trigger.

## Crons de Auditoria / Gerenciais

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--|
| `757eefb8738b` | manaloom-master-watchdog | `every 30m` | ✅ | 2026-05-27 11:20Z | 41min | 🟢 ok | 2026-05-27 12:27Z | sem ação |
| `660397bb97e1` | manaloom-hermes-normal-audit | `0 16,21 * * *` | ✅ | 2026-05-26 21:59Z | 841min | 🟢 ok | 2026-05-27 11:59Z | trigger manual enviado nesta rodada |
| `07346720b753` | manaloom-hermes-daily-deep-audit | `30 11 * * *` | ✅ | 2026-05-27 11:42Z | 18min | 🔴 error | 2026-05-28 11:30Z | erro anterior; não atende critério de run nesta rodada |
| `3542b818f8b3` | manaloom-hermes-weekly-memory-cleanup | `0 12 * * 0` | ✅ | — | — | 🟡 never-run | 2026-05-27 11:59Z | trigger de inicialização enviado |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | `30 12 * * 0` | ✅ | — | — | 🟡 never-run | 2026-05-27 11:59Z | trigger de inicialização enviado |
| `2d436c71bbf7` | manaloom-manager-watchdog | `every 30m` | ✅ | 2026-05-26 23:17Z | 763min | 🟢 ok | 2026-05-27 11:59Z | trigger manual enviado nesta rodada |

## Crons de Conhecimento Commander

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--|
| `75eed994c103` | manaloom-commander-knowledge-deep | `every 20m` | ✅ | 2026-05-26 22:35Z | 805min | 🔴 error | 2026-05-27 11:59Z | trigger manual enviado nesta rodada |
| `7915cc2377a0` | manaloom-gamechanger-research | `every 20m` | ✅ | 2026-05-26 22:47Z | 794min | 🟢 ok | 2026-05-27 11:59Z | trigger manual enviado nesta rodada |
| `5fe699ed7ff2` | manaloom-themes-research | `every 20m` | ✅ | 2026-05-26 23:01Z | 780min | 🟢 ok | 2026-05-27 11:59Z | trigger manual enviado nesta rodada |
| `4430f8384ce4` | manaloom-missing-gc-filler | `every 20m` | ✅ | 2026-05-26 23:10Z | 771min | 🟢 ok | 2026-05-27 11:59Z | trigger manual enviado nesta rodada |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | `every 360m` | ✅ | 2026-05-27 01:59Z | 602min | 🟢 ok | 2026-05-27 11:59Z | trigger manual enviado nesta rodada |
| `444aa9510c2c` | manaloom-mana-base-validator | `every 60m` | ✅ | 2026-05-26 22:08Z | 833min | 🟢 ok | 2026-05-27 11:59Z | trigger manual enviado nesta rodada |

## Lorehold Knowledge Pipeline

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--|
| `f20ac299992b` | lorehold-deck-scout | `every 30m` | ✅ | 2026-05-27 11:56Z | 4min | 🔴 error | 2026-05-27 12:26Z | erro anterior; não atende critério de run nesta rodada |
| `712579b15767` | lorehold-deck-validator | `every 60m` | ✅ | 2026-05-27 10:45Z | 76min | 🔴 error | 2026-05-27 12:57Z | erro anterior; não atende critério de run nesta rodada |
| `08468451a06a` | lorehold-mulligan-analyst | `every 120m` | ✅ | 2026-05-27 10:45Z | 76min | 🔴 error | 2026-05-27 12:45Z | erro anterior; não atende critério de run nesta rodada |
| `a50bef4c2a59` | lorehold-evolution-oracle | `every 360m` | ✅ | 2026-05-27 08:46Z | 195min | 🔴 error | 2026-05-27 11:59Z | trigger manual enviado nesta rodada |

## Ações da Rodada Atual (2026-05-27T12:01Z)

| # | ID | Cron | Ação | Motivo | Resultado |
|:-:|:--|:--|:--|:--|:--|
| 1 | `660397bb97e1` | manaloom-hermes-normal-audit | `run` | last_run_at 840min atrás (>120min) | ✅ trigger manual aceito; next_run_at ajustado para 2026-05-27T11:59:17Z |
| 2 | `3542b818f8b3` | manaloom-hermes-weekly-memory-cleanup | `run` | last_run_at=null | ✅ inicialização manual aceita; next_run_at ajustado para 2026-05-27T11:59:17Z |
| 3 | `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | `run` | last_run_at=null | ✅ inicialização manual aceita; next_run_at ajustado para 2026-05-27T11:59:17Z |
| 4 | `75eed994c103` | manaloom-commander-knowledge-deep | `run` | last_run_at 804min atrás (>120min) | ✅ trigger manual aceito; cron segue enabled=true |
| 5 | `7915cc2377a0` | manaloom-gamechanger-research | `run` | last_run_at 792min atrás (>120min) | ✅ trigger manual aceito |
| 6 | `5fe699ed7ff2` | manaloom-themes-research | `run` | last_run_at 778min atrás (>120min) | ✅ trigger manual aceito |
| 7 | `4430f8384ce4` | manaloom-missing-gc-filler | `run` | last_run_at 769min atrás (>120min) | ✅ trigger manual aceito |
| 8 | `2d436c71bbf7` | manaloom-manager-watchdog | `run` | last_run_at 762min atrás (>120min) | ✅ trigger manual aceito |
| 9 | `b340374bc4e7` | manaloom-tag-accuracy-reporter | `run` | last_run_at 600min atrás (>120min) | ✅ trigger manual aceito |
| 10 | `444aa9510c2c` | manaloom-mana-base-validator | `run` | last_run_at 831min atrás (>120min) | ✅ trigger manual aceito |
| 11 | `a50bef4c2a59` | lorehold-evolution-oracle | `run` | last_run_at 193min atrás (>120min) | ✅ trigger manual aceito; cron segue enabled=true com last_status=error anterior |

**Total:** 11 ações — 0 `resume`, 11 `run`.

## Alertas Pendentes

Crons habilitados com `last_status=error` no snapshot pós-recuperação:

- `manaloom-hermes-daily-deep-audit` `07346720b753` — último run 2026-05-27 11:42Z; next 2026-05-28 11:30Z (aguardando próximo ciclo; não estava >120min ou já rodou recentemente).
- `manaloom-commander-knowledge-deep` `75eed994c103` — último run 2026-05-26 22:35Z; next 2026-05-27 11:59Z (trigger enviado nesta rodada).
- `lorehold-deck-scout` `f20ac299992b` — último run 2026-05-27 11:56Z; next 2026-05-27 12:26Z (aguardando próximo ciclo; não estava >120min ou já rodou recentemente).
- `lorehold-deck-validator` `712579b15767` — último run 2026-05-27 10:45Z; next 2026-05-27 12:57Z (aguardando próximo ciclo; não estava >120min ou já rodou recentemente).
- `lorehold-mulligan-analyst` `08468451a06a` — último run 2026-05-27 10:45Z; next 2026-05-27 12:45Z (aguardando próximo ciclo; não estava >120min ou já rodou recentemente).
- `lorehold-evolution-oracle` `a50bef4c2a59` — último run 2026-05-27 08:46Z; next 2026-05-27 11:59Z (trigger enviado nesta rodada).

Crons com `next_run_at` <= horário do relatório (provavelmente aguardando tick do scheduler):
- `manaloom-hermes-normal-audit` `660397bb97e1` — next_run_at 2026-05-27 11:59Z.
- `manaloom-hermes-weekly-memory-cleanup` `3542b818f8b3` — next_run_at 2026-05-27 11:59Z.
- `manaloom-hermes-weekly-parallel-audit` `aeaeb666d377` — next_run_at 2026-05-27 11:59Z.
- `manaloom-commander-knowledge-deep` `75eed994c103` — next_run_at 2026-05-27 11:59Z.
- `manaloom-gamechanger-research` `7915cc2377a0` — next_run_at 2026-05-27 11:59Z.
- `manaloom-themes-research` `5fe699ed7ff2` — next_run_at 2026-05-27 11:59Z.
- `manaloom-missing-gc-filler` `4430f8384ce4` — next_run_at 2026-05-27 11:59Z.
- `manaloom-manager-watchdog` `2d436c71bbf7` — next_run_at 2026-05-27 11:59Z.
- `manaloom-tag-accuracy-reporter` `b340374bc4e7` — next_run_at 2026-05-27 11:59Z.
- `manaloom-mana-base-validator` `444aa9510c2c` — next_run_at 2026-05-27 11:59Z.
- `lorehold-evolution-oracle` `a50bef4c2a59` — next_run_at 2026-05-27 11:59Z.

## Notas

- Branch conferida: `codex/hermes-analysis-docs` ✅; nenhum checkout para `master` foi feito.
- `cronjob(action="list", include_disabled=True)` retornou 16 jobs; chamada sem `include_disabled` também retornou 16, indicando ausência de jobs ocultos/desabilitados neste snapshot.
- Working tree já continha artefatos não relacionados de crons de conhecimento/deck antes desta rodada; esta atualização deve commitar apenas `CRON_STATUS.md`.
- Nenhum token/secret foi registrado neste relatório.

---

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
