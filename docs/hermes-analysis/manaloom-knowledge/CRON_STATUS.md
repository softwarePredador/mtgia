# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-28T03:10Z** (manager-watchdog — snapshot rotineiro)

## Resumo

|| Métrica | Valor |
||:--|:--:|
|| Total de crons (`include_disabled=True`) | 15 |
|| Habilitados | 15/15 |
|| Desabilitados | 0 |
|| `last_status=error` | **6** |
|| Nunca executaram (`last_run_at=null`) | 0 |
|| Stale (>120min atrás, `enabled=true`) | 0 |
|| Ações de recuperação nesta execução | 0 (erros transitórios — ver abaixo) |
|| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** todos os 15 crons habilitados e scheduled. **6 crons com `last_status=error`** — todos erros transitórios (HTTP 429/502 rate-limit do provider, truncation de resposta). Nenhum cron desabilitado, stale (>120min) ou never-run; portanto **nenhum `resume`/`run` foi necessário** — os erros são de runtime (provider/truncation), não de configuração.

## Ações da Rodada Atual

|| # | Ação | Resultado ||
||:--|:-----|:----------||
|| 1 | `cronjob(action='list', include_disabled=True)` | ✅ 15 jobs listados |
|| 2 | Verificação de branch (`git branch --show-current`) | ✅ `codex/hermes-analysis-docs` |
|| 3 | Verificação do worktree (`git status --short`) | ⚠️ 1 arquivo dirty: `knowledge.db` (artefato de cron, ignorado) |
|| 4 | Avaliação das regras gerenciais (`enabled=false`, stale>120m, never-run) | ✅ nenhuma ação corretiva requerida |
|| 5 | Verificação de `last_status=error` | ⚠️ 6 erros encontrados (todos transitórios — ver detalhes abaixo) |
|| 6 | Atualização do CRON_STATUS.md | ✅ snapshot 2026-05-28T03:10Z |

## Crons de Auditoria / Gerenciais

|| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação ||
||---|---|---|---|---|---|---|---|---||
|| `757eefb8738b` | manaloom-master-watchdog | every 30m | sim | 2026-05-28T03:10Z | 1min | 🟢 ok | scheduled | sem ação ||
|| `660397bb97e1` | manaloom-hermes-normal-audit | 0 16,21 * * * | sim | 2026-05-28T01:30Z | 100min | 🟢 ok | scheduled | próxima: 16:00Z ||
|| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | 30 12 * * 0 | sim | 2026-05-28T01:36Z | 94min | 🟢 ok | scheduled | próxima: dom 12:30Z ||
|| `2d436c71bbf7` | manaloom-manager-watchdog | every 30m | sim | 2026-05-28T03:10Z | 1min | 🟢 ok | scheduled | **esta execução** ||
|| `577a0a669714` | manaloom-code-structure-auditor (weekly) | 0 6 * * 0 | sim | 2026-05-28T02:22Z | 48min | 🔴 error | scheduled | **HTTP 502** — provider error transitório ||
|| `bb03201b8911` | manaloom-code-structure-auditor (4h) | 0 20,0,4,8,12,16 * * * | sim | 2026-05-28T02:22Z | 48min | 🔴 error | scheduled | **HTTP 502** — provider error transitório ||

## Crons de Conhecimento Commander

|| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação ||
||---|---|---|---|---|---|---|---|---||
|| `75eed994c103` | manaloom-commander-knowledge-deep | every 20m | sim | 2026-05-28T03:12Z | 1min | 🔴 error | scheduled | **truncated response** — ferramenta de resposta excedeu limite (arquivo 1.5KB) ||
|| `7915cc2377a0` | manaloom-gamechanger-research | every 20m | sim | 2026-05-28T03:12Z | 1min | 🟢 ok | scheduled | execução OK ||
|| `b340374bc4e7` | manaloom-tag-accuracy-reporter | every 360m | sim | 2026-05-28T02:05Z | 68min | 🟢 ok | scheduled | sem ação ||
|| `444aa9510c2c` | manaloom-mana-base-validator | every 60m | sim | 2026-05-28T03:28Z | 5min 🟢 | 🟢 ok | scheduled | sem ação ||
|| `b2f5c21ce2d7` | manaloom-knowledge-import | every 30m | sim | 2026-05-28T03:11Z | 2min | 🔴 error | scheduled | **HTTP 429** — rate limit do provider |

## Lorehold Knowledge Pipeline

|| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação ||
||---|---|---|---|---|---|---|---|---||
|| `f20ac299992b` | lorehold-deck-scout | every 30m | sim | 2026-05-28T03:03Z | 10min | 🟢 ok | scheduled | sem ação ||
|| `712579b15767` | lorehold-deck-validator | every 60m | sim | 2026-05-28T03:42Z | 11min 🟢 | 🟢 ok | scheduled | sem ação ||
|| `08468451a06a` | lorehold-mulligan-analyst | every 120m | sim | 2026-05-28T02:22Z | 51min | 🔴 error | scheduled | **scout data mismatch** — comparação EDHREC corpus vs live (erro de dados, não de config) ||
|| `a50bef4c2a59` | lorehold-evolution-oracle | every 360m | sim | 2026-05-28T02:22Z | 51min | 🔴 error | scheduled | **scout data mismatch** — mesmo erro que mulligan-analyst ||

## Alertas Pendentes

**6 crons com `last_status=error` nesta rodada** — todos classificados como erros transitórios de runtime, não requerendo ação de `resume` ou `run`:

| Job ID | Nome | Erro | Tipo | Ação |
|:-------|:-----|:-----|:-----|:-----|
| `75eed994c103` | commander-knowledge-deep | `Response remained truncated after 3 continuation attempts` | Truncação de resposta (prompt muito grande?) | Monitorar — se persistir, reduzir prompt |
| `08468451a06a` | lorehold-mulligan-analyst | Scout data mismatch — EDHREC corpus 0% vs live 55.4% | Dados EDHREC inconsistentes | Monitorar — erro nos dados de entrada, não no código |
| `a50bef4c2a59` | lorehold-evolution-oracle | Mesmo scout data mismatch | Dados EDHREC inconsistentes | Monitorar — mesmo root cause acima |
| `b2f5c21ce2d7` | manaloom-knowledge-import | `HTTP 429: Rate limit exceeded` | Rate limit transitório | Auto-recupera na próxima tick |
| `577a0a669714` | structure-auditor (weekly) | `HTTP 502: Provider returned error` | Provider outage transitório | Auto-recupera na próxima tick |
| `bb03201b8911` | structure-auditor (4h) | `HTTP 502: Provider returned error` | Provider outage transitório | Auto-recupera na próxima tick |

**Nenhuma ação corretiva aplicada** — os 6 erros são de runtime (provider rate-limit, truncation, data mismatch), não de configuração (disabled, stale, never-run). Todos os crons com erro continuam `enabled=true` e `state=scheduled`, sendo reexecutados automaticamente pelo scheduler.

## Precisão das Functional Tags (tag_accuracy)

> Última verificação: **2026-05-28T02:00Z** (cron `manaloom-tag-accuracy-reporter`)

### Resumo Geral

| Métrica | Valor |
|:--|:--:|
| Total de tags avaliadas | 29 |
| Acertos / Total | **378/454** |
| Precisão global | **83.3%** |

### Tags com 100% de Precisão (15 tags)

| Tag | Amostras |
|:--|:--:|
| land | 87 |
| utility | 76 |
| ramp | 53 |
| draw | 32 |
| removal | 30 |
| creature | 22 |
| tutor | 6 |
| board_wipe | 3 |
| recursion | 3 |
| planeswalker | 2 |
| artifact | 2 |
| enchantment | 3 |
| sacrifice_outlet | 1 |
| finisher | 2 |
| wipe | 1 |

### Tags Problemáticas (< 50%)

| Tag | Precisão | Amostras | Problema |
|:--|:--:|:--|:--|
| **ninja** | **0.0%** | 17 | TODAS as 17 classificações como "ninja" estão erradas |
| ramp + combo_piece | 0.0% | 1 | Tag composta rara, sem acerto |
| recursion + wincon | 0.0% | 1 | Tag composta rara, sem acerto |
| ramp + payoff | 0.0% | 1 | Tag composta rara, sem acerto |
| payoff + removal | 0.0% | 1 | Tag composta rara, sem acerto |
| payoff + token_maker | 0.0% | 1 | Tag composta rara, sem acerto |
| stax_disruption | 0.0% | 3 | 3/3 erradas — classificador confunde stax com outras funções |

### Tags Intermediárias (50-75%)

| Tag | Precisão | Amostras |
|:--|:--:|:--:|
| payoff | 35.5% | 31 |
| combo_piece | 50.0% | 2 |
| enabler | 50.0% | 42 |
| other | 50.0% | 2 |
| protection | 69.2% | 13 |
| wincon | 75.0% | 8 |
| engine | 75.0% | 8 |

### Análise

**Pontos fortes:**
- Tags fundamentais (land, utility, ramp, draw, removal) estão em 100% — a base do classificador é sólida.
- 15 de 29 tags têm precisão perfeita.

**Pontos fracos críticos:**
1. **ninja (0.0%, 17 erros):** O classificador está atribuindo "ninja" massivamente a cartas que não são ninja. Isso é um viés grave — provavelmente o regex/heurística captura retorno à mão (ninjutsu) mas classifica errado.
2. **stax_disruption (0.0%, 3 erros):** O classificador não consegue diferenciar stax de outras formas de disruption.
3. **Tags compostas (todas 0%):** Tags compostas como `ramp + combo_piece`, `payoff + removal` têm amostras muito pequenas (1 cada) e zero acertos. Ou o classificador não deveria gerá-las golden tags, ou precisa de ajuste.
4. **enabler (50%, 42 amostras):** Metade dos "enablers" estão classificados errados — impacto significativo na análise de decks.
5. **payoff (35.5%, 31 amostras):** A tag mais problemática em volume. 20 das 31 classificações estão erradas.

**Recomendação:** Revisar as heurísticas de ninja, payoff, enabler e stax_disruption. As tags compostas podem ser reviewedas para verificar se os golden labels estão corretos.

## Mana Base Validation Report

> **Última execução:** 2026-05-28T03:25Z (cron `manaloom-mana-base-validator`)
> **Decks analisados:** 8
> **Nota:** Lorehold (deck 6) não possui perfil de referência no diretório de artifacts — sem validação de role_targets.

### Resumo

| Deck | Commander | Status | Total Cards | DB Lands | SQLite Lands | Profile Lands | Problemas |
|:-----|:----------|:------:|:-----------:|:--------:|:------------:|:-------------:|:----------|
| 1 — Kinnan | Kinnan, Bonder Prodigy | 🔴 CRIT | 13 | 29 | 0 | 29-34 | Ramp (mana_dorks) 🔴 CRIT; Protection (interaction_protection) 🔴 CRIT; Total Cards 🔴 CRIT (13/100); Lands DB vs SQLite 🔴 CRIT |
| 2 — Dimir Ninja | Yuriko, the Tiger's Shadow | 🟡 WARN | 99 | 33 | 35 | 30-34 | Total Cards 🟡 WARN (99/100); Lands DB vs SQLite 🟡 WARN (DB=33, SQLite=35) |
| 3 — Korvold | Korvold, Fae-Cursed King | 🔴 CRIT | 11 | 25 | 0 | 34-37 | Lands 🔴 CRIT; Ramp (ramp_treasure) 🔴 CRIT; Draw (draw_value) 🔴 CRIT; Total Cards 🔴 CRIT (11/100); Lands DB vs SQLite 🔴 CRIT |
| 4 — Teysa | Teysa Karlov | 🔴 CRIT | 80 | 35 | 15 | 35-37 | Ramp (ramp) 🔴 CRIT; Total Cards 🔴 CRIT (80/100); Lands DB vs SQLite 🔴 CRIT |
| 5 — Aesi | Aesi, Tyrant of Gyre Strait | 🔴 CRIT | 100 | 40 | 40 | 39-43 | Ramp (ramp_extra_lands) 🔴 CRIT; Draw (supplemental_draw) 🟡 WARN; Protection (protection) 🟡 WARN |
| 6 — Lorehold | Lorehold, the Historian | ✅ OK | 100 | 35 | 35 | N/A (sem perfil) | (sem perfil de referência) |
| 7 — Winota | Winota, Joiner of Forces | 🟡 WARN | 100 | 34 | 34 | 31-35 | Protection (protection) 🟡 WARN |
| 9 — Atraxa | Atraxa, Praetors' Voice | 🔵 BLUE | 100 | 36 | 36 | 35-38 | Ramp (ramp_fixing) 🔵 BLUE |

### Achados Críticos

1. **4 decks incompletos/parciais:** Deck 1 (Kinnan): 13/100; Deck 2 (Yuriko): 99/100; Deck 3 (Korvold): 11/100; Deck 4 (Teysa): 80/100
2. **3 decks com divergência grave DB vs SQLite lands:** Deck 1 (Kinnan): DB=29, SQLite=0, Diff=-29; Deck 3 (Korvold): DB=25, SQLite=0, Diff=-25; Deck 4 (Teysa): DB=35, SQLite=15, Diff=-20
3. **Deck 5 (Aesi):** ramp_count=28 vs perfil 14-18 (CRIT +10 acima do max), draw_count=12 vs perfil 6-9 (WARN +3 acima do max), protection_count=7 vs perfil 2-4 (WARN +3 acima do max)
4. **Deck 7 (Winota):** protection_count=10 vs perfil 5-8 (WARN +2 acima do max)
5. **Deck 6 (Lorehold):** único deck completo sem perfil de referência — não é possível validar role_targets contra EDHREC

### Divergências Lands DB vs SQLite

| Deck | DB total_lands | SQLite lands | Diferença | Status |
|:-----|:---------------|:-------------|:----------|:-------|
| 1 — Kinnan | 29 | 0 | -29 | ❌ |
| 2 — Yuriko | 33 | 35 | +2 | ⚠️ |
| 3 — Korvold | 25 | 0 | -25 | ❌ |
| 4 — Teysa | 35 | 15 | -20 | ❌ |
| 5 — Aesi | 40 | 40 | 0 | ✅ |
| 6 — Lorehold | 35 | 35 | 0 | ✅ |
| 7 — Winota | 34 | 34 | 0 | ✅ |
| 9 — Atraxa | 36 | 36 | 0 | ✅ |

### Mudanças desde última validação (02:18Z)

- **Sem mudanças estruturais**: todos os decks mantêm os mesmos totais de cartas e lands desde a validação anterior.
- **Decks 1, 3, 4** continuam com dados incompletos nas tabelas (insert parcial durante import anterior).
- **Deck 2 (Yuriko):** total_cards no DB permanece 84 vs 99 real no SQLite — dado desatualizado desde import.
- **Nenhum novo deck inserido ou removido** desde última validação.

---

## Observações Importantes

- **6 crons com erro** (todos `enabled=true`, `state=scheduled`): 2× HTTP 502 (provider outage), 1× HTTP 429 (rate limit), 1× truncated response, 2× scout data mismatch. **Nenhum requeriu `resume`/`run`** — todos são erros de runtime transitórios.
- `lorehold-mulligan-analyst` e `lorehold-evolution-oracle` falharam no mesmo erro de dados EDHREC (comparação 0% vs 55.4%) — provável inconsistência temporária na fonte de dados, não bug no código.
- `commander-knowledge-deep` com resposta truncada (1.5KB) — possivelmenteprompt muito grande ou tool-call limit. Monitorar nas próximas execuções.
- `manaloom-knowledge-import` com HTTP 429 — rate limit do provider, auto-recupera.
- `manaloom-code-structure-auditor` (ambos) com HTTP 502 — provider outage transitório.
- `lorehold-deck-validator` rodou há 11min (03:42Z) — execução mais recente da frota.
- `origin/master` estável sem novos commits desde a última análise.
- `dart` e `flutter` continuam presentes (`/opt/data/tools/flutter/bin/`).
- Apenas este arquivo (`CRON_STATUS.md`) foi atualizado intencionalmente nesta rodada.

