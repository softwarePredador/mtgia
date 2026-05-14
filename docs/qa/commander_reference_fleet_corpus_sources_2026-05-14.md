# Commander Reference Fleet Corpus Sources - 2026-05-14

## Resultado

**PASS_WITH_RISKS** para pesquisa e selecao de fontes publicas candidatas.

Foram encontrados corpora publicos de alta qualidade para os 12 comandantes da
fleet candidata, com 4-5 paginas EDHREC Average Deck ou equivalentes EDHREC
tematicos por comandante. Nenhuma decklist completa foi salva nesta etapa, nenhum
codigo foi alterado e nenhuma mudanca de banco foi aplicada.

## Escopo

- Incluido: leitura de trackers/relatorios atuais, validacao web de baixo volume,
  prova de contexto Commander por fonte publica, estimativa de 3-5 decks/fontes por
  comandante, riscos de cartas novas, riscos de scraping e recomendacao por
  comandante.
- Fora do escopo: salvar decklists completas, criar artifacts de corpus JSON,
  inserir em `commander_reference_decks`, gravar em
  `external_commander_meta_candidates`, aplicar migrations, alterar runtime,
  alterar app, alterar endpoints ou expor secrets.

## Fontes locais lidas

- `ROADMAP.md`
- `docs/CONTEXTO_PRODUTO_ATUAL.md`
- `server/doc/META_DECK_INTELLIGENCE_AGENT_2026-04-23.md`
- `server/doc/RELATORIO_META_DECK_INTELLIGENCE_2026-04-23.md`
- `server/doc/EXTERNAL_COMMANDER_META_CANDIDATES_WORKFLOW_2026-04-23.md`
- `server/doc/RELATORIO_COMMANDER_ONLY_OPTIMIZATION_VALIDATION_2026-04-21.md`
- `server/doc/COMMANDER_REFERENCE_SPRINT3_TRACKER_2026-05-13.md`
- `server/doc/COMMANDER_REFERENCE_SPRINT3_LOT_B_PLAN_2026-05-14.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_B_PUBLIC_PROOF_2026-05-14.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_C_CORPUS_PREP_2026-05-14.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_C_PUBLIC_PROOF_2026-05-14.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_DECK_CORPUS_V1_2026-05-12.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_DECK_CORPUS_EDGAR_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_DECK_CORPUS_PROSPER_2026-05-13.md`
- `server/test/fixtures/optimization_resolution_corpus.json`

## Comandos e consultas executadas

Sem secrets, sem banco e sem escrita de decklists:

```bash
git --no-pager status --short --branch
find docs server/doc .github/instructions -maxdepth 3 -type f ...
rg -n "Atraxa|Miirym|Kaalia|Prosper|12 candidatos|..." server/doc docs server/test/fixtures .github/agents
curl -sS --max-time 20 -A ManaLoomResearch/1.0 "https://api.scryfall.com/cards/named?exact=<commander>"
python3 <low_volume_edhrec_probe>
```

O probe EDHREC registrou apenas status HTTP, titulo da pagina, presenca do rotulo
`Average Deck` e `total_card_count=100`. As listas de cartas das paginas nao foram
persistidas no repositorio.

## Fatos locais/database comprovados

- O produto continua `Commander-first`; fontes externas devem enriquecer o core de
  gerar/analisar/otimizar decks, nao substituir validacao local.
- `server/test/fixtures/optimization_resolution_corpus.json` contem os 12
  candidatos abaixo como seeds ja estabilizados dentro do corpus de resolucao.
- `RELATORIO_COMMANDER_ONLY_OPTIMIZATION_VALIDATION_2026-04-21.md` registrou
  `19/19 passed`, incluindo esses 12 comandantes.
- O runner de corpus completo exige gates objetivos antes de qualquer apply:
  comandante resolvido, comandante quantidade 1, main 99, `unresolved=0`,
  `off_color=0` e singleton limpo fora de terrenos basicos.
- A politica vigente classifica EDHREC como `enrichment-only` para
  `external_commander_meta_candidates`; portanto estas URLs sao candidatas para
  curadoria offline/reference corpus, nao para staging automatico em `meta_decks`.
- Nada foi escrito no banco nesta etapa.

## Achados web-derived

- Scryfall `cards/named` retornou `legalities.commander=legal` para todos os 12
  comandantes e confirmou identidade de cor/tipo lendario.
- As paginas EDHREC Average Deck aceitas retornaram HTTP 200, titulo
  `Average Deck for <commander>` e `total_card_count=100`.
- A pagina `https://edhrec.com/average-decks/atraxa-praetors-voice/superfriends`
  foi sondada, mas ficou fora do conjunto por erro HTTP no probe atual.
- Nao foi provada nesta etapa a validade de decklists individuais de Moxfield,
  Archidekt ou TopDeck para estes 12 comandantes. Para esse nivel, o status aqui e
  `not proven`.

## Matriz de candidatos

| Commander | Prova Commander web | URLs candidatas para 3-5 decks/fontes | Estimativa | Risco cartas novas | Risco scraping | Recomendacao |
| --- | --- | --- | --- | --- | --- | --- |
| `Atraxa, Praetors' Voice` | Scryfall legal Commander; EDHREC Average Deck 100 cartas. | `https://edhrec.com/average-decks/atraxa-praetors-voice`; `https://edhrec.com/average-decks/atraxa-praetors-voice/optimized`; `https://edhrec.com/average-decks/atraxa-praetors-voice/infect`; `https://edhrec.com/average-decks/atraxa-praetors-voice/proliferate` | 4 fontes aproveitaveis agora; 5a fonte precisa alternativa porque `/superfriends` nao provou no probe. | Medio: proliferate, poison e counters recebem suporte recorrente. | Medio: EDHREC respondeu, mas e fonte nao oficial para automacao. | **PASS_WITH_RISKS** |
| `Muldrotha, the Gravetide` | Scryfall legal Commander; EDHREC Average Deck 100 cartas. | `https://edhrec.com/average-decks/muldrotha-the-gravetide`; `https://edhrec.com/average-decks/muldrotha-the-gravetide/optimized`; `https://edhrec.com/average-decks/muldrotha-the-gravetide/lands`; `https://edhrec.com/average-decks/muldrotha-the-gravetide/mill`; `https://edhrec.com/average-decks/muldrotha-the-gravetide/budget` | 5 fontes. | Medio: permanentes de cemiterio, lands e self-mill mudam com sets novos. | Medio. | **PASS** |
| `Sythis, Harvest's Hand` | Scryfall legal Commander; EDHREC Average Deck 100 cartas; ja promovida no Sprint 3 Lote B. | `https://edhrec.com/average-decks/sythis-harvests-hand`; `https://edhrec.com/average-decks/sythis-harvests-hand/optimized`; `https://edhrec.com/average-decks/sythis-harvests-hand/enchantress`; `https://edhrec.com/average-decks/sythis-harvests-hand/budget`; `https://edhrec.com/average-decks/sythis-harvests-hand/auras` | 5 fontes. | Medio: enchantress e auras recebem cartas frequentes; separar value de Voltron. | Medio; provas publicas anteriores ja observaram 429 em lote. | **PASS** |
| `Isshin, Two Heavens as One` | Scryfall legal Commander; EDHREC Average Deck 100 cartas. | `https://edhrec.com/average-decks/isshin-two-heavens-as-one`; `https://edhrec.com/average-decks/isshin-two-heavens-as-one/optimized`; `https://edhrec.com/average-decks/isshin-two-heavens-as-one/tokens`; `https://edhrec.com/average-decks/isshin-two-heavens-as-one/samurai`; `https://edhrec.com/average-decks/isshin-two-heavens-as-one/budget` | 5 fontes. | Medio: ataques, tokens e Samurai recebem suporte desigual; risco de goodstuff Mardu. | Medio. | **PASS** |
| `Krenko, Mob Boss` | Scryfall legal Commander; EDHREC Average Deck 100 cartas; ja promovido no Sprint 3 Lote A. | `https://edhrec.com/average-decks/krenko-mob-boss`; `https://edhrec.com/average-decks/krenko-mob-boss/optimized`; `https://edhrec.com/average-decks/krenko-mob-boss/goblins`; `https://edhrec.com/average-decks/krenko-mob-boss/tokens`; `https://edhrec.com/average-decks/krenko-mob-boss/budget` | 5 fontes. | Baixo-medio: Goblins e haste sao shell maduro, mas novos token makers podem entrar. | Medio. | **PASS** |
| `Urza, Lord High Artificer` | Scryfall legal Commander; EDHREC Average Deck 100 cartas; ja promovido no Sprint 3 Lote B. | `https://edhrec.com/average-decks/urza-lord-high-artificer`; `https://edhrec.com/average-decks/urza-lord-high-artificer/optimized`; `https://edhrec.com/average-decks/urza-lord-high-artificer/artifacts`; `https://edhrec.com/average-decks/urza-lord-high-artificer/combo`; `https://edhrec.com/average-decks/urza-lord-high-artificer/budget` | 5 fontes, mas separar budget/casual de combo. | Alto: artifacts, combo, fast mana e banlist mudam a leitura de poder. | Medio-alto: risco de cEDH/stax contaminando casual; usar baixo volume e backoff. | **PASS_WITH_RISKS** |
| `Edgar Markov` | Scryfall legal Commander; EDHREC Average Deck 100 cartas; corpus Edgar ja documentado e promovido. | `https://edhrec.com/average-decks/edgar-markov`; `https://edhrec.com/average-decks/edgar-markov/optimized`; `https://edhrec.com/average-decks/edgar-markov/vampires`; `https://edhrec.com/average-decks/edgar-markov/budget`; `https://edhrec.com/average-decks/edgar-markov/aristocrats` | 5 fontes; corpus anterior usou 4 e pode ser expandido com aristocrats. | Medio: Vampires recebem suporte periodico; Eminence puxa vies high-power. | Medio. | **PASS** |
| `Miirym, Sentinel Wyrm` | Scryfall legal Commander; EDHREC Average Deck 100 cartas. | `https://edhrec.com/average-decks/miirym-sentinel-wyrm`; `https://edhrec.com/average-decks/miirym-sentinel-wyrm/optimized`; `https://edhrec.com/average-decks/miirym-sentinel-wyrm/dragons`; `https://edhrec.com/average-decks/miirym-sentinel-wyrm/budget`; `https://edhrec.com/average-decks/miirym-sentinel-wyrm/clones` | 5 fontes. | Medio: Dragon typal, copy effects e ramp recebem upgrades frequentes e caros. | Medio. | **PASS** |
| `Meren of Clan Nel Toth` | Scryfall legal Commander; EDHREC Average Deck 100 cartas; ja promovida no Sprint 3 Lote B. | `https://edhrec.com/average-decks/meren-of-clan-nel-toth`; `https://edhrec.com/average-decks/meren-of-clan-nel-toth/optimized`; `https://edhrec.com/average-decks/meren-of-clan-nel-toth/aristocrats`; `https://edhrec.com/average-decks/meren-of-clan-nel-toth/sacrifice`; `https://edhrec.com/average-decks/meren-of-clan-nel-toth/budget` | 5 fontes. | Baixo-medio: recursion/sacrifice e toolbox sao maduros, mas novos engines entram. | Medio. | **PASS** |
| `Korvold, Fae-Cursed King` | Scryfall legal Commander; EDHREC Average Deck 100 cartas; retry promovido no Sprint 3 Lote B. | `https://edhrec.com/average-decks/korvold-fae-cursed-king`; `https://edhrec.com/average-decks/korvold-fae-cursed-king/optimized`; `https://edhrec.com/average-decks/korvold-fae-cursed-king/treasure`; `https://edhrec.com/average-decks/korvold-fae-cursed-king/aristocrats`; `https://edhrec.com/average-decks/korvold-fae-cursed-king/budget` | 5 fontes, mas precisa lane explicita. | Alto: treasure/sacrifice/combo e banlist afetam muito a qualidade. | Medio-alto: high-power/cEDH e treasure-combo podem poluir bracket casual. | **PASS_WITH_RISKS** |
| `Kaalia of the Vast` | Scryfall legal Commander; EDHREC Average Deck 100 cartas. | `https://edhrec.com/average-decks/kaalia-of-the-vast`; `https://edhrec.com/average-decks/kaalia-of-the-vast/optimized`; `https://edhrec.com/average-decks/kaalia-of-the-vast/angels`; `https://edhrec.com/average-decks/kaalia-of-the-vast/demons`; `https://edhrec.com/average-decks/kaalia-of-the-vast/dragons` | 5 fontes. | Medio: novos Angels/Demons/Dragons podem trocar topo de curva; risco de curva pesada. | Medio-alto: comandante popular e paginas de hosts publicos podem acionar rate limit em coleta larga. | **PASS_WITH_RISKS** |
| `Prosper, Tome-Bound` | Scryfall legal Commander; EDHREC Average Deck 100 cartas; corpus Prosper ja documentado e promovido. | `https://edhrec.com/average-decks/prosper-tome-bound`; `https://edhrec.com/average-decks/prosper-tome-bound/optimized`; `https://edhrec.com/average-decks/prosper-tome-bound/treasure`; `https://edhrec.com/average-decks/prosper-tome-bound/exile`; `https://edhrec.com/average-decks/prosper-tome-bound/artifacts` | 5 fontes; corpus anterior usou optimized/control/cedh/artifacts, esta matriz adiciona default/treasure/exile como alternativas. | Alto: exile-cast e treasure recebem suporte constante; cEDH pode contaminar casual. | Medio-alto: manter `cedh` separado de bracket casual. | **PASS_WITH_RISKS** |

## Interpretacao estrategica por comandante

- `Atraxa, Praetors' Voice`: proliferate/counters/superfriends/infect querem
  acumular vantagem incremental e transformar marcadores em inevitabilidade. Para
  ManaLoom, absorver como pacotes separados; nao deixar infect ou planeswalkers
  virarem default sem intencao do usuario.
- `Muldrotha, the Gravetide`: plano de valor por permanentes no cemiterio, com
  self-mill, sac outlets e recursion. Absorver como recursion engine; evitar loops
  lentos sem win condition clara.
- `Sythis, Harvest's Hand`: enchantress value, draw por encantamento, ramp/protecao
  e algumas auras. Manter separado de Light-Paws Voltron.
- `Isshin, Two Heavens as One`: maximiza triggers de ataque, tokens e combat
  snowball. Absorver densidade de atacantes/payoffs; evitar Mardu goodstuff sem
  ataques relevantes.
- `Krenko, Mob Boss`: goblin go-wide e haste para converter quantidade em letal.
  Ja e padrao forte de mono-red typal; nao reutilizar como fonte para Purphoros
  token-burn sem filtrar typal.
- `Urza, Lord High Artificer`: artifacts/control/combo; cEDH/stax sao incentivos
  reais do commander, mas devem ficar em lane de poder explicita.
- `Edgar Markov`: Vampire typal agressivo com Eminence, lord effects, tokens e
  aristocrats. Evitar overfit em listas high-power que ignoram mesa casual.
- `Miirym, Sentinel Wyrm`: dragons, clones, ramp e ETB/copy payoff. Absorver curva
  e ramp suficientes; controlar risco de top-heavy sem interacao.
- `Meren of Clan Nel Toth`: sacrifice value, recursion, toolbox creatures e
  aristocrats. Absorver como Golgari graveyard engine; separar de Muldrotha que
  usa permanentes mais amplos.
- `Korvold, Fae-Cursed King`: sacrifice/treasure/value-combo. Absorver pacotes de
  fodder, treasure e payoffs; exigir bracket/power lane para combo forte.
- `Kaalia of the Vast`: cheat attackers Angels/Demons/Dragons, protecao/evasion e
  interacao para passar do primeiro ataque. Absorver protecao e curva; evitar
  apenas bombas caras sem setup.
- `Prosper, Tome-Bound`: exile-cast + treasure, impulsive draw e payoffs Rakdos.
  Absorver engine de vantagem incremental; manter cEDH/artifacts separados do
  casual bracket 3.

## Padroes uteis para absorver em `optimize` e `generate`

1. Usar EDHREC Average Deck como sinal agregado de roles, densidade e pacotes, nao
   como decklist a copiar.
2. Reforcar `generate` com pacotes por intencao: typal, aristocrats, treasure,
   artifacts, enchantress, blink/combat/recursion, sempre com identidade de cor e
   singleton local.
3. Para `optimize`, usar as fontes para detectar lacunas: ramp/draw/interacao,
   protecao do comandante, curva top-heavy e payoffs ausentes.
4. Separar lanes casual/high-power/cEDH para Urza, Korvold e Prosper; suas paginas
   otimizadas e combo nao devem alimentar bracket casual sem consentimento.
5. Priorizar fontes que ja tiveram sucesso nos fluxos atuais: Krenko, Sythis,
   Urza, Meren, Korvold, Edgar e Prosper.

## Padroes arriscados ou nao transferiveis

1. Nao promover EDHREC diretamente para `meta_decks` ou
   `external_commander_meta_candidates`; a politica local atual trata EDHREC como
   `enrichment-only`.
2. Nao salvar decklists completas nesta etapa e nao copiar listas para prompts.
3. Nao fazer scraping em massa de EDHREC, Archidekt ou Moxfield. Usar coleta
   manual/baixo volume, cache offline auditavel e backoff.
4. Nao misturar cEDH com Commander casual. Urza/Korvold/Prosper precisam de lane
   explicita antes de influenciar recomendacoes fortes.
5. Nao assumir que popularidade externa equivale a qualidade de ManaLoom. Cada
   fonte ainda precisa passar por resolvedor local, banned/color identity,
   singleton e public proof antes de guidance forte.

## Riscos transversais

| Risco | Impacto | Mitigacao minima |
| --- | --- | --- |
| Cartas novas nao resolvidas localmente | Dry-run rejeita decks ou forca fontes laterais, como ja ocorreu com Veyran no Lote C. | Rodar sync/backfill de cartas antes de promover corpus novo; nunca aplicar com `unresolved>0`. |
| EDHREC como fonte agregada | Average Deck nao representa uma lista humana unica nem evento competitivo. | Usar apenas como sinal estatistico/reference corpus offline, com revisao humana dos pacotes. |
| Rate limit/429 | Coletas e provas em lote podem falhar por excesso de chamadas. | Baixo volume, backoff, cache de artefatos sanitizados e reexecucao parcial. |
| Scraping/ToS | Dependencia de HTML nao oficial pode quebrar ou violar uso esperado. | Nao depender em runtime; registrar URL e metadados, coletar manualmente/baixo volume, evitar automacao ampla. |
| Contaminacao cEDH | Decks high-power podem piorar UX casual. | Separar bracket/power lane e bloquear stax/combo como default. |

## Menores proximas acoes tecnicas

1. Para cada comandante ainda sem corpus completo aplicado, escolher 3-5 URLs desta
   matriz e montar um corpus JSON sanitizado fora do runtime, sem decklists no doc.
2. Rodar `commander_reference_deck_corpus.dart --dry-run` por comandante e bloquear
   qualquer fonte com `unresolved>0`, `off_color>0`, comandante != 1, main != 99 ou
   singleton violation.
3. Aplicar somente em tarefa futura explicita, com `--apply`, idempotencia,
   scorecard e public proof 5/5 antes de promover.
4. Para Atraxa, substituir ou revalidar a lane `superfriends` antes de tentar 5/5.
5. Para Urza, Korvold e Prosper, registrar lane casual/high-power/cEDH no metadata
   do corpus para impedir contaminacao de bracket.

## Decisao final

O conjunto e suficiente para planejar uma fleet de referencia com 12 comandantes:
7 estao em **PASS** e 5 em **PASS_WITH_RISKS**. Nenhum comandante ficou
**BLOCKED** nesta etapa porque todos tem pelo menos 4 fontes EDHREC Average Deck
validas e prova Commander externa, mas os riscos de scraping, cartas novas e
contaminacao de poder impedem promocao automatica.
