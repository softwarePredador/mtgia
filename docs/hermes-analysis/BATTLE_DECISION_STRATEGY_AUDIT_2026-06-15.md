# Battle Decision Strategy Audit — 2026-06-15

## Resumo

Esta auditoria separa duas perguntas que estavam misturadas nos replays Hermes:

- A ação foi legal pelas regras?
- A ação foi estrategicamente defensável para Commander?

O battle engine já valida vários aspectos legais e forenses, mas ainda não prova
que cada decisão foi boa. O avanço deste slice é instrumentar e auditar decisões
estratégicas sem alterar API pública, app Flutter, PostgreSQL ou contratos de
produto.

Escopo deste ciclo: Hermes-only, report-only para estratégia, sem auto-apply de
swaps, sem ban global de Mox e sem transformar o simulador em judge engine
completo.

### Atualizacao 2026-06-18

- O batch curto de 2026-06-18 mostrou um problema concreto: `Wheel of Fortune`
  podia entrar por `miracle_cast` do Lorehold mesmo quando o próprio contexto
  de `wheel` registrava `timing_justified=false`.
- O runtime foi ajustado para:
  - bloquear `miracle_cast` automático de `wheel`, `board_wipe` e
    `worldfire_reset` quando os guardrails já dizem que a linha não é boa;
  - inferir `draw_count` correto para wheels clássicas sem `count`
    explícito, fechando a regressão de `Reforge the Soul` que resolvia como
    draw `2`.
- Revalidação:
  - suite `test_battle_analyst_v10_3.py` passou;
  - rodada curta
    `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260618_004552/summary.json`
    terminou com `strategy_findings=0` e
    `board_wipe_wheel=coherent_in_sample`.

## Fontes e política de evidência

Fontes oficiais usadas como regra:

- Wizards Rules: <https://magic.wizards.com/en/rules>
- London Mulligan: <https://magic.wizards.com/en/news/announcements/london-mulligan-2019-06-03>
- Commander oficial: <https://magic.wizards.com/en/formats/commander>
- Mox Diamond no Scryfall: <https://scryfall.com/card/sth/138/mox-diamond>
- Lotus Petal no Scryfall: <https://scryfall.com/card/tmp/294/lotus-petal>
- Crop Rotation no Scryfall:
  <https://scryfall.com/card/ulg/98/crop-rotation>
- Harrow no Scryfall: <https://scryfall.com/card/cma/115/harrow>
- Roiling Regrowth no Scryfall:
  <https://scryfall.com/card/znr/201/roiling-regrowth>

Fontes estratégicas usadas apenas para calibrar heurística:

- Draftsim/Commander mulligan e discussões Commander: manter mão precisa de
  plano jogável, não só quantidade de terrenos.
- Card Kingdom, EDHREC, MTGSalvation, Reddit EDH/cEDH: threat assessment,
  uso de remoção, fast mana e custo de oportunidade são contextuais.
- PlayedH/Card Kingdom/GrimDeck/MTGSalvation/EDHREC: board wipe e wheel
  precisam justificar assimetria, prevenção de lethal, payoff ou risco de
  reabastecer oponentes.
  - <https://www.playedh.com/articles/board-wipes-top10>
  - <https://blog.cardkingdom.com/is-a-boardwipe-in-the-command-zone-fair/>
  - <https://blog.cardkingdom.com/how-to-pick-a-board-wipe-commander/>
  - <https://grimdeck.com/blog/when-to-board-wipe-commander>
  - <https://grimdeck.com/blog/when-to-wheel-commander>
  - <https://blog.cardkingdom.com/is-smothering-tithe-a-fair-card/>

Regra operacional: fórum, Reddit e artigo de estratégia não viram regra dura.
Eles só justificam flags auditáveis. Comportamento duro exige texto oficial,
replay e teste focado.

## Implementação adicionada

### `decision_trace_v1` estendido

Arquivo:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`

Campos estratégicos adicionados ao trace:

- `strategic_principle`
- `heuristic_version`
- `resource_delta`
- `risk_flags`
- `alternatives_considered`
- `rejected_reason`

Esses campos não mudam a simulação. Eles explicam a decisão para auditoria e
aprendizado posterior.

### Mulligan traceável

O mulligan agora emite `decision_type=mulligan_decision` com:

- contagem de terrenos;
- cores disponíveis;
- resumo da mão;
- cartas de custo alto;
- early play/ramp detectado;
- motivo do keep/mulligan;
- cartas colocadas no fundo;
- flags como `mana_screw`, `mana_flood`, `no_early_game_plan`,
  `expensive_dead_hand` e `forced_keep_after_mulligan_cap`.
- desde 2026-06-18, contadores adicionais de plano:
  `plan_role`, `card_flow_count`, `proactive_board_count`,
  `reactive_only_count` e `high_cost_cluster_count`.

Limitação conhecida: a escolha das cartas colocadas no fundo continua
heurística e o keep ainda não é calibrado por comandante/arquetipo. O gap já
não é mais "detectar mão claramente morta"; agora é ranking comparativo de
alternativas e tuning fino por profile.

### Seleção contextual de land

Custos como Mox Diamond, Crop Rotation/Harrow/Roiling Regrowth agora registram
contexto quando consomem land:

- opções consideradas;
- cores de cada land;
- se a land era básica;
- se estava virada;
- se fornecia cor única;
- motivo de escolha;
- risco `spending_last_land` ou `spending_unique_color_land`.

O comportamento continua permitido quando a jogada é legal, mas o replay passa a
ser auditável como decisão estratégica.

### Auditor estratégico

Novo arquivo:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py`

Função:

- aponta decisões legais, mas estrategicamente fracas ou mal explicadas;
- complementa `battle_action_critic.py` e `battle_forensic_audit.py`;
- não substitui auditoria legal/forense.

Findings iniciais:

- `missing_strategy_fields`
- `mulligan_keep_without_early_plan`
- `forced_keep_after_bad_mulligan`
- `mulligan_without_hand_summary`
- `ramp_ritual_without_unlock_signal`
- `land_discard_missing_risk_flag`
- `pass_without_context`
- `resource_cost_without_selection_context`
- `spending_last_land`
- `spending_unique_color_land`

## Matriz de decisões

| Decisão | Regra oficial | Estratégia esperada | Status Hermes | Próximo ajuste |
|---|---|---|---|---|
| Mulligan | London Mulligan: compra 7 e coloca N no fundo após N mulligans | Avaliar terrenos, cores, curva T1-T3, ramp, draw/filter, interação e mão morta | Parcial forte: avalia lands, plano inicial, ramp barato, card flow, reactive-only e cluster caro sem setup; emite trace rico | Melhorar ranking comparativo das opções e tuning por comandante/arquetipo |
| Lotus Petal/ritual | Sacrificar para gerar mana conforme oracle | Usar só para destravar ação relevante, proteção, win attempt ou correção crítica | Parcial: `ramp_ritual` só entra no ramp loop se destrava ação no turno; auditor exige sinal | Ampliar para storm/free-spell synergies e proteção reativa |
| Mox Diamond | Deve descartar land da mão antes de entrar | Só jogar com land descartável e plano de mana real | Guardrail mínimo: exige `requires_discard_land`, preserva cor única e bloqueia última/única land sem payoff nominal | Ampliar corpus e casos por bracket, sem ban global de Mox |
| Sacrificar land | Crop Rotation/Harrow etc. exigem land conforme texto | Avaliar land sacrificada, risco de counter, alvo buscado e mana screw | Guardrail mínimo: escolhe alvo de land-ramp por score e bloqueia fetch/tapped sem benefício claro quando gasta última/única fonte | Ampliar scoring de utility lands e risco de counter |
| Cast de spell | Legalidade/timing/mana | Escolher por curva, função, janela, risco de overextension e plano | Parcial: score heurístico por papel | Registrar opção rejeitada com motivo por spell jogável |
| Removal/counter/protection | Respeitar alvo/timing/stack | Responder a win attempt, engine, commander crítico, wipe ou lethal | Parcial: threat score e response trace | Tuning por ameaça real e política multiplayer |
| Tutor | Legalidade da busca | Escolher alvo por estado: land/ramp, interação, wincon ou engine | Coerente na amostra: target trace e selected_reason emitidos | Ampliar scoring por arquétipo e alvo de utility land |
| Board wipe/wheel | Timing e efeito legal | Usar quando atrás, evita lethal, assimétrico ou tem payoff | Coerente na amostra pós-ajuste: gate de timing e wheel multiplayer v1 | Ampliar corpus e refinar payoff denial/hand quality |
| Combate/bloqueio | Ataque/bloqueio/dano legal | Avaliar lethal, crackback, commander damage e múltiplos defensores | Parcial: alvo e combat trace | Registrar blockers lucrativos e risco de crackback |
| Pass/no-action | Prioridade pode ser passada | Explicar sem opções, segurando instant, preservando recurso ou jogada ruim | Parcial: pass trace e auditor | Expandir pass reasons com opções rejeitadas |

## Evidência de código

- `battle_analyst_v9.py`: `emit_decision_trace`, `play_mulligan`,
  `mulligan_evaluation`, `choose_land_for_resource_cost`,
  `pay_additional_card_costs`, `sacrifice_land_for_effect`.
- `battle_decision_strategy_auditor.py`: auditor de estratégia.
- `test_battle_decision_strategy_auditor.py`: testes do auditor.
- `battle_turn_flow_tests.py`: testes de mulligan e one-shot ramp.
- `battle_card_specific_tests.py`: teste de Mox Diamond descartando land da mão.

## Status de confiança

O slice melhora rastreabilidade, mas ainda não autoriza confiar em WR bruto do
Lorehold como verdade. Resultado de replay só deve alimentar aprendizado quando:

- auditor forense não tiver critical/high;
- auditor de ação não tiver critical/high;
- auditor estratégico explicar recursos de alto custo;
- unknown/heuristic/needs_review estiverem contabilizados;
- amostra mínima estiver registrada.

## Validação local do slice

Rodada local:

- Seed: `61501`
- Knowledge DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Replay temporário: `/tmp/manaloom_strategy_audit_20260615_61501/`
- Eventos: `1412`
- Decision traces: `177`
- Tipos de decisão: `cast_spell=33`, `combat_attack=33`,
  `mulligan_decision=5`, `pass_no_action=106`
- `battle_action_critic.py`: `558` ações, `552 ok`, `5 low`, `1 medium`,
  `0 high`, `0 critical`
- `battle_decision_strategy_auditor.py`: `0` findings,
  `verdict=usable_for_strategy_learning`

Validações executadas:

```bash
python3 -m py_compile \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py

python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py
```

Leitura correta: a rodada prova que o trace/auditor funcionam em um replay
local e não geram findings estratégicos no seed testado. Não prova ainda que o
simulador joga perfeitamente, nem que o WR de Lorehold é confiável em agregado.

## Rotina local automatizada

Para acelerar os 10 dias finais do projeto, foi criada uma rotina local no Mac
com alto volume de rodadas, mas sem auto-apply:

- Script horário:
  `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- LaunchAgent horário:
  `/Users/desenvolvimentomobile/Library/LaunchAgents/com.manaloom.battle-strategy-audit.plist`
- Intervalo: `3600s`
- Seeds por ciclo: `16`
- Artefatos:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/`
- Link latest:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest`

Rotina nightly pesada:

- Script:
  `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-nightly.sh`
- LaunchAgent:
  `/Users/desenvolvimentomobile/Library/LaunchAgents/com.manaloom.battle-strategy-nightly.plist`
- Horário: `03:15`
- Seeds por ciclo: `64`

Comandos operacionais:

```bash
/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 16
/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --seeds 64 --start-seed 70001
cat /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json
launchctl list | grep com.manaloom.battle-strategy
```

Interpretação dos relatórios:

- `high`/`critical` no `battle_action_critic.py` bloqueia usar o replay como
  dado de aprendizado.
- `blocked` no `battle_decision_strategy_auditor.py` significa que a jogada pode
  ser legal, mas não deve ensinar heurística.
- `low`/`medium` repetido por muitos seeds vira backlog P1/P2.
- Nenhum job aplica swap, altera PostgreSQL ou muda app. A rotina só gera
  evidência para correção.

### Research Review por decisão

Novo agregador:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py`

Ele lê os diretórios `seed_*`, agrega `decision_trace`, `strategy_audit` e
classifica cada categoria de decisão contra a matriz de fontes:

- `mulligan`
- `fast_mana_one_shot`
- `mox_land_discard`
- `sacrifice_land`
- `cast_spell`
- `response`
- `combat_attack`
- `pass_no_action`
- `tutor`
- `board_wipe_wheel`

Rodada local inicial de 16 seeds:

- Run dir:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260615_151841`
- Eventos: `17200`
- Decisões: `2270`
- `mulligan`: `coherent_in_sample`
- `fast_mana_one_shot`: `coherent_in_sample`
- `cast_spell`: `coherent_in_sample`
- `response`: `coherent_in_sample`
- `combat_attack`: `coherent_in_sample`
- `pass_no_action`: `coherent_in_sample`
- `sacrifice_land`: `coherent_in_sample`
- `mox_land_discard`: `blocked_or_needs_review`
- `tutor`: `tracked_gap_not_observed`
- `board_wipe_wheel`: `tracked_gap_not_observed`

Achado concreto:

- Seed `63161449`: Mox Diamond descartou `City of Traitors`, mas houve
  `commander_cast` no mesmo turno. O auditor foi ajustado para tratar esse caso
  como payoff imediato coerente em vez de falso blocker.
- Seed `63161453`: Mox Diamond descartou `Exotic Orchard` como última/única
  land e não houve payoff relevante comprovado; segue blocker estratégico.

Conclusão da rodada:

- A rotina agora valida cada categoria observada contra fonte oficial/estratégica
  e separa coerente, pendente e blocker.
- O ajuste de runtime seguinte foi aplicado em `battle_analyst_v9.py`: Mox
  Diamond/permanent fast mana que exige descarte de land agora só passa pelo
  loop de ramp se a land descartada não for recurso extremo ou se a mana
  destravar comandante/spell de alto impacto no mesmo turno.
- Tutor e board wipe/wheel ainda precisam aparecer como `decision_type`
  próprio antes de serem usados para aprendizado.

Rodada local pós-ajuste com a mesma janela de 16 seeds:

- Run dir:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260615_153120`
- Eventos: `17295`
- Decisões: `2259`
- `strategy_findings`: `0`
- `seeds_with_strategy_blockers`: `[]`
- `mox_land_discard`: `coherent_in_sample`
- `mulligan`: `coherent_in_sample`
- `fast_mana_one_shot`: `coherent_in_sample`
- `cast_spell`: `coherent_in_sample`
- `response`: `coherent_in_sample`
- `combat_attack`: `coherent_in_sample`
- `pass_no_action`: `coherent_in_sample`
- `sacrifice_land`: `coherent_in_sample`
- `tutor`: `tracked_gap_not_observed`
- `board_wipe_wheel`: `tracked_gap_not_observed`

Conclusão pós-ajuste:

- O blocker concreto de Mox Diamond usando última/única land sem payoff deixou
  de aparecer na janela reproduzida.
- O caso coerente continua permitido: descartar land para destravar
  `commander_cast` no mesmo turno segue válido.
- A conclusão é amostral, não universal. Manter as automações horárias/noturnas
  para confirmar que não aparecem novos falsos positivos em corpora maiores.

Rodada local expandida depois de instrumentar tutor, board wipe e wheel:

- Run dir:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260615_160111`
- Start seed: `63161548`
- Seeds completos: `16/16`
- Eventos: `18254`
- Decisões: `2468`
- Action critic: `0 high`, `0 critical`, `13 medium`, `78 low`
- Strategy audit: `21` findings, sendo `3 high` e `18 medium`
- Seeds com blocker estratégico: `63161555`, `63161560`, `63161562`

Status por decisão no batch:

| Categoria | Status | Decisões/achados | Leitura |
|---|---|---:|---|
| Mulligan | `coherent_in_sample` | `103/0` | A mão é avaliada por lands, cores, early plays, ramp barato e cartas mortas caras; ainda falta bottom-card selection ótima. |
| Fast mana one-shot | `coherent_in_sample` | `400/0` | Lotus Petal/ritual não apareceram como gasto sem payoff nesta amostra. |
| Mox/land discard | `blocked_or_needs_review` | `400/6` | Ainda há descarte de última/única land em `Mox Diamond`; a jogada é legal, mas não deve ensinar heurística até provar payoff real. |
| Sacrifice land | `coherent_in_sample` agregado, com blockers pontuais | `400/0` no research category, mas `2` seeds com high no strategy audit | Crop/Harrow-like land sacrifice precisa registrar alvo/benefício líquido antes de ser usado como aprendizado. |
| Cast spell | `coherent_in_sample` | `400/0` | Casts genéricos estão rastreados por papel, mana, alternativa e payoff heurístico. |
| Response | `coherent_in_sample` | `2/0` | Pouca amostra; manter monitoramento para counter/protection/removal. |
| Combat attack | `coherent_in_sample` | `375/0` | Alvo de ataque está explicado por vida/lethal/ameaça na amostra. |
| Pass/no-action | `coherent_in_sample` | `1550/0` | Passes estão documentados; ainda pode enriquecer motivos políticos/segurar instant. |
| Tutor | `coherent_in_sample` | `27/0` | Target agora é escolhido por contexto: mana, interação, engine, wincon, battlefield impact ou setup. |
| Board wipe/wheel | `blocked_or_needs_review` | `11/15` | Board wipe sem assimetria clara e wheel self-only/refill-risk bloqueiam uso desses replays para aprendizado. |

Achados concretos do batch:

- `seed_63161555`: `Mox Diamond` descartou `Command Tower` como última/única
  land da mão; no mesmo turno o comandante `Thrasios, Triton Hero` continuou
  impagável. Isso prova que o guardrail precisa revalidar payoff real no
  momento do cast, não apenas no cálculo inicial de candidatos.
- `seed_63161560` e `seed_63161562`: land sacrifice consumiu última/única land.
  Esses casos exigem trace de alvo buscado, mana screw esperado e risco de
  counter antes de virarem dado confiável.
- Board wipe/wheel ficou observado, não mais "tracked gap não observado":
  `board_wipe_without_clear_asymmetry=3`, `wheel_model_simplified=7`,
  `wheel_opponent_refill_risk=5`.

Correção adicional aplicada nesta rodada:

- O loop de ramp agora revalida `ramp_resource_unlocks_same_turn_action` no
  momento exato do cast. Isso fecha o bypass em que a lista de ramp era montada
  antes de a mão mudar por land play/ações anteriores.
- Para permanent fast mana que exige descarte de land, o payoff simulado também
  precisa passar por uma checagem conservadora de mana nominal depois do ramp.
  Isso reduz casos em que `can_pay_card` estima que o Mox destravaria algo que
  o fluxo real ainda não consegue pagar.

Leitura correta:

- Este batch deixa `mulligan`, `fast_mana_one_shot`, `cast_spell`, `response`,
  `combat_attack`, `pass_no_action` e `tutor` coerentes na amostra atual.
- `mox_land_discard`, `land sacrifice` pontual e `board_wipe_wheel` seguem
  pendentes. Replays com esses findings não devem alimentar WR, swaps ou
  aprendizado de deck.
- A fonte oficial valida legalidade; a fonte estratégica só define quando uma
  decisão legal precisa de justificativa mais forte.

Rodada local pós-correção de land-sacrifice:

- Run dir:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260615_162840`
- Start seed: `63161548`
- Seeds completos: `16/16`
- Eventos: `18667`
- Decisões: `2526`
- Action critic: `0 high`, `0 critical`, `14 medium`, `81 low`
- Strategy audit: `14` findings, todos `medium`
- Seeds com blocker estratégico: nenhuma

Status por decisão no batch pós-correção:

| Categoria | Status | Decisões/achados | Leitura |
|---|---|---:|---|
| Mulligan | `coherent_in_sample` | `103/0` | Keep/mulligan está explicado por lands, cores, early plays, ramp barato e mão cara. |
| Fast mana one-shot | `coherent_in_sample` | `404/0` | Lotus Petal/ritual seguem sem gasto observado sem payoff. |
| Mox/land discard | `coherent_in_sample` | `404/0` | O bypass de Mox Diamond com última/única land foi fechado na amostra. |
| Sacrifice land | `coherent_in_sample` | `404/0` | Crop/Harrow-like agora precisa de alvo/benefício traceável; fetch/tapped sem ganho claro é bloqueado por guardrail. |
| Cast spell | `coherent_in_sample` | `404/0` | Casts genéricos seguem rastreados por papel, mana, alternativa e payoff heurístico. |
| Response | `coherent_in_sample` | `2/0` | Pouca amostra; manter monitoramento. |
| Combat attack | `coherent_in_sample` | `380/0` | Ataques seguem com alvo explicado por vida/lethal/ameaça. |
| Pass/no-action | `coherent_in_sample` | `1598/0` | Passes estão documentados; motivos políticos ainda podem enriquecer o trace. |
| Tutor | `coherent_in_sample` | `28/0` | Target contextual segue coerente na amostra. |
| Board wipe/wheel | `blocked_or_needs_review` | `11/14` | Ainda não pode alimentar aprendizado: wipe sem assimetria clara e wheel self-only/refill-risk seguem modelo incompleto. |

Correção adicional aplicada:

- `Crop Rotation` e `Harrow` agora distinguem lands buscadas untapped de ramp
  que explicitamente entra tapped, como `Roiling Regrowth`.
- Land-ramp com sacrifício agora escolhe alvo por scoring mínimo antes de pagar
  custo: evita fetch/tapped sem ganho claro quando a land sacrificada era a
  última/única fonte, mas permite alvo high-value/untapped como `Ancient Tomb`
  ou net land increase.
- O evento `additional_cost_paid` registra `land_ramp_target_options` e
  `strategic_benefit_reason`; o auditor aceita `high_value_land_target`,
  `untapped_net_mana_upgrade`, `net_land_count_increase` ou
  `flexible_color_fixing` como justificativa explícita.

Leitura correta pós-correção:

- `mox_land_discard` e `sacrifice_land` estão coerentes nesta amostra de 16
  seeds, mas continuam monitorados nas crons por serem decisões sensíveis.
- `board_wipe_wheel` é o único bloqueio estratégico restante para uso de
  replays em aprendizado neste batch.
- A próxima implementação de decisão deve focar em timing/modelo de board wipe
  e wheel, não em ban genérico de Mox ou bloqueio amplo de land sacrifice.

Rodada local pós-correção de board wipe/wheel:

- Run dir:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260615_172608`
- Start seed: `63161548`
- Seeds completos: `16/16`
- Eventos: `19226`
- Decisões: `2564`
- Action critic: `0 high`, `0 critical`, `14 medium`, `79 low`
- Strategy audit: `0` findings
- Seeds com blocker estratégico: nenhuma

Status por decisão no batch pós-correção de board wipe/wheel:

| Categoria | Status | Decisões/achados | Leitura |
|---|---|---:|---|
| Mulligan | `coherent_in_sample` | `103/0` | Segue coerente na amostra reproduzida. |
| Fast mana one-shot | `coherent_in_sample` | `405/0` | Segue sem gasto sem payoff observado. |
| Mox/land discard | `coherent_in_sample` | `405/0` | Guardrail de última/única land manteve o batch limpo. |
| Sacrifice land | `coherent_in_sample` | `405/0` | Land sacrifice segue exigindo alvo/benefício traceável. |
| Cast spell | `coherent_in_sample` | `405/0` | Casts continuam rastreados por papel, mana e alternativas. |
| Response | `coherent_in_sample` | `2/0` | Pouca amostra; manter monitoramento. |
| Combat attack | `coherent_in_sample` | `395/0` | Ataques seguem com alvo explicado. |
| Pass/no-action | `coherent_in_sample` | `1621/0` | Passes seguem auditáveis. |
| Tutor | `coherent_in_sample` | `30/0` | Alvo contextual segue coerente na amostra. |
| Board wipe/wheel | `coherent_in_sample` | `8/0` | Wipe agora exige timing justificado; Wheel resolve discard/draw multiplayer v1 e só alerta refill quando sem payoff/timing. |

Correção aplicada:

- `board_wipe_decision_context` agora registra `behind_on_board`,
  `rebuild_plan`, `rebuild_cards_in_hand`, `rebuild_engines` e
  `timing_justified`.
- O cast de board wipe é evitado quando não há assimetria, lethal pressure,
  board disadvantage ou plano de rebuild.
- Wheel-like draw deixou de ser self-only: `resolve_wheel_like_draw` descarta a
  mão e compra cartas para todos os jogadores vivos, registra evento
  `wheel_resolved` e modela payoff mínimo de `Smothering Tithe`.
- `wheel_decision_context` registra net cards próprios, net cards dos
  oponentes, refill risk, payoff e `model_scope=multiplayer_discard_draw_v1`.
- O auditor estratégico só mantém finding de Wheel quando há risco de refill
  sem payoff/timing ou quando aparecer o modelo legado simplificado.

Leitura correta pós-correção:

- `board_wipe_wheel` deixou de bloquear o batch reproduzido e agora pode ser
  tratado como coerente na amostra.
- Isso não transforma Wheel/board wipe em heurística final: ainda falta corpus
  maior, hand-quality scoring, payoff denial mais completo e tuning por
  arquétipo.
- Como action critic ainda retornou findings low/medium, os replays continuam
  válidos para auditoria estratégica, mas não devem ser usados como verdade
  absoluta de WR sem agregação estatística e baseline fresco.

## Pendências priorizadas

### P1

- Melhorar bottom-card selection do London Mulligan.
- Registrar por que uma spell jogável foi rejeitada.
- Ampliar score de alvo de tutor e land-ramp com mais tipos de utility lands e
  estado de mesa; o slice mínimo já cobre high-value/untapped/fetch.
- Land-tutor activated abilities agora usam o mesmo guardrail de sacrifice-land
  e target scoring; manter monitoramento em corpus maior para confirmar que
  utility lands/fronteiras de risco seguem coerentes.
- Slice 2026-06-18: `pass/no-action` já ganhou reason estruturado no runtime
  (`hold_instant_speed_interaction`, `no_affordable_nonland_action`,
  `phase_or_heuristic_restriction_blocks_line`, `reactive_window_held`,
  `no_nonland_resources_available`). O gap que resta é comparativo: explicar
  melhor por que uma linha principal jogável foi rejeitada contra outra.
- Ampliar `decision_type=board_wipe`/`wheel` para corpus maior e melhorar
  hand-quality/payoff-denial: o gate mínimo de timing e o modelo multiplayer v1
  já estão implementados, mas ainda não cobrem toda estratégia de Wheel em
  Commander.
- Monitorar Mox Diamond/land discard e land sacrifice em corpora maiores; não
  promover como heurística universal sem replay limpo contínuo.

### P2

- Criar score de threat assessment por player/permanent com foco Commander.
- Diferenciar Lotus Petal em deck casual, high-power e cEDH.
- Registrar risco de crackback em combate.
- Persistir `selected_target_reason` de tutor como métrica agregável para
  futuros scorecards de aprendizado.

### P3

- Persistir decision traces em SQLite Hermes quando o schema estabilizar.
- Só considerar PostgreSQL depois de schema e uso operacional estarem maduros.
