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
- Rechecagem oficial de Commander Brackets: o update de 2026-02-09 mantém
  hybrid identity estrita, e o update de 2025-10-21 lista Game Changers que
  também precisam preservar tags secundárias como tutor, fast mana e proteção.
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

### Revisão complementar 2026-06-11 — snapshot oficial e Brawl

**Status:** concluída localmente.

**Problema validado:**
- `server/magicrules.txt` ainda carregava Comprehensive Rules efetivas em
  `2026-02-27`, enquanto a fonte oficial atual em `magic.wizards.com/en/rules`
  publica `MagicCompRules 20260417.txt`.
- A elegibilidade compartilhada de commander não distinguia Brawl de Commander
  para planeswalkers lendários, apesar de CR 903.12c permitir planeswalker como
  comandante em Brawl.

**Entregue:**
- `server/magicrules.txt` atualizado para o snapshot oficial efetivo em
  `2026-04-17`.
- Novo teste guardião `server/test/magic_rules_source_test.dart`.
- `isCommanderEligibleCard(format: ...)` mantém Commander estrito por padrão e
  aceita planeswalker lendário somente em `brawl`.
- `DeckRulesService` e `POST /decks/:id/cards` passam o formato real para o
  helper compartilhado.
- `color_identity_test.dart` agora prova diretamente que `resolveCardColorIdentity`
  expande símbolos híbridos para todas as cores componentes.

**Validação local:**
- `dart analyze bin lib routes test`.
- `dart test test/magic_rules_source_test.dart test/commander_eligibility_test.dart test/color_identity_test.dart test/mtg_rules_validation_test.dart test/deck_validation_test.dart --reporter compact`.
- `dart_frog dev -p 8082` com TTY + `dart test test/decks_incremental_add_test.dart --reporter compact`.
- `python3 -m py_compile` nos scripts do battle analyst.
- `python3 test_battle_analyst_v10_3.py`.
- `git diff --check`.

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

**Status:** em andamento, com dezenove extrações de testes, seis splits
do engine e dezenove splits da rota/runtime de optimize concluídos.

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
- `server/routes/ai/optimize/index.dart` — 2522 linhas após splits de
  resposta/diagnóstico, envelope async, parsing inicial, payload final e
  warnings/diagnostics/fallback vazio/rejeições de qualidade/validação
  pós-processamento/retry orchestration/filtro inicial de sugestões/filtro de
  identidade de cor/filtro de bracket/top-up determinístico do modo complete e
  proteção de remoção de lands/reequilíbrio pós-filtros/coleta EDHREC/query de
  dados completos de adições/análise virtual pós-swap/execução do
  `OptimizationValidator`. A rota ainda deve seguir reduzindo até ficar como
  orquestrador fino.
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
- `server/lib/ai/optimize_route_request_support.dart` — 65 linhas extraídas da
  rota.
- `server/test/optimize_route_request_support_test.dart` — 67 linhas cobrindo
  defaults, overrides por presença de chave, `async` tri-state e comportamento
  legado de `mode.contains('complete')`.
- `server/lib/ai/optimize_route_payload_support.dart` — 186 linhas extraídas da
  rota.
- `server/test/optimize_route_payload_support_test.dart` — 147 linhas cobrindo
  balanceamento final, filtro de duplicidade Commander/Brawl e reconstrução de
  `recommendations`.
- `server/lib/ai/optimize_route_warnings_support.dart` — 61 linhas extraídas da
  rota.
- `server/test/optimize_route_warnings_support_test.dart` — 89 linhas cobrindo
  warnings finais de cartas inválidas, identidade de cor, bracket, tema e
  fallback vazio.
- `server/lib/ai/optimize_route_diagnostics_support.dart` — 37 linhas extraídas
  da rota.
- `server/test/optimize_route_diagnostics_support_test.dart` — 88 linhas
  cobrindo shape de fallback diagnostics e merge incremental sem sobrescrita.
- `server/lib/ai/optimize_route_empty_fallback_support.dart` — 103 linhas
  extraídas da rota.
- `server/test/optimize_route_empty_fallback_support_test.dart` — 108 linhas
  cobrindo seleção de candidatas, aplicação de swaps e razões de falha do
  fallback de sugestões vazias.
- `server/lib/ai/optimize_route_quality_rejection_support.dart` — 48 linhas
  extraídas da rota.
- `server/test/optimize_route_quality_rejection_support_test.dart` — 65 linhas
  cobrindo payloads `OPTIMIZE_NO_SAFE_SWAPS` e
  `OPTIMIZE_QUALITY_REJECTED`.
- `server/lib/ai/optimize_route_post_validation_support.dart` — 146 linhas
  extraídas da rota.
- `server/test/optimize_route_post_validation_support_test.dart` — 119 linhas
  cobrindo warnings de identidade de cor, coleta de ausentes no EDHREC,
  mismatch de tema e comparação antes/depois.
- `server/lib/ai/optimize_route_retry_support.dart` — 64 linhas extraídas da
  rota.
- `server/test/optimize_route_retry_support_test.dart` — 105 linhas cobrindo
  planos de fallback IA e metadata dos retornos de optimize.
- `server/lib/ai/optimize_route_suggestion_filter_support.dart` — 76 linhas
  extraídas da rota.
- `server/test/optimize_route_suggestion_filter_support_test.dart` — 70 linhas
  cobrindo filtro inicial de removals/additions, comandante, core cards,
  duplicatas e modo complete.
- `server/lib/ai/optimize_route_color_identity_filter_support.dart` — 38
  linhas extraídas da rota.
- `server/test/optimize_route_color_identity_filter_support_test.dart` — 51
  linhas cobrindo filtro de identidade de cor, comandante colorless e dados de
  identidade ausentes.
- `server/lib/ai/optimize_route_bracket_policy_filter_support.dart` — 47
  linhas extraídas da rota.
- `server/test/optimize_route_bracket_policy_filter_support_test.dart` — 74
  linhas cobrindo bloqueio por bracket, repetições permitidas e normalização de
  dados vindos da query.
- `server/lib/ai/optimize_route_complete_top_up_support.dart` — 91 linhas
  extraídas da rota.
- `server/test/optimize_route_complete_top_up_support_test.dart` — 72 linhas
  cobrindo dedupe de singleton, cópias fora de singleton, distribuição
  round-robin de básicos e entradas sem `card_id`.
- `server/lib/ai/optimize_route_land_removal_protection_support.dart` — 62
  linhas extraídas da rota.
- `server/test/optimize_route_land_removal_protection_support_test.dart` — 62
  linhas cobrindo bloqueio de remoção de land em baixa contagem, passagem quando
  a contagem é segura, matching case-insensitive e nomes não-land.
- `server/lib/ai/optimize_route_rebalance_support.dart` — 128 linhas extraídas
  da rota.
- `server/test/optimize_route_rebalance_support_test.dart` — 92 linhas cobrindo
  plano de missing/excludes, aplicação de substitutas e truncamento final.

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
- Novo módulo Dart `optimize_route_request_support.dart` centraliza o parsing
  inicial do request sem alterar casts, defaults ou quirks legados.
- Novo módulo Dart `optimize_route_payload_support.dart` centraliza
  balanceamento/filtro final de sugestões e corrige `recommendations` stale
  após truncamento, safety net ou remoção de duplicatas.
- Novo módulo Dart `optimize_route_warnings_support.dart` centraliza warnings
  finais da rota sem alterar o shape público de `warnings`.
- Novo módulo Dart `optimize_route_diagnostics_support.dart` centraliza o Map
  de `optimize_diagnostics` e merges incrementais sem sobrescrever diagnostics
  já anexados.
- Novo módulo Dart `optimize_route_empty_fallback_support.dart` centraliza a
  seleção de candidatas e aplicação/razões do fallback quando a IA retorna
  sugestões vazias.
- Novo módulo Dart `optimize_route_quality_rejection_support.dart` centraliza
  payloads de rejeição do quality gate sem alterar códigos/shape público.
- Novo módulo Dart `optimize_route_post_validation_support.dart` centraliza
  builders de warnings/improvements pós-processamento: identidade de cor,
  validação EDHREC, mismatch de tema e comparação de análise antes/depois.
- `optimize_route_post_validation_support.dart` agora também centraliza a coleta
  de adições ausentes nos dados EDHREC via callback, removendo o loop direto da
  rota sem acoplar o helper ao tipo `EdhrecCommanderData`.
- Novo módulo Dart `optimize_route_retry_support.dart` centraliza o plano de
  retry de deterministic-first para IA e a aplicação de metadata (`mode`,
  `strategy_source`, `fallback_trigger`) nos retornos de optimize.
- Novo módulo Dart `optimize_route_suggestion_filter_support.dart` centraliza
  filtros iniciais de sugestões antes de `validateCardNames`: balanceamento,
  sanitização, proteção de comandante/core cards, bloqueio de no-op e
  preservação de repetições em modo complete.
- Novo módulo Dart `optimize_route_color_identity_filter_support.dart`
  centraliza o filtro puro de adições por identidade de cor do commander,
  deixando a rota responsável apenas pelo SELECT que monta `identityByName`.
- Novo módulo Dart `optimize_route_bracket_policy_filter_support.dart`
  centraliza a aplicação da política de bracket sobre adições já resolvidas,
  preservando ordem/repetição da lista validada pela rota.
- Novo módulo Dart `optimize_route_complete_top_up_support.dart` centraliza o
  top-up determinístico do modo complete, separando cálculo de missing/dedupe da
  query que carrega IDs de terrenos básicos.
- Novo módulo Dart `optimize_route_land_removal_protection_support.dart`
  centraliza a proteção contra remoção de terrenos quando o deck já está abaixo
  da margem segura, removendo o cálculo de contagem/filtragem da rota.
- Novo módulo Dart `optimize_route_rebalance_support.dart` centraliza a parte
  pura do reequilíbrio pós-filtros: plano de substitutas, aplicação das linhas
  retornadas e truncamento final sem chamar banco/OpenAI.
- Correção funcional em `edh_bracket_policy.dart`: cartas oficiais Game
  Changer não encerram mais o classificador cedo; agora preservam tags
  secundárias como `fastMana`, `tutor`, `freeInteraction`, `valueEngine` e
  `infiniteCombo`. Isso deixa diagnostics e orçamento de bracket mais fiéis ao
  papel real da carta.
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
- `dart analyze lib/ai/optimize_route_request_support.dart routes/ai/optimize/index.dart test/optimize_route_request_support_test.dart`
- `dart test test/optimize_route_request_support_test.dart test/optimize_route_async_support_test.dart test/optimize_route_response_support_test.dart test/optimize_learning_pipeline_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart -r expanded`
- `dart analyze lib/ai/optimize_route_payload_support.dart routes/ai/optimize/index.dart test/optimize_route_payload_support_test.dart`
- `dart test test/optimize_route_payload_support_test.dart test/optimize_route_request_support_test.dart test/optimize_route_async_support_test.dart test/optimize_route_response_support_test.dart test/optimization_pipeline_integration_test.dart test/optimize_learning_pipeline_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart -r expanded`
- `dart analyze lib/ai/optimize_route_warnings_support.dart routes/ai/optimize/index.dart test/optimize_route_warnings_support_test.dart`
- `dart test test/optimize_route_warnings_support_test.dart test/optimize_route_payload_support_test.dart test/optimize_route_request_support_test.dart test/optimize_route_async_support_test.dart test/optimize_route_response_support_test.dart test/optimization_pipeline_integration_test.dart test/optimize_learning_pipeline_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`
- `dart analyze lib/ai/optimize_route_diagnostics_support.dart routes/ai/optimize/index.dart test/optimize_route_diagnostics_support_test.dart`
- `dart test test/optimize_route_diagnostics_support_test.dart test/optimize_route_warnings_support_test.dart test/optimize_route_payload_support_test.dart test/optimize_route_response_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`
- `dart analyze lib/ai/optimize_route_empty_fallback_support.dart routes/ai/optimize/index.dart test/optimize_route_empty_fallback_support_test.dart`
- `dart test test/optimize_route_empty_fallback_support_test.dart test/optimize_route_diagnostics_support_test.dart test/optimize_route_warnings_support_test.dart test/optimize_route_payload_support_test.dart test/optimization_pipeline_integration_test.dart test/optimize_learning_pipeline_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`
- `dart analyze lib/ai/optimize_route_quality_rejection_support.dart routes/ai/optimize/index.dart test/optimize_route_quality_rejection_support_test.dart`
- `dart test test/optimize_route_quality_rejection_support_test.dart test/optimize_route_empty_fallback_support_test.dart test/optimize_route_diagnostics_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`
- `dart analyze lib/ai/optimize_route_post_validation_support.dart routes/ai/optimize/index.dart test/optimize_route_post_validation_support_test.dart`
- `dart test test/optimize_route_post_validation_support_test.dart test/optimize_route_quality_rejection_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`
- `dart analyze lib/ai/optimize_route_retry_support.dart routes/ai/optimize/index.dart test/optimize_route_retry_support_test.dart`
- `dart test test/optimize_route_retry_support_test.dart test/optimize_route_post_validation_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`
- `dart analyze lib/ai/optimize_route_suggestion_filter_support.dart routes/ai/optimize/index.dart test/optimize_route_suggestion_filter_support_test.dart`
- `dart test test/optimize_route_suggestion_filter_support_test.dart test/optimize_route_retry_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`
- `dart analyze lib/ai/optimize_route_color_identity_filter_support.dart routes/ai/optimize/index.dart test/optimize_route_color_identity_filter_support_test.dart`
- `dart test test/optimize_route_color_identity_filter_support_test.dart test/optimize_route_suggestion_filter_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`
- `dart analyze lib/ai/optimize_route_bracket_policy_filter_support.dart routes/ai/optimize/index.dart test/optimize_route_bracket_policy_filter_support_test.dart`
- `dart test test/optimize_route_bracket_policy_filter_support_test.dart test/optimize_route_color_identity_filter_support_test.dart test/optimize_route_suggestion_filter_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`
- `dart analyze lib/ai/optimize_route_complete_top_up_support.dart routes/ai/optimize/index.dart test/optimize_route_complete_top_up_support_test.dart`
- `dart test test/optimize_route_complete_top_up_support_test.dart test/optimize_route_bracket_policy_filter_support_test.dart test/optimize_route_color_identity_filter_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`
- `dart analyze lib/ai/optimize_route_land_removal_protection_support.dart routes/ai/optimize/index.dart test/optimize_route_land_removal_protection_support_test.dart`
- `dart test test/optimize_route_land_removal_protection_support_test.dart test/optimize_route_complete_top_up_support_test.dart test/optimize_route_bracket_policy_filter_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`
- `dart analyze lib/ai/optimize_route_rebalance_support.dart routes/ai/optimize/index.dart test/optimize_route_rebalance_support_test.dart`
- `dart test test/optimize_route_rebalance_support_test.dart test/optimize_route_land_removal_protection_support_test.dart test/optimize_route_complete_top_up_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`
- `dart analyze lib/ai/optimize_route_post_validation_support.dart routes/ai/optimize/index.dart test/optimize_route_post_validation_support_test.dart`
- `dart test test/optimize_route_post_validation_support_test.dart test/optimize_route_rebalance_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`
- `dart analyze lib/edh_bracket_policy.dart test/edh_bracket_policy_test.dart test/optimize_runtime_support_test.dart`
- `dart test test/edh_bracket_policy_test.dart test/optimize_runtime_support_test.dart test/optimize_route_bracket_policy_filter_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`
- Hermes/AWS pós-push:
  - `battle_passes=130`.
  - analyze focado em `commander_eligibility`, `DeckRulesService`, rota
    incremental de cards, `optimize_route_response_support` e rota
    `ai/optimize`: sem issues.
  - `dart test test/commander_eligibility_test.dart test/optimize_route_response_support_test.dart -r expanded`: `All tests passed`.
  - `dart test test/commander_eligibility_test.dart test/mtg_rules_validation_test.dart test/color_identity_test.dart -r expanded`: 81 testes, `All tests passed`.
  - `manaloom-hermes-report-only.sh 211d5b01`: `PASS`; observações de risco
    foram cobertas pela rodada adicional de regras Commander/color identity.
- Hermes/AWS pós-push do split async (`b2f51ade`):
  - `battle_passes=130`.
  - analyze focado em `optimize_route_async_support`, rota `ai/optimize` e
    teste async: sem issues.
  - `dart test test/optimize_route_async_support_test.dart test/optimize_route_response_support_test.dart -r expanded`: `All tests passed`.
  - `dart test test/optimization_pipeline_integration_test.dart test/optimize_learning_pipeline_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart -r expanded`: 39 testes, `All tests passed`.
  - `manaloom-hermes-report-only.sh b2f51ad`: `PASS`; risco de cobertura
    integrada mitigado pela rodada adicional de pipeline/route contract.
- Hermes/AWS pós-push do split request (`d5194431`):
  - `battle_passes=130`.
  - analyze focado em `optimize_route_request_support`, rota `ai/optimize` e
    teste de request parsing: sem issues.
  - `dart test test/optimize_route_request_support_test.dart test/optimize_route_async_support_test.dart test/optimize_route_response_support_test.dart test/optimize_learning_pipeline_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart -r expanded`: 25 testes, `All tests passed`.
  - `manaloom-hermes-report-only.sh d519443`: `PASS`, risco baixo.
- Hermes/AWS pós-push do split payload (`e1a1d6e6`):
  - `battle_passes=130`.
  - analyze focado em `optimize_route_payload_support`, rota `ai/optimize` e
    teste de payload final: sem issues.
  - `dart test test/optimize_route_payload_support_test.dart test/optimize_route_request_support_test.dart test/optimize_route_async_support_test.dart test/optimize_route_response_support_test.dart test/optimization_pipeline_integration_test.dart test/optimize_learning_pipeline_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 52 testes, `All tests passed`.
  - `manaloom-hermes-report-only.sh e1a1d6e6`: `PASS`; risco médio por caminho
    runtime mitigado por testes unitários do payload e pipeline/route contract.
- Hermes/AWS pós-push do split warnings (`69f0cb3b`):
  - `battle_passes=130`.
  - analyze focado em `optimize_route_warnings_support`, rota `ai/optimize` e
    teste de warnings finais: sem issues.
  - `dart test test/optimize_route_warnings_support_test.dart test/optimize_route_payload_support_test.dart test/optimize_route_request_support_test.dart test/optimize_route_async_support_test.dart test/optimize_route_response_support_test.dart test/optimization_pipeline_integration_test.dart test/optimize_learning_pipeline_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 55 testes, `All tests passed`.
  - `manaloom-hermes-report-only.sh 69f0cb3b`: `PASS`; sem `RISK` novo, mudança
    classificada como extração pura sem alteração comportamental.
- Hermes/AWS pós-push do split diagnostics (`a526ec5c`):
  - `battle_passes=130`.
  - analyze focado em `optimize_route_diagnostics_support`, rota `ai/optimize`
    e teste de diagnostics finais: sem issues.
  - `dart test test/optimize_route_diagnostics_support_test.dart test/optimize_route_warnings_support_test.dart test/optimize_route_payload_support_test.dart test/optimize_route_response_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 40 testes, `All tests passed`.
  - `manaloom-hermes-report-only.sh a526ec5c`: `PASS`; sem riscos, mudança
    classificada como extração pura sem alteração comportamental.
- Hermes/AWS pós-push do split fallback vazio (`22bf1618`):
  - `battle_passes=130`.
  - analyze focado em `optimize_route_empty_fallback_support`, rota
    `ai/optimize` e teste de fallback vazio: sem issues.
  - `dart test test/optimize_route_empty_fallback_support_test.dart test/optimize_route_diagnostics_support_test.dart test/optimize_route_warnings_support_test.dart test/optimize_route_payload_support_test.dart test/optimization_pipeline_integration_test.dart test/optimize_learning_pipeline_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 57 testes, `All tests passed`.
  - `manaloom-hermes-report-only.sh 22bf1618`: `PASS`; Hermes classificou
    como extração limpa com risco baixo genérico de wiring, mitigado pela
    rodada remota de pipeline/route contract acima.
- Hermes/AWS pós-push do split quality rejection (`0186f6b5`):
  - `battle_passes=130`.
  - analyze focado em `optimize_route_quality_rejection_support`, rota
    `ai/optimize` e teste de rejeições de qualidade: sem issues.
  - `dart test test/optimize_route_quality_rejection_support_test.dart test/optimize_route_empty_fallback_support_test.dart test/optimize_route_diagnostics_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 38 testes, `All tests passed`.
  - `manaloom-hermes-report-only.sh 0186f6b5`: `PASS`; sem riscos aparentes,
    mudança classificada como extração com cobertura dedicada.
- Hermes/AWS pós-push do split post-validation (`92723ed4`):
  - `battle_passes=130`.
  - analyze focado em `optimize_route_post_validation_support`, rota
    `ai/optimize` e teste de validação pós-processamento: sem issues.
  - `dart test test/optimize_route_post_validation_support_test.dart test/optimize_route_quality_rejection_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 32 testes, `All tests passed`.
  - `manaloom-hermes-report-only.sh 92723ed4`: `PASS`; Hermes apontou risco
    baixo de wiring por extração, mitigado por teste unitário, pipeline e route
    contract remotos.
- Hermes/AWS pós-push do split retry (`92a4083a`):
  - `battle_passes=130`.
  - analyze focado em `optimize_route_retry_support`, rota `ai/optimize` e
    teste de retry: sem issues.
  - `dart test test/optimize_route_retry_support_test.dart test/optimize_route_post_validation_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 34 testes, `All tests passed`.
  - `manaloom-hermes-report-only.sh 92a4083a`: `PASS`; risco baixo de wiring
    por refactor interno, sem mudança de contrato público.
- Hermes/AWS pós-push do split suggestion-filter (`9ced572b`):
  - `battle_passes=130`.
  - analyze focado em `optimize_route_suggestion_filter_support`, rota
    `ai/optimize` e teste de filtro inicial: sem issues.
  - `dart test test/optimize_route_suggestion_filter_support_test.dart test/optimize_route_retry_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 32 testes, `All tests passed`.
  - `manaloom-hermes-report-only.sh 9ced572b`: `PASS`; risco baixo de
    fidelidade de extração, mitigado por teste dedicado e pipeline/route
    contract remotos.
- Hermes/AWS pós-push do split color-identity-filter (`8bd2fe69`):
  - `battle_passes=130`.
  - analyze focado em `optimize_route_color_identity_filter_support`, rota
    `ai/optimize` e teste de identidade de cor: sem issues.
  - `dart test test/optimize_route_color_identity_filter_support_test.dart test/optimize_route_suggestion_filter_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 31 testes, `All tests passed`.
  - `manaloom-hermes-report-only.sh 8bd2fe69`: `PASS`; risco baixo de wiring
    em endpoint core, mitigado por teste unitário e pipeline/route contract
    remotos.
- Hermes/AWS pós-push do split bracket-policy-filter (`7bc10b13`):
  - `battle_passes=130`.
  - analyze focado em `edh_bracket_policy`, `optimize_route_bracket_policy_filter_support`,
    rota `ai/optimize` e testes de bracket/runtime: sem issues.
  - `dart test test/edh_bracket_policy_test.dart test/optimize_runtime_support_test.dart test/optimize_route_bracket_policy_filter_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 65 testes, `All tests passed`.
  - `manaloom-hermes-report-only.sh 7bc10b13`: `PASS`; sem riscos. Hermes
    classificou como extração limpa com cobertura dedicada e docs alinhadas.
- Hermes/AWS pós-push do split complete-top-up (`e39113b0`):
  - `battle_passes=130`.
  - analyze focado em `optimize_route_complete_top_up_support`, rota
    `ai/optimize` e teste de top-up: sem issues.
  - `dart test test/optimize_route_complete_top_up_support_test.dart test/optimize_route_bracket_policy_filter_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 32 testes, `All tests passed`.
  - `manaloom-hermes-report-only.sh e39113b0`: `PASS`; sem riscos no escopo do
    diff. Hermes observou apenas os 22 avisos SQL preexistentes da rota, fora
    deste corte.
- Hermes/AWS pós-push do split land-removal-protection (`8854208b`):
  - `battle_passes=130`.
  - analyze focado em `optimize_route_land_removal_protection_support`, rota
    `ai/optimize` e teste de proteção de lands: sem issues.
  - `dart test test/optimize_route_land_removal_protection_support_test.dart test/optimize_route_complete_top_up_support_test.dart test/optimize_route_bracket_policy_filter_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 36 testes, `All tests passed`.
  - `manaloom-hermes-report-only.sh 8854208b`: `PASS`; risco menor apenas de
    wiring de import, mitigado pelo analyze e pela suite remota.
- Hermes/AWS pós-push do split rebalance (`c7104a44`):
  - `battle_passes=130`.
  - analyze focado em `optimize_route_rebalance_support`, rota `ai/optimize` e
    teste de reequilíbrio: sem issues.
  - `dart test test/optimize_route_rebalance_support_test.dart test/optimize_route_land_removal_protection_support_test.dart test/optimize_route_complete_top_up_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 39 testes, `All tests passed`.
  - `manaloom-hermes-report-only.sh c7104a44`: `PASS`; risco baixo de wire-up,
    mitigado por analyze/testes remotos.
- Hermes/AWS pós-push do split EDHREC addition checks (`247859d6`):
  - `battle_passes=130`.
  - analyze focado em `optimize_route_post_validation_support`, rota
    `ai/optimize` e teste de pós-validação: sem issues.
  - `dart test test/optimize_route_post_validation_support_test.dart test/optimize_route_rebalance_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 37 testes, `All tests passed`.
  - `manaloom-hermes-report-only.sh 247859d6`: `PASS`; sem riscos.
- Split local da query de dados completos das adições/quality gate:
  - Criado `server/lib/ai/optimize_route_addition_data_support.dart`.
  - Criado `server/test/optimize_route_addition_data_support_test.dart`.
  - A rota `server/routes/ai/optimize/index.dart` removeu SQL inline para
    dados completos de adições em modo complete e optimize normal.
  - Validação local focada:
    - `dart analyze lib/ai/optimize_route_addition_data_support.dart routes/ai/optimize/index.dart test/optimize_route_addition_data_support_test.dart`: sem issues.
    - `dart test test/optimize_route_addition_data_support_test.dart test/optimize_route_post_validation_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 35 testes, `All tests passed`.
  - Validação local ampliada:
    - `dart analyze bin lib routes test`: sem issues.
    - `dart test test/optimize_route_addition_data_support_test.dart test/optimize_route_post_validation_support_test.dart test/optimize_route_rebalance_support_test.dart test/optimize_route_land_removal_protection_support_test.dart test/optimize_route_complete_top_up_support_test.dart test/optimize_route_bracket_policy_filter_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 52 testes, `All tests passed`.
    - `python3 -m py_compile battle_analyst_v9.py battle_*_support.py battle_*_tests.py test_battle_analyst_v10_3.py`: sem erro.
    - `python3 test_battle_analyst_v10_3.py`: `battle_passes=130`.
- Hermes/AWS pós-push do split addition-data (`c694776b`):
  - O comando agente interativo via `/opt/hermes/bin/hermes -z` não retornou em
    180s para um prompt report-only curto; a etapa foi substituída por
    validação determinística no container.
  - `git pull --ff-only origin master`: `REMOTE_HEAD=c694776beed3feacd4237ea8109e29a2062c5f15`.
  - `dart analyze lib/ai/optimize_route_addition_data_support.dart routes/ai/optimize/index.dart test/optimize_route_addition_data_support_test.dart`: sem issues.
  - `dart test test/optimize_route_addition_data_support_test.dart test/optimize_route_post_validation_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 35 testes, `All tests passed`.
  - `python3 -m py_compile battle_analyst_v9.py battle_*_support.py battle_*_tests.py test_battle_analyst_v10_3.py`: sem erro.
  - `python3 test_battle_analyst_v10_3.py`: `battle_passes=130`.
  - Risco operacional separado: o modo agente Hermes não é confiável para
    report-only curto neste momento; comandos determinísticos no container
    continuam funcionais.
- Split local da análise virtual pós-swap:
  - Criado `server/lib/ai/optimize_route_virtual_analysis_support.dart`.
  - Criado `server/test/optimize_route_virtual_analysis_support_test.dart`.
  - A rota `server/routes/ai/optimize/index.dart` removeu a montagem inline de
    `additionsForAnalysis`, `virtualDeck`, `DeckArchetypeAnalyzerCore` e
    summary antes/depois; a execução do `OptimizationValidator` permanece
    inline como próximo corte.
  - Validação local focada:
    - `dart analyze lib/ai/optimize_route_virtual_analysis_support.dart routes/ai/optimize/index.dart test/optimize_route_virtual_analysis_support_test.dart`: sem issues.
    - `dart test test/optimize_route_virtual_analysis_support_test.dart test/optimize_route_addition_data_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 30 testes, `All tests passed`.
- Hermes/AWS pós-push do split virtual-analysis (`0149bf18`):
  - `git pull --ff-only origin master`: `REMOTE_HEAD=0149bf18274d1a2d3a8f8e214741707f7300c047`.
  - `dart analyze lib/ai/optimize_route_virtual_analysis_support.dart routes/ai/optimize/index.dart test/optimize_route_virtual_analysis_support_test.dart`: sem issues.
  - `dart test test/optimize_route_virtual_analysis_support_test.dart test/optimize_route_addition_data_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 30 testes, `All tests passed`.
  - `python3 -m py_compile battle_analyst_v9.py battle_*_support.py battle_*_tests.py test_battle_analyst_v10_3.py`: sem erro.
  - `python3 test_battle_analyst_v10_3.py`: `battle_passes=130`.
- Split local da execução do `OptimizationValidator`:
  - Criado `server/lib/ai/optimize_route_validator_support.dart`.
  - Criado `server/test/optimize_route_validator_support_test.dart`.
  - A rota `server/routes/ai/optimize/index.dart` moveu a execução injetável do
    validator, persistência de `postAnalysis.validation` e warnings de
    reprovação para support dedicado. O próximo corte fica limitado à decisão
    de rejeição/retry final.
  - Validação local focada:
    - `dart analyze lib/ai/optimize_route_validator_support.dart routes/ai/optimize/index.dart test/optimize_route_validator_support_test.dart`: sem issues.
    - `dart test test/optimize_route_validator_support_test.dart test/optimize_route_virtual_analysis_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 28 testes, `All tests passed`.
- Hermes/AWS pós-push do split validator-support (`ff7580b3`):
  - `git pull --ff-only origin master`: `REMOTE_HEAD=ff7580b38505db914247953570140d68780c145a`.
  - `dart analyze lib/ai/optimize_route_validator_support.dart routes/ai/optimize/index.dart test/optimize_route_validator_support_test.dart`: sem issues.
  - `dart test test/optimize_route_validator_support_test.dart test/optimize_route_virtual_analysis_support_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 28 testes, `All tests passed`.
  - `python3 -m py_compile battle_analyst_v9.py battle_*_support.py battle_*_tests.py test_battle_analyst_v10_3.py`: sem erro.
  - `python3 test_battle_analyst_v10_3.py`: `battle_passes=130`.
- Split local da decisão final pós-validator:
  - Criado `server/lib/ai/optimize_route_final_gate_support.dart`.
  - Criado `server/test/optimize_route_final_gate_support_test.dart`.
  - A rota `server/routes/ai/optimize/index.dart` removeu a decisão inline de
    rejeição final por quality gate, validação serializada e Semantic Layer v2.
    O retry deterministic-first continua orquestrado na rota para preservar o
    fluxo `continue optimizeAttemptLoop`, mas a decisão pura agora é testável.
  - Tamanho da rota após o corte: `2498` linhas.
  - Validação local focada:
    - `dart analyze lib/ai/optimize_route_final_gate_support.dart routes/ai/optimize/index.dart test/optimize_route_final_gate_support_test.dart`: sem issues.
    - `dart test test/optimize_route_final_gate_support_test.dart test/optimize_route_validator_support_test.dart test/optimize_route_quality_rejection_support_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart --reporter compact`: 10 testes, `All tests passed`.
- Hardening live do rebuild guiado:
  - O teste live completo de `/ai/optimize` revelou regressão real em
    `rebuild_guided`: terreno básico sintético com `card_id: ""` causava
    `22P02 invalid input syntax for type uuid`.
  - A rota `server/routes/ai/rebuild/index.dart` agora resolve identidade de cor
    do comandante via `resolveCardColorIdentity`, usando fallback por
    `mana_cost` e `oracle_text`.
  - `server/lib/ai/rebuild_guided_service.dart` agora carrega terrenos básicos
    por subtipo de `type_line` e nome canônico, cobrindo bases como
    `Island // Island`; identidade vazia completa com `Wastes`; e qualquer
    carta sem `card_id` vira `RebuildException` controlada antes de validar ou
    persistir.
  - Validação live local com `dart_frog dev -p 8082`:
    - `dart test test/ai_optimize_flow_test.dart -p vm --plain-name 'AI optimize flow | /ai/optimize rebuild_guided preview_only rebuilds Talrand as full non-commander rebuild' --reporter compact`: passou.
    - `dart test test/ai_optimize_flow_test.dart -p vm --plain-name 'AI optimize flow | /ai/optimize rebuild_guided draft_clone creates a strict-valid commander deck' --reporter compact`: passou.
    - `dart test test/ai_optimize_flow_test.dart --reporter compact`: 10 testes passaram, 1 stress matrix skipped.

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
   cortes de response/cache, envelope async, parsing inicial, payload final,
   warnings finais, diagnostics finais, fallback de sugestões vazias e payloads
   de rejeição do quality gate, validação pós-processamento e retry
   orchestration/filtro inicial de sugestões/filtro de identidade de cor/filtro
   de bracket/top-up determinístico de básicos no modo complete/proteção de
   remoção de terrenos/reequilíbrio pós-filtros/coleta EDHREC pós-processamento
   query de dados completos das adições/quality gate, análise virtual pós-swap
   execução do `OptimizationValidator` e decisão final pós-validator já foram
   feitos; o próximo corte seguro é avaliar se ainda há blocos grandes de
   orquestração que possam virar support sem esconder o fluxo principal.
3. Continuar o split de `server/lib/ai/optimize_runtime_support.dart`: os dois
   primeiros cortes moveram assinatura/cache para `optimize_cache_support.dart`
   e quality ranking/loader para `optimize_candidate_quality_support.dart`,
   mantendo wrappers/exports compatíveis.
4. Implementar efeitos card-specific de Omen/Prepare/Paradigm/Station somente
   quando houver corpus concreto usando essas cartas.
5. Revalidar drift restante entre analysis/generate/optimize depois do split
   estrutural.
