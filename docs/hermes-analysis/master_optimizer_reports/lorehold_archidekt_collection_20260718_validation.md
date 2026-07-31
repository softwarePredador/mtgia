# Lorehold — melhor lista limitada à coleção Archidekt

- Fonte: `/Users/desenvolvimentomobile/Downloads/archidekt-collection-export-2026-07-18.csv`
- SHA-256 do CSV: `c9d97bb1cbd2425efcc65e297c7b1615bed10b336ee7ffae7a1ab85300c02473`
- Comandante: `Lorehold, the Historian`
- Resultado: melhor finalista defensável com as cartas do CSV, usando o deck 607 como benchmark protegido.
- Premissa: Lorehold não aparece no CSV e é fornecido separadamente pelo usuário.

## Decisão

O deck 607 continua sendo o melhor benchmark interno sem restrição de coleção, mas somente 77 de seus 99 slots de main deck estão disponíveis no CSV. O finalista preserva esses 77 slots e faz 22 substituições funcionais.

Pacote não terreno escolhido:

- `Mana Vault` e `Archaeomancer's Map` substituem os dois ramps ausentes.
- `Austere Command` substitui o wipe modal de `Farewell`.
- `Olórin's Searing Light` troca excesso de wipes por interação instantânea contra todos os oponentes.
- `Perch Protection` ocupa a macrofunção de tokens/fechamento de `Tempt with Bunnies` e adiciona uma janela de proteção.
- `Volcanic Vision` recupera uma mágica, limpa apenas as criaturas adversárias de forma condicional e possui execução nativa verificada.

Os 16 terrenos ausentes são substituídos por todos os sete terrenos reais adicionais disponíveis no CSV, mais cinco Mountains e quatro Plains adicionais. O resultado mantém 34 terrenos reais.

## Validação

| Verificação | Resultado |
| --- | --- |
| Tamanho | PASS — 99 main + 1 commander = 100 |
| Posse | PASS — 99/99 slots do main deck disponíveis |
| Singleton | PASS — somente Mountain ×9 e Plains ×8 repetem |
| Resolução | PASS — todos os IDs do CSV resolvidos; zero nomes do deck sem Oracle |
| Legalidade | PASS — zero banidas/ilegais no deck |
| Identidade de cor | PASS — zero cartas fora de RW |
| Memorabilia | PASS — `Arcane Signet // Arcane Signet` art-series ficou fora; usa-se o Arcane Signet normal |
| Mass land denial | PASS — Jokulhaups, Obliterate e Worldfire ficaram fora |
| Battle-rule coherence | PASS — 85/85 identidades, zero high/critical |
| Matriz Lorehold | `141.564`, intent alignment `100.0`, contra `139.038`/`99.547` do 607 |
| Bracket | Bracket 4 — Optimized; cinco Game Changers |

Game Changers: `Ancient Tomb`, `Jeska's Will`, `Mana Vault`, `Smothering Tithe` e `Teferi's Protection`.

A matriz foi recalculada com os valores de mana oficiais corrigidos para `Furygale Flocking` (10), `Improvisation Capstone` (7) e `Prismari Pianist` (3). A pontuação é prova estrutural comparativa, não prova estatística de superioridade em batalha.

## Estrutura e mãos

- 34 terrenos reais + 2 MDFCs jogáveis como terreno.
- 21 fontes vermelhas e 20 fontes brancas no auditor de mana.
- 17 básicos, tornando `Land Tax` e `Archaeomancer's Map` mais consistentes.
- 65 não terrenos no main: MV médio corrigido `3.923`; 25 com MV 0–2, 18 com MV 3–4 e 22 com MV 5+.
- 36 instants/sorceries, preservando o eixo de miracle do comandante.
- Chance exata de uma mão de sete conter 2–4 fontes de terreno, contando os MDFCs: `74.03%`.
- Chance de 0–1 fonte de terreno: `20.15%`.
- Até a terceira compra, chance de ver ao menos três fontes de terreno: `78.05%`.
- Até a quarta compra, chance de ver ao menos quatro fontes de terreno: `62.09%`.
- Acesso ao núcleo `Library of Leng` / `Scroll Rack` / `Sensei's Divining Top`: `19.94%` na mão inicial e `32.42%` nas primeiras 12 cartas.

O auditor conservador conta sete peças de fundação inicial contra alvo oito, pois trata `Archaeomancer's Map` como ramp contextual. Isso é o principal risco restante: a lista tem mana total suficiente, mas mãos com fontes colorless/narrow exigem mulligan disciplinado.

## Testes executados

- 22 testes Dart dos serviços de validação, reference readiness e swap candidates: PASS.
- 25 testes Python de strategy profile, variant matrix e battle-rule coherence: PASS.
- Auditoria isolada em cópia do SQLite; nenhuma escrita no PostgreSQL ou no deck 607.

## Limite da prova

Este finalista é a melhor lista collection-only validada estruturalmente hoje. Ele ainda não substitui o 607 como campeão de batalha: faltam quatro batches pareados novos, com os mesmos 12 oponentes/seeds, e síntese estatística persistida. Além disso, o runtime pode subestimar as habilidades utilitárias de `Arena of Glory`, `Boseiju, Who Shelters All`, `Cavern of Souls` e `Kor Haven`.

## Lista canônica — 100 cartas

```text
1 Lorehold, the Historian
1 Ancient Tomb
1 Approach of the Second Sun
1 Arcane Signet
1 Archaeomancer's Map
1 Arena of Glory
1 Arid Mesa
1 Artist's Talent
1 Austere Command
1 Avatar's Wrath
1 Bender's Waterskin
1 Big Score
1 Blasphemous Act
1 Bloodstained Mire
1 Boseiju, Who Shelters All
1 Call Forth the Tempest
1 Cavern of Souls
1 Clifftop Retreat
1 Command Tower
1 Creative Technique
1 Dawn's Truce
1 Deflecting Swat
1 Emeria's Call // Emeria, Shattered Skyclave
1 Esper Sentinel
1 Everything Comes to Dust
1 Fated Clash
1 Flawless Maneuver
1 Flooded Strand
1 Furygale Flocking
1 Generous Gift
1 Giver of Runes
1 Hexing Squelcher
1 High Noon
1 Hit the Mother Lode
1 Improvisation Capstone
1 Inspiring Vantage
1 Insurrection
1 Jeska's Will
1 Kor Haven
1 Land Tax
1 Library of Leng
1 Lightning Greaves
1 Mana Vault
1 Mizzix's Mastery
1 Molecule Man
1 Monument to Endurance
1 Mother of Runes
9 Mountain
1 Olórin's Searing Light
1 Path to Exile
1 Pearl Medallion
1 Perch Protection
1 Pinnacle Monk // Mystic Peak
8 Plains
1 Prismari Pianist
1 Promise of Loyalty
1 Redirect Lightning
1 Reforge the Soul
1 Rise of the Eldrazi
1 Ruby Medallion
1 Sacred Foundry
1 Scalding Tarn
1 Scroll Rack
1 Sensei's Divining Top
1 Smothering Tithe
1 Sol Ring
1 Storm Herd
1 Stroke of Midnight
1 Sundown Pass
1 Surge to Victory
1 Swiftfoot Boots
1 Swords to Plowshares
1 Talisman of Conviction
1 Teferi's Protection
1 The Mind Stone
1 The Scarlet Witch
1 Thor, God of Thunder
1 Tibalt's Trickery
1 Unexpected Windfall
1 Urza's Saga
1 Victory Chimes
1 Volcanic Vision
1 War Room
1 Winds of Abandon
1 Windswept Heath
```

## Fontes externas

- Commander: https://magic.wizards.com/en/formats/commander
- Notas oficiais de Lorehold e Library of Leng: https://magic.wizards.com/en/news/feature/secrets-of-strixhaven-release-notes
- Banimentos atuais: https://magic.wizards.com/en/banned-restricted-list
- Atualização de brackets de fevereiro de 2026: https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-february-9-2026
- API de coleção do Scryfall: https://scryfall.com/docs/api/cards/collection
- Corpus direcional de Lorehold: https://edhrec.com/commanders/lorehold-the-historian
