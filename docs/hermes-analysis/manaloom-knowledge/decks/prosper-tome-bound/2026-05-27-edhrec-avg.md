# Analise de Deck: Prosper, Tome-Bound

> **Data:** 2026-05-27  
> **Fonte:** EDHREC Average Decks (4 arquétipos: optimized, control, cEDH, artifacts)  
> **Amostra:** 4 decks x ~88 cartas cada (corpus `commander_reference_deck_corpus_prosper_2026-05-13`)  
> **Perfil de referencia:** `commander_reference_profile_anchor30_batch_a_2026-05-12/profiles/prosper_tome_bound.json` (source_count=6)

## Resumo Executivo

Prosper, Tome-Bound e o comandante Rakdos de exile value e treasure generation mais popular do formato. O deck e um **engine value** que gera card advantage via impulse draw e converte essa vantagem em treasures. Diferente de outros engines (Aesi, Korvold), Prosper gera tesouros PASSIVAMENTE — cada carta conjurada do exile produz um treasure, sem necessidade de sacrificio.

**3 arquétipos principais identificados:**
1. **Optimized Combo/Artifacts Treasure** — Foco em storm + treasure payoffs + combo (Underworld Breach + LED + Grinding Station)
2. **Control Exile Treasure** — Foco em interacao + exile value incremental, com wincons de drenagem (Marionette Master, Mayhem Devil)
3. **cEDH Storm Treasure** — 28 lands, 9 tutors, Underworld Breach storm packages, Aetherflux Reservoir

## Perfil de Referencia (source_count=6)

| Metrica | Profile Min-Max | Notas |
|:--------|:---------------:|:------|
| Lands | 33-36 | Varia por arquetipo; cEDH usa 28 |
| Exile Casting | 10-16 | O motor do deck |
| Treasure Generation | 8-13 | Geracao passiva via Prosper + cartas adicionais |
| Treasure Payoffs | 5-9 | Xorn, Academy Manufactor, Marionette Master |
| Rituals | 3-8 | Dark Ritual, Rite of Flame, Jeska's Will |
| Interaction | 8-12 | Chaos Warp, Abrade, Pyroblast, Deflecting Swat |
| Storm Combo | 0-6 | Underworld Breach + LED + Grinding Station |

### Packages Core (do profile)

| Package | Cartas Chave | Funcao |
|:--------|:------------|:-------|
| Exile Casting (8) | Light Up the Stage, Reckless Impulse, Jeska's Will, Laelia, Outpost Siege, Theater of Horrors, Valakut Exploration, Ignite the Future | Motor de card advantage via impulse draw |
| Treasure Payoffs (8) | Xorn, Academy Manufactor, Marionette Master, Mirkwood Bats, Revel in Riches, Nadier's Nightblade, Mayhem Devil, Pitiless Plunderer | Convertem treasures em dano/cartas/mana |
| Storm Combo (6) | Underworld Breach, Lion's Eye Diamond, Grinding Station, Grapeshot, Wishclaw Talisman, Aetherflux Reservoir | Wincon de alto nivel |
| Rituals (6) | Dark Ritual, Rite of Flame, Culling the Weak, Rain of Filth, Jeska's Will, Seething Song | Ramp explosiva para storm |
| Interaction (7) | Deflecting Swat, Pyroblast, Abrade, Opposition Agent, Deadly Rollick, Chaos Warp, Feed the Swarm | Protecao e remocao |

## Metricas do Corpus EDHREC (4 decks)

### Por Arquétipo

| Metrica | Optimized (86 cards) | Control (85 cards) | cEDH (98 cards) | Artifacts (88 cards) | **Media** |
|:--------|:-------------------:|:------------------:|:---------------:|:--------------------:|:--------:|
| Lands | 33 | 34 | **28** | 32 | **31.75** |
| Ramp | 10 | 12 | 10 | 11 | **10.75** |
| Ritual/Treasure | 12 | 10 | 10 | 10 | **10.5** |
| Interaction | 8 | 7 | 9 | 7 | **7.75** |
| Exile Value | 6 | **10** | 8 | 9 | **8.25** |
| Tutor | **5** | 1 | **9** | 3 | **4.5** |
| Win Condition | **5** | **5** | 0* | 4 | **3.5** |
| Board Wipe | 1 | 1 | 0 | 1 | **0.75** |
| Protection | 1 | 2 | 1 | 2 | **1.5** |
| Recursion | 2 | 1 | 4 | 1 | **2.0** |
| Miracle/Topdeck | 4 | 4 | 4 | 5 | **4.25** |
| Creature | 5 | 5 | 4 | 7 | **5.25** |
| Spellslinger | 2 | 1 | 3 | 1 | **1.75** |
| Draw Value | 1 | 1 | 1 | 0 | **0.75** |

\* cEDH nao declara wincons separadamente — storm e combo sao o plano primario

### Top Cards Universais (4/4 decks)

| Carta | Papel | Sinergia com Prosper |
|:------|:-----:|:---------------------|
| Arcane Signet | Ramp | Fixacao de mana Rakdos |
| Birgi, God of Storytelling | Ramp | Harnfel e ramp. Flipside e exile engine — adia e faz treasures |
| Bolas's Citadel | Miracle/Topdeck | Topdeck manipulation + cast do topo = treasures |
| Crime Novelist | Ramp | Cada treasure que morre = +1 mana |
| Dark Ritual | Ramp | Ramp explosivo para Prosper no turno 2-3 |
| Dauthi Voidwalker | Creature | Hatebear + pode castar cartas do exile dos oponentes = treasures |
| Deadly Rollick | Interaction | Remocao free |
| Deflecting Swat | Protection | Protecao free |
| Demonic Tutor | Tutor | Busca peca chave |
| Feed the Swarm | Interaction | Unica remocao de enchantment em Rakdos |
| Fellwar Stone | Ramp | Ramp generico |
| Jeska's Will | Ritual/Treasure | Ramp explosivo + exile draw |
| Light Up the Stage | Exile Value | Impulse draw de 2 cartas por 1R |
| Mayhem Devil | Interaction | Cada treasure que morre = 1 de dano a qualquer alvo |
| Professional Face-Breaker | Ritual/Treasure | Atacar = treasure + card advantage |
| Reckless Fireweaver | Creature | Cada artefato que entra = 1 de dano |
| Reckless Impulse | Exile Value | Impulse draw basico |
| Sensei's Divining Top | Miracle/Topdeck | Topdeck manipulation para Bolas's Citadel + Prosper |
| Sol Ring | Ramp | Ramp generico |
| Storm-Kiln Artist | Spellslinger | Cada spell = treasure + +1/+1 counter |
| Xorn | Ramp | Cada treasure gerado = +1 treasure |
| Talisman of Indulgence | Ramp | Ramp colorido |

## Tema Principal: Exile Value Treasure Engine

Prosper e um **engine deck** que gera valor atraves de:
1. **Impulse draw** (exile casting) — Reckless Impulse, Light Up the Stage, Jeska's Will
2. **Treasure generation passiva** — Cada spell do exile gera 1 treasure
3. **Treasure payoffs** — Xorn (dobra treasures), Marionette Master (drena), Mayhem Devil (pings)

Diferente de Korvold (que precisa sacrificar), Prosper gera tesouros SEMPRE que conjura do exile. Isso torna o deck mais consistente — nao depende de ter algo para sacrificar.

### Metricas Chave

| Metrica | EDHREC Media | Profile | Julgamento |
|:--------|:------------:|:-------:|:----------|
| Lands | 31.75 | 33-36 | **Abaixo do profile** — especialmente o cEDH com 28 lands. O deck Rakdos pode funcionar com menos lands porque tem muitos rituals |
| Ramp | 10.75 | — | Aceitavel para Rakdos sem dorks verdes. Inclui rituals |
| Exile Casting | 8.25 | 10-16 | **No minimo do profile**. Decks control/artifacts tem 9-10, o que e ok |
| Treasure Payoffs | ~8 (implícito) | 5-9 | No limite superior. O deck tem muitos payoffs |
| Rituals | 4+ (est.) | 3-8 | No meio do range |
| Interaction | 7.75 | 8-12 | **Ligeiramente abaixo**. 8 e o minimo aceitavel |
| Tutors | 4.5 | — | Varia muito por arquetipo (cEDH tem 9, control tem 1) |

### Discrepancias EDHREC vs Profile

1. **Lands baixas (31.75 vs 33-36)** — O deck funciona com menos lands em Rakdos por causa dos rituals, mas 31 lands e arriscado para bracket 3. O profile recomenda 33-36 para consistencia.
2. **Interaction no minimo (7.75 vs 8-12)** — Rakdos ja tem as piores cores para interacao (sem counters, sem enchantment removal confiavel). 8 interacoes e o minimo para nao morrer para combos.
3. **Protection muito baixa (1.5)** — Prosper custa 4 manas e e o motor do deck. Com so 1-2 protecoes, oponentes podem simplesmente matar Prosper e parar o deck.

## Padroes de Deckbuilding

### Regras Gerais

1. **Prosper e o unico comandante que gera treasures por conjurar do exile** — Nao ha outro comandante que faca isto. Cada carta de impulse draw e efetivamente "R: exile top card, conjure ate o fim do turno. Se conjurar, crie um treasure."
2. **O deck nao precisa de ramp verde para acelerar** — Rituals (Dark Ritual, Rite of Flame, Jeska's Will) compensam a falta de dorks. Cada ritual que leva Prosper ao campo no turno 2-3 gera valor exponencial.
3. **Bolas's Citadel e a melhor carta do deck** — Citadel permite conjurar do topo do library, que ativa Prosper (treasure) e ignora timing de impulse draw. Em 4/4 decks do corpus, e universal.
4. **Topdeck manipulation substitui draw tradicional** — Sensei's Top + Bolas's Citadel + Scroll Rack dao controle absoluto do topo, que alimenta tanto Prosper quanto Citadel. O deck tem ~4 cartas de topdeck setup, similar a Lorehold.
5. **Treasure payoffs sao wincons** — Marionette Master, Mirkwood Bats, Mayhem Devil, Nadier's Nightblade convertem treasures em dano direto. O deck nao precisa de combos para vencer — treasures + payoffs = dano inevitavel.
6. **Storm e opcional, nao obrigatorio** — O cEDH e o optimized incluem Underworld Breach storm, mas o control e artifacts nao. O deck funciona sem storm em bracket 3, apenas com treasure payoffs incrementais.
7. **Rakdos sofre contra enchantments** — Feed the Swarm e a unica remocao de enchantment consistente. Chaos Warp e situacional. O deck depende de remover oponentes antes que eles estabelecam prison enchantments.
8. **Dauthi Voidwalker e hatebear + synergy** — Nao apenas impede oponentes de usar GY, mas permite castar cartas do exile deles, gerando treasures de Prosper com cartas de oponentes.

### Psicologia do Jogador

- **Jogador de Prosper Optimized/Artifacts:** Estrategista value-engine. Pensa em termos de "mana gerada por treasure" e "valor por carta de exile." Prefere payoffs incrementais a combos deterministicos. Aceita riscos de mana (rituals > rocks) pela velocidade extra.
- **Jogador de Prosper Control:** Conservador-valor. Pensa em termos de "nao posso perder tempo" — usa interaction para sobreviver ate o midgame, quando Prosper + Bolas's Citadel geram vantagem imparavel.
- **Jogador de cEDH Prosper:** Agressivo-combo. Pensa em termos de "storm count" e "mana positiva." Inclui LED + Breach + Grinding Station como wincon principal, com Prosper como plano B de value.

### Insights para ManaLoom

| Carta | Tag ManaLoom | Tag Esperada | Diferenca |
|:------|:-----------:|:------------:|:---------|
| Prosper, Tome-Bound | engine | draw/engine | Sistema precisa de tag "engine" para comandantes que geram valor passivo |
| Bolas's Citadel | miracle_topdeck | engine + wincon | E o motor principal do deck, nao apenas topdeck setup |
| Xorn | ramp | treasure_payoff | Xorn duplica treasures, mas so funciona se voce ja tem treasure gen |
| Crime Novelist | ramp | treasure_payoff | Mesmo problema — e payoff condicional, nao ramp puro |
| Mayhem Devil | interaction | payoff + removal | E o principal payoff do deck, nao so remocao |
| Birgi, God of Storytelling | ramp | engine + ramp | O flip (Harnfel) e engine de exile |
| Storm-Kiln Artist | spellslinger | ramp + payoff | Cada spell gera treasure. E ramp condicional |
| Professional Face-Breaker | ritual_treasure | engine + ramp | Atacar gera treasure + card advantage. E engine de mesa |
| Dauthi Voidwalker | creature | hatebear + GY hate + value | Carta serve a 3 funcoes: GY hate, cast do exile, treasure gen |

## Sinergias Documentadas

| Carta A | Carta B | Tipo de Sinergia | Forca |
|:--------|:--------|:-----------------|:-----:|
| Prosper | Reckless Impulse | Exile draw → Treasure | Essencial |
| Prosper | Bolas's Citadel | Topdeck cast → Treasure infinito | Essencial |
| Prosper | Sensei's Divining Top | Controle de topo → Treasure por turno | Alta |
| Bolas's Citadel | Sensei's Divining Top | Cast barato do topo → Pay life 1 | Alta |
| Xorn + Prosper | Treasure generation | Cada treasure = 2 treasures | Essencial |
| Academy Manufactor + Prosper | Treasure generation | Cada treasure = treasure + clue + food | Alta |
| Marionette Master | Qualquer treasure morte | Drena 3 por treasure | Alta |
| Mayhem Devil | Qualquer treasure morte | 1 de dano a qualquer alvo | Alta |
| Underworld Breach | LED + Grinding Station | Storm combo infinito | Essencial (cEDH) |
| Underworld Breach | Lotus Petal + Grinding Station | Storm combo budget | Alta (optimized) |
| Birgi (Harnfel) | Qualquer spell | Exile draw que alimenta Prosper | Alta |
| Professional Face-Breaker | Prosper | Ataque = treasure + card advantage | Alta |

## Conclusao

Prosper e um dos engines mais consistentes do formato porque:
1. **Nao depende de combat triggers** — Diferente de Korvold, Yuriko, Winota, Prosper gera valor sem atacar
2. **Cada carta de impulse draw e um motor pequeno** — O deck funciona com 8-10 fontes de impulse draw, cada uma gerando 1-3 treasures
3. **Tem wincons integrados** — Treasure payoffs (Marionette Master, Mayhem Devil) convertem valor em dano sem precisar de combo
4. **Rakdos tem boa interaction** — Deflecting Swat, Deadly Rollick, Chaos Warp sao staples de alto nivel

**O gap mais comum:** Protection (1.5 na media). Prosper custa 4 mana e e o unico motor do deck. Sem protecao, oponentes removem Prosper e o deck para completamente. O profile recomenda 8-12 interacoes, mas so ~2 sao protecao direta.

**Comparacao com outros engines:**
| Comandante | Engine Type | Resumo |
|:-----------|:------------|:-------|
| Prosper | Exile + Treasure | Gera treasure passivamente por conjurar do exile |
| Korvold | Sacrifice Value | Gera card advantage por sacrificar |
| Aesi | Landfall | Gera draw + land drop por jogar terrenos |
| Yuriko | Combat Flip | Gera dano por CMC das cartas reveladas |
| Winota | Combat Trigger | Gera tokens atacantes nao-Human que buscam Humans |
