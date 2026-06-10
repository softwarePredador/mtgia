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

**Status:** em andamento, com primeira extração concluída.

**Arquivos que precisam split dedicado:**
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py` — 7869 linhas.
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py` — 3815 linhas após primeira extração.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_rules_2026_tests.py` — 304 linhas extraídas.
- `server/routes/ai/optimize/index.dart` — 3092 linhas.
- `server/lib/ai/optimize_runtime_support.dart` — 2772 linhas.

**Decisão:**
Não misturar refactors grandes com correções funcionais. A primeira extração
foi limitada às regras oficiais 2026 porque elas já formavam um domínio
fechado, com cenários próprios e sem dependência de produto mobile.

**Entregue agora:**
- Novo módulo `battle_rules_2026_tests.py` com `CONFORMANCE_SCENARIOS_2026`
  e `register_tests(...)`.
- `test_battle_analyst_v10_3.py` continua sendo o runner único, mas registra
  os testes 2026 a partir do módulo extraído.
- A saída do runner continua exibindo os testes 2026, provando que a cobertura
  não foi removida.

**Validação:**
- `python3 -m py_compile battle_rules_2026_tests.py test_battle_analyst_v10_3.py battle_analyst_v9.py`
- `python3 test_battle_analyst_v10_3.py`

## Etapa 4 — Próximas pendências reais

**Prioridade atual:**
1. Separar mais suites Hermes por domínio, priorizando combat/replacement e
   commander rules.
2. Extrair blocos da rota `routes/ai/optimize/index.dart` para support
   services mantendo a rota como orquestração fina.
3. Implementar efeitos card-specific de Omen/Prepare/Paradigm/Station somente
   quando houver corpus concreto usando essas cartas.
4. Revalidar drift restante entre analysis/generate/optimize depois do split
   estrutural.
