# Commander Reference Profile Anchor 30 Plan — 2026-05-12

## Objetivo

Preparar a primeira base ampla de 30 comandantes âncora para alimentar:

- `/ai/generate` com `commander_name`;
- archetype reference reuse para comandantes parecidos;
- future optimize/rebuild guidance;
- cobertura por cor, tema e nível de poder.

Esta lista não substitui os profiles já aplicados de Secrets of Strixhaven. Ela
é a próxima camada: comandantes populares/estáveis que cobrem arquétipos
recorrentes de Commander.

## Critérios de seleção

- Priorizar commanders estáveis e reconhecíveis, com alto volume histórico de
  listas públicas.
- Cobrir macrotemas diferentes para maximizar reaproveitamento por arquétipo.
- Evitar depender apenas de cartas muito recentes/Universes Beyond até provar
  completude do banco local.
- Evitar partner pairs nesta primeira onda porque o pipeline de profile ainda é
  mais seguro com `commander_name` único.
- Manter cEDH/high-power como parte da base, mas sem transformar todo profile
  casual em `competitive_commander`.

Fontes de sinal usadas para priorização:

- EDHREC como referência pública de popularidade/tendências de Commander.
- Histórico local do projeto: profiles Strixhaven lot 1/2 e archetype reuse já
  provados.
- Cobertura funcional desejada para gerar decks melhores.

## Estado atual já coberto

Profiles já aplicados/provados recentemente:

- Lorehold, the Historian
- Dina, Essence Brewer
- Killian, Decisive Mentor
- Prismari, the Inspiration
- Quandrix, the Proof
- Quintorius, History Chaser
- Rootha, Mastering the Moment
- Silverquill, the Disputant
- Witherbloom, the Balancer
- Zimone, Infinite Analyst
- Aziza, Mage Tower Captain
- Berta, Wise Extrapolator
- Excava, the Risen Past
- Gorma, the Gullet
- Muddle, the Ever-Changing
- Primo, the Unbounded
- Scriv, the Obligator
- Zaffai and the Tempests

## Anchor 30

| # | Commander | Identity | Primary theme | Secondary reuse value | Power lane | Batch |
|---:|---|---|---|---|---|---|
| 1 | Atraxa, Praetors' Voice | WUBG | Proliferate/+1 counters/superfriends | counters, planeswalkers, poison | high-power casual | A |
| 2 | Korvold, Fae-Cursed King | BRG | Sacrifice/treasure/value | aristocrats, food/clues/treasures | high-power casual | A |
| 3 | Muldrotha, the Gravetide | BGU | Graveyard permanent recursion | self-mill, value engines | casual/high-power | A |
| 4 | Chulane, Teller of Tales | GWU | Creature value/ramp/draw | ETB chains, creature combo | high-power casual | A |
| 5 | Yuriko, the Tiger's Shadow | UB | Ninjas/topdeck damage | topdeck manipulation, evasive tempo | high-power/cEDH-adjacent | A |
| 6 | Kinnan, Bonder Prodigy | GU | Mana dorks/artifact ramp/combo | big mana, creature cheating | high-power/cEDH | A |
| 7 | Winota, Joiner of Forces | RW | Combat triggers/cheat humans | attack triggers, stax-combat | high-power/cEDH-adjacent | A |
| 8 | Prosper, Tome-Bound | BR | Exile value/treasure | impulse draw, treasure engines | casual/high-power | A |
| 9 | Edgar Markov | WBR | Vampire typal/aggro tokens | typal aggro, aristocrats | high-power casual | B |
| 10 | Miirym, Sentinel Wyrm | GUR | Dragon typal/copy | creature copy, ramp payoffs | casual/high-power | B |
| 11 | Isshin, Two Heavens as One | RWB | Attack trigger doubling | combat value, token attack | casual/high-power | B |
| 12 | Teysa Karlov | WB | Aristocrats/death triggers | tokens, death payoffs | casual | B |
| 13 | Lathril, Blade of the Elves | BG | Elf typal/go-wide drain | typal ramp, tokens | casual | B |
| 14 | Aesi, Tyrant of Gyre Strait | GU | Lands/ramp/draw | landfall, extra lands | casual/high-power | B |
| 15 | Sythis, Harvest's Hand | GW | Enchantress | auras, enchantment value | casual/high-power | B |
| 16 | Urza, Lord High Artificer | U | Artifacts/constructs/control | artifact mana, stax/control | high-power/cEDH | B |
| 17 | Krenko, Mob Boss | R | Goblin typal/tokens | go-wide, haste payoffs | casual | C |
| 18 | K'rrik, Son of Yawgmoth | B | Mono-black life-as-mana/combo | devotion, storm/combo | high-power/cEDH | C |
| 19 | Giada, Font of Hope | W | Angels/+1 counters | tribal curve, counters | casual | C |
| 20 | Light-Paws, Emperor's Voice | W | Auras/Voltron | equipment/auras, protection | casual/high-power | C |
| 21 | Meren of Clan Nel Toth | BG | Graveyard sacrifice recursion | aristocrats, toolbox creatures | casual/high-power | C |
| 22 | Niv-Mizzet, Parun | UR | Spellslinger/draw damage | wheels, instant/sorcery control | high-power | C |
| 23 | Brago, King Eternal | WU | Blink/ETB control | flicker, stax/value | casual/high-power | C |
| 24 | Feather, the Redeemed | RW | Heroic/protection spells | spellslinger-voltron | casual | C |
| 25 | Wilhelt, the Rotcleaver | UB | Zombie typal/aristocrats | tokens, sacrifice, recursion | casual | D |
| 26 | Najeela, the Blade-Blossom | WUBRG | Warrior combat/combo | combat combo, five-color aggro | high-power/cEDH | D |
| 27 | The Ur-Dragon | WUBRG | Dragon typal/big mana | tribal ramp, top-end threats | casual/high-power | D |
| 28 | Jodah, the Unifier | WUBRG | Legendary typal/cascade value | legends-matter, five-color goodstuff | casual/high-power | D |
| 29 | Omnath, Locus of Creation | WURG | Landfall/value | lands, ramp, elemental value | high-power casual | D |
| 30 | Anje Falkenrath | BR | Madness/discard combo | discard value, graveyard setup | high-power/cEDH-adjacent | D |

## Cobertura por identidade

| Group | Count | Notes |
|---|---:|---|
| Mono-color | 5 | W/U/B/R represented; mono-G deferred to next wave because land/ramp is already covered by Aesi/Omnath/Kinnan. |
| Two-color | 14 | Strongest first-wave coverage for common Commander archetypes. |
| Three-color | 7 | Covers sacrifice, graveyard, typal, creature value, combat, dragons. |
| Four/five-color | 4 | Enough to seed 4c/5c archetype reuse without overloading the first wave. |

## Cobertura por macrotema

| Macrotheme | Anchors |
|---|---|
| Aristocrats/sacrifice | Korvold, Teysa, Meren, Wilhelt |
| Graveyard/reanimator/value | Muldrotha, Meren, Anje |
| Spellslinger/big spells | Niv-Mizzet, Feather, Velomachus via archetype reuse, existing Lorehold |
| Typal | Edgar, Lathril, Krenko, Giada, Wilhelt, The Ur-Dragon |
| Lands/ramp | Aesi, Omnath, Kinnan |
| Enchantress/auras | Sythis, Light-Paws |
| Blink/ETB | Brago, Chulane |
| Combat/attack triggers | Winota, Isshin, Najeela |
| Artifacts/control | Urza |
| +1/+1 counters/proliferate | Atraxa, Giada |
| Treasure/exile value | Prosper, Korvold |
| Five-color legends/goodstuff | Jodah, Najeela, The Ur-Dragon |

## Batch execution plan

### Batch A — 8 profiles

Priority: highest impact on archetype reuse and quality proof.

- Atraxa, Praetors' Voice
- Korvold, Fae-Cursed King
- Muldrotha, the Gravetide
- Chulane, Teller of Tales
- Yuriko, the Tiger's Shadow
- Kinnan, Bonder Prodigy
- Winota, Joiner of Forces
- Prosper, Tome-Bound

### Batch B — 8 profiles

- Edgar Markov
- Miirym, Sentinel Wyrm
- Isshin, Two Heavens as One
- Teysa Karlov
- Lathril, Blade of the Elves
- Aesi, Tyrant of Gyre Strait
- Sythis, Harvest's Hand
- Urza, Lord High Artificer

### Batch C — 8 profiles

- Krenko, Mob Boss
- K'rrik, Son of Yawgmoth
- Giada, Font of Hope
- Light-Paws, Emperor's Voice
- Meren of Clan Nel Toth
- Niv-Mizzet, Parun
- Brago, King Eternal
- Feather, the Redeemed

### Batch D — 6 profiles

- Wilhelt, the Rotcleaver
- Najeela, the Blade-Blossom
- The Ur-Dragon
- Jodah, the Unifier
- Omnath, Locus of Creation
- Anje Falkenrath

## Gates obrigatórios por profile

Antes de `--apply`:

- Commander resolve em `/cards/resolve` e no banco local.
- `off_color_count=0`.
- `unresolved=0`, ou profile fica `not_proven` e não aplica.
- `expected_packages` com nomes de cartas reais e verificáveis.
- Não copiar decklists completas de fontes públicas.
- Artifacts sanitizados, sem tokens, e-mails reais, JWT, DSN, DATABASE_URL ou
  prompts/decklists completos.

Depois de `--apply`:

- Rodar idempotência.
- Rodar probe local/público para pelo menos 2 commanders do batch.
- Runtime público completo do batch antes de avançar para o próximo.

## Comando recomendado para Batch A

```bash
copilot --agent "Commander Meta Web Research Analyst" --allow-all -p "Objetivo: criar e aplicar Commander Reference Profiles Batch A da base Anchor 30. Repo: /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia. Branch alvo: master. Batch A: Atraxa, Praetors' Voice; Korvold, Fae-Cursed King; Muldrotha, the Gravetide; Chulane, Teller of Tales; Yuriko, the Tiger's Shadow; Kinnan, Bonder Prodigy; Winota, Joiner of Forces; Prosper, Tome-Bound. Nao expor secrets, tokens, JWT, DATABASE_URL, SENTRY_DSN, OPENAI_API_KEY ou decklists completas. Nao copiar decklists inteiras; usar apenas sinais agregados, pacotes, temas, roles e cartas representativas. Tarefas: sincronizar master; checar git status; consultar server/doc/COMMANDER_REFERENCE_PROFILE_ANCHOR_30_PLAN_2026-05-12.md, API_CONTRACTS_AND_DATA_MAP.md e relatorios recentes de Strixhaven; para cada commander montar profile JSON com commander, color_identity, themes, role_targets, expected_packages, avoid_patterns, confidence, source_count; validar commander_card_resolution; rodar server/bin/commander_reference_profile.dart --profile-json=<path> --dry-run; exigir unresolved=0 e off_color_count=0; aplicar somente profiles seguros; rodar idempotencia; gerar relatorio server/doc/RELATORIO_COMMANDER_REFERENCE_PROFILE_ANCHOR30_BATCH_A_2026-05-12.md e artifacts sanitizados em server/test/artifacts/commander_reference_profile_anchor30_batch_a_2026-05-12/. Validacoes: cd server && dart analyze bin lib routes test; cd server && dart test test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart -r expanded; git diff --check; scan simples de secrets. Commit/push se aplicar. Criterios: PASS se 8/8 aplicados com unresolved=0/off_color=0; PASS WITH RISKS se alguns ficarem not_proven documentados sem aplicar; BLOCKED se dados insuficientes ou DB nao resolver commanders. Worktree limpo ao final."
```

## Próximos passos

1. Executar Batch A.
2. Fazer runtime público Batch A.
3. Só avançar para Batch B depois de 8/8 ou decisão documentada sobre casos
   `not_proven`.
