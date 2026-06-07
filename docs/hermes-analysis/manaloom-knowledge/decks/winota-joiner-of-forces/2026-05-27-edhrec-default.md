# Analise: Winota, Joiner of Forces — EDHREC Average Default

## Camada 1: Estrutura do Deck

### Meta
- **Comandante:** Winota, Joiner of Forces
- **Arquetipo:** aggro-stax / combat triggers / Humans
- **Estrategia central:** atacar com nao-Humanos baratos para disparar Winota e colocar Humans atacando sem pagar custo; os Humans sao simultaneamente dano, stax, protecao e payoff.
- **Bracket:** 4 para leitura cEDH/high-power, porque o profile referencia cEDH Decklist Database e Moxfield primer; o corpus EDHREC average e agregado de 12840 decks.
- **Fonte do deck:** https://edhrec.com/average-decks/winota-joiner-of-forces
- **Fonte live EDHREC:** https://edhrec.com/commanders/winota-joiner-of-forces
- **Fonte profile:** /opt/data/workspace/mtgia/server/test/artifacts/commander_reference_profile_anchor30_batch_a_2026-05-12/profiles/winota_joiner_of_forces.json
- **Fonte cEDH/primer:** cEDH DDB index confirmou "Winota Stax" e aponta Moxfield IDs `j-0aJlxuOUm9FnKRvJcfZw` e `vreLLzMBwk2e4UoyV7mZUw`; Moxfield direto retornou Cloudflare neste ambiente.

### Dados EDHREC reais
- **Amostra live EDHREC:** 12840 decks; rank EDHREC #149; salt score 1.849; avg price informado 1303.
- **Distribuicao de tipos EDHREC live:** creatures 46, instants 8, sorceries 3, artifacts 6, enchantments 4, lands 32.
- **Mana curve EDHREC live:** {'0': 3, '1': 14, '2': 18, '3': 18, '4': 6, '5': 3, '6': 3, '7': 1}.
- **Corpus local EDHREC default:** 85 linhas, `SUM(quantity)=100`, fonte `commander_reference_sprint2_2026-05-13`.

### Analise de Mana
- **CMC medio calculado com Scryfall:** 2.35 em 66 nao-terrenos.
- **Total de terrenos:** 34.
- **Ramp total multi-tag:** 10.
- **Profile real Winota:** lands 31-35; nonhuman_enablers 18-28; human_hits 16-24; stax_disruption 5-10; protection 5-8; interaction 6-10.
- **Validacao contra profile:** 34 lands fica dentro de 31-35; 24 Human hits no main deck ficam dentro de 16-24 (25 Humans se contar a comandante Winota); 22 nao-Humanos fica dentro de 18-28 antes de contar token makers.

### Distribuicao Funcional

| Funcao | Contagem real | Fonte |
|:--|--:|:--|
| Lands | 34 | Scryfall type_line + corpus EDHREC |
| Ramp | 10 | ManaLoom multi-tag via oracle Scryfall |
| Draw | 3 | ManaLoom multi-tag via oracle Scryfall |
| Removal | 8 | ManaLoom multi-tag via oracle Scryfall |
| Board wipes | 1 | ManaLoom multi-tag via oracle Scryfall |
| Protection | 10 | ManaLoom multi-tag via oracle Scryfall |
| Token makers | 11 | ManaLoom multi-tag via oracle Scryfall |
| Engine | 10 | ManaLoom multi-tag via oracle Scryfall |
| Human creatures | 25 | Scryfall type_line |
| Non-Human creatures | 22 | Scryfall type_line |

### Pacotes esperados do profile

| Pacote | Encontrado neste deck | Lista do profile |
|:--|--:|:--|
| Nonhuman enablers | 6/9 | Ornithopter, Gingerbrute, Goblin Rabblemaster, Legion Warboss, Aven Mindcensor, Loyal Apprentice |
| Human hits | 6/8 | Drannith Magistrate, Thalia, Guardian of Thraben, Ethersworn Canonist, Blade Historian, Angrath's Marauders, Imperial Recruiter |
| Stax | 2/7 | Deafening Silence, Magus of the Moon |
| Protection | 4/6 | Deflecting Swat, Boros Charm, Mother of Runes, Grand Abolisher |
| Combat payoffs | 3/6 | Professional Face-Breaker, Combat Celebrant, Goldnight Commander |

### Top cards EDHREC live
- **High Synergy Cards:** Blade Historian (11191/12840, synergy 0.77), Ornithopter (10106/12840, synergy 0.74), Angrath's Marauders (9977/12840, synergy 0.74), Lena, Selfless Champion (8997/12840, synergy 0.67), Loyal Apprentice (10241/12840, synergy 0.65)
- **Top Cards:** Swords to Plowshares (9706/12840, synergy 0.1), Ornithopter of Paradise (9101/12840, synergy 0.58), Deafening Silence (7718/12840, synergy 0.57), Path to Exile (7607/12840, synergy 0.02), Thalia, Guardian of Thraben (7604/12840, synergy 0.56)
- **Game Changers:** Drannith Magistrate (6406/12840, synergy 0.45), Ancient Tomb (3909/12840, synergy 0.23), Chrome Mox (3497/12840, synergy 0.23), Enlightened Tutor (3231/12840, synergy 0.1), Mana Vault (3074/12840, synergy 0.2)
- **Mana Artifacts:** Sol Ring (11878/12840, synergy 0.08), Arcane Signet (8915/12840, synergy -0.1), Talisman of Conviction (6367/12840, synergy -0.02), Boros Signet (4367/12840, synergy -0.16), Lotus Petal (4321/12840, synergy 0.29)

### Plano de Jogo
- **Turnos 1-3:** baixar enablers nao-Humanos de custo baixo, rocks e stax leve; objetivo e fazer Winota entrar com pelo menos um atacante pronto.
- **Turnos 4-6:** atacar, disparar Winota, converter hits Humanos em rule effects, protecao e dano dobrado.
- **Turnos 7+:** se a mesa estabiliza, usar combat payoffs e engines de token/treasure para manter pressao; sem Winota, o deck vira beatdown/stax RW de baixa compra.
- **Plano A:** trigger chain de Winota colocando Humans como Blade Historian/Angrath's Marauders/Combat Celebrant para dano explosivo.
- **Plano B:** aggro-stax: Drannith Magistrate, Thalia, Archon, Deafening Silence/High Noon atrasam oponentes enquanto criaturas pequenas reduzem vida.
- **Plano C:** protecao/tempo com Grand Abolisher, Silence, Deflecting Swat, Boros Charm e removal barato para forcar uma janela de ataque.

---

## Camada 2: Psicologia do Deckbuilding

### Leituras carta-a-carta prioritarias

#### Winota, Joiner of Forces — ManaLoom real: `draw`; multi-tags: `protection`; peso: Alta

- **Fonte real:** Scryfall oracle + profile/corpus; inclusao EDHREC: commander.
- **O que faz:** Whenever a non-Human creature you control attacks, look at the top six cards of your library. You may put a Human creature card from among them onto the battlefield tapped and attacking. It gains indestructible until end
- **Por que esta neste deck:** E o motor: transforma ataques de nao-Humanos em Humans atacando do topo, criando assimetria de mana e cartas.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Nao ha substituto funcional no command zone; o plano depende do texto de Winota.
- **Staple vs escolha pessoal:** Escolha de pacote/meta.
#### Ornithopter — ManaLoom real: `creature`; multi-tags: `creature`; peso: Muito alta

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 78.7% (10106/12840).
- **O que faz:** Flying
- **Por que esta neste deck:** Existe para aumentar a densidade de triggers de Winota: nao-Humano barato ou produtor de corpos que atacam antes/depois de Winota.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Memnite / Phyrexian Walker (mesmo papel de corpo nao-Humano de custo zero; Memnite aparece no profile como enabler esperado).
- **Staple vs escolha pessoal:** Staple/consenso EDHREC.
#### Rograkh, Son of Rohgahh — ManaLoom real: `creature`; multi-tags: `creature`; peso: Alta

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 50.3% (6454/12840).
- **O que faz:** First strike, menace, trample
- **Por que esta neste deck:** Existe para aumentar a densidade de triggers de Winota: nao-Humano barato ou produtor de corpos que atacam antes/depois de Winota.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Ornithopter / Phyrexian Walker para custo zero; Signal Pest se o jogador aceitar pagar 1 mana por evasao e pump.
- **Staple vs escolha pessoal:** Staple/consenso EDHREC.
#### Gingerbrute — ManaLoom real: `creature`; multi-tags: `sacrifice_outlet, lifegain, enabler`; peso: Alta

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 65.7% (8442/12840).
- **O que faz:** Haste (This creature can attack and {T} as soon as it comes under your control.)
- **Por que esta neste deck:** Existe para aumentar a densidade de triggers de Winota: nao-Humano barato ou produtor de corpos que atacam antes/depois de Winota.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Signal Pest ou Phoenix Chick: ambos mantem evasao/pressao; Gingerbrute ganha valor por ser quase unblockable.
- **Staple vs escolha pessoal:** Staple/consenso EDHREC.
#### Goblin Rabblemaster — ManaLoom real: `creature`; multi-tags: `token_maker, payoff, enabler, engine`; peso: Alta

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 51.5% (6607/12840).
- **O que faz:** Other Goblin creatures you control attack each combat if able.
- **Por que esta neste deck:** Existe para aumentar a densidade de triggers de Winota: nao-Humano barato ou produtor de corpos que atacam antes/depois de Winota.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Legion Warboss / Loyal Apprentice: todos aumentam triggers de Winota por gerar atacantes nao-Humanos.
- **Staple vs escolha pessoal:** Staple/consenso EDHREC.
#### Legion Warboss — ManaLoom real: `creature`; multi-tags: `token_maker, enabler, engine`; peso: Muito alta

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 70.5% (9046/12840).
- **O que faz:** Mentor (Whenever this creature attacks, put a +1/+1 counter on target attacking creature with lesser power.)
- **Por que esta neste deck:** Existe para aumentar a densidade de triggers de Winota: nao-Humano barato ou produtor de corpos que atacam antes/depois de Winota.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Goblin Rabblemaster / Dragon Fodder; Warboss e melhor quando mentor importa, Dragon Fodder e mais descartavel.
- **Staple vs escolha pessoal:** Staple/consenso EDHREC.
#### Loyal Apprentice — ManaLoom real: `creature`; multi-tags: `token_maker, enabler, engine`; peso: Muito alta

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 79.8% (10241/12840).
- **O que faz:** Haste
- **Por que esta neste deck:** Existe para aumentar a densidade de triggers de Winota: nao-Humano barato ou produtor de corpos que atacam antes/depois de Winota.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Goblin Rabblemaster / Legion Warboss; Apprentice exige comandante em campo, mas gera Thopter evasivo.
- **Staple vs escolha pessoal:** Staple/consenso EDHREC.
#### Blade Historian — ManaLoom real: `creature`; multi-tags: `creature`; peso: Muito alta

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 87.2% (11191/12840).
- **O que faz:** Attacking creatures you control have double strike.
- **Por que esta neste deck:** E um hit de Winota: entra atacando sem pagar o custo normal e converte o trigger em stax, protecao ou dano.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Aurelia, the Warleader / Adriana, Captain of the Guard (ambas no profile como combat payoffs); Historian e mais compacto em mana.
- **Staple vs escolha pessoal:** Staple/consenso EDHREC.
#### Angrath's Marauders — ManaLoom real: `creature`; multi-tags: `creature`; peso: Muito alta

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 77.7% (9977/12840).
- **O que faz:** If a source you control would deal damage to a permanent or player, it deals double that damage to that permanent or player instead.
- **Por que esta neste deck:** E um hit de Winota: entra atacando sem pagar o custo normal e converte o trigger em stax, protecao ou dano.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Aurelia, the Warleader / Shared Animosity: alternativas de explosao de combate citadas no pacote de combat_payoffs.
- **Staple vs escolha pessoal:** Staple/consenso EDHREC.
#### Drannith Magistrate — ManaLoom real: `creature`; multi-tags: `creature`; peso: Alta

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 49.9% (6406/12840).
- **O que faz:** Your opponents can't cast spells from anywhere other than their hands.
- **Por que esta neste deck:** E um hit de Winota: entra atacando sem pagar o custo normal e converte o trigger em stax, protecao ou dano.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Eidolon of Rhetoric / Archon of Emeria se o medo for storm; Grafdigger's Cage/Rest in Peace aparecem no profile mas nao neste deck.
- **Staple vs escolha pessoal:** Escolha de pacote/meta.
#### Thalia, Guardian of Thraben — ManaLoom real: `creature`; multi-tags: `creature`; peso: Alta

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 59.2% (7604/12840).
- **O que faz:** First strike
- **Por que esta neste deck:** E um hit de Winota: entra atacando sem pagar o custo normal e converte o trigger em stax, protecao ou dano.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Thorn of Amethyst / Deafening Silence: tax/limite de spells; Thalia ganha por ser Human hit.
- **Staple vs escolha pessoal:** Staple/consenso EDHREC.
#### Archon of Emeria — ManaLoom real: `creature`; multi-tags: `creature`; peso: Alta

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 66.2% (8506/12840).
- **O que faz:** Flying
- **Por que esta neste deck:** Existe para aumentar a densidade de triggers de Winota: nao-Humano barato ou produtor de corpos que atacam antes/depois de Winota.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Eidolon of Rhetoric / High Noon: mesmo eixo Rule of Law; Archon e nao-Humano, entao tambem dispara Winota.
- **Staple vs escolha pessoal:** Staple/consenso EDHREC.
#### Deafening Silence — ManaLoom real: `enchantment`; multi-tags: `enchantment`; peso: Alta

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 60.1% (7718/12840).
- **O que faz:** Each player can't cast more than one noncreature spell each turn.
- **Por que esta neste deck:** Preenche slot de suporte do plano aggro-stax conforme corpus EDHREC/profile.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Rule of Law / High Noon (profile cita Rule of Law; deck usa High Noon tambem).
- **Staple vs escolha pessoal:** Staple/consenso EDHREC.
#### Grand Abolisher — ManaLoom real: `creature`; multi-tags: `creature`; peso: Alta

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 55.7% (7152/12840).
- **O que faz:** During your turn, your opponents can't cast spells or activate abilities of artifacts, creatures, or enchantments.
- **Por que esta neste deck:** E um hit de Winota: entra atacando sem pagar o custo normal e converte o trigger em stax, protecao ou dano.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Silence / Hope of Ghirapur / Ranger-Captain of Eos; Abolisher e Human hit e trava respostas no seu turno.
- **Staple vs escolha pessoal:** Staple/consenso EDHREC.
#### Boros Charm — ManaLoom real: `removal`; multi-tags: `removal, protection`; peso: Media/baixa

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 26.1% (3349/12840).
- **O que faz:** Choose one —
- **Por que esta neste deck:** Protege a janela critica em que Winota precisa atacar e resolver triggers.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Flawless Maneuver / Teferi's Protection; Boros Charm e mais barato e tambem pode finalizar com dano.
- **Staple vs escolha pessoal:** Escolha de pacote/meta.
#### Deflecting Swat — ManaLoom real: `utility`; multi-tags: `big_spell`; peso: Alta

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 39.1% (5015/12840).
- **O que faz:** If you control a commander, you may cast this spell without paying its mana cost.
- **Por que esta neste deck:** Preenche slot de suporte do plano aggro-stax conforme corpus EDHREC/profile.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Flawless Maneuver / Silence; Swat protege no stack sem mana se Winota esta em campo.
- **Staple vs escolha pessoal:** Escolha de pacote/meta.
#### Professional Face-Breaker — ManaLoom real: `ramp`; multi-tags: `ramp, exile_value, token_maker, engine`; peso: Alta

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 57.6% (7399/12840).
- **O que faz:** Menace
- **Por que esta neste deck:** Existe para aumentar a densidade de triggers de Winota: nao-Humano barato ou produtor de corpos que atacam antes/depois de Winota.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Goldnight Commander / Combat Celebrant; Face-Breaker converte combate em Treasure e card selection.
- **Staple vs escolha pessoal:** Staple/consenso EDHREC.
#### Combat Celebrant — ManaLoom real: `creature`; multi-tags: `creature`; peso: Muito alta

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 74.3% (9541/12840).
- **O que faz:** If this creature hasn't been exerted this turn, you may exert it as it attacks. When you do, untap all other creatures you control and after this phase, there is an additional combat phase. (An exerted creature won't unt
- **Por que esta neste deck:** E um hit de Winota: entra atacando sem pagar o custo normal e converte o trigger em stax, protecao ou dano.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Aurelia, the Warleader / Rionya, Fire Dancer; Celebrant da combate extra com corpo Human.
- **Staple vs escolha pessoal:** Staple/consenso EDHREC.
#### Sol Ring — ManaLoom real: `ramp`; multi-tags: `ramp`; peso: Muito alta

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 92.5% (11878/12840).
- **O que faz:** {T}: Add {C}{C}.
- **Por que esta neste deck:** Acelera Winota para entrar cedo; em Winota, velocidade inicial vale mais que card economy perfeita.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Mana Crypt/Mana Vault em bracket alto; Arcane Signet/Talisman em builds menos explosivos.
- **Staple vs escolha pessoal:** Staple/consenso EDHREC.
#### Chrome Mox — ManaLoom real: `ramp`; multi-tags: `ramp, artifact_synergy`; peso: Media/baixa

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 27.2% (3497/12840).
- **O que faz:** Imprint — When this artifact enters, you may exile a nonartifact, nonland card from your hand.
- **Por que esta neste deck:** Acelera Winota para entrar cedo; em Winota, velocidade inicial vale mais que card economy perfeita.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Mox Diamond / Lotus Petal / Simian Spirit Guide; Chrome troca carta por velocidade persistente.
- **Staple vs escolha pessoal:** Escolha de pacote/meta.
#### Swords to Plowshares — ManaLoom real: `removal`; multi-tags: `removal`; peso: Muito alta

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 75.6% (9706/12840).
- **O que faz:** Exile target creature. Its controller gains life equal to its power.
- **Por que esta neste deck:** Remove a peca que impede ataques/triggers; o deck nao quer jogo longo sem conectar combate.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Path to Exile / Skyclave Apparition; Swords e a resposta mais eficiente em W.
- **Staple vs escolha pessoal:** Staple/consenso EDHREC.
#### Imperial Recruiter — ManaLoom real: `tutor`; multi-tags: `tutor, draw, enabler`; peso: Alta

- **Fonte real:** EDHREC live inclusion/synergy; inclusao EDHREC: 39.7% (5098/12840).
- **O que faz:** When this creature enters, search your library for a creature card with power 2 or less, reveal it, put it into your hand, then shuffle.
- **Por que esta neste deck:** E um hit de Winota: entra atacando sem pagar o custo normal e converte o trigger em stax, protecao ou dano.
- **Medo/risco que resolve:** Sem esta carta, o deck perde uma camada: trigger density, stax/protecao ou explosao de combate.
- **Ambicao/oportunidade:** Quando aparece na janela certa, transforma um ataque pequeno em snowball: mais corpos, mais dano, mais tax ou mais mana.
- **Trade-off:** Slot dedicado ao plano linear Winota; o jogador abre mao de draw/removal generico para maximizar coerencia do comandante.
- **Alternativa real:** Recruiter of the Guard (profile) / Enlightened Tutor para buscar stax/artifacts; Recruiter preserva corpo Human.
- **Staple vs escolha pessoal:** Escolha de pacote/meta.

### Restante do deck por grupos funcionais
- **Mana base (34 lands):** escolhida para bater o range real do profile (31-35) e permitir Winota cedo; MDFC Shatterskull Smashing conta como land pela regra de validacao.
- **Pacote de nao-Humanos (22 criaturas nao-Humanas + 11 token makers):** revela medo principal do jogador: comprar Winota sem atacantes. O deck aceita cartas individualmente fracas porque cada corpo e uma roleta de Human hit.
- **Pacote de Humans (25 criaturas Human):** revela ambicao de transformar biblioteca em mao/campo. O jogador maximiza hits que sao bons quando trapaceados e ainda razoaveis se comprados.
- **Pacote stax/protecao:** revela que o jogador nao quer apenas ser rapido; quer reduzir a janela de resposta dos oponentes.

### Discrepancias com ManaLoom

| Carta | Tag ManaLoom real | Funcao contextual esperada | Evidencia | Impacto |
|:--|:--|:--|:--|:--|
| Winota, Joiner of Forces | draw | engine/enabler de mana cheat | Oracle Scryfall + profile themes `combat_triggers_humans` | Alto |
| Drannith Magistrate | creature | stax_disruption + Human hit | EDHREC Game Changers 49.9% (6406/12840) | Alto |
| Blade Historian | creature | combat_payoff | EDHREC High Synergy 87.2% (11191/12840) | Medio |

---

## Camada 3: Mental Model do Deckbuilder

### Personalidade do deck
- **Estilo:** agressivo-controlador. O deck ataca cedo, mas usa stax para impedir que a mesa jogue no mesmo eixo de velocidade.
- **Tolerancia a risco:** alta: aceita 1-drops/0-drops ruins isoladamente porque eles viram triggers de Winota.
- **Nivel de orcamento:** alto no agregado EDHREC; a pagina live informa avg price 1303 e inclui Game Changers como Chrome Mox, Ancient Tomb e Drannith Magistrate.
- **Foco principal:** densidade de enablers + qualidade dos hits, nao card advantage tradicional.

### O que este deck revela sobre como o jogador pensa
O jogador de Winota pensa em **biparticao**, nao em curva tradicional: metade do deck precisa iniciar triggers (nao-Humanos), e a outra metade precisa ser recompensa (Humans). A pergunta mental nao e "esta carta e boa?"; e "esta carta e boa quando revelada pela Winota ou quando ataca para revelar outra?". Isso explica por que Ornithopter e Phyrexian Walker, cartas fracas em abstrato, sao escolhas racionais.

O deck tambem revela uma psicologia de **janela curta**: em vez de comprar 8-12 cartas como midrange comum, ele quer que 1 ataque resolvido substitua varios turnos de draw. Stax como Drannith, Thalia, Archon, Deafening Silence e High Noon nao existe para travar indefinidamente; existe para comprar um unico turno em que Winota ataca sem ser punida.

### Principios de deckbuilding extraidos
1. **Decks de comandante-engine exigem metricas contextuais:** para Winota, creature_count so e util se separado em non-Human enablers e Human hits.
2. **Cartas ruins podem ser corretas quando sao boas no papel estrutural:** Ornithopter e ruim como card individual, mas excelente como trigger gratuito.
3. **Aggro-stax troca draw por compressao de tempo:** a vantagem vem de mana cheat e restricao dos oponentes, nao de card draw numerico.
4. **O melhor hit e aquele que tambem e castavel:** profile alerta contra Humans incastaveis; este deck usa muitos Humans de custo 2-4, mantendo plano B.

---

## Pesquisa de Contexto

### Sobre o Comandante
- EDHREC live lista 12840 decks para Winota e rank #149.
- O profile local tem confidence high, source_count 3 e fontes: https://edhrec.com/commanders/winota-joiner-of-forces, https://cedh-decklist-database.com/decklists/winota-joiner-of-forces/, https://www.moxfield.com/decks/9TqHgOD7p0ydnvFzZRY9og.
- O cEDH Decklist Database foi acessado via curl e tem entrada "Winota Stax" com links Moxfield; Moxfield direto retornou Cloudflare, entao nao foi usado para extrair decklist nesta execucao.

### Sobre o Meta
- EDHREC Game Changers mais presentes no comandante incluem Drannith Magistrate 49.9% (6406/12840), Ancient Tomb 30.4% (3909/12840), Chrome Mox 27.2% (3497/12840) e Enlightened Tutor 25.2% (3231/12840).
- Isso confirma que a leitura correta e bracket-aware/high-power, nao casual battlecruiser.

### Sobre Deckbuilding Theory
- O profile real define targets especificos ({'lands': {'min': 31, 'max': 35}, 'nonhuman_enablers': {'min': 18, 'max': 28}, 'human_hits': {'min': 16, 'max': 24}, 'stax_disruption': {'min': 5, 'max': 10}, 'protection': {'min': 5, 'max': 8}, 'combat_payoffs': {'min': 4, 'max': 8}, 'interaction': {'min': 6, 'max': 10}}) em vez de thresholds genericos. Portanto, qualquer avaliacao ManaLoom precisa usar `nonhuman_enablers`, `human_hits` e `stax_disruption`, nao apenas ramp/draw/removal.

---

## Insights e Descobertas

### Novos desta analise
- [x] Winota precisa de uma metrica bipartida: non-Human enablers vs Human hits.
- [x] O EDHREC default tem 34 lands, dentro do profile 31-35; logo lands baixas nao sao problema aqui.
- [x] Draw baixo (3) nao implica necessariamente deck ruim: Winota converte ataques em vantagem de campo.
- [x] Single-tag ManaLoom perde stax/payoff contextual em hits Humanos.

### Vocabulario do Dominio
- **Trigger density:** quantidade de corpos/efeitos que realmente disparam o comandante.
- **Human hit:** criatura Human que vale revelar com Winota.
- **Aggro-stax window:** turno curto em que stax impede resposta e combate resolve.

## Fontes
- https://edhrec.com/average-decks/winota-joiner-of-forces — 12702 decks avg, 85 entries, total_card_count=100
- https://edhrec.com/average-decks/winota-joiner-of-forces/humans — 303 decks avg, 81 entries, total_card_count=100
- https://edhrec.com/average-decks/winota-joiner-of-forces/hatebears — 928 decks avg, 86 entries, total_card_count=100
- https://edhrec.com/average-decks/winota-joiner-of-forces/budget — 1270 decks avg, 72 entries, total_card_count=100
- EDHREC live `__NEXT_DATA__`: https://edhrec.com/commanders/winota-joiner-of-forces — extraido em 2026-05-27 com `curl`, campos `num_decks_avg`, `panels.mana_curve`, `container.json_dict.cardlists`.
- Scryfall API: `https://api.scryfall.com/cards/named?exact=<card>` para as 85 linhas do deck.
- Profile local: `server/test/artifacts/commander_reference_profile_anchor30_batch_a_2026-05-12/profiles/winota_joiner_of_forces.json`.
- cEDH DDB index: https://cedh-decklist-database.com — entrada "Winota Stax" observada no HTML com links Moxfield.
