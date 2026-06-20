# Battle + Generator Implementation Slice Spec - 2026-06-17

> Status 2026-06-19: documento historico de especificacao. Use como contexto
> de implementacao, nao como prova de estado atual. Fonte viva:
> [BATTLE_VALIDATION_REGISTER_2026-06-19.md](BATTLE_VALIDATION_REGISTER_2026-06-19.md).
> Indice: [BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md](BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md).

## Objetivo

Traduzir o backlog consolidado em pontos exatos de implementação:

- arquivo;
- função/ponto de entrada;
- o que já existe;
- o que falta;
- teste mínimo necessário.

Este documento é a ponte entre:

- estudo/verdade consolidada;
- backlog priorizado;
- trabalho de código do próximo ciclo.

## Base usada

- [BATTLE_GENERATOR_TRUTH_STUDY_2026-06-17.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/BATTLE_GENERATOR_TRUTH_STUDY_2026-06-17.md)
- [BATTLE_GENERATOR_LOREHOLD_TASK_MATRIX_2026-06-17.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/BATTLE_GENERATOR_LOREHOLD_TASK_MATRIX_2026-06-17.md)
- [LOREHOLD_MIRACLE_TOPDECK_READINESS_AUDIT_2026-06-17.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/LOREHOLD_MIRACLE_TOPDECK_READINESS_AUDIT_2026-06-17.md)
- [IMPLEMENTATION_GAPS.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/IMPLEMENTATION_GAPS.md)

## Slice 1 — `decision_trace_v1` comparativo

### Arquivos

- [battle_analyst_v9.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py)
- [replay_decision_auditor.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py)
- [battle_decision_strategy_auditor.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py)
- [battle_decision_trace_tests.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_trace_tests.py)
- [test_battle_decision_strategy_auditor.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py)

### O que já existe

- `emit_decision_trace()` já aceita:
  - `available_options`
  - `chosen_option`
  - `rejected_options`
  - `score_components`
  - `expected_benefit_score`
  - `alternatives_considered`
  - `rejected_reason`
- `replay_decision_auditor.py` já valida:
  - campos obrigatórios;
  - `chosen_option` dentro de `available_options`;
  - `expected_benefit_score` numérico.
- `battle_decision_strategy_auditor.py` já interpreta:
  - `mulligan_decision`
  - `cast_spell`
  - `pass_no_action`
  - `tutor`
  - board wipe / wheel / land-cost patterns.

### O que falta

- registrar ranking comparativo das opções, não só a escolhida;
- registrar motivo por opção rejeitada, não só um `rejected_reason` genérico;
- registrar payoff esperado da rejeitada principal;
- tornar `pass_no_action` auditável quando existiam linhas jogáveis;
- amarrar as opções e a escolhida a um score comparável.

### Mudança mínima recomendada

Adicionar ao schema:

- `ranked_options`
- `chosen_option_score`
- `top_rejected_option`
- `top_rejected_option_score`
- `top_rejected_reason`
- `decision_window_has_playable_line`

Sem quebrar compatibilidade:

- manter `available_options` e `chosen_option`;
- tratar os novos campos como aditivos.

### Pontos candidatos no código

- `emit_decision_trace()` em `battle_analyst_v9.py`
- loops de cast e selection já com score:
  - ramp loop
  - high threat
  - cast spell normal
  - tutor selection
  - combat selection

### Teste mínimo necessário

- chosen score > rejected score no trace emitido;
- auditor falha se houver `decision_window_has_playable_line=true` e
  `pass_no_action` sem opção rejeitada principal;
- auditor falha se `ranked_options` não contiver a escolhida;
- teste de regressão confirmando formato antigo ainda aceito.

## Slice 2 — executor genérico de activated ability recorrente

### Arquivos

- [battle_analyst_v9.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py)
- [battle_rule_registry.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py)
- [test_battle_rule_alternatives.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_rule_alternatives.py)
- [test_reviewed_battle_card_rules.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py)

### O que já existe

- multi-rule runtime já bloqueia corretamente activated ability sem executor:
  `activated_ability_requires_executor`.
- `Ashnod's Altar` já tem metadata rastreável, mas não executa hard behavior.
- `activated_ability_skipped` já é emitido em vários pontos do runtime.

### O que falta

- executor mínimo e genérico para:
  - `activation_cost = sacrifice_creature`
  - `mana_produced`
  - `produces`
- heurística mínima para decidir quando ativar;
- rastreio no decision trace da escolha de sacrificar ou não.

### Mudança mínima recomendada

Criar capability family explícita, por exemplo:

- `battle_model_scope=activated_creature_sacrifice_mana_source_v1`

Executar apenas quando:

- há criatura sacrificável;
- o mana extra destrava spell/ability relevante no mesmo turno;
- não destrói peça de valor maior que o payoff imediato.

### Teste mínimo necessário

- `Ashnod's Altar` não gera mana ao resolver o spell;
- ativa corretamente quando sacrificar uma criatura destrava ação relevante;
- não ativa quando o custo destrói a única peça de engine sem payoff;
- replay sai de `review_rule_used` para caminho executável confiável.

## Slice 3 — multi-row real em `card_battle_rules`

### Arquivos

- [battle_analyst_v9.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py)
- [battle_rule_registry.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py)
- [test_battle_rule_alternatives.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_rule_alternatives.py)
- [auto_promote_battle_rules.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/bin/auto_promote_battle_rules.py)

### O que já existe

- seleção de primária segura;
- composição segura de subset;
- merge seguro de anotações de custo;
- block reasons explícitos;
- tests de fixture local.

### O que falta

- casos reais persistidos no PostgreSQL;
- escopo explícito por regra;
- seleção por janela/ação, não por nome.

### Mudança mínima recomendada

Persistir 3-5 cartas reais com row split verdadeiro, adicionando campos lógicos
como:

- `selection_scope`
  - `spell_resolution`
  - `activated_ability`
  - `trigger_resolution`
  - `cost_annotation`
  - `static_layer`
- `executor_family`
  - `resolution`
  - `activated`
  - `trigger`
  - `annotation`
  - `state_layer`

### Teste mínimo necessário

- auditor multi-rule passa a encontrar multi-row real no PG;
- runtime escolhe a row correta para a janela certa;
- auto-promotion continua pulando casos ambíguos não mapeados.

## Slice 4 — política explícita de precedência do builder determinístico

### Arquivos

- [commander_reference_generate_fallback_support.dart](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/lib/ai/commander_reference_generate_fallback_support.dart)
- [commander_generate_provenance_audit.dart](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/bin/commander_generate_provenance_audit.dart)
- [audit_commander_generator_source_mix.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/audit_commander_generator_source_mix.py)

### O que já existe

- ordem de inclusão real:
  `reference_card_stats -> reference_corpus_packages -> profile_expected_packages -> active_learned_deck -> usage_hot_cards -> deterministic_fallback`
- auditor de proveniência já mede source mix e buckets.

### O que falta

- transformar essa ordem de código em policy explícita de produto;
- decidir se `active_learned_deck` só preenche slots ou também reordena picks;
- eliminar drift entre docs, auditor e comportamento esperado.

### Mudança mínima recomendada

- declarar policy em doc canônico;
- expor um `precedence_policy_version` no diagnostics do builder;
- tornar o auditor sensível a violações dessa policy.

### Teste mínimo necessário

- builder diagnostics mostram a policy ativa;
- auditor falha se a ordem de inclusão mudar sem atualização de policy;
- caso Lorehold reproduz a policy documentada.

## Slice 5 — cura do fallback residual do Lorehold

### Arquivos

- [commander_reference_generate_fallback_support.dart](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/lib/ai/commander_reference_generate_fallback_support.dart)
- [audit_commander_generator_source_mix.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/audit_commander_generator_source_mix.py)
- fontes de profile/stats/corpus/usage no backend

### O que já existe

- buckets já isolados:
  - `fallback_without_profile_or_stats = 9`
  - `learned_plus_fallback_only = 2`
  - `fallback_profile_stats_no_empirical_support = 18`

### O que falta

- promover staples/interações que hoje já são óbvias, mas ainda não têm
  profile/stats;
- decidir se `Fellwar Stone` e `Lightning Greaves` viram source-backed ou
  exceção deliberada;
- revisar o bloco temático de 18 cartas sem suporte empírico forte.

### Mudança mínima recomendada

Atacar em ordem:

1. `fallback_without_profile_or_stats`
2. `learned_plus_fallback_only`
3. `fallback_profile_stats_no_empirical_support`

### Teste mínimo necessário

- rerun do provenance audit;
- rerun do source-mix audit;
- queda reproduzível dos buckets P1 sem aumentar `fallback_only`.

## Slice 6 — revalidação temática do Lorehold

### Arquivos

- [LOREHOLD_RECOMMENDED_DECK_RATIONALE_2026-06-16.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/LOREHOLD_RECOMMENDED_DECK_RATIONALE_2026-06-16.md)
- [LOREHOLD_BATTLE_MODEL_COVERAGE_MATRIX_2026-06-16.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/LOREHOLD_BATTLE_MODEL_COVERAGE_MATRIX_2026-06-16.md)
- [LOREHOLD_MIRACLE_TOPDECK_READINESS_AUDIT_2026-06-17.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/LOREHOLD_MIRACLE_TOPDECK_READINESS_AUDIT_2026-06-17.md)
- generate/optimize/battle artifacts do Lorehold

### O que já existe

- rationale de deck;
- coverage matrix;
- source mix audit;
- referências externas atuais do Lorehold em EDHREC enfatizando
  `miracle/topdeck/spellslinger`.

### O que falta

- provar que o deck final, o generator e o battle ainda convergem para esse
  plano, e não só para “big red spells”.
- fechar os gaps concretos já auditados:
  - trigger explícito de upkeep do oponente para o Lorehold;
  - regra canônica expressiva do comandante, em vez de `commander + haste`;
  - capabilities reais para `Sensei's Divining Top` / `Scroll Rack` e afins;
  - correção de `Library of Leng`, hoje ainda mal classificada no battle.

### Mudança mínima recomendada

Criar checklist de revalidação temática:

- topdeck manipulation presente e explicada;
- miracle window rastreável no battle;
- upkeep rummage do comandante presente e auditável;
- payoffs de instant/sorcery e rummage/upkeep lines coerentes;
- `Library of Leng` e peças de topo com papel coerente no runtime;
- sem dependência excessiva de bombas desconectadas do plano.

### Teste mínimo necessário

- relatório final Lorehold com veredito:
  - `trusted`
  - `needs_more_samples`
  - `blocked`

## Ordem de execução recomendada

1. Slice 1
2. Slice 2
3. Slice 4
4. Slice 5
5. Slice 6
6. Slice 3

## Motivo da ordem

- Slice 1 e 2 aumentam a qualidade do dado de batalha antes de qualquer
  interpretação forte.
- Slice 4 e 5 limpam o generator exatamente onde o Lorehold ainda depende de
  fallback residual.
- Slice 6 revalida o caso de controle depois que battle/generator melhorarem.
- Slice 3 entra no fim porque já está arquiteturalmente preparado, mas ainda
  depende mais de desenho de corpus do que de correção de bug ativo.
