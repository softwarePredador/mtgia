# ManaLoom Cron Status

> Relat�rio gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-31T03:37Z** (manaloom-manager-watchdog)

## Resumo

| M�trica | Valor |
|:--|:--:|
| Total de crons (`include_disabled=True`) | **18** |
| Habilitados | 18/18 |
| Desabilitados | **0** |
| `last_status=error` | **4** |
| `last_status=ok` | **14** |
| Nunca executaram (`last_run_at=null`) | **0** |
| Stale (>1.5x schedule atr�s, `enabled=true`) | **0** |
| A��es de recupera��o nesta execu��o | 0 (rate limit lifting -- auto-recupera��o em progresso) |
| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** 18 crons habilitados, **14 OK**, **4 com erro**. Rate limit do OpenRouter continuando a recuperar: **12 → 8 → 6 → 5 → 4 erros em ~3h**.

## An�lise de Recupera��o

| Snapshot | Hor�rio | OK | Erros | Delta Erros |
|:--|:--:|:--:|:--:|:--:|
| 1 | 2026-05-31T00:53Z | 6 | 12 | — |
| 2 | 2026-05-31T01:32Z | 10 | 8 | -4 |
| 3 | 2026-05-31T02:12Z | 12 | 6 | -2 |
| 4 | 2026-05-31T03:37Z | 14 | 4 | -1 |

**Recupera��o acumulada: 12 → 5 erros (-58%)**

**Mudan�as desde snapshot anterior (02:12Z → 02:51Z):**
- **1 cron recuperado (error → ok):**
  - `manaloom-commander-knowledge-deep` — rodou OK �s 02:47Z
- **Diagn�stico:** Rate limit continuando a recuperar gradualmente
- **A��o tomada:** Nenhuma -- recupera��o autom�tica pelo scheduler
- **Previs�o:** 5 crons restantes devem recuperar nos pr�ximos ticks conforme scheduler

## Crons OK (13)

| Job ID | Nome | Schedule | Last run | Status | Observa��o |
|---|---|---|---|---|---|
| `757eefb8738b` | manaloom-master-watchdog | every 30m | 2026-05-31T01:54Z | ok | script-based |
| `f20ac299992b` | lorehold-deck-scout | every 120m | 2026-05-31T01:53Z | ok | ✅ recuperado de 429 (agora!) |
| `bb03201b8911` | manaloom-code-structure-auditor (3h) | every 180m | 2026-05-31T01:59Z | ok | ✅ recuperado de 429 (agora!) |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | 0 12 * * 0 | 2026-05-30T14:30Z | ok | semanal |
| `7915cc2377a0` | manaloom-gamechanger-research | every 120m | 2026-05-31T01:20Z | ok | ✅ recuperado de 429 |
| `2d436c71bbf7` | manaloom-manager-watchdog | every 30m | 2026-05-31T02:51Z | ok | **esta execu��o** |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | every 1440m | 2026-05-30T14:42Z | ok | di�rio |
| `712579b15767` | lorehold-deck-validator | every 180m | 2026-05-31T01:08Z | ok | ✅ recuperado de 429 |
| `a50bef4c2a59` | lorehold-evolution-oracle | every 720m | 2026-05-30T16:11Z | ok | 12h schedule |
| `b2f5c21ce2d7` | manaloom-knowledge-import | every 120m | 2026-05-31T01:31Z | ok | ✅ recuperado de 429 |
| `75eed994c103` | manaloom-commander-knowledge-deep | every 240m | 2026-05-31T02:47Z | ok | ✅ recuperado de 429 (agora!) |
| `10a59b3bdf4d` | manaloom-knowledge-synthesis | every 120m | 2026-05-31T01:16Z | ok | ✅ recuperado de 429 |
| `94f8590b1beb` | lorehold-battle-analyst | every 480m | 2026-05-31T01:18Z | ok | 8h schedule |

## Crons com Erro (4) -- Rate Limit Residual

Todos os erros abaixo s�o provavelmente res�duos do rate limit `HTTP 429: Rate limit exceeded: free-models-per-day-stealth` que est� se recuperando.

### Crons de Auditoria / Gerenciais com Erro

| Job ID | Nome | Schedule | Last run | �ltimo erro | Pr�ximo tick |
|---|---|---|---|---|---|
| `660397bb97e1` | manaloom-hermes-normal-audit | 0 16,21 * * * | 2026-05-30T21:00Z | 429 | 16:00Z |
| `577a0a669714` | manaloom-code-structure-auditor (weekly) | 0 6 * * 0 | 2026-05-30T16:56Z | 429 | domingo 06:00Z |
| `de6fb777f5d1` | manaloom-logic-coherence-auditor | every 120m | 2026-05-31T00:52Z | 429 | ~02:52Z |

### Crons de Conhecimento Commander com Erro

| Job ID | Nome | Schedule | Last run | �ltimo erro | Pr�ximo tick |
|---|---|---|---|---|---|
| `444aa9510c2c` | manaloom-mana-base-validator | every 360m | 2026-05-30T20:50Z | 429 | ~02:50Z |

### Lorehold Pipeline com Erro

| Job ID | Nome | Schedule | Last run | �ltimo erro | Pr�ximo tick |
|---|---|---|---|---|---|
| `08468451a06a` | lorehold-mulligan-analyst | every 360m | 2026-05-30T21:53Z | 429 | ~03:53Z |

## An�lise de Erro

**Causa raiz:** `HTTP 429: Rate limit exceeded: free-models-per-day-stealth` (recuperando gradualmente)
**Provider:** OpenRouter (free-tier shared pool)
**Afetados:** 5/18 crons (redu��o de 12 para 5 -- melhora de 58%)
**Dura��o total do incidente:** ~5h (desde ~21:00Z 30/05)
**Status:** **RECUPERA��O EM ANDAMENTO** -- 7 crons j� voltaram a ok desde o pico

**Por que nenhum `run` foi disparado:**
- Com 7 crons j� recuperados, o rate limit est� claramente lifting
- Todos os 5 crons de erro t�m next_run_at no futuro (pr�ximos ticks pendentes)
- Disparar `run` em crons que est�o prestes a rodar naturalmente desperdi�a chamadas

**Recupera��o esperada:**
- Os 5 crons restantes devem auto-recuperar nos pr�ximos 30-60min conforme o scheduler tick
- Se algum cron ainda estiver em erro ap�s 2-3 ticks naturais, pode indicar problema estrutural

## A��es Realizadas Neste Cycle (2026-05-31T02:51Z)

| A��o | Cron | Resultado |
|:-----|:------|:----------|
| -- | Nenhuma (auto-recupera��o em progresso) | 2 crons recuperados naturalmente | Aguardando pr�ximos ticks para os 6 restantes |

## Alertas Pendentes

**P1 -- 5 crons ainda com HTTP 429 (rate limit residual, melhorando):**
- **Sintoma:** Crons `openrouter/owl-alpha` com schedules curtos ainda falhando com 429
- **Impacto:** Produ��o de conhecimento/audits parcialmente reduzida
- **Tend�ncia:** MELHORA CONTÍNUA -- de 12 para 5 erros (58% de melhora)
- **Recupera��o:** Autom�tica conforme scheduler tick
- **A��o do watchdog:** Monitorar pr�ximo tick. Se os 5 crons restantes n�o recuperarem em 90min, investigar individualmente

## Mudan�as desde Snapshot Anterior

### Crons que Recuperaram (ERROR → OK) -- 4 (cumulativo)

| Cron | Schedule | Recuperou em |
|:-----|:--------|:-----------|
| lorehold-deck-scout | every 120m | 2026-05-31T01:53Z |
| manaloom-code-structure-auditor (3h) | every 180m | 2026-05-31T01:59Z |
| manaloom-mana-base-validator | every 360m | 2026-05-31T03:12Z |

### Crons que Regrediram (OK → ERROR)
*(nenhum)*

### Crons Est�veis

| Cron | Status |
|:-----|:--------|
| manaloom-manager-watchdog | ok |
| manaloom-master-watchdog | ok |
| manaloom-hermes-weekly-parallel-audit | ok |
| manaloom-tag-accuracy-reporter | ok |
| lorehold-evolution-oracle | ok |
| lorehold-battle-analyst | ok |
| lorehold-deck-validator | ok |
| manaloom-gamechanger-research | ok |
| manaloom-knowledge-import | ok |
| manaloom-knowledge-synthesis | ok |
| manaloom-hermes-normal-audit | 429 |
| manaloom-commander-knowledge-deep | 429 |
| manaloom-mana-base-validator | 429 |
| lorehold-mulligan-analyst | 429 |
| manaloom-code-structure-auditor (weekly) | 429 |
| manaloom-logic-coherence-auditor | 429 |

## Observa��es Importantes

- **Fleet: 18 crons** (sem mudan�a)
- **6 crons ainda em erro** -- redu��o de 12→8→6 (melhor cont�nua de 50%)
- **Rate limit em recupera��o** -- tend�ncia positiva consistente em 3 snapshots
- **Nenhum cron foi desabilitado** -- recupera��o ser� autom�tica
- **Nenhum `run` ou `resume` necess�rio** -- scheduler natural processando todos os ticks (mana-base-validator next_run_at=02:50Z, 1min em atraso, dentro da tolerância)

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

## Precis�o das Functional Tags (manaloom-tag-accuracy-reporter)

> �ltima atualiza��o: **2026-05-30T14:42Z**

### Resumo Geral

| M�trica | Valor |
|:--------|:-----:|
| **Precis�o total** | **83.3%** (378/454 classifica��es corretas) |
| Tags avaliadas | 29 |
| Tags com 100% | 14 |
| Tags com < 50% | 7 |

### Tags com Precis�o 100% (14)

`land` (87/87), `ramp` (53/53), `draw` (32/32), `removal` (30/30), `tutor` (6/6), `board_wipe` (3/3), `recursion` (3/3), `wipe` (1/1), `sacrifice_outlet` (1/1), `finisher` (2/2), `utility` (76/76), `creature` (22/22), `planeswalker` (2/2), `artifact` (2/2), `enchantment` (3/3)

### Tags com Precis�o < 50% (7)

| Tag | Precis�o | Amostra | Problema |
|:----|:--------:|:-------:|:---------|
| `ninja` | 0.0% | 17/17 erradas | Tag muito espec�fica -- classificador n�o reconhece ninja como fun��o |
| `ramp + combo_piece` | 0.0% | 1/1 errada | Tag composta rara -- amostra insuficiente |
| `recursion + wincon` | 0.0% | 1/1 errada | Tag compoda rara -- amostra insuficiente |
| `ramp + payoff` | 0.0% | 1/1 errada | Tag composta rara -- amostra insuficiente |
| `payoff + removal` | 0.0% | 1/1 errada | Tag composta rara -- amostra insuficiente |
| `payoff + token_maker` | 0.0% | 1/1 errada | Tag composta rara -- amostra insuficiente |
| `stax_disruption` | 0.0% | 3/3 erradas | Classificador n�o possui categoria stax |

### Tags com Precis�o 50-75% (8)

| Tag | Precis�o | Amostra |
|:----|:--------:|:-------:|
| `payoff` | 35.5% | 11/31 |
| `combo_piece` | 50.0% | 1/2 |
| `enabler` | 50.0% | 21/42 |
| `other` | 50.0% | 1/2 |
| `protection` | 69.2% | 9/13 |
| `wincon` | 75.0% | 6/8 |
| `engine` | 75.0% | 6/8 |

### An�lise

**Pontos fortes:** Tags estruturais (`land`, `creature`, `artifact`, `enchantments`) e fun��es prim�rias (`ramp`, `draw`, `removal`, `tutor`) t�m precis�o perfeita.

**Pontos fracos:**
1. **Tags compostas** t�m amostra m�nima (1 caso cada) e 0% de precis�o
2. **`stax_disruption` (0/3):** Classificador n�o possui categoria dedicada para stax
3. **`ninja` (0/17):** Tag muito espec�fica de tribo -- classificador funcional n�o captura tribos
4. **`payoff` (35.5%):** Tag amb�gua -- classificador confunde payoff com wincon ou engine
5. **`enabler` (50.0%):** Fronteira dif�cil -- distin��o entre enabler e engine � sutil

---

*Status snapshot: 2026-05-31T02:12Z | Branch: codex/hermes-analysis-docs | Fleet: 18 crons (18 enabled, 12 ok, 6 error -- rate limit em recupera��o, tend�ncia positiva cont�nua: 12→8→6 erros / 50% melhora)*

*Recuperação timeline: 00:53Z (12 erros) → 01:32Z (8 erros, -4) → 02:12Z (6 erros, -2) → 02:51Z (5 erros, -1) | Próxima validação: ~03:21Z*
