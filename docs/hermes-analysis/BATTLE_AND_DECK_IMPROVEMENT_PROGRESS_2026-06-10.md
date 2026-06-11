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
- A rota incremental `POST /decks/:id/cards` agora usa a mesma elegibilidade
  Commander 2026 compartilhada, evitando divergência entre validação completa
  e adição manual de comandante.

**Validação:**
- `python3 -m py_compile` nos scripts Hermes.
- `python3 test_battle_analyst_v10_3.py`.
- `dart analyze bin lib routes test`.
- `dart test test/mtg_rules_validation_test.dart`.
- `dart test test/color_identity_test.dart test/mtg_rules_validation_test.dart`.
- `dart test test/commander_eligibility_test.dart test/mtg_rules_validation_test.dart -r expanded`.
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

**Status:** em andamento, com dezenove extrações de testes e seis splits
do engine concluídos.

**Arquivos que precisam split dedicado:**
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py` — 7017 linhas após seis splits do engine.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_mana_cost_support.py` — 101 linhas extraídas do engine.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_characteristics_support.py` — 173 linhas extraídas do engine.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_land_support.py` — 110 linhas extraídas do engine.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_support.py` — 118 linhas extraídas do engine.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replacement_support.py` — 231 linhas extraídas do engine.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_support.py` — 381 linhas extraídas do engine.
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py` — 238 linhas após dezenove extrações; agora atua como runner/orquestrador fino.
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
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_continuous_effects_tests.py` — 155 linhas extraídas.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_engine_metrics_tests.py` — 133 linhas extraídas.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_conformance_tests.py` — 201 linhas extraídas.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_trigger_tests.py` — 228 linhas extraídas.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_misc_regression_tests.py` — 198 linhas extraídas.
- `server/routes/ai/optimize/index.dart` — 2986 linhas após splits de
  resposta/diagnóstico e envelope async da rota.
- `server/lib/ai/optimize_runtime_support.dart` — 2386 linhas após dois splits.
- `server/lib/ai/optimize_cache_support.dart` — 119 linhas extraídas do runtime.
- `server/test/optimize_cache_support_test.dart` — 77 linhas cobrindo cache key
  direta e delegação pelo runtime.
- `server/lib/ai/optimize_candidate_quality_support.dart` — 327 linhas
  extraídas do runtime.
- `server/test/optimize_candidate_quality_support_test.dart` — 97 linhas
  cobrindo ranking, buckets e export compatível pelo runtime.
- `server/lib/ai/optimize_route_response_support.dart` — 136 linhas extraídas
  da rota.
- `server/test/optimize_route_response_support_test.dart` — 156 linhas cobrindo
  cache response, contagem de swaps, diagnostics agressivos e payload
  `rebuild_guided`.
- `server/lib/ai/optimize_route_async_support.dart` — 179 linhas extraídas da
  rota.
- `server/test/optimize_route_async_support_test.dart` — 72 linhas cobrindo os
  contratos `202 Accepted` de optimize async e complete async.

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
- Novo módulo `battle_continuous_effects_tests.py` com 3 regressões de
  continuous effects/layers: sublayers 7b-7e, layers 3-6, timestamps e
  dependências declaradas.
- Novo módulo `battle_engine_metrics_tests.py` com 3 regressões de telemetria:
  contadores de stack/priority/SBA/replacement, snapshot JSON sanitizado e
  agregação por `engine_metrics_report.py`.
- Novo módulo `battle_conformance_tests.py` com a registry base de conformidade
  e 4 regressões transversais: cobertura versionada, blocked-stays-blocked,
  APNAP trigger order e prevenção antes de dano.
- Novo módulo `battle_event_trigger_tests.py` com 5 regressões de replay/triggers:
  evento estruturado de combate, triggers de fim de combate, APNAP LIFO,
  ordenação por timestamp do mesmo controlador e trigger de spell antes do spell.
- Novo módulo `battle_misc_regression_tests.py` com 6 regressões auxiliares:
  taxonomia de loss, token maker por lands, Lumra land recursion, proteção de
  jogador, auditoria de land atacante e criatura 0-power sem trigger de ataque.
- Novo módulo `battle_mana_cost_support.py` com helpers puros de mana/custo:
  `MANA_SYMBOL_TO_POOL`, parser de custo, merge de custos, contagem de X/Y/Z,
  custo de carta e snapshot de custo para replay. O split reduz dependência do
  arquivo principal sem tocar em jogador, pilha ou resolução.
- Novo módulo `battle_card_characteristics_support.py` com helpers puros de
  características de carta: faces/modos (DFC, adventure, omen, prepare,
  prototype, split), identidade de cor, leitura de listas JSON, checagem de
  criatura, Vehicle/Spacecraft e elegibilidade Commander 2026.
- Novo módulo `battle_land_support.py` com helpers puros de lands/fontes:
  cores de terrenos básicos/artefato, lista de lands conhecidas, normalização
  de nome, `source_colors` e `is_land`.
- Novo módulo `battle_zone_transition_support.py` com helpers parametrizados
  de zona: countered spell, move to exile, resolved spell com
  Flashback/Adventure, LKI e movimento de criatura saindo do battlefield com
  injeção explícita de `ReplacementRegistry`/`ReplacementEvent`.
- Novo módulo `battle_replacement_support.py` com `ReplacementEvent`,
  `ReplacementRegistry`, mudança de vida, dano, ganho de vida e escudos de
  prevenção. O engine mantém wrappers locais para amarrar replay ao módulo
  ativo e evitar drift de hook quando a suite carrega o battle analyst mais de
  uma vez.
- Novo módulo Dart `commander_eligibility.dart` centraliza a regra Commander
  2026 para criatura lendária, exceções textuais e Legendary Vehicle/Spacecraft
  com P/T. `DeckRulesService` e `POST /decks/:id/cards` agora usam a mesma
  função.
- Novo módulo Dart `optimize_route_response_support.dart` centraliza montagem
  de resposta cacheada, contagem de swaps, diagnostics agressivos e payload
  `rebuild_guided`, reduzindo a rota `ai/optimize` sem alterar contrato.
- Novo módulo Dart `optimize_route_async_support.dart` centraliza criação de
  job, fire-and-forget com crash handling e payloads `202 Accepted` para
  optimize async e complete async.
- `test_battle_analyst_v10_3.py` não contém mais `def test_` inline; ele carrega
  módulos, constrói os helpers/registry e executa a lista agregada.
- `test_battle_analyst_v10_3.py` continua sendo o runner único, mas registra
  os testes 2026, combate, replacement/prevention, Commander, mana/custos e
  stack/casting/card-specific/targeting/summoning sickness/zone transitions/card import/turn flow/SBA-zone/permanents complexos/continuous effects/engine metrics/conformance/event triggers/misc regressions a partir dos módulos extraídos.
- A saída do runner continua exibindo esses testes, provando que a cobertura
  não foi removida.

**Validação:**
- `python3 -m py_compile battle_mana_cost_support.py battle_card_characteristics_support.py battle_land_support.py battle_zone_transition_support.py battle_replacement_support.py battle_misc_regression_tests.py battle_event_trigger_tests.py battle_conformance_tests.py battle_engine_metrics_tests.py battle_continuous_effects_tests.py battle_permanents_complex_tests.py battle_sba_zone_tests.py battle_turn_flow_tests.py battle_card_import_tests.py battle_zone_transition_tests.py battle_summoning_sickness_tests.py battle_targeting_tests.py battle_card_specific_tests.py battle_stack_casting_tests.py battle_mana_tests.py battle_commander_tests.py battle_replacement_tests.py battle_combat_tests.py battle_rules_2026_tests.py test_battle_analyst_v10_3.py battle_analyst_v9.py`
- `python3 test_battle_analyst_v10_3.py`
- `dart analyze lib/commander_eligibility.dart lib/deck_rules_service.dart routes/decks/[id]/cards/index.dart test/commander_eligibility_test.dart`
- `dart test test/commander_eligibility_test.dart test/mtg_rules_validation_test.dart -r expanded`
- `dart analyze lib/ai/optimize_route_response_support.dart routes/ai/optimize/index.dart test/optimize_route_response_support_test.dart`
- `dart test test/optimize_route_response_support_test.dart test/optimization_pipeline_integration_test.dart test/optimize_learning_pipeline_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart -r expanded`
- `dart analyze lib/ai/optimize_route_async_support.dart routes/ai/optimize/index.dart test/optimize_route_async_support_test.dart`
- `dart test test/optimize_route_async_support_test.dart test/optimize_route_response_support_test.dart test/optimization_pipeline_integration_test.dart test/optimize_learning_pipeline_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart -r expanded`
- Hermes/AWS pós-push:
  - `battle_passes=130`.
  - analyze focado em `commander_eligibility`, `DeckRulesService`, rota
    incremental de cards, `optimize_route_response_support` e rota
    `ai/optimize`: sem issues.
  - `dart test test/commander_eligibility_test.dart test/optimize_route_response_support_test.dart -r expanded`: `All tests passed`.
  - `dart test test/commander_eligibility_test.dart test/mtg_rules_validation_test.dart test/color_identity_test.dart -r expanded`: 81 testes, `All tests passed`.
  - `manaloom-hermes-report-only.sh 211d5b01`: `PASS`; observações de risco
    foram cobertas pela rodada adicional de regras Commander/color identity.

## Etapa 4 — Próximas pendências reais

**Prioridade atual:**
1. Continuar o split do engine `battle_analyst_v9.py` por domínio. Os seis
   cortes seguros (`battle_mana_cost_support.py` e
   `battle_card_characteristics_support.py`, `battle_land_support.py`,
   `battle_zone_transition_support.py`, `battle_replacement_support.py` e
   `battle_sba_support.py`) já
   isolaram helpers de baixo risco; o sexto corte (`battle_sba_support.py`)
   isolou SBAs, anexos ilegais, Saga final, lifecycle de token e loop de
   estabilização com callbacks explícitos de replay/métricas/zone move.
2. Continuar extraindo blocos da rota `routes/ai/optimize/index.dart`: os
   cortes de response/diagnostics e envelope async já foram feitos; os próximos
   cortes seguros são parsing/guards do request e normalização/finalização do
   payload de sugestões.
3. Continuar o split de `server/lib/ai/optimize_runtime_support.dart`: os dois
   primeiros cortes moveram assinatura/cache para `optimize_cache_support.dart`
   e quality ranking/loader para `optimize_candidate_quality_support.dart`,
   mantendo wrappers/exports compatíveis.
4. Implementar efeitos card-specific de Omen/Prepare/Paradigm/Station somente
   quando houver corpus concreto usando essas cartas.
5. Revalidar drift restante entre analysis/generate/optimize depois do split
   estrutural.
