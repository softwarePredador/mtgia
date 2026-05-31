# ManaLoom Cron Status

> Relat�rio gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> �ltima atualiza��o: **2026-05-31T01:32Z** (manaloom-manager-watchdog)

## Resumo

|| M�trica | Valor ||
|:--|:--:||
| Total de crons (`include_disabled=True`) | **18** ||
| Habilitados | 18/18 ||
| Desabilitados | **0** ||
| `last_status=error` | **8** ||
| `last_status=ok` | **10** ||
| Nunca executaram (`last_run_at=null`) | **0** ||
| Stale (>1.5x schedule atr�s, `enabled=true`) | **0** |
| A��es de recupera��o nesta execu��o | 0 (rate limit parcialmente lifting -- auto-recupera��o em progresso) |
| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** 18 crons habilitados, **10 OK**, **8 com erro**. -- **MELHORA:** Rate limit do OpenRouter parcialmente recuperado. 4 crons voltaram de error para ok desde snapshot anterior. Erros restantes ainda podem ser 429 residuais -- aguardando pr�ximos ticks.

## An�lise de Recupera��o

Snapshot anterior: **2026-05-31T00:53Z** (6 OK, 12 error, 0 desabilitados)
Este snapshot: **2026-05-31T01:32Z** (10 OK, 8 error, 0 desabilitados)

|| M�trica | 00:53Z | 01:32Z | Delta |
|:--|:--:|:--:|:--:|:--:||
| Total crons | 18 | 18 | 0 |
| Habilitados | 18 | 18 | 0 |
| Errors | 12 | 8 | **-4** |
| OK | 6 | 10 | **+4** |

**Mudan�as desde snapshot anterior:**
- **4 crons recuperados (error → ok):**
  - `manaloom-gamechanger-research` — rodou OK �s 01:20Z
  - `lorehold-deck-validator` — rodou OK �s 01:08Z
  - `manaloom-knowledge-import` — rodou OK �s 01:31Z
  - `manaloom-knowledge-synthesis` — rodou OK �s 01:16Z
- **Diagn�stico:** Rate limit parcialmente recuperado -- crons come�am a passar
- **A��o tomada:** Nenhuma -- recupera��o autom�tica pelo scheduler
- **Previs�o:** Demais crons devem recuperar nos pr�ximos ticks

## Crons OK (10)

|| Job ID | Nome | Schedule | Last run | Idade | Status | Observa��o |
|---|---|---|---|---|---|---|
| `757eefb8738b` | manaloom-master-watchdog | every 30m | 2026-05-31T00:24Z | 67min | ok | script-based |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | 0 12 * * 0 | 2026-05-30T14:30Z | ~11h | ok | semanal |
| `7915cc2377a0` | manaloom-gamechanger-research | every 120m | 2026-05-31T01:20Z | 11min | ok | ✅ recuperado de 429 |
| `2d436c71bbf7` | manaloom-manager-watchdog | every 30m | 2026-05-31T00:58Z | 33min | ok | **esta execu��o** |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | every 1440m | 2026-05-30T14:42Z | ~11h | ok | di�rio |
| `712579b15767` | lorehold-deck-validator | every 180m | 2026-05-31T01:08Z | 23min | ok | ✅ recuperado de 429 |
| `a50bef4c2a59` | lorehold-evolution-oracle | every 720m | 2026-05-30T16:11Z | ~9h | ok | 12h schedule |
| `b2f5c21ce2d7` | manaloom-knowledge-import | every 120m | 2026-05-31T01:31Z | 0min | ok | ✅ recuperado de 429 (agora!) |
| `10a59b3bdf4d` | manaloom-knowledge-synthesis | every 120m | 2026-05-31T01:16Z | 15min | ok | ✅ recuperado de 429 |
| `94f8590b1beb` | lorehold-battle-analyst | every 480m | 2026-05-31T01:18Z | 13min | ok | 8h schedule |

## Crons com Erro (8) -- Rate Limit Residual

Todos os erros abaixo s�o provavelmente res�duos do rate limit `HTTP 429: Rate limit exceeded: free-models-per-day-stealth` que est� se recuperando.

### Crons de Auditoria / Gerenciais com Erro

|| Job ID | Nome | Schedule | Last run | �ltimo erro |
|---|---|---|---|---|
| `660397bb97e1` | manaloom-hermes-normal-audit | 0 16,21 * * * | 2026-05-30T21:00Z | 429 -- pr�ximo tick: 16:00Z |
| `577a0a669714` | manaloom-code-structure-auditor (weekly) | 0 6 * * 0 | 2026-05-30T16:56Z | 429 -- pr�ximo tick: domingo 06:00Z |
| `bb03201b8911` | manaloom-code-structure-auditor (3h) | every 180m | 2026-05-30T22:58Z | 429 -- pr�ximo tick: ~01:58Z |
| `de6fb777f5d1` | manaloom-logic-coherence-auditor | every 120m | 2026-05-31T00:52Z | 429 -- pr�ximo tick: ~02:52Z |

### Crons de Conhecimento Commander com Erro

|| Job ID | Nome | Schedule | Last run | �ltimo erro |
|---|---|---|---|---|
| `75eed994c103` | manaloom-commander-knowledge-deep | every 240m | 2026-05-30T22:33Z | 429 -- pr�ximo tick: ~02:33Z |
| `444aa9510c2c` | manaloom-mana-base-validator | every 360m | 2026-05-30T20:50Z | 429 -- pr�ximo tick: ~02:50Z |

### Lorehold Pipeline com Erro

|| Job ID | Nome | Schedule | Last run | �ltimo erro |
|---|---|---|---|---|
| `f20ac299992b` | lorehold-deck-scout | every 120m | 2026-05-30T23:29Z | 429 -- pr�ximo tick: ~01:29Z |
| `08468451a06a` | lorehold-mulligan-analyst | every 360m | 2026-05-30T21:53Z | 429 -- pr�ximo tick: ~01:53Z |

## An�lise de Erro

**Causa raiz:** `HTTP 429: Rate limit exceeded: free-models-per-day-stealth` (parcialmente recuperado)
**Provider:** OpenRouter (free-tier shared pool)
**Afetados:** 8/18 crons (redu��o de 12 para 8 -- melhora de 33%)
**Dura��o total do incidente:** ~6.5h (desde ~21:00Z 30/05)
**Status:** **RECUPERA��O EM ANDAMENTO** -- 4 crons j� voltaram a ok

**Por que nenhum `run` foi disparado:**
- Com 4 crons j� recuperados, o rate limit est� claramente lifting
- Disparar `run` em crons que est�o prestes a rodar naturalmente desperdi�a chamadas
- Os pr�ximos ticks naturais devem processar os 8 crons restantes sem interven��o

**Recupera��o esperada:**
- Os 8 crons restantes devem auto-recuperar nos pr�ximos 30-60min conforme o scheduler tick
- Se algum cron ainda estiver em erro ap�s 2-3 ticks naturais, pode indicar problema estrutural

## A��es Realizadas Neste Cycle (2026-05-31T01:32Z)

|| A��o | Cron | Resultado |
|:-----|:------|:----------|
| -- | Nenhuma (auto-recupera��o em progresso) | 4 crons recuperados naturalmente | Aguardando pr�ximos ticks para os 8 restantes |

## Alertas Pendentes

**P1 -- 8 crons ainda com HTTP 429 (rate limit residual, melhorando):**
- **Sintoma:** Crons `openrouter/owl-alpha` com schedules curtos ainda falhando com 429
- **Impacto:** Produ��o de conhecimento/audits parcialmente reduzida
- **Tend�ncia:** MELHORA -- de 12 para 8 erros em 39min
- **Recupera��o:** Autom�tica conforme scheduler tick
- **A��o do watchdog:** Monitorar pr�ximo tick. Se os 8 crons restantes n�o recuperarem em 60min, investigar individualmente

## Mudan�as desde Snapshot Anterior (00:53Z -> 01:32Z)

### Crons que Recuperaram (ERROR → OK) -- 4

|| Cron | Schedule | Recuperou em |
|:-----|:--------|:-----------|
| manaloom-gamechanger-research | every 120m | 2026-05-31T01:20Z |
| lorehold-deck-validator | every 180m | 2026-05-31T01:08Z |
| manaloom-knowledge-import | every 120m | 2026-05-31T01:31Z |
| manaloom-knowledge-synthesis | every 120m | 2026-05-31T01:16Z |

### Crons que Regrediram (OK → ERROR)
*(nenhum)*

### Crons Est�veis

|| Cron | Status |
|:-----|:--------|
| manaloom-manager-watchdog | ok |
| manaloom-master-watchdog | ok |
| manaloom-hermes-weekly-parallel-audit | ok |
| manaloom-tag-accuracy-reporter | ok |
| lorehold-evolution-oracle | ok |
| lorehold-battle-analyst | ok |
| manaloom-hermes-normal-audit | 429 |
| manaloom-commander-knowledge-deep | 429 |
| manaloom-mana-base-validator | 429 |
| lorehold-deck-scout | 429 |
| lorehold-mulligan-analyst | 429 |
| manaloom-code-structure-auditor (weekly) | 429 |
| manaloom-code-structure-auditor (3h) | 429 |
| manaloom-logic-coherence-auditor | 429 |

## Observa��es Importantes

- **Fleet: 18 crons** (sem mudan�a)
- **8 crons ainda em erro** -- redu��o de 12→8 (33% de melhora)
- **Rate limit parcialmente recuperado** -- tend�ncia positiva
- **Nenhum cron foi desabilitado** -- recupera��o ser� autom�tica
- **Nenhum `run` ou `resume` necess�rio** -- scheduler natural processando

---

## Mana Base Validation Report (manaloom-mana-base-validator)

> �ltima atualiza��o: **2026-05-30T14:47Z** (antes do 429)

**Decks analisados:** 8
**Crit�rios:** Lands vs perfil EDHREC, Ramp/Draw/Remo��o vs ranges do perfil

### Resumo Geral

|| # | Deck | Total Cards | Status | Lands SQLite | Lands Perfil | Observa��o |
|---|---|------|:-----------:|:------:|:------------:|:------------:|------------|
| 1 | Kinnan, Bonder Prodigy | 13/100 | INCOMPLETE | 0 | 29-34 | Apenas 13/100 cartas inseridas |
| 2 | EDHREC Average - Dimir Ninja Topdeck Tempo | 99/100 | WARN | 35 | 30-34 | 99/100 cards (1 short); Lands 35 vs 30-34 |
| 3 | EDHREC Average Default (Korvold) | 11/100 | INCOMPLETE | 0 | 34-37 | Apenas 11/100 cartas inseridas |
| 4 | EDHREC Average Default (Teysa) | 80/100 | CRIT | 15 | 35-37 | Teysa: 80 cards, lands=15 (perfil 35-37), ramp CRIT |
| 5 | Aesi EDHREC Average Default | 100/100 | WARN | 40 | 39-43 | protection: DB=7 vs perfil [2-4] |
| 6 | Lorehold Spellslinger | 100/100 | OK | 35 | -- | Sem perfil de refer�ncia |
| 7 | EDHREC Average - Boros Combat Trigger Humans | 100/100 | WARN | 34 | 31-35 | protection: DB=10 vs perfil [5-8] |
| 9 | Atraxa EDHREC Average (41k decks) | 100/100 | OK | 36 | 35-38 | Dentro do perfil |

*Legenda: OK | WARN (d=2-3) | CRIT (d>=4) | INCOMPLETE (<50 cards)*

---

## Precis�o das Functional Tags (manaloom-tag-accuracy-reporter)

> �ltima atualiza��o: **2026-05-30T14:42Z**

### Resumo Geral

|| M�trica | Valor ||
|:--------|:-----:||
| **Precis�o total** | **83.3%** (378/454 classifica��es corretas) ||
| Tags avaliadas | 29 ||
| Tags com 100% | 14 ||
| Tags com < 50% | 7 |

### Tags com Precis�o 100% (14)

`land` (87/87), `ramp` (53/53), `draw` (32/32), `removal` (30/30), `tutor` (6/6), `board_wipe` (3/3), `recursion` (3/3), `wipe` (1/1), `sacrifice_outlet` (1/1), `finisher` (2/2), `utility` (76/76), `creature` (22/22), `planeswalker` (2/2), `artifact` (2/2), `enchantment` (3/3)

### Tags com Precis�o < 50% (7)

|| Tag | Precis�o | Amostra | Problema |
|:----|:--------:|:-------:|:---------|
| `ninja` | 0.0% | 17/17 erradas | Tag muito espec�fica -- classificador n�o reconhece ninja como fun��o |
| `ramp + combo_piece` | 0.0% | 1/1 errada | Tag composta rara -- amostra insuficiente |
| `recursion + wincon` | 0.0% | 1/1 errada | Tag composta rara -- amostra insuficiente |
| `ramp + payoff` | 0.0% | 1/1 errada | Tag composta rara -- amostra insuficiente |
| `payoff + removal` | 0.0% | 1/1 errada | Tag composta rara -- amostra insuficiente |
| `payoff + token_maker` | 0.0% | 1/1 errada | Tag composta rara -- amostra insuficiente |
| `stax_disruption` | 0.0% | 3/3 erradas | Classificador n�o possui categoria stax |

### Tags com Precis�o 50-75% (8)

|| Tag | Precis�o | Amostra |
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

*Status snapshot: 2026-05-31T01:32Z | Branch: codex/hermes-analysis-docs | Fleet: 18 crons (18 enabled, 10 ok, 8 error -- rate limit parcialmente recuperado, tend�ncia positiva)*
