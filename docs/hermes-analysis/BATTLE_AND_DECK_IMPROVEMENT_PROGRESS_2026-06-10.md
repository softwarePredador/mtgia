# Battle Engine e Deck Improvement — Progresso por Etapas

> Data: 2026-06-10
> Escopo: pendências de `IMPLEMENTATION_GAPS.md`, `PENDING_TASKS.md`,
> modularização e lógica de melhoria de deck.

## Etapa 1 — Regras oficiais 2026

**Status:** concluída.

**Entregue:**
- Matriz oficial de regras em `RULES_SOURCE_COVERAGE_AUDIT_2026-06-10.md`.
- Atualização de `IMPLEMENTATION_GAPS.md`, `PENDING_TASKS.md` e
  `BATTLE_SYSTEM_LOGIC.md`.
- Suporte mínimo para Vehicle/Spacecraft commander, hybrid identity estrita,
  Warp, Station, Flashback, Omen, Prepare, Paradigm, Lander, ability-word
  telemetry e combate multi-defensor.
- `DeckRulesService` aceita Legendary Vehicle/Spacecraft com power/toughness.

**Validação:**
- `python3 -m py_compile` nos scripts Hermes.
- `python3 test_battle_analyst_v10_3.py`.
- `dart analyze bin lib routes test`.
- `dart test test/mtg_rules_validation_test.dart`.
- `dart test test/color_identity_test.dart test/mtg_rules_validation_test.dart`.
- Hermes report-only pós-push: `PASS`.

## Etapa 2 — Alinhamento da melhoria de deck com análise funcional

**Status:** concluída.

**Problema validado:**
O optimize já carregava `functional_tags`, mas o diagnóstico semântico
`semantic_layer_v2.role_delta` ainda calculava perdas somente por
`semantic_tags_v2`. Isso podia deixar o gate parcial ignorar tags persistidas
que o usuário vê na análise do deck.

**Entregue:**
- `buildOptimizationSemanticV2Diagnostics` agora usa a mesma fonte única de
  roles do optimize: `functional_tags` persistido → `semantic_tags_v2` →
  heurística.
- Campos compatíveis preservados (`source`, `role_delta`, counts antigos).
- Campos auditáveis adicionados:
  - `role_source_priority`
  - `role_signal_source_counts`
- Helper sem uso `_classifySemanticV2FunctionalRole` removido.
- Teste novo prova que tags persistidas vencem `semantic_tags_v2` divergente.

**Validação:**
- `dart analyze lib/ai/optimization_functional_roles.dart test/optimization_validator_test.dart`
- `dart test test/optimization_validator_test.dart test/optimization_quality_gate_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart -r expanded`

## Etapa 3 — Auditoria de modularização

**Status:** em andamento, com quatorze extrações concluídas.

**Arquivos que precisam split dedicado:**
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py` — 7869 linhas.
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py` — 1011 linhas após quatorze extrações.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_rules_2026_tests.py` — 304 linhas extraídas.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_combat_tests.py` — 330 linhas extraídas.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replacement_tests.py` — 151 linhas extraídas.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_commander_tests.py` — 145 linhas extraídas.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_mana_tests.py` — 112 linhas extraídas.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py` — 289 linhas extraídas.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py` — 328 linhas extraídas.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_targeting_tests.py` — 241 linhas extraídas.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_summoning_sickness_tests.py` — 362 linhas extraídas.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_tests.py` — 229 linhas extraídas.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_import_tests.py` — 278 linhas extraídas.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_turn_flow_tests.py` — 147 linhas extraídas.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_zone_tests.py` — 171 linhas extraídas.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_permanents_complex_tests.py` — 246 linhas extraídas.
- `server/routes/ai/optimize/index.dart` — 3092 linhas.
- `server/lib/ai/optimize_runtime_support.dart` — 2772 linhas.

**Decisão:**
Não misturar refactors grandes com correções funcionais. A primeira extração
foi limitada às regras oficiais 2026 porque elas já formavam um domínio
fechado, com cenários próprios e sem dependência de produto mobile.

**Entregue:**
- Novo módulo `battle_rules_2026_tests.py` com `CONFORMANCE_SCENARIOS_2026`
  e `register_tests(...)`.
- Novo módulo `battle_combat_tests.py` com 10 regressões de combate:
  bloqueio pelo jogador correto, alvo letal, foco em caster de Approach,
  first strike, multi-block, trample, deathtouch, indestructible e double
  strike + trample.
- Novo módulo `battle_replacement_tests.py` com 7 regressões de
  replacement/prevention: life can't change, replacement registry,
  commander-to-command-zone e escudos de prevenção de dano.
- Novo módulo `battle_commander_tests.py` com 3 regressões Commander:
  ledger de commander damage, dano por origem/partner e retorno à command zone
  após destruição em combate.
- Novo módulo `battle_mana_tests.py` com 6 regressões diretas de mana/custos:
  fontes que não recarregam após gasto, tesouros, mana colorida, fontes
  flexíveis, básicos coloridos e híbrido/Phyrexian.
- Novo módulo `battle_stack_casting_tests.py` com 11 regressões de stack,
  priority e casting pipeline: stack LIFO, counterspell, janelas de prioridade
  com pilha vazia, custo travado antes de pagamento, X/alternative/additional
  costs, replay de modes/targets e proteção contra counter no próprio spell.
- Novo módulo `battle_card_specific_tests.py` com 9 regressões card-specific:
  três cenários de Lorehold miracle e proteções/interações específicas de
  `Boros Charm`, `Akroma's Will` e `Silence`; também cobre filtros Lorehold
  contra land/creature/flash creature e duração do efeito de Silence até cleanup.
- Novo módulo `battle_targeting_tests.py` com 7 regressões de targeting formal:
  hexproof, protection, ward como alvo legal com pagamento separado, metadata
  de replay, partial resolution de multi-target e ward pago/não pago.
- Novo módulo `battle_summoning_sickness_tests.py` com 11 regressões de
  summoning sickness, haste, vigilance, tokens hasty/non-hasty, landfall token,
  mana source creature e ativação de Elvish Reclaimer.
- Novo módulo `battle_zone_transition_tests.py` com 10 regressões de zone
  transitions, lifecycle de tokens fora do battlefield, remoção/tutor sem
  falsos positivos, ramp/recursion para lands e reanimation.
- Novo módulo `battle_card_import_tests.py` com 9 regressões de import/oracle:
  oracle cache, battle card rules verificadas, lands que não viram instant/sorcery,
  janela de end step sem cast de lands, artefatos curados e sync de regras
  geradas normalizado por oracle.
- Novo módulo `battle_turn_flow_tests.py` com 7 regressões de turn flow/draw:
  draw step único, Approach win state/turn stop, failed draw por biblioteca vazia,
  extra turns e discard/draw/treasure de Unexpected Windfall.
- Novo módulo `battle_sba_zone_tests.py` com 7 regressões de SBA/zone metadata:
  eliminação nova, cleanup com jogador eliminado, cancelamento +1/+1/-1/-1,
  aura/equipment ilegais, Saga final, LKI/zone id e exile visibility.
- Novo módulo `battle_permanents_complex_tests.py` com 6 regressões de
  permanents complexos: planeswalker loyalty/dano/SBA, battle/siege defense e
  recompensa da back face, DFC color identity, adventure, prototype e split.
- `test_battle_analyst_v10_3.py` continua sendo o runner único, mas registra
  os testes 2026, combate, replacement/prevention, Commander, mana/custos e
  stack/casting/card-specific/targeting/summoning sickness/zone transitions/card import/turn flow/SBA-zone/permanents complexos a partir dos módulos extraídos.
- A saída do runner continua exibindo esses testes, provando que a cobertura
  não foi removida.

**Validação:**
- `python3 -m py_compile battle_permanents_complex_tests.py battle_sba_zone_tests.py battle_turn_flow_tests.py battle_card_import_tests.py battle_zone_transition_tests.py battle_summoning_sickness_tests.py battle_targeting_tests.py battle_card_specific_tests.py battle_stack_casting_tests.py battle_mana_tests.py battle_commander_tests.py battle_replacement_tests.py battle_combat_tests.py battle_rules_2026_tests.py test_battle_analyst_v10_3.py battle_analyst_v9.py`
- `python3 test_battle_analyst_v10_3.py`

## Etapa 4 — Próximas pendências reais

**Prioridade atual:**
1. Separar mais suites Hermes por domínio, priorizando regressões remanescentes
   de continuous effects/layers, métricas do engine, conformance e triggers que
   ainda estão inline no runner.
2. Extrair blocos da rota `routes/ai/optimize/index.dart` para support
   services mantendo a rota como orquestração fina.
3. Implementar efeitos card-specific de Omen/Prepare/Paradigm/Station somente
   quando houver corpus concreto usando essas cartas.
4. Revalidar drift restante entre analysis/generate/optimize depois do split
   estrutural.
