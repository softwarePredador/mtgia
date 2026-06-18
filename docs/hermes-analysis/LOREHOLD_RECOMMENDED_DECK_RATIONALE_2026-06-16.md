# Lorehold Recommended Deck Rationale - 2026-06-16

## Status

- Fonte primária: `docs/hermes-analysis/master_optimizer_reports/lorehold_canonical_snapshot_20260614.json`.
- Status do snapshot: `approved`, ação local `validated_only`; este arquivo documenta a recomendação, não aplica no app/PG.
- Deck id local Hermes: `6`; cartas: `100`; terrenos: `33`; CMC médio: `2.97`.
- WR documentado no servidor para o snapshot canônico: `87.3%`. Esse WR segue como evidência operacional, não verdade absoluta de qualidade.
- Decisão preservada: sem ban global de Mox. O deck aprendido de Lorehold evita `Chrome Mox`, `Mox Diamond` e `Mox Opal` por decisão de produto/teste; `Mox Amber` permanece porque depende de lendária e não exige descarte/imprint premium.
- Decisão canônica mantida: `Wheel of Misfortune` entrou no lugar de `Reforge the Soul`; `Plaza of Heroes` foi rejeitada e `Rise of the Eldrazi` permaneceu.

## Leitura rápida do plano

- Plano principal: Boros spellslinger/big-spell com proteção forte, wheels, rituais, cópias e finalizações explosivas.
- Plano secundário: linha `Dualcaster Mage` + mágicas de cópia; `Approach of the Second Sun`; `Aetherflux Reservoir`; dano amplificado com `Fiery Emancipation`/`Guttersnipe`; reset/finalização com `Worldfire` e big spells.
- Fragilidade esperada: mãos com bombas caras sem ramp/seleção devem mulligar; o deck precisa de decisão de mulligan e uso de fast mana rastreáveis no battle.

## Contagem por papel

- Board wipe (`board_wipe`): 2
- Comandante (`commander`): 1
- Compra/filtro (`draw`): 9
- Engine/combo (`engine`): 4
- Terreno/fixing (`land`): 33
- Proteção/stax (`protection`): 14
- Ramp/aceleração (`ramp`): 17
- Remoção (`removal`): 3
- Tutor/seleção (`tutor`): 5
- Suporte/revisar (`unknown`): 1
- Condição de vitória (`wincon`): 11

## Decklist importável

```text
1 Lorehold, the Historian
1 Ancient Den
1 Ancient Tomb
1 Arid Mesa
1 Battlefield Forge
1 Bloodstained Mire
1 City of Brass
1 Clifftop Retreat
1 Command Tower
1 Elegant Parlor
1 Flooded Strand
1 Gemstone Caverns
1 Great Furnace
1 Hall of Heliod's Generosity
1 Inspiring Vantage
1 Inventors' Fair
1 Mana Confluence
1 Marsh Flats
1 Mountain // Mountain
1 Needleverge Pathway // Pillarverge Pathway
1 Plains // Plains
1 Plateau
1 Prismatic Vista
1 Rugged Prairie
1 Sacred Foundry
1 Scalding Tarn
1 Spectator Seating
1 Sunbaked Canyon
1 Sunbillow Verge
1 Sundown Pass
1 Urza's Saga
1 War Room
1 Windswept Heath
1 Wooded Foothills
1 Lotus Petal
1 Mox Amber
1 Enlightened Tutor
1 Esper Sentinel
1 Faithless Looting
1 Gamble
1 Giver of Runes
1 Land Tax
1 Mana Vault
1 Mother of Runes
1 Orim's Chant
1 Path to Exile
1 Pyroblast
1 Rite of Flame
1 Sensei's Divining Top
1 Silence
1 Sol Ring
1 Swords to Plowshares
1 Arcane Signet
1 Boros Charm
1 Boros Signet
1 Drannith Magistrate
1 Fellwar Stone
1 Grand Abolisher
1 Lightning Greaves
1 Molten Duplication
1 Reverberate
1 Ruby Medallion
1 Scroll Rack
1 Talisman of Conviction
1 Twinflame
1 Birgi, God of Storytelling // Harnfel, Horn of Bounty
1 Deflecting Swat
1 Dualcaster Mage
1 Electroduplicate
1 Flawless Maneuver
1 Generous Gift
1 Guttersnipe
1 Heat Shimmer
1 Imperial Recruiter
1 Jeska's Will
1 Monument to Endurance
1 Ranger-Captain of Eos
1 Recruiter of the Guard
1 Reiterate
1 Seething Song
1 Teferi's Protection
1 Valakut Awakening // Valakut Stoneforge
1 Victory Chimes
1 Wheel of Fortune
1 Wheel of Misfortune
1 Aetherflux Reservoir
1 Mizzix's Mastery
1 Past in Flames
1 Smothering Tithe
1 Storm-Kiln Artist
1 The One Ring
1 Unexpected Windfall
1 Mana Geyser
1 Fiery Emancipation
1 Rite of the Dragoncaller
1 Approach of the Second Sun
1 Blasphemous Act
1 Worldfire
1 Storm Herd
1 Rise of the Eldrazi
```

## Racional carta a carta

| # | Carta | Papel | CMC | Por que entrou |
| ---: | --- | --- | ---: | --- |
| 1 | Lorehold, the Historian | Comandante | 5.0 | Comandante do teste: habilita o plano Boros spellslinger/big-spell, transforma sequência de mágicas em valor e define identidade RW do deck. |
| 2 | Ancient Den | Terreno/fixing | 0.0 | Land artefato branca; aumenta contagem de fontes e sinergia com artefatos/Inventors/Urza. |
| 3 | Ancient Tomb | Terreno/fixing | 0.0 | Fast mana em land slot; acelera rocks, tutors e big spells. |
| 4 | Arid Mesa | Terreno/fixing | 0.0 | Fetch para corrigir mana e alimentar shuffle com Top/Rack. |
| 5 | Battlefield Forge | Terreno/fixing | 0.0 | Dual land untapped Boros. |
| 6 | Bloodstained Mire | Terreno/fixing | 0.0 | Fetch para corrigir vermelho via Plateau/Sacred Foundry e shuffle. |
| 7 | City of Brass | Terreno/fixing | 0.0 | Fixing 5 cores irrelevante, mas entra untapped e gera qualquer cor. |
| 8 | Clifftop Retreat | Terreno/fixing | 0.0 | Dual Boros consistente. |
| 9 | Command Tower | Terreno/fixing | 0.0 | Fixing perfeito para commander. |
| 10 | Elegant Parlor | Terreno/fixing | 0.0 | Dual tipada; fetchável e útil para fixing. |
| 11 | Flooded Strand | Terreno/fixing | 0.0 | Fetch para Plateau/Sacred Foundry/Elegant Parlor. |
| 12 | Gemstone Caverns | Terreno/fixing | 0.0 | Aceleração no draw e fixing em mesas rápidas. |
| 13 | Great Furnace | Terreno/fixing | 0.0 | Land artefato vermelha; sinergia artefato e fonte vermelha. |
| 14 | Hall of Heliod's Generosity | Terreno/fixing | 0.0 | Recupera enchantments-chave como Fiery Emancipation. |
| 15 | Inspiring Vantage | Terreno/fixing | 0.0 | Dual untapped cedo. |
| 16 | Inventors' Fair | Terreno/fixing | 0.0 | Tutor/valor para artefatos como Aetherflux, The One Ring e rocks. |
| 17 | Mana Confluence | Terreno/fixing | 0.0 | Fixing untapped universal. |
| 18 | Marsh Flats | Terreno/fixing | 0.0 | Fetch para Plateau/Sacred Foundry/Elegant Parlor. |
| 19 | Mountain // Mountain | Terreno/fixing | 0.0 | Fonte básica vermelha para resiliência contra hate e fetch/ramp simples. |
| 20 | Needleverge Pathway // Pillarverge Pathway | Terreno/fixing | 0.0 | Dual modal untapped. |
| 21 | Plains // Plains | Terreno/fixing | 0.0 | Fonte básica branca para resiliência contra hate. |
| 22 | Plateau | Terreno/fixing | 0.0 | Dual original fetchável Boros. |
| 23 | Prismatic Vista | Terreno/fixing | 0.0 | Fetch flexível para básicos e shuffle. |
| 24 | Rugged Prairie | Terreno/fixing | 0.0 | Filtro Boros para corrigir custos duplos. |
| 25 | Sacred Foundry | Terreno/fixing | 0.0 | Dual fetchável Boros. |
| 26 | Scalding Tarn | Terreno/fixing | 0.0 | Fetch para fontes vermelhas/brancas via duals. |
| 27 | Spectator Seating | Terreno/fixing | 0.0 | Dual commander multiplayer quase sempre untapped. |
| 28 | Sunbaked Canyon | Terreno/fixing | 0.0 | Land que vira card quando flooda. |
| 29 | Sunbillow Verge | Terreno/fixing | 0.0 | Fonte Boros moderna aprendida nos decks importados. |
| 30 | Sundown Pass | Terreno/fixing | 0.0 | Dual Boros consistente no midgame. |
| 31 | Urza's Saga | Terreno/fixing | 0.0 | Busca Sol Ring/Top/Petal e cria pressão/valor. |
| 32 | War Room | Terreno/fixing | 0.0 | Card draw em land slot. |
| 33 | Windswept Heath | Terreno/fixing | 0.0 | Fetch para duals/básicos. |
| 34 | Wooded Foothills | Terreno/fixing | 0.0 | Fetch para fontes vermelhas/brancas via duals. |
| 35 | Lotus Petal | Ramp/aceleração | 0.0 | Fast mana de baixo custo; acelera turnos de combo sem depender dos Mox removidos. |
| 36 | Mox Amber | Ramp/aceleração | 0.0 | Mantido porque ainda é menos problemático que Mox Diamond/Opal/Chrome e pode ligar com comandante/legends. |
| 37 | Enlightened Tutor | Tutor/seleção | 1.0 | Tutor barato para Aetherflux, Fiery Emancipation, The One Ring, Scroll Rack, Sol Ring e peças-chave. |
| 38 | Esper Sentinel | Compra/filtro | 1.0 | Draw/tax cedo; uma das melhores formas de compensar Boros em mesa multiplayer. |
| 39 | Faithless Looting | Compra/filtro | 1.0 | Filtra mão e abastece graveyard para Mizzix's Mastery/Past in Flames. |
| 40 | Gamble | Tutor/seleção | 1.0 | Tutor vermelho eficiente para buscar combo/wincon; sinergiza com recursion/graveyard. |
| 41 | Giver of Runes | Proteção/stax | 1.0 | Protege comandante e criaturas-chave como Dualcaster/Guttersnipe/Grand Abolisher. |
| 42 | Land Tax | Tutor/seleção | 1.0 | Garante land drops, melhora mãos iniciais e alimenta filtros/descartes. |
| 43 | Mana Vault | Ramp/aceleração | 1.0 | Fast mana de alto impacto para big spells. |
| 44 | Mother of Runes | Proteção/stax | 1.0 | Proteção barata e recorrente para peças-chave. |
| 45 | Orim's Chant | Proteção/stax | 1.0 | Proteção de combo; impede interação no turno decisivo. |
| 46 | Path to Exile | Remoção | 1.0 | Remoção eficiente para criatura problemática. |
| 47 | Pyroblast | Proteção/stax | 1.0 | Proteção/interação barata contra azul, essencial em mesas com counters. |
| 48 | Rite of Flame | Ramp/aceleração | 1.0 | Ritual barato para acelerar combo/big spell. |
| 49 | Sensei's Divining Top | Compra/filtro | 1.0 | Topdeck control para Approach, consistência e seleção. |
| 50 | Silence | Proteção/stax | 1.0 | Proteção de combo; fecha janela de interação dos oponentes. |
| 51 | Sol Ring | Suporte/revisar | 1.0 | Ramp obrigatório e mais frequente no corpus. |
| 52 | Swords to Plowshares | Remoção | 1.0 | Melhor remoção branca eficiente. |
| 53 | Arcane Signet | Ramp/aceleração | 2.0 | Ramp universal e consistente; apareceu muito no corpus e corrige mana cedo. |
| 54 | Boros Charm | Proteção/stax | 2.0 | Proteção contra wipes, dano final ocasional e flexibilidade por custo baixo. |
| 55 | Boros Signet | Ramp/aceleração | 2.0 | Ramp estável e redundância de aceleração sem usar Mox premium. |
| 56 | Drannith Magistrate | Proteção/stax | 2.0 | Peça stax para travar commanders/casts externos enquanto montamos combo. |
| 57 | Fellwar Stone | Ramp/aceleração | 2.0 | Substituto budget/limpo para Mox premium; mantém densidade de ramp de 2 mana. |
| 58 | Grand Abolisher | Proteção/stax | 2.0 | Fecha janelas de interação no turno de combo/big spell. |
| 59 | Lightning Greaves | Proteção/stax | 2.0 | Adicionado no lugar de Mox premium; protege comandante/criaturas-chave e dá haste quando relevante. |
| 60 | Molten Duplication | Condição de vitória | 2.0 | Redundância de copy-combo com Dualcaster. |
| 61 | Reverberate | Engine/combo | 2.0 | Redundância de copy spell; protege/duplica big spells e aumenta pacote Dualcaster. |
| 62 | Ruby Medallion | Ramp/aceleração | 2.0 | Redutor de custo para rituais/spells vermelhas e linhas de storm. |
| 63 | Scroll Rack | Compra/filtro | 2.0 | Combina com Land Tax e Approach; melhora seleção de topo. |
| 64 | Talisman of Conviction | Ramp/aceleração | 2.0 | Ramp de 2 mana consistente nas cores do deck. |
| 65 | Twinflame | Condição de vitória | 2.0 | Peça essencial do combo com Dualcaster Mage. |
| 66 | Birgi, God of Storytelling // Harnfel, Horn of Bounty | Ramp/aceleração | 3.0 | Engine de mana para turnos explosivos com ritual/spellslinger; melhora storm e big spells. |
| 67 | Deflecting Swat | Proteção/stax | 3.0 | Proteção de stack para wincons e comandante; forte em turnos de all-in. |
| 68 | Dualcaster Mage | Engine/combo | 3.0 | Peça central do pacote copy-combo; combina com Twinflame/Heat Shimmer/Molten Duplication/Electroduplicate. |
| 69 | Electroduplicate | Condição de vitória | 3.0 | Peça de cópia para habilitar linhas com Dualcaster e redundância de combo. |
| 70 | Flawless Maneuver | Proteção/stax | 3.0 | Proteção gratuita para segurar board/combo em turnos críticos. |
| 71 | Generous Gift | Remoção | 3.0 | Resposta universal para permanentes problemáticas. |
| 72 | Guttersnipe | Condição de vitória | 3.0 | Peça de wincon incremental; fica letal com Fiery Emancipation e sequência de spells. |
| 73 | Heat Shimmer | Condição de vitória | 3.0 | Peça de combo com Dualcaster Mage e redundância de Twinflame. |
| 74 | Imperial Recruiter | Tutor/seleção | 3.0 | Busca Dualcaster, Grand Abolisher, Esper Sentinel e outras criaturas-chave. |
| 75 | Jeska's Will | Ramp/aceleração | 3.0 | Ritual + card advantage; um dos melhores aceleradores do corpus. |
| 76 | Monument to Endurance | Ramp/aceleração | 3.0 | Engine de valor/descartes recorrente do pacote Lorehold aprendido. |
| 77 | Ranger-Captain of Eos | Proteção/stax | 3.0 | Tutor/proteção de stack: sacrifica para travar respostas no turno de combo. |
| 78 | Recruiter of the Guard | Tutor/seleção | 3.0 | Busca peças-chave de baixa força, especialmente Dualcaster/Grand Abolisher/Giver. |
| 79 | Reiterate | Engine/combo | 3.0 | Peça de cópia e potencial combo com Mana Geyser/rituais. |
| 80 | Seething Song | Ramp/aceleração | 3.0 | Ritual para alcançar Mizzix/Rise/Worldfire e sequências de spells. |
| 81 | Teferi's Protection | Proteção/stax | 3.0 | Proteção premium para sobreviver e proteger setups all-in. |
| 82 | Valakut Awakening // Valakut Stoneforge | Compra/filtro | 3.0 | Filtro de mão em slot de land/spell; melhora consistência. |
| 83 | Victory Chimes | Compra/filtro | 3.0 | Substituto de Mox premium; aceleração política e mana extra em multiplayer. |
| 84 | Wheel of Fortune | Compra/filtro | 3.0 | Recarga explosiva de mão e graveyard para Past/Mizzix. |
| 85 | Wheel of Misfortune | Compra/filtro | 3.0 | Substitui Reforge the Soul no snapshot canônico: mantém o pacote de wheel/draw explosivo, alimenta graveyard para Past in Flames/Mizzix e evita depender de milagre para ser eficiente. |
| 86 | Aetherflux Reservoir | Condição de vitória | 4.0 | Win condition alternativa para linhas de storm/ritual: transforma sequência longa de spells em kill imediato. |
| 87 | Mizzix's Mastery | Condição de vitória | 4.0 | Uma das wincons/engines mais importantes: converte graveyard cheio em turno explosivo. |
| 88 | Past in Flames | Engine/combo | 4.0 | Redundância de graveyard storm para recastar rituais e interação. |
| 89 | Smothering Tithe | Ramp/aceleração | 4.0 | Ramp/treasure de alto impacto, aparece bastante no corpus. |
| 90 | Storm-Kiln Artist | Ramp/aceleração | 4.0 | Engine de treasure para spellslinger/ritual chains. |
| 91 | The One Ring | Compra/filtro | 4.0 | Card advantage e proteção temporária; muito presente nos melhores decks importados. |
| 92 | Unexpected Windfall | Ramp/aceleração | 4.0 | Ritual/card draw: descarta, compra e gera treasure. |
| 93 | Mana Geyser | Ramp/aceleração | 5.0 | Ritual explosivo em multiplayer; permite Rise/Worldfire/Mizzix turnos grandes. |
| 94 | Fiery Emancipation | Condição de vitória | 6.0 | Wincon de dano amplificado; pacote validado com Guttersnipe e spells de dano. |
| 95 | Rite of the Dragoncaller | Condição de vitória | 6.0 | Wincon #1 do Oracle; incluída como prioridade principal aprendida. |
| 96 | Approach of the Second Sun | Condição de vitória | 7.0 | Win condition alternativa que combina com Scroll Rack/Sensei's Divining Top para acelerar o segundo cast. |
| 97 | Blasphemous Act | Board wipe | 9.0 | Board wipe eficiente que ajuda a sobreviver até os turnos de big spell. |
| 98 | Worldfire | Board wipe | 9.0 | Wincon/reset de alto impacto, validado pelo catálogo como pacote separado. |
| 99 | Storm Herd | Condição de vitória | 10.0 | Wincon go-wide aprendida dos decks big spell; alternativa ao plano combo. |
| 100 | Rise of the Eldrazi | Proteção/stax | 12.0 | Big spell wincon de alta resiliência, muito frequente nos decks aprendidos. |

## Pontos de validação antes de promover

- Rodar geração/validação Lorehold com o backend atual e confirmar 1 comandante, 99 main deck e identidade RW.
- Rodar replay/battle com decision trace e confirmar que `Lotus Petal`, `Mox Amber`, wheels e bombas caras só são usados com payoff rastreável.
- Usar `docs/hermes-analysis/LOREHOLD_BATTLE_MODEL_COVERAGE_MATRIX_2026-06-16.md` para separar carta hard-modelled de carta ainda `needs_review`.
- Não reintroduzir `Chrome Mox`, `Mox Diamond` ou `Mox Opal` no learned deck 82 sem nova rodada explícita de produto, regra e replay.
- Se qualquer carta de custo 8+ aparecer em mão inicial sem ramp/seleção, a heurística de mulligan deve justificar keep ou mulligan no trace.

## Artefatos relacionados

- `docs/hermes-analysis/master_optimizer_reports/lorehold_canonical_snapshot_20260614.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_canonical_snapshot_20260614.md`
- `docs/hermes-analysis/manaloom-knowledge/LOREHOLD_BEST_OF_LEARNED_NO_MOX_CARD_RATIONALE.md`
- `docs/hermes-analysis/LOREHOLD_BATTLE_MODEL_COVERAGE_MATRIX_2026-06-16.md`
