# ManaLoom Cron Status

> Relat�rio gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> �ltima atualiza��o: **2026-05-31T00:53Z** (manaloom-manager-watchdog)

## Resumo

|| M�trica | Valor ||
|:--|:--:||
| Total de crons (`include_disabled=True`) | **18** ||
| Habilitados | 18/18 ||
| Desabilitados | **0** ||
| `last_status=error` | **12** ||
| `last_status=ok` | **6** ||
| Nunca executaram (`last_run_at=null`) | **0** ||
| Stale (>1.5x schedule atr�s, `enabled=true`) | **0** ||
| A��es de recupera��o nesta execu��o | 0 (systemic 429 -- run n�o resolve) |
| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** 18 crons habilitados, **6 OK**, **12 com erro**. -- **FALHA SIST�MICA CONT�NUA:** Todos os 12 erros s�o `HTTP 429: Rate limit exceeded: free-models-per-day-stealth`. Nenhuma a��o por-cron resolver� -- o limite di�rio do provider continua esgotado.

## An�lise de Recupera��o

Snapshot anterior: **2026-05-31T00:06Z** (6 OK, 12 error, 0 desabilitados)
Este snapshot: **2026-05-31T00:53Z** (6 OK, 12 error, 0 desabilitados)

|| M�trica | 00:06Z | 00:53Z | Delta |
|:--|:--:|:--:|:--:||
| Total crons | 18 | 18 | 0 |
| Habilitados | 18 | 18 | 0 |
| Errors | 12 | 12 | 0 |
| OK | 6 | 6 | 0 |

**Mudan�as desde snapshot anterior:**
- **Nenhuma mudan�a** -- mesmos 6 OK, mesmos 12 em erro
- 429 persistente: `manaloom-logic-coherence-auditor` rodou aos 00:52Z (1min atr�s) e j� errou com 429 -- confirma rate limit ainda ativo
- **Diagn�stico:** Limite di�rio de modelos gratuitos do OpenRouter continua esgotado
- **A��o tomada:** Nenhuma -- `run` em cada cron resultaria no mesmo 429
- **Previs�o:** Auto-recupera��o quando o limite di�rio for resetado

## Crons OK (6)

|| Job ID | Nome | Schedule | Last run | Idade | Status | Observa��o |
|---|---|---|---|---|---|---|
| `757eefb8738b` | manaloom-master-watchdog | every 30m | 2026-05-31T00:24Z | 29min | ok | script-based |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | 0 12 * * 0 | 2026-05-30T14:30Z | ~10h | ok | semanal |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | every 1440m | 2026-05-30T14:42Z | ~10h | ok | di�rio |
| `a50bef4c2a59` | lorehold-evolution-oracle | every 720m | 2026-05-30T16:11Z | ~9h | ok | 12h schedule |
| `94f8590b1beb` | lorehold-battle-analyst | every 480m | 2026-05-30T16:47Z | ~8h | ok | 8h schedule |
| `2d436c71bbf7` | manaloom-manager-watchdog | every 30m | 2026-05-31T00:13Z | 40min | ok | **esta execu��o** |

## Crons com Erro HTTP 429 (12) -- Falha Sist�mica

Todos os erros abaixo compartilham a mesma causa raiz: `RuntimeError: HTTP 429: Rate limit exceeded: free-models-per-day-stealth`.

### Crons de Auditoria / Gerenciais com Erro

|| Job ID | Nome | Schedule | Last run | �ltimo erro |
|---|---|---|---|---|
| `660397bb97e1` | manaloom-hermes-normal-audit | 0 16,21 * * * | 2026-05-30T21:00Z | 429 |
| `577a0a669714` | manaloom-code-structure-auditor (weekly) | 0 6 * * 0 | 2026-05-30T16:56Z | 429 |
| `bb03201b8911` | manaloom-code-structure-auditor (3h) | every 180m | 2026-05-30T22:58Z | 429 |
| `de6fb777f5d1` | manaloom-logic-coherence-auditor | every 120m | 2026-05-31T00:52Z | 429 (acabou de rodar e falhar) |
| `10a59b3bdf4d` | manaloom-knowledge-synthesis | every 120m | 2026-05-30T22:48Z | 429 |

### Crons de Conhecimento Commander com Erro

|| Job ID | Nome | Schedule | Last run | �ltimo erro |
|---|---|---|---|---|
| `75eed994c103` | manaloom-commander-knowledge-deep | every 240m | 2026-05-30T22:33Z | 429 |
| `7915cc2377a0` | manaloom-gamechanger-research | every 120m | 2026-05-30T23:00Z | 429 |
| `444aa9510c2c` | manaloom-mana-base-validator | every 360m | 2026-05-30T20:50Z | 429 |
| `b2f5c21ce2d7` | manaloom-knowledge-import | every 120m | 2026-05-30T22:59Z | 429 |

### Lorehold Pipeline com Erro

|| Job ID | Nome | Schedule | Last run | �ltimo erro |
|---|---|---|---|---|
| `f20ac299992b` | lorehold-deck-scout | every 120m | 2026-05-30T23:29Z | 429 |
| `712579b15767` | lorehold-deck-validator | every 180m | 2026-05-30T21:39Z | 429 |
| `08468451a06a` | lorehold-mulligan-analyst | every 360m | 2026-05-30T21:53Z | 429 |

## An�lise de Erro Sist�mico

**Causa raiz:** `HTTP 429: Rate limit exceeded: free-models-per-day-stealth`
**Provider:** OpenRouter (free-tier shared pool)
**Afetados:** 12/18 crons (todos os crons com schedules <=360m que tentaram rodar ap�s ~21:00Z de 30/05)
**Dura��o:** ~4 horas de rate limit cont�nuo (desde ~21:00Z 30/05 at� 00:53Z 31/05)

**Por que nenhum `run` foi disparado:**
- `cronjob(action='run')` apenas reschedula o next_run_at; N�o executa sincronamente
- Todos os 12 crons compartilham o mesmo provider/model (`openrouter/owl-alpha`)
- Disparar `run` em cada cron resultaria no mesmo erro 429
- Esta � uma falha de depend�ncia compartilhada, n�o 12 bugs independentes
- **Nota:** `manaloom-logic-coherence-auditor` rodou h� 1 minuto (00:52Z) e j� falhou -- confirma 429 ativo AGORA

**Recupera��o esperada:**
- O limite di�rio do OpenRouter free-tier tipicamente reseta em janela de 24h
- Na pr�xima execu��o do manager-watchdog ap�s reset, os crons voltar�o a executar normalmente
- Se os crons estiverem com `last_status=error` mas o scheduler tick process�-los com sucesso, o status atualizar� automaticamente para `ok`
- **Se o 429 persistir por >24h, considerar migrar para modelo pago ou alternativo**

## A��es Realizadas Neste Cycle (2026-05-31T00:53Z)

|| A��o | Cron | Resultado |
|:-----|:------|:----------|
| -- | Nenhuma (systemic 429) | Todos os 12 em erro | `run` n�o resolveria -- aguardando reset do rate limit |

**Nota:** Em falhas sist�micas de provider, disparar `run` em cada cron desperdi�a chamadas que tamb�m resultariam em 429. A recupera��o � autom�tica quando o rate limit reseta.

## Alertas Pendentes

**P1 -- 12 crons com HTTP 429 (rate limit esgotado):**
- **Sintoma:** Todos os crons `openrouter/owl-alpha` com schedules curtos falhando com 429
- **Impacto:** Nenhum conhecimento/decks/audits est�o sendo produzidos desde ~21:00Z (30/05)
- **Dura��o:** ~4h de rate limit cont�nuo
- **Recupera��o:** Autom�tica quando o limite di�rio do OpenRouter free-tier resetar
- **A��o do watchdog:** Aguardar pr�ximo tick e re-verificar. Se o 429 persistir por >24h, considerar migrar para modelo pago ou alternativo

## Mudan�as desde Snapshot Anterior (00:06Z -> 00:53Z)

### Crons que Regrediram (OK -> ERROR)
*(nenhum -- est�vel)*

### Crons que Recuperaram (ERROR -> OK)
*(nenhum -- est�vel)*

### Crons Est�veis (sem mudan�a)

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
| manaloom-gamechanger-research | 429 |
| manaloom-mana-base-validator | 429 |
| lorehold-deck-scout | 429 |
| lorehold-deck-validator | 429 |
| lorehold-mulligan-analyst | 429 |
| manaloom-knowledge-import | 429 |
| manaloom-code-structure-auditor (weekly) | 429 |
| manaloom-code-structure-auditor (3h) | 429 |
| manaloom-logic-coherence-auditor | 429 |
| manaloom-knowledge-synthesis | 429 |

## Observa��es Importantes

- **Fleet: 18 crons** (sem mudan�a)
- **12 crons afetados por 429** -- falha sist�mica cont�nua h� ~4h
- **6 crons ainda funcionando:** S�o os que rodaram antes do rate limit esgotar e t�m schedules longos (360m-1440m)
- **Nenhum cron foi desabilitado** -- recupera��o ser� autom�tica
- **manaloom-logic-coherence-auditor** �ltima execu��o h� 1min (00:52Z) -- 429 confirmado ativo neste momento

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

*Status snapshot: 2026-05-31T00:53Z | Branch: codex/hermes-analysis-docs | Fleet: 18 crons (18 enabled, 6 ok, 12 error -- systemic 429 persistente ~4h)*
