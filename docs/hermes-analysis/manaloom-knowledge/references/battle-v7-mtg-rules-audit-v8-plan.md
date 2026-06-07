# MTG Rules Audit v2 -- Battle Analyst v7 -> Plano v8

**Data:** 2026-05-31
**Auditor:** Hermes Agent (cron: manaloom-commander-knowledge-deep)
**Versao auditada:** `scripts/battle_analyst_v7.py` (924 linhas)
**Foco:** Priority, Stack, Instant timing, Mecanicas do Lorehold

---

## 1. Panorama Geral do v7

O v7 implementa **19 correcoes** sobre o v6 (Commander Zone, Commander Damage, Blockers,
Summoning Sickness, Cleanup Step, First/Double Strike, Teferi's Protection real, etc.)
mas AINDA NAO modela as 3 regras fundamentais do MTG que tornam o jogo interativo:
**Priority, Stack, e Instant Timing.**

### Evidencia Empirica do Vies

O v7 reporta **78.8% - 94.2% WR** contra 6 arquétipos. Isso e irrealista para qualquer
deck Commander. A razao: Oponentes nao podem interagir no turno do Lorehold porque
nao existe sistema de prioridade nem stack. Counterspells, instant-speed removal,
e respostas simplesmente nao existem no simulador.

| Execucao | WR Overall | Stalls | Turno Medio |
|:---------|----------:|-------:|:-----------|
| Run 1 (16:20Z) | 94.2% | 31/600 | 15.1 |
| Run 2 (16:22Z) | 78.8% | 120/600 | 17.4 |

**Conclusao:** O v7 e util para medir goldfishing (capacidade de executar o plano
sem interacao), mas NAO mede performance real de jogo. O v8 precisa adicionar
interacao minima para que os WRs facam sentido.

---

## 2. Gaps Remanescentes do v7

| # | Gap | Severidade | Impacto no Lorehold | Estimativa de Codigo |
|:--|:----|:-----------|:--------------------|:---------------------|
| 1 | **Priority System** (CR 117) | CRITICO | Counterspell/resposta nao existe; WRs sao goldfish puro | ~120 linhas |
| 2 | **Stack (LIFO)** (CR 405, 608) | CRITICO | Counterspells nao podem responder; copies nao vao pra stack | ~80 linhas |
| 3 | **Instant vs Sorcery Timing** (CR 307, 304) | CRITICO | Boros Charm so conjurado na main phase, nao em combate/resposta | ~60 linhas |
| 4 | **Miracle** (CR 702.94) | ALTO | Dance with Calamity (CMC 8) deveria custar RRR no draw step; Reforge the Soul custa 1R. Lorehold da miracle 2 a TODAS instants/sorceries na mao. **CORE DO DECK** | ~40 linhas |
| 5 | **State-Based Actions** (CR 704) | MEDIO | Derrotas so checadas apos cada turno, nao entre spells. Commander damage 21 so checado no combat. | ~25 linhas |
| 6 | **Copy Spells na Stack** | MEDIO | Double Vision + Arcane Bombardment so incrementam `copy_engines += 1`; nao criam copias reais | ~30 linhas |
| 7 | **Treasure com Sacrifice** | BAIXO | `treasures += 1` adiciona mana generica; mas nao modela decisao de usar agora vs guardar | ~15 linhas |
| 8 | **Boros Charm Double Strike** | BAIXO | `alt_effect: double_strike` nunca e usado; so `effect: indestructible` | ~5 linhas |
| 9 | **Haste do Lorehold** | BAIXO | Commander tem haste mas `summoning_sick = True` e setado ao conjurar | ~5 linhas |
| 10 | **Lifelink de Akroma's Will** | BAIXO | Keyword lifelink e setada mas nunca aplica life gain | ~5 linhas |
| 11 | **Indestructible per-creature** | BAIXO | So `player.indestructible` existe; Akroma's Will da indestructible a creatures, nao ao player | ~5 linhas |
| 12 | **Teferi phased out timing** | BAIXO | Phased out retorna no untap (deveria ser no upkeep) | ~3 linhas |
| 13 | **Double Strike dano triplo** | BAIXO | v7 causa 3x dano (pwr*2 no first strike + pwr no regular); deveria ser 2x total | ~5 linhas |

**Total estimado v8: ~400 novas linhas**

---

## 3. Mecanicas do Lorehold NAO implementadas

### 3.1 MIRACLE -- A Mecanica CORE do Deck

**Lorehold, the Historian:** _"Each instant and sorcery card in your hand has miracle {2}."_

No v7, TODAS as instants e sorceries sao conjuradas pelo custo normal (CMC).
Com miracle, o deck pode conjurar:
- Dance with Calamity (CMC 8) por RRR se comprada no draw step
- Reforge the Soul (CMC 5) por 1R se comprada no draw step
- QUALQUER outra instant/sorcery por {2} + seus custos coloridos

**Impacto no simulador:** O v7 superestima o custo de mana do deck em ~30-50%.
As spells mais caras (CMC 7-10) tem um custo efetivo muito menor com miracle.

**Regras relevantes (CR 702.94):**
- Miracle e uma triggered ability que dispara quando a carta e comprada
- "You may reveal this card from your hand as you draw it if it's the first card you drew this turn"
- "When you reveal this card this way, you may cast it by paying [cost] rather than its mana cost"
- So pode ser usada no momento em que a carta e comprada (como primeira carta do turno)
- Pode ser conjurada como instant mesmo sendo sorcery

**O que o v8 precisa implementar:**
1. No draw step, verificar se a carta comprada e instant/sorcery
2. Verificar se e a primeira carta comprada no turno
3. Se Lorehold estiver no campo, custo miracle = {2} + colored pips
4. Se a carta tiver miracle proprio (Reforge the Soul: 1R), usar o menor
5. Conjurar por custo alternativo no momento do draw

### 3.2 COPY EFFECTS -- Double Vision / Arcane Bombardment

**v7:** `player.copy_engines += 1` (linha 652)
Usado apenas em Mizzix's Mastery para dobrar o dano (`spells = spells * 2`).

**Como deveria funcionar:**
- Double Vision: _"copy that spell. You may choose new targets for the copy."_
- A copia vai para a stack e resolve como um spell normal
- Arcane Bombardment: _"copy the exiled card. You may cast the copy without paying its mana cost."_
- A copia e conjurada, ativando Storm-Kiln Artist e Rite of the Dragoncaller

**O que o v8 precisa:**
- Criar copias reais de spells na stack
- Copias ativam triggers de "whenever you cast" (Storm-Kiln, Rite of the Dragoncaller)
- Copias podem ter novos alvos

### 3.3 TREASURE TOKENS

**v7:** `player.treasures += 1` (linha 529), adicionado ao mana pool como generico.
**Correto na intencao mas incompleto:** Treasure e "{T}, Sacrifice this artifact: Add one mana of any color."
O v7 trata como mana imediata, mas nao modela a decisao estrategica de guardar para turnos futuros.

**O que o v8 precisa:**
- Treasure como permanente (pode ser sacrificado quando quiser)
- Mana de qualquer cor (nao so generica)
- Interage com artefatos (afetado por remocao de artefato)

### 3.4 MIZZIX'S MASTERY -- Nao tem Overload

Mizzix's Mastery nao tem overload. O v7 rotula como `"overload_recursion"` (linha 76)
e faz dano baseado em `len(spells) * 3 * copy_engines`. O efeito real e:
_"Exile target card that's an instant or sorcery from your graveyard. For each card
exiled this way, copy it, and you may cast the copy without paying its mana cost."_

**O que o v8 precisa:**
- Exilar spells do graveyard
- Criar copias e conjura-las (ativando cast triggers)
- Dano e contextual (depende de quais spells estao no graveyard)

### 3.5 AKROMA'S WILL -- Keywords

**v7 (linhas 635-644):** `pump_all` com keywords. Seta `flying`, `double_strike`, `lifelink`,
`indestructible` nas creatures. Dobra power (`c["power"] * 2`).

**Problemas:**
- Double strike no v7 faz a creature causar 3x dano (pwr*2 no first strike + pwr no regular), deveria ser 2x total
- Lifelink e setado mas nunca aplica life gain
- Indestructible e setado nas creatures mas so `player.indestructible` e verificado em board wipes
- Vigilance nao e modelada (creatures atacando nao tappam? Nao importa muito)
- Protection from all colors nao e modelada

### 3.6 BOROS CHARM -- Effect Selection

**v7 KNOWN_CARDS (linhas 67-68):**
```python
"Boros Charm": {"effect": "indestructible", "alt_effect": "double_strike"},
```

**Problema:** `get_card_effect()` so retorna o `effect` principal. `alt_effect` nunca e
usado. Boros Charm SEMPRE da indestructible, nunca double strike.

**As 4 modalidades de Boros Charm:**
1. Deal 4 damage to target player
2. Permanents you control gain indestructible until end of turn
3. Target creature gains double strike until end of turn
4. Untap all creatures you control (Commander 2020)

**O v8 precisa:** Escolher modalidade baseado no contexto (em combate ofensivo = double strike,
em resposta a board wipe = indestructible).

---

## 4. O Sistema de Prioridade + Stack (CR 117 + 405)

### 4.1 Como funciona (resumo para implementacao)

**Priority (CR 117.3-117.4):**
- O jogador ativo recebe prioridade no inicio de cada step/phase
- Com a stack vazia, pode conjurar sorceries (na sua main phase)
- Com a stack nao-vazia, ou no turno de outro jogador, so instants e habilidades
- Quando todos passam prioridade em sequencia, o topo da stack resolve
- Apos resolucao, o jogador ativo recebe prioridade novamente

**Stack (CR 405):**
- LIFO: ultimo a entrar, primeiro a resolver
- Spells, activated abilities, e triggered abilities usam a stack
- Counterspells devem ser conjuradas EM RESPOSTA ao spell alvo, com o alvo ainda na stack

### 4.2 O que o v8 precisa (versao simplificada)

```python
class Stack:
    def __init__(self):
        self.items = []  # (spell, controller)

    def push(self, spell, controller):
        self.items.append((spell, controller))

    def resolve_top(self):
        spell, controller = self.items.pop()
        apply_effect(controller, spell)
        check_sbas()

    def is_empty(self):
        return len(self.items) == 0

def priority_pass(active_player, all_players, stack):
    """
    Cada jogador em ordem recebe prioridade.
    Se ninguem faz nada, resolve o topo da stack.
    """
    # Ordem: active_player -> next in turn order
    for player in turn_order(active_player, all_players):
        if player.is_human:
            # Lorehold decide se conjura instant ou passa
            action = decide_instant_action(player, stack)
            if action:
                stack.push(action['spell'], player)
                return 'action_taken'
        else:
            # Oponente verifica se tem counterspell/removal em resposta
            if player.has_counterspell() and stack.has_threat():
                stack.push(player.use_counterspell(), player)
                return 'action_taken'
    # Ninguem agiu
    if not stack.is_empty():
        stack.resolve_top()
        return 'resolved'
    return 'phase_advance'
```

**Simplificacoes aceitaveis para o v8:**
1. Oponentes so interagem com counterspell (nao fazem instant-speed removal complexo)
2. Prioridade so modelada na main phase e combat (nao em upkeep/draw/end)
3. Stack maxima de 3 spells (evita loops infinitos)
4. Oponentes so respondem se tiverem `counters > 0` E o spell for ameacador
   (finisher, board wipe, ou approach)

### 4.3 Impacto esperado no WR

Com Priority/Stack implementado, oponentes podem counterar ~15-25% das spells
decisivas do Lorehold. Espera-se queda de WR de ~78-94% para ~50-65%, que e
mais realista para Commander.

---

## 5. Instant vs Sorcery Timing

### 5.1 Regras (CR 307, 304)

- **Sorcery:** So na main phase do seu turno, com stack vazia
- **Instant:** Qualquer momento em que tenha prioridade

### 5.2 Impacto no Lorehold

Cartas que mudam de funcao com timing correto:

| Carta | v7 (sempre main) | Com timing correto |
|:------|:------------------|:-------------------|
| Boros Charm | Main phase apenas | Em resposta a board wipe OU durante combate |
| Teferi's Protection | Main phase apenas | Em resposta a ameaca letal |
| Deflecting Swat | Main phase apenas | Em resposta a remocao direcionada |
| Chaos Warp | Main phase apenas | Em resposta a ameaca (remocao instant) |
| Path to Exile / Swords | Main phase apenas | Em resposta a criatura atacante ou combo |
| Abrade | Main phase apenas | Em resposta a artefato ativado |
| Enlightened Tutor | Main phase apenas | EOT (end of turn) antes do seu turno |
| Thrill of Possibility | Main phase apenas | EOT se tiver mana sobrando |
| Big Score / Unexpected Windfall | Main phase apenas | EOT se tiver mana sobrando |

### 5.3 O que o v8 precisa

```python
def can_cast_now(card, player, phase, stack_empty, is_own_turn):
    type_line = card.get('type_line', '')
    is_instant = 'Instant' in type_line
    is_sorcery = 'Sorcery' in type_line

    if is_instant:
        return True  # any time with priority
    if is_sorcery:
        # Sorcery timing: own main phase, stack empty
        return is_own_turn and phase in ('precombat_main', 'postcombat_main') and stack_empty
    # Creatures, artifacts, etc.: own main phase, stack empty
    return is_own_turn and phase in ('precombat_main', 'postcombat_main') and stack_empty
```

---

## 6. Plano de Implementacao v8 (ordenado por impacto)

### FASE A -- Sistema de Interacao (CRITICO, ~200 linhas)

1. **Priority System basico** -- Jogador ativo recebe prioridade; oponentes podem responder
   - Classe `GameState` com `priority_player`, `stack`, `current_phase`
   - Loop: enquanto stack nao-vazia ou ainda tem acoes, passa prioridade
   - Oponentes respondem com counterspell a spells ameacadoras

2. **Stack (LIFO)** -- Spells vao para stack; resolvem em ordem reversa
   - Classe `Stack` com `push()` e `resolve()`
   - Counterspell remove o spell alvo da stack
   - Apos cada resolucao, check SBAs e prioridade volta

3. **Instant vs Sorcery Timing** -- Checar `can_cast_now()` antes de conjurar
   - Instants podem ser conjurados em qualquer prioridade
   - Sorceries so na main phase com stack vazia
   - Boros Charm, Teferi's Protection, Deflecting Swat ganham timing correto

### FASE B -- Mecanicas do Lorehold (ALTO, ~80 linhas)

4. **Miracle** -- Triggered ability no draw step
   - Verificar se a carta comprada e instant/sorcery
   - Se Lorehold no campo, custo = {2} + pips coloridos
   - Se a carta tem miracle proprio, usar o menor custo
   - Conjurar imediatamente (como instant)

5. **Copy Spells na Stack** -- Double Vision / Arcane Bombardment criam copias reais
   - Push copia para stack
   - Copia ativa "whenever you cast" triggers

6. **Treasure Tokens com Sacrifice** -- Permanentes que podem ser sacrificados
   - Adicionar ao battlefield como artefato com "{T}, sacrifice: +1 mana"
   - Decisao: sacrificar agora vs guardar

### FASE C -- Correcoes Pontuais (MEDIO/BAIXO, ~115 linhas)

7. **State-Based Actions** -- Verificar apos cada spell resolver
   - Life <= 0 -> perde
   - Commander damage >= 21 -> perde
   - Poison >= 10 -> perde
   - Creature toughness <= 0 -> morre
   - Draw from empty -> perde (ja tem, mover para SBA check)

8. **Boros Charm effect selection** -- Escolher modalidade por contexto
   - Se tem ameaca de board wipe -> indestructible
   - Se em combate com creatures relevantes -> double strike
   - Se precisa de dano direto -> 4 damage

9. **Haste no Lorehold** -- Commander nao deve ter summoning sickness
   - Verificar keyword "haste" no type_line ou oracle_text

10. **Akroma's Will lifelink** -- Aplicar life gain ao causar dano
    - Se creature tem lifelink, `player.life += damage_dealt`

11. **Indestructible per-creature** -- Nao so `player.indestructible`
    - Board wipe so destroi creatures sem `c.get("indestructible")`

12. **Double Strike dano 2x** -- Corrigir dano total (atualmente 3x)
    - First strike: `a_pwr` = power normal
    - Regular: `a_pwr` = power normal
    - Total = 2x power (nao 3x)

13. **Teferi's Protection timing** -- Phased out retorna no upkeep, nao untap
    - Mover `player.battlefield.extend(player.phased_out)` do untap para upkeep

---

## 7. Estimativa de Esforco

| Fase | Itens | Linhas | Impacto no WR |
|:-----|:------|-------:|:--------------|
| A -- Interacao | Priority + Stack + Instant Timing | ~200 | -20 a -30pp |
| B -- Mecanicas | Miracle + Copy + Treasure | ~80 | -5 a -10pp (Miracle reduz custo!) |
| C -- Correcoes | SBAs + Boros Charm + Haste + Keywords | ~115 | -2 a -5pp |
| **Total v8** | **13 itens** | **~400 novas linhas** | **WR esperado: 45-55%** |

---

## 8. Fontes

- **CR 117 (Timing and Priority):** magic.wizards.com/en/rules
- **CR 405 (Stack):** magic.wizards.com/en/rules
- **CR 702.94 (Miracle):** magic.wizards.com/en/rules
- **CR 704 (State-Based Actions):** magic.wizards.com/en/rules
- **CR 307 (Sorceries), 304 (Instants):** magic.wizards.com/en/rules
- **CR 702.4 (Double Strike), 702.7 (First Strike):** magic.wizards.com/en/rules
- **CR 702.15 (Lifelink), 702.12 (Indestructible):** magic.wizards.com/en/rules
- **Lorehold, the Historian (C21):** scryfall.com/card/c21/34/lorehold-the-historian

---

## 9. Conclusao

O v7 e um goldfish simulator competente (modela fases do turno, commander zone,
combat com blockers, Teferi's Protection real). Mas **sem Priority/Stack/Instant timing,
os WRs nao significam nada alem de "o deck consegue executar seu plano sem interacao."**

O v8 precisa priorizar a **Fase A (Interacao)**. Sem ela, as outras melhorias
(Miracle, Copy, Treasure) sao cosmeticas -- o simulador continua medindo goldfishing.

**Recomendacao:** Implementar Fase A primeiro (200 linhas), rodar o simulador,
comparar WR com v7, E ENTAO decidir se Fase B e C valem o investimento.

---

*Auditoria gerada por Hermes Agent em 2026-05-31 como parte do cron manaloom-commander-knowledge-deep.*
