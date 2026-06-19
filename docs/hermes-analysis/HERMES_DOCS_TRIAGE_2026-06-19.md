# Hermes Docs Branch Triage — 2026-06-19

> Branch avaliada: `origin/codex/hermes-analysis-docs` em `8ddc978a`.
> Base local: `master`.
> Objetivo: ler os relatórios novos gerados pelo Hermes, validar contra o
> código atual e incorporar apenas achados tecnicamente corretos.

## Decisão De Merge

Não foi feito merge bruto da branch docs para `master`.

Motivo: a branch contém centenas de artefatos e relatórios gerados
automaticamente, incluindo históricos de execuções e arquivos grandes de replay.
Eles são úteis para triagem, mas não devem virar fonte canônica sem validação por
arquivo/linha, testes e estado atual do produto.

## Docs Lidos Nesta Rodada

- `docs/hermes-analysis/STRUCTURE_AUDIT.md`
- `docs/hermes-analysis/PLANO_CORRECAO.md`
- `docs/hermes-analysis/IMPLEMENTATION_TASKS.md`
- `docs/hermes-analysis/TECHNICAL_MAP.md`
- `docs/hermes-analysis/manaloom-knowledge/TAG_ACCURACY_REPORT.md`
- `docs/hermes-analysis/manaloom-knowledge/GAMECHANGER_RESEARCH_REPORT.md`
- `docs/hermes-analysis/manaloom-knowledge/MANA_BASE_VALIDATION_REPORT.md`
- `docs/hermes-analysis/manaloom-knowledge/CRON_STATUS.md`

## Incorporado Agora

### P1 — `swap_integrity` era emitido, mas não protegia o apply

Validação:

- `server/routes/ai/optimize/index.dart` anexa `swap_integrity` na resposta de
  optimize.
- `server/lib/ai/optimize_swap_integrity.dart` define o formato canônico de hash.
- O app consumia `removals_detailed`/`additions_detailed`, mas ignorava
  `swap_integrity`.

Correção aplicada:

- `OptimizePreviewData` agora parseia `swap_integrity`.
- `requestOptimizePreview` recalcula o hash da resposta antes de liberar o
  preview/aplicação.
- `OptimizeApplyPlan` carrega `expectedDeckSignature`.
- `DeckProvider.applyOptimizationWithIds` bloqueia a mutação quando a assinatura
  atual do deck não bate com a assinatura usada na geração da sugestão.

Limite consciente:

- O app valida a integridade da resposta e o estado local carregado. Um endpoint
  backend-owned de apply ainda seria o caminho definitivo para comparar contra o
  PostgreSQL no instante exato da mutação.

### P2 — `DeckProgressChip` não possuía consumidor runtime

Validação:

- `rg` encontrou `DeckProgressChip(` apenas no construtor da própria classe.
- `DeckProgressIndicator` continua vivo e consumido em detalhes/visão geral de
  deck.

Correção aplicada:

- `DeckProgressChip` foi removido de
  `app/lib/features/decks/widgets/deck_progress_indicator.dart`.

### P2 — `LotusPresentationMode` existia, mas não era chamado

Validação:

- `LotusPresentationMode.enter/exit` não tinha call-site em `app/lib`.
- `LotusLifeCounterScreen` é o fluxo runtime vivo do contador.

Correção aplicada:

- `LotusLifeCounterScreen` chama `LotusPresentationMode.enter()` em `initState`
  e `LotusPresentationMode.exit()` em `dispose`, exceto Web.

## Válido, Mas Não Incorporado Neste Slice

### Funções/classes sem uso runtime confirmado

`DeckCard` e `LifeCounterScreen` continuam plausíveis, mas exigem decisão de
produto/teste visual antes de remoção. Não foram removidos nesta rodada porque
ainda existem suites de teste/fixtures legadas e o fluxo vivo precisa de decisão
explícita antes de apagar cobertura histórica.

### `optimize_response_support.dart` parcialmente extraído

O achado é válido como code-health: parte dos builders existe em helper, mas a
rota de optimize ainda concentra muita orquestração. Não é bug funcional
imediato e deve ser tratado em slice separado de refactor com testes de contrato.

### Tag accuracy e CMC corrompido no SQLite Hermes

O relatório de tag accuracy ainda aponta `tag_accuracy` estagnado, tags órfãs e
CMC `0.0` no `knowledge.db` Hermes. Isso é válido para a camada de laboratório,
mas não deve ser corrigido diretamente no app. O caminho correto é sync
determinístico PG/Scryfall/MTGJSON para o SQLite Hermes e validação por cron,
mantendo PostgreSQL/backend como fonte de verdade.

### Game Changers ausentes no cache Hermes

O relatório mais recente corrigiu uma metodologia antiga errada e reduziu a
lacuna real para Game Changers do produto. Permanecem gaps prováveis no cache
Hermes para Panoptic Mirror, Serra's Sanctum e Tergrid. Isso é issue de sync
Hermes/cache, não mudança imediata de política do backend.

### Decks seed incompletos em relatórios Hermes

`MANA_BASE_VALIDATION_REPORT.md` ainda lista muitos decks de simulator com
`0/100` ou seeds parciais. O dado é útil para governança de cron, mas não deve
alimentar optimize/generate. O comportamento correto permanece: crons devem
filtrar decks incompletos e reportar `INCOMPLETE`, não gerar recomendações.

## Rejeitado Ou Stale Nesta Rodada

- Claims massivas de imports quebrados: o próprio relatório informa que a
  ferramenta anterior gerava falso positivo e deve ser confrontada por
  `dart analyze`.
- `sync_cards_utils.dart` como helper test-only amplo: stale; o relatório novo
  reconhece que o CLI real chama o utilitário.
- `MLKnowledgeService.recordFeedback` sem chamada: stale; há coleta em
  `/ai/optimize` e leitura operacional em `/ai/ml-status`.
- Reabertura de Game Changer double-counting: rejeitada; a política atual é
  multi-tag intencional e já protegida por testes.
- `verifySwapIntegrity` sem uso no app: stale após `master@47411a23`; o app
  agora valida `swap_integrity` e assinatura local antes de aplicar optimize.

## Próximo Slice Recomendado

1. Criar endpoint/backend apply para optimize, validando `swap_integrity` contra
   o deck atual no PostgreSQL antes de mutar `deck_cards`.
2. Rodar slice separado de limpeza UI/fixtures para decidir remover ou religar
   `DeckCard` e `LifeCounterScreen`.
3. Corrigir o sync Hermes de `tag_accuracy`, CMC e Game Changers ausentes sem
   alterar contratos app-facing.
4. Refatorar `optimize_response_support.dart` somente com teste de contrato do
   payload de `/ai/optimize`.
