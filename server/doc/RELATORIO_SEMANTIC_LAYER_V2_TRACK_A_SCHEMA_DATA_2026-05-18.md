# Semantic Layer v2 Track A - Schema/Data - 2026-05-18

## Veredito

PASS_WITH_RISKS.

## Entrega

- Adicionado schema aditivo `card_semantic_tags_v2`, sem alterar `cards` ou contratos legados.
- Campos v2: `speed`, `mana_efficiency`, `card_advantage_type`,
  `interaction_scope`, `combo_piece`, `wincon`, `engine`, `payoff`,
  `enabler`, `protection_type`, `recursion_type`, `role_confidence` e
  `explanation_reason`.
- `functional_tags.schema_version` permanece em v1 para compatibilidade; v2 entra
  como `semantic_schema_version` e `sample_details`.
- Rotas de analysis usam fallback seguro quando `card_semantic_tags_v2` ainda nao
  existe.

## Riscos

- Heuristicas v2 seguem deterministicas; tags contextuais como `wincon` e
  `engine` precisam de auditoria humana antes de virar regra bloqueante.
