# Pending Tasks — ManaLoom Commander Battle Engine

> **Handoff: 2026-06-09.**  
> 19/25 itens implementados no battle_analyst_v9.py (5900+ linhas).
> 6 pendentes de alta complexidade — requerem refatoração arquitetural.
> Tudo documentado com lógica exata, pseudocódigo e referências às Comprehensive Rules.

---

## Progresso

| # | Item | Status |
|---|---|---|
| ✅ | SBA loop (check_sbas_until_stable) | v9:2540 |
| ✅ | Creature toughness/damage SBA | v9:2545 |
| ✅ | Legend rule SBA | v9:2555 |
| ✅ | Poison counter + SBA | v9:2282, 2535 |
| ✅ | Commander replacement opcional | v9:2865 |
| ✅ | classify_loss + taxonomia canônica | v9:4958 |
| ✅ | WDWR/WPWR | card_impact_analyzer.py |
| ✅ | Loss-mode suggester | loss_mode_suggester.py |
| ✅ | Slot optimizer role fix | slot_optimizer.py |
| ✅ | Ward (check_ward scaffold) | v9:3530 |
| ✅ | LKI + Zone change counter | v9:2865, 2863 |
| ✅ | is_legal_target | v9:2596 |
| ✅ | Token lifecycle SBA | v9:2590 |
| ✅ | copy_spell_on_stack | v9:2443 |
| ✅ | 3 docs (LOGIC, GAPS, TASKS) | docs/hermes-analysis/ |
| ✅ | APNAP trigger ordering básico | v9:2444, 2752, tests |
| ✅ | Prioridade com pilha vazia | v9:priority_round/run_priority_loop |
| ✅ | Passos de combate formais | v9:beginning/declare/damage/end combat steps |
| ✅ | Casting pipeline 601.2 mínimo | v9:CastingContext/begin_cast_context/commit_cast_payment |
| ⏳ | Layers 1-7 (continuous effects) | P1 |
| ⏳ | Replacement/Prevention effects | P1 |
| ⏳ | Planeswalkers + Battles | P2 |
| ⏳ | DFC/Adventure/Prototype | P2 |
| ⏳ | Telemetria de saúde do motor | P2 |
| ⏳ | Suite de conformidade | P2 |

---

## Ordem Recomendada de Implementação

| Ordem | Item | Esforço | Impacto | Depende de |
|---|---|---|---|---|
| 1 | Replacement effects | 5-7 dias | Alto | — |
| 2 | Casting pipeline 601.2 avançado | 5-7 dias | Alto | 601.2 mínimo |
| 3 | Layers 1-7 | 7-10 dias | Alto | #1 |
| 4 | Planeswalkers/Battles | 3-4 dias | Médio | combate/casting |
| 5 | DFC/Adventure/Prototype | 4-5 dias | Médio | #1 |
| 6 | Telemetria de saúde | 2-3 dias | Médio | — |
| 7 | Suite de conformidade | 5-7 dias | Alto | #1-6 |

---

## P1 — Kernel de Regras

### 1. APNAP Trigger Ordering

**Status 2026-06-09**: ✅ APNAP básico implementado.

**Arquivos**:
- `battle_analyst_v9.py`: `_pending_triggers`, `enqueue_trigger`, `flush_triggers_in_apnap`, `resolve_or_enqueue_trigger`, `triggered_ability` no `priority_round`.
- `test_battle_analyst_v10_3.py`: `test_apnap_trigger_order_puts_nonactive_trigger_on_top`, `test_same_controller_triggers_keep_timestamp_stack_order`.

**O que foi coberto**:
- Triggers entram na stack como `triggered_ability`.
- Ordem APNAP: active player primeiro, non-active depois, logo non-active resolve primeiro por LIFO.
- Chamadas legadas sem `stack` continuam resolvendo imediatamente para compatibilidade.
- Estado global de triggers é limpo entre simulações e testes.

**Regra**: CR 603.3, CR 603.3b

**Limite restante**: escolha manual de ordenação pelo jogador e triggers aninhadas complexas ainda precisam de suite própria, junto com o pipeline 601.2 avançado.

---

### 2. Prioridade com Pilha Vazia nos Main Phases

**Status 2026-06-10**: ✅ Implementado.

**Arquivos**:
- `battle_analyst_v9.py`: `priority_round(..., phase=...)`, `run_priority_loop`, `cast_spells_v8(..., max_actions=...)`.
- `test_battle_analyst_v10_3.py`: `test_empty_stack_priority_requires_main_phase`, `test_empty_stack_priority_casts_main_phase_creature`, `test_main_phase_priority_loop_casts_bounded_empty_stack_actions`.

**O que foi coberto**:
- `priority_round` não age com stack vazia fora de main phase.
- `priority_round(..., phase="precombat_main"|"postcombat_main")` permite uma ação sorcery-speed.
- `run_priority_loop` aplica janelas vazias de main phase de forma limitada e resolve a stack/triggers entre ações.
- O turno usa `run_priority_loop` nas duas main phases.

**Limite restante**: ainda não é o loop completo APNAP com escolha humana/interativa para todos os jogadores; isso será aprofundado junto do casting pipeline 601.2 avançado e combate formal.

**Regra**: CR 117.3, CR 117.4

---

### 3. Casting Pipeline 601.2

**Status 2026-06-10**: ✅ Mínimo implementado / ⚠️ avançado pendente.

**Arquivos**:
- `battle_analyst_v9.py`: `CastingContext`, `begin_cast_context`, `commit_cast_payment`, integração em `cast_spells_v8`.
- `test_battle_analyst_v10_3.py`: `test_casting_context_locks_cost_before_payment`, `test_casting_context_rejects_illegal_timing_without_payment`, `test_cast_spells_emits_minimal_601_pipeline_fields`.

**O que foi coberto**:
- Announce/evento `cast_announced` antes de pagamento.
- Custo travado via `locked_cost` antes do pagamento.
- Custo de comandante inclui `commander_tax` como `additional_generic`.
- Timing básico impede creature/sorcery fora de main phase.
- Pagamento usa `Player.spend_mana` sobre o custo travado.
- Eventos de cast carregam `cast_pipeline=601.2_minimal`, `locked_cost`, `additional_generic` e `role`.

**Limite restante**:
- Ainda não escolhe formalmente modes, X, alternative costs, kicker/flashback/prototype ou divisão de efeitos.
- Targeting formal ainda fica no bloco próprio de targeting.
- Hybrid/Phyrexian e spend restrictions seguem pendentes.

**Regra**: CR 601.2a-601.2h

---

### 4. Passos de Combate Formais

**Status 2026-06-10**: ✅ Implementado como refatoração incremental.

**Arquivos**:
- `battle_analyst_v9.py`: `beginning_of_combat_step`, `declare_attackers_step`, `declare_blockers_step`, `combat_damage_steps`, `end_of_combat_step`.
- `test_battle_analyst_v10_3.py`: `test_combat_emits_structured_event` valida sequência `combat_step`.

**O que foi coberto**:
- Evento formal `combat_step` para `beginning_of_combat`.
- Declaração de atacantes em função dedicada, mantendo target heuristic existente.
- Janela de remoção instant-speed depois dos atacantes declarados.
- Declaração de bloqueadores em função dedicada.
- Damage step dedicado, incluindo first strike/double strike quando aplicável.
- Evento formal `combat_step` para `end_of_combat`.
- Eventos legados `combat` e `combat_result` preservados para consumidores atuais.

**Limite restante**: atacantes/bloqueadores ainda são escolhidos por heurística automática; requirements/restrictions avançadas e escolha interativa ficam pendentes para a suite de conformidade e casting pipeline.

---

### 5. Replacement/Prevention Effects

**Gap**: Completamente ausente. Nenhum efeito de substituição ou prevenção.

**Arquivo**: Novo módulo ou adição ao v9

**Implementação**:
```python
class ReplacementRegistry:
    """Registro de efeitos de replacement/prevention ativos."""
    
    @staticmethod
    def process_event(event, affected_player):
        """Aplica replacement effects em ordem (CR 614, 616)."""
        applicable = ReplacementRegistry.find_applicable(event, affected_player)
        
        while applicable:
            if len(applicable) == 1:
                chosen = applicable[0]
            else:
                # Self-replacement > control-change > APNAP (CR 616.1)
                chosen = ReplacementRegistry.choose_order(event, applicable, affected_player)
            
            event = chosen.replace(event)
            applicable = ReplacementRegistry.find_applicable(event, affected_player)
        
        # Prevention (CR 615) — only for damage events
        if event.type == "damage":
            preventions = find_prevention_effects(event)
            for p in preventions:
                event.amount = max(0, event.amount - p.shield_amount)
        
        return event  # Event is now final, execute it

# Exemplo: Commander replacement
ReplacementRegistry.register(
    match=lambda e: e.type == "zone_change" and e.card.get("is_commander") 
                    and e.to_zone in ("graveyard", "exile", "hand", "library"),
    replace=lambda e: setattr(e, "to_zone", "command_zone") if e.owner_chooses() else e
)
```

**Regra**: CR 614 (Replacement), CR 615 (Prevention), CR 616 (Interaction)

---

### 6. Layers 1-7 (Continuous Effects)

**Gap**: Completamente ausente. Sem engine de continuous effects.

**Arquivo**: Novo módulo dedicado

**Implementação**: Ver seção 6 do BATTLE_SYSTEM_LOGIC.md. As 7 camadas:
- Layer 1: Copiable values
- Layer 2: Control-changing
- Layer 3: Text-changing
- Layer 4: Type-changing
- Layer 5: Color-changing
- Layer 6: Ability-adding/removing
- Layer 7: P/T (7a: CDA, 7b: set, 7c: modify, 7d: counters, 7e: switch)

Dentro de cada camada, efeitos são ordenados por timestamp com resolução de dependências.

---

## P2 — Tipos Complexos

### 7. Planeswalkers e Battles

**Implementação**:
```python
# Planeswalker
def handle_planeswalker_etb(card, controller):
    card["loyalty"] = card.get("starting_loyalty", 3)
    card["loyalty_used_this_turn"] = False

def can_activate_loyalty(player, planeswalker):
    return (not planeswalker.get("loyalty_used_this_turn") 
            and player.has_priority()
            and stack.empty()
            and is_main_phase(player))

def damage_to_planeswalker(source, planeswalker, amount):
    planeswalker["loyalty"] = (planeswalker.get("loyalty", 0) - amount)
    # SBA at loyalty <= 0 (já implementado em check_sbas)

# Battle (Siege)
def handle_siege_etb(card, controller, opponents):
    # Controller chooses an opponent as protector
    card["protector"] = opponents[0]  # Sim: first opponent
    card["defense"] = card.get("defense", 5)

def battle_takes_damage(battle, amount):
    battle["defense"] = (battle.get("defense", 0) - amount)
    if battle["defense"] <= 0:
        exile_and_allow_transform(battle)

# SBA adicionais:
# - Planeswalker loyalty <= 0 -> graveyard
# - Battle defense <= 0 -> exile + transform cast
```

---

### 8. DFC/Adventure/Prototype

**Implementação**:
```python
def get_card_characteristics(card, zone, cast_mode=None):
    """Retorna características corretas baseado em zona e modo de cast."""
    # DFC: fora da stack/battlefield = front face
    if card.get("is_dfc"):
        if zone in ("stack", "battlefield") and card.get("is_transformed"):
            return card["back_face"]
        return card["front_face"]
    
    # Adventure: spell na stack usa adventure part
    if cast_mode == "adventure" and card.get("adventure"):
        return card["adventure"]
    
    # Prototype: spell na stack pode usar prototype alt
    if cast_mode == "prototype" and card.get("prototype"):
        return card["prototype"]
    
    # Split: na stack = metade escolhida; fora = combinado
    if card.get("is_split"):
        if zone == "stack":
            return card[card.get("chosen_half", "half_a")]
        # Fora da stack: mana value combinado
        return {
            "mana_value": card["half_a"]["cmc"] + card["half_b"]["cmc"],
            "colors": card["half_a"]["colors"] + card["half_b"]["colors"],
        }
    
    return card

def compute_color_identity(card):
    """Color identity inclui TODAS as faces (CR 903.4)."""
    colors = set()
    for face in [card] + card.get("faces", []):
        colors.update(extract_mana_symbol_colors(face.get("mana_cost", "")))
        colors.update(extract_text_colors(face.get("oracle_text", "")))
        if face.get("color_indicator"):
            colors.update(face["color_indicator"])
    return colors
```

---

## P2 — Infraestrutura

### 9. Telemetria de Saúde do Motor

**Implementação**:
```python
class EngineMetrics:
    """Coleta métricas de saúde do motor de regras."""
    def __init__(self):
        self.priority_passes = 0
        self.sba_iterations = []
        self.illegal_rewinds = 0
        self.oracle_fallbacks = 0
        self.stack_max_depth = 0
        self.triggers_per_window = []
        self.game_duration_turns = 0
    
    def snapshot(self):
        return {
            "total_priority_passes": self.priority_passes,
            "avg_sba_iterations": sum(self.sba_iterations)/max(1,len(self.sba_iterations)),
            "illegal_rewinds": self.illegal_rewinds,
            "oracle_fallbacks": self.oracle_fallbacks,
            "max_stack_depth": self.stack_max_depth,
        }

# Hook nos pontos de medição:
# check_sbas_until_stable: registrar sba_iterations
# priority_round: incrementar priority_passes
# illegal action revert: incrementar illegal_rewinds
```

---

### 10. Suite de Conformidade

**Cenários mínimos** (cada um deve ser um teste reproduzível):
```python
CONFORMANCE_SCENARIOS = [
    {
        "name": "counter_war_4p",
        "setup": "4 players, spell on stack, chain of counterspells",
        "expected": "stack resolves in LIFO, all players had priority in APNAP",
        "rule": "CR 117, 405, 608"
    },
    {
        "name": "commander_damage_ledger",
        "setup": "Commander deals 21 damage across multiple zone changes",
        "expected": "player loses at exactly 21, ledger persists through blink",
        "rule": "CR 903.10a, 903.14"
    },
    {
        "name": "saga_final_chapter",
        "setup": "Saga at final chapter, trigger on stack, SBA check",
        "expected": "saga sacrificed only after final chapter leaves stack",
        "rule": "CR 714.4"
    },
    {
        "name": "adventure_recast",
        "setup": "Cast Adventure, exile on resolve, cast creature from exile",
        "expected": "creature cast from exile, not adventure zone",
        "rule": "CR 715.3"
    },
    {
        "name": "blocked_stays_blocked",
        "setup": "Attacker blocked, blocker removed before damage",
        "expected": "attacker remains blocked, deals 0 damage to player",
        "rule": "CR 509.1h"
    },
    {
        "name": "active_player_concede",
        "setup": "Active player concedes during their own main phase",
        "expected": "turn continues without active player, priority passes to next",
        "rule": "CR 800.4a"
    }
]
```

---

## Arquivos do Projeto

| Arquivo | Descrição | Linhas |
|---|---|---|
| `battle_analyst_v9.py` | Engine de batalha com todas as melhorias v9 | 5867 |
| `battle_analyst_v8.py` | Engine legado/histórico; não usar como default operacional | 5263 |
| `master_optimizer_common.py` | Funções comuns do optimizer | ~700 |
| `master_optimizer_baseline.py` | Baseline (WR do deck) | ~100 |
| `slot_optimizer.py` | Teste de swaps por categoria | ~550 |
| `master_optimizer_quality_gate.py` | Validação de swaps | ~80 |
| `battle_forensic_audit.py` | Auditoria de regras de batalha | ~500 |
| `optimizer_loop.sh` | Pipeline completa (usa v9 via env var) | ~100 |
| `generate_card_replays.py` | Gerador de replays JSONL | ~120 |
| `card_impact_analyzer.py` | WDWR/WPWR | ~300 |
| `loss_mode_suggester.py` | Sugestão de swap por loss mode | ~280 |
| `auto_promote_battle_rules.py` | Auto-promoção de regras | ~150 |

---

## Engine Ativo no Optimizer

O optimizer loop e os fallbacks atuais já usam v9. Para deixar explícito no
Hermes/AWS:
```bash
export MANALOOM_BATTLE_SCRIPT="/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py"
```

Ou rodar diretamente:
```bash
MANALOOM_BATTLE_SCRIPT=.../battle_analyst_v9.py python3 master_optimizer_baseline.py --deck-id 6 --games 10
```
