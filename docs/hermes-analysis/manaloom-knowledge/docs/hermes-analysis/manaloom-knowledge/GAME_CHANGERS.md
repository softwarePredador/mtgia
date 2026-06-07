# Game Changers — Research Repository

> 53 cartas oficiais designadas pelo Commander Rules Committee como Game Changers.
> Fonte oficial: Scryfall `is:gamechanger`
>
> Cada entrada e preenchida uma por execucao do cron `manaloom-gamechanger-research`.
> Ultima atualizacao: 2026-05-27

## Status

| Status | Qtd |
|:-------|:---:|
| Total | 53 |
| Analisados | 4 |
| Faltando | 49 |

## Analises Realizadas

### Ultima analise SQLite: Smothering Tithe

**Card:** Smothering Tithe ({3}{W}, Enchantment, CMC 4)
**Impact Level:** 10/10
**Impact Category:** fast_mana
**Sources:** Scryfall, EDHREC (salt=2.58, inclusion=36%), ManaLoom code analysis

**Why Game Changer:** Smothering Tithe e considerada Game Changer por quatro razoes:

1. **Vantagem passiva institucionalizada:** Muda a estrutura basica do jogo sem voce fazer nada. Cada draw de oponente cria um Dilema do Prisioneiro — pagar {2} ou te dar um tesouro. Em 3 oponentes, se todos pagam, gastaram 6 mana. Se alguem nao paga, voce acumula ramp branco, algo que mono-white historicamente nao tem.

2. **Potencial de snowballing:** Cada tesouro gera mana para ativar mais controle. Smothering Tithe + Rhystic Study paralisa a mesa: cada draw aciona ambos.

3. **Salt 2.58/10:** Salt altissimo para uma carta que nao faz nada no turno que entra. Jogadores a consideram frustrante porque ela muda o ritmo silenciosamente.

4. **Inclusao massiva:** ~36% de todos os decks EDHREC (15.374 em 42.251).

5. **Sem substituta:** Unica fonte de ramp passivo branco que escala com numero de oponentes.

**Detectada pelo ManaLoom?** NAO — bracket system nao detecta Tithe em nenhuma categoria. Precisa de categoria gameChanger propria. O single-tag classifier classifica como 'draw' (falso positivo — oracle contem "draw a card" mas ela nao compra). Multi-tag corretamente da ramp (0.88).

**Preco:** $53.94

---

### Analise anterior: Cyclonic Rift (2026-05-27)

**Card:** Cyclonic Rift ({1}{U} / {6}{U}, Instant, CMC 2/7)
**Impact Level:** 10/10
**Impact Category:** board_wipe
**Sources:** Scryfall, EDHREC (salt=2.36, inclusion=30%), mtgcommander.net/brackets (NAO VERIFICADO)

**Why Game Changer:** Cyclonic Rift e a unica mass bounce unilateral do jogo. Por {6}{U}, devolve CADA permanente nao-terreno que voce nao controla — seus oponentes perdem tudo, voce mantem tudo. A face overloaded custa {1}{U], entao nunca e carta morta. Instant speed permite overload no final do turno do oponente da direita, dando a voce o primeiro turno com mesa limpa. Rank #51 EDHREC, ~30% inclusao. Salt 2.36/10.

**Detectada pelo ManaLoom?** NAO.

---

### Analise anterior: Ad Nauseam (2026-05-26)

**Card:** Ad Nauseam ({3}{B}{B}, Instant, CMC 5)
**Impact Level:** 9/10
**Impact Category:** combo_piece
**Sources:** Scryfall, EDHREC, cEDH/Moxfield

**Why Game Changer:** Ad Nauseam revela o deck inteiro por vida, permitindo encontrar o combo (Thassa's Oracle + Demonic Consultation) ou qualquer resposta. O custo de vida e trivial em cEDH onde CMC medio e ~1.5. Ad Nauseam + Angel's Grace = ganha no turno sem restricao de vida.

**Detectada pelo ManaLoom?** SIM — detectada como draw (correto funcionalmente). Bracket: NAO (nao se encaixa nas 5 categorias atuais).

---

### Analise anterior: Thassa's Oracle (2026-05-26)

**Card:** Thassa's Oracle ({U}{U}, Creature, CMC 2)
**Impact Level:** 10/10
**Impact Category:** combo_piece
**Sources:** Scryfall, EDHREC, cEDH/Moxfield

**Why Game Changer:** A wincondition mais eficiente do cEDH. Com Demonic Consultation ou Tainted Pact, e uma vitoria de 2 cartas por {U}{U} + {B}. Nao ha interacao que pare (nem Stifle se a biblioteca estiver vazia). Define o meta do cEDH — todo deck preto precisa de resposta a Thoracle.

**Detectada pelo ManaLoom?** SIM — na lista _knownInfiniteComboPieces (bracket categoria infiniteCombo).
