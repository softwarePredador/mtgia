# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-27T15:41Z**

## Resumo

| Métrica | Valor |
|:--|:--:|
| Total de crons (`include_disabled=True`) | 12 |
| Habilitados | 12/12 |
| Desabilitados | 0 |
| `last_status=error` | **4** 🔴 (↓ de 9 desde 15:02Z) |
| Nunca executaram (`last_run_at=null`) | 0 |
| Stale (>120min atrás, `enabled=true`) | 0 |
| Fleet removidos desde última rodada | 4 (daily-deep-audit, weekly-memory-cleanup, themes-research, missing-gc-filler) |
| Recuperados desde última rodada | 2 (commander-knowledge-deep, lorehold-deck-scout) |
| Branch do workdir | `codex/hermes-analysis-docs` |
| HEAD da branch de análise | `9a1ee1410858` |

**Estado geral:** 12/12 habilitados ✅. Fleet reduzido de 16 para 12 (consolidação 2026-05-27). 4 crons em `status=error` 🔴 (↓ de 9). 2 crons se recuperaram desde o último relatório. Nenhum cron stale ou desabilitado.

**Padrão:** Os 4 erros são todos de provider/model (3× GitHub 429, 1× gpt-5.5 model not found). Crons que funcionam usam `provider=deepseek` com `model=deepseek-v4-flash` e conseguiram executar. Os que falham parecem estar com provider chain caindo em copilot mesmo com deepseek configurado — ou tiveram a configuração alterada recentemente e os erros são de execuções anteriores.

## Crons de Auditoria / Gerenciais

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--|
| `757eefb8738b` | manaloom-master-watchdog | `every 30m` | ✅ | 2026-05-27 15:05Z | 36min | 🟢 ok | 2026-05-27 15:35Z | sem ação |
| `660397bb97e1` | manaloom-hermes-normal-audit | `0 16,21 * * *` | ✅ | 2026-05-27 12:19Z | 3h22min | 🟢 ok | 2026-05-27 16:00Z | agendado para 16:00 — normal |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | `30 12 * * 0` | ✅ | 2026-05-27 12:56Z | 2h45min | 🟢 ok | 2026-05-31 12:30Z | aguardando domingo |
| `2d436c71bbf7` | manaloom-manager-watchdog | `every 30m` | ✅ | 2026-05-27 15:05Z | 36min | 🟢 ok | 2026-05-27 15:35Z | **esta execução** |

## Crons de Conhecimento Commander

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--|
| `75eed994c103` | manaloom-commander-knowledge-deep | `every 20m` | ✅ | 2026-05-27 15:38Z | 3min | 🟢 ok | 2026-05-27 15:58Z | ✅ **RECUPERADO** desde 15:02Z (estava error) — deepseek funcionou |
| `7915cc2377a0` | manaloom-gamechanger-research | `every 20m` | ✅ | 2026-05-27 15:01Z | 40min | 🔴 error | 2026-05-27 15:40Z | ❌ HTTP 429 (GitHub rate limit) — provider aparenta cair em copilot |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | `every 360m` | ✅ | 2026-05-27 13:05Z | 2h36min | 🟢 ok | 2026-05-27 19:05Z | próximo ciclo às 19:05Z |
| `444aa9510c2c` | manaloom-mana-base-validator | `every 60m` | ✅ | 2026-05-27 14:40Z | 1h01min | 🔴 error | 2026-05-27 16:04Z | ❌ HTTP 429 (GitHub rate limit) — sem provider explícito, usa default chain (copilot?) |

## Lorehold Knowledge Pipeline

| ID | Cron | Schedule | Enabled | Last run | Age | Status | Next run | Observação |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--|
| `f20ac299992b` | lorehold-deck-scout | `every 30m` | ✅ | 2026-05-27 15:16Z | 25min | 🟢 ok | 2026-05-27 15:46Z | ✅ **RECUPERADO** — trigger da rodada 15:02Z funcionou |
| `712579b15767` | lorehold-deck-validator | `every 60m` | ✅ | 2026-05-27 14:44Z | 57min | 🔴 error | 2026-05-27 16:29Z | ❌ HTTP 429 (GitHub rate limit) |
| `08468451a06a` | lorehold-mulligan-analyst | `every 120m` | ✅ | 2026-05-27 15:21Z | 20min | 🔴 error | 2026-05-27 17:29Z | ❌ Model `gpt-5.5` não acessível (config residual de copilot) |
| `a50bef4c2a59` | lorehold-evolution-oracle | `every 360m` | ✅ | 2026-05-27 13:22Z | 2h19min | 🟢 ok | 2026-05-27 19:22Z | normal para schedule 6h |

## Ações da Rodada Atual (2026-05-27T15:41Z)

| # | ID | Cron | Ação | Motivo | Resultado |
|:-:|:--|:--|:--|:--|:--|
| 1 | — | **mestre** | `git pull` | Branch `codex/hermes-analysis-docs` já atualizada | ✅ ff-only aplicado |
| 2 | — | **diagnóstico** | diagnosticou 4 erros | 3× HTTP 429, 1× gpt-5.5 model error | 🔍 dados coletados dos arquivos de output |

**Observação:** Nenhum cron estava desabilitado ou stale (>120min). Nenhum `resume` ou `run` foi necessário. Os 4 erros são sistêmicos (provider/model chain) e os crons afetados continuam habilitados e agendados.

## Mudanças desde o Último Relatório (2026-05-27T15:02Z)

| Mudança | Detalhe |
|:--------|:--------|
| Fleet reduzido | 16→12 crons (4 removidos na consolidação 2026-05-27: daily-deep-audit, weekly-memory-cleanup, themes-research, missing-gc-filler) |
| Commander-knowledge-deep | **RECUPERADO** ✅ — erro → ok (agora com deepseek funcional) |
| Lorehold-deck-scout | **RECUPERADO** ✅ — stale/error → ok (trigger funcionou) |
| Lorehold-mulligan-analyst | **NOVO ERRO** 🔴 — era ok→error (gpt-5.5 model not found) |
| Erros totais | 9→4 (↓ devido à remoção de crons + recuperações) |
| Stale crons | 2→0 (triggers funcionaram) |

## Alertas Pendentes

### 🔴 4 crons com `last_status=error` — padrão de provider

Todos os 4 erros compartilham a mesma causa raiz: problemas de provider/model chain que fazem o Hermes cair em copilot em vez de usar deepseek.

| Cron | Último run | Erro | Provider configurado | Model configurado |
|:-----|:----------:|:----|:--------------------:|:-----------------:|
| manaloom-gamechanger-research | 15:01Z | HTTP 429 (GitHub) | `deepseek` | `deepseek-v4-flash` |
| manaloom-mana-base-validator | 14:40Z | HTTP 429 (GitHub) | `None` (default) | `None` (default) |
| lorehold-deck-validator | 14:44Z | HTTP 429 (GitHub) | `deepseek` | `deepseek-v4-flash` |
| lorehold-mulligan-analyst | 15:21Z | gpt-5.5 not accessible | `deepseek` | `deepseek-v4-flash` |

**Hipótese principal:** A configuração `provider=deepseek, model=deepseek-v4-flash` está sendo salva no cron config, mas o Hermes provider chain pode ter um fallback que cai em copilot quando deepseek está indisponível ou quando o modelo específico não pode ser usado. Isto explicaria por que:
- Alguns crons com deepseek funcionam (commander-knowledge-deep, deck-scout)
- Outros com deepseek idêntico falham com 429 do GitHub (gamechanger, deck-validator)

**3 crons com HTTP 429 (GitHub rate limit):** Estes provavelmente estão caindo no provider copilot via fallback chain. O mana-base-validator não tem provider/model explícito — usa o default, que inclui copilot.

**1 cron com modelo gpt-5.5:** Herança de configuração residual de copilot. O scheduler pode estar usando a configuração antiga em vez da atual.

**Nenhum action trigger enviado:** Todos os 4 crons estão `enabled=true` com `state=scheduled` e `next_run_at` avançando. A scheduler tentará executá-los novamente nos próximos ciclos. Como o padrão é sistêmico e não de scheduler, triggers `run` adicionais não resolveriam — os jobs continuariam falhando no mesmo ponto.

**Recomendação:** Para resolver, cada cron afetado precisaria de:
1. Confirmação de que `provider=deepseek, model=deepseek-v4-flash` é respeitado (não cai em copilot)
2. Se o mana-base-validator não tiver provider/model, definir explicitamente
3. Se o fallback chain do sistema for inevitável, aumentar a frequência dos crons menos frequentes ou aceitar que alguns minutos são perdidos para 429

## Notas

- Branch confirmada: `codex/hermes-analysis-docs` ✅ (HEAD `9a1ee1410858`)
- `cronjob(action="list", include_disabled=True)` retornou 12 jobs sem `enabled=false`.
- Working tree contém artefatos não relacionados (decks lorehold, scripts de scout, `__pycache__`, `scripts/knowledge.db` vazio em `/opt/data/workspace/mtgia/scripts/`) — apenas `CRON_STATUS.md` será comitado.
- Nenhum token/secret registrado neste relatório.
- 2 crons recuperaram desde o último relatório (commander-knowledge-deep, deck-scout), indicando que o scheduler e deepseek provider estão funcionais para alguns jobs.

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
