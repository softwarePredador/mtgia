# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-27T12:58Z**

## Resumo

| Métrica | Valor |
|:--|:--:|
| Total de crons vistos (`include_disabled=True`) | 16 |
| Habilitados | 16/16 |
| Desabilitados | 0 |
| `last_status=error` | 6 |
| Nunca executaram (`last_run_at=null`) | 0 |
| Triggers aceitos nesta rodada | 8 |
| Resumes nesta rodada | 0 |
| Branch do workdir | `codex/hermes-analysis-docs` |
| HEAD da branch de análise | `9190520f06b6` |

**Estado geral:** 16/16 habilitados ✅. Nenhum cron precisou de `resume`. Foram enviados 8 `cronjob(action="run")` para jobs habilitados com `last_run_at` acima de 120min, conforme a rotina gerencial.

**Observação operacional:** `cronjob(action="run")` é trigger de scheduler, não prova de execução concluída. Nesta rodada os triggers foram aceitos e `next_run_at` foi reprogramado; `last_run_at/last_status` só mudam quando o scheduler realmente inicia e conclui cada job.

## Crons de Auditoria / Gerenciais

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--|
| `757eefb8738b` | manaloom-master-watchdog | `every 30m` | ✅ | 2026-05-27 12:10Z | 47min | 🟢 ok | 2026-05-27 12:40Z | next_run_at já venceu; aguardando tick do scheduler |
| `660397bb97e1` | manaloom-hermes-normal-audit | `0 16,21 * * *` | ✅ | 2026-05-27 12:19Z | 39min | 🟢 ok | 2026-05-27 16:00Z | sem ação |
| `07346720b753` | manaloom-hermes-daily-deep-audit | `30 11 * * *` | ✅ | 2026-05-27 11:42Z | 76min | 🔴 error | 2026-05-28 11:30Z | erro anterior; aguardando próximo ciclo/diagnóstico específico |
| `3542b818f8b3` | manaloom-hermes-weekly-memory-cleanup | `0 12 * * 0` | ✅ | 2026-05-27 12:31Z | 27min | 🔴 error | 2026-05-31 12:00Z | erro anterior; aguardando próximo ciclo/diagnóstico específico |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | `30 12 * * 0` | ✅ | 2026-05-27 12:56Z | 2min | 🟢 ok | 2026-05-31 12:30Z | sem ação |
| `2d436c71bbf7` | manaloom-manager-watchdog | `every 30m` | ✅ | 2026-05-27 12:03Z | 55min | 🟢 ok | 2026-05-27 12:41Z | next_run_at já venceu; aguardando tick do scheduler |

## Crons de Conhecimento Commander

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--|
| `75eed994c103` | manaloom-commander-knowledge-deep | `every 20m` | ✅ | 2026-05-26 22:35Z | 863min | 🔴 error | 2026-05-27 12:57Z | trigger aceito nesta rodada; aguardando scheduler atualizar last_run_at/last_status |
| `7915cc2377a0` | manaloom-gamechanger-research | `every 20m` | ✅ | 2026-05-26 22:47Z | 851min | 🟢 ok | 2026-05-27 12:57Z | trigger aceito nesta rodada; aguardando scheduler atualizar last_run_at/last_status |
| `5fe699ed7ff2` | manaloom-themes-research | `every 20m` | ✅ | 2026-05-26 23:01Z | 837min | 🟢 ok | 2026-05-27 12:57Z | trigger aceito nesta rodada; aguardando scheduler atualizar last_run_at/last_status |
| `4430f8384ce4` | manaloom-missing-gc-filler | `every 20m` | ✅ | 2026-05-26 23:10Z | 828min | 🟢 ok | 2026-05-27 12:57Z | trigger aceito nesta rodada; aguardando scheduler atualizar last_run_at/last_status |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | `every 360m` | ✅ | 2026-05-27 01:59Z | 659min | 🟢 ok | 2026-05-27 12:57Z | trigger aceito nesta rodada; aguardando scheduler atualizar last_run_at/last_status |
| `444aa9510c2c` | manaloom-mana-base-validator | `every 60m` | ✅ | 2026-05-26 22:08Z | 890min | 🟢 ok | 2026-05-27 12:57Z | trigger aceito nesta rodada; aguardando scheduler atualizar last_run_at/last_status |

## Lorehold Knowledge Pipeline

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--|
| `f20ac299992b` | lorehold-deck-scout | `every 30m` | ✅ | 2026-05-27 11:56Z | 62min | 🔴 error | 2026-05-27 12:26Z | erro anterior; aguardando próximo ciclo/diagnóstico específico |
| `712579b15767` | lorehold-deck-validator | `every 60m` | ✅ | 2026-05-27 12:10Z | 48min | 🟢 ok | 2026-05-27 13:10Z | sem ação |
| `08468451a06a` | lorehold-mulligan-analyst | `every 120m` | ✅ | 2026-05-27 10:45Z | 133min | 🔴 error | 2026-05-27 12:57Z | trigger aceito nesta rodada; aguardando scheduler atualizar last_run_at/last_status |
| `a50bef4c2a59` | lorehold-evolution-oracle | `every 360m` | ✅ | 2026-05-27 08:46Z | 252min | 🔴 error | 2026-05-27 12:57Z | trigger aceito nesta rodada; aguardando scheduler atualizar last_run_at/last_status |

## Ações da Rodada Atual (2026-05-27T12:58Z)

| # | ID | Cron | Ação | Motivo | Resultado |
|:-:|:--|:--|:--|:--|:--|
| 1 | `75eed994c103` | manaloom-commander-knowledge-deep | `run` | last_run_at 862min atrás (>120min) | ✅ trigger aceito; next_run_at ajustado para 2026-05-27T12:57:44Z; last_status=error anterior ainda pendente |
| 2 | `7915cc2377a0` | manaloom-gamechanger-research | `run` | last_run_at 851min atrás (>120min) | ✅ trigger aceito; next_run_at ajustado para 2026-05-27T12:57:44Z |
| 3 | `5fe699ed7ff2` | manaloom-themes-research | `run` | last_run_at 836min atrás (>120min) | ✅ trigger aceito; next_run_at ajustado para 2026-05-27T12:57:44Z |
| 4 | `4430f8384ce4` | manaloom-missing-gc-filler | `run` | last_run_at 828min atrás (>120min) | ✅ trigger aceito; next_run_at ajustado para 2026-05-27T12:57:44Z |
| 5 | `b340374bc4e7` | manaloom-tag-accuracy-reporter | `run` | last_run_at 659min atrás (>120min) | ✅ trigger aceito; next_run_at ajustado para 2026-05-27T12:57:44Z |
| 6 | `444aa9510c2c` | manaloom-mana-base-validator | `run` | last_run_at 889min atrás (>120min) | ✅ trigger aceito; next_run_at ajustado para 2026-05-27T12:57:44Z |
| 7 | `08468451a06a` | lorehold-mulligan-analyst | `run` | last_run_at 132min atrás (>120min) | ✅ trigger aceito; next_run_at ajustado para 2026-05-27T12:57:44Z; last_status=error anterior ainda pendente |
| 8 | `a50bef4c2a59` | lorehold-evolution-oracle | `run` | last_run_at 252min atrás (>120min) | ✅ trigger aceito; next_run_at ajustado para 2026-05-27T12:57:44Z; last_status=error anterior ainda pendente |

**Total:** 8 ações — 0 `resume`, 8 `run`.

## Alertas Pendentes

Crons habilitados com `last_status=error` no snapshot pós-recuperação:

- `manaloom-hermes-daily-deep-audit` `07346720b753` — último run 2026-05-27 11:42Z; next 2026-05-28 11:30Z; status antigo permanece até nova execução concluída.
- `manaloom-hermes-weekly-memory-cleanup` `3542b818f8b3` — último run 2026-05-27 12:31Z; next 2026-05-31 12:00Z; status antigo permanece até nova execução concluída.
- `manaloom-commander-knowledge-deep` `75eed994c103` — último run 2026-05-26 22:35Z; next 2026-05-27 12:57Z; trigger enviado nesta rodada; status antigo permanece até nova execução concluída.
- `lorehold-deck-scout` `f20ac299992b` — último run 2026-05-27 11:56Z; next 2026-05-27 12:26Z; status antigo permanece até nova execução concluída.
- `lorehold-mulligan-analyst` `08468451a06a` — último run 2026-05-27 10:45Z; next 2026-05-27 12:57Z; trigger enviado nesta rodada; status antigo permanece até nova execução concluída.
- `lorehold-evolution-oracle` `a50bef4c2a59` — último run 2026-05-27 08:46Z; next 2026-05-27 12:57Z; trigger enviado nesta rodada; status antigo permanece até nova execução concluída.

Crons com `next_run_at` <= horário do relatório (provavelmente aguardando tick do scheduler):
- `manaloom-master-watchdog` `757eefb8738b` — next_run_at 2026-05-27 12:40Z.
- `manaloom-commander-knowledge-deep` `75eed994c103` — next_run_at 2026-05-27 12:57Z.
- `manaloom-gamechanger-research` `7915cc2377a0` — next_run_at 2026-05-27 12:57Z.
- `manaloom-themes-research` `5fe699ed7ff2` — next_run_at 2026-05-27 12:57Z.
- `manaloom-missing-gc-filler` `4430f8384ce4` — next_run_at 2026-05-27 12:57Z.
- `manaloom-manager-watchdog` `2d436c71bbf7` — next_run_at 2026-05-27 12:41Z.
- `manaloom-tag-accuracy-reporter` `b340374bc4e7` — next_run_at 2026-05-27 12:57Z.
- `manaloom-mana-base-validator` `444aa9510c2c` — next_run_at 2026-05-27 12:57Z.
- `lorehold-deck-scout` `f20ac299992b` — next_run_at 2026-05-27 12:26Z.
- `lorehold-mulligan-analyst` `08468451a06a` — next_run_at 2026-05-27 12:57Z.
- `lorehold-evolution-oracle` `a50bef4c2a59` — next_run_at 2026-05-27 12:57Z.

## Notas

- Branch conferida: `codex/hermes-analysis-docs` ✅; nenhum checkout para `master` foi feito.
- `cronjob(action="list", include_disabled=True)` retornou 16 jobs; chamada sem `include_disabled` retornou 16.
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

*Atualizado pelo cron manaloom-tag-accuracy-reporter — 2026-05-27T13:01Z*

**Geral:** 155/187 acertos = **82.9%** (187 amostras, 6 decks)

| Tag | Acertos | Total | Precisão | Status |
|:----|:-------:|:-----:|:--------:|:------|
| ninja | 0 | 17 | 0.0% | 🔴 |
| payoff + removal | 0 | 1 | 0.0% | 🔴 |
| payoff + token_maker | 0 | 1 | 0.0% | 🔴 |
| ramp + combo_piece | 0 | 1 | 0.0% | 🔴 |
| ramp + payoff | 0 | 1 | 0.0% | 🔴 |
| recursion + wincon | 0 | 1 | 0.0% | 🔴 |
| protection | 3 | 7 | 42.9% | 🟠 |
| combo_piece | 1 | 2 | 50.0% | 🟡 |
| other | 1 | 2 | 50.0% | 🟡 |
| wincon | 6 | 8 | 75.0% | 🟡 |
| engine | 6 | 7 | 85.7% | 🟢 |
| payoff | 11 | 12 | 91.7% | 🟢 |
| board_wipe | 3 | 3 | 100.0% | ✅ |
| draw | 15 | 15 | 100.0% | ✅ |
| enabler | 12 | 12 | 100.0% | ✅ |
| finisher | 2 | 2 | 100.0% | ✅ |
| land | 37 | 37 | 100.0% | ✅ |
| ramp | 32 | 32 | 100.0% | ✅ |
| recursion | 3 | 3 | 100.0% | ✅ |
| removal | 16 | 16 | 100.0% | ✅ |
| sacrifice_outlet | 1 | 1 | 100.0% | ✅ |
| tutor | 6 | 6 | 100.0% | ✅ |

### Status dos decks no DB
- **6 decks** | **6 comandantes** | **18 discrepâncias** | **187 cartas classificadas**

### Problemas Identificados

1. **🔴 ninja = 0/17 (0%)** — 17 cartas no deck Yuriko com tag esperada "ninja" que o ManaLoom não detecta. A tag `ninja` não existe no classificador atual. Impacto: toda análise de decks ninja perde informação relevante.
2. **🟠 protection = 3/7 (42.9%)** — ManaLoom sub-detecta proteção de comandante e counterspells. 4 cartas classificadas como `other` quando deveriam ser `protection`.
3. **🟡 wincon = 6/8 (75.0%)** — 2 wincons não detectadas. Possível: wincons que dependem de combo não-Thoracle não são capturadas.
4. **🟡 combo_piece = 1/2 (50.0%)** — Faltam heurísticas para peças de combo não óbvias.
5. **🟡 other = 1/2 (50.0%)** — 1 carta caiu em "other" que tinha tag esperada conhecida.
6. **🔴 Multi-tags (5 casos, 0%)** — Todas as multi-tags registradas são 0% de acerto porque o sistema legacy de `tag_accuracy` só compara contra `functional_tag` (single-tag). Cartas com tags múltiplas (Smothering Tithe = ramp + engine + token_maker) são contadas como erro porque a tag primária não corresponde à tag composta. **Corrigir**: separar medição de multi-tag em coluna própria ou usar `card_tags` para comparação.

### Comparação com Auditoria Anterior (2026-05-26)
- Precisão geral: 82.9% (vs ~61% na auditoria de tags funcionais de 2026-05-26)
- Melhoria: +22pp atribuída à inclusão de tags de alta confiança (ramp, draw, removal)
- Piora aparente: "ninja" e multi-tags puxam a média para baixo

## Mana Base Validation (2026-05-27T13:11Z)

**Fonte:** SQLite `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db` + perfis/corpus EDHREC locais quando disponíveis.

**Regras aplicadas nesta rodada:** `lands < 32` => ALERTA; `CMC > 3.5` => ALERTA; `lands < 30 AND CMC > 3.0` => CRÍTICO. Perfis EDHREC locais foram usados como contexto adicional para evitar falsos positivos/negativos.

| Deck | Commander | Fonte | Lands | CMC | Ramp | Bracket | Data Quality | Alertas |
|:-----|:----------|:------|:-----:|:---:|:----:|:-------:|:-------------|:--------|
| Lorehold Spellslinger | Lorehold, the Historian | User provided decklist (Scryfall classified) | 34 | 3.98 | 17 | 3 | COMPLETA (qty=100; declared=100) | 🟡 ALERTA: CMC=3.98 > 3.5<br>ℹ️ Lorehold corpus avg lands=32.00 (3 decks EDHREC) |
| Aesi EDHREC Average Default | Aesi, Tyrant of Gyre Strait | EDHREC | 40 | 2.61 | 28 | 3 | COMPLETA (qty=100; declared=79) | ✅ lands dentro do profile (39-43) |
| EDHREC Average Default | Teysa Karlov | EDHREC | 35 | 2.9 | 15 | 3 | PARCIAL/EDHREC (qty=80; declared=80) | ✅ lands dentro do profile (35-37)<br>🟡 ramp=15 > profile ramp max=11 |
| EDHREC Average Default | Korvold, Fae-Cursed King | EDHREC | 25 | 3.2 | 3 | 3 | BAIXA (qty=11; declared=11) | 🔴 CRÍTICO: lands=25 < 30 e CMC=3.20 > 3.0<br>🟡 EDHREC profile lands min=34<br>🟡 ramp=3 < profile ramp_treasure min=10 |
| EDHREC Average Deck - Dimir Ninja Topdeck Tempo | Yuriko, the Tiger's Shadow | EDHREC | 33 | 2.8 | 8 | 3 | COMPLETA (qty=99; declared=84) | ✅ lands dentro do profile (30-34) |
| Kinnan, Bonder Prodigy | Kinnan, Bonder Prodigy | EDHTop16 | 29 | 1.8 | 4 | 4 | BAIXA (qty=13; declared=13) | 🟡 ALERTA: lands=29 < 32<br>✅ lands dentro do profile (29-34)<br>🟡 ramp=4 < profile nonland_mana_sources min=18 |

### Resumo da rodada
- Decks avaliados: **6**
- P0 críticos: **1**
- Alertas P1: **3**
- Sem alerta de mana base: **2**

### Alertas Críticos (P0)
- **EDHREC Average Default / Korvold, Fae-Cursed King:** 🔴 CRÍTICO: lands=25 < 30 e CMC=3.20 > 3.0

### Alertas Moderados / Observações
- **Lorehold Spellslinger / Lorehold, the Historian:** 🟡 ALERTA: CMC=3.98 > 3.5; ℹ️ Lorehold corpus avg lands=32.00 (3 decks EDHREC)
- **EDHREC Average Default / Teysa Karlov:** ✅ lands dentro do profile (35-37); 🟡 ramp=15 > profile ramp max=11
- **Kinnan, Bonder Prodigy / Kinnan, Bonder Prodigy:** 🟡 ALERTA: lands=29 < 32; ✅ lands dentro do profile (29-34); 🟡 ramp=4 < profile nonland_mana_sources min=18

### Ações recomendadas
- **P0/P1 revisar classificação:** Korvold, Fae-Cursed King disparou crítico genérico, mas é artefato EDHREC parcial (`total_cards=11`); validar contra corpus/profile antes de reinserir.
- **P1:** Lorehold tem CMC 3.98 > 3.5; validar se a curva alta é intencional do plano topdeck/miracle ou se precisa reduzir bombas caras.
- **P2:** revisar métricas de Teysa Karlov contra profile/corpus específico antes de alterar decklist.
- **P2:** Kinnan tem 29 lands e bracket 4; profile EDHREC aceita 29-34, então o alerta genérico de lands baixas não deve virar bug sem evidência adicional.

### Evidência de profiles/corpus usados
- `commander_reference_deck_corpus_lorehold_2026-05-12/dry_run_after_backfill/lorehold_the_historian_dry_run_summary.json` — Lorehold corpus: lands avg=32.0, ramp avg=14.67, accepted_decks=3
- `commander_reference_profile_anchor30_batch_b_2026-05-12/profiles/aesi_tyrant_of_gyre_strait.json` — commander Aesi, Tyrant of Gyre Strait; keys=lands, ramp_extra_lands, supplemental_draw, interaction_counter, board_wipes_bounce, protection, landfall_payoffs, land_recursion_bounce, finishers
- `commander_reference_profile_anchor30_batch_b_2026-05-12/profiles/teysa_karlov.json` — commander Teysa Karlov; keys=lands, ramp, draw_value, interaction, board_wipes, protection, sacrifice_outlets, fodder_tokens, death_payoffs, recursion
- `commander_reference_profile_anchor30_batch_a_2026-05-12/profiles/korvold_fae_cursed_king.json` — commander Korvold, Fae-Cursed King; keys=lands, ramp_treasure, sacrifice_fodder, sacrifice_outlets, aristocrat_payoffs, draw_value, interaction, combo_finishers
- `commander_reference_profile_anchor30_batch_a_2026-05-12/profiles/yuriko_the_tigers_shadow.json` — commander Yuriko, the Tiger's Shadow; keys=lands, evasive_enablers, ninjas, topdeck_manipulation, high_mv_reveals, interaction, combo_finishers
- `commander_reference_profile_anchor30_batch_a_2026-05-12/profiles/kinnan_bonder_prodigy.json` — commander Kinnan, Bonder Prodigy; keys=lands, nonland_mana_sources, mana_dorks, artifact_mana, infinite_mana_pieces, payoffs_outlets, interaction_protection

<!-- mana-base-validator: end -->
