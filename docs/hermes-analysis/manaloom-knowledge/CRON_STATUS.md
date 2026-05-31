# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-31T07:13:03Z** (manaloom-manager-watchdog)

## Resumo

| Métrica | Valor |
|:--|:--:|
| Total de crons (`include_disabled=True`) | **18** |
| Habilitados | 18/18 |
| Desabilitados | **0** |
| `last_status=error` | **3** |
| `last_status=ok` | **15** |
| Nunca executaram (`last_run_at=null`) | **0** |
| Stale (>1.5x schedule atrás, `enabled=true`) | **0** |
| Ações de recuperação nesta execução | 0 (rate limit lifting -- auto-recuperação em progresso) |
| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** 18 crons habilitados, **16 OK**, **2 com erro**. Estagnação quebrada: `code-structure-auditor` (weekly) recuperou em 06:37Z. Melhora acumulada: 12→2 erros (-83%).

## Análise de Recuperação

| Snapshot | Horário | OK | Erros | Delta Erros |
|:--|:--:|:--:|:--:|:--:|
| 1 | 2026-05-31T00:53Z | 6 | 12 | — |
| 2 | 2026-05-31T01:32Z | 10 | 8 | -4 |
| 3 | 2026-05-31T02:12Z | 12 | 6 | -2 |
| 4 | 2026-05-31T02:51Z | 13 | 5 | -1 |
| 5 | 2026-05-31T03:37Z | 14 | 4 | -1 |
| 6 | 2026-05-31T04:21:01Z | **15** | **3** | **-1** |
| 7 | 2026-05-31T04:52:00Z | **15** | **3** | **0** |
| 8 | 2026-05-31T06:37Z | **16** | **2** | **-1** |

**Recuperação acumulada: 12 → 2 erros (-83%)**

**✅ Estagnação quebrada: Snapshot 8 mostra recuperação do `code-structure-auditor` (weekly).**

**Mudanças desde snapshot anterior (04:52Z → 2026-05-31T07:13:03Z):**
- **1 cron recuperado (error → ok):**
  - `manaloom-code-structure-auditor` (weekly) — rodou OK às 06:37Z
- **Diagnóstico:** Estagnação de 4 snapshots quebrada. Rate limit do OpenRouter free-tier continuando recuperação gradual
- **Ação tomada:** Nenhuma — recuperação automática pelo scheduler
- **Próximo tick relevante:** `manaloom-logic-coherence-auditor` em ~07:50Z (~59min)

**Mudanças desde snapshot anterior (03:37Z → 2026-05-31T04:21:01Z):**
- **1 cron recuperado (error → ok):**
  - `manaloom-mana-base-validator` — rodou OK às 03:12Z
- **Diagnóstico:** Rate limit continuando a recuperar gradualmente
- **Ação tomada:** Nenhuma -- recuperação automática pelo scheduler

## Crons OK (15)

| Job ID | Nome | Schedule | Last run | Status | Observação |
|---|---|---|---|---|---|
| `757eefb8738b` | manaloom-master-watchdog | every 30m | 2026-05-31T04:49Z | ok | script-based |
| `660397bb97e1` | manaloom-hermes-normal-audit | 0 16,21 * * * | 2026-05-30T21:00Z | **error** | 429 residual, next 16:00Z |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | 0 12 * * 0 | 2026-05-30T14:30Z | ok | semanal |
| `75eed994c103` | manaloom-commander-knowledge-deep | every 240m | 2026-05-31T02:47Z | ok | ✅ recuperado de 429 |
| `7915cc2377a0` | manaloom-gamechanger-research | every 120m | 2026-05-31T03:28Z | ok | ✅ recuperado de 429 |
| `2d436c71bbf7` | manaloom-manager-watchdog | every 30m | 2026-05-31T04:52Z | ok | **esta execução** |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | every 1440m | 2026-05-30T14:42Z | ok | diário |
| `444aa9510c2c` | manaloom-mana-base-validator | every 360m | 2026-05-31T03:12Z | ok | ✅ recuperado de 429 (agora!) |
| `f20ac299992b` | lorehold-deck-scout | every 120m | 2026-05-31T04:04Z | ok | ✅ recuperado de 429 |
| `712579b15767` | lorehold-deck-validator | every 180m | 2026-05-31T04:31Z | ok | ✅ recuperado de 429 |
| `08468451a06a` | lorehold-mulligan-analyst | every 360m | 2026-05-31T04:16Z | ok | ✅ recuperado de 429 |
| `a50bef4c2a59` | lorehold-evolution-oracle | every 720m | 2026-05-31T04:48Z | ok | 12h schedule |
| `b2f5c21ce2d7` | manaloom-knowledge-import | every 120m | 2026-05-31T03:55Z | ok | ✅ recuperado de 429 |
| `10a59b3bdf4d` | manaloom-knowledge-synthesis | every 120m | 2026-05-31T03:37Z | ok | ✅ recuperado de 429 |
| `94f8590b1beb` | lorehold-battle-analyst | every 480m | 2026-05-31T01:18Z | ok | 8h schedule |
| `bb03201b8911` | manaloom-code-structure-auditor (3h) | every 180m | 2026-05-31T01:59Z | ok | ✅ recuperado de 429 |

## Crons com Erro (3) -- Estagnação desde ~03:37Z

Os 3 erros abaixo estão estagnados desde ~03:37Z (sem recuperação nos últimos 3 snapshots). Provável rate limit residual do OpenRouter free-tier.

| Job ID | Nome | Schedule | Last run | Último erro | Próximo tick |
|---|---|---|---|---|---|
| `660397bb97e1` | manaloom-hermes-normal-audit | 0 16,21 * * * | 2026-05-30T21:00Z | error | 2026-05-31T16:00Z |
| `577a0a669714` | manaloom-code-structure-auditor (weekly) | 0 6 * * 0 | 2026-05-30T16:56Z | 429 | próximo domingo 06:00Z |
| `de6fb777f5d1` | manaloom-logic-coherence-auditor | every 120m | 2026-05-31T03:26Z | error | ~05:27Z |

*Nota: `manaloom-logic-coherence-auditor` marcou FAILED mas output contém audit report válido com apenas P2 findings (doc drift). Erro provavelmente de tool-call limit, não de rate limit. Próximo tick natural para validar.

## Análise de Erro

**Causa raiz:** `HTTP 429: Rate limit exceeded: free-models-per-day-stealth` (recuperando)
**Provider:** OpenRouter (free-tier shared pool)
**Afetados:** 2/18 crons (redução de 12 para 2 -- melhora de 83%)
**Duração total do incidente:** ~10h (desde ~21:00Z 30/05)
**Status:** **RECUPERANDO** -- estagnação quebrada em snapshot 8 (06:37Z): `code-structure-auditor` (weekly) recuperou

**Por que nenhum `run` foi disparado neste cycle:**
- Ambos os crons de erro têm `next_run_at` no futuro (próximos ticks pendentes)
- `manaloom-logic-coherence-auditor`: próximo tick em ~07:50Z (~59min) — cron mais frequente, próximo a rodar
- `manaloom-hermes-normal-audit`: próximo tick em 16:00Z (~9h) — cron diário com horários fixos
- Disparar `run` em crons que estão prestes a rodar naturalmente desperdiçaria chamadas e poderia agravar rate limit

**Recuperação esperada:**
- `logic-coherence-auditor` deve auto-recuperar no próximo tick (~07:50Z) — **critério de validação:** se não recuperar em 2 ticks consecutivos, investigar output
- `hermes-normal-audit` deve auto-recuperar no tick das 16:00Z
- `code-structure-auditor` (weekly) ✅ **JÁ RECUPEROU** em 06:37Z

## Ações Realizadas Neste Cycle (2026-05-31T07:13:03Z)

| Ação | Cron | Resultado |
|:-----|:------|:----------|
| -- | Nenhuma (auto-recuperação em progresso) | 1 cron recuperado naturalmente (code-structure-auditor weekly) |

## Alertas Pendentes

**P2 -- 2 crons ainda com error:**
- **Sintoma:** 2 crons `openrouter/owl-alpha` mantendo `last_status=error`
- **Impacto:** Redução temporária de auditorias e análises
- **Tendência:** MELHORA -- estagnação quebrada no snapshot 8. Próxima validação: tick do `logic-coherence-auditor` (~07:50Z)
- **Recuperação:** Automática conforme scheduler tick. `logic-coherence-auditor` é o próximo a rodar (~07:50Z)
- **Ação do watchdog:** Monitorar tick do `logic-coherence-auditor` (~07:50Z). Se não recuperar em 2 ticks consecutivos, investigar output individual. `hermes-normal-audit` (16:00Z) tem tick mais distante.

## Mudanças desde Snapshot Anterior

### Crons que Recuperaram (ERROR → OK) -- 1 neste cycle (cumulativo -7)

| Cron | Schedule | Recuperou em |
|:-----|:--------|:-----------|
| manaloom-code-structure-auditor (weekly) | 0 6 * * 0 | 2026-05-31T06:37Z |
| manaloom-mana-base-validator | every 360m | 2026-05-31T03:12Z |
| manaloom-commander-knowledge-deep | every 240m | 2026-05-31T02:47Z |

### Crons que Regrediram (OK → ERROR)
*(nenhum)*

### Outras Observações


---

## Mana Base Validation Report (manaloom-mana-base-validator)

> Última atualização: **2026-05-31T03:08Z**

**Decks analisados:** 8
**Critérios:** Lands vs perfil EDHREC, Ramp/Draw/Remoção vs ranges do perfil

### Resumo Geral

| # | Deck | Total Cards | Status | Lands SQLite | Lands Perfil | Observação |
|---|------|:-----------:|:------:|:-----------:|:------------:|------------|
| 1 | Kinnan, Bonder Prodigy | 13/100 | ⚪ INCOMPLETE | — | 29-34 | Apenas 13 cartas inseridas (seed cEDH) |
| 2 | EDHREC Average - Dimir Ninja Topdeck Tempo | 99/100 | 🟡 WARN | 35 | 30-34 | 99/100 cards (1 short); Lands BLUE(d=1); interaction BLUE(d=1) |
| 3 | EDHREC Average Default (Korvold) | 11/100 | ⚪ INCOMPLETE | — | 34-37 | Apenas 11 cartas inseridas |
| 4 | EDHREC Average Default (Teysa) | 80/100 | 🔴 CRIT* | 15 | 35-37 | *Parcial: aggregate EDHREC (80 cards). Corpus artifact, não deck real. |
| 5 | Aesi EDHREC Average Default | 100/100 | 🟡 WARN | 40 | 39-43 | Lands OK. ramp_extra_lands sub-role CRIT(d=10,INFO). protection WARN(d=3). finishers WARN(d=3) |
| 6 | Lorehold Spellslinger | 100/100 | ✅ OK | 35 | — | Sem perfil de referência EDHREC |
| 7 | EDHREC Average - Boros Combat Trigger Humans | 100/100 | 🟡 WARN | 34 | 31-35 | Lands OK. protection=10 vs 5-8 (WARN d=2) |
| 9 | Atraxa EDHREC Average (41k decks) | 100/100 | 🟡 WARN | 36 | 35-38 | Lands OK. finishers=1 vs 4-7 (WARN d=3). ramp_fixing BLUE(d=1) |

*Legenda: ✅ OK | 🟡 BLUE (d=1) | 🟡 WARN (d=2-3) | 🔴 CRIT (d>=4) | ⚪ INCOMPLETE (<50 cards)*

### Notas de Interpretação

1. **Decks INCOMPLETE (<50 cards):** Kinnan (#1) e Korvold (#3) são seeds parciais — métricas não acionáveis.
2. **Teysa CRIT*:** 80-card aggregate EDHREC, não deck real. Lands=15 vs 35-37 é corpus artifact.
3. **Sub-roles:** `ramp_extra_lands` mapeia para `ramp_count` agregado — valor INFO, não CRIT acionável.
4. **Atraxa (#9):** finishers=1 vs [4-7] (WARN d=3) — natureza "goodstuff" de Atraxa, finishers menos definidos.
5. **Tendência vs validação anterior (2026-05-30):** Sem mudanças críticas novas. WARNs estruturais dos aggregates EDHREC.
6. **Aesi (#5):** DB metadata total_cards=79 mas SUM(quantity)=100 — possível metadata stale.

---

## Precisão das Functional Tags (manaloom-tag-accuracy-reporter)

> Última atualização: **2026-05-30T14:42Z**

### Resumo Geral

| Métrica | Valor |
|:--------|:-----:|
| **Precisão total** | **83.3%** (378/454 classificações corretas) |
| Tags avaliadas | 29 |
| Tags com 100% | 14 |
| Tags com < 50% | 7 |

### Tags com Precisão 100% (14)

`land` (87/87), `ramp` (53/53), `draw` (32/32), `removal` (30/30), `tutor` (6/6), `board_wipe` (3/3), `recursion` (3/3), `wipe` (1/1), `sacrifice_outlet` (1/1), `finisher` (2/2), `utility` (76/76), `creature` (22/22), `planeswalker` (2/2), `artifact` (2/2), `enchantment` (3/3)

### Tags com Precisão < 50% (7)

| Tag | Precisão | Amostra | Problema |
|:----|:--------:|:-------:|:---------|
| `ninja` | 0.0% | 17/17 erradas | Tag muito específica -- classificador não reconhece ninja como função |
| `ramp + combo_piece` | 0.0% | 1/1 errada | Tag composta rara -- amostra insuficiente |
| `recursion + wincon` | 0.0% | 1/1 errada | Tag composta rara -- amostra insuficiente |
| `ramp + payoff` | 0.0% | 1/1 errada | Tag composta rara -- amostra insuficiente |
| `payoff + removal` | 0.0% | 1/1 errada | Tag composta rara -- amostra insuficiente |
| `payoff + token_maker` | 0.0% | 1/1 errada | Tag composta rara -- amostra insuficiente |
| `stax_disruption` | 0.0% | 3/3 erradas | Classificador não possui categoria stax |

### Tags com Precisão 50-75% (8)

| Tag | Precisão | Amostra |
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
3. **`ninja` (0/17):** Tag muito específica de tribo -- classificador funcional não captura tribos
4. **`payoff` (35.5%):** Tag ambígua -- classificador confunde payoff com wincon ou engine
5. **`enabler` (50.0%):** Fronteira difícil -- distinção entre enabler e engine é sutil |

---

*Status snapshot: 2026-05-31T07:13:03Z | Branch: codex/hermes-analysis-docs | Fleet: 18 crons (18 enabled, 16 ok, 2 error -- 12→2 erros / 83% melhora / estagnação quebrada)*

*Recuperação timeline: 00:53Z (12 erros) → 01:32Z (8 erros, -4) → 02:12Z (6 erros, -2) → 02:51Z (5 erros, -1) → 03:37Z (4 erros, -1) → 04:21Z (3 erros, -1) → 04:52Z (3 erros, 0) → 2026-05-31T07:13:03Z (2 erros, -1, estagnação quebrada) | Próxima validação: ~07:50Z (logic-coherence-auditor)*
