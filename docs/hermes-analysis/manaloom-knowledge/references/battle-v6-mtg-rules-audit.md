## MTG Rules Audit — Battle Analyst v6

**Data:** 2026-05-31
**Auditor:** MTG Rules Auditor Cron (manaloom-commander-knowledge)
**Fonte:** Magic: The Gathering Comprehensive Rules (2024-11-08)
**Código auditado:** `scripts/battle_analyst_v6.py` (857 linhas)
**Formato:** 4-player Commander simulando Lorehold vs 6 arquétipos, 100 jogos cada

### Sumário

| Categoria | Correto | Incorreto | Ausente | Total |
|:----------|--------:|----------:|--------:|------:|
| A. Turn Structure | 4 | 2 | 6 | 12 |
| B. Casting Rules | 1 | 2 | 4 | 7 |
| C. Combat Rules | 1 | 3 | 6 | 10 |
| D. Mulligan Rules | 2 | 1 | 0 | 3 |
| E. Commander Rules | 2 | 1 | 6 | 9 |
| F. Board Wipes & Protection | 1 | 2 | 1 | 4 |
| G. Game State & Win/Loss | 2 | 1 | 3 | 6 |
| **Total** | **13 (25%)** | **12 (24%)** | **26 (51%)** | **51** |

---

### A. Turn Structure (CR 500-514)

#### Correto

| # | Item | Regra (CR) | Implementação |
|:--|:-----|:-----------|:--------------|
| A1 | **Untap step — mana pool esvazia** | CR 500.4: "When a step or phase ends, any unused mana left in a player's mana pool empties." | Linha 332: `player.mana_pool = 0` no início de cada turno |
| A2 | **Untap step — reset de land drop** | CR 305.2b: um land por turno | Linha 333: `player.lands_played_this_turn = 0` |
| A3 | **Draw step — draw 1 card** | CR 504.1: "First, the active player draws a card." | Linha 341: `player.draw(1, rng)` |
| A4 | **Main phase — land drop** | CR 305.2: play one land per turn during main phase | Linhas 343-349: `lands_in_hand` -> `player.battlefield.append("land")` |

#### Incorreto

| # | Item | Regra (CR) | Como está | Como deveria |
|:--|:-----|:-----------|:----------|:-------------|
| A5 | **Draw step no T1** | CR 800.7: Em multiplayer, o starting player NAO pula o draw step do primeiro turno. So se pula em 1v1 (CR 103.7a). | Linha 340: `if turn > 1 or player.name != "Lorehold":` -> **Lorehold (starting player) nao compra no T1** | Em Commander multiplayer, o primeiro jogador DEVE comprar no T1 |
| A6 | **Fim do turno — end step com triggers** | CR 513.1: "First, all abilities that trigger 'at the beginning of the end step' go on the stack." | Linha 743: `if player.draw_engines > 0: player.draw(1, rng)` — trata draw engines como trigger de end step, mas ignora TODOS os outros triggers | O end step e mal representado — nenhum outro trigger "at the beginning of the end step" e considerado |

#### Ausente

| # | Item | Regra (CR) | Impacto |
|:--|:-----|:-----------|:--------|
| A7 | **Upkeep step** | CR 503.1: "Once it begins, the active player gets priority." Triggers que disparam no upkeep sao colocados na stack. | Critico — Efeitos como "at the beginning of your upkeep" nao existem na simulacao. Smothering Tithe, The One Ring (burden counters), etc. sao ignorados. |
| A8 | **Beginning of Combat step** | CR 507.2: "The active player gets priority." | Medio — Oponentes nao podem responder antes dos attackers serem declarados (ex: tapar criaturas do atacante) |
| A9 | **Declare Blockers step** | CR 509: Oponentes declaram blockers | Critico — NUNCA ha bloqueadores. Todo combate e efetivamente "unblockable". Isso infla o dano e distorce vitorias. |
| A10 | **Combat Damage step separado** | CR 510.1: "First, the active player announces how each attacking creature assigns its combat damage." | Medio — First strike e double strike nao funcionam (Boros Charm double strike nao faz diferenca) |
| A11 | **Postcombat Main Phase** | CR 505.1: segunda main phase existe | Medio — Jogadores nao podem jogar spells apos o combate. Cartas com "post-combat main phase" perdem timing. |
| A12 | **Cleanup step** | CR 514.1: "First, if the active player's hand contains more cards than their maximum hand size (normally seven), they discard enough cards to reduce their hand size to that number." | Critico — Sem descarte para 7. Maos inflam sem consequencia. Cartas como The One Ring (que forca descarte) perdem a penalidade. |

---

### B. Casting Rules (CR 601, 117)

#### Correto

| # | Item | Regra (CR) | Implementação |
|:--|:-----|:-----------|:--------------|
| B1 | **Mana cost tracking** | CR 601.2f: The total cost is the mana cost | Linhas 306-307: `can_cast()` verifica `card["cmc"] <= available_mana(turn)` e deduz CMC do mana pool |

#### Incorreto

| # | Item | Regra (CR) | Como está | Como deveria |
|:--|:-----|:-----------|:----------|:-------------|
| B2 | **Sorcery vs Instant timing** | CR 117.1a: "A player may cast an instant spell any time they have priority. A player may cast a noninstant spell during their main phase any time they have priority and the stack is empty." | Linha 398-412: TODAS as spells sao jogadas no mesmo loop, sem diferenciar sorcery de instant | Spells de instant deveriam poder ser conjuradas em resposta (na stack) ou no turno do oponente. Sorceries so na main phase |
| B3 | **Colored mana requirements** | CR 601.2f: Custo inclui mana colorido, nao so CMC generico | Linha 307: `card["cmc"] <= self.available_mana(turn)` — so verifica CMC numerico | Um card com custo colorido especifico pode ser conjurado com mana de qualquer cor. Color requirements sao completamente ignorados |

#### Ausente

| # | Item | Regra (CR) | Impacto |
|:--|:-----|:-----------|:--------|
| B4 | **Priority system** | CR 117.3-117.4: Jogadores passam prioridade; stack resolve | Critico — Sem priority, nao ha respostas. Counterspells, removal em resposta, protecao em resposta — nada funciona. O jogo e "cada um joga no seu turno sem interacao". |
| B5 | **Stack** | CR 117.7: Spells podem ser respondidas; LIFO | Critico — Intrinsecamente ligado a ausencia de priority. Sem stack = sem countermagic, sem "em resposta", sem protecao reativa. |
| B6 | **Commander tax** | CR 903.8: Commander custa +2 generico por cada vez anterior que foi conjurado da command zone | Medio — O commander Lorehold nunca e rastreado separadamente, entao nunca paga tax. Em jogos longos, isso distorce. |
| B7 | **Spell legality check** | CR 601.2e: "The game checks to see if the proposed spell can legally be cast." | Baixo — A simulacao simplificada nao precisa checar targeting legality, mas remocoes deveriam pelo menos verificar se ha alvo valido |

---

### C. Combat Rules (CR 506-511)

#### Correto

| # | Item | Regra (CR) | Implementação |
|:--|:-----|:-----------|:--------------|
| C1 | **Combat damage reduz vida** | CR 119.3: Damage dealt to a player causes loss of life | Linha 663: `target.life -= actual_damage` (e nas varias funcoes de dano) |

#### Incorreto

| # | Item | Regra (CR) | Como está | Como deveria |
|:--|:-----|:-----------|:----------|:-------------|
| C2 | **Declare Attackers — sem tapping** | CR 508.1f: "The active player taps the chosen creatures. Tapping a creature when it's declared as an attacker isn't a cost; attacking simply causes creatures to become tapped." | Linha 630-663: `combat_phase()` NUNCA da tap nos atacantes. Criaturas atacam sem virar | Atacantes deveriam ser virados (tapped), impedindo-as de bloquear no turno do oponente |
| C3 | **Declare Attackers — sem summoning sickness** | CR 302.6: Criaturas nao podem atacar ou usar habilidades de tap no turno em que entram (a menos que tenham haste). CR 508.1a requer que criaturas sejam untapped e controladas desde o inicio do turno ou tenham haste | Criaturas podem atacar no mesmo turno em que entram | Criaturas sem haste deveriam esperar 1 turno para atacar |
| C4 | **Trample** | CR 702.19: Excesso de dano vai para o jogador | Ausente, mas cartas com trample existem (Akroma's Will da trample) | Danos de criaturas com trample deveriam passar pelo bloqueador |

#### Ausente

| # | Item | Regra (CR) | Impacto |
|:--|:-----|:-----------|:--------|
| C5 | **Declare Blockers** | CR 509: Defensor declara blockers | Critico — Sem blockers, toda criatura e "unblockable". Win rate contra Aggro (Krenko, 35 criaturas) e artificialmente baixo porque as 35 criaturas do oponente batem sem oposicao. Contra Control, e artificialmente alto porque as criaturas do Lorehold tambem batem livre. |
| C6 | **First Strike / Double Strike** | CR 702.7 / 702.4: Dois combat damage steps | Medio — Boros Charm da double strike (linha 56) mas nao ha segundo combat damage step. Akroma's Will tambem da double strike. |
| C7 | **Flying** | CR 702.9: So pode ser bloqueada por criaturas com flying/reach | Medio — Criaturas com flying (Akroma's Will keywords) nao sao bloqueaveis, mas como NAO HA blockers, isso nao importa. Se blockers fossem implementados, flying faria diferenca. |
| C8 | **Multiple blockers** | CR 509.2: Varias criaturas podem bloquear 1 atacante | Medio — So relevante se blockers existirem |
| C9 | **Combat damage assignment order** | CR 509.3: Atacante escolhe ordem de blockers | Baixo — So relevante com blockers |
| C10 | **Remover criatura do combate** | CR 506.4: Criatura que sai do battlefield e removida do combate | Baixo — Simplificacao aceitavel para simulacao sem stack |

---

### D. Mulligan Rules (CR 103.4-103.5)

#### Correto

| # | Item | Regra (CR) | Implementação |
|:--|:-----|:-----------|:--------------|
| D1 | **London Mulligan — draw 7** | CR 103.5: "draws a new hand of cards equal to their starting hand size" | Linhas 668, 679: sempre compra 7 |
| D2 | **Bottom N cards** | CR 103.5: "puts a number of those cards equal to the number of times that player has taken a mulligan on the bottom of their library" | Linhas 681-684: coloca `mulligan_count` cartas no fundo |

#### Incorreto

| # | Item | Regra (CR) | Como está | Como deveria |
|:--|:-----|:-----------|:----------|:-------------|
| D3 | **First mulligan free (multiplayer)** | CR 103.5c: "In a multiplayer game... the first mulligan a player takes doesn't count toward the number of cards that player will put on the bottom of their library" | Linha 681: `for _ in range(mulligan_count):` — conta desde o primeiro mulligan. O primeiro mulligan poe 1 carta no fundo quando deveria por 0 | O primeiro mulligan deveria por 0 cartas no fundo; o segundo 1 carta; o terceiro 2 cartas. A penalidade atual e 1 carta mais severa do que o correto para Commander multiplayer |

---

### E. Commander-Specific Rules (CR 903)

#### Correto

| # | Item | Regra (CR) | Implementação |
|:--|:-----|:-----------|:--------------|
| E1 | **Starting life = 40** | CR 903.7: "each player sets their life total to 40" | Linha 268: `self.life = 40` |
| E2 | **Deck size = 100** | CR 903.5a: "Each deck must contain exactly 100 cards, including its commander." | `load_deck()` carrega 100 cartas do SQLite (commander incluso no deck_cards) |

#### Incorreto

| # | Item | Regra (CR) | Como está | Como deveria |
|:--|:-----|:-----------|:----------|:-------------|
| E3 | **Opponent decks sem commander** | CR 903.3: "Each deck has a legendary creature card designated as its commander." | `generate_opponent_deck()` gera 99 cartas sem commander (linha 254) e nenhuma delas e a legendary creature que lidera o deck | Oponentes deveriam ter 1 commander + 99 cartas no deck = 100 cards total. Atualmente tem 99 cartas sem commander |

#### Ausente

| # | Item | Regra (CR) | Impacto |
|:--|:-----|:-----------|:--------|
| E4 | **Commander zone** | CR 903.6: Commander comeca na command zone | Critico — O commander do Lorehold esta no deck como carta normal. Nao ha distincao entre commander e outras cartas. |
| E5 | **Commander damage (21)** | CR 903.10a: "A player who's been dealt 21 or more combat damage by the same commander over the course of the game loses the game." (SBA 704.6c) | Critico — `commander_damage` defaultdict existe (linha 269) mas NUNCA e atualizado nem verificado. Vitorias por commander damage nunca ocorrem. |
| E6 | **Commander cast from command zone** | CR 903.8: Commander pode ser conjurado da command zone | Medio — Sem command zone, o commander e comprado do deck como carta normal. Se for morto/exilado, nao pode ser re-conjurado. |
| E7 | **Commander tax** | CR 903.8: +2 generico por cada cast anterior da command zone | Medio — Consequencia da ausencia da command zone |
| E8 | **Color identity enforcement** | CR 903.5c: "A card can be included in a Commander deck only if every color in its color identity is also found in the color identity of the deck's commander." | Baixo — Oponentes usam decks genericos pre-definidos. Para o deck Lorehold (Boros), todas as cartas no SQLite ja respeitam color identity |
| E9 | **Commander vai para command zone ao morrer/exilar** | CR 903.9a-b: State-based action permite mover commander para command zone | Medio — Sem command zone, commander vai para o cemiterio como carta normal |

---

### F. Board Wipes & Protection

#### Correto

| # | Item | Regra (CR) | Implementação |
|:--|:-----|:-----------|:--------------|
| F1 | **Wrath destroi TODAS as criaturas** | Efeitos de "destroy all creatures" afetam todas as criaturas em jogo | Linhas 457-463: Itera sobre TODOS os jogadores (incluindo o caster) e destroi criaturas. Board wipes sao simetricos. |

#### Incorreto

| # | Item | Regra (CR) | Como está | Como deveria |
|:--|:-----|:-----------|:----------|:-------------|
| F2 | **Teferi's Protection — confunde "phase out" com "protection"** | CR 702.26 (Phasing): Phase out remove permanents do battlefield. NAO da protecao ao jogador contra tudo. Teferi's Protection da "your life total can't change" e "you have protection from everything", mas o phase out e dos PERMANENTS, nao do JOGADOR como escudo. | Linhas 484-487: `"phase_out"` seta `player.protected = True` e `player.protected_until = turn + 2`. Isso trata phase out como um escudo de protecao que bloqueia wipes (linha 458) — MAS phase out REALMENTE remove os permanents do campo, nao cria um escudo magico. | Phase out deveria: (1) remover TODOS os permanents do jogador do battlefield temporariamente, (2) o jogador nao pode ser alvo de spells/abilities e sua vida nao muda. Wipes nao deveriam destruir criaturas "phased out" porque elas NAO ESTAO no battlefield. O codigo atual so poe um flag `protected` que bloqueia wipes mas nao simula o phase out. |
| F3 | **Boros Charm — confunde "indestructible to permanents" com "protection to player"** | Boros Charm da indestructible a TODOS os permanents que voce controla ate o final do turno. NAO da protecao ao jogador. | Linhas 489-492: `"indestructible"` seta `player.protected = True` e `player.protected_until = turn + 1`. Isso bloqueia TODOS os efeitos (nao so destruction) e trata como protecao ao jogador em vez de indestructible aos permanents. | Indestructible deveria: impedir que permanents sejam destruidos (por damage ou "destroy" effects), mas NAO bloqueia exile, sacrifice, bounce, -X/-X, etc. O codigo atual trata como protecao total ao jogador (incluindo contra wipes), o que e funcionalmente similar ao resultado final (criaturas sobrevivem ao wipe) mas tecnicamente diferente |

#### Ausente

| # | Item | Regra (CR) | Impacto |
|:--|:-----|:-----------|:--------|
| F4 | **Regeneration** | CR 701.15: "Regeneration is a destruction-replacement effect." | Baixo — Nenhuma carta no deck atual usa regenerate |

---

### G. Game State & Win/Loss

#### Correto

| # | Item | Regra (CR) | Implementação |
|:--|:-----|:-----------|:--------------|
| G1 | **Life <= 0 = lose** | CR 704.5a: "If a player has 0 or less life, that player loses the game." | Linha 309-310: `is_alive()` retorna `self.life > 0` (embora nao verificado como SBA) |
| G2 | **Approach of the Second Sun** | Mecanica da carta: primeiro cast ganha 7 life e vai 7a do topo; segundo cast = win | Linhas 509-520: primeiro cast -> `approach_count += 1`, ganha 7 life, vai 7a do topo. Linhas 733-734: `approach_count >= 2` -> vitoria. |

#### Incorreto

| # | Item | Regra (CR) | Como está | Como deveria |
|:--|:-----|:-----------|:----------|:-------------|
| G3 | **Insurrection win check** | Insurrection e um feitico que rouba TODAS as criaturas e as desvira. A vitoria vem do ataque com as criaturas roubadas. | Linhas 737-740: `if any(c.get("name") == "Insurrection" for c in player.graveyard):` — verifica se Insurrection esta NO CEMITERIO e assume vitoria se nao ha oponentes vivos. | Insurrection vai para o cemiterio APOS resolver, entao esse check so ocorre em turnos FUTUROS (depois que Insurrection ja resolveu). A vitoria deveria ser verificada IMEDIATAMENTE apos o efeito de steal_all_creatures causar dano letal, nao depois |

#### Ausente

| # | Item | Regra (CR) | Impacto |
|:--|:-----|:-----------|:--------|
| G4 | **Draw from empty library = lose** | CR 704.5b: "If a player attempted to draw a card from a library with no cards in it since the last time state-based actions were checked, that player loses the game." | Medio — Jogos que chegam ao turno 15+ podem ter decks vazios. `player.draw()` na linha 288 so retorna lista vazia, sem trigger de derrota |
| G5 | **Maximum hand size (discard to 7)** | CR 514.1: Cleanup step descarta ate 7 | Medio — Sem cleanup step, maos crescem indefinidamente. Em jogos longos (10+ turnos), jogadores acumulam 15+ cartas na mao sem penalidade |
| G6 | **Poison counters (10 = lose)** | CR 704.5c: "If a player has ten or more poison counters, that player loses the game." | Baixo — Nenhuma carta no deck atual usa poison/infect |

---

### Recomendações Prioritárias

#### 1. [CRITICO] Implementar Declare Blockers (C5)
**Impacto:** Todo combate e "unblockable". Win rates sao completamente distorcidos.  
**Como corrigir:** Adicionar uma funcao `declare_blockers()` no `combat_phase()` onde cada oponente vivo pode designar criaturas para bloquear. Bloqueadores reduzem o dano ao jogador em `power do bloqueador`.

#### 2. [CRITICO] Implementar Priority/Stack (B4, B5)
**Impacto:** Sem stack, counterspells, respostas e protecao reativa nao existem. O jogo e "goldfishing" multiplayer.  
**Como corrigir:** Adicionar uma lista `stack` ao estado do jogo. Cada spell vai para a stack antes de resolver. Jogadores podem responder com instants.

#### 3. [CRITICO] Implementar Commander Zone e Commander Damage (E4, E5)
**Impacto:** Mecanica mais fundamental do formato esta ausente. 21 commander damage e uma condicao de vitoria inteira.  
**Como corrigir:** Separar o commander do deck. Coloca-lo na command zone. Rastrear commander damage por jogador. Permitir re-cast com tax.

#### 4. [CRITICO] Corrigir Cleanup Step — descarte para 7 (A12)
**Impacto:** Maos inflam sem consequencia em jogos longos, distorcendo decisoes de keep/discard.  
**Como corrigir:** Adicionar cleanup step ao final do turno: `while len(player.hand) > 7: discard one`.

#### 5. [ALTO] Corrigir Draw Step no T1 para multiplayer (A5)
**Impacto:** Lorehold comeca com -1 carta em todas as simulacoes (erro de ~1% em win rate consistente).  
**Como corrigir:** Remover a condicao `or player.name != "Lorehold"` da linha 340. Em Commander multiplayer, todos compram no T1.

#### 6. [ALTO] Corrigir Teferi's Protection — implementar phase out real (F2)
**Impacto:** Teferi's Protection e tratado como escudo magico, nao como phase out.  
**Como corrigir:** Phase out deveria: remover todos os permanents do battlefield para uma zona "phased out", impedir life change, e dar protection from everything ao jogador. Retornar no proximo untap.

#### 7. [ALTO] Implementar Postcombat Main Phase (A11)
**Impacto:** Jogadores nao podem jogar spells apos o combate. Cartas que dependem de "postcombat main" perdem timing.  
**Como corrigir:** Adicionar segunda main phase apos o combate no loop `simulate_game()`.

#### 8. [MEDIO] Corrigir colored mana requirements (B3)
**Impacto:** Cartas com custo colorido especifico podem ser conjuradas com qualquer mana. Em decks multicolor, isso e um buff artificial.  
**Como corrigir:** Adicionar tracking de mana colorida (W, U, B, R, G) junto com mana generica.

#### 9. [MEDIO] Corrigir summoning sickness (C3)
**Impacto:** Criaturas atacam no mesmo turno em que entram. Acelera o clock de dano.  
**Como corrigir:** Adicionar flag `summoning_sick = True` ao entrar, limpar no proximo untap do controlador.

#### 10. [MEDIO] Corrigir free mulligan em multiplayer (D3)
**Impacto:** Penalidade de 1 carta extra no primeiro mulligan. Efeito pequeno mas cumulativo em simulacoes de 1000+ jogos.  
**Como corrigir:** `bottom_count = max(0, mulligan_count - 1)` em vez de `mulligan_count`.

#### 11. [BAIXO] Adicionar draw from empty library = lose (G4)
**Impacto:** Raro em Commander (100 cartas), mas relevante para decks de mill.  
**Como corrigir:** Verificar `len(player.library) == 0` apos cada draw e marcar como derrota.

#### 12. [BAIXO] Corrigir opponent deck size (E3)
**Impacto:** Oponentes tem 99 cartas em vez de 100 (1 commander + 99). Diferenca de 1%.  
**Como corrigir:** Adicionar uma carta "Commander" ao deck do oponente e rastrear commander damage.

---

### Conclusão

O Battle Analyst v6 e um **simulador de goldfishing multiplayer**, nao um simulador de Commander. Ele modela corretamente a progressao de mana e a curva de CMC, mas omite a maioria das regras de interacao entre jogadores (combate com blockers, stack, priority, respostas).

**O que o simulador mede bem:**
- Consistencia de curva de mana (quantos turnos para conjurar spells de CMC X)
- Impacto de ramp e aceleracao de mana
- Velocidade de "clock" (quantos turnos para matar oponentes sem interacao)
- Probabilidade de encontrar win conditions (Approach, Insurrection)

**O que o simulador NAO mede:**
- Interacao real entre decks (removal, counters, protecao em resposta)
- Sobrevivencia contra estrategias agressivas com blockers
- Valor real de cartas de protecao (Boros Charm, Teferi's Protection) — sao superestimados
- Commander damage como rota alternativa de vitoria

**Recomendacao para v7:** Priorizar blockers e commander zone/commander damage. Essas duas features sozinhas corrigiriam ~60% dos gaps criticos e fariam o simulador passar de "goldfishing multiplayer" para "Commander aproximado". Stack completa e desejavel mas pode ser adiada para v8.

---

*Fontes consultadas:*
- Magic: The Gathering Comprehensive Rules (November 8, 2024) — CR 103, 117, 500-514, 601, 704, 903
- https://media.wizards.com/2024/downloads/MagicCompRules%2020241108.txt
