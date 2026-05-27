# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-27T16:22Z**

## Resumo

| Métrica | Valor |
|:--|:--:|
| Total de crons (`include_disabled=True`) | 12 |
| Habilitados | 12/12 |
| Desabilitados | 0 |
| `last_status=error` | **2** 🔴 (↓ de 4 desde 15:41Z) |
| Nunca executaram (`last_run_at=null`) | 0 |
| Stale (>120min atrás, `enabled=true`) | 0 |
| Fleet removidos desde última rodada | 4 (daily-deep-audit, weekly-memory-cleanup, themes-research, missing-gc-filler) |
| Recuperados desde última rodada | 4 (commander-knowledge-deep, lorehold-deck-scout, gamechanger-research, mana-base-validator) |
| Branch do workdir | `codex/hermes-analysis-docs` |
| HEAD da branch de análise | `dfe4451003` |

**Estado geral:** 12/12 habilitados ✅. Fleet consolidado em 12 crons. 2 crons em `status=error` 🔴 (↓ de 4 desde 15:41Z). 4 crons se recuperaram desde o último relatório: commander-knowledge-deep, lorehold-deck-scout, gamechanger-research, mana-base-validator. Nenhum cron stale ou desabilitado.

**Padrão:** 2 erros residuais (lorehold-deck-validator, lorehold-mulligan-analyst). Ambos têm config corrigida — `provider=deepseek, model=deepseek-v4-flash` com `workdir` correto — mas os últimos runs ocorreram antes da correção, então os erros (HTTP 429 e gpt-5.5 model) refletem a configuração anterior. Ambos estão agendados para nova execução (deck-validator: ~16:29Z, mulligan-analyst: ~17:29Z).

## Crons de Auditoria / Gerenciais

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--|
| `757eefb8738b` | manaloom-master-watchdog | `every 30m` | ✅ | 2026-05-27 15:44Z | 38min | 🟢 ok | 2026-05-27 16:14Z | sem ação — rodando normalmente |
| `660397bb97e1` | manaloom-hermes-normal-audit | `0 16,21 * * *` | ✅ | 2026-05-27 16:09Z | 13min | 🟢 ok | 2026-05-27 21:00Z | executou às 16:09Z ✅ |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | `30 12 * * 0` | ✅ | 2026-05-27 12:56Z | 3h26min | 🟢 ok | 2026-05-31 12:30Z | aguardando domingo |
| `2d436c71bbf7` | manaloom-manager-watchdog | `every 30m` | ✅ | 2026-05-27 15:44Z | 38min | 🟢 ok | 2026-05-27 16:14Z | **esta execução** |

## Crons de Conhecimento Commander

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--|
| `75eed994c103` | manaloom-commander-knowledge-deep | `every 20m` | ✅ | 2026-05-27 15:38Z | 3min | 🟢 ok | 2026-05-27 15:58Z | ✅ **RECUPERADO** desde 15:02Z (estava error) — deepseek funcionou |
| `7915cc2377a0` | manaloom-gamechanger-research | `every 20m` | ✅ | 2026-05-27 16:22Z | <1min | 🟢 ok | 2026-05-27 16:42Z | ✅ **RECUPERADO** — agora com deepseek funcional |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | `every 360m` | ✅ | 2026-05-27 13:05Z | 2h36min | 🟢 ok | 2026-05-27 19:05Z | próximo ciclo às 19:05Z |
| `444aa9510c2c` | manaloom-mana-base-validator | `every 60m` | ✅ | 2026-05-27 16:11Z | 11min | 🟢 ok | 2026-05-27 17:11Z | ✅ **RECUPERADO** — executou com deepseek funcional |

## Lorehold Knowledge Pipeline

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--|
| `f20ac299992b` | lorehold-deck-scout | `every 30m` | ✅ | 2026-05-27 16:17Z | 5min | 🟢 ok | 2026-05-27 16:47Z | ✅ rodando com deepseek normalmente |
| `712579b15767` | lorehold-deck-validator | `every 60m` | ✅ | 2026-05-27 14:44Z | 1h38min | 🔴 error | 2026-05-27 16:29Z | ❌ HTTP 429 no último run (config copilot anterior). Config já corrigida para deepseek ✅. Aguardando scheduler (~16:29Z) |
| `08468451a06a` | lorehold-mulligan-analyst | `every 120m` | ✅ | 2026-05-27 15:21Z | 1h01min | 🔴 error | 2026-05-27 17:29Z | ❌ Model `gpt-5.5` no último run (config copilot anterior). Config já corrigida para deepseek + workdir ✅. Aguardando scheduler (~17:29Z) |
| `a50bef4c2a59` | lorehold-evolution-oracle | `every 360m` | ✅ | 2026-05-27 13:22Z | 2h19min | 🟢 ok | 2026-05-27 19:22Z | normal para schedule 6h |

## Ações da Rodada Atual (2026-05-27T16:22Z)

| # | ID | Cron | Ação | Motivo | Resultado |
|:-:|:--|:--|:--|:--|:--|
| 1 | — | **mestre** | `git pull` | Branch `codex/hermes-analysis-docs` já atualizada | ✅ ff-only aplicado |
| 2 | — | **diagnóstico** | diagnosticou 12 crons | 2 erros residuais (↓ de 4 em 15:41Z) | 🔍 dados coletados |
| 3 | — | **observação** | 2 crons se recuperaram desde 15:41Z | gamechanger-research e mana-base-validator voltaram a ok | ✅ recuperação natural via scheduler |
| 4 | — | **config** | verificação de config | deck-validator e mulligan-analyst já com deepseek + workdir correto | ✅ config verificada, aguardando próximos runs |

**Observação:** Nenhum cron estava desabilitado ou stale (>120min). Nenhum `resume` ou `run` foi necessário. 2 crons se recuperaram naturalmente via scheduler desde 15:41Z. 2 erros residuais (deck-validator, mulligan-analyst) com config já corrigida, aguardando próximos runs do scheduler.

## Mudanças desde o Último Relatório (2026-05-27T15:41Z)

| Mudança | Detalhe |
|:--------|:--------|
| Manaloom-gamechanger-research | **RECUPERADO** ✅ — erro→ok (deepseek funcional na rodada 16:22Z) |
| Manaloom-mana-base-validator | **RECUPERADO** ✅ — erro→ok (deepseek funcional na rodada 16:11Z) |
| Manaloom-hermes-normal-audit | **EXECUTOU** ✅ — rodada 16:09Z completada |
| Lorehold-deck-validator | **CONFIG CORRIGIDA** ✅ — provider=deepseek, workdir correto. Aguardando próximo run (~16:29Z) |
| Lorehold-mulligan-analyst | **CONFIG CORRIGIDA** ✅ — provider=deepseek, workdir correto. Aguardando próximo run (~17:29Z) |
| Erros totais | 4→2 🔴 (↓ 50%) |

## Alertas Pendentes

### 🔴 2 crons com `last_status=error` — erros residuais de config anterior

Ambos os crons tiveram a configuração corrigida (provider=deepseek, model=deepseek-v4-flash, workdir correto) em rodadas anteriores — mas os últimos runs documentados ainda refletem a configuração antiga (copilot). Aguardando o próximo ciclo do scheduler para confirmar recuperação.

| Cron | Último run | Erro | Provider configurado | Model configurado |
|:-----|:----------:|:----|:--------------------:|:-----------------:|
| lorehold-deck-validator | 14:44Z | HTTP 429 (GitHub) | `deepseek` | `deepseek-v4-flash` |
| lorehold-mulligan-analyst | 15:21Z | gpt-5.5 not accessible | `deepseek` | `deepseek-v4-flash` |

**Próximo ciclo previsto:** deck-validator ~16:29Z, mulligan-analyst ~17:29Z.

**2 crons que se recuperaram nesta rodada (não são mais alerta):**
- manaloom-gamechanger-research: erro (15:01Z, HTTP 429) → ok (16:22Z) ✅
- manaloom-mana-base-validator: erro (14:40Z, HTTP 429) → ok (16:11Z) ✅

**Observação:** Nenhum trigger `run` ou `resume` foi necessário. Todos os 12 crons estão `enabled=true, state=scheduled`. A recuperação dos 2 crons aconteceu naturalmente via scheduler.

## Notas

- Branch confirmada: `codex/hermes-analysis-docs` ✅ (HEAD `dfe4451003`)
- `cronjob(action="list", include_disabled=True)` retornou 12 jobs, todos `enabled=true`.
- 2 crons com `last_status=error` (↓ de 4 desde 15:41Z). Ambos com config corrigida, aguardando scheduler.
- 2 crons recuperaram naturalmente (gamechanger-research, mana-base-validator) desde o último relatório.
- Working tree contém artefatos não relacionados (decks lorehold, scripts de scout, `__pycache__`, `scripts/knowledge.db` vazio em `/opt/data/workspace/mtgia/scripts/`) — apenas `CRON_STATUS.md` será comitado.
- Nenhum token/secret registrado neste relatório.
- Nenhum trigger `run` ou `resume` foi necessário — todos os crons estão habilitados e agendados.

======================================================================

## Validacao de Mana Base (contra Perfis EDHREC)

Deck                           Commander                 Brkt Lands  CMC    Ramp  Draw  Qual       Alertas
------------------------------------------------------------------------------------------------------------------------

Edgar Markov EDHREC Default Av Edgar Markov              3    36     2.9    7     9     COMPLETO(100/100) 🟡ALERT ramp=7<9
Muldrotha EDHREC Average       Muldrotha, the Gravetide  3    36     2.7    12    14    COMPLETO(87/100) ✅
EDHREC Average Default — Boros Winota, Joiner of Forces  4    34     2.4    10    3     COMPLETO(100/100) ✅
Lorehold Spellslinger          Lorehold, the Historian   3    35     4.0    15    8     COMPLETO(100/100) 🟡 CMC=4.0>3.5
Aesi EDHREC Average Default    Aesi, Tyrant of Gyre Stra 3    40     2.6    28    12    EDHREC_P(100/79) 🔵 EDHREC avg parcial (79 cards, sem terrenos completos)
EDHREC Average Default         Teysa Karlov              3    35     2.9    15    11    EDHREC_P(80/80) ✅
EDHREC Average Default         Korvold, Fae-Cursed King  3    25     3.2    3     1     PARCIAL(11/11) 🔴CRIT lands=25(ok 34-37) | 🔴CRIT ramp=3<10 | 🟡ALERT draw=1<6
EDHREC Average Deck - Dimir Ni Yuriko, the Tiger's Shado 3    33     2.8    8     14    EDHREC_P(99/84) 🔵 Yuriko: CMC alto = BOM
Kinnan, Bonder Prodigy         Kinnan, Bonder Prodigy    4    29     1.8    4     3     PARCIAL(13/13) 🔴CRIT ramp=4<18

---

### Perfis EDHREC Usados na Validacao
- **Kinnan, Bonder Prodigy**: lands=29-34, ramp=18-26, draw=?-? | keys=['lands', 'nonland_mana_sources', 'mana_dorks', 'artifact_mana', 'infinite_mana_pieces', 'payoffs_outlets', 'interaction_protection']
- **Yuriko, the Tiger's Shadow**: lands=30-34, ramp=?-?, draw=?-? | keys=['lands', 'evasive_enablers', 'ninjas', 'topdeck_manipulation', 'high_mv_reveals', 'interaction', 'combo_finishers']
- **Korvold, Fae-Cursed King**: lands=34-37, ramp=?-?, draw=6-10 | keys=['lands', 'ramp_treasure', 'sacrifice_fodder', 'sacrifice_outlets', 'aristocrat_payoffs', 'draw_value', 'interaction', 'combo_finishers']
- **Teysa Karlov**: lands=35-37, ramp=9-11, draw=10-14 | keys=['lands', 'ramp', 'draw_value', 'interaction', 'board_wipes', 'protection', 'sacrifice_outlets', 'fodder_tokens', 'death_payoffs', 'recursion']
- **Aesi, Tyrant of Gyre Strait**: lands=39-43, ramp=?-?, draw=?-? | keys=['lands', 'ramp_extra_lands', 'supplemental_draw', 'interaction_counter', 'board_wipes_bounce', 'protection', 'landfall_payoffs', 'land_recursion_bounce', 'finishers']
- **Winota, Joiner of Forces**: lands=31-35, ramp=?-?, draw=?-? | keys=['lands', 'nonhuman_enablers', 'human_hits', 'stax_disruption', 'protection', 'combat_payoffs', 'interaction']
- **Muldrotha, the Gravetide**: lands=36-39, ramp=9-12, draw=?-? | keys=['lands', 'ramp', 'self_mill', 'recursion_value', 'replayable_interaction', 'graveyard_protection', 'finishers']
- **Edgar Markov**: lands=34-36, ramp=9-12, draw=10-13 | keys=['lands', 'ramp', 'draw_value', 'interaction', 'board_wipes', 'protection', 'vampire_density', 'sacrifice_enablers', 'lord_drain_payoffs']
- **Lorehold, the History Scholar**: sem profile EDHREC (Strixhaven) - thresholds genericos usados

---

### Alertas e Recomendacoes

#### Edgar Markov (COMPLETO(100/100))
- 🟡ALERT ramp=7<9

#### Lorehold, the Historian (COMPLETO(100/100))
- 🟡 CMC=4.0>3.5

#### Aesi, Tyrant of Gyre Strait (EDHREC_P(100/79))
- 🔵 EDHREC avg parcial (79 cards, sem terrenos completos)

#### Korvold, Fae-Cursed King (PARCIAL(11/11))
- 🔴CRIT lands=25(ok 34-37)
- 🔴CRIT ramp=3<10
- 🟡ALERT draw=1<6

#### Yuriko, the Tiger's Shadow (EDHREC_P(99/84))
- 🔵 Yuriko: CMC alto = BOM

#### Kinnan, Bonder Prodigy (PARCIAL(13/13))
- 🔴CRIT ramp=4<18

### 🔴 Alertas Criticos (P0)
- Korvold, Fae-Cursed King: ['🔴CRIT lands=25(ok 34-37)', '🔴CRIT ramp=3<10']
- Kinnan, Bonder Prodigy: ['🔴CRIT ramp=4<18']

### 🟡 Alertas Moderados (P1)
- Edgar Markov: ['🟡ALERT ramp=7<9']
- Lorehold, the Historian: ['🟡 CMC=4.0>3.5']

---

*Relatorio gerado em 2026-05-27 pelo cron de validacao de mana base.*
