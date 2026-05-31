# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-31T00:06Z** (manaloom-manager-watchdog)

## Resumo

|| Métrica | Valor ||
|:--|:--:||
| Total de crons (`include_disabled=True`) | **18** ||
| Habilitados | 18/18 ||
| Desabilitados | **0** ||
| `last_status=error` | **12** ||
| `last_status=ok` | **6** ||
| Nunca executaram (`last_run_at=null`) | **0** ||
| Stale (>1.5× schedule atrás, `enabled=true`) | **0** ||
| Ações de recuperação nesta execução | 0 (systemic 429 — run não resolve) |
| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** 18 crons habilitados, **6 OK**, **12 com erro**. ⚠️ **FALHA SISTÊMICA:** Todos os 12 erros são `HTTP 429: Rate limit exceeded: free-models-per-day-stealth`. Nenhuma ação por-cron resolverá — o limite diário do provider foi esgotado.

## Análise de Recuperação

Snapshot anterior: **2026-05-30T14:34Z** (15 OK, 2 error, 0 desabilitados)
Este snapshot: **2026-05-31T00:06Z** (6 OK, 12 error, 0 desabilitados)

|| Métrica | 14:34Z | 00:06Z | Delta |
|:--|:--:|:--:|:--:||
| Total crons | 18 | 18 | 0 |
| Habilitados | 18 | 18 | 0 |
| Errors | 2 | 12 | **+10** 🔴 |
| OK | 15 | 6 | **-9** 🔴 |

**Mudanças desde snapshot anterior:**
- 🔴 **10 crons regrediram de OK → ERROR** — todos com HTTP 429 rate limit
- Erro compartilhado: `RuntimeError: HTTP 429: Rate limit exceeded: free-models-per-day-stealth`
- **Diagnóstico:** Limite diário de modelos gratuitos do OpenRouter esgotado
- **Ação tomada:** Nenhuma — `run` em cada cron resultaria no mesmo 429
- **Previsão:** Auto-recuperação quando o limite diário for resetado

## Crons OK (6)

|| Job ID | Nome | Schedule | Last run | Idade | Status | Observação |
|---|---|---|---|---|---|---|
| `757eefb8738b` | manaloom-master-watchdog | every 30m | 2026-05-30T23:54Z | 12min | 🟢 ok | script-based |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | 0 12 * * 0 | 2026-05-30T14:30Z | ~10h | 🟢 ok | semanal |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | every 1440m | 2026-05-30T14:42Z | ~9h | 🟢 ok | diário |
| `a50bef4c2a59` | lorehold-evolution-oracle | every 720m | 2026-05-30T16:11Z | ~8h | 🟢 ok | 12h schedule |
| `94f8590b1beb` | lorehold-battle-analyst | every 480m | 2026-05-30T16:47Z | ~7h | 🟢 ok | 8h schedule |
| `2d436c71bbf7` | manaloom-manager-watchdog | every 30m | 2026-05-30T23:34Z | 32min | 🟢 ok | **esta execução** |

## Crons com Erro HTTP 429 (12) — Falha Sistêmica

Todos os erros abaixo compartilham a mesma causa raiz: `RuntimeError: HTTP 429: Rate limit exceeded: free-models-per-day-stealth`.

### Crons de Auditoria / Gerenciais com Erro

|| Job ID | Nome | Schedule | Last run | Último erro |
|---|---|---|---|---|
| `660397bb97e1` | manaloom-hermes-normal-audit | 0 16,21 * * * | 2026-05-30T21:00Z | 429 |
| `577a0a669714` | manaloom-code-structure-auditor (weekly) | 0 6 * * 0 | 2026-05-30T16:56Z | 429 |
| `bb03201b8911` | manaloom-code-structure-auditor (3h) | every 180m | 2026-05-30T22:58Z | 429 |
| `de6fb777f5d1` | manaloom-logic-coherence-auditor | every 120m | 2026-05-30T22:35Z | 429 |
| `10a59b3bdf4d` | manaloom-knowledge-synthesis | every 120m | 2026-05-30T22:48Z | 429 |

### Crons de Conhecimento Commander com Erro

|| Job ID | Nome | Schedule | Last run | Último erro |
|---|---|---|---|---|
| `75eed994c103` | manaloom-commander-knowledge-deep | every 240m | 2026-05-30T22:33Z | 429 |
| `7915cc2377a0` | manaloom-gamechanger-research | every 120m | 2026-05-30T23:00Z | 429 |
| `444aa9510c2c` | manaloom-mana-base-validator | every 360m | 2026-05-30T20:50Z | 429 |
| `b2f5c21ce2d7` | manaloom-knowledge-import | every 120m | 2026-05-30T22:59Z | 429 |

### Lorehold Pipeline com Erro

|| Job ID | Nome | Schedule | Last run | Último erro |
|---|---|---|---|---|
| `f20ac299992b` | lorehold-deck-scout | every 120m | 2026-05-30T23:29Z | 429 |
| `712579b15767` | lorehold-deck-validator | every 180m | 2026-05-30T21:39Z | 429 |
| `08468451a06a` | lorehold-mulligan-analyst | every 360m | 2026-05-30T21:53Z | 429 |

## Análise de Erro Sistêmico

**Causa raiz:** `HTTP 429: Rate limit exceeded: free-models-per-day-stealth`
**Provider:** OpenRouter (free-tier shared pool)
**Afetados:** 12/18 crons (todos os crons com schedules ≤360m que tentaram rodar após ~21:00Z)

**Por que nenhum `run` foi disparado:**
- `cronjob(action='run')` apenas reschedula o next_run_at; Não executa sincronamente
- Todos os 12 crons compartilham o mesmo provider/model (`openrouter/owl-alpha`)
- Disparar `run` em cada cron resultaria no mesmo erro 429
- Esta é uma falha de dependência compartilhada, não 12 bugs independentes

**Recuperação esperada:**
- O limite diário do OpenRouter free-tier tipicamente reseta em janela de 24h
- Na próxima execução do manager-watchdog após reset, os crons voltarão a executar normalmente
- Se os crons estiverem com `last_status=error` mas o scheduler tick processá-los com sucesso, o status atualizará automaticamente para `ok`

## Ações Realizadas Neste Cycle (2026-05-31T00:06Z)

|| Ação | Cron | Resultado |
|:-----|:------|:----------|
| — | Nenhuma (systemic 429) | Todos os 12 em erro | `run` não resolveria — aguardando reset do rate limit |

**Nota:** Em falhas sistêmicas de provider, disparar `run` em cada cron desperdiça chamadas que também resultariam em 429. A recuperação é automática quando o rate limit reseta.

## Alertas Pendentes

**🔴 P1 — 12 crons com HTTP 429 (rate limit esgotado):**
- **Sintoma:** Todos os crons `openrouter/owl-alpha` com schedules curtos falhando com 429
- **Impacto:** Nenhum conhecimento/decks/audits estão sendo produzidos desde ~21:00Z
- **Recuperação:** Automática quando o rate limit diário do OpenRouter free-tier resetar
- **Ação do watchdog:** Aguardar próximo tick e re-verificar. Se o 429 persistir por >24h, considerar migrar para modelo pago ou alternativo
- **CRON_STATUS.md:** Será atualizado no próximo cycle do manager-watchdog com o status pós-reset

## Mudanças desde Snapshot Anterior (14:34Z → 00:06Z)

### Crons que Regrediram (OK → ERROR, todos 429)

| Cron | 14:34Z | 00:06Z |
|:-----|:--------|:--------|
| manaloom-hermes-normal-audit | 🟢 ok | 🔴 429 |
| manaloom-commander-knowledge-deep | 🟢 ok | 🔴 429 |
| manaloom-gamechanger-research | 🟢 ok | 🔴 429 |
| manaloom-mana-base-validator | 🟢 ok | 🔴 429 |
| lorehold-deck-scout | 🟢 ok | 🔴 429 |
| lorehold-deck-validator | 🟢 ok | 🔴 429 |
| lorehold-mulligan-analyst | 🟢 ok | 🔴 429 |
| manaloom-knowledge-import | 🟢 ok | 🔴 429 |
| manaloom-code-structure-auditor (3h) | 🟢 ok | 🔴 429 |
| manaloom-logic-coherence-auditor | 🟢 ok | 🔴 429 |
| manaloom-code-structure-auditor (weekly) | 🔴 error (502) | 🔴 429 |
| manaloom-knowledge-synthesis | 🔴 error (empty) | 🔴 429 |

### Crons Estáveis (sem mudança)

| Cron | Status |
|:-----|:--------|
| manaloom-manager-watchdog | 🟢 ok |
| manaloom-master-watchdog | 🟢 ok |
| manaloom-hermes-weekly-parallel-audit | 🟢 ok |
| manaloom-tag-accuracy-reporter | 🟢 ok |
| lorehold-evolution-oracle | 🟢 ok |
| lorehold-battle-analyst | 🟢 ok |

## Observações Importantes

- **Fleet: 18 crons** (sem mudança)
- **12 crons afetados por 429** — maior falha sistêmica registrada
- **6 crons ainda funcionando:** São os que rodaram antes do rate limit esgotar e têm schedules longos (360m-1440m)
- **Nenhum cron foi desabilitado** — recuperação será automática

---

## Mana Base Validation Report (manaloom-mana-base-validator)

> Última atualização: **2026-05-30T14:47Z** (antes do 429)

**Decks analisados:** 8
**Critérios:** Lands vs perfil EDHREC, Ramp/Draw/Remoção vs ranges do perfil

### Resumo Geral

|| # | Deck | Total Cards | Status | Lands SQLite | Lands Perfil | Observação |
|---|---|------|:-----------:|:------:|:------------:|:------------:|------------|
| 1 | Kinnan, Bonder Prodigy | 13/100 | ⚪ INCOMPLETE | 0 | 29-34 | Apenas 13/100 cartas inseridas |
| 2 | EDHREC Average - Dimir Ninja Topdeck Tempo | 99/100 | 🟡 WARN | 35 | 30-34 | 99/100 cards (1 short); Lands 35 vs 30-34 |
| 3 | EDHREC Average Default (Korvold) | 11/100 | ⚪ INCOMPLETE | 0 | 34-37 | Apenas 11/100 cartas inseridas |
| 4 | EDHREC Average Default (Teysa) | 80/100 | 🔴 CRIT | 15 | 35-37 | Teysa: 80 cards, lands=15 (perfil 35-37), ramp CRIT |
| 5 | Aesi EDHREC Average Default | 100/100 | 🟡 WARN | 40 | 39-43 | protection: DB=7 vs perfil [2-4] |
| 6 | Lorehold Spellslinger | 100/100 | ✅ OK | 35 | — | Sem perfil de referência |
| 7 | EDHREC Average - Boros Combat Trigger Humans | 100/100 | 🟡 WARN | 34 | 31-35 | protection: DB=10 vs perfil [5-8] |
| 9 | Atraxa EDHREC Average (41k decks) | 100/100 | ✅ OK | 36 | 35-38 | Dentro do perfil |

*Legenda: ✅ OK | 🟡 WARN (d=2-3) | 🔴 CRIT (d≥4) | ⚪ INCOMPLETE (<50 cards)*

---

## Precisão das Functional Tags (manaloom-tag-accuracy-reporter)

> Última atualização: **2026-05-30T14:42Z**

### Resumo Geral

|| Métrica | Valor ||
|:--------|:-----:||
| **Precisão total** | **83.3%** (378/454 classificações corretas) ||
| Tags avaliadas | 29 ||
| Tags com 100% | 14 ||
| Tags com < 50% | 7 ||

### Tags com Precisão 100% (14)

`land` (87/87), `ramp` (53/53), `draw` (32/32), `removal` (30/30), `tutor` (6/6), `board_wipe` (3/3), `recursion` (3/3), `wipe` (1/1), `sacrifice_outlet` (1/1), `finisher` (2/2), `utility` (76/76), `creature` (22/22), `planeswalker` (2/2), `artifact` (2/2), `enchantment` (3/3)

### Tags com Precisão < 50% (7)

|| Tag | Precisão | Amostra | Problema |
|:----|:--------:|:-------:|:---------|
| `ninja` | 0.0% | 17/17 erradas | Tag muito específica — classificador não reconhece ninja como função |
| `ramp + combo_piece` | 0.0% | 1/1 errada | Tag composta rara — amostra insuficiente |
| `recursion + wincon` | 0.0% | 1/1 errada | Tag composta rara — amostra insuficiente |
| `ramp + payoff` | 0.0% | 1/1 errada | Tag composta rara — amostra insuficiente |
| `payoff + removal` | 0.0% | 1/1 errada | Tag composta rara — amostra insuficiente |
| `payoff + token_maker` | 0.0% | 1/1 errada | Tag composta rara — amostra insuficiente |
| `stax_disruption` | 0.0% | 3/3 erradas | Classificador não possui categoria stax |

### Tags com Precisão 50-75% (8)

|| Tag | Precisão | Amostra |
|:----|:--------:|:-------:|
| `payoff` | 35.5% | 11/31 |
| `combo_piece` | 50.0% | 1/2 |
| `enabler` | 50.0% | 21/42 |
| `other` | 50.0% | 1/2 |
| `protection` | 69.2% | 9/13 |
| `wincon` | 75.0% | 6/8 |
| `engine` | 75.0% | 6/8 |

### Análise

**Pontos fortes:** Tags estruturais (`land`, `creature`, `artifact`, `enchantments`) e funções primárias (`ramp`, `draw`, `removal`, `tutor`) têm precisão perfeita.

**Pontos fracos:**
1. **Tags compostas** têm amostra mínima (1 caso cada) e 0% de precisão
2. **`stax_disruption` (0/3):** Classificador não possui categoria dedicada para stax
3. **`ninja` (0/17):** Tag muito específica de tribo — classificador funcional não captura tribos
4. **`payoff` (35.5%):** Tag ambígua — classificador confunde payoff com wincon ou engine
5. **`enabler` (50.0%):** Fronteira difícil — distinção entre enabler e engine é sutil

---

*Status snapshot: 2026-05-31T00:06Z | Branch: codex/hermes-analysis-docs | Fleet: 18 crons (18 enabled, 6 ok, 12 error — systemic 429)*
