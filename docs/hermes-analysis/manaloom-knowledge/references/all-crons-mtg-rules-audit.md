# Auditoria Completa — Regras MTG em Todas as Crons

**Versão:** v3.6  
**Data:** 2026-06-04T12:00:00+00:00  
**Commit:** `d693b9fb`  
**Auditor:** MTG Rules Auditor v3 (cron `c0591cb18024`)  
**Escopo:** Pipeline Lorehold completo (Scout, Validator, Mulligan, Battle, Evolution Oracle)  
**Artefatos inspecionados:** `jobs.json` (prompts), outputs mais recentes de `/opt/data/cron/output/<id>/`, código fonte `battle_simulator.dart` (879 linhas)  
**Fontes de regras:** MTG Comprehensive Rules 2024-11-08, Scryfall API, CR 103 (Mulligan), CR 117.3-117.4 (Priority/Stack), CR 702.94 (Miracle), CR 903 (Commander)

---

## Sumário Executivo

| Cron | Nota | Confiabilidade | Estado Real | Gaps Críticos |
|:-----|:----:|:--------------|:------------|:---------------|
| Scout | 3.5/10 | 🔴 BAIXA | [SILENT] há +72h | Prompt é "Wincon Hunter", perdeu função original de busca EDHREC+sinergia; 94%+ taxa [SILENT] |
| Validator | 7.0/10 | 🟡 MÉDIA | v3.25 executou 2026-06-04 | Usa DB `mtgia-broken` stale (7+ dias); recomenda cartas que já saíram |
| Mulligan | 7.0/10 | 🟡 MÉDIA | [SILENT] há +72h | Não simula tapped lands nem color screw; T3 1.6% é subestimado |
| Battle | N/A | N/A | Diretório REMOVIDO | Nunca foi cron; código 2-player sem stack/priority/Commander |
| Oracle | 1.5/10 | 🔴 CRÍTICA | Script quebrado + timeout | Script `wincon_pipeline.py` não existe; Death Loop >72h; Miracle mechanic mal interpretado |
| **PIPELINE** | **3.8/10** | **🔴 BAIXA** | **Death Loop autossustentável** | 4/5 agentes [SILENT]; 0 análises novas em >72h; DB principal corrompido (0-byte ghost) |

**Tendência vs v3.5 (2026-06-04):** Pipeline score estável em 3.8/10 (+0.0). Oracle #53 executou `execute_code` — progresso de 0.5→1.5 — mas output truncado. Validator v3.25 executou com sucesso (primeira execução em 7+ dias), corrigindo erro de banlist Worldfire. Death Loop persiste. Battle directory confirmado REMOVIDO (não é cron).

---

## Cron 1: Scout (`f20ac299992b`) — 3.5/10 🔴 BAIXA

### Prompt (atual)

```text
## Lorehold Scout — Busque Wincons com Pontuacao
### SCORING DE WINCONS (card_deck_analysis):
- speed_score (1-10), resilience_score (1-10), stealth_score (1-10)
- wincon_total_score: speed + resilience + stealth (max 30)

### BUSQUE wincons na colecao que NAO estao no deck:
[SQL query card_deck_analysis JOIN user_collection]

### REGRAS DE PRIORIZACAO:
1. resilience >= 7: WINCON IMBATIVEIS
2. stealth >= 7: DANO INVISIVEL
3. speed >= 6: WINCON RAPIDA
```

### Último Output: `2026-06-04T10:12:41`

```
The deck hash (8b9c643c...) matches the last Scout execution (#38). 
The wincon pool is identical — same 4 unique collection candidates, 
all already analyzed. The deck remains supersaturated with 13 wincons.
[SILENT]
```

### O que faz CERTO
- ✅ Detecta hash inalterado e evita re-trabalho (short-circuit funciona)
- ✅ Usa `card_deck_analysis` para scoring multicamada (speed/resilience/stealth)
- ✅ Filtra por `user_collection.quantity > 0` — só recomenda cartas disponíveis
- ✅ Evita recomendar cartas já no deck (`NOT IN deck_cards`)

### O que faz ERRADO
- 🔴 **Prompt perdeu função original.** O Scout foi projetado para buscar EDHREC JSON API → cross-ref `user_collection` → Score A (Sinergia) + B (Custo) + C (Evidência). O prompt atual é um "Wincon Hunter" que só consulta `card_deck_analysis`. Isso significa que:
  - Não busca EDHREC para tendências do meta
  - Não avalia sinergia contextual (Score A+B+C)
  - Não detecta cartas novas/rising stars no EDHREC
  - Cartas com 0% EDHREC que têm sinergia óbvia NUNCA são recomendadas
- 🔴 **94%+ taxa [SILENT].** Das últimas 10+ execuções, quase todas retornaram [SILENT]. O Scout efetivamente parou de produzir análises novas.
- 🔴 **Sem verificação de color identity.** Nenhuma menção no prompt sobre filtrar cartas que violam a color identity RW do deck. `user_collection.color` existe, mas não é usado.
- 🔴 **Sem verificação de banlist.** Nenhuma menção sobre verificar legalidade Commander das cartas recomendadas.
- 🟡 **`card_deck_analysis` referencia deck_ids deletados.** Execução #37 (2026-06-02) mostrou que os scores de wincon referenciam `deck_id=16` (deletado), não o deck ativo (#6). Scores de spellslinger podem não ser válidos para o arquétipo atual (cEDH combo).
- 🟡 **Wincon misclassification.** `Trouble in Pairs` e `Perch Protection` são classificados como `role_in_deck='wincon'` com scores altos (T=16), mas são draw engine e fog/proteção respectivamente — não wincons.
- 🟡 **Ignora EDHREC 0% com alta sinergia.** Cartas como Spiteful Banditry e Xorn (0% EDHREC em Lorehold, mas sinergia óbvia com treasure) nunca aparecem porque o prompt só consulta `card_deck_analysis`.

### Recomendações
1. **Restaurar busca EDHREC JSON API** como fonte primária de dados. O Wincon Hunter pode ser um complemento, não substituto.
2. **Adicionar verificação de color identity** via `user_collection.color` com filtro `set(color.split(',')).issubset({'R','W'})`.
3. **Adicionar verificação de banlist** via `card_legalities` no SQLite (após sync).
4. **Quebrar short-circuit quando `deck_id` dos scores não corresponde ao deck ativo.**
5. **Validar `role_in_deck` contra função real da carta** antes de recomendar como wincon.

---

## Cron 2: Validator (`712579b15767`) — 7.0/10 🟡 MÉDIA

### Prompt (atual)

```text
## Lorehold Validator — PG Reference
### LOREHOLD IDEAL PROFILE (from PG commander_reference_deck_analysis):
lands: 32, ramp: 3.67, ritual_treasure: 10, big_spell_payoff: 7.67
miracle_topdeck: 4.33, interaction: 5.33, protection: 3.67
draw_value: 2.67, tutor: 3.67, win_condition: 1.33

### VALIDE o deck atual contra este perfil:
SYNERGY_MAP com 7 eixos + comparacao PG

### PG card_rulings disponivel:
Use card_oracle_data.ruling_text para explicar interacoes
```

### Último Output: `2026-06-04T11:40:54` — v3.25

Primeira execução do Validator em 7+ dias. Produziu análise completa com 409 linhas.

### O que faz CERTO
- ✅ **Detectou ARCHETYPE MISMATCH.** PG profile (cEDH/high-power, 32 lands) não corresponde ao deck atual (spellslinger Bracket 3, 35 lands). 7/15 métricas com delta >3 — corretamente atribuído a mudança estrutural, não problemas de tuning.
- ✅ **Detectou BRACKET VIOLATION.** 5 Game Changers em deck Bracket 3 (máx 3). Identificação correta.
- ✅ **6 cartas em declínio detectadas.** Rise of the Eldrazi (-0.75), Artist's Talent (-0.72), Esper Sentinel (-0.66), Seething Song (-0.59), Perch Protection (-0.59), Call Forth the Tempest (-0.57). Todos com EDHREC >15% e trend < -0.3.
- ✅ **10 double-null cards** com identificação correta de Scroll Rack e Penance como core engines (NÃO cortar).
- ✅ **SYNERGY_MAP com 7 eixos** cobrindo Token+Pump, Wipe+Proteção, Recursion, Mana Explosiva, Combo, Stack & Resilience, Card Advantage.
- ✅ **Corrigiu erro de banlist Worldfire.** v3.24 havia afirmado que Worldfire estava banida; v3.25 usou abordagem correta (não repetiu o erro).
- ✅ **5 recomendações de swap** com justificativa e ΔCMC calculado. Net ΔCMC = -2.

### O que faz ERRADO
- 🔴 **Usa DB stale (`mtgia-broken`).** O `knowledge.db` do repo principal (`mtgia`) é um ghost de 0 bytes. O validator teve que usar o repo `mtgia-broken` que está 7+ dias desatualizado. Isso significa que:
  - O deck no DB pode não ser o atual
  - Os run_logs podem estar faltando
  - Os scores de `card_deck_analysis` podem ser de um deck antigo
- 🟡 **Recomenda cartas que já saíram do deck.** Oswald Fiddlebender (cortado Ciclo #5), Desperate Ritual (cortado Ciclo #3), Goblin Engineer (cortado) são listados como "OUT" candidates — mas já foram removidos. O validator está operando sobre um deck antigo.
- 🟡 **Referencia tabela inexistente.** Prompt menciona `card_oracle_data.ruling_text` — esta tabela NÃO existe no PostgreSQL. A tabela correta é `card_rulings`.
- 🟡 **Perfil PG inaplicável.** O perfil `commander_reference_deck_analysis` do PG foi construído para um deck cEDH/high-power com 32 lands. O deck atual é spellslinger B3 com 35 lands. O validator corretamente detecta o mismatch, mas ainda assim reporta "Top 5 Swap Recommendations" baseadas em um perfil que ele mesmo declarou inaplicável.
- 🟡 **Sem verificação de banlist sistemática.** O prompt não inclui passo de sync de legalidades. A correção da Worldfire foi manual/ad-hoc, não sistemática.
- 🟡 **Stack & Resilience score 4/10** — corretamente identificou zero counterspells (limitação RW), mas o eixo deveria incluir proteção (Teferi's Protection, Boros Charm, Flare of Duplication) que está presente.

### Recomendações
1. **Corrigir o DB principal.** O `knowledge.db` no repo `mtgia` está corrompido (0 bytes). Restaurar de backup ou regenerar.
2. **Adicionar sync de legalidades** como passo obrigatório antes da validação.
3. **Validar deck state real** antes de recomendar swaps — query `deck_cards WHERE deck_id=6` e cruzar com recomendações.
4. **Corrigir nome da tabela no prompt:** `card_rulings` (não `card_oracle_data`).
5. **Quando ARCHETYPE MISMATCH** é detectado, suprimir recomendações de swap e recomendar geração de novo perfil PG.

---

## Cron 3: Mulligan (`08468451a06a`) — 7.0/10 🟡 MÉDIA

### Prompt (atual)

```text
## Agente 3: Lorehold Mulligan Tester
### PASSO 2: Simular 1000 mãos
- 7 cartas iniciais
- Jogável se: 2+ lands + 1 ramp OR 3+ lands
- Mulligan se: 0-1 lands OR 0 ramp + 2 lands
- Calcule: % sem play no T3, % ramp T1

### REGRA — London Mulligan Free First
Em Commander multiplayer, o PRIMEIRO mulligan e GRATIS (0 cartas no fundo).
bottom_count = max(0, mulligan_count - 1)
```

### Último Output: `2026-06-04T10:16:03`

```
The deck hasn't changed. DB hash 8b9c643c... matches Execução #16.
Evolution Oracle last ran 2026-06-01 — pre-dating the last mulligan.
T3 stable at 1.6%. Pipeline still in Death Loop.
[SILENT]
```

### O que faz CERTO
- ✅ **London Mulligan implementado corretamente.** Free first mulligan em Commander multiplayer: `max(0, mulligan_count - 1)`. Regra CR 103.4c respeitada.
- ✅ **Definição de "jogável" correta.** 2-4 lands AND (ramp >= 1 OR lands >= 3). Definição rigorosa que evita superestimação de ~20pp.
- ✅ **T1 Ramp usa conjunto canônico.** Prompt não especifica, mas as execuções recentes usam apenas `{Sol Ring}` como T1 ramp — correto.
- ✅ **Hash verification no início** — evita re-simular deck inalterado.
- ✅ **T3 "Sem Play" metric** é definition-independent — stable comparison point.

### O que faz ERRADO
- 🟡 **Não simula tapped lands.** Temple of Triumph, Boros Garrison (e outras duals que entram tapped) são tratadas como untapped no turno de entrada. Isso faz o T3 reportado ser MELHOR que o real.
- 🟡 **Não verifica color screw.** Mão com 3 Mountains + spells brancos é considerada "jogável" porque o simulador só conta lands, não verifica se as cores produzidas batem com os pips das spells. ~3-8pp de superestimação.
- 🟡 **Só avalia mão inicial.** Não simula draws dos turnos 1, 2, 3. É um snapshot da mão de abertura, não uma simulação de jogo real. Isso subestima T3 (não considera topdecks que podem salvar uma mão ruim) mas superestima jogabilidade (não considera que draws podem ser inúteis).
- 🟡 **T3 = 1.6% é suspeito.** Com 35 lands em 99 cartas e apenas Sol Ring como T1 ramp, P(0-1 lands in opener) ≈ 15-25%. P(mão jogável mas sem play T3) deveria ser maior que 1.6%. O valor pode ser artefato de classificação incorreta de ramp (ver Gap 15).
- 🟡 **Não detecta mudanças de classificação.** Quando o classificador foi corrigido (ramp tags 6→19, 2026-06-03), o mulligan não re-executou porque o hash do deck não mudou. Mas a simulação deveria produzir resultados DIFERENTES com classificação corrigida.

### Recomendações
1. **Adicionar simulação de tapped lands.** Marcar lands com "enters tapped" no type_line e não usar mana delas no turno de entrada.
2. **Adicionar verificação de color identity.** Verificar se as lands produzem as cores necessárias para as spells na mão.
3. **Invalidar cache quando classificação de cartas é corrigida** (não só quando deck muda).
4. **Investigar T3 = 1.6%** — parece baixo demais. Rodar simulação fresca com N=1000 para confirmar.

---

## Cron 4: Battle Analyst (`94f8590b1beb`) — N/A

### Estado Atual

**Diretório `/opt/data/cron/output/94f8590b1beb/` NÃO EXISTE.**  
Confirmado v3.4 (2026-06-04, commit `1c082553`), re-confirmado v3.5 (`ef09bbb2`), re-confirmado v3.6 (esta auditoria).

O Battle Analyst NUNCA FOI UM CRON. O código fonte em `server/lib/ai/battle_simulator.dart` (879 linhas) existe, mas não há entrada em `jobs.json` com script ou prompt que o execute, e o diretório de output foi removido.

### Código Fonte (879 linhas, inspecionado)

| Aspecto | Implementado? | Observação |
|:--------|:------------:|:-----------|
| 2-player | ✅ Sim | Apenas Deck A vs Deck B — não é Commander multiplayer |
| Flying evasion | ✅ Sim | Bloqueadores precisam ter flying |
| Trample | ✅ Sim | Dano excedente passa (linha 497-499) |
| First Strike | ✅ Sim | Resolve antes do dano normal |
| Lifelink | ✅ Sim | SEM cap de vida (linha 516-519) |
| Deathtouch | ✅ Sim | Mata com 1 de dano |
| Vigilance | ✅ Sim | Não tapa ao atacar |
| Haste | ✅ Sim | Ignora summoning sickness |
| Stack/Priority | 🔴 NÃO | Spells resolvem imediatamente (linha 9: "Sem stack complexo") |
| Counterspells | 🔴 NÃO | Impossível sem stack |
| Commander damage (21) | 🔴 NÃO | Sem distinção de combat damage por commander |
| Commander tax (+2) | 🔴 NÃO | Sem command zone ou re-casting |
| Multiplayer (3+ players) | 🔴 NÃO | Apenas 2 jogadores |
| ETB triggers | 🔴 NÃO | Criaturas entram sem efeitos |
| Planeswalkers | 🔴 NÃO | Tipo não existe no modelo |
| Enchantments/Artifacts | 🔴 NÃO | Não têm efeitos contínuos |
| Instant-speed interaction | 🔴 NÃO | Tudo resolve em main phase |
| Múltiplos bloqueadores | 🔴 NÃO | 1 blocker por attacker |
| Commander color identity | 🔴 NÃO | Não validado |

### Conclusão

O código é um protótipo de simulação 2-player simplificada — útil como proof-of-concept, mas **não simula Commander real**. Não deve ser usado para decisões de swap. Se um dia for promovido a cron, precisará de:
1. Stack/priority (CR 117.3-117.4)
2. Commander damage tracking (CR 903.10a)
3. Commander tax (CR 903.8)
4. Multiplayer (3-4 jogadores)
5. Instant-speed interaction

---

## Cron 5: Evolution Oracle (`a50bef4c2a59`) — 1.5/10 🔴 CRÍTICA

### Prompt (atual)

```text
## Lorehold Evolution Oracle — Decida Swaps com PG + Miracle

### NOVOS DADOS DISPONIVEIS:
#### 1. Miracle Global (Lorehold)
TODAS instants/sorceries no deck custam {2} + pips coloridos com Lorehold no campo.
Priorize instants/sorceries — sao mais rapidas que parecem pelo CMC nominal.

#### 2. PG Multi-Role (card_deck_analysis)
#### 3. Wincon Catalog (wincon_catalog)

### PASSO 0: Analise Estrategica (obrigatorio)
### PASSO 1: Leia os logs (MULLIGAN, BATTLE, SCOUT)
### PASSO 2: Decida swaps (0-3)
```

Script: `manaloom-wincon-oracle.sh` (existe e funciona)

### Último Output: `2026-06-04T11:42:11`

```
Script exited with code 2
stderr: /opt/hermes/.venv/bin/python3: can't open file 
'/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/wincon_pipeline.py': 
[Errno 2] No such file or directory
```

O agente então tentou análise manual, mas o output foi truncado após 1 tool call (`execute_code` para listar scripts). Padrão consistente com TODAS as execuções de 04/Jun.

### O que faz CERTO
- ✅ Script `manaloom-wincon-oracle.sh` EXISTE e é referenciado corretamente em `jobs.json`.
- ✅ Agente TENTA executar análise manual após falha do script (resiliência).
- ✅ `execute_code` funcionou na Execução #53 (hash verification + run_log query).
- ✅ Prompt inclui verificação de singleton e restrição a `user_collection`.

### O que faz ERRADO
- 🔴 **Script `wincon_pipeline.py` NÃO EXISTE.** Referenciado pelo script `manaloom-wincon-oracle.sh` mas o arquivo não está no filesystem. Toda execução retorna exit code 2.
- 🔴 **Death Loop >72h.** Oracle truncado → Scout [SILENT] → Validator [SILENT] → Mulligan [SILENT] → Oracle truncado. Nenhum agente produz análise nova. O ciclo é autossustentável e não se autocorrige.
- 🔴 **Miracle mechanic mal interpretado.** O prompt diz: "TODAS instants/sorceries no deck custam {2} + pips coloridos com Lorehold no campo." Isso é FALSO. A habilidade de Lorehold, Praetor of the Council copia a primeira instant/sorcery conjurada a cada turno (não reduz custo). A redução de {2} é da habilidade "Miracle" (CR 702.94) que se aplica APENAS se a carta foi comprada como primeiro card do turno — NÃO é global. O Oracle está tomando decisões de swap baseado em uma premissa mecânica incorreta.
- 🔴 **Timeout consistente.** O agente é interrompido após ~1 tool call. Aumentar timeout DEVE resolver — o agente não está quebrado, está sendo impedido de terminar.
- 🟡 **Prompt referencia BATTLE_LOG.md** — arquivo que não é produzido por nenhum cron ativo. O agente espera dados que não existem.
- 🟡 **"Wincon Catalog" não documentado.** Referencia `wincon_catalog` como fonte de dados, mas não especifica onde está ou como é populado.
- 🟡 **Sem hash verification.** Diferente do Scout e Mulligan, o Oracle não verifica hash do deck antes de tentar análise. Isso significa que se o deck mudasse, o Oracle não saberia.

### Recomendações
1. **🔴 IMEDIATO:** Aumentar timeout do Oracle para ≥ 300s + forçar execução com `--force`.
2. **🔴 IMEDIATO:** Corrigir ou remover referência a `wincon_pipeline.py` no script `manaloom-wincon-oracle.sh`.
3. **🔴 IMEDIATO:** Corrigir descrição do Miracle mechanic no prompt. Lorehold COPIA spells, não reduz custo. A redução de {2} é do keyword Miracle, que é condicional.
4. **Remover referência a BATTLE_LOG.md** (não existe) ou substituir por fonte real.
5. **Adicionar hash verification** como passo 0.
6. **Considerar trocar provider** para `deepseek-v4-flash` (mais rápido, menor timeout).

---

## Death Loop Analysis (Autossustentável)

O Pipeline Death Loop é um ciclo de feedback positivo que se auto-perpetua:

```
Oracle (timeout/truncado) 
    → não produz análise nova
        → Scout: hash inalterado → [SILENT]
        → Validator: hash inalterado → [SILENT]  
        → Mulligan: hash inalterado → [SILENT]
            → Oracle lê logs: todos [SILENT] 
                → conclui "nada mudou" 
                    → também [SILENT]/truncado
                        → (loop)
```

**Por que é autossustentável:**
1. Nenhum agente produz dados novos se o deck não muda
2. O deck não muda porque o Oracle não aplica swaps
3. O Oracle não aplica swaps porque não consegue completar análise
4. Volta ao passo 1

**Como quebrar o ciclo:**
- Intervenção externa: mudar o deck (hash diverge → força reanálise)
- Forçar execução do Oracle com `--force` + timeout ≥ 300s
- Corrigir o script `wincon_pipeline.py` (ou remover a dependência)

---

## Plano de Correções (ordenado por impacto)

| # | Severidade | Cron | Ação | Esforço |
|:-:|:----------:|:-----|:-----|:-------:|
| 1 | 🔴 CRÍTICO | Oracle | Aumentar timeout ≥ 300s | Baixo |
| 2 | 🔴 CRÍTICO | Oracle | Corrigir/remover referência a `wincon_pipeline.py` | Baixo |
| 3 | 🔴 CRÍTICO | Oracle | Corrigir Miracle mechanic no prompt (Lorehold COPIA, não reduz custo) | Baixo |
| 4 | 🔴 CRÍTICO | Pipeline | Corrigir DB principal (knowledge.db 0-byte ghost no repo `mtgia`) | Médio |
| 5 | 🔴 ALTO | Scout | Restaurar busca EDHREC JSON API (Score A+B+C), não só Wincon Hunter | Médio |
| 6 | 🔴 ALTO | Scout | Adicionar verificação de color identity e banlist no prompt | Baixo |
| 7 | 🟡 MÉDIO | Mulligan | Adicionar simulação de tapped lands e color screw | Médio |
| 8 | 🟡 MÉDIO | Validator | Não recomendar swaps quando ARCHETYPE MISMATCH é detectado | Baixo |
| 9 | 🟡 MÉDIO | Validator | Corrigir nome da tabela no prompt: `card_rulings` (não `card_oracle_data`) | Baixo |
| 10 | 🟡 MÉDIO | Oracle | Remover referência a BATTLE_LOG.md (não existe) | Baixo |
| 11 | 🟢 BAIXO | Oracle | Adicionar hash verification como passo 0 | Baixo |
| 12 | 🟢 BAIXO | Mulligan | Invalidar cache quando classificação de cartas é corrigida | Médio |

---

## Conclusão

A pipeline Lorehold tem confiabilidade **BAIXA** (3.8/10) em relação às regras oficiais de MTG. O score é estável desde v3.5 — houve progresso marginal (Oracle executou tool call real pela primeira vez em 3 dias, Validator corrigiu erro de banlist), mas o Death Loop persiste como problema sistêmico.

**Causa raiz do Death Loop:** O Oracle não consegue completar análise por timeout + script quebrado. Sem Oracle, nenhum swap é aplicado. Sem swaps, o deck não muda. Sem mudança, todos os agentes retornam [SILENT]. O ciclo se auto-perpetua.

**Maior risco de curto prazo:** O Oracle está tomando decisões baseado em uma premissa mecânica incorreta (Miracle global reduz CMC para {2}). Se o timeout fosse aumentado e o Oracle conseguisse completar análise, ele aplicaria swaps baseados em regras erradas.

**Maior gap estrutural:** O Scout perdeu sua função original. Em vez de buscar ativamente o meta (EDHREC) e cruzar com a coleção para encontrar sinergias, ele se tornou um "Wincon Hunter" passivo que só consulta scores pré-calculados. Isso significa que o pipeline perdeu a capacidade de descobrir cartas novas que a comunidade está adotando.

**Próximo passo recomendado:** Resolver os 3 itens CRÍTICOS do Oracle (timeout, script, Miracle mechanic) em uma única intervenção. Isso deve quebrar o Death Loop e permitir que o pipeline volte a produzir análises.
