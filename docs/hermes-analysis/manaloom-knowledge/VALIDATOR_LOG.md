# VALIDATOR_LOG.md — Análise do Deck Lorehold

## Execução: 2026-05-27 (Lorehold Purpose Analyzer)

> **Deck:** Lorehold Spellslinger (bracket 3)
> **Comandante:** Lorehold, the Historian
> **Fonte:** Lista do usuário + DB knowledge.db (deck_id=6)
> **Total: 100 cartas** (99 main + 1 commander)

---

## Seção 1: Visão Geral

### Comparação vs Perfil EDHREC (4 fontes, confidence=high)

O perfil oficial (`commander_reference_profile_lorehold_2026-05-11`) estabelece estes ranges. O deck está:

| Métrica | Seu Deck | EDHREC Ideal | Status | O Que Significa |
|:--------|:--------:|:------------:|:------:|:----------------|
| Lands | 35 | 36-38 | 🔴 1 abaixo | Levemente abaixo — gerenciável com 15 ramp |
| Mana Rocks / Treasure Ramp | 15 | 10-13 | 🟡 2 acima | Maior que a média, mas em Boros ramp extra é raro e bem-vindo |
| Draw (single-tag) | 3 | 8-12 | 🔴🔴 crítico | O problema mais grave do deck |
| Topdeck / Miracle Setup | 7 | 6-9 | ✅ | Scroll Rack, Top, Penance, Land Tax = bom pacote |
| Miracle Haymakers (Big Spells) | 13 | 10-16 | ✅ | CMC 6+: Sunbird's, Volcanic Vision, Insurrection, Storm Herd, etc. |
| Spot Interaction | 4 | 4-6 | ✅ | Swords, Path, Boros Charm, Deflecting Palm |
| Board Wipes / Resets | 4 | 3-5 | ✅ | Austere, Volcanic Vision, Call Forth, Fated Clash |
| Spell Payoffs / Copy Engines | 5 | 5-8 | ✅ | Double Vision, Galvanoth, Rite of the Dragoncaller, Mizzix's Mastery, Sunbird's |
| Protection | 5 | 3-5 | ✅ | Teferi's, Perch, Mother of Runes, Lightning Greaves, Hexing Squelcher |
| **Graveyard Recursion** | **4** | **2-5** | ✅ | **Correção da análise anterior:** deck TEM recursão (Mizzix's Mastery, Surge to Victory, Restoration Seminar, Volcanic Vision, Goblin Engineer) |
| Win Conditions (dedicadas) | 2 | 4-7 | 🔴 2 abaixo | Apenas Approach + Hellkite Tyrant têm tag wincon — mas na prática deck ganha de outras formas (ver abaixo) |
| **CMC médio (não-terrenos)** | 3.69 | 2.5-3.5 | 🟡 levemente acima | Aceitável para Lorehold que casta big spells |

### Pontos-Chave que a análise anterior errou

1. **Draw não é 4 — é 3 (single-tag) ou 8+ (multi-tag).** O problema real é que as únicas fontes de draw consistentes são Artist's Talent, Esper Sentinel e Sensei's Divining Top. Monument to Endurance é bom mas não puxa cartas sozinho. O deck depende de topdeck manipulation como pseudo-draw.

2. **Recursão existe.** A análise anterior disse "0 recursion" mas o deck tem Mizzix's Mastery + Surge to Victory + Restoration Seminar + Goblin Engineer + Volcanic Vision. São 5 cartas de recursão no total.

3. **Terrenos são 35, não 34.** A diferença é pequena mas relevante — 35 com 15 ramp é OK para bracket 3.

4. **Wincons reais.** O classificador vê só 2 wincons (Approach + Hellkite), mas na prática o deck ganha por: Insurrection (rouba criaturas), Storm Herd (token massivo), Hellkite Tyrant (rouba artefatos), Approach (win condition literal), Volcanic Vision loop (recursão infinita de wipes).

---

## Seção 2: Cartas Que Brilham no Lorehold

### Top 5 — Sinergia Máxima com o Comandante

#### 1. **Mizzix's Mastery** ⭐⭐⭐⭐⭐ — A Carta Mais Importante do Deck

Lorehold copia instants/sorceries do graveyard. Mizzix's Mastery exila TODAS as instants/sorceries do graveyard e copia cada uma. Com Lorehold no campo, você paga {4}{R} e ganha **o efeito de cada instant/sorcery no seu cemitério**, dobrado pelo Lorehold. É um Sunbird's Invocation que não precisa de topdeck — só precisa de um cemitério cheio.

**Sinergia:** Lorehold reduz o custo de Mizzix's Mastery (qualquer instant/sorcery do gy custa {1} a menos). Mizzix's Mastery copia TUDO de uma vez. Lorehold COPIA a copia. O resultado é: cada spell no cemitério é conjurada duas vezes.

**Melhor cenário:** Tempo 6. Cemitério com Volcanic Vision, Reforge the Soul, Season of the Bold, Surge to Victory. Casta Mizzix's Mastery → copia 4 spells (8 com Lorehold) → limpa a mesa, compra 7 cartas, faz treasures, devolve mais spells.

---

#### 2. **Volcanic Vision** ⭐⭐⭐⭐⭐ — Loop de Board Wipe + Recursão

Lorehold gosta de spells caras no graveyard. Volcanic Vision custa 7, volta UMA instant/sorcery do gy pra mão, e limpa a mesa. Com Lorehold, ela é copiada — você pode voltar duas spells.

**A verdadeira mágica:** Volcanic Vision volta Mizzix's Mastery → Mizzix's Mastery exila o gy de novo → volta Volcanic Vision → loop. É um reset completo a cada turno.

**Função real:** board_wipe + recursion + engine. Não só um board wipe.

---

#### 3. **Sunbird's Invocation** ⭐⭐⭐⭐ — Double Your Pleasure

A ironia é que o classificador chama isso de "big_spell", mas Sunbird's Invocation é o *segundo motor de cópia* do deck. Quando você casta uma spell de CMC 5+, Sunbird's Invocation procura outra spell de CMC ≤ a primeira e casta de graça. Lorehold então COPIA essa também.

**Na prática:** Casta Insurrection (CMC 8) → Sunbird's procura CMC 8 → encontra Storm Herd → casta de graça → Lorehold copia Insurrection + copia Storm Herd → 2x Insurrection + 2x Storm Herd no mesmo turno.

**Custo de oportunidade zero:** Sunbird's é um payoff que não ocupa slot de "big spell" — é um motor que transforma cada big spell em TWO big spells.

---

#### 4. **Double Vision** ⭐⭐⭐⭐ — O Comeback Engine

Copia o primeiro instant/sorcery de cada turno. Em um deck de spellslinger como Lorehold, isso significa: seu primeiro removal vira dois, seu primeiro draw vira dois, sua primeira recursão vira duas.

**Por que não é #1:** Double Vision copia só UMA spell por turno (no early). Mizzix's Mastery escala com o tamanho do cemitério. Double Vision é melhor em jogos longos; Mizzix's é melhor quando o cemitério está cheio.

---

#### 5. **Jeska's Will** ⭐⭐⭐⭐ — Ramp + Gas + Sinergia

{3} mana → exila top 3 → pode jogar este turno → ou {R} pra cada oponente. Com Lorehold {1} de desconto em instant/sorcery, Jeska's Will fica ainda mais eficiente. E as cartas exiladas viram gas imediato.

**O que torna especial:** É ramp E card advantage E sinergia com Lorehold (spell do exílio, Lorehold desconta). Três funções em uma carta.

---

### Menções Honrosas

| Carta | Por que brilha |
|:------|:---------------|
| **Galvanoth** | Revela topo, casta instant/sorcery CMC≤4 de graça. Lorehold copia. Custa {5} mas paga 1 spell + 1 cópia de graça a cada upkeep. |
| **Rite of the Dragoncaller** | Cada spell cria um 5/5 Dragon token. Lorehold copiando = dois tokens por spell. |
| **Season of the Bold** | Exila top 2, casta se pagar. Lorehold copia = 4 cartas exiladas. E faz treasures. |
| **Unexpected Windfall** | Desconta carta, compra 2, faz 2 treasures. Lorehold copia = compra 4, faz 4 treasures. |

---

## Seção 3: Cartas Questionáveis

### 1. **Rise of the Eldrazi** (CMC 12, removal)
**Função atual:** Removal (target creature/planeswalker)
**% de uso externo:** Extremamente raro em Lorehold. Nenhum EDHREC average deck inclui isso.

**Por que talvez não seja ideal:**
- CMC 12 é caro demais até para Lorehold. Castar isso consome o turno inteiro.
- Ele não é copy-friendly. Lorehold copia como "target" — você ganha um segundo "destroy target" que só funciona se a criatura/planeswalker original tiver aniquilador.
- Aniquilador é irrelevante em Commander (poucos jogadores bloqueiam com 4+ criaturas).
- O deck já tem Austere Command, Volcanic Vision, Fated Clash, Call Forth como wipes.

**Alternativa da sua coleção:**
- **Blasphemous Act** (CMC 9, mas custa {1} na prática com N criaturas) — muito mais jogável.
- **Catastrophe** (CMC 6, board wipe + Armageddon opcional) — mais barato e com opção de land wipe.
- **Obliterate** (CMC 8, board wipe que não pode ser respondido) — melhor que Rise em qualquer cenário.

---

### 2. **Deflecting Palm** (CMC 2, uncertain — é removal condicional)
**Função atual:** Prevenir dano + redirecionar
**% de uso externo:** Muito raro. Só aparece em meta com um único oponente focando você.

**Por que talvez não seja ideal:**
- É um "fog" condicional que precisa de um oponente te atacando com dano relevante.
- Em Commander de 4 jogadores, você raramente sabe quem vai te atacar.
- Deflecting Swat (presente no deck) faz trabalho similar e melhor (redireciona qualquer spell/ability).

**Alternativa da sua coleção:**
- **Chaos Warp** — removal versátil que acerta qualquer permanente. Bota na biblioteca e o oponente revela.
- **Generous Gift** — transforma qualquer permanente em 3/3 Elephant. Cria um blocker mas não deixa o oponente pescar topdeck.
- **Bolt Bend** — redireciona se sua criatura tiver poder 4+. Lorehold é poder 5 em mana 5. Funciona bem.

---

### 3. **Pearl Medallion** (CMC 2, uncertain)
**Função atual:** Cost reduction para white spells
**% de uso externo:** Baixo em Lorehold (EDHREC mostra ~5% de inclusão)

**Por que talvez não seja ideal:**
- O deck tem apenas ~12 white spells. Pearl Medallion reduz {1} em cada.
- Lorehold já dá desconto de {1} em instant/sorcery. O medallion se sobrepõe parcialmente.
- Um turno 2 Pearl Medallion gasta um slot de rampa/rocks que poderia ser um Arcane Signet (que acelera mais).

**Alternativa da sua coleção:**
- **Fellwar Stone** (CMC 2, ramp) — mana de qualquer cor que oponentes tenham. Mais ramp que cost reduction.
- **Storm-Kiln Artist** (CMC 4, ramp + spellslinger payoff) — faz treasure cada vez que casta instant/sorcery. Sinergia direta com Lorehold.
- **Tablet of Discovery** (CMC 3, ramp) — procura uma land básica para o topo.

---

### 4. **Ruby Medallion** (CMC 2, uncertain)
Mesma lógica do Pearl, mas para red. O deck tem mais red spells (~25-30), então Ruby é marginalmente melhor. Ainda assim:

**Custo de oportunidade:** Poderia ser um ramp que realmente acelera em vez de reduzir custo. Em Lorehold, você quer chegar em 5+ mana rápido — um Sol Ring (já incluso) ou Talisman (já incluso) fazem mais.

---

### 5. **Taunt from the Rampart** (CMC 5, uncertain)
**Função atual:** Goad + can't block
**% de uso externo:** Muito raro. Não aparece em EDHREC Lorehold.

**Por que talvez não seja ideal:**
- CMC 5 é caro para um efeito que não avança seu plano de jogo.
- Goar criaturas não te ajuda a vencer. Apenas adia a derrota por um turno.
- Lorehold spellslinger quer CASTAR big spells com cópias, não controlar o combate.

**Alternativa da sua coleção:**
- **Disrupt Decorum** (CMC 4) — goad todas as criaturas. Mesmo efeito, {1} mais barato, e é instantaneo. Na prática, Disrupt Decorum faz a mesma coisa melhor.
- **Pacifism** (CMC 2) — remove blocker de forma permanente.

---

### 6. **Victory Chimes** (CMC 3, uncertain)
**Função atual:** Mana para outros jogadores
**% de uso externo:** Praticamente zero em Lorehold EDHREC.

**Por que talvez não seja ideal:**
- Dá mana para QUALQUER jogador. O deckbuilder que inclui Victory Chimes está desesperado por ramp em Boros.
- O deck já tem 15 ramp sources (2 acima da média). Não precisa mais.
- Dar mana para um oponente em bracket 3 é presente perigoso.

**Alternativa da sua coleção:**
- **Simian Spirit Guide** (CMC 3, mas funciona como instantâneo) — mana imediato sem dar vantagem ao oponente.
- **Manamorphose** (ou qualquer spell de 2 mana) — melhor usar slot como spell que o Lorehold possa copiar.

---

### 7. **Penance** (CMC 3, uncertain)
**Função atual:** Topdeck manipulation + damage prevention condicional
**% de uso externo:** Extremamente raro. Carta obscura.

**Por que talvez não seja ideal:**
- Colocar carta da mão no topo é útil para Lorehold (que casta do topo com desconto), mas só durante a sua main phase.
- O "damage prevention" é contra black/red sources — muito situacional.
- A carta poderia ser um draw spell real.

**Apesar disso:** Penance tem **sinergia real** com Lorehold se você colocar uma big spell no topo e castar do topo com desconto de {1}. Não descarte completamente — é uma escolha pessoal criativa.

**Alternativa da sua coleção:**
- **Faithless Looting** (CMC 1, loot 2) — coloca big spell no graveyard, compra e descarta. Sinergia com Lorehold via graveyard, não via topdeck.
- **Dragon's Rage Channeler** (CMC 1, surveil + payoff) — mise no topo e enche o gy.
- **Valakut Awakening** (já incluso no deck como MDFC — boa!)

---

### 8. **Library of Leng** (CMC 1, graveyard_synergy)
**Função atual:** No maximum hand size + discard to top
**% de uso externo:** Muito baixo em Lorehold.

**Por que talvez não seja ideal:**
- "No maximum hand size" é quase irrelevante em Commander (a não ser que você compre 15+ cartas por turno).
- Colocar discard no topo em vez do gy é ANTI-sinergia com Lorehold (que quer instants/sorceries no gy para copiar com Mizzix's, Volcanic Vision, etc.).
- Exceto se você quiser colocar big spells no topo para castar com Lorehold — mas Penance + Scroll Rack + Sensei's Top já fazem isso.

**IMPORTANTE:** Library of Leng PODE ser boa se usada para colocar big spells no topo em vez de descartá-las. Mas o deck tem 3+ ferramentas de topdeck manipulation — a Library é redundante e ocupa um slot precioso.

**Alternativa da sua coleção:**
- **Dragon's Rage Channeler** — surveil + delimitação. Sinergia com graveyard de Lorehold.
- **Faithless Looting** — enche o gy de spells. Lorehold copia spells do gy.

---

## Seção 4: O Que Outros Decks de Lorehold Fazem Diferente

### Análise do EDHREC Average Lorehold (corpus v2, 5+ fontes)

O EDHREC average deck de Lorehold foca em **topdeck manipulation + miracle** como mecanismo central, enquanto seu deck foca em **treasures + recursion via graveyard**. As diferenças:

#### Seu deck faz MAIS que a média:
- **Ramp via treasures:** Smothering Tithe, Goldspan Dragon, Ancient Copper Dragon, Brass's Bounty. O EDHREC average não investe tanto em treasure ramp.
- **Recursão:** Mizzix's Mastery + Surge to Victory + Restoration Seminar. Média Lorehold usa Sun Titan + Sevinne's Reclamation.
- **Proteção de combo:** Grand Abolisher + Orim's Chant + Galadriel's Dismissal + Teferi's Protection. Média Lorehold prioriza Deflecting Swat + Flawless Maneuver.

#### A média faz MAIS que seu deck:
- **Draw consistente:** EDHREC Lorehold usa Trouble in Pairs, Esper Sentinel, Archivist of Oghma, Mystic Remora, Land Tax + Scroll Rack. O deck tem Artist's Talent + Esper Sentinel + Top — é insuficiente.
- **Miracle payoff direto:** Terminus, Entreat the Dead, Temporal Trespass, etc. Seu deck não tem miracles (exceto o próprio Lorehold).
- **Topdeck manipulation reutilizável:** Scroll Rack + Sensei's Top + Land Tax são o padrão. O deck já tem esses 3, mas faltam mais manipuladores (Sylvan Library não cabe em RW; Crystal Ball, Tower of Fortunes, God-Eternal Oketra pour opções).

#### Por que seu deck é diferente:
Seu deck parece ter sido construído com uma **premissa diferente** da média. Em vez de "topdeck + miracle", sua tese é "acumule treasures, encha o graveyard, e exploda com Mizzix's Mastery / Volcanic Vision." É uma abordagem mais explosiva mas menos consistente.

**Isso é um problema?** Depende. Em bracket 3, decks que explodem no turno 8-10 são perfeitamente viáveis. O risco é que sem draw consistente, você pode chegar no turno 10 com 0 gas. O EDHREC average troca explosão por consistência.

### Cartas que você DEVERIA considerar da média Lorehold

#### Prioridade Alta — Tapar o buraco de draw:
1. **Trouble in Pairs** (Rare, 1W) — draw massivo quando oponentes fazem coisas (que é sempre). Na sua coleção! Considere substituir uma carta questionável.
2. **Archivist of Oghma** (Rare, 2W) — draw cada vez que oponente busca library. Sua coleção tem!
3. **Dawn's Truce** — proteção + draw. Na sua coleção!
4. **Mystic Remora** — draw barato (se pagar {4} por upkeep). Barato em $$$, excelente.

#### Prioridade Média — Melhorar pacotes existentes:
5. **Flawless Maneuver** (Rare) — proteção GRÁTIS se tiver commander no campo. Lorehold está sempre no campo.
6. **Akroma's Will** (Rare, 5W) — proteção + ataque massivo (double strike + flying + lifelink). Na sua coleção!
7. **Farewell** (Rare, 6W) — o melhor board wipe do formato. Exila tudo que você quer exilar. Na sua coleção!
8. **Blasphemous Act** (Rare, R) — {9} mas custa {1} na prática. Na sua coleção!

---

## Seção 5: Recomendações Baseadas na Coleção do Usuário

### Swap Priority #1 — +Draw (Crítico)

| 🔄 Remover | ➕ Adicionar | Por quê |
|:-----------|:------------|:--------|
| Taunt from the Rampart | Trouble in Pairs | Draw consistente em bracket 3 |
| Victory Chimes | Archivist of Oghma | Draw por oponentes buscarem |
| Deflecting Palm | Dawn's Truce | Proteção + draw |

### Swap Priority #2 — Melhorar Board Wipes

| 🔄 Remover | ➕ Adicionar | Por quê |
|:-----------|:------------|:--------|
| Rise of the Eldrazi | Farewell | Melhor board wipe do formato |
| Call Forth the Tempest | Blasphemous Act | Mais barato, mais consistente |

### Swap Priority #3 — Sinergia + Proteção

| 🔄 Remover | ➕ Adicionar | Por quê |
|:-----------|:------------|:--------|
| Pearl Medallion | Flawless Maneuver | Proteção grátis |
| Library of Leng | Dragon's Rage Channeler | Surveil + delimitação + sinergia gy |

---

## Seção 6: Cartas Que Não Foram Classificadas

10 cartas do deck não têm tag funcional primária. O classificador (single-tag) não conseguiu categorizá-las, o que significa que:

1. **O classificador não sabe o que elas fazem** — impacto na precisão das métricas de draw count, protection count, etc.
2. **O ManaLoom pode sugerir removê-las** sem entender o valor.

| Carta | Função Real | Tag Que Deveria Ser | Risco de Swap Indevido |
|:------|:------------|:-------------------:|:----------------------:|
| Grand Abolisher | Proteção — trava oponentes no seu turno | protection | 🟡 Alto — sistema pode tentar trocar por "removal" |
| Orim's Chant | Proteção / Tempo — trava um jogador | protection | 🟡 Alto — sistema vê como "other" |
| Galadriel's Dismissal | Proteção — phasing out de emergência | protection | 🟡 Médio — sistema vê como "other" |
| Scroll Rack | Topdeck manipulation — core do plano | enabler/setup | 🔴 Alto — sem tag, sistema pode sugerir swap. **NÃO REMOVA** |
| Penance | Topdeck manipulation + dano condicional | enabler/topdeck | 🔴 Médio — semi-dispensável, mas tem sinergia |
| Pearl Medallion | Cost reduction white | ramp (indireto) | 🟢 Baixo — já substituível |
| Ruby Medallion | Cost reduction red | ramp (indireto) | 🟢 Baixo — já substituível |
| Victory Chimes | Mana assistida | ramp (ruim) | 🟢 Baixo — já substituível |
| Taunt from the Rampart | Goad temporário | tempo | 🟢 Baixo — já substituível |
| Deflecting Palm | Removal condicional redirecionado | removal | 🟡 Médio — cartas melhores existem |

---

## Resumo para o Jogador

> **Força:** Seu deck tem um plano claro — acumule treasures, encha o graveyard, exploda com Mizzix's Mastery + Volcanic Vision loop. Ramp está acima da média, board wipes estão no range ideal, recursão existe e é boa.

> **Fraqueza crítica:** Draw é insuficiente. Você tem 3 fontes de draw confiáveis (Artist's Talent, Esper Sentinel, Sensei's Top) em vez de 8-12. Você compensa com topdeck manipulation, mas em jogos longos (controle, stax) você vai ficar sem gas enquanto seus oponentes compram 3 cartas por turno.

> **Swap mais urgente:** Substitua Taunt from the Rampart por Trouble in Pairs (está na sua coleção!). A diferença de CMC é 5→4, e você ganha draw massivo.

> **Swap mais criativo:** Substitua Library of Leng por Dragon's Rage Channeler. Você troca "mão sem limite" por surveil 1 por turno + delimitação (que vira 3/3 com 7+ no gy). Dragon's Rage Channeler enche o graveyard que Lorehold precisa.

> **Swap mais seguro:** Substitua Rise of the Eldrazi por Farewell (está na sua coleção!). CMC 12 → 6. Board wipe que exila escolhido. Diferença de dia e noite.

> **Observação final:** Seu deck é um Lorehold "explosivo" diferente da média EDHREC "topdeck + miracle". Isso não é errado — é seu estilo. Mas para tornar esse estilo viável em bracket 3, você precisa de DRAW. 3 fontes não sustentam um plano de recursion-heavy. Adicione 3 fontes de draw, corte as cartas questionáveis, e seu deck vira de "divertido mas inconsistente" para "ameaça real na mesa."
