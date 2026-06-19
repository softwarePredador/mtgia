# Battle System Logic — Documentação Completa

> Documento canônico da lógica de simulação de batalha, otimização e validação.
> Tudo que é usado e pensado em cada etapa do pipeline de análise de deck.

Última atualização: 2026-06-18

Revisão estratégica oficial: 2026-06-11
(`BATTLE_RULES_2026_STRATEGIC_REVIEW_2026-06-11.md`).

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

`battle_analyst_v9.py` é o único engine ativo e versionado no diretório
operacional. Os arquivos `battle_analyst.py`, `battle_analyst_v6.py`,
`battle_analyst_v7.py` e `battle_analyst_v8.py` foram removidos para evitar
divergência de fonte de verdade. Relatórios antigos ainda podem mencionar v8,
mas isso é histórico e não deve orientar implementação, cron, optimizer ou
auditoria atual.

### 2.1 Arquitetura de Turno

Cada turno de cada jogador segue a sequência operacional abaixo. O nome
`play_turn_v8`/`play_turn_sequence_v8` permanece por compatibilidade historica,
mas o arquivo ativo e `battle_analyst_v9.py`.

```
play_turn_sequence_v8(player, opponents, all_players, turn, rng, stack):
  1. turn_start         — reset de contadores de turno e protecoes temporarias
  2. untap             — desvira permanentes; sem prioridade
  3. upkeep            — triggers simplificados, como burden/draw engine
                         e, quando aplicável, upkeep rummage do Lorehold
                         em turnos de oponentes
  4. draw              — compra de turno, miracle/Lorehold e deck-out SBA
  5. precombat_main    — land drop, triggers de landfall/opponent land play,
                         ativacoes land-tutor e priority loop de spells
  6. combat            — beginning of combat, declare attackers, declare blockers,
                         first strike/regular damage e end of combat
  7. extra_combat      — ate o cap anti-loop quando efeito agenda combate extra
  8. postcombat_main   — segunda priority loop de spells
  9. end_step          — triggers simplificados, warp e uma janela limitada de
                         instant por oponente
 10. cleanup           — descarte ate 7, clear until-EOT e SBA final
```

Limitacoes conhecidas desta arquitetura:

- Upkeep ainda nao e uma fila generica completa de todos os triggers possiveis.
- Cleanup descarta ate sete e roda SBA final, mas ainda nao modela
  integralmente a excecao CR 514.3a em que SBA/trigger no cleanup gera
  prioridade e outro cleanup.
- End-step interaction e limitada por heuristica para evitar loops.
- O engine e simulador Commander heuristico/auditavel, nao judge engine
  competitivo completo.

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
| Lorehold upkeep rummage | upkeep de oponente pode descartar/comprar com trace auditável e abrir janela de miracle |
| Boros Charm modal | Escolhe indestructible ou double strike por contexto |
| Double Strike | 2x dano total (corrigido de implementações anteriores) |
| Indestructible per-creature | Board wipe respeita indestructible individual |
| Toughness <= 0 SBA | Criatura morre mesmo se for indestrutivel; indestrutivel so impede destruicao/dano letal |
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

### 2.5.1 Decision Trace v1

Desde 2026-06-15, o engine tambem suporta `DECISION_TRACE_HANDLER` como
side-channel opcional. Ele nao altera ordem de prioridade, mana, stack, combate
ou resultado da partida; apenas grava a decisao tomada.

Cada decisao registra:
- `decision_id`
- `replay_id`
- `turn`
- `phase`
- `player`
- `decision_type`
- `available_options`
- `chosen_option`
- `rejected_options`
- `score_components`
- `rule_source`
- `rule_status`
- `confidence`
- `expected_benefit_score`
- `actual_outcome`
- `strategic_principle`
- `heuristic_version`
- `resource_delta`
- `risk_flags`
- `alternatives_considered`
- `rejected_reason`
- `chosen_option_score`
- `available_option_scores`
- `rejected_option_scores`
- `best_available_option_score`
- `best_rejected_option_score`
- `score_gap_vs_best_rejected`
- `expected_payoff_reason`

Cobertura inicial:
- mulligan pregame;
- cast de ramp;
- cast de spell normal;
- cast de criatura;
- cast high-threat/wincon;
- resposta com protection/counter;
- ataque/combat target;
- pass/no-action de prioridade.
- tutor com alvo, alternativas e motivo contextual;
- board wipe com assimetria, criaturas/poder proprio vs oponentes e pressao
  lethal;
- wheel-like draw com tamanho de mao, refill risk, payoff e
  `model_scope=multiplayer_discard_draw_v1`.
- upkeep do Lorehold com `lorehold_upkeep_rummage`, replacement de
  `Library of Leng` e reorder parcial de `Sensei's Divining Top`.

No slice de 2026-06-18, `pass/no-action` deixou de ser apenas
`empty_stack_no_action`: o trace agora diferencia janelas como
`hold_instant_speed_interaction`, `no_affordable_nonland_action`,
`phase_or_heuristic_restriction_blocks_line`, `reactive_window_held` e
`no_nonland_resources_available`, além de registrar alternativas consideradas
e flags de risco coerentes com o estado da mão.

No slice seguinte de 2026-06-18, o trace passou a materializar comparativo
minimo auditavel: quando as opcoes ja possuem score no runtime, o replay grava
`chosen_option_score`, lista de scores disponiveis/rejeitados, melhor score
rejeitado, `score_gap_vs_best_rejected` e `expected_payoff_reason`. `pass` com
linhas jogaveis tambem passou a pontuar as alternativas, e os casts genericos
de ramp/criatura/spell normal deixaram de sair sem score comparativo quando a
heuristica ja tinha ranking local.

No slice de fechamento de 2026-06-18, o upkeep rummage do Lorehold tambem
passou a emitir `rejected_options` e scores comparativos. A prova viva local
com seed fixa gerou `1098` eventos estruturados e `152` decision traces; o
`replay_decision_auditor.py --require-decision-trace --skip-baseline --report`
fechou com `turn_findings=0`, `decision_findings=0`, `critical=0`, `high=0`,
`medium=0` e `low=0`.

No slice de 2026-06-19, `mulligan_decision` tambem passou a pontuar
explicitamente `keep` vs `mulligan` no trace. Maos como `3 lands + quatro
spells custo 8/9` agora registram `chosen_option_score`,
`best_rejected_option_score`, `score_gap_vs_best_rejected` e `risk_flags`
como `expensive_dead_hand`, sem mudar a decisao da simulação.

Auditoria:

```bash
python3 replay_decision_auditor.py \
  --events /path/replay.jsonl \
  --decision-trace /path/replay.decision_trace.jsonl \
  --require-decision-trace
```

Auditoria estrategica complementar:

```bash
python3 battle_decision_strategy_auditor.py \
  --events /path/replay.jsonl \
  --decision-trace /path/replay.decision_trace.jsonl \
  --output /path/strategy_audit.md \
  --json-output /path/strategy_audit.json
```

Uso correto:
- `unknown` e `needs_review` sao achados auditaveis, nao enforcement duro.
- WR alto de Lorehold nao vira conclusao confiavel sem trace limpo, baseline
  fresco e amostra minima.
- Persistencia atual e somente artefato JSON/MD; SQLite/PG ficam fora ate o
  formato estabilizar.
- Legalidade e estrategia sao camadas diferentes: uma jogada pode ser legal
  mas ainda ser marcada como fraca se gastar Lotus Petal sem payoff, descartar
  land unica no Mox Diamond, sacrificar land sem alvo relevante ou manter mao
  sem plano inicial.
- No fechamento do slice de resource trace em 2026-06-18, linhas de
  `ramp_ritual`, `requires_discard_land` e `requires_sacrifice_land`
  passaram a registrar contexto de payoff/beneﬁcio: `unlock_card`,
  `unlock_role`, `unlock_effect`, `unlock_reason`, `resource_gate`,
  `resource_land`, `imprint_card` e `strategic_benefit_reason`.
- O auditor estrategico agora usa isso para flagar
  `resource_risk_without_payoff_reason` quando uma jogada com
  `spending_last_land` ou `spending_unique_color_land` nao documenta por que
  o recurso escasso foi gasto.
- A politica atual de opening hand precisa continuar alinhada a fontes externas
  estaveis: a regra dura e London Mulligan, e a heuristica minima de Commander
  precisa avaliar `curve + color + plan + sequencing + interaction`, nao apenas
  contagem de lands.
- O bottom do London Mulligan nao deve ser aleatorio. Desde 2026-06-17,
  `choose_mulligan_bottom_cards()` prioriza cartas caras/mortas para o fundo,
  preserva lands necessarias quando a mao tem ate 3 lands, preserva ramp/early
  interaction live e so bottoma land em excesso quando nao existe spell morta
  melhor. Isso ainda e heuristica, mas torna a decisao reproduzivel e testavel.
- Em 2026-06-18 a heuristica de keep ficou mais estrita: a abertura agora
  classifica explicitamente `ramp`, `card_flow`, `engine`, `board` e
  `reactive_only`. Spell reativa isolada deixou de justificar keep em maos
  land-heavy, e um unico corpo barato nao mascara mais uma mao `3 lands +`
  cluster de bombas `7+` sem setup.
- As rejeicoes novas ficaram explicitas no runtime e no trace:
  `reactive_only_opener`, `land_heavy_reactive_only` e
  `expensive_cluster_without_setup`. Isso fecha o caso "legal mas morta" sem
  depender apenas da contagem de terrenos.
- O `decision_trace_v1` de mulligan agora tambem carrega `plan_role`,
  `card_flow_count`, `proactive_board_count`, `reactive_only_count` e
  `high_cost_cluster_count`, deixando rastreavel por que a mao foi mantida ou
  devolvida.
- No follow-up de 2026-06-18, a heuristica tambem deixou de tratar como
  "plano valido" cartas cedo que so seriam castaveis off-color: o runtime usa
  `mana_cost` real + subconjuntos possiveis dos terrenos na mao para decidir se
  um ramp/card-flow/engine/board inicial esta realmente live. Isso tambem
  entrou no bottom do London Mulligan, que agora prioriza spell cedo morta por
  cor antes de bottomar terreno excedente quando a mao ja tem bomba mais cara
  para devolver.
- Fast mana condicional conta como recurso inicial apenas quando a condicao de
  producao esta ativa no estado da partida ou na linha inicial prevista. Exemplo
  concreto ja fechado localmente: `Mox Amber` nao pode justificar keep nem
  entrar no score de ramp sem uma criatura lendaria ou planeswalker relevante
  que realmente ligue sua mana no early game.
- A partir da politica `battle_decision_strategy_v1_2026_06_15`, Mox
  Diamond/permanent fast mana que exige descarte de land nao pode contornar o
  loop de ramp: se a escolha consumiria ultima land ou land de cor unica, o
  cast so e permitido quando destrava comandante ou spell de alto impacto no
  mesmo turno. Isso evita que uma jogada legal mas estrategicamente ruim vire
  dado de aprendizado.
- A rotina de 16 seeds `20260615_162840`, depois dos guardrails de Mox e
  land-sacrifice, ficou sem blockers estrategicos high/critical:
  `mox_land_discard=coherent_in_sample` e `sacrifice_land=coherent_in_sample`.
  Esses pontos seguem monitorados por corpus maior, mas nao bloqueiam o batch
  atual.
- Tutor esta coerente na amostra atual: o alvo agora e escolhido por estado
  (mana/fix, interacao, engine, wincon, impacto material ou setup), nao apenas
  por maior CMC.
- Board wipe/wheel deixou de ser blocker na rodada reproduzida
  `20260615_172608`: wipe precisa justificar assimetria/lethal prevention,
  estar atras ou ter rebuild plan; wheel-like draw descarta e compra para todos
  os jogadores vivos no modelo `multiplayer_discard_draw_v1` e registra refill
  risk/payoff. Ainda falta corpus maior, hand-quality e payoff-denial mais
  completo antes de usar como heuristica final de aprendizado.
- Em 2026-06-17, `Dismember` foi promovido para
  `curated/verified` como `stat_modifier_removal_until_eot_v1`
  (`-5/-5` ate o fim do turno, custo `{1}{B/P}{B/P}`), e o SBA foi corrigido
  para matar criaturas com resistencia `<= 0` mesmo se tiverem
  indestrutivel. A rodada local de 2 seeds `20260617_005901` fechou com
  `action_findings=0` e `strategy_findings=0`; o low anterior
  `review_rule_used` de `Dismember` desapareceu.
- Forums/artigos de estrategia podem calibrar heuristicas; comportamento duro
  continua exigindo regra oficial, replay e teste focado.

### 2.5.2 Runtime rule provenance and fallback order

O runtime atual do battle nao deve mais resolver regras de carta a partir de um
inventario manual oculto.

Ordem correta de resolucao:

1. waiver manual explicito e temporario (`MANUAL_RULE_RUNTIME_WAIVERS`);
2. `battle_card_rules` via registry/cache SQLite/PG;
3. `known_cards_canonical_snapshot.json` como fallback canonico degradado;
4. `functional_tags_json` / heuristicas / `unknown`.

`known_cards_generated.json` nao e mais fallback executavel do
`battle_analyst_v9.py`. Ele fica no repositorio apenas como input historico de
sync/auditoria ate a limpeza completa dos consumidores secundarios.

Atualizacao 2026-06-17: o loader compartilhado
`known_cards_fallback_snapshot.load_layered_known_cards()` tambem passou a ser
canonico por padrao. Consumidores operacionais como `slot_optimizer.py`,
`universal_optimizer.py`, `battle_effect_coverage_audit.py` e
`sync_pg_card_metadata_to_hermes.py` nao optam mais por
`known_cards_generated.json`; apenas scripts de geracao, sync seed e auditoria
de drift podem pedir explicitamente esse arquivo.

Atualizacao 2026-06-19: mesmo como legado, `known_cards_generated.json` nao
deve recriar semantica falsa para cartas centrais. `generate_known_cards.py` e
`kc_validator.py` passaram a manter overrides completos para
`Lorehold, the Historian`, `Library of Leng`, `Sensei's Divining Top`,
`Scroll Rack`, `Brainstone` e `Approach of the Second Sun`. Alem disso,
artefato sem texto explicito de mana nao pode cair em `ramp_permanent` apenas
por possuir `Artifact` no `type_line`; nesses casos o fallback correto e
`unknown` ate existir regra revisada ou heuristica rastreavel.

Atualizacao 2026-06-19: a linha `Approach of the Second Sun` + ferramentas de
topo ganhou evidencia de `decision_trace_v1`. O teste focado registra
`Brainstone`, `Sensei's Divining Top` e `Scroll Rack` como opcoes
comparativas de `topdeck_setup`, preserva `rule_source/status`, score e
`risk_flags`. Isso ainda nao transforma a manipulacao de topo em executor duro:
o trace prova que a decisao e auditavel, enquanto a execucao completa de
reordenar/comprar/posicionar Approach permanece gap separado.

Atualizacao 2026-06-19: a execucao completa da linha `Sensei's Divining Top` +
`Lorehold, the Historian` + `Approach of the Second Sun` tambem passou a ter
teste focado. O replay controlado prova: Top reordena `Approach` para o topo,
o rummage do Lorehold descarta uma carta morta, compra `Approach`, miracle-casta
a segunda copia e gera `game_won reason=approach`. Naquele ponto,
`Scroll Rack` e `Brainstone` ainda estavam em fila separada para cobertura
executavel/policy reutilizavel.

Atualizacao 2026-06-19: `Scroll Rack` tambem passou a ter replay executavel na
linha de Lorehold. O gate de `hand_to_top_exchange` agora aceita
`opponent_upkeep`, que representa ativar Scroll Rack em resposta a trigger de
upkeep do Lorehold antes do rummage resolver. O teste prova a troca
`Approach` da mao para o topo, compra via rummage, miracle e vitoria por
segunda resolucao. Naquele ponto, `Brainstone` permanecia pendente por exigir
executor proprio de `{2}, {T}, sacrifice: draw three, put two back`.

Atualizacao 2026-06-19: `Brainstone` tambem passou a ter replay executavel
conservador na linha de Lorehold. O runtime so sacrifica Brainstone quando a
primeira carta comprada ja e um alvo de miracle de alta prioridade, ha mana
para pagar `{2}` + o custo de miracle, ha cartas suficientes para colocar duas
de volta no topo e a ativacao fecha uma janela imediata. O teste prova:
Brainstone compra `Approach of the Second Sun` como primeira carta, coloca duas
cartas de volta, miracle-casta a segunda resolucao e encerra com
`game_won reason=approach` antes do rummage continuar. A policy genérica para
outros comandantes/linhas ainda fica separada.

Guardrails operacionais atuais:

- `HANDCRAFTED_KNOWN_CARDS` deve permanecer vazio por padrao;
- `MANUAL_RULE_RUNTIME_WAIVERS` deve permanecer vazio por padrao;
- qualquer carta em `generated/needs_review` ou `unknown` e um gap de
  modelagem/cobertura, nao autorizacao para reintroduzir override manual como
  fonte primaria;
- suites de fallback/promoted hotfix existem para garantir que cartas
  canonizadas resolvam pelo registry e nao pelo legado manual.

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

Atualização 2026-06-11: a revisão oficial confirmou que o próximo trabalho de
regras deve ser card-specific e orientado por corpus. Warp, Station,
Prepare/Omen/Paradigm e ability words não devem ganhar enforcement genérico
pesado sem carta real, replay e teste focado.
Para Edge of Eternities, o `Update Bulletin` é a fonte primária dos números
novos de regra (`111.10u`, `721`, `702.184`, `702.185`); mechanics/release
notes são usadas como explicação operacional e card-specific.

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
| WNS WR | Win Rate sem carta vista | jogos_ganhos_sem_carta_vista / jogos_sem_carta_vista |
| Not Cast WR | Win Rate sem carta castada | jogos_ganhos_sem_carta_castada / jogos_sem_carta_castada |
| Cast Delta | WPWR - Not Cast WR | Evita concluir impacto só porque a carta apareceu em jogos vencidos |
| Delta vs Not Seen | WDWR - WNS WR | Evita confiar apenas em WR bruto |
| Baseline Hash | Hash/identificador do corpus de replay | Impede comparar scorecards de bases diferentes como se fossem a mesma rodada |
| Sample Quality | `low_sample` / `usable` | Bloqueia conclusao quando a amostra nao sustenta decisao |

### 4.2 Geração de Replays (generate_card_replays.py)

```bash
python3 server/bin/generate_card_replays.py --games 5 --opponents 6 --deck-id 6
```

- Usa `REPLAY_EVENT_HANDLER` para capturar eventos sem modificar a engine
- Usa `load_deck()` nativo do v8 para carregar cartas com metadata completa
- Gera arquivos JSONL em `master_optimizer_replays/`
- Cada arquivo contém eventos turn-by-turn + game_ended com won/loss
- Desde 2026-06-18, o runner resolve o repo atual dinamicamente no Mac local e
  no EasyPanel; nao depende mais de `/opt/data/workspace/mtgia` para localizar
  `battle_analyst_v9.py`.

### 4.3 Análise de Impacto (card_impact_analyzer.py)

```bash
python3 card_impact_analyzer.py --replay-dir /path/to/replays
python3 card_impact_analyzer.py --replay-dir /path/to/replays --json-output /tmp/card_impact.json
python3 card_impact_analyzer.py --replay-dir /path/to/replays --baseline-hash lorehold_round_001 --min-usable-sample 10
python3 card_impact_analyzer.py --replay-dir /path/to/replays --json-summary-output /tmp/card_impact_summary.json
```

- Lê todos os arquivos JSONL
- Rastreia `spell_cast`, `miracle_cast` e `commander_cast` para determinar
  quais cartas foram jogadas
- Rastreia cartas vistas por cast, resolução, manipulação de topo e eventos de
  compra (`drawn`/`drawn_cards`)
- Usa `game_won` ou `game_ended` com vencedor compatível para classificar
  vitória/derrota do deck analisado
- Filtra cartas com ≥3 aparições (min-games)
- Emite `seen_wr`, `not_seen_wr`, `cast_wr`, `not_cast_wr`,
  `delta_vs_baseline`, `delta_seen_vs_not_seen`, `delta_cast_vs_not_cast`,
  `baseline_hash` e `sample_quality`
- Pode emitir resumo operacional com `status=trusted|needs_more_samples|blocked`,
  blockers, contagem de cartas utilizáveis e política `auto_apply=false`
- Ordena por `seen_wr`/WDWR decrescente

### 4.4 Exemplo de Output

```
Baseline WR: 58.3%
Baseline hash: lorehold_round_001
Scorecard status: needs_more_samples — No tracked card reached the usable sample threshold.

Top 15 — Highest WDWR:
  Boros Charm                    seen_wr=75.0% seen=4 cast=2 delta=+16.7pp vs_not_seen=8.4 quality=low_sample
  ...
Bottom 15 — Lowest WDWR:
  Surge to Victory               seen_wr=20.0% seen=5 cast=1 delta=-38.3pp vs_not_seen=-42.0 quality=low_sample
```

O scorecard ainda nao autoriza swap sozinho. A conclusao fica
`needs_more_samples` ou `blocked` quando `sample_quality=low_sample`, quando o
`baseline_hash` nao bate com a rodada comparada, ou quando o corpus nao foi
segmentado por arquétipo/turno.

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
       ├→ Sugestão principal: adicionar {category} / reforçar tipo funcional
       └→ Cut candidates: cartas com WDWR mais baixo observadas no proprio corpus
```

Leitura correta:

- `loss_mode_suggester.py` nao consome `known_cards_generated.json`;
- ele tambem nao consulta `battle_card_rules`;
- hoje ele usa apenas loss tags e `card_impact` derivados dos replays para
  sugerir categorias e candidatos observados no proprio corpus;
- se no futuro ele for promovido para sugerir candidatos externos de verdade,
  deve ler pool canonico agregado (`battle_card_rules`/snapshot/bridge), nao o
  JSON legado cru.

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

## 11. Card Pool e precedencia de regras

O runtime atual nao usa mais `known_cards_generated.json` como fonte principal de
efeito de batalha.

Precedencia real do battle runtime:

1. waiver manual explicito de emergencia;
2. `card_battle_rules` / cache SQLite `battle_card_rules`;
3. `known_cards_canonical_snapshot.json` exportado do cache canonico;
4. tags/heuristicas quando nao ha regra estruturada melhor.

Leitura correta:

- `card_battle_rules` e o inventario operacional canonico de efeito executavel;
- desde a migration `028`, PostgreSQL `card_battle_rules` e SQLite Hermes
  `battle_card_rules` persistem `logical_rule_key` e usam chave composta
  `(normalized_name, logical_rule_key)`. Isso permite armazenar múltiplas
  regras por mesmo nome normalizado sem overwrite. O sistema ainda deve agregar
  por `card_id` para evitar fanout em contexto de deck e nao deve tentar
  corrigir isso escolhendo uma unica regra com `LIMIT 1`;
- desde o Slice 2 de 2026-06-17, o registry Hermes possui dois contratos:
  `load_active_battle_card_rules()`/`lookup_battle_card_rule()` retornam uma
  regra primária para compatibilidade, enquanto
  `load_active_battle_card_rule_lists()`/`lookup_battle_card_rule_list()`
  retornam todas as regras ativas por nome normalizado. Otimizadores e
  snapshots estratégicos devem usar o contrato de lista quando precisam
  entender todos os papéis de uma carta;
- desde o Slice 3 de 2026-06-17, `battle_analyst_v9.py#get_card_effect` pode
  compor múltiplas regras executáveis no mesmo spell quando todas as linhas
  ativas são `verified`/`active`, possuem `compose_on_resolution=true` e
  pertencem ao conjunto seguro de efeitos de resolução imediata. O replay passa
  a registrar `effect=composite_resolution`, `composite_rule_component_count`,
  `composite_rule_component_resolved` e `composite_rule_resolved`;
- desde o slice incremental seguinte, quando uma carta possui múltiplas regras
  mas não entra no caminho de `composite_resolution`, o runtime não “executa
  tudo pelo nome”. Ele seleciona uma regra primária e preserva as demais como
  alternativas auditáveis via `_rule_runtime_selection`,
  `rule_runtime_selection_mode` e `_rule_blocked_alternatives`. Os principais
  motivos explícitos de bloqueio hoje são:
  `activated_ability_requires_executor`, `trigger_requires_event_hook`,
  `static_effect_requires_state_layer`, `blocked_by_<cost_or_clause>` e
  `multi_rule_requires_explicit_selector`;
- desde o slice incremental mais recente de 2026-06-17, uma regra secundária
  `verified/active` que só adiciona metadata segura de custo adicional
  (`requires_discard_*`, `requires_sacrifice_*`) ao mesmo efeito principal pode
  ser fundida ao runtime sem criar segunda resolução. O replay passa a expor
  `rule_runtime_selection_mode=single_selected_with_safe_annotations` e
  `rule_merged_annotation_count`; isso cobre o caso de multi-rule “efeito
  principal + custo/guardrail” sem reabrir execução cega por nome;
- a auditoria `BATTLE_MULTI_RULE_RUNTIME_READINESS_2026-06-17.md` revalidou o
  estado do corpus canônico: apesar da infraestrutura multi-rule já existir,
  o PostgreSQL real tinha `3158` nomes ativos e `0` nomes com mais de uma regra
  ativa ou histórica no momento do estudo. Logo, a lacuna atual não é “o
  runtime já falha em várias cartas multi-rule vivas”, e sim “a fonte de
  verdade ainda não materializou multi-row real por escopo de execução”;
- no fechamento desse slice em 2026-06-17, PG `card_battle_rules`, SQLite
  Hermes `battle_card_rules`, snapshot canônico e runtime passaram a carregar
  `execution_status` com os estados
  `auto|executable|annotation_only|review_only|disabled`. A partir daí,
  “múltiplas regras por carta” deixou de significar implicitamente “múltiplas
  regras executáveis por carta”;
- `load_active_battle_card_rule_lists()` e os consumidores secundários do pool
  canônico passaram a excluir `execution_status='disabled'` do contrato ativo.
  `annotation_only` e `review_only` continuam úteis para auditoria e
  explainability, mas não podem voltar a contaminar runtime como se fossem
  regras duras;
- `server/bin/auto_promote_battle_rules.py` também foi ajustado para não
  promover linhas por `normalized_name` quando existir multi-rule ativa para a
  mesma carta. Nesses casos ele atualiza rastreamento, mas bloqueia promoção e
  exige evidência row-level em vez de promover todas as regras silenciosamente;
- `Worldfire` deixou de ser modelado como `board_wipe` genérico. O runtime
  agora o trata como `worldfire_reset`: exila permanentes, exila mãos e
  cemitérios, ajusta vidas para `1` e respeita replacement de comandante para
  `command_zone`. O cast automático continua bloqueado por padrão até existir
  uma heurística confiável de linha vencedora pós-reset;
- regras sem opt-in, `needs_review`, triggers, habilidades ativadas, efeitos
  estáticos e componentes sem executor explícito continuam preservados em
  `_rule_alternatives`, mas não executam comportamento duro automaticamente.
  Custos adicionais/sacrifícios agora só podem atravessar esse limite quando
  entram como metadata segura fundida a uma regra primária já executável;
- `known_cards_canonical_snapshot.json` existe para manter um modo degradado mais
  proximo da fonte canonica quando SQLite/PG nao estiverem disponiveis;
- desde a rodada local de 2026-06-17, o export do
  `known_cards_canonical_snapshot.json` deixou de depender de ordem incidental
  de linhas e passou a escolher uma regra fallback por carta usando a mesma
  prioridade base de `review_status`, `execution_status`, `source`,
  `confidence` e `rule_version`. Isso evita degradar cartas como
  `Approach of the Second Sun` ou `Library of Leng` quando coexistem linhas
  `manual/curated/generated` no cache canonico;
- no fechamento adicional de 2026-06-17, o sync local SQLite
  `sync_battle_card_rules.py` passou a remover dois tipos de drift antes de
  reexportar o snapshot canônico:
  - linhas `source='manual'` obsoletas, já que `manual` agora é reservado a
    `MANUAL_RULE_RUNTIME_WAIVERS` explícitos e o runtime normal deve mantê-los
    vazios;
  - linhas `curated` superseded do mesmo card quando o reviewed JSON mudou a
    `logical_rule_key`, evitando que o snapshot continue escolhendo uma versão
    antiga de cartas como `Scroll Rack` por empate lexical entre irmãs
    `curated/active`;
- no mesmo fechamento, o espelho `sync_battle_card_rules_pg.py` passou a
  filtrar linhas `curated` históricas do PostgreSQL que já não pertencem ao
  reviewed layer atual antes de repovoar o SQLite Hermes, para o cache
  operacional não reintroduzir uma irmã antiga logo após o cleanup local;
- `known_cards_generated.json` continua no repositorio apenas como compatibilidade
  historica, seed de sync/auditoria e comparacao de drift, nao como fallback
  executavel do battle runtime;
- `KNOWN_CARDS` em `battle_analyst_v9.py` começa vazio; o antigo dicionario
  literal manual foi removido do codigo ativo;
- `HANDCRAFTED_KNOWN_CARDS` e `MANUAL_RULE_RUNTIME_WAIVERS` devem permanecer
  vazios no runtime normal e so podem ser preenchidos em incidentes controlados
  ou testes focados.
- fechamento operacional de 2026-06-18: um replay local chegou a parecer
  degradado porque foi gerado antes do refresh `PG -> SQLite`, ainda usando
  snapshot/metadata stale para cartas que o PostgreSQL já possuía como
  `curated/verified`. A reexecução imediata após
  `sync_battle_card_rules_pg.py --apply-sqlite-from-pg` fechou um sample com
  `decision_findings=0`, e o runner local consolidado manteve o auditor
  estratégico em `usable_for_strategy_learning`; em outra seed curta ainda
  sobraram apenas findings `low` de oponentes que seguem em
  `known_cards_canonical_snapshot/needs_review`. A leitura correta é:
  - o problema não era mais precedência do runtime;
  - o problema era validar replay local com cache Hermes defasado;
  - a rotina local correta agora é usar
    `server/bin/run_local_battle_replay_audit.sh` ou, no mínimo, sincronizar o
    SQLite antes do replay.

### 9.4 Focused Evidence Gate Para `needs_review`

Desde o slice de 2026-06-18, a esteira operacional de novas cartas possui uma
etapa intermediária entre draft de regra e promotion gate:

```text
manaloom_battle_rule_review_queue
  -> manaloom_battle_rule_focused_evidence
      -> manaloom_battle_rule_promotion_gate
```

Contrato:

- `manaloom_battle_rule_review_queue` continua criando apenas drafts
  `proposed_status=needs_review`;
- `manaloom_battle_rule_focused_evidence` executa cenários focados em harness
  controlado somente para templates suportados e grava replay/decision
  trace/evidence em artefatos;
- `manaloom_battle_rule_promotion_gate` consome `latest_evidence.json` quando
  existir e decide se a regra está bloqueada ou elegível para promoção manual;
- nenhum desses jobs escreve em PostgreSQL;
- nenhum desses jobs promove comportamento duro no runtime de produto;
- `needs_review` vindo de banco/sync continua review-only; a execução em
  `focused_evidence` é cenário isolado para provar se uma futura promoção manual
  é segura.

Template suportado no primeiro slice:

```text
oracle_text_excerpt == "Counter target spell."
effect_families inclui counterspell_stack_interaction
```

Templates adicionais suportados no mesmo pipeline:

```text
Targeted creature removal simples
- oracle_text_excerpt contem exatamente "Destroy target creature.";
- effect_families inclui targeted_interaction;
- executor estreito: apply_effect_immediate() com effect remove_creature;
- o teste focado prova alvo legal, criatura alvo removida, criatura decoy
  preservada, envio ao graveyard e replay/decision audit sem critical/high.

Targeted nonland permanent removal simples
- oracle_text_excerpt contem exatamente "Destroy target nonland permanent.";
- effect_families inclui targeted_interaction;
- executor estreito: apply_effect_immediate() com effect remove_permanent;
- o teste focado prova alvo não criatura legal, artefato removido, criatura
  decoy preservada, land preservada, envio ao graveyard e replay/decision
  audit sem critical/high.

Targeted artifact/enchantment removal simples
- oracle_text_excerpt contem exatamente "Destroy target artifact." ou
  "Destroy target enchantment.";
- effect_families inclui targeted_interaction;
- executor estreito: apply_effect_immediate() com effect remove_permanent e
  target específico `artifact` ou `enchantment`;
- o teste focado prova que o alvo correto é removido, o outro tipo de
  permanente usado como decoy é preservado, land é preservada e replay/
  decision audit fica sem critical/high.

Creature board wipe simples
- oracle_text_excerpt contem exatamente "Destroy all creatures.";
- effect_families inclui mass_removal_or_modal_wipe;
- executor estreito: apply_effect_immediate() com effect board_wipe;
- o teste focado prova criaturas não protegidas destruídas, criatura
  indestrutível preservada, permanentes não criatura preservados e replay/
  decision audit sem critical/high.

Sacrifice outlet de dano simples
- oracle_text contem "Sacrifice a creature:"
- oracle_text contem dano a alvo/any target
- executor estreito: activate_sacrifice_damage_outlets()
- so sacrifica criatura expendable; nao sacrifica commander, mana creature ou
  criatura de alto valor por um dano sem justificativa

Extra combat + flashback simples
- oracle_text contem additional combat phase
- oracle_text contem flashback
- prova resolucao da mao, cast via graveyard, replacement para exile e replay
  audit sem critical/high

Attack trigger + Treasure + artifact tutor
- oracle_text contem trigger de ataque, Treasure, sacrificio de artefato e
  busca de artifact card para o campo;
- executor estreito: `resolve_attack_artifact_tutor_trigger()`;
- para `Iron Man, Titan of Innovation`, o cenário respeita o oracle atual:
  sacrifica artefato **não criatura**, busca artefato com mana value exatamente
  `1 +` mana value do artefato sacrificado e coloca no campo **virado**;
- o cenário focado sacrifica Treasure expendable e busca `Sol Ring` CMC 1,
  mantendo `rule_status=needs_review` e sem promover para comportamento duro.
```

Resultado de controle:

- `Counterspell` ficou elegível para
  `eligible_for_manual_verified_promotion` depois de cenário focado
  stack/counterspell e replay/decision audit sem finding crítico/high;
- `Goblin Bombardment` ficou elegível para promoção manual depois de cenário
  focado de sacrifice outlet com token expendable, dano aplicado e decision
  trace;
- `Seize the Day` ficou elegível para promoção manual depois de cenário focado
  de extra combat + flashback/recast;
- `Iron Man, Titan of Innovation` ficou elegível para promoção manual depois de
  cenário focado com trigger de ataque, Treasure, sacrifício de artefato não
  criatura expendable, tutor CMC exato e entrada virada.
- Em 2026-06-19, os templates de `Destroy target creature.` e
  `Destroy all creatures.` elevaram a evidência focada global de 18 para 113
  drafts elegíveis para futura promoção manual.
- Em seguida, o template `Destroy target nonland permanent.` foi validado em
  fixture/harness controlado, elevando o teste local de consumidores de 6 para
  7 drafts elegíveis. A rodada full não foi repetida neste slice para evitar
  novo artefato gigante no disco local.
- Em seguida, o runtime passou a preservar target type específico para
  `artifact`, `enchantment`, `artifact_or_enchantment`, `nonland_permanent` e
  `creature` durante normalização por oracle text; isso corrigiu a degradação
  de `Destroy target artifact/enchantment` para `nonland_permanent`.
- Com os templates `Destroy target artifact.` e `Destroy target enchantment.`,
  o teste local de consumidores subiu de 7 para 9 drafts elegíveis e a rodada
  full report-only passou para `118` evidências focadas / `118` elegíveis no
  promotion gate, ainda com `13765` drafts bloqueados corretamente por falta de
  template/fonte/replay.

Correção crítica associada ao wipe:

- o executor de `board_wipe` não pode remover itens da lista `battlefield`
  enquanto itera sobre ela, porque isso pode pular elementos e descartar
  permanentes não criatura;
- `battle_analyst_v9.py` agora calcula `survivors` e `destroyed_cards` em uma
  cópia da lista e só depois move as criaturas destruídas para o graveyard;
- o teste focado de `Destroy all creatures.` exige explicitamente que `Mana
  Rock` permaneça no battlefield após o wipe.

Correção associada a remoções de permanente:

- o runtime agora expõe `move_permanent_from_battlefield()` como caminho
  canônico para permanentes não criatura;
- `move_creature_from_battlefield()` permanece como wrapper compatível para
  chamadas antigas;
- a seleção de alvo agora trata `unknown` como ausência de efeito e volta para
  o `effect` real do permanente, impedindo que remoção genérica escolha criatura
  pequena antes de um artefato/engine mais relevante apenas por fallback.

Logo, o gate já prova que regras simples podem avançar para revisão manual,
mas ainda preserva a barreira correta para cartas multi-etapa ou com custo/
trigger/flashback complexo.

Na rodada real read-only local contra `msh,msc,mar`, os bloqueadores restantes
foram:

- `Black Panther, Wakandan King`: precisa template para commander/engine com
  counters, compra e recorrência.
- `Captain America, First Avenger`: precisa template para engine/interaction
  ligado a alvo/equip/ataque.
- `Concerted Effort`: precisa modelo focado de compartilhamento contínuo de
  habilidades/keywords.
- `Final Showdown`: precisa template focado para spell modal com wipe/protection
  e timing estratégico.
- `Ravenous Tyrannosaurus`: precisa template focado de combate/dano/counters.
- `Storm, Force of Nature`: precisa template focado de copy/protection/removal
  por trigger/spell.
- `Warleader's Call`: precisa template de engine estática/trigger de dano em
  entrada de criaturas.
- `Wolverine, Best There Is`: precisa template focado de engine/counters/combat.

Campos tipicos encontrados no snapshot/fallback legado:

- `name`: nome da carta
- `effect`: efeito de batalha (`ramp_permanent`, `remove_creature`, etc.)
- `deck_category`: categoria de deckbuilding historica
- `cmc`: mana value / custo convertido
- `color_identity`: identidade de cor
- `battle_rule_source`: proveniencia da regra (`manual`, `curated`, `generated`, `heuristic`)
- `battle_rule_review_status`: status da regra (`verified`, `needs_review`, etc.)

Filtros aplicados pelo slot optimizer e consumidores equivalentes:

- `off_color`: identidade de cor fora da do commander
- `illegal`: `commander_legality != "legal"`
- `high_cmc`: `CMC > MAX_CMC_BY_CATEGORY`
- `deck`: carta ja esta no deck atual
- `basic`: terra basica

Risco operacional remanescente:

- o conflito principal ja nao e de precedencia no runtime;
- o risco real virou drift de consumidores secundarios: o JSON historico ainda
  cobre menos cartas e pode divergir semanticamente do snapshot canonico se algum
  script auxiliar voltar a le-lo como fonte operacional;
- por isso, qualquer auditoria ou scorecard deve preferir `battle_card_rules` ou
  o snapshot canonico antes de confiar no JSON legado.
- a promocao de casos relevantes agora deve acontecer por uma camada versionada
  de regras revisadas, nao por novo crescimento de hardcode runtime. Exemplo ja
  validado nesta rodada: `Angel's Grace` foi promovida para
  `curated/verified`, enquanto `Chromatic Star` entrou como
  `curated/active` com
  `effect=cantrip_mana_filter_artifact` e
  `battle_model_scope=sacrifice_mana_filter_cantrip_v2`.
- continuidade validada em 2026-06-17:
  - `Incubation Druid` entrou como `curated/active` em
    `reviewed_battle_card_rules.json` com baseline de mana dork
    (`effect=creature`, `is_mana_source=true`, `mana_produced=1`), e o runtime
    passou a suportar esse caminho diretamente em `apply_effect_immediate()`;
  - `Ashnod's Altar` entrou como `curated/active` com metadata revisada de
    habilidade ativada (`activated_mana_ability`, `activation_cost`,
    `mana_produced`). No incremento validado do mesmo dia, o runtime ganhou um
    slice seguro e contextual para habilidades de mana com custo
    `sacrifice_creature`: a ativacao so ocorre quando destrava uma jogada real
    no precombat main e sem sacrificar comandante. A regra correta no momento
    ainda e manter isso fora de qualquer executor generico/combo engine e nunca
    transformar a habilidade em mana gratis no resolve do spell.
- leitura correta desses dois casos:
  - o runtime esta coerente e consome a camada revisada sem conflito;
  - `Angel's Grace` saiu de drift de fallback e ganhou semantica executavel
    minima (`cannot_lose_turn`);
  - `Chromatic Star` deixou de ser `unknown` e saiu do surrogate puro de
    `draw_cards`; hoje ela entra como artefato utilitario sacrificavel que pode
    corrigir cor no precombat e virar draw no postcombat;
  - `Incubation Druid` deixou de depender de `needs_review` generico e passou a
    ter comportamento parcial coerente com summoning sickness e mana baseline;
  - `Ashnod's Altar` deixou de colapsar em `ramp_ritual` e passou a ter
    ativacao contextual minima para `sacrifice_creature -> mana unlock`, mas o
    custo ainda nao esta coberto por executor generico completo nem por
    heuristica de combo;
  - no fechamento incremental seguinte do mesmo dia, `Basking Broodscale` e
    `Scavenging Ooze` deixaram de aparecer em cast ao vivo como
    `known_cards_canonical_snapshot/needs_review`: ambas foram promovidas para
    `curated/active` com semantica conservadora de criatura, impedindo
    degradacao para `token_maker` e `remove_permanent` no resolve do spell;
  - o gap remanescente dessas duas cartas mudou de natureza: agora e
    explicitamente "trigger/activated ability ainda sem executor dedicado",
    nao mais "efeito principal errado no replay";
  - no fechamento incremental de 2026-06-18, `Ancient Tomb`, `Fellwar Stone`,
    `Mana Vault`, `Path to Exile`, `Seething Song` e
    `Talisman of Conviction` deixaram de depender da camada
    `generated/needs_review` e passaram a sair do registry reviewed como
    `curated/verified` ou `curated/active`, com semantica limitada ao que o
    runtime ja executa hoje;
  - mesmo assim, ela ainda nao deve ser tratada como regra totalmente
    verificada enquanto a mana ability completa e todos os edge cases de combo
    nao estiverem modelados com fidelidade maior.
  - fechamento adicional do mesmo slice:
    - `Crop Rotation` foi promovida para `curated/verified` como
      `land_ramp` com `requires_sacrifice_land=true`, impedindo que o runtime a
      tratasse como `ramp_permanent`;
    - `Rampant Growth` passou a `curated/verified` como `land_ramp` de
      `basic land` entrando tapped, corrigindo a ida do spell ao cemitério em
      vez de virar permanente;
    - `Splendid Reclamation` passou a `curated/verified` como
      `land_recursion`, evitando degradação para `recursion` genérica;
    - `Entomb` passou a `curated/verified` como `tutor` para `graveyard`,
      impedindo colapso em `draw_cards`;
    - `Reanimate` passou a `curated/active` como `recursion` para
      `destination=battlefield`, preservando o comportamento central sem ainda
      fechar toda a paridade de life loss;
    - `Skullclamp` passou a `curated/active` como `passive` de equipamento com
      trigger de draw em morte, deixando de comprar carta na resolução;
    - `Mystical Tutor` passou a `curated/active` com filtro
      `target=instant_or_sorcery`, impedindo que tutorasse criatura por falta
      de restrição;
    - `Lumra, Bellow of the Woods` passou a `curated/verified` como
      `land_recursion_creature` com `mill_count=4` e
      `power/toughness = lands`, ativando o executor dedicado que já existia no
      runtime;
    - `get_card_effect()` também ganhou fallback por face frontal para MDFC e
      split names, o que fechou o caso
      `Valakut Awakening // Valakut Stoneforge` sem novo hardcode por nome;
    - com esse lote sincronizado, a suíte agregada
      `test_battle_analyst_v10_3.py` voltou a `PASS` no ambiente local.

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
