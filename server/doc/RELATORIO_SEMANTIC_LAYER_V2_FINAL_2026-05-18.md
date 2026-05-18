# Semantic Layer v2 Final - 2026-05-18

## Resultado final

PASS_WITH_RISKS.

## Consolidado

- Schema/data v2 aditivo criado com compatibilidade do envelope v1.
- Backfill dry-run e apply sanitizados executados com 72.295% de cobertura.
- Apply controlado gravou `24172` linhas em `card_semantic_tags_v2` e
  `52797` tags funcionais derivadas da v2, sem regressões agregadas.
- Optimize/generate integrados em shadow mode para evitar regressao por tags
  contextuais ainda heuristicas.
- Deck Analysis exibe explicabilidade por carta/tag com fallback legado.
- Testes/analyzers focados passaram.

## Proximos passos objetivos

1. Aguardar deploy publico do codigo v2 e provar `/analysis` + Deck Analysis
   consumindo `semantic_tags_v2` em runtime.
2. Medir delivery de swaps optimize antes/depois em corpus representativo.
3. Promover v2 de shadow para gate somente apos taxa de falsos positivos aceitavel.
