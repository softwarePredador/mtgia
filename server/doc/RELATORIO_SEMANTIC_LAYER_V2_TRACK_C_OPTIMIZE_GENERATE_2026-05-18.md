# Semantic Layer v2 Track C - Optimize/Generate - 2026-05-18

## Veredito

PASS_WITH_RISKS.

## Entrega

- `optimize_candidate_quality_summary` passa a expor `semantic_tags_v2` quando o
  schema v2 estiver aplicado.
- `OptimizationValidator` ganhou adapter v2 -> roles legados, preservando o
  pipeline existente.
- Optimize usa v2 em shadow mode no texto/sinais de ranking quando a fonte
  `deterministic_semantic_v2` aparecer; os quality gates legados continuam
  soberanos.
- `/ai/generate` adiciona `semantic_layer_v2` opcional com cobertura/contagens em
  shadow mode, sem quebrar Commander Reference.

## Riscos

- Nao foi habilitada rejeicao dura baseada exclusivamente em v2 para evitar
  regressao de optimize por falsos positivos contextuais.
