# Padroes de Win Condition em Lorehold, the Historian

> Ultima atualizacao: 2026-05-31T22:00:00+00:00
> Baseado em: 7,851 decks no EDHREC + analise de oracle text via Scryfall

## Visao Geral

Lorehold, the Historian e um commander spellslinger Boros (RW) focado em:
1. Gerar mana explosiva via tesouros e rituais
2. Conjurar spells massivas que definem o jogo
3. Copiar essas spells para multiplicar o valor
4. Fechar com win conditions deterministicas ou baseadas em combate

O deck medio do EDHREC joga 35 lands, 13 criaturas, 34 spells nao-criatura.
O CMC medio das spells e alto (muitas spells 7+ mana), compensado por
geracao massiva de tesouros.

---

## Padrao 1: Approach + Topdeck Manipulation (PRINCIPAL)

**Frequencia:** ~64% dos decks (Approach of the Second Sun em 63.8% dos decks)

### Cartas Envolvidas
| Carta | CMC | Funcao | Inclusao |
|:------|:---:|:-------|:--------:|
| Approach of the Second Sun | 7 | Wincon primario | 63.8% |
| Sensei's Divining Top | 1 | Topdeck manipulation | 66.8% |
| Scroll Rack | 2 | Hand/library swap | 59.5% |
| Library of Leng | 1 | No max hand + discard-to-top | 77.8% |
| Enlightened Tutor | 1 | Tutor | 18.4% |
| Penance | 3 | Topdeck setup + protecao | 41.7% |

### Como Funciona
1. Conjurar Approach of the Second Sun (CMC 7). Ela vai para o topo (7a posicao).
2. Usar Sensei's Divining Top ou Scroll Rack para manipular o topo e buscar Approach.
3. Conjurar Approach novamente para vencer.

**Por que e tao efetivo em Lorehold:**
- O deck naturalmente gera muito mana (tesouros) — CMC 7 e facil de atingir
- Top e Scroll Rack ja sao cartas core do deck (topdeck manipulation)
- Approach ganha o jogo sozinha, sem precisar de combate
- Library of Leng protege contra discard e poe Approach de volta no topo

**Tempo tipico de vitoria:** Turno 7-9
**Vulnerabilidades:** Counterspell, remocao de encantamento/artefato (Top/Rack)

---

## Padrao 2: Storm Herd + Pump

**Frequencia:** ~75% dos decks (Storm Herd em 75.0% dos decks)

### Cartas Envolvidas
| Carta | CMC | Funcao | Inclusao |
|:------|:---:|:-------|:--------:|
| Storm Herd | 10 | Mass token creation | 75.0% |
| Boros Charm | 2 | Double strike / indestructible | 45.5% |
| Akroma's Will | 4 | Mass pump + protection | ~20% |
| Insurrection | 8 | Steal all creatures | 45.2% |

### Como Funciona
1. Conjurar Storm Herd (CMC 10) — cria X tokens 1/1 flying, onde X = seu life total.
2. Normalmente 35-45 tokens em Commander.
3. Dar double strike ou pump massivo com Boros Charm / Akroma's Will.
4. Atacar com 35+ tokens para letal.

**Por que e tao efetivo:**
- CMC 10 e viavel com a geracao de tesouros do deck
- Nao depende do combate ate o turno final
- Sinergia com lifegain incidental (Beacon of Immortality em 34.2%)

**Vulnerabilidades:** Board wipe no turno seguinte, fog (prevent combat damage)

---

## Padrao 3: Mizzix's Mastery + Graveyard

**Frequencia:** ~57% dos decks

### Cartas Envolvidas
| Carta | CMC | Funcao | Inclusao |
|:------|:---:|:-------|:--------:|
| Mizzix's Mastery | 4 | Reanimate e copiar spells | 57.4% |
| Arcane Bombardment | 6 | Copiar do graveyard todo turno | 42.4% |
| Restoration Seminar | 7 | Recursion de permanent | 37.9% |
| Faithless Looting | 1 | Loot + encher graveyard | 29.7% |
| Dragon's Rage Channeler | 1 | Surveil + beater | 39.5% |

### Como Funciona
1. Encher o graveyard com spells via looting, surveil, ou naturalmente.
2. Conjurar Mizzix's Mastery (CMC 4, overload CMC 8).
3. Copiar e conjurar TODAS as spells no graveyard sem pagar custo de mana.
4. Com Arcane Bombardment, fazer isso TODO TURNO.

**Variante de combo:** Mizzix's Mastery + Faithless Looting (pre-enche graveyard) +
qualquer spell grande no graveyard = valor explosivo.

**Vulnerabilidades:** Graveyard hate (Rest in Peace, Bojuka Bog), counterspell

---

## Padrao 4: Rise of the Eldrazi (Extra Turn)

**Frequencia:** ~55% dos decks

### Cartas Envolvidas
| Carta | CMC | Funcao | Inclusao |
|:------|:---:|:-------|:--------:|
| Rise of the Eldrazi | 12 | Destroy + draw + extra turn | 54.6% |
| Double Vision | 5 | Copiar a spell | 46.5% |
| Velomachus Lorehold | 7 | Cast free do topo | 32.6% |

### Como Funciona
1. Conjurar Rise of the Eldrazi (CMC 12).
2. Destruir um permanente problematico.
3. Comprar 4 cartas.
4. Turno extra — repetir o processo.
5. Se copiada com Double Vision: 2 permanentes destruidos, 8 cartas, 2 turnos extras.

**Por que e bom:** CMC 12 parece impossivel, mas com tesouros e rituais (Jeska's Will, Mana Geyser),
o deck consistentemente chega a 12+ mana.

**Vulnerabilidades:** Muito lento contra combo. Nao ganha no mesmo turno (precisa do turno extra).

---

## Padrao 5: Apex of Power + Topdeck Exile

**Frequencia:** ~55% dos decks

### Cartas Envolvidas
| Carta | CMC | Funcao | Inclusao |
|:------|:---:|:-------|:--------:|
| Apex of Power | 10 | Exile top 7 + 10 mana | 54.9% |
| Dance with Calamity | 8 | Exile ate CMC total = mana | 50.2% |
| Improvisation Capstone | 7 | Exile topo ate CMC 4 | 49.0% |
| Call Forth the Tempest | 8 | Cascade x2 | 65.3% |

### Como Funciona
1. Conjurar Apex of Power (CMC 10) da mao.
2. Adicionar 10 mana de qualquer cor.
3. Exilar top 7 — conjurar todas as spells de la.
4. Com 10 mana extra, conjurar ainda mais spells.

**Variante:** Dance with Calamity (CMC 8) — escolher quantas vezes quiser exilar topo.
Se o total de CMC exilado for 13 ou menos, conjurar todas.

**Vulnerabilidades:** Alta variancia (depende do topo). Se whiffar, perdeu 10 mana.

---

## Padrao 6: Treasure Payoff Direto

**Frequencia:** Componente presente em ~80% dos decks

### Cartas Envolvidas
| Carta | CMC | Funcao | Inclusao |
|:------|:---:|:-------|:--------:|
| Storm-Kiln Artist | 4 | Cria tesouro ao castar/copiar | 55.3% |
| Smothering Tithe | 4 | Cria tesouro quando oponente compra | 29.4% |
| Hit the Mother Lode | 7 | Discover 10 + tesouros | 79.3% |
| Big Score | 4 | Draw 2 + 2 tesouros | 67.3% |
| Brass's Bounty | 7 | Tesouro por land | 67.1% |
| Unexpected Windfall | 4 | Draw 2 + 2 tesouros | 56.7% |

### Como Funciona
1. Acumular tesouros via Big Score, Hit the Mother Lode, Storm-Kiln Artist.
2. Converter tesouros em mana para spells grandes.
3. Storm-Kiln Artist escala: cada spell copiada gera tesouro.

**Motor completo:** Treasure Ramp -> Big Spell Free -> Lorehold Copy -> Treasure Payoff

---

## Padrao 7: Insurrection (Steal & Swing)

**Frequencia:** ~45% dos decks

### Como Funciona
1. Conjurar Insurrection (CMC 8).
2. Ganhar controle de TODAS as criaturas.
3. Todas ganham haste.
4. Atacar com o board inteiro dos oponentes.

**Por que e bom:** Nao depende do seu board state. Vira o jogo instantaneamente.
**Vulnerabilidades:** Teferi's Protection, fog effects.

---

## Prioridade de Win Conditions (por Velocidade)

| Wincon | Turno tipico | Confiabilidade | Dependencia |
|:-------|:-----------:|:-------------:|:------------|
| Approach + Topdeck | 7-9 | Alta | Precisa de Top/Rack |
| Insurrection | 8-10 | Media | Depende do board oponente |
| Storm Herd + Pump | 9-11 | Alta | Precisa sobreviver um turno |
| Mizzix's Mastery | 8-12 | Media-alta | Precisa de graveyard |
| Rise of the Eldrazi | 10-14 | Media | Turno extra pode nao bastar |
| Apex/Dance exilado | 8-12 | Baixa-media | Alta variancia |

---

## Como o Deck SOBREVIVE ate la?

### Remocao (Early Game)
| Carta | CMC | Inclusao |
|:------|:---:|:--------:|
| Swords to Plowshares | 1 | 69.0% |
| Path to Exile | 1 | 57.4% |
| Chaos Warp | 3 | 38.8% |
| Generous Gift | 3 | 32.4% |
| Deflecting Swat | 3 | 36.8% |

### Board Wipes
| Carta | CMC | Inclusao |
|:------|:---:|:--------:|
| Blasphemous Act | 9* | 40.4% |
| Austere Command | 6 | 33.3% |
| Farewell | 6 | 17.5% |

*Blasphemous Act tipicamente custa 1 mana vermelha com reducao por criatura

### Protecao
| Carta | CMC | Inclusao |
|:------|:---:|:--------:|
| Boros Charm | 2 | 45.5% |
| Teferi's Protection | 3 | 21.2% |
| Mother of Runes | 1 | 34.5% |
| Deflecting Swat | 3 | 36.8% |

---

## Conclusao

Lorehold e um deck que:
1. **Turnos 1-4:** Ramp (Sol Ring, Arcane Signet, Fellwar Stone) + card selection (Faithless Looting, Top)
2. **Turnos 4-6:** Geracao massiva de tesouros (Big Score, Hit the Mother Lode)
3. **Turnos 6-9:** Spells grandes que definem o jogo (Apex, Mizzix, Approach)
4. **Turnos 9+:** Fechar com Approach (deterministico) ou Storm Herd + pump (combat)

A forca do deck esta na capacidade de gerar 10+ mana em um unico turno via tesouros,
permitindo conjurar spells que normalmente seriam "cedo demais" para commander.

---

## Fontes
- Scryfall API: oracle text oficial de todas as cartas mencionadas
- EDHREC JSON API: dados de inclusao de 7,851 decks
- EDHREC Decks page: 10+ decks individuais analisados
