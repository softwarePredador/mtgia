# Analise: Muldrotha, the Gravetide

## Camada 1: Estrutura do Deck

### Meta
- **Comandante:** Muldrotha, the Gravetide (BGU, 6 CMC)
- **Parceiro (se houver):** Nenhum
- **Arquetipo:** Graveyard Value Midrange / Self-Mill
- **Estrategia central:** Encher o cemiterio via self-mill (Satyr Wayfinder, Stitcher's Supplier, Mesmeric Orb) e usar Muldrotha para rejogar 1 permanente de cada tipo por turno, gerando vantagem de cartas resiliente. O cemiterio funciona como "segunda mao" — se uma permanente importante for removida, ela volta no turno seguinte.
- **Bracket:** 3 (high power casual)
- **Fonte:** https://edhrec.com/average-decks/muldrotha-the-gravetide
- **Amostra:** 23.212 decks (EDHREC average)
- **Data:** 2026-05-27
- **Posicao:** N/A (EDHREC average deck)

### Analise de Mana
- **CMC medio:** 2.66 (EDHREC mana curve: 1-mana=13, 2-mana=19, 3-mana=15, 4-mana=7, 5-mana=7, 6-mana=1)
- **Total de terrenos:** 36 (EDHREC pie chart: 36 lands)
- **Terrenos no avg list:** 24 mostrados (12 basics nao listados no EDHREC top87)
- **Ramp total:** 12 (Arcane Signet, Birds of Paradise, Crop Rotation, Cultivate, Farseek, Harrow, Icetill Explorer, Kheru Goldkeeper, Lotus Petal, Sakura-Tribe Elder, Skull Prophet, Sol Ring)
- **Ramp profile:** 9-12 (profile: min=9, max=12) — **VALIDADO** ✅
- **Notas:** O profile do comandante espera lands 36-39. O EDHREC average tem 36 lands, no limite inferior do range. Ramp em 12 esta no teto do range (9-12), mostrando que jogadores priorizam ramp via permanentes que podem ser re-jogadas do cemiterio (Sakura-Tribe Elder, Lotus Petal).

### Distribuicao Funcional

| Funcao | Contagem | Profile Min-Max | Status |
|:-------|:--------:|:---------------:|:------|
| Lands | 36 | 36-39 | ✅ No range |
| Ramp | 12 | 9-12 | ✅ No range (teto) |
| Draw/Value | 14 | 10-16 (recursion_value) | ✅ No range |
| Self-mill | 11 | 7-11 | ✅ No range (teto) |
| Remocao/Interacao | 11 | 6-10 (replayable interaction) | ⚠️ Acima do range |
| Protecao | 3 | 2-5 (graveyard_protection) | ✅ No range |
| Recursao | 10 | 10-16 (recursion_value) | ✅ No range (minimo) |
| Wincons | 2 | 4-7 (finishers) | ⚠️ Abaixo do range |
| Engines | 8 | — | — |
| Sacrifice Outlets | 1 | — | ⚠️ Apenas Altar of Dementia |

**Nota sobre funcoes:** Os nomes no profile sao especificos para Muldrotha:
- `recursion_value`: Eternal Witness, Animate Dead, Pernicious Deed, World Shaper, etc.
- `replayable_interaction`: Spore Frog, Seal of Removal, Seal of Primordium, etc.
- `graveyard_protection`: Kaya's Ghostform, Perpetual Timepiece
- `finishers`: Jace Wielder of Mysteries, Syr Konrad + self-mill combo

### Plano de Jogo
- **Turnos 1-3 (early):** Self-mill (Satyr Wayfinder, Stitcher's Supplier, Hedron Crab-like effects). Ramp via mana dorks e rocks. Entomb para colocar peca-chave no cemiterio.
- **Turnos 4-6 (mid):** Colocar Muldrotha em jogo. Rejogar permanentes do cemiterio. Estabelecer engines de valor (Rhystic Study, Mystic Remora, The Gitrog Monster).
- **Turnos 7+ (late):** Recursao massiva com World Shaper, Teval, River Kelpie. Syr Konrad drena vida com cada permanente entrando/morrendo. Jace Wielder of Mysteries win via self-mill total.
- **Plano A (vencer):** Self-mill total com Jace, Wielder of Mysteries (sem deck = vitoria). Alternativamente Syr Konrad dano massivo.
- **Plano B (fallback):** Value grind — rejogar Spore Frog todo turno para fogs, Glen Elendra Archmage como counterspell reusavel, Pernicious Deed para reset.
- **Plano C (emergencia):** Recursao de terrenos com Life from the Loam para nunca perder por mana screw. Commander tax irrelevante com Command Beacon e recursao de terrenos.

---

## Camada 2: Psicologia do Deckbuilding

> Analise de cada carta no deck EDHREC average (23.212 decks). Para cada carta,
> explico o raciocinio humano por tras da escolha.

### [Spore Frog] — [Protecao / Fog / Enabler]

**1. O que esta carta FAZ no jogo?**
{1}{G}: "Sacrifice Spore Frog: Prevent all combat damage that would be dealt this turn."

**2. Por que ela esta NESTE deck em vez de outra?**
Spore Frog e a carta mais emblematica do deck Muldrotha. Ela e uma criatura (permanente), custa 1 mana (re-jogavel facilmente com Muldrotha), e tem um efeito de fog reusavel. Nenhuma outra carta faz isso tao eficientemente. Com Muldrotha em campo, voce pode fogar todos os combates de todos os turnos oponentes — 3 fogs por ciclo completo de mesa. **14.001 decks** usam Spore Frog (fonte: EDHREC regex extraction).

**3. Qual medo/risco esta carta resolve?**
"Se eu nao tiver Spore Frog, posso morrer para combate massivo em um turno antes de estabilizar." Muldrotha eh um deck que precisa de tempo para construir o cemiterio. Spore Frog da esse tempo.

**4. Qual ambicao/oportunidade esta carta cria?**
"Com Spore Frog + Muldrotha, eu essencialmente tenho 'fog toda vez que alguem ataca'. Isso me da controle total sobre quando o jogo avanca."

**5. Trade-off explicito:**
O jogador trocou um slot de criatura util por uma criatura que so faz fog. Spore Frog nao contribui para o plano de vitoria — so para sobrevivencia.

**6. Analise de custo de oportunidade:**
Spore Frog e um dos melhores usos de slot defensivo neste deck. A sinergia com Muldrotha e tao forte que e dificil justificar nao inclui-la.

**7. A carta e um STAPLE ou uma ESCOLHA PESSOAL?**
**Staple** para Muldrotha. Especifica do comandante, nao do formato.

### [Kaya's Ghostform] — [Protecao]

**1. O que esta carta FAZ no jogo?**
Enchantment {B}: "Enchant creature you control. When enchanted creature dies, return it to the battlefield under your control."

**2. Por que ela esta NESTE deck?**
Muldrotha custa 6 manas. Commander tax acumula rapido. Kaya's Ghostform protege Muldrotha de remocao por apenas {B} e pode ser re-jogada do cemiterio se Muldrotha morrer. **11.276 decks** usam (fonte: EDHREC).

**3. Qual medo/risco esta carta resolve?**
"Se matarem Muldrotha com um Swords to Plowshares, eu perco 2 turnos (re-jogar por 8 manas). Cada morte e um desastre."

**4. Trade-off explicito:**
Um slot de enchantment que so protege. Nao gera valor nem avanca o plano. Mas o custo de perder Muldrotha e tao alto que vale o slot.

**5. Staple or Personal?** **Staple** para Muldrotha.

### [Altar of Dementia] — [Sacrifice Outlet / Self-Mill / Wincon Enabler]

**1. O que faz?**
Artifact {2}: "Sacrifice a creature: Target player mills cards equal to the sacrificed creature's power."

**2. Por que esta no deck?**
Altar of Dementia e triplamente util: (1) sacrifica criaturas que voce quer no cemiterio, (2) milla oponentes ou voce mesmo, (3) e um enabler de combo com Hermit Druid ou Syr Konrad.

**3. Qual medo resolve?** "Se eu nao tiver um outlet de sacrificio, criaturas 'gastas' (Eternal Witness apos usar) ficam paradas sem funcao."

**4. Qual ambicao cria?** "Com Altar, eu posso transformar qualquer criatura em mill. Isso acelera o plano de self-mill e pode matar oponentes via Syr Konrad + mill."

**5. Staple or Personal?** **Staple** para Muldrotha. E a carta mais comum de sacrificio no deck.

### [Seal of Primordium] — [Remocao Reusavel]

**1. O que faz?**
Enchantment {1}{G}: "Sacrifice Seal of Primordium: Destroy target artifact or enchantment."

**2. Por que esta no deck?**
E um enchantment (permanente) que pode ser re-jogado do cemiterio com Muldrotha. Cada turno, voce pode sacrifica-lo, destruir algo, e no turno seguinte re-joga-lo do cemiterio. Interacao infinita por 2 manas. **11.513 decks** usam (fonte: EDHREC).

**3. Qual medo resolve?** "Se alguem colocar um Rest in Peace, meu deck morre. Preciso de remocao de encantamento reusavel."

**4. Trade-off:** Um slot de enchantment que so serve como remocao condicional. Nao afeta criaturas.

**5. Staple or Personal?** **Staple** para Muldrotha.

### [Seal of Removal] — [Bounce Reusavel]

**1. O que faz?**
Enchantment {U}: "Sacrifice Seal of Removal: Return target creature to its owner's hand."

**2. Por que esta no deck?**
Mesma logica do Seal of Primordium: permanent-based interaction que pode ser re-jogada todo turno com Muldrotha.

**3. Staple or Personal?** **Staple** para Muldrotha.

### [Lotus Petal] — [Ramp Temporario Reusavel]

**1. O que faz?**
Artifact {0}: "Sacrifice Lotus Petal: Add one mana of any color."

**2. Por que esta no deck?**
Com Muldrotha, Lotus Petal e essencialmente "adicione uma mana de qualquer cor" toda vez que voce conjura Muldrotha. Ela vai pro cemiterio apos uso, e Muldrotha pode re-joga-la no turno seguinte. Ramp {0} que nunca acaba.

**3. Staple or Personal?** **Staple** para Muldrotha.

### [Command Beacon] — [Anti-Commander Tax]

**1. O que faz?**
Land: "Sacrifice Command Beacon: Put target commander from the command zone into your hand."

**2. Por que esta no deck?**
Muldrotha custa 6 manas. Cada vez que ela morre, custa 2 a mais. Command Beacon (que e land, permanente) pode ser sacrificada para colocar Muldrotha na mao, ignorando tax. E depois re-jogada do cemiterio.

**3. Staple or Personal?** **Staple** para Muldrotha.

### [Rhystic Study] — [Draw / Engine]

**1. O que faz?**
Enchantment {3}: "Whenever an opponent casts a spell, you may draw a card unless that player pays {1}."

**2. Por que esta no deck?**
E uma das melhores fontes de card advantage do formato (Game Changer oficial). Em 23.212 decks, Rhystic Study e ubiquo. O deck Muldrotha precisa de draw para encontrar pecas de self-mill e interacao.

**3. Medo:** "Se eu nao tiver Rhystic Study, oponentes jogam spells livremente enquanto eu luto para encontrar pecas no cemiterio."

**4. Staple or Personal?** **Staple** do formato (Game Changer).

### [Mystic Remora] — [Draw / Engine]

**1. O que faz?**
Enchantment {U}: "Whenever an opponent casts a noncreature spell, you may draw a card unless that player pays {4}. At the beginning of your upkeep, pay {U} or sacrifice Mystic Remora."

**2. Por que esta no deck?**
Early game card advantage. Nos primeiros turnos, oponentes geralmente nao tem {4} para pagar, entao Mystic Remora gera 2-3 cartas extra. Em Muldrotha, e um enchantment (re-jogavel).

**3. Staple or Personal?** **Staple** do formato (Game Changer).

### [Cyclonic Rift] — [Board Wipe]

**1. O que faz?**
Instant {1}{U}: "Return target nonland permanent you don't control to its owner's hand." Overload {6}{U}: "Return each nonland permanent you don't control to its owner's hand."

**2. Por que esta no deck?**
Cyclonic Rift e o melhor board wipe unilateral do formato. Em Muldrotha, ele nao pode ser re-jogado (instant), mas e a rede de seguranca definitiva quando voce esta perdendo.

**3. Staple or Personal?** **Staple** do formato (Game Changer).

### [Jace, Wielder of Mysteries] — [Wincon]

**1. O que faz?**
Planeswalker {1}{U}{U}{U}: "Draw a card." "If you would draw a card while your library has no cards in it, you win the game instead of losing."

**2. Por que esta no deck?**
Jace e a wincon primaria do deck. Com self-mill (Altar of Dementia, Hermit Druid, Mesmeric Orb), voce pode esvaziar seu grimorio e vencer com Jace no campo. E um planeswalker (permanente), entao pode ser re-jogado do cemiterio.

**3. Medo:** "Se meu self-mill esvaziar meu deck sem Jace, eu perco no draw."

**4. Ambicao:** "Se eu tiver Jace + self-mill engine, eu ganho na hora assim que meu deck acabar."

**5. Staple or Personal?** **Staple** para Muldrotha (wincon especifica do arquétipo).

### [Syr Konrad, the Grim] — [Wincon / Payoff]

**1. O que faz?**
Creature {3}{B}{B}: "Whenever a creature card is put into a graveyard from anywhere, each opponent loses 1 life and you gain 1 life."

**2. Por que esta no deck?**
Syr Konrad transforma self-mill em dano direto. Cada carta de criatura que vai pro cemiterio (via Altar, Mesmeric Orb, Satyr Wayfinder) da ping nos oponentes. Com cemiterio cheio de criaturas, vira morte por mil cortes.

**3. Staple or Personal?** **Escolha pessoal** (uma das wincons alternativas, nao a principal).

### [Hermit Druid] — [Engine / Enabler]

**1. O que faz?**
Creature {2}{G}: "{T}, Exile a creature card from your graveyard: You may play that card this turn. {T}, Exile a card from your graveyard: Mill a card."

**2. Por que esta no deck?**
Hermit Druid e um enabler versatil: exila cartas do cemiterio para jogar (redundancia com Muldrotha) e milla para encher o cemiterio.

**3. Staple or Personal?** **Staple** para Muldrotha.

### [Skull Prophet] — [Ramp + Self-Mill]

**1. O que faz?**
Creature {1}{B}{G}: "{T}: Add {B} or {G}. {T}: Mill a card."

**2. Por que esta no deck?**
Ramp de 2 manas que tambem milla. E uma criatura, entao pode ser re-jogada do cemiterio. Duas funcoes em uma carta.

**3. Staple or Personal?** **Staple** para Muldrotha.

---

## Camada 3: Mental Model do Deckbuilder

### Personalidade do deck
O EDHREC average deck de Muldrotha, baseado em 23.212 decks, revela um jogador que:

- **Estilo:** Conservador e resiliente. Prefere valor incremental a explosao.
- **Tolerancia a risco:** Media. O deck tem wincons claras (Jace, Syr Konrad) mas nao depende de combos de 2 cartas para vencer. A estrategia principal e "nao perder" (fogs, counter spells, recursion) em vez de "ganhar rapido."
- **Nivel de orcamento:** Mid-range casual (sem Force of Will, sem Mana Crypt, sem fetch lands caras T1).
- **Foco principal:** CONSISTENCIA. O deck tem 3+ maneiras de encher o cemiterio, 3+ maneiras de reanimar, e 3+ maneiras de proteger Muldrotha. Nenhum plano depende de uma unica carta.

### O que este deck REVELA sobre como o jogador pensa:

**Principio #1: "O cemiterio e minha segunda mao."**
O deckbuilder de Muldrotha nao ve o cemiterio como descarte — ve como extensao da mao. Cada permanente que vai pro cemiterio esta disponivel no turno seguinte. Isso muda completamente a avaliacao de cartas: um Sol Ring no cemiterio e quase tao bom quanto Sol Ring na mao.

**Principio #2: "Eu prefiro permanent-based interaction a instant/sorcery."**
O deck tem apenas 11 cartas que nao sao permanentes (Cultivate, Counterspell, Cyclonic Rift, Crop Rotation, Farseek, Harrow, Buried Alive, Entomb, Reanimate, Assassin's Trophy, Victimize). Tudo o resto sao permanentes — criaturas, artifacts, enchantments, planeswalkers, lands. Isso maximiza o valor de Muldrotha (que so rejoga 1 permanente de cada tipo por turno).

**Principio #3: "Interacao reusavel > Interacao forte."**
Em vez de Damnation (board wipe forte mas uso unico), o deck prefere Spore Frog (fog todo turno). Em vez de Beast Within (remocao instantanea), prefere Seal of Primordium (remocao reusavel). A logica: com Muldrotha, "usar 1 vez por turno" e melhor que "usar 1 vez e cabou."

**Principio #4: "Protecao de cemiterio e prioridade."**
Kaya's Ghostform, Perpetual Timepiece, e o fato de que quase todas as cartas sao permanentes (resilientes a remocao de cemiterio) mostram que o jogador tem medo de Rest in Peace, Bojuka Bog, e outras formas de hate de cemiterio.

**Principio #5: "Ramp e investimento, nao gasto."**
Em decks normais, Sakura-Tribe Elder sacrificado e um ramp que vai pro cemiterio e acaba. Em Muldrotha, ele volta no turno seguinte. Lotus Petal usada vira um artifact no cemiterio que pode ser re-jogado. Ramp permanentes sao essencialmente "gratuitas" porque retornam.

### Principios de deckbuilding que este deck exemplifica:

1. **"Strategy over power"** — Preferir cartas que se encaixam no plano do comandante a cartas objetivamente mais fortes.
2. **"The graveyard is a resource, not a cost"** — Self-mill nao e "perder cartas", e "preparar o motor."
3. **"Reusable interaction beats one-shot interaction"** — Em decks com recursao, cartas que podem ser usadas multiplas vezes sao superiores a cartas de efeito unico.
4. **"Anti-hate is mandatory"** — Se seu deck depende do cemiterio, voce PRECISA de respostas para Rest in Peace, Bojuka Bog, Leyline of the Void.
5. **"The commander is the engine, not the finisher"** — Muldrotha nao ganha o jogo sozinha. Ela permite que outras cartas ganhem o jogo. O deckbuilder entende que o role do comandante e ser facilitator, nao wincon.

---

## Pesquisa de Contexto

### Sobre o Comandante
Muldrotha, the Gravetide e amplamente considerado **o comandante de recursao de cemiterio mais popular do Commander** (fonte: EDHREC rank #64 em 2026-06). Ela e unica porque permite jogar 1 permanente de CADA tipo do cemiterio por turno — criatura, artifact, enchantment, land, planeswalker. Nenhum outro comandante faz isso com tanta flexibilidade.

**Primers/guias:**
1. EDHREC average deck: https://edhrec.com/average-decks/muldrotha-the-gravetide (23.212 decks)
2. EDH Wiki: https://edh.wiki/commanders/muldrotha-the-gravetide/ (guia de construcao)
3. Draftsim: https://draftsim.com/muldrotha-edh-deck/ (guia completo com budget options)

### Sobre o Meta
Muldrotha e um deck de bracket 3 high-power que sofre contra:
- **Hate de cemiterio:** Rest in Peace, Leyline of the Void, Bojuka Bog, Surgical Extraction — qualquer uma destas paralisa o deck.
- **Graveyard exiling removals:** Swords to Plowshares que exila Muldrotha ao inves de mandar pro cemiterio.
- **Combo fast:** Decks cEDH que ganham antes do turno 4. Muldrotha precisa de 3-4 turnos para estabelecer o motor.

### Sobre Deckbuilding Theory
O deck Muldrotha exemplifica um conceito importante de deckbuilding: **"Synergy-weighted card evaluation."** Cartas que sao medíocres em 99% dos decks (Spore Frog, Seal of Primordium, Kaya's Ghostform) sao All-Stars em Muldrotha. O deckbuilder expert entende que o valor de uma carta depende 50% do texto da carta e 50% do contexto do deck. Este principio e fundamental para a avaliacao de IA de decks.

---

## Insights e Descobertas

### Novos (desta analise)
- [x] **Muldrotha cria uma nova categoria de avaliacao de cartas: "permanent-based efficiency."** O deck prioriza cartas que sao permanentes mesmo se o efeito for mais fraco. Instants e sorceries sao vistos como "descartaveis" porque Muldrotha nao pode rejoga-los. Isto cria um bias forte contra interacao instantanea que o ManaLoom pode nao capturar.
- [x] **Spore Frog e a carta mais subestimada do Commander.** Em 99% dos decks, Spore Frog e lixo. Em Muldrotha, e o melhor fog do formato. O sistema de tags do ManaLoom classifica Spore Frog como apenas "creature" (multi-tag vazio), perdendo completamente o proposito real da carta no deck.
- [x] **Lotus Petal e ramp infinito em Muldrotha.** O classificador ve Lotus Petal como ramp (correto), mas nao captura que ela e muito mais valiosa aqui que em outros decks. Toda carta que vai pro cemiterio e "recursavel" ganha valor adicional.

### Confirmados (validados contra conhecimento anterior)
- [x] **cEDH quebra as regras:** Mas Muldrotha e bracket 3, entao as metricas tradicionais se aplicam (36 lands, 12 ramp, 2.66 avg CMC).
- [x] **EDHREC Average Deck e confiavel:** O profile de Muldrotha (5 fontes, confidence=high) valida todas as metricas do EDHREC average.
- [x] **Bracket 3 subestima interacao:** Confirmado — 11 remocoes mas 3 sao counterspells reativos. 0 board wipes alem de Cyclonic Rift (que e unilateral, nao wipe completo).

### Discrepancias com ManaLoom
| Carta | Tag ManaLoom (single-tag) | Tag Esperada | Diferenca | Impacto |
|:------|:-------------------------:|:------------:|:---------:|:-------:|
| Spore Frog | creature (no tag) | protection / fog | Nao detecta funcao defensiva | Alto — IA ve como criatura inutil |
| Kaya's Ghostform | enchantment (no tag) | protection / recursion | Nao detecta protecao de comandante | Alto — IA pode sugerir cortar |
| Pernicious Deed | enchantment (no tag) | board_wipe | Nao detecta wipe | Medio — IA ve como "enchantment generico" |
| Accursed Marauder | creature (no tag) | removal | Nao detecta edict | Medio — IA ve como criatura mediana |
| Mesmeric Orb | artifact (no tag) | self-mill / engine | Nao detecta enabler | Medio — IA ve como artifact generico |
| Lotus Petal | ramp | ramp (+value, recursavel) | Correto mas sub-valorizado | Baixo — tag certa, peso errado |
| Six | creature | recursion / graveyard_synergy | Multi-tag captura recursion(0.86) | Baixo — multi-tag funciona |
| Aftermath Analyst | creature | recursion / graveyard_synergy | Multi-tag captura recursion(0.86) | Baixo — multi-tag funciona |

### Vocabulario do Dominio
- **Fog pacifista:** Estrategia de "nao deixar ninguem ganhar por combate" usando fogs reusaveis (Spore Frog).
- **Permanent-based interaction:** Interacao que vem de permanentes (Seals, criaturas com ativadas) em vez de instants.
- **Graveyard as second hand:** Conceito de que o cemiterio e uma extensao da mao quando se tem recursao.
- **Soft lock:** Com Spore Frog + Muldrotha, voce essencialmente tem um soft lock em combates — ninguem pode atacar sem gastar recursos para matar Spore Frog primeiro.
- **Synergy-weighted card evaluation:** Cartas sao avaliadas nao por seu poder isolado, mas por quao bem se encaixam no tema do comandante.

---

## Fontes

| Fonte | URL | Dados |
|:------|:----|:------|
| EDHREC Average Deck | https://edhrec.com/average-decks/muldrotha-the-gravetide | 23.212 decks, mana curve, type distribution, 87 card avg list |
| EDHREC Live Page | https://edhrec.com/commanders/muldrotha-the-gravetide | Card salt, rank, 287 card entries with num_decks |
| Scryfall API | https://api.scryfall.com | Oracle text, CMC, type line para 87 cartas |
| Profile Anchor30 | artifacts/commander_reference_profile_anchor30_batch_a_2026-05-12/profiles/muldrotha_the_gravetide.json | role_targets (5 fontes, confidence=high) |
| EDH Wiki | https://edh.wiki/commanders/muldrotha-the-gravetide/ | Primer/reference |
| Draftsim | https://draftsim.com/muldrotha-edh-deck/ | Guia de construcao |

---

## Anexo: Decklist Completa (87 cartas do EDHREC avg)

### Comandante (1)
1x Muldrotha, the Gravetide (CMC 6)

### Criaturas (27+)
Spore Frog (1), Sakura-Tribe Elder (2), Satyr Wayfinder (2), Stitcher's Supplier (1), Birds of Paradise (1), Hermit Druid (2), Eternal Witness (3), Skull Prophet (2), Baleful Strix (2), Aftermath Analyst (2), Accursed Marauder (2), Plaguecrafter (3), Siren Stormtamer (1), Doc Aurlock, Grizzled Genius (2), Haywire Mite (1), Icetill Explorer (4), Kheru Goldkeeper (4), River Kelpie (5), Sidisi, Brood Tyrant (4), Six (3), Solemn Simulacrum (4), Syr Konrad, the Grim (5), Tatyova, Benthic Druid (5), Teval, the Balanced Scale (4), The Gitrog Monster (5), Underrealm Lich (5), World Shaper (4), Gravebreaker Lamia (5), Glen Elendra Archmage (4), Mulldrifter (5), Hedron Shredder (4)

### Artefatos (9)
Arcane Signet (2), Sol Ring (1), Lotus Petal (0), Altar of Dementia (2), Lightning Greaves (2), Swiftfoot Boots (2), Mesmeric Orb (2), Perpetual Timepiece (2), Hedron Shredder (4)

### Enchantments (9)
Kaya's Ghostform (1), Animate Dead (2), Pernicious Deed (3), Ripples of Undeath (2), Secrets of the Dead (3), Seal of Primordium (2), Seal of Removal (1), Rhystic Study (3), Mystic Remora (1)

### Planeswalkers (2)
Jace, Wielder of Mysteries (4), Ashiok, Dream Render (3)

### Instants (4)
Counterspell (2), Cyclonic Rift (2), Assassin's Trophy (2), Crop Rotation (1)

### Sorceries (6)
Buried Alive (3), Entomb (1), Reanimate (1), Victimize (3), Life from the Loam (2), Cultivate (3), Farseek (2), Harrow (3)

### Lands (24 no avg list)
Bojuka Bog, Breeding Pool, Command Beacon, Command Tower, Drowned Catacomb, Evolving Wilds, Exotic Orchard, Fabled Passage, Forest, Hinterland Harbor, Island, Misty Rainforest, Opulent Palace, Overgrown Tomb, Polluted Delta, Rejuvenating Springs, Sunken Hollow, Swamp, Terramorphic Expanse, Undergrowth Stadium, Verdant Catacombs, Watery Grave, Woodland Cemetery, Zagoth Triome
