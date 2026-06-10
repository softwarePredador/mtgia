# Pending Tasks — ManaLoom Commander Battle Engine

> **Handoff: 2026-06-09.**  
> 25/25 itens implementados no battle_analyst_v9.py (6900+ linhas).
> 0 macros pendentes nesta lista. Gaps avançados continuam rastreados em `IMPLEMENTATION_GAPS.md`.
>
> **Atualização 2026-06-10.**
> Nova rodada oficial CR/Commander 2026 adicionou 9 cenários de conformidade:
> Vehicle/Spacecraft commander, hybrid identity strict, Warp, Station, Prepare,
> Omen, Flashback, multi-defender Commander combat e modern ability-word telemetry.
> Todos estão cobertos em `test_battle_analyst_v10_3.py`.
> Tudo documentado com lógica exata, pseudocódigo e referências às Comprehensive Rules.
>
> **Atualização 2026-06-10 — etapa deck-improvement.**
> O diagnóstico/gate semântico do optimize deixou de depender apenas de
> `semantic_tags_v2` para `role_delta`: agora usa a mesma precedência do produto
> (`functional_tags` persistido → `semantic_tags_v2` → heurística) e expõe
> `role_source_priority`/`role_signal_source_counts` para auditoria. Testes
> focados adicionados em `test/optimization_validator_test.dart`.
>
> **Atualização 2026-06-10 — modularização.**
> Extrações iniciais da suite Hermes concluídas: regras oficiais 2026 foram
> movidas para `battle_rules_2026_tests.py` e regressões de combate foram
> movidas para `battle_combat_tests.py`; replacement/prevention foi movido
> para `battle_replacement_tests.py`, mantendo
> `test_battle_analyst_v10_3.py` como runner único.

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
| ✅ | Ward single-target removal integration | v9:check_ward/apply_effect_immediate |
| ✅ | LKI + Zone change counter | v9:2865, 2863 |
| ✅ | is_legal_target | v9:2596 |
| ✅ | Token lifecycle SBA | v9:2590 |
| ✅ | copy_spell_on_stack | v9:2443 |
| ✅ | 3 docs (LOGIC, GAPS, TASKS) | docs/hermes-analysis/ |
| ✅ | APNAP trigger ordering básico | v9:2444, 2752, tests |
| ✅ | Prioridade com pilha vazia | v9:priority_round/run_priority_loop |
| ✅ | Passos de combate formais | v9:beginning/declare/damage/end combat steps |
| ✅ | Casting pipeline 601.2 mínimo | v9:CastingContext/begin_cast_context/commit_cast_payment |
| ✅ | Replacement/Prevention mínimo | v9:ReplacementRegistry/ReplacementEvent |
| ✅ | Layers 1-7 básico | v9:ContinuousEffect/apply_continuous_effects |
| ✅ | Planeswalkers + Battles básico | v9:planeswalker/battle helpers + SBA |
| ✅ | DFC/Adventure/Prototype/Split básico | v9:get_card_characteristics/compute_color_identity |
| ✅ | Telemetria de saúde do motor | v9:EngineMetrics |
| ✅ | Suite de conformidade | `test_battle_analyst_v10_3.py:CONFORMANCE_SCENARIOS` |
| ✅ | Regras modernas 2026 | Omen/Station/Spacecraft/Warp/Prepare/Paradigm/Flashback/multi-defender |
| ✅ | Optimize role diagnostics alinhado ao produto | `functional_tags` → `semantic_tags_v2` → heurística |
| ✅ | Primeira extração da suite Hermes | `battle_rules_2026_tests.py` |
| ✅ | Segunda extração da suite Hermes | `battle_combat_tests.py` |
| ✅ | Terceira extração da suite Hermes | `battle_replacement_tests.py` |

---

## Próximo Hardening

| Ordem | Item | Esforço | Impacto | Depende de |
|---|---|---|---|---|
| 1 | Tipos complexos avançados | 5-7 dias | Alto | Harness por cenário |
| 2 | Seleção de alvos card-specific avançada | 3-5 dias | Alto | Targeting formal + multi-target básico |
| 3 | Plugar relatório agregado em cron/dashboard | 1-2 dias | Médio | `engine_metrics_report.py` |
| 4 | Efeitos card-specific de mecânicas 2026 | 5-10 dias | Médio | Corpus concreto usando Omen/Prepare/Station/Warp |
| 5 | Modularização de arquivos grandes | 3-6 dias | Alto | Contratos/testes verdes antes do split |

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

**Status 2026-06-10**: ✅ Contextual implementado / ⚠️ targeting legal formal fica no bloco Targeting.

**Arquivos**:
- `battle_analyst_v9.py`: `CastingContext`, `begin_cast_context`, `commit_cast_payment`, integração em `cast_spells_v8`.
- `test_battle_analyst_v10_3.py`: `test_casting_context_locks_cost_before_payment`, `test_casting_context_rejects_illegal_timing_without_payment`, `test_cast_spells_emits_minimal_601_pipeline_fields`.

**O que foi coberto**:
- Announce/evento `cast_announced` antes de pagamento.
- Custo travado via `locked_cost` antes do pagamento.
- Custo de comandante inclui `commander_tax` como `additional_generic`.
- X spells entram no custo travado via `x_value`.
- `alternative_cost` substitui o custo impresso para o cast.
- `additional_costs` somam custos extras ao custo travado.
- `modes` e `targets` são capturados no contexto e no replay.
- Timing básico impede creature/sorcery fora de main phase.
- Pagamento usa `Player.spend_mana` sobre o custo travado.
- Eventos de cast carregam `cast_pipeline=601.2_minimal`, `locked_cost`, `additional_generic` e `role`.

**Limite restante**:
- Targeting formal ainda fica no bloco próprio de targeting.
- Hybrid/Phyrexian básico cobre `{W/U}` e `{W/P}`; `{2/W}`, `{2/P}` e spend restrictions seguem pendentes no bloco de mana.

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

**Status 2026-06-10**: ✅ Registry determinística implementada / ⚠️ efeitos card-specific pendentes.

**Arquivos**:
- `battle_analyst_v9.py`: `ReplacementEvent`, `ReplacementRegistry`, integração em `change_life`, `deal_damage`, `gain_life`, `move_creature_from_battlefield`.
- `test_battle_analyst_v10_3.py`: `test_replacement_registry_prevents_damage_before_life_mutation`, `test_replacement_registry_moves_commander_to_command_zone`.

**O que foi coberto**:
- Dano é processado por prevention antes de mutar vida.
- `life_cant_change` e `protection_from_everything` passam por evento centralizado.
- Prevention shields quantitativos reduzem dano parcial/total e são consumidos antes da mutação de vida.
- Efeitos aplicáveis são escolhidos em ordem determinística por prioridade e expõem `replacement_order`.
- Ganho/perda de vida usa replacement antes de alterar life total.
- Commander em zone change para graveyard/exile/hand/library é redirecionado para command zone quando o owner não escolhe manter a zona destino.
- Evento `replacement_applied` expõe `replacement_pipeline=replacement_prevention_minimal`.

**Limite restante**:
- Escolha humana/APNAP real entre replacement effects concorrentes ainda é simulada por prioridade determinística.
- Efeitos self-replacement específicos por carta ainda precisam de casos dedicados.

**Regra**: CR 614 (Replacement), CR 615 (Prevention), CR 616 (Interaction)

---

### 6. Layers 1-7 (Continuous Effects)

**Status 2026-06-10**: ✅ Engine básico implementado / ⚠️ integração plena no loop pendente.

**Arquivos**:
- `battle_analyst_v9.py`: `ContinuousEffect`, `order_continuous_effects`, `apply_continuous_effects`.
- `test_battle_analyst_v10_3.py`: testes de sublayers 7a-7e, layers 3-6 e dependência/timestamp.

**O que foi coberto**:
- Layer 1: copiable values via `copy`.
- Layer 2: controller change via `set_controller`.
- Layer 3: text replacement.
- Layer 4: type add/remove/set.
- Layer 5: color add/set.
- Layer 6: ability add/remove.
- Layer 7: set/modify/counter/switch P/T com sublayer ordering.
- Ordenação por layer, sublayer, timestamp e dependências explícitas.

**Limite restante**:
- O loop de jogo ainda não recalcula todas as características dinamicamente a cada consulta.
- Dependências complexas de CR 613 ainda são declaradas explicitamente; não há inferência automática.

---

## P2 — Tipos Complexos

### 7. Planeswalkers e Battles

**Status 2026-06-10**: ✅ Básico implementado.

**Arquivos**:
- `battle_analyst_v9.py`: `handle_planeswalker_etb`, `can_activate_loyalty`, `activate_loyalty_ability`, `damage_to_planeswalker`, `handle_siege_etb`, `battle_takes_damage`, SBAs de loyalty/defense.
- `test_battle_analyst_v10_3.py`: `test_planeswalker_loyalty_activation_damage_and_sba`, `test_battle_defense_damage_and_sba`.

**O que foi coberto**:
- Planeswalker entra com loyalty inicial e só ativa loyalty uma vez por turno em main phase com stack vazia.
- Dano em planeswalker reduz loyalty.
- SBA move planeswalker com loyalty <= 0 para graveyard.
- Battle/Siege entra com defense e protector.
- Dano em Battle reduz defense.
- SBA move Battle com defense <= 0 para exile e marca `battle_defeated`.
- Se houver `back_face`, a face de trás é lançada/colocada no battlefield como recompensa básica da Siege.

**Limite restante**:
- Loyalty abilities ainda são genéricas; efeitos específicos de cada planeswalker não foram implementados.

---

### 8. DFC/Adventure/Prototype

**Status 2026-06-10**: ✅ Básico implementado.

**Arquivos**:
- `battle_analyst_v9.py`: `get_card_characteristics`, `compute_color_identity`, `adventure_spell_card`, `finish_resolved_spell`, `cast_adventure_spell_from_hand`, `cast_adventure_creature_from_exile`.
- `test_battle_analyst_v10_3.py`: `test_dfc_characteristics_and_color_identity_use_all_faces`, `test_adventure_prototype_and_split_characteristics_by_cast_mode`, `test_adventure_resolves_to_exile_then_casts_creature_from_exile`.

**O que foi coberto**:
- DFC usa front face fora da stack/battlefield e back face quando transformado em stack/battlefield.
- Adventure usa parte adventure no cast mode `adventure`.
- Adventure resolvida vai para exile com marker de recast e a criatura pode ser lançada do exile em main phase.
- Prototype usa custo/características prototype no cast mode `prototype`.
- Split usa metade escolhida na stack e características combinadas fora da stack.
- Color identity agrega mana/colors de faces/partes/adventure/prototype/split.

**Limite restante**:
- Efeitos específicos de faces complexas ainda dependem de regras card-specific.

---

## P2 — Infraestrutura

### 9. Telemetria de Saúde do Motor

**Status 2026-06-10**: ✅ Básico implementado.

**Arquivos**:
- `battle_analyst_v9.py`: `EngineMetrics`, `set_engine_metrics`, `clear_engine_metrics`, hooks em replay events, `Stack`, `check_sbas_until_stable` e `priority_round`.
- `engine_metrics_report.py`: agregador sanitizado de snapshots JSON por diretório/arquivo.
- `test_battle_analyst_v10_3.py`: `test_engine_metrics_collects_core_health_signals`, `test_engine_metrics_snapshot_writes_sanitized_json`, `test_engine_metrics_report_aggregates_sanitized_snapshots`.

**O que foi coberto**:
- Contadores de `stack_pushes`, `stack_resolutions`, `priority_rounds`, `sba_iterations`, `replacement_events` e movimentos por SBA.
- `event_counts` para eventos estruturados de replay, incluindo `replacement_applied`.
- `max_stack_depth` para detectar cenários de pilha mais profunda.
- `warnings` opcionais carregadas de eventos.
- API explícita para ligar/desligar métricas sem alterar o comportamento da simulação.
- Snapshot JSON sanitizado via `MANALOOM_ENGINE_METRICS_OUT`.
- Runners Hermes podem gravar snapshots por rodada via `MANALOOM_ENGINE_METRICS_DIR`.
- Relatório agregado `battle_engine_metrics_report_v1` soma contadores/eventos, max stack depth e amostras curtas de warning sem decklists/replays brutos.

**Limite restante**:
- Falta apenas plugar o agregador em cron/dashboard operacional se esse painel for necessário.

---

### 10. Suite de Conformidade

**Status 2026-06-10**: ✅ Básica implementada.

**Arquivo**:
- `test_battle_analyst_v10_3.py`: `CONFORMANCE_SCENARIOS` + testes de regressão/conformidade.

**Cenários cobertos**:
- `stack_lifo_405`: resolução LIFO da stack.
- `commander_damage_ledger_903_10a`: ledger de commander damage persiste após zone change para command zone.
- `commander_damage_per_origin_903_10a`: múltiplos comandantes acumulam 21 de dano separadamente por origem.
- `empty_library_draw_104_3c`: draw falho de library vazia perde mesmo com cartas na mão.
- `token_ceases_outside_battlefield_110_5f`: token em zona não-battlefield deixa de existir via SBA.
- `plus_minus_counter_cancel_704_5q`: marcadores +1/+1 e -1/-1 se cancelam como SBA.
- `illegal_attachment_sba_704_5m_n`: Aura ilegal vai ao cemitério; Equipment ilegal desanexa.
- `saga_final_chapter_sba_704_5s`: Saga no capítulo final vai ao cemitério após a habilidade deixar de estar pendente.
- `zone_change_lki_identity_400_7`: zone change registra LKI e avança identidade lógica por `_zone_id`.
- `exile_visibility_406_3`: cartas movidas para o exílio preservam metadados básicos de face-up/face-down.
- `blocked_stays_blocked_509_1h`: criatura bloqueada continua bloqueada após blocker sair.
- `end_of_combat_trigger_511_3`: triggers do fim do combate entram na stack em ordem APNAP e resolvem LIFO.
- `apnap_trigger_order_603_3b`: triggers entram na stack em ordem APNAP e resolvem LIFO.
- `prevention_before_damage_615`: prevention reduz dano antes de mutar vida.
- `hybrid_phyrexian_payment_601_2h`: mana híbrida colorida e Phyrexian colorida usam alternativas legais de pagamento.

**Limite restante**:
- Esta é uma suite mínima de regressão, não uma implementação completa das Comprehensive Rules.
- Cenários ainda sem suporte formal, como active-player concede, `{2/W}`/`{2/P}` e full APNAP pass sequence, continuam rastreados em `IMPLEMENTATION_GAPS.md`.

---

## Arquivos do Projeto

| Arquivo | Descrição | Linhas |
|---|---|---|
| `battle_analyst_v9.py` | Engine de batalha com todas as melhorias v9 | 7042 |
| `engine_metrics_report.py` | Agregador sanitizado de snapshots de telemetria | 104 |
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
