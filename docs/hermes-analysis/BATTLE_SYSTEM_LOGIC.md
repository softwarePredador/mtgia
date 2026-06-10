# Battle System Logic — Documentação Completa

> Documento canônico da lógica de simulação de batalha, otimização e validação.
> Tudo que é usado e pensado em cada etapa do pipeline de análise de deck.

Última atualização: 2026-06-10

---

## 1. Visão Geral do Sistema

O battle system simula partidas de Commander 4 jogadores (Lorehold vs 3 oponentes) para:
- Medir a win rate (WR) do deck atual
- Testar swaps de cartas (slot optimizer)
- Auditar regras de batalha (forensic)
- Medir impacto individual de cada carta (card impact/WDWR)
- Sugerir trocas baseadas em modo de derrota (loss-mode suggester)

### Fluxo completo de análise

```
generate_card_replays.py
  └→ simulate_game_v8() × N jogos
       └→ JSONL replays (turn-by-turn events)
            ├→ card_impact_analyzer.py → WDWR/WPWR por carta
            ├→ loss_mode_suggester.py → sugestões de swap direcionadas
            └→ master_optimizer_baseline.py → WR por matchup
                 └→ slot_optimizer.py → testa swaps por categoria
                      └→ quality_gate.py → valida antes de aplicar
```

---

## 2. Battle Engine (battle_analyst_v9.py)

`battle_analyst_v9.py` é o engine ativo. `battle_analyst_v8.py` permanece
versionado apenas como legado histórico/comparação forense e não deve ser usado
como default de cron ou optimizer.

### 2.1 Arquitetura de Turno

Cada turno de cada jogador segue a sequência:

```
play_turn_sequence_v8(player, opponents, all_players, turn, rng, stack):
  1. untap_step()       — desvira permanentes
  2. draw_step()        — compra 1 carta
  3. precombat_main()   — conjura spells (instants, sorceries, artifacts, creatures)
  4. combat_step()      — declara atacantes, bloqueadores, dano
  5. postcombat_main()  — segunda janela de conjuração
  6. end_step()         — fim do turno, descarte se >7 cartas
```

### 2.2 Sistema de Prioridade (CR 117)

```
Priority System:
  - Cada jogador recebe prioridade por turno
  - Stack LIFO (CR 405): spells resolvem em ordem reversa
  - Instant vs Sorcery timing: instants podem ser conjurados em resposta
  - Oponentes podem counterar spells ameaçadoras
```

### 2.3 State-Based Actions (CR 704)

Verificadas após cada spell resolver:
- `life <= 0` → jogador eliminado
- `failed_draw_from_empty_library` → jogador eliminado
- `deck_out` → jogador eliminado
- `commander_damage >= 21` → jogador eliminado
- `approach_of_the_second_sun` cast 2x → vitória

### 2.4 Mecânicas Específicas Implementadas

| Mecânica | Descrição |
|---|---|
| Miracle (CR 702.94) | Lorehold reduz custo de instants/sorceries em {2} + pips |
| Boros Charm modal | Escolhe indestructible ou double strike por contexto |
| Double Strike | 2x dano total (corrigido de implementações anteriores) |
| Indestructible per-creature | Board wipe respeita indestructible individual |
| Lifelink | Ganho de vida ao causar dano |
| Haste | Lorehold não tem summoning sickness |
| Counterspells | Oponentes podem counterar spells com threat_score alto |
| Vehicle/Spacecraft commander | Legendary Vehicle/Spacecraft com power/toughness é elegível como commander |
| Warp | Custo alternativo, exílio no end step e recast posterior do exile |
| Station | Tap de outra criatura adiciona charge counters e destrava Spacecraft |
| Omen/Prepare/Paradigm | Características/cópias/exile tracking básicos |
| Flashback | Cast do graveyard e exile replacement ao resolver/ser counterado |
| Ability-word telemetry | Void/Repartee/Opus/Increment/Infusion/Converge como sinais, sem enforcement |
| Multi-defender combat | Atacantes podem ser distribuídos entre múltiplos defensores em Commander |

### 2.5 Sistema de Replay (REPLAY_EVENT_HANDLER)

Mecanismo de extensão que permite capturar todos os eventos do jogo sem modificar a engine:

```python
REPLAY_EVENT_HANDLER = None  # setado externamente

def emit_replay_event(event, **data):
    if REPLAY_EVENT_HANDLER:
        REPLAY_EVENT_HANDLER(event, data)
```

Eventos emitidos:
- `turn_start`: hand size, life, board size
- `mana_refreshed`: mana disponível, fontes
- `land_played`: qual carta, efeito
- `spell_cast`: carta, CMC, efeito, fase, rule_source
- `spell_resolved`: carta, efeito, resultado
- `combat`: atacantes, bloqueadores, dano
- `combat_result`: resultado do combate
- `player_eliminated`: jogador, motivo
- `game_ended`: resultado, turno, motivo (adicionado pelo gerador de replays)

### 2.6 Carregamento de Oponentes

```python
load_learned_opponents():
  - Lê learned_decks do SQLite
  - Filtra oponentes reais (is_real=True)
  - Carrega built_deck (lista de 100 cartas com metadata completa)
  - 12 oponentes disponíveis, selecionados aleatoriamente por jogo
```

### 2.7 Parâmetros de Simulação

| Parâmetro | Padrão | Descrição |
|---|---|---|
| GAMES | 50 | Jogos por oponente |
| MAX_TURNS | 35 | Teto de turnos (após = stall) |
| PLAYERS | 4 | Jogadores por partida |
| RNG_SEED | 42 | Seed fixa para reprodutibilidade |

### 2.8 Cobertura de regras oficiais 2026

Rodada de 2026-06-10 alinhada com `RULES_SOURCE_COVERAGE_AUDIT_2026-06-10.md`.

O engine agora distingue:
- `source_zone` e `alternative_cost_kind` no contexto de cast.
- `warp`, `flashback` e casts futuros do exile/graveyard.
- `omen`, `prepare`, `prototype`, `adventure`, split e DFC em `get_card_characteristics`.
- elegibilidade Commander para Legendary Vehicle/Spacecraft com P/T.
- distribuição de atacantes contra múltiplos defensores.

Limite intencional: isso ainda é simulação Commander prática. Não é judge engine
completo para todas as interações CR 613/616 nem para todo texto card-specific.

---

## 3. Root-Cause Loss Tagging (classify_loss)

### 3.1 Tags de Derrota

Após cada jogo, `classify_loss()` analisa o estado final e classifica a derrota:

| Tag | Condição | Significado |
|---|---|---|
| `screw` | Turno ≥ 4, mana < 3, lands < 3 | Falta de mana — deck precisa de mais ramp/lands |
| `flood` | Lands ≥ 7, nonland spells ≤ 2 | Excesso de terra — deck precisa de card draw/filter |
| `out-valued` | Turno ≥ 10, sem screw/flood/combo | Perdeu em valor — deck precisa de card advantage |
| `out-comboed` | Oponente executou combo | Morreu pra combo — deck precisa de stax/counters |
| `bad-mulligan` | Mulligan ≥ 2, turno < 6 | Mão inicial ruim — deck precisa de card selection |
| `commander-removed` | Commander removido ≥ 3x | Commander muito visado — deck precisa de proteção |
| `combat-damage` | Nenhuma tag acima | Morte por dano de combate — deck precisa de removal/blockers |

### 3.2 Dados Coletados Durante o Jogo

Para classificação, o Player rastreia:
- `total_mana_produced`: total de mana gerada
- `nonland_spells_cast`: quantas spells não-terreno foram conjuradas
- `mulligan_count`: quantos mulligans tomou
- `commander_times_removed`: quantas vezes o commander voltou à command zone
- `opponent_combo_detected`: se oponente executou sequência de combo
- `lands_played_this_turn`: lands jogadas (resetado a cada turno)

### 3.3 Exibição no Baseline

O output do baseline mostra loss tags no formato:
```
vs Kinnan WR=0% [W:elimination=1, L:screw=4, L:out-valued=2]
```

---

## 4. Card Impact Scoring (WDWR/WPWR)

### 4.1 Métricas

| Métrica | Definição | Cálculo |
|---|---|---|
| WDWR | When Drawn Win Rate | jogos_ganhos_com_carta_na_mao / jogos_que_carta_apareceu |
| WPWR | When Played Win Rate | jogos_ganhos_com_carta_jogada / jogos_que_carta_foi_jogada |
| Impact Delta | WDWR - Baseline WR | Quanto a carta desvia da média |

### 4.2 Geração de Replays (generate_card_replays.py)

```bash
python3 generate_card_replays.py --games 5 --opponents 6 --deck-id 6
```

- Usa `REPLAY_EVENT_HANDLER` para capturar eventos sem modificar a engine
- Usa `load_deck()` nativo do v8 para carregar cartas com metadata completa
- Gera arquivos JSONL em `master_optimizer_replays/`
- Cada arquivo contém eventos turn-by-turn + game_ended com won/loss

### 4.3 Análise de Impacto (card_impact_analyzer.py)

```bash
python3 card_impact_analyzer.py --replay-dir /path/to/replays
```

- Lê todos os arquivos JSONL
- Rastreia `spell_cast` events para determinar quais cartas foram jogadas
- Usa `game_ended` para classificar vitória/derrota
- Filtra cartas com ≥3 aparições (min-games)
- Ordena por WDWR decrescente

### 4.4 Exemplo de Output

```
Top 10 WDWR:
  Mox Opal                       WDWR=80.0% seen=5 won=4
  Lotus Petal                    WDWR=75.0% seen=4 won=3
  Boros Charm                    WDWR=75.0% seen=4 won=3
  ...
Bottom 5:
  Surge to Victory               WDWR=20.0% seen=5 won=1
  Rapid Hybridization            WDWR= 0.0% seen=3 won=0
  Arcane Signet                  WDWR= 0.0% seen=3 won=0
```

---

## 5. Slot Optimizer (slot_optimizer.py)

### 5.1 Categorização de Cartas

A função `category_for_card()` determina a categoria de cada carta usando 4 fontes em ordem de prioridade:

| Prioridade | Fonte | Exemplo |
|---|---|---|
| 1 (máxima) | Role real do `card_deck_analysis.role_in_deck` / `deck_cards.functional_tag` | Rise of the Eldrazi → wincon |
| 2 | `known_cards.deck_category` | Mapeamento pré-computado |
| 3 | Battle effect → `EFFECT_TO_CATEGORY` | remove_permanent → removal |
| 4 | `functional_tag` da carta | ramp, draw, tutor, etc. |

### 5.2 Proteção Contra Swap Cross-Categoria (v2)

**Correção implementada em 2026-06-09**: O slot optimizer agora prioriza o role real do `card_deck_analysis` sobre o battle effect. Isso evita swaps inválidos como:

```
❌ Rise of the Eldrazi (wincon, CMC 12) → Erode (removal, CMC 2)
✅ Generous Gift (removal, CMC 3) → Erode (removal, CMC 2)
```

### 5.3 Fluxo de Swap

```
Para cada categoria (ramp, draw, removal, protection, wincon, wipe, tutor, engine):
  1. choose_swap_targets(): escolhe carta de maior CMC não-protegida como cut target
  2. legal_candidates(): filtra cartas disponíveis por:
     - Color identity (subset do commander)
     - Commander legality (legal)
     - CMC cap (MAX_CMC_BY_CATEGORY)
     - Já está no deck? (skip)
  3. Para cada candidato (até max_per_category):
     - temporary_swap(): adiciona candidato, remove cut target
     - run_battle(): simula N jogos
     - Calcula WR delta (pp_delta)
     - Restaura deck original
  4. Salva resultados em slot_benchmarks
```

### 5.4 Cartas Protegidas

Nunca são sugeridas como cut target:
- Commander
- `PROTECTED_CARDS`: Sol Ring, Arcane Signet, Command Tower, etc.
- `EXTRA_PROTECTED`: cartas definidas pelo usuário

### 5.5 Categorias e Efeitos

```python
EFFECT_TO_CATEGORY = {
    "ramp_permanent": "ramp", "ramp_ritual": "ramp", "ramp_engine": "ramp",
    "draw_cards": "draw", "draw_engine": "draw", "topdeck_manipulation": "draw",
    "tutor": "tutor",
    "remove_creature": "removal", "remove_permanent": "removal",
    "board_wipe": "wipe",
    "finisher": "wincon", "approach": "wincon", "token_maker": "wincon",
    "overload_recursion": "wincon", "steal_all_creatures": "wincon",
    "pump_all": "wincon", "extra_turn": "wincon",
    "silence_opponents": "protection", "indestructible": "protection",
    "phase_out": "protection", "counter": "protection",
    "copy_spell": "engine", "recursion": "engine", "ripple_engine": "engine",
}
```

---

## 6. Quality Gate (master_optimizer_quality_gate.py)

### 6.1 Validações Antes de Aplicar

Cada candidato de swap passa por:

| Validação | Descrição |
|---|---|
| 100-card legality | Deck precisa ter exatamente 100 cartas |
| Commander color identity | Carta adicionada deve estar na identidade de cor |
| Land count | 30-40 lands |
| Protected cards | Não pode cortar cartas protegidas |
| Role preservation | Categoria do add deve ser compatível com o cut |
| Game Changer/bracket | Respeita budget de bracket |
| Commander plan | Swap não quebra o plano do commander |
| Deck hash match | Deck atual deve bater com o baseline congelado |

### 6.2 Estados de Revisão

| Status | Significado |
|---|---|
| `passed` | Swap passou em todas as validações |
| `blocked` | Swap bloqueado por uma ou mais razões |
| `needs_review` | Swap precisa de revisão manual |

---

## 7. Forensic Audit (battle_forensic_audit.py)

### 7.1 Objetivo

Auditar regras de batalha, não desempenho do deck. Detecta:
- Cartas com regras `needs_review` que afetaram o jogo
- Fontes heurísticas (functional_tag, type_line) em vez de regras verificadas
- Eventos que dependeram de regras não-verificadas

### 7.2 Classificação de Findings

| Severidade | Significado | Ação |
|---|---|---|
| `critical` | Regra quebrada, bloqueia release | Corrigir imediatamente |
| `high` | Dependeu de `needs_review` em wincon/removal/wipe/counter | Bloqueia confiar no optimizer |
| `medium` | Dependeu de `needs_review` ou heurística | Review + promover |
| `low` | Cosmético, sem impacto | Ignorar |

### 7.3 Auto-Promoção de Regras (auto_promote_battle_rules.py)

```python
# Critérios:
# needs_review + idade >= 12h + só medium findings → promove verified
# heuristic + idade >= 24h + só medium findings → promove curated
```

---

## 8. Loss-Mode Swap Suggester (loss_mode_suggester.py)

### 8.1 Pipeline

```
Replay JSONL
  ├→ classify_replays_by_turn() → loss_tags {screw: 6, combat-damage: 5}
  ├→ compute_impact_from_replays() → card_impact {Mox Opal: {wdwr: 80}, ...}
  └→ suggest_swaps_by_loss_mode()
       ├→ Sugestão principal: adicionar {category} com alto WDWR
       └→ Cut candidates: cartas com WDWR mais baixo
```

### 8.2 Mapeamento Loss Mode → Solução

| Loss Mode | Categoria Recomendada | Tipos de Carta |
|---|---|---|
| screw | ramp | ramp, ritual, mana_rock, land |
| flood | draw | draw, card_advantage, wheel, scry |
| out-valued | draw | draw, card_advantage, engine, recursion |
| out-comboed | protection | protection, stax, counter, removal |
| combat-damage | removal | removal, board_wipe, protection |
| bad-mulligan | draw | draw, scry, tutor |
| commander-removed | protection | protection, hexproof, indestructible |

### 8.3 Exemplo de Output

```
LOSS MODE: combat-damage (11/11 (100%))
→ Add removal:
  Mox Opal                          WDWR=80.0%
  Lotus Petal                       WDWR=75.0%

CUT: Rapid Hybridization            WDWR=0.0%
CUT: Arcane Signet                  WDWR=0.0%
```

---

## 9. Pipeline Completo de Otimização

### 9.1 Ordem de Execução (otimizador loop)

```
1. Sync PG    — envia regras de batalha para PostgreSQL
2. Sync SQLite — atualiza cache local do PG
3. Forensic   — audita regras (critical=0, high=0?)
4. Baseline   — mede WR do deck atual contra 12 oponentes
5. Slot Scan  — testa swaps por categoria (ramp, draw, removal, ...)
6. Quality Gate — valida candidatos antes de aplicar
```

### 9.2 Parâmetros Ajustáveis

| Parâmetro | Padrão cron | Padrão teste | Descrição |
|---|---|---|---|
| GAMES_PER_OPPONENT | 3 | 1-50 | Jogos por oponente no baseline |
| SLOT_GAMES | 5 | 1-20 | Jogos por swap no slot optimizer |
| MAX_PER_CATEGORY | 5 | 2-15 | Máximo de cartas testadas por categoria |
| FORENSIC_SEEDS | 5 | 3-20 | Seeds geradas no forensic audit |
| MIN_SEEN_COUNT | 3 | 3 | Mínimo de aparições para WDWR |

### 9.3 Guardrails (Nunca Violar)

1. Não aplicar swap se deck hash ≠ baseline hash
2. Não aplicar swap se carta de corte não existe no deck atual
3. Não aplicar swap se carta de entrada já existe no deck
4. Não aplicar swap de `slot_benchmarks` direto no produto
5. Não aplicar sem `full_confirmation` aprovada
6. Não copiar swap Hermes → produto sem handoff + aprovação humana

---

## 10. Tabelas do Banco (SQLite)

### 10.1 Tabelas de Batalha

| Tabela | Descrição |
|---|---|
| `decks` | Decks registrados (id, nome, lands, CMC, counts) |
| `deck_cards` | Cartas do deck (id, nome, quantity, functional_tag, is_commander) |
| `card_deck_analysis` | Análise detalhada por carta (role_in_deck, synergy, scores) |
| `card_battle_rules` | Regras de batalha (efeito, source, review_status) |
| `slot_benchmarks` | Resultados de swap testados (card_added, card_removed, WR, delta) |
| `optimizer_baseline_runs` | Histórico de baselines (WR, games, hash, matchup data) |
| `optimizer_quality_reviews` | Resultados do quality gate |

### 10.2 Campos Relevantes de `card_deck_analysis`

| Campo | Descrição |
|---|---|
| `role_in_deck` | Papel real da carta (wincon, ramp, removal, engine, etc.) |
| `speed_score` | 1-10: quantos turnos para matar |
| `resilience_score` | 1-10: quão difícil de parar |
| `stealth_score` | 1-10: quanto foco atrai |
| `wincon_total_score` | speed + resilience + stealth (max 30) |
| `pg_roles` | Roles do PostgreSQL (cross-reference) |
| `pg_confidence` | Confiança da classificação PG |

---

## 11. Card Pool (known_cards_generated.json)

Fonte de cartas para o slot optimizer. Contém para cada carta:
- `name`: nome da carta
- `effect`: efeito de batalha (ramp_permanent, remove_creature, etc.)
- `deck_category`: categoria no deck
- `cmc`: converted mana cost
- `color_identity`: identidade de cor
- `battle_rule_source`: fonte da regra (known_cards_manual, curated, generated, heuristic)
- `battle_rule_review_status`: status da regra (verified, needs_review, active)

Filtros aplicados pelo slot optimizer:
- `off_color`: identidade de cor fora da do commander
- `illegal`: commander_legality != "legal"
- `high_cmc`: CMC > MAX_CMC_BY_CATEGORY
- `deck`: já está no deck atual
- `basic`: terra básica

---

## 12. Ferramentas CLI (Resumo)

| Comando | Função |
|---|---|
| `generate_card_replays.py --games N --opponents M` | Gera replays JSONL com dados de carta |
| `card_impact_analyzer.py --replay-dir DIR` | Calcula WDWR/WPWR |
| `loss_mode_suggester.py --replay-dir DIR` | Sugere swaps por modo de derrota |
| `master_optimizer_baseline.py --deck-id 6 --games N` | Mede WR do deck |
| `slot_optimizer.py --deck-id 6 --category ramp --games N` | Testa swaps |
| `master_optimizer_quality_gate.py --deck-id 6` | Valida candidatos |
| `battle_forensic_audit.py --generate N` | Audita regras |
| `auto_promote_battle_rules.py --apply` | Promove regras needs_review→verified |
