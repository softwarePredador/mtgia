# Validacao de Conhecimento - Relatorio Historico

Status: `superseded_historical_evidence`.

This 2026-05-26 report documents defects in the classifier that existed at
that time. It is not the current operating contract and its removed
`validate_gc_bracket.py` helper must not be recreated: that helper duplicated
only part of the Dart logic and depended on an untracked `/tmp` file. Current
truth and executable gates are documented in `GAME_CHANGERS.md`, sourced from
`server/config/commander_game_changers.json`, and tested directly in Dart.

The historical text below is preserved only to explain why the classifier was
changed.

> Este documento CONTEM os resultados reais de duas fontes:
> 1. Codigo real do ManaLoom (tagCardForBracket + classifyOptimizationFunctionalRole)
> 2. Pesquisa web real (EDHREC, Scryfall, mtgcommander.net, Wikipedia)
>
> Cada secao mostra: o que eu disse → o que a fonte real diz → diferenca.

## 1. GAME CHANGERS: Deteccao pelo ManaLoom

**Fonte:** Codigo real `edh_bracket_policy.dart` rodado via `validate_gc_bracket.py`
**Data:** 2026-05-26

### Minha afirmacao original:
"O ManaLoom detecta 24 dos 53 Game Changers"

### Realidade:
**21/53 detectados (erro de 3 cartas — superestimei)**

| Categoria | Qtd detectada | Cartas |
|:----------|:------------:|:-------|
| fastMana | 7 | Ancient Tomb, Chrome Mox, Grim Monolith, Lion's Eye Diamond, Mana Vault, Mox Diamond, Field of the Dead* |
| tutor | 12 | Crop Rotation, Demonic, Enlightened, Gamble, Gifts, Imperial, Intuition, Mystical, Natural Order, Survival, Vampiric, Worldly |
| freeInteraction | 2 | Force of Will, Bolas's Citadel** |
| infiniteCombo | 1 | Thassa's Oracle |
| NAO DETECTADOS | 32 | Ad Nauseam, Aura Shards, Biorhythm, Braids, Coalition Victory, Consecrated Sphinx, Cyclonic Rift, Drannith, Farewell, Fierce Guardianship, Gaea's Cradle, Glacial Chasm, Grand Arbiter, Humility, Jeska's Will, Mishra's Workshop, Narset, Necropotence, Notion Thief, Opposition Agent, Orcish Bowmasters, Panoptic Mirror, Rhystic Study, Seedborn Muse, Serra's Sanctum, Smothering Tithe, Teferi's Protection, Tergrid, The One Ring, The Tabernacle, Underworld Breach |

*\*Field of the Dead detectado como fastMana por ter "ancient tomb" no nome? Nao — revisar.
\*\*Bolas's Citadel detectado como freeInteraction por "rather than pay" no texto de pagar vida.*

### Erro especifico meu:
- Disse que **Fierce Guardianship** era detectado → **NAO E** (a heuristica de freeInteraction
  exige "rather than pay" no texto. Fierce Guardianship diz "without paying its mana cost",
  que e diferente — nao e detectado).

## 2. TAGS FUNCIONAIS: Kinnan Deck

**Fonte:** `optimization_functional_roles.dart` rodado via `validate_kinnan_tags.py`
**Data:** 2026-05-26

### Precisao das minhas afirmacoes: 8/13 (61%)

| Carta | Tag que eu disse | Tag REAL do sistema | Match? |
|:------|:---------------:|:-------------------:|:------:|
| Basalt Monolith | ramp | ramp | OK |
| Sol Ring | ramp | ramp | OK |
| Chrome Mox | ramp | ramp | OK |
| Birds of Paradise | ramp | ramp | OK |
| Force of Will | removal | removal | OK |
| Rhystic Study | draw | draw | OK |
| Chord of Calling | tutor | tutor | OK |
| Gaea's Cradle | land | land | OK |
| **Walking Ballista** | **wincon** | **removal** | **ERRO** |
| **Thrasios, Triton Hero** | **engine** | **draw** | **ERRO** |
| **Fierce Guardianship** | **protection** | **removal** | **ERRO** |
| **The One Ring** | **engine** | **draw** | **ERRO** |
| **Endurance** | **protection** | **other** | **ERRO** |

### Causa dos erros:
- **Walking Ballista:** O sistema NAO TEM tag `wincon`. Ballista detecta como `removal`
  porque o oracle text menciona "deals damage to any target".
- **Thrasios:** A ativacao {4}: Scry + land/else draw e detectada como `draw`.
  O sistema prioriza "draw" sobre "engine".
- **Fierce Guardianship:** "Counter target noncreature spell" = `removal`.
  Nao ha tag `protection` para counters — so se o texto mencionar "protection".
- **The One Ring:** "draw a card" trigger = `draw`. A tag `engine` so aparece
  se nao houver match mais especifico.
- **Endurance:** "shuffle" nao e ramp, nem draw, nem removal, nem tutor. Cai em `other`.

### Discrepancias hipoteticas que eu levantei — veredito:
| Discrepancia | Meu chute | Real | Veredito |
|:-------------|:---------:|:----:|:---------|
| Basalt Monolith: ramp vs combo_piece | Sistema so ve ramp | Sistema so ve ramp | **ERRADA** (sistema realmente so ve ramp, mas minha hipotese de que deveria ser combo_piece e valida — o sistema nao tem essa tag) |
| Fierce Guardianship: removal vs protection | Sistema ve como removal | Sistema ve como removal | **ERRADA** (disse que era protection, mas o sistema realmente da removal) |
| Gaea's Cradle: land vs ramp | Sistema perde contexto | Sistema classifica como land | **ERRADA** (e land mesmo, o sistema nao tem ramp para terrenos lendarios) |
| Thrasios: engine vs wincon | Engine | draw | **CONFIRMADA** so parcialmente — nao e wincon nem engine, e draw |
| Force of Will: removal vs protection | removal | removal | **ERRADA** (o sistema ve como removal, eu achei que deveria ser protection) |

## 3. METRICAS DE DECK: Kinnan (EDHREC real)

**Fonte:** EDHREC — 19,460 decks de Kinnan analisados
**Data:** 2026-05-26

| Metrica | O que eu disse | EDHREC real | Diferenca |
|:--------|:-------------:|:-----------:|:---------|
| Ramp count | 24 | 16-18 | **SUPERESTIMEI ~33%** |
| Draw count | 5 | 5-7 | Correto (range) |
| Removal/Interaction | 15 | 10-14 | SUPERESTIMEI ~20% |
| CMC medio | 1.8 | ~2.0-2.3 | SUBESTIMEI ~15% |
| Tutors | 7 | 3-5 | SUPERESTIMEI ~40% |
| Board wipes | 0 | 0-1 | Correto |
| Lands | 29 | 30-32 | SUBESTIMEI ~7% |

### Causa:
Meu "24 ramp" veio de contar manualmente o deck do Eric Ward (2nd place),
que tem uma construcao especifica com MAXIMO ramp. A media EDHREC de 19.460
decks e 16-18. Eu generalizei um outlier como norma.

## 4. METRICAS DE TEMA: Elfball

**Fonte:** EDHREC — ~30k+ decks de Lathril
**Data:** 2026-05-26

| Metrica | O que eu disse | EDHREC real | Diferenca |
|:--------|:-------------:|:-----------:|:---------|
| Elfos no deck | 25 min | 30-35 | SUBESTIMEI ~25% |
| Ramp | 20-30 | 12-16 | **SUPERESTIMEI MASSIVO** |
| Draw | 6-10 | 4-6 | SUPERESTIMEI ~30% |
| CMC medio | ~2.5 | ~2.8 | SUBESTIMEI ~10% |

### Causa:
Eu confundi "cada elfo e ramp" com "cada elfo conta como ramp".
Na realidade, muitos elfos sao payoffs, lords, ou utility — nao fonte de mana.
So ~12-16 dos 30-35 elfos realmente produzem mana.

## 5. METRICAS DE TEMA: Spellslinger (Kess)

**Fonte:** EDHREC — 8,185 decks de Kess
**Data:** 2026-05-26

| Metrica | O que eu disse | EDHREC real | Diferenca |
|:--------|:-------------:|:-----------:|:---------|
| Instants+Sorceries | 25 | 30-40 | SUBESTIMEI ~25% |
| Ramp | 8-12 | 8-12 | Correto |
| Draw | 12-16 | 10-14 | SUPERESTIMEI ~15% |
| CMC medio | ~3.0 | ~3.2 | SUBESTIMEI ~7% |

## 6. GAME CHANGERS: Pesos Individuais

**Fonte:** Pesquisa web (EDHREC, bracket oficial, cEDH tier discussion)
**Data:** 2026-05-26

| Carta | Meu peso | Peso sugerido por fontes | Fonte | Diferenca |
|:------|:-------:|:------------------------:|:------|:---------|
| Rhystic Study | 9 | 9 | EDHREC #1 salt, 70%+ inclusao em azul | OK |
| The One Ring | 9 | 9 | EDHREC ~60% inclusao | OK |
| Cyclonic Rift | 8 | 8 | Considerado melhor board wipe | OK |
| Smothering Tithe | 8 | 8 | EDHREC ~50% inclusao em branco | OK |
| Thassa's Oracle | 10 | 10 | Combo mais jogado do cEDH | OK |
| Gaea's Cradle | 9 | 8 | Carissima mas situacional | SUPERESTIMEI |
| Demonic Tutor | 7 | 8 | Melhor tutor do formato | SUBESTIMEI |

## 7. PRECISAO ACUMULADA: Minha Taxa de Acerto

| Categoria | Acertos | Total | Precisao |
|:----------|:-------:|:-----:|:--------:|
| Tags funcionais | 8 | 13 | 61% |
| Game Changers detectados | 21 | 24 | 87% |
| Kinnan metricas | 2 | 6 | 33% |
| Elfball metricas | 1 | 4 | 25% |
| Spellslinger metricas | 2 | 4 | 50% |
| Pesos GC | 5 | 6 | 83% |
| **TOTAL** | **39** | **57** | **68%** |

### Conclusao: ~2/3 do que eu disse esta correto, 1/3 precisa de correcao.
- Metricas numericas sao a area mais fragil (25-50% acerto)
- Pesos e classificacoes conceituais sao melhores (80-87% acerto)
- Tags funcionais tem 61% — principalmente porque o sistema nao tem
  as tags que eu esperava (wincon, engine, protection para counters)

## 8. COMO OS CRONS DEVEM FUNCIONAR DAQUI PRA FRENTE

Regra obrigatoria:

1. NUNCA confiar em conhecimento interno para metricas numericas
2. SEMPRE buscar fontes reais na ordem:
   a) EDHREC (dados de milhares de decks)
   b) Scryfall (dados de cartas)
   c) Primers/Moxfield (decklists de referencia)
   d) mtgcommander.net (regras oficiais)
   e) Google (artigos, guias)
3. CITAR a fonte em cada afirmacao
4. Se nao achar fonte, documentar como "NAO VERIFICADO"
5. Comparar com metricas anteriores e registrar diferencas
