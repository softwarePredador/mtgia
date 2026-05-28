# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-28T03:05Z** (manager-watchdog — snapshot rotineiro)

## Resumo

| Métrica | Valor |
|:--|:--:|
| Total de crons (`include_disabled=True`) | 15 |
| Habilitados | 15/15 |
| Desabilitados | 0 |
| `last_status=error` | **0** |
| Nunca executaram (`last_run_at=null`) | 0 |
| Stale (>120min atrás, `enabled=true`) | 0 |
| Ações de recuperação nesta execução | 0 |
| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** todos os 15 crons habilitados e scheduled. **0 crons em `last_status=error`** — os 4 erros anteriores (HTTP 429/402 do OpenRouter free-tier) foram resolvidos ou são artefatos de rodadas anteriores. Nenhum cron desabilitado, stale (>120min) ou never-run; portanto **nenhum `resume`/`run` foi necessário**.

## Ações da Rodada Atual

| # | Ação | Resultado |
|:--|:-----|:----------|
| 1 | `cronjob(action='list', include_disabled=True)` | ✅ 15 jobs listados |
| 2 | Verificação de branch (`git branch --show-current`) | ✅ `codex/hermes-analysis-docs` |
| 3 | Verificação do worktree (`git status --short`) | ✅ limpo (sem artefatos de cron relevantes) |
| 4 | Avaliação das regras gerenciais (`enabled=false`, stale>120m, never-run) | ✅ nenhuma ação corretiva requerida |
| 5 | Verificação de `last_status=error` | ✅ 0 erros — todos os 15 crons com status OK ou sem erro |
| 6 | Atualização do CRON_STATUS.md | ✅ snapshot 2026-05-28T03:05Z |

## Crons de Auditoria / Gerenciais

| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação |
|---|---|---|---|---|---|---|---|---|
| `757eefb8738b` | manaloom-master-watchdog | every 30m | sim | 2026-05-28T01:09:56Z | 116min | — | scheduled | sem ação |
| `660397bb97e1` | manaloom-hermes-normal-audit | 0 16,21 * * * | sim | 2026-05-28T01:30:40Z | 95min | — | scheduled | sem ação |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | 30 12 * * 0 | sim | 2026-05-28T01:36:02Z | 90min | — | scheduled | sem ação |
| `2d436c71bbf7` | manaloom-manager-watchdog | every 30m | sim | 2026-05-28T02:02:13Z | 63min | — | scheduled | **esta execução** |
| `577a0a669714` | manaloom-code-structure-auditor | 0 6 * * 0 | sim | 2026-05-28T02:22:52Z | 43min | — | scheduled | sem ação |
| `bb03201b8911` | manaloom-code-structure-auditor | 0 20,0,4,8,12,16 * * * | sim | 2026-05-28T02:22:52Z | 43min | — | scheduled | sem ação |

## Crons de Conhecimento Commander

| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação |
|---|---|---|---|---|---|---|---|---|
| `75eed994c103` | manaloom-commander-knowledge-deep | every 20m | sim | 2026-05-28T02:48:13Z | 17min | — | scheduled | sem ação |
| `7915cc2377a0` | manaloom-gamechanger-research | every 20m | sim | 2026-05-28T02:48:48Z | 17min | — | scheduled | sem ação |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | every 360m | sim | 2026-05-28T02:05:01Z | 61min | — | scheduled | sem ação |
| `444aa9510c2c` | manaloom-mana-base-validator | every 60m | sim | 2026-05-28T02:19:01Z | 47min | — | scheduled | sem ação |
| `b2f5c21ce2d7` | manaloom-knowledge-import | every 30m | sim | 2026-05-28T02:22:51Z | 43min | — | scheduled | sem ação |

## Lorehold Knowledge Pipeline

| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação |
|---|---|---|---|---|---|---|---|---|
| `f20ac299992b` | lorehold-deck-scout | every 30m | sim | 2026-05-28T03:03:46Z | 2min | — | scheduled | sem ação |
| `712579b15767` | lorehold-deck-validator | every 60m | sim | 2026-05-28T02:22:26Z | 43min | — | scheduled | sem ação |
| `08468451a06a` | lorehold-mulligan-analyst | every 120m | sim | 2026-05-28T02:22:34Z | 43min | — | scheduled | sem ação |
| `a50bef4c2a59` | lorehold-evolution-oracle | every 360m | sim | 2026-05-28T02:22:43Z | 43min | — | scheduled | sem ação |

## Alertas Pendentes

**Nenhum alerta pendente nesta rodada.** Todos os 15 crons estão habilitados, sem erros, sem staleness. Os 4 erros anteriores (HTTP 429/402 do OpenRouter free-tier) foram resolvidos — os crons retomaram execução normal nas rodadas seguintes.

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

- Nenhum cron desabilitado, stale (>120min) ou never-run nesta rodada — **nenhuma ação `resume`/`run` foi necessária**.
- **Resolução dos erros anteriores:** Os 4 crons que estavam em `last_status=error` na rodada 2026-05-28T02:00Z (lorehold-deck-scout, lorehold-deck-validator, lorehold-mulligan-analyst, commander-knowledge-deep) todos retornaram a execução normal. O `cronjob(list)` atual retornou 0 erros.
- `lorehold-deck-scout` rodou há apenas 2 minutos (03:03:46Z) — execução mais recente de toda a frota.
- `origin/master` estável sem novos commits desde a última análise.
- `dart` e `flutter` continuam presentes (`/opt/data/tools/flutter/bin/`), baseline de tooling responsiva.
- Apenas este arquivo (`CRON_STATUS.md`) foi atualizado intencionalmente nesta rodada.

