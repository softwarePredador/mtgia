# Pending Tasks — ManaLoom Commander Battle Engine

> Todas as pendências com descrição exata da lógica a implementar.
> Ordenado por prioridade (P1 = bloqueia confiabilidade, P2 = expande cobertura).
> Referências: CR = Comprehensive Rules oficiais.

Última atualização: 2026-06-09

---

## P1 — Alta Prioridade

### 1. APNAP Trigger Ordering

**O que é**: Quando múltiplas triggered abilities disparam desde a última vez que um jogador recebeu prioridade, elas devem ser colocadas na stack em ordem APNAP (Active Player, Non-Active Player em ordem de turno). Dentro do mesmo controlador, a ordem é escolhida por ele.

**Estado atual**: Triggers resolvem imediatamente, sem ir para a stack. Ex: `emit_replay_event("trigger_resolved", ...)` resolve na hora.

**Lógica exata**:
```python
def settle_triggers():
    batch = []
    for player in turn_order:
        player_triggers = collect_triggered_abilities(player)
        # Player chooses order for their own triggers
        batch.extend(player_triggers)  # APNAP: active first, then others
    
    for trigger in batch:
        stack.push(trigger)  # Goes on stack, doesn't resolve immediately
    
    # After stacking all triggers, SBAs re-check
    check_sbas_until_stable()
    
    # Now priority loop can respond to triggers
```

**Regra**: CR 603.3, CR 603.3b, CR 405

**Arquivos**: `battle_analyst_v8.py` — todas as chamadas `emit_replay_event("trigger_*")`

---

### 2. Prioridade com Pilha Vazia

**O que é**: Jogadores devem receber prioridade durante suas main phases mesmo com a pilha vazia, para poder jogar lands, conjurar criaturas/artifacts/enchantments/planeswalkers em velocidade de sorcery, ou ativar abilities.

**Estado atual**: `priority_round()` retorna imediatamente se `stack.empty()` (linha 2564).

**Lógica exata**:
```python
def run_priority_loop(active_player, all_players):
    current_player = active_player
    pass_count = 0
    
    while True:
        action = get_player_action(current_player)
        if action == "pass":
            pass_count += 1
            if pass_count >= len(all_players):
                break  # All passed in succession
        else:
            pass_count = 0
            execute(action)
            check_sbas_until_stable()
        
        current_player = next_in_turn_order(current_player)
```

**Regra**: CR 117.3, CR 117.4

**Arquivos**: `battle_analyst_v8.py:2563-2620`

---

### 3. Casting Pipeline 601.2

**O que é**: O processo formal de casting de uma spell segue 8 passos: (1) anunciar e mover para stack, (2) escolher modos/alternativas/X, (3) escolher targets, (4) dividir efeitos, (5) checar legalidade, (6) determinar custo total, (7) ativar mana abilities e pagar, (8) spell torna-se cast.

**Estado atual**: Custo calculado inline como `cmd["cmc"] + player.commander_tax` sem lock-in formal, sem suporte a custos alternativos, kicker, X spells, ou hybrid/Phyrexian mana.

**Lógica exata**:
```python
def cast_spell(player, card, stack):
    # 601.2a: Announce and move to stack
    spell = StackItem(card, controller=player)
    stack.push(spell)
    
    # 601.2b: Choose modes, alternative costs, X value
    modes = choose_modes(card)
    x_value = choose_x(card) if has_x(card) else 0
    
    # 601.2c: Choose targets
    targets = choose_targets(card, modes)
    
    # 601.2d: Divide effects (damage, counters)
    divisions = divide_effects(card, targets)
    
    # 601.2e: Check legality
    if not legal_cast(spell, targets):
        revert()  # CR 733.1 — illegal action rewind
    
    # 601.2f: Determine total cost
    base_cost = card.mana_cost or alternative_cost
    additions = sum_additional_costs(card)  # kicker, commander tax
    increases = sum_increasers(card)
    reductions = sum_reducers(card)
    total_cost = base_cost + additions + max(0, increases - reductions)
    total_cost["generic"] += x_value
    spell.locked_cost = total_cost  # LOCK — no further changes
    
    # 601.2g: Activate mana abilities, pay costs
    if not can_pay(player, total_cost):
        revert()
    pay_costs(player, total_cost)
    
    # 601.2h: Spell becomes cast
    spell.is_cast = True
    emit_triggers("when_you_cast", spell)
```

**Regra**: CR 601.2a-601.2h

**Arquivos**: `battle_analyst_v8.py:3524-3820` (cast_spells_v8 e funções relacionadas)

---

### 4. Passos de Combate Formais

**O que é**: O combate deve ter 5 passos distintos: Beginning of Combat, Declare Attackers, Declare Blockers, Combat Damage, End of Combat. Cada passo tem janelas de prioridade.

**Estado atual**: `combat_phase_v8()` é monolítico (linhas 4314-4603). Atacantes são declarados automaticamente, bloqueadores são calculados, não há escolha do jogador.

**Lógica exata**:
```python
def combat_phase():
    # Beginning of Combat step
    begin_step("combat_begin")
    check_sbas_until_stable()
    run_priority_loop(active_player)
    
    # Declare Attackers step
    begin_step("declare_attackers")
    attacker = active_player.choose_attackers()  # Human chooses
    validate_attack_legality(attacker)  # Check restrictions/requirements
    check_sbas_until_stable()
    run_priority_loop(active_player)
    
    # Declare Blockers step
    begin_step("declare_blockers")
    for defending_player in get_defending_players():
        defender.choose_blockers(attacker)  # Human chooses
    validate_block_legality()
    check_sbas_until_stable()
    run_priority_loop(active_player)
    
    # Combat Damage step (first strike if applicable)
    if has_first_strike_or_double_strike():
        assign_combat_damage(first_strike=True)
        check_sbas_until_stable()
        run_priority_loop(active_player)
    
    assign_combat_damage(first_strike=False)
    check_sbas_until_stable()
    run_priority_loop(active_player)
    
    # End of Combat step
    begin_step("end_combat")
    check_sbas_until_stable()
    run_priority_loop(active_player)
    remove_from_combat()
```

**Regra**: CR 506-511

**Arquivos**: `battle_analyst_v8.py:4314-4603`

---

### 5. LKI (Last Known Information)

**O que é**: Quando um objeto muda de zona ou deixa de existir, o motor precisa lembrar suas últimas características conhecidas (LKI) para resolver efeitos que referenciam o objeto após sua saída.

**Lógica exata**:
```python
def move_zone(obj, to_zone):
    # Before moving, snapshot LKI
    obj._lki_snapshot = {
        "name": obj.get("name"),
        "power": obj.get("power"),
        "toughness": obj.get("toughness"),
        "cmc": obj.get("cmc"),
        "colors": obj.get("colors", []),
        "types": obj.get("type_line", ""),
        "controller": obj.get("controller"),
        "owner": obj.get("owner"),
    }
    
    # Move the object
    remove_from_current_zone(obj)
    add_to_zone(obj, to_zone)
    obj.zone_change_counter += 1
    
    # Triggers that fire use LKI if object no longer in expected zone
    for trigger in find_zone_change_triggers(obj):
        if obj not in expected_zone(trigger):
            trigger.use_lki = obj._lki_snapshot
```

**Exemplo**: Criatura com power 5 morre. Trigger "when this creature dies, it deals damage equal to its power" usa LKI: power=5.

**Regra**: CR 608.2g, CR 400.7

**Arquivos**: `battle_analyst_v8.py:2828-2840` (move_creature_from_battlefield)

---

### 6. Zone Change Counter / Instance ID

**O que é**: Cada vez que um objeto muda de zona, ele se torna um "novo objeto" sem memória da existência anterior. Precisa de um contador para distinguir instâncias.

**Lógica exata**:
```python
class GameObject:
    def __init__(self):
        self.instance_id = generate_uuid()
        self.zone_change_counter = 0
        self.current_zone = None
    
    def move_to(self, new_zone):
        if self.current_zone != new_zone:
            self.zone_change_counter += 1
            self.instance_id = generate_uuid()  # New identity
            self.clear_state()  # No damage, no counters, no EOT effects
            self.current_zone = new_zone
```

**Impacto**: Blink, reanimate, flicker, delayed triggers, commander returning from CZ.

**Regra**: CR 400.7

**Arquivos**: `battle_analyst_v8.py` — classe Player e estruturas de carta

---

### 7. Targeting — Partial Resolution

**O que é**: Se um spell/ability tem múltiplos alvos e alguns se tornam ilegais antes da resolução, o spell NÃO é counterado completamente — ele resolve parcialmente, ignorando os alvos ilegais.

**Lógica exata**:
```python
def resolve_spell(spell):
    legal_targets = []
    for target_word in spell.target_groups:  # Each instance of "target"
        remaining = [t for t in target_word if is_legal_target(t, spell)]
        if not remaining:
            # ALL targets for this target word are illegal → spell fizzles
            counter_on_resolution(spell)
            return
        legal_targets.append(remaining)
    
    # Partial resolution: apply to remaining legal targets
    apply_effect(spell, legal_targets)
```

**Exemplo**: "Destroy target artifact and target creature" — se artifact some, ainda destrói a criatura. Se AMBOS somem, fizzle.

**Regra**: CR 608.2b

**Arquivos**: `battle_analyst_v8.py:3644-3669` (apply_effect_immediate)

---

### 8. Ward

**O que é**: Ward é uma triggered ability que countera o spell/ability alvo a menos que seu controlador pague o custo de ward.

**Lógica exata**:
```python
def check_ward(target, spell):
    if not target.get("ward_cost"):
        return False
    
    # Ward triggers when target is chosen
    ward_trigger = TriggeredAbility(
        source=target,
        event="becomes_target",
        controller=target.controller,
    )
    stack.push(ward_trigger)
    
    # When ward resolves:
    def resolve_ward():
        if spell.controller.can_pay(ward_cost) and spell.controller.chooses_to_pay():
            spell.controller.pay(ward_cost)
        else:
            stack.counter(spell)  # Counter the targeting spell
```

**Regra**: CR 702.21a

**Arquivos**: `battle_analyst_v8.py` — targeting logic (ausente)

---

## P2 — Média Prioridade

### 9. Camadas (Layers) 1-7

**O que é**: Características de permanentes são determinadas por efeitos contínuos aplicados em 7 camadas na ordem: (1) copiable values, (2) control, (3) text, (4) type, (5) color, (6) abilities, (7) P/T com subcamadas 7a-7d.

**Lógica exata**:
```python
LAYER_ORDER = [1, 2, 3, 4, 5, 6, 7]

def compute_characteristics(permanent):
    state = permanent.base_characteristics.copy()
    
    for layer in LAYER_ORDER:
        effects = get_continuous_effects_in_layer(layer)
        # Sort by timestamp, respecting dependencies
        effects = topological_sort_by_dependency(effects)
        for effect in effects:
            effect.apply(state, layer)
    
    # Layer 7 sub-layers
    # 7a: Characteristic-defining abilities (CDA)
    # 7b: P/T setting effects
    # 7c: P/T modifying (non-switch, non-counter)
    # 7d: P/T counters
    # 7e: P/T switching
    
    permanent.characteristics = state
```

**Regra**: CR 613.1-613.4

**Arquivos**: Ausente. Precisa ser implementado do zero.

---

### 10. Replacement/Prevention Effects

**O que é**: Efeitos que substituem ou previnem eventos. Ex: "If a creature would die, exile it instead", "Prevent all combat damage", commander replacement (GY/exile → CZ).

**Lógica exata**:
```python
def process_event(event):
    applicable_replacements = find_applicable_replacements(event)
    
    while applicable_replacements:
        if len(applicable_replacements) == 1:
            chosen = applicable_replacements[0]
        else:
            # Self-replacement first, then control, then APNAP
            chosen = choose_replacement_order(event, applicable_replacements)
        
        event = chosen.replace(event)
        applicable_replacements = find_applicable_replacements(event)
    
    # After replacements, apply prevention
    if event.type == "damage":
        applicable_prevention = find_prevention_effects(event)
        for prevention in applicable_prevention:
            event.damage_amount = prevention.prevent(event)
    
    # Commit the final event
    execute(event)
```

**Regra**: CR 614, CR 615

**Arquivos**: Ausente. Precisa ser implementado do zero.

---

### 11. Planeswalkers e Battles

**O que é**: Planeswalkers usam loyalty counters e loyalty abilities (1 por turno). Battles têm defense counters e um protector.

**Lógica exata**:
```python
# Planeswalker
class Planeswalker(Permanent):
    loyalty = initial_loyalty  # From printed loyalty
    abilities_used_this_turn = 0
    
    def can_activate_loyalty(self):
        return (self.controller.has_priority() and 
                stack.is_empty() and 
                self.abilities_used_this_turn == 0 and
                is_main_phase(self.controller))
    
    def take_damage(self, amount):
        self.loyalty -= amount
        # SBA at loyalty <= 0

# Battle (Siege)
class Battle(Permanent):
    defense = initial_defense
    protector = chosen_protector  # An opponent of the controller
    
    def take_damage(self, amount):
        self.defense -= amount
        if self.defense <= 0:
            exile_and_allow_transform_cast(self)
```

**Regra**: CR 306 (Planeswalkers), CR 310 (Battles)

**Arquivos**: `battle_analyst_v8.py` — SBA loop (parcial)

---

### 12. DFC, Adventure e Prototype

**O que é**: Cartas com duas faces (DFC), aventuras e protótipos têm características diferentes dependendo de como são jogadas.

**Lógica exata**:
```python
class Card:
    faces = []  # [front_face, back_face] for DFC
    adventure_part = None  # Adventure spell characteristics
    prototype_alt = None  # Prototype alternative characteristics
    
    def get_characteristics(self, zone, cast_mode):
        if cast_mode == "adventure" and self.adventure_part:
            return self.adventure_part
        if cast_mode == "prototype" and self.prototype_alt:
            return self.prototype_alt
        if zone in ("stack", "battlefield") and self.is_transformed():
            return self.faces[1]  # Back face
        return self.faces[0]  # Front face
    
    def color_identity(self):
        # Color identity includes BOTH faces for DFC
        colors = set()
        for face in self.faces:
            colors.update(face.mana_cost_colors)
            colors.update(face.rules_text_colors)
        return colors
```

**Regra**: CR 711-714

**Arquivos**: Ausente

---

### 13. Tokens e Cópias

**O que é**: Tokens são criados por efeitos e deixam de existir ao sair do battlefield. Cópias de spells na stack não são "cast".

**Lógica exata**:
```python
def create_token(definition, controller):
    token = {
        "name": definition.name,
        "power": definition.power,
        "toughness": definition.toughness,
        "type_line": definition.type_line,
        "is_token": True,
        "owner": controller,
        "controller": controller,
        "zone_change_counter": 0,
    }
    controller.battlefield.append(token)
    return token

# SBA: token outside battlefield → cease to exist
def check_sbas():
    for zone in ("graveyard", "exile", "hand", "library"):
        for obj in zone:
            if obj.get("is_token"):
                cease_to_exist(obj)  # Vanishes, no death trigger

def copy_spell(original):
    copy = {
        "name": original.name,
        "cmc": original.cmc,
        "modes": original.modes,  # Copy cast choices
        "targets": original.targets,
        "is_copy": True,
        "was_cast": False,  # Copies are NOT cast
    }
    stack.push(copy)
```

**Regra**: CR 110.5-110.7 (Tokens), CR 706-707 (Copies)

---

## P2 — Infraestrutura

### 14. Taxonomia Canônica de Derrota

Adicionar ao `classify_loss()`:
- `poison` — 10+ poison counters
- `effect_says_lose` — "you lose the game"
- `effect_says_win` — opponent "wins the game"  
- `concede` — player conceded
- `all_opponents_left` — last player standing

### 15. Telemetria de Saúde do Motor

Adicionar métricas:
- `priority_pass_count` — passes de prioridade por jogo
- `sba_iterations_per_window` — iterações do loop SBA
- `illegal_action_rewinds` — ações ilegais revertidas
- `oracle_fallback_hits` — cartas sem Oracle data

### 16. Suite de Conformidade

Criar testes:
- "Counter war em mesa de 4" — chain de counterspells
- "Blink de comandante e ledger de damage" — commander damage persiste
- "Saga no capítulo final com trigger pendente"
- "Adventure exilada e recast"
- "Concede do active player em resposta"

---

## Progresso (2026-06-09)

| # | Item | Status |
|---|---|---|
| ✅ | SBA loop (check_sbas_until_stable) | Feito |
| ✅ | Creature toughness/damage SBA | Feito |
| ✅ | Legend rule SBA | Feito |
| ✅ | Commander replacement opcional | Feito |
| ✅ | Loss tagging (classify_loss) | Feito |
| ✅ | Taxonomia canônica (poison, concede, effect_says_lose) | Feito |
| ✅ | WDWR/WPWR (card_impact_analyzer) | Feito |
| ✅ | Loss-mode suggester | Feito |
| ✅ | Slot optimizer role fix | Feito |
| ✅ | Ward (check_ward scaffold) | Feito |
| ✅ | LKI + Zone change counter | Feito |
| ✅ | BATTLE_SYSTEM_LOGIC.md | Feito |
| ✅ | IMPLEMENTATION_GAPS.md | Feito |
| ⏳ | APNAP trigger ordering | Pendente |
| ⏳ | Prioridade com pilha vazia | Pendente |
| ⏳ | Casting pipeline 601.2 | Pendente |
| ⏳ | Passos de combate formais | Pendente |
| ⏳ | Targeting partial resolution | Pendente |
| ⏳ | Layers 1-7 | Pendente |
| ⏳ | Replacement effects | Pendente |
| ⏳ | Planeswalkers/Battles | Pendente |
| ⏳ | DFC/Adventure/Prototype | Pendente |
| ⏳ | Tokens/Cópias | Pendente |
| ⏳ | Telemetria de saúde | Pendente |
| ⏳ | Suite de conformidade | Pendente |
