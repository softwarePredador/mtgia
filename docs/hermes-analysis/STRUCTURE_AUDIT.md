# ManaLoom Code Structure Audit
> Atualizacao Copilot: 2026-05-29 12:10 UTC
> Commit verificado: `origin/master@2396956e`

## Revalidacao pos-correcao: `sync_cards_utils.dart` ligado ao sync operacional

O Copilot cruzou o achado de helper testado sem chamador runtime contra a
`master` real e aplicou correcao segura em `origin/master@2396956e`.

### Resolvido em `origin/master@2396956e`

- `server/bin/sync_cards.dart` agora importa `server/lib/sync_cards_utils.dart`.
- O CLI operacional passou a usar `parseSinceDays`,
  `getNewSetCodesSinceFromData`, `extractCardRow`, `extractSetCardRow`,
  `extractOracleIds` e `extractLegalities`.
- As copias privadas `_parseSinceDays`, `_getNewSetCodesSinceFromData` e
  `_extractCardRow` foram removidas do binario.
- Os loops inline de rows incrementais, oracle IDs e legalidades foram
  substituidos pelos helpers compartilhados.
- `extractSetCardRow` foi alinhado ao prepared statement real de sync
  incremental e agora retorna tambem `collector_number` e `foil`.

### Validacao executada

- `dart format lib/sync_cards_utils.dart bin/sync_cards.dart test/sync_cards_test.dart`
- `dart analyze lib/sync_cards_utils.dart bin/sync_cards.dart test/sync_cards_test.dart`
- `dart test test/sync_cards_test.dart -r expanded`
- `dart analyze bin lib routes test`
- `dart test` em `server/`: 610 testes passaram.
- `git diff --check`
- Scan simples de segredos no diff/stage.
- Hermes post-push smoke para `2396956e`: `PASS`.

### Observacoes

- Esta rodada nao executou o sync MTGJSON real contra banco. A alteracao foi
  limitada a religar o caminho operacional aos helpers ja testados e preservar o
  contrato SQL existente.
- Permanecem abertos os outros helpers publicos sem chamador runtime listados
  nesta auditoria (`request_trace`, Commander Reference, PerformanceService,
  MTGTop8 e candidate quality sample SQL).

> Atualizacao Copilot: 2026-05-29 11:56 UTC
> Commit verificado: `origin/master@640f4ab4`

## Revalidacao pos-correcao: imports app e ciclo Community/Social

O Copilot cruzou os achados desta rodada contra a `master` real e aplicou
correcao segura em `origin/master@640f4ab4`.

### Resolvido em `origin/master@640f4ab4`

- `app/lib/features/decks/widgets/deck_analysis_tab.dart` e
  `app/lib/features/home/life_counter_screen.dart` agora importam
  `AppTheme`/`ManaHelper` via `package:manaloom/...`, removendo dependencia de
  profundidade relativa fragil.
- `CommunityDeckDetailScreen` nao importa mais `UserProfileScreen`; navega para
  `/community/user/:userId` via `GoRouter`.
- `UserProfileScreen` nao importa mais `CommunityDeckDetailScreen`; navega para
  `/community/decks/:deckId` via `GoRouter`.
- `app/lib/main.dart` registrou a rota `/community/decks/:deckId`.

### Validacao executada

- `flutter analyze lib/main.dart lib/features/decks/widgets/deck_analysis_tab.dart lib/features/home/life_counter_screen.dart lib/features/community/screens/community_deck_detail_screen.dart lib/features/social/screens/user_profile_screen.dart --no-version-check`
- `flutter analyze lib test --no-version-check`
- Grafo local de imports em `app/lib`: `SCCS 0`
- `flutter test test/features/community/providers/community_provider_test.dart test/features/community/providers/social_provider_test.dart test/features/home/life_counter_screen_test.dart --no-version-check --reporter compact`
- `git diff --check`
- Hermes post-push smoke para `640f4ab4`: `PASS`

### Observacoes

- `server/bin/local_test_server.dart` passou em `dart analyze` no workspace
  principal porque `server/.dart_frog/server.dart` existe localmente como
  artefato gerado. No clone limpo do Hermes, esse arquivo pode continuar
  ausente; tratar como risco de ambiente/fluxo local, nao como bug confirmado de
  produto runtime.
- A rodada mista com `home_screen_test.dart` falhou por expectativa preexistente
  (`Gerar com IA` ausente) e golden longa; ela nao foi usada como gate desta
  correcao. Os testes diretamente afetados passaram.

> Atualizacao: 2026-05-29 11:00 UTC
> Rotacao local Codex: `broken-imports-and-circular-dependencies`

## Rodada focada: Broken imports and circular dependencies

Escopo desta rodada: somente imports quebrados e ciclos de dependencias locais.
Nao foi executada auditoria ampla de classes, funcoes, tabelas PostgreSQL,
duplicacao geral ou coerencia funcional entre camadas.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativa.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo no inicio da rodada; depois o auditor base
  atualizou este arquivo.
- `git rev-parse --short HEAD`: `ba3b74ad`.
- `rg` nao esta instalado neste shell local; buscas focadas usaram
  `grep -RIn`, `find` e um resolvedor local somente leitura para diretivas Dart.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 174.
- Imports quebrados no recorte `server/lib` + `server/routes`: 0.

Limitacao para esta rotacao: o auditor base nao cobre `server/bin`, `app/lib`,
`app/test` ou `app/integration_test`, e tambem nao calcula ciclos de imports.
Por isso a triagem focada montou um grafo de imports locais para 721 arquivos
Dart em `server/` e `app/`, resolvendo `package:server/...`,
`package:manaloom/...`, alias historico `package:ai/...` e imports relativos a
partir do arquivo origem.

Validação adicional:

- `dart analyze` em `server/` confirmou 1 erro de import:
  `bin/local_test_server.dart:3:8 - Target of URI doesn't exist:
  '../.dart_frog/server.dart'`.
- `flutter analyze --no-pub --no-fatal-infos` em `app/` nao foi conclusivo para
  estes achados porque `app/.dart_tool/package_config.json` nao existe neste
  checkout; o analyzer reportou dezenas de milhares de erros de pacote ausente
  (`package:flutter`, `package:manaloom`, `package:flutter_lints`, etc.) antes
  de uma leitura util dos imports locais.

### Achados confirmados

#### P1 — Dois imports relativos em `app/lib` apontam para `app/core`, que nao existe

- **Imports quebrados:**
  - `app/lib/features/decks/widgets/deck_analysis_tab.dart:5` importa
    `../../../../core/utils/mana_helper.dart`.
  - `app/lib/features/home/life_counter_screen.dart:7` importa
    `../../../core/theme/app_theme.dart`.
- **Evidencia filesystem:** os arquivos reais existem em
  `app/lib/core/utils/mana_helper.dart` e `app/lib/core/theme/app_theme.dart`.
  Resolvidos a partir dos arquivos origem, os imports atuais apontam para
  `app/core/utils/mana_helper.dart` e `app/core/theme/app_theme.dart`, que nao
  existem.
- **Por que parece quebrado:** a profundidade relativa esta um nivel acima do
  necessario. Em `deck_analysis_tab.dart`, outros imports core vizinhos usam
  `../../../core/...`; em `life_counter_screen.dart`, o arquivo esta em
  `app/lib/features/home/`, entao `../../../core/...` tambem sobe ate `app/`,
  nao ate `app/lib/`.
- **Impacto:** qualquer build/analyze com package config valido deve falhar ao
  resolver esses arquivos, ou entao esses arquivos ficam fora do grafo efetivo
  de compilacao se nao forem atingidos.
- **O que valida:** corrigir os imports para alvos sob `app/lib/core/...` e
  rerodar `flutter analyze` depois de recriar `app/.dart_tool/package_config.json`
  com `flutter pub get`.
- **O que falsifica:** provar que estes arquivos nao entram mais no produto e
  remove-los/retira-los do grafo, ou demonstrar outro mecanismo de resolucao que
  faca `app/core/...` existir no ambiente de build.

#### P1 — `server/bin/local_test_server.dart` importa artefato Dart Frog ausente

- **Import quebrado:** `server/bin/local_test_server.dart:3` importa
  `../.dart_frog/server.dart`.
- **Evidencia:** `dart analyze` em `server/` falhou com
  `uri_does_not_exist` exatamente nesse import. `ls server/.dart_frog` nao
  encontrou o diretorio no checkout atual.
- **Por que parece quebrado:** o binario depende de um artefato gerado pelo Dart
  Frog, mas o artefato nao esta versionado nem presente localmente.
- **Impacto:** o backend nao fica analisavel com `dart analyze` puro enquanto o
  arquivo existir nesse estado; isso reduz a confianca de checks locais e ja
  aparece como risco recorrente em `PLANO_CORRECAO.md`.
- **O que valida:** documentar/automatizar a geracao de `.dart_frog/server.dart`
  antes do analyze, ou trocar o entrypoint por um caminho resiliente que nao
  exija artefato ausente.
- **O que falsifica:** remover o binario se ele for legado, ou provar que o
  fluxo oficial de analyze sempre gera `.dart_frog/server.dart` antes da
  verificacao.

#### P2 — Ciclo direto entre detalhe de deck comunitario e perfil social

- **Ciclo confirmado:**
  - `app/lib/features/community/screens/community_deck_detail_screen.dart:8`
    importa `../../social/screens/user_profile_screen.dart`.
  - `app/lib/features/social/screens/user_profile_screen.dart:7` importa
    `../../community/screens/community_deck_detail_screen.dart`.
- **Chamadas que fecham o ciclo:**
  - `community_deck_detail_screen.dart:213` navega para
    `UserProfileScreen(userId: deck['owner_id'] as String)`.
  - `user_profile_screen.dart:469` navega para
    `CommunityDeckDetailScreen(deckId: deck.id)`.
- **Evidencia do grafo:** a triagem de 721 arquivos Dart encontrou 1 unico SCC
  com mais de um arquivo, composto exatamente por essas duas telas; nao foram
  encontrados ciclos locais em `server/lib`, `server/routes` ou `server/bin`.
- **Por que importa:** telas de dominios diferentes (`community` e `social`)
  conhecem as classes concretas uma da outra. Mesmo que Dart aceite ciclos de
  import em alguns cenarios, isso dificulta recorte, testes isolados e evolucao
  de rotas/navegacao.
- **O que valida:** mover a navegacao cruzada para rotas nomeadas/GoRouter, um
  callback de navegacao injetado, ou um helper de navegacao fora dos dois
  dominios, e rerodar o grafo local mostrando `SCCS 0`.
- **O que falsifica:** demonstrar que um dos imports nao e mais necessario no
  runtime ou que a tela foi retirada do fluxo app-facing.

### Itens verificados e nao classificados como problema

- O auditor estrutural base continua reportando `Imports quebrados: 0` para
  `server/lib` e `server/routes`; os achados acima estao fora desse recorte.
- O resolvedor focado nao encontrou outros imports/exports/parts locais
  quebrados em `server/` e `app/` alem dos 3 listados.
- O grafo focado nao encontrou ciclos de imports locais no backend.

## Rodada focada: Functions not called

Escopo desta rodada: somente funcoes aparentemente nao chamadas ou chamadas
apenas por testes/harnesses fora do fluxo runtime. Nao foi executada auditoria
ampla de classes, imports/ciclos, tabelas PostgreSQL, duplicacao geral ou
coerencia entre camadas.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativo.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo no inicio da rodada.
- `git rev-parse --short HEAD`: `e5de80fd`.
- `rg` nao esta instalado neste shell local; buscas focadas usaram
  `grep -RIn --include='*.dart' --include='*.md'`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 174.
- Imports quebrados: 0.

Limitacao para esta rotacao: o auditor lista apenas "Funcoes Publicas
(primeiros 5 por arquivo)" e "Funcoes com nomes duplicados"; ele nao prova
chamadores. A triagem abaixo usou busca textual de simbolos e manteve apenas
casos em que o nome aparece so na propria definicao, em testes, ou em scripts
operacionais fora do runtime app/API.

### Achados confirmados

#### P1 — `sync_cards_utils.dart` estava testado, mas nao era chamado pelo sync real

**Status 2026-05-29: RESOLVIDO em `origin/master@2396956e`.**

- **Funcoes:** `extractCardRow`, `parseSinceDays`, `extractSetCardRow`,
  `extractOracleIds` e `extractLegalities`.
- **Correcao aplicada:** `server/bin/sync_cards.dart` agora importa
  `sync_cards_utils.dart` e usa esses helpers no full sync, sync incremental,
  selecao de sets, oracle IDs e legalidades. O helper `extractSetCardRow` foi
  expandido para devolver `collector_number` e `foil`, mantendo compatibilidade
  com o INSERT incremental de 12 colunas.
- **Validacao:** `dart analyze bin lib routes test` e `dart test` em `server/`
  passaram; `test/sync_cards_test.dart` foi ampliado para o shape incremental
  real.

Historico do achado:

- **Definicoes:** `server/lib/sync_cards_utils.dart:16`, `:102`, `:116`,
  `:161` e `:172`.
- **Evidencia de nao chamada no runtime:** `grep -RIn --include='*.dart'
  "sync_cards_utils" server` encontrou apenas
  `server/test/sync_cards_test.dart:3`; nenhum `server/bin/*.dart`,
  `server/lib/*.dart` ou rota importa esse arquivo.
- **Comparacao com o sync ativo:** `server/bin/sync_cards.dart` importa
  `mtg_data_integrity_support.dart`, mas nao `sync_cards_utils.dart`; ele mantem
  implementacoes privadas equivalentes em `server/bin/sync_cards.dart:376`
  (`_parseSinceDays`), `:680` (`_extractCardRow`) e loops inline para oracle IDs
  e legalidades em `:806`-`:838`. O bloco incremental de carta tambem monta rows
  inline em `:604`-`:663`, em vez de chamar `extractSetCardRow`.
- **Por que parece nao chamada:** as buscas por simbolo mostram os helpers
  publicos usados somente por `server/test/sync_cards_test.dart`; o binario que
  roda o sync operacional usa codigo privado no proprio arquivo.
- **Risco:** os testes podem estar validando uma copia morta da logica, enquanto
  mudancas no sync real passam sem exercitar os helpers testados. Isso tambem
  preserva duplicacao entre a promessa do comentario de `sync_cards_utils.dart`
  ("extraidas do sync_cards.dart") e o estado real do CLI.
- **O que valida:** importar `sync_cards_utils.dart` em
  `server/bin/sync_cards.dart` e substituir as copias privadas/loops inline por
  esses helpers, mantendo `server/test/sync_cards_test.dart` como cobertura
  direta do caminho operacional.
- **O que falsifica:** remover `sync_cards_utils.dart` e seus testes como
  harness legado, ou provar outro entrypoint operacional que o importe.

#### P2 — Wrapper de request trace existe, mas os chamadores usam `context.read<RequestTrace>()` direto

- **Funcoes:** `getRequestTrace` e `tryGetRequestId`.
- **Definicoes:** `server/lib/request_trace.dart:48` e
  `server/lib/request_trace.dart:51`.
- **Evidencia:** `grep -RIn --include='*.dart' "\btryGetRequestId\b" server app`
  encontrou apenas a propria definicao. `getRequestTrace` aparece apenas na
  definicao e dentro de `tryGetRequestId`. Em contraste, rotas e middlewares
  acessam `RequestTrace` diretamente, por exemplo
  `server/routes/_middleware.dart:29` cria o trace,
  `server/routes/_middleware.dart:64` injeta o provider,
  `server/routes/trades/index.dart:332` e
  `server/routes/conversations/[id]/messages.dart:249` leem
  `context.read<RequestTrace>().requestId`.
- **Por que parece nao chamada:** nao ha chamador runtime nem teste direto para
  `tryGetRequestId`; o wrapper `getRequestTrace` so existe para alimentar esse
  helper sem uso.
- **O que valida:** trocar rotas/helpers que fazem acesso direto por
  `getRequestTrace`/`tryGetRequestId` quando o fallback for intencional.
- **O que falsifica:** remover os wrappers e manter o contrato atual de acesso
  direto, ou adicionar chamador real coberto por teste.

#### P2 — `normalizedCommanderReferenceCandidate` nao tem chamador

- **Funcao:** `normalizedCommanderReferenceCandidate`.
- **Definicao:** `server/lib/ai/commander_reference_profile_support.dart:49`.
- **Evidencia:** `grep -RIn --include='*.dart'
  "\bnormalizedCommanderReferenceCandidate\b" server/lib server/routes
  server/bin server/test` encontrou apenas a propria definicao. O codigo ativo
  usa `normalizeCommanderReferenceName` diretamente em
  `server/lib/ai/commander_reference_card_stats_support.dart:308`, `:559`,
  `:717`, `server/lib/ai/commander_reference_readiness_support.dart:304` e
  `server/routes/ai/generate/index.dart:581`.
- **Por que parece nao chamada:** a funcao nullable parece ser um wrapper
  residual de normalizacao, mas os consumidores fazem normalizacao direta.
- **O que valida:** substituir consumidores que precisam de retorno nullable
  por esse wrapper e adicionar teste.
- **O que falsifica:** apagar o wrapper e manter `normalizeCommanderReferenceName`
  como API unica.

#### P2 — Parte da API customizada de `PerformanceService` nao e chamada pelo app

- **Funcoes/metodos:** `startTrace`, `stopTrace`, `addMetric`,
  `addAttribute`, `getLocalStats` e `printLocalStats`.
- **Definicoes:** `app/lib/core/services/performance_service.dart:110`,
  `:130`, `:200`, `:210`, `:220` e `:248`.
- **Evidencia:** `grep -RIn --include='*.dart'
  "\bPerformanceService\b\|\bstartTrace\b\|\bstopTrace\b\|\baddMetric\b\|\baddAttribute\b\|\bprintLocalStats\b\|\bgetLocalStats\b"
  app/lib app/test app/integration_test` encontrou inicializacao em
  `app/lib/main.dart:121`, uso de `traceAsync` no smoke
  `app/integration_test/release_observability_smoke_test.dart:51` e o
  `PerformanceNavigatorObserver`, mas nao encontrou chamadas runtime para os
  metodos customizados listados alem das proprias definicoes. `getLocalStats`
  so e chamado por `printLocalStats`, que tambem nao tem chamador externo.
- **Por que parece nao chamada:** a observabilidade ativa usa `init`,
  `traceAsync` e o observer de navegacao; a API manual de traces/metricas parece
  ter ficado como superficie planejada ou legado de debug.
- **Risco:** baixo/medio. Nao afeta fluxo de produto diretamente, mas aumenta a
  superficie de observabilidade aparente e pode sugerir que metricas customizadas
  estao instrumentadas quando nao estao.
- **O que valida:** instrumentar chamadas reais para operacoes criticas
  (`fetch_decks`, optimize, import, etc.) usando esses metodos, ou adicionar
  testes/smokes que provem consumo.
- **O que falsifica:** remover os metodos manuais e manter `traceAsync`/observer
  como contrato unico de performance.

#### P2 — `extractMtgTop8FormatCodeFromSourceUrl` e test-only no checkout atual

- **Funcao:** `extractMtgTop8FormatCodeFromSourceUrl`.
- **Definicao:** `server/lib/meta/mtgtop8_meta_support.dart:139`.
- **Evidencia:** `grep -RIn --include='*.dart'
  "\bextractMtgTop8FormatCodeFromSourceUrl\b" .` encontrou somente
  `server/test/mtgtop8_meta_support_test.dart:147` e a definicao. A funcao
  vizinha `extractMtgTop8EventIdFromSourceUrl` e usada pelo reparo operacional
  em `server/bin/repair_mtgtop8_meta_history.dart:59`, mas o format code nao e
  consumido.
- **Por que parece nao chamada:** o helper de formato foi mantido junto do
  helper de event id, mas o pipeline atual nao usa o parametro `f` extraido da
  URL.
- **O que valida:** usar o helper no reparo/import/promocao quando o formato da
  URL for parte do contrato.
- **O que falsifica:** remover o helper e o teste, se o formato for derivado de
  outra fonte mais confiavel.

#### P2 — `buildCandidateQualitySamplePoolSql` so e exercitado por teste

- **Funcao:** `buildCandidateQualitySamplePoolSql`.
- **Definicao:** `server/lib/ai/candidate_quality_data_support.dart:631`.
- **Evidencia:** `grep -RIn --include='*.dart'
  "\bbuildCandidateQualitySamplePoolSql\b" server/bin server/lib server/routes
  server/test` encontrou apenas
  `server/test/candidate_quality_data_support_test.dart:123` e a definicao. O
  runner operacional `server/bin/candidate_quality_data_foundation.dart` importa
  `candidate_quality_data_support.dart`, mas monta seus pools via
  `_loadCandidateCards`, `_buildSampleCandidatePools` e SQL proprio; a busca por
  `optimize_candidate_quality_summary cqs` aparece somente no builder sem uso.
- **Por que parece nao chamada:** o SQL builder pode ser resquicio de uma
  amostragem anterior; hoje nao ha rota, lib runtime ou binario que execute a
  string retornada.
- **O que valida:** chamar esse builder a partir do runner/scorecard que precisa
  da amostra, com teste de integracao ou dry-run.
- **O que falsifica:** remover o builder e seu teste se a amostragem atual for
  responsabilidade definitiva de `candidate_quality_data_foundation.dart`.

### Itens verificados e nao classificados como problema

- `auditCommanderReferenceTables`, `ensureCommanderReferenceProfileTable`,
  `ensureCommanderReferenceCardStatsTable`, `ensureCardLocalizedNamesTable`,
  `decodeExternalCommanderMetaArtifact`, `isCommanderCandidateLegalityAllowed`,
  `loadExistingMetaDeckFingerprints` e `metaDeckAnalyticsFormatKey` aparecem com
  baixa contagem em `server/lib`, mas tem chamadores em `server/bin`; foram
  classificados como suporte operacional, nao como funcoes mortas.
- Funcoes top-level em rotas Dart Frog chamadas por convencao (`onRequest`) nao
  foram auditadas como "nao chamadas".

## Rodada focada: Card semantics audit

Escopo desta rodada: hardcoded card names em runtime, drift entre
`functional_tags`, `semantic_tags_v2` e classificacao funcional do optimize, e
pontos onde utilidade ainda e inferida por nome em vez de texto/tipo/custo/dados
semanticos persistidos.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativo.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo no inicio da rodada.
- `git rev-parse --short HEAD`: `7014a2cc`.
- `rg` nao esta instalado neste shell local; buscas focadas usaram
  `grep -RIn` em `server/lib`, `server/routes` e `app/lib`.

### Achados confirmados

#### P1 — Excecoes por nome ainda entram na classificacao semantica de runtime

- **Fluxo:** `inferFunctionalCardTags`, `inferSemanticCardAnalysisV2` e
  `inferCandidateFunctionTags`.
- **Evidencia:**
  - `server/lib/ai/functional_card_tags.dart:220`-`:226` classifica ramp por
    `normalizedName.contains('signet')`, `normalizedName.contains('talisman')`,
    `normalizedName == 'sol ring'` e `normalizedName == 'arcane signet'`.
  - `server/lib/ai/functional_card_tags.dart:714`-`:717`, `:754`-`:780`,
    `:823`-`:851` e `:859`-`:899` usam nomes como `Teferi's Protection`,
    `Heroic Intervention`, `Swiftfoot Boots`, `Lightning Greaves`,
    `Blood Artist`, `Ephemerate`, `Jeska's Will`, `Thassa's Oracle`,
    `Isochron Scepter` e `Dramatic Reversal` para protecao, aristocrats,
    blink, ritual, wincon, combo, payoff e enabler.
  - `server/lib/ai/candidate_quality_data_support.dart:375`-`:379`,
    `:421`-`:428`, `:439`-`:445`, `:472`-`:478`, `:590`-`:605` e
    `:611`-`:628` repetem parte dessas excecoes e ainda aplicam
    `highPowerNames`/`premium` para bracket e score.
- **Classificacao:** **Risk**. Estes sao caminhos de runtime que afetam analise,
  candidate quality e optimize; nao sao fixtures, docs ou corpus. Algumas
  cartas podem merecer excecao conhecida, mas no checkout local elas nao estao
  versionadas como policy nem ligadas a dados persistidos com motivo/fonte.
- **Por que importa:** uma carta pode ganhar papel funcional por nome mesmo que
  `oracle_text`, `type_line`, `mana_cost`, `cmc` ou `semantic_tags_v2`
  persistidos nao justifiquem o papel; isso tambem torna o comportamento dificil
  de auditar quando Oracle muda ou quando uma carta com texto equivalente nao
  esta na lista.
- **O que valida:** testes que comparem cartas com texto equivalente e nomes
  diferentes, alem de teste de policy versionada para cada excecao realmente
  intencional.
- **O que falsifica:** mover essas excecoes para dados semanticos persistidos ou
  policy versionada com `role`, `reason`, `source`, `bracket` e testes que
  provem que o fallback por texto continua suficiente para cartas equivalentes.
- **Correcao recomendada:** manter heuristicas por `oracle_text`/`type_line`
  como fonte principal, backfillar excecoes reais em `card_semantic_tags_v2` ou
  policy versionada, e remover checks inline de nome dos classificadores puros.

#### P1 — Optimize ainda possui listas fixas de staples/fillers que influenciam score e selecao

- **Fluxo:** mana base, complete/filler, fallback universal e fallback
  contextual do optimize.
- **Evidencia:**
  - `server/lib/ai/optimize_runtime_support.dart:406`-`:454` define
    `premiumLandNames` e soma `+250` para terrenos como `Command Tower`,
    `City of Brass`, `Exotic Orchard`, `Mana Confluence`, `Path of Ancestry` e
    `Reflecting Pool`.
  - `server/lib/ai/optimize_runtime_support.dart:1296`-`:1345` consulta uma
    lista fixa de staples quando o pool inicial tem menos candidatos.
  - `server/lib/ai/optimize_runtime_support.dart:1948`-`:1995` define
    `_weakCommanderFillerDenylist` e `_premiumCommanderFillerNames`; `:2033`-`:2052`
    aplica bonus de score para nomes premium.
  - `server/lib/ai/optimize_runtime_support.dart:3476`-`:3509` e `:3565`-`:3615`
    carregam fallbacks universais/contextuais por nomes fixos antes de ordenar
    por legalidade/meta.
  - Busca local encontrou apenas `server/lib/edh_bracket_policy.dart` como
    modulo `*policy*`; o `commander_fallback_policy.dart` citado em anotacoes
    historicas nao existe neste checkout.
- **Classificacao:** **Risk**. A selecao ainda consulta banco/legality/color
  identity, mas a prioridade inicial e o bonus de utilidade sao por nome.
- **Por que importa:** a promessa operacional de `functional_tags_then_semantic_v2_then_heuristic`
  nao se sustenta nesses caminhos; staples nomeadas podem superar cartas mais
  adequadas por oracle/role/custo/semantic score.
- **O que valida:** extrair as listas para policy versionada ou tabela de seed
  com fonte e motivo, e testes que provem que legalidade, identidade de cor,
  bracket, budget e role semantic continuam bloqueando sugestoes inadequadas.
- **O que falsifica:** se essas listas forem apenas corpus/benchmark inerte;
  nesta leitura elas sao usadas por score/selecao runtime, entao nao sao inertes.
- **Correcao recomendada:** centralizar os nomes em policy versionada
  (`commander_fallback_policy` ou tabela), registrar `source/reason`, e preferir
  `semantic_tags_v2`, `card_role_scores`, `card_function_tags`, meta usage,
  `oracle_text`, `type_line`, `mana_cost` e `cmc` no score final.

#### P1 — Deck analysis usa `card_function_tags`, mas optimize/validator nao carrega esse sinal

- **Fluxos comparados:** `summarizeFunctionalTagsForDeck`,
  `loadOptimizeDeckContext`, `classifyOptimizationFunctionalRole`,
  `OptimizationValidator` e `filterUnsafeOptimizeSwapsByCardData`.
- **Evidencia:**
  - `server/routes/decks/[id]/analysis/index.dart:80`-`:96` e
    `server/routes/decks/[id]/ai-analysis/index.dart:119`-`:135` selecionam
    `card_function_tags` e `semantic_tags_v2`.
  - `server/lib/ai/functional_card_tags.dart:432`-`:465` prefere
    `functional_tags` persistidos e so cai para heuristica quando nao ha tag
    persistida; `:551`-`:607` le `semantic_tags_v2` para detalhes/explicacao.
  - `server/lib/ai/optimize_request_support.dart:86`-`:105`, `:186`-`:198` e
    `:323`-`:339` carregam `semantic_tags_v2`, mas nao carregam
    `card_function_tags`/`functional_tags` para `allCardData`.
  - `server/lib/ai/optimization_functional_roles.dart:55`-`:58` usa
    `semantic_tags_v2` primeiro, depois cai para `type_line`/`oracle_text`
    (`:60`-`:124`); nao ha leitura de `functional_tags`.
  - `server/lib/ai/optimization_validator.dart:265`-`:267` e
    `server/lib/ai/optimization_quality_gate.dart:52`-`:53` chamam
    `classifyOptimizationFunctionalRole`, portanto herdam essa ausencia.
- **Classificacao:** **Risk / semantic drift**.
- **Por que importa:** uma carta pode aparecer corretamente como `draw`,
  `ramp`, `removal`, `engine`, `payoff` etc. na aba de analise por causa de
  `card_function_tags`, mas o optimize/quality gate pode ignorar esse dado se
  `semantic_tags_v2` estiver ausente/abaixo de confianca e recair em heuristica.
- **O que valida:** teste end-to-end com carta contendo `functional_tags`
  persistido e `semantic_tags_v2` ausente provando que deck analysis e optimize
  classificam o mesmo papel.
- **O que falsifica:** `loadOptimizeDeckContext` e as queries de additions
  passarem a carregar `functional_tags`, e `classifyOptimizationFunctionalRole`
  aplicar a mesma prioridade documentada: `functional_tags` persistidos,
  depois `semantic_tags_v2`, depois heuristica por oracle/tipo/custo.
- **Correcao recomendada:** criar um adapter unico de role funcional que aceite
  `functional_tags`, `semantic_tags_v2`, `oracle_text`, `type_line`,
  `mana_cost` e `cmc`, e usar esse adapter em deck analysis, quality gate,
  validator e candidate quality.

#### P1 — `semantic_tags_v2` multi-tag e colapsado em um unico papel no optimize

- **Fluxo:** `classifyOptimizationFunctionalRole` e diagnostico v2 do optimize.
- **Evidencia:**
  - `server/lib/ai/optimization_functional_roles.dart:127`-`:180` escolhe uma
    unica entrada de maior `role_confidence` e retorna o primeiro papel conforme
    ordem fixa: `board_wipe`, `draw`, `removal`, `ramp`, `tutor`, `protection`,
    `recursion`, `wincon`, `combo_piece`, e so depois flags `engine`, `payoff`,
    `enabler`.
  - `server/lib/ai/optimization_functional_roles.dart:292`-`:323` calcula
    `role_delta` usando somente esse papel unico para cada remocao/adicao.
  - `server/lib/ai/candidate_quality_data_support.dart:290`-`:309` usa outro
    mapa de colapso (`drain -> wincon`, `lifegain -> protection`,
    `exile_value -> draw`, `token_maker -> token`, etc.), criando outro eixo de
    interpretacao para o mesmo conjunto de tags.
- **Classificacao:** **Risk / semantic drift**.
- **Por que importa:** uma carta com tags `draw + engine`, `combo_piece +
  enabler`, ou `aristocrat_payoff + drain + payoff` pode preservar uma funcao
  importante, mas o optimize so enxerga o primeiro papel escolhido pela ordem
  local. Isso reduz a fidelidade do validator e da decisao `role_delta`.
- **O que valida:** testes com `semantic_tags_v2.tags` contendo multiplos papeis
  que exercitem validator, quality gate e candidate quality, verificando que
  papeis secundarios relevantes nao somem.
- **O que falsifica:** `role_delta` passar a operar sobre conjunto de roles por
  carta, com roles criticos e secundarios ponderados, e candidate quality usar o
  mesmo adapter.
- **Correcao recomendada:** substituir retorno escalar por `Set<String>`/objeto
  de roles preservados, mantendo um `primary_role` apenas para compatibilidade
  de resposta.

#### P2 — Rotas de recomendacao ainda retornam nomes fixos por metrica simples

- **Fluxos:** `/decks/:id/recommendations` e `/ai/weakness-analysis`.
- **Evidencia:**
  - `server/routes/decks/[id]/recommendations/index.dart:262`-`:268` recomenda
    `Command Tower` quando `landCount < 34`, sem passar por busca semantica de
    terrenos/fixing.
  - A mesma rota busca categorias por `oraclePatterns` em `:244`-`:253` e
    staples por raridade em `:408`-`:438`; isso e melhor que lista fixa, mas
    ainda nao usa `semantic_tags_v2`/`card_function_tags`.
  - `server/routes/ai/weakness-analysis/index.dart:206`-`:285` retorna listas
    fixas de nomes para ramp, draw, removal, wipes e protecao; `:345`-`:358`
    tambem recomenda texto com `Swords to Plowshares`.
- **Classificacao:** **Risk** para logica runtime; nao e fixture nem doc.
- **Por que importa:** utilidade e inferida de buckets agregados e nomes
  genericos, sem garantir que a carta recomendada respeita identidade de cor,
  budget/bracket, legalidade, tema, cartas ja presentes ou dados persistidos.
- **O que valida:** testes de recomendacao com decks de identidades diferentes
  provando que sugestoes fixas off-color/fora de bracket nao aparecem.
- **O que falsifica:** trocar listas fixas por consulta a `cards` +
  `card_legalities` + `card_function_tags`/`semantic_tags_v2`/`card_role_scores`
  com filtros de identidade, budget, bracket e exclusao de cartas ja presentes.
- **Correcao recomendada:** manter mensagens genericas, mas gerar nomes por
  consulta semantica versionada em vez de literals inline.

### Candidatos permitidos ou intencionais

- **Allowed — UI/example/route comment:** exemplos como `1 Sol Ring` em
  `app/lib/features/decks/screens/deck_import_screen.dart:383`-`:392` e
  `:591`-`:592`, comentarios de `server/routes/cards/resolve/batch/index.dart`
  e mensagens de importacao sao exemplos de formato, nao decisao funcional.
- **Allowed — card search suggestion UI:** `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:39`-`:44`
  e lista de busca rapida; nao participa de optimize, validator ou analise.
- **Allowed — prompt example, with caution:** `server/lib/ai/prompt.md` e
  `server/lib/ai/prompt_complete.md` contem nomes como exemplos para o modelo.
  Eles influenciam prompt, mas nao sao gate deterministico; devem continuar fora
  da fonte de verdade de classificacao.
- **Allowed — localized alias:** `server/lib/import_card_lookup_service.dart:26`
  mapeia alias PT para `Swords to Plowshares`; isso e resolucao de nome
  localizado, nao julgamento de utilidade.
- **Intentional exception / seed data:** `server/lib/ai/commander_reference_profile_support.dart:153`-`:171`
  e `server/lib/ai/commander_reference_generate_fallback_support.dart:182`-`:245`
  embutem pacotes Lorehold/fallback. Ha cobertura relacionada em
  `server/test/commander_reference_card_stats_support_test.dart`, entao isto se
  comporta como seed/corpus de perfil Commander, nao como regra generica de
  optimize. Ainda assim, se esse fallback crescer, deve virar corpus/policy
  versionada para manter fonte, bracket e motivo auditaveis.

### Resumo da checagem pedida

- `semantic_tags_v2` e usado antes de heuristica no optimize quando esta
  presente (`classifyOptimizationFunctionalRole`), mas `functional_tags`
  persistidos nao entram no optimize.
- `summarizeFunctionalTagsForDeck` prefere `functional_tags` persistidos e
  usa heuristica depois; isso diverge do optimize.
- Candidate quality reaproveita `inferFunctionalCardTags`, mas adiciona aliases,
  `premium` e `highPowerNames` por nome, criando drift de role/bracket.
- Ha utilidade ainda name-based em classificadores, score de candidatos, filler
  do optimize e rotas de recomendacao/weakness.

## Rodada focada: Classes not used

Escopo desta rodada: somente classes aparentemente sem uso em runtime/producao.
Nao foi executada auditoria ampla de funcoes nao chamadas, imports/ciclos,
tabelas PostgreSQL, duplicacao geral ou coerencia entre camadas.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativo.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo no inicio da rodada.
- `git rev-parse --short HEAD`: `f0eaf872`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 174.
- Imports quebrados: 0.

Limitacao atual: o auditor estrutural marca como "classe potencialmente nao
usada" quando uma classe nao aparece em outro arquivo. Para Flutter e Dart isso
gera muitos falsos positivos esperados: `State` privado, widgets auxiliares,
DTOs retornados por metodos do mesmo arquivo e classes usadas por inferencia de
tipo. A triagem abaixo manteve apenas classes cujo nome nao aparece em runtime
fora da propria declaracao/constructor, ou aparece somente em testes.

Como `rg` nao esta instalado neste shell local, a validacao usou buscas focadas
com `grep -RIn --include='*.dart'`.

### Achados confirmados

#### P1 — `LifeCounterScreen` legado segue em `app/lib`, mas a rota de producao usa `LotusLifeCounterScreen`

- **Classe:** `LifeCounterScreen`.
- **Definicao:** `app/lib/features/home/life_counter_screen.dart:61`.
- **Rota ativa:** `app/lib/main.dart:283` constroi
  `LotusLifeCounterScreen()` para a rota do life counter; `app/lib/main.dart:54`
  importa `features/home/lotus_life_counter_screen.dart`.
- **Busca de uso em producao:** `grep -RIn --include='*.dart' '\bLifeCounterScreen\b' app/lib`
  encontrou apenas a propria declaracao, construtor e `State` em
  `app/lib/features/home/life_counter_screen.dart:61`-`:77`.
- **Uso fora de producao:** a classe ainda aparece em
  `app/test/features/home/life_counter_screen_test.dart:36` e
  `app/test/features/home/life_counter_clone_proof_test.dart:277`.
- **Por que parece nao usada:** nao ha import/chamada de
  `life_counter_screen.dart` em `app/lib`; o fluxo app-facing usa a tela Lotus.
- **Risco:** `life_counter_screen.dart` tem cerca de 6400 linhas e continua
  citado como gargalo/risco visual, mas pode estar funcionando apenas como
  legado/test harness. Isso infla o mapa tecnico e cria ambiguidade sobre qual
  superficie e produto ativo.
- **O que valida:** remover a classe/arquivo e migrar ou remover os testes
  dependentes, ou documentar explicitamente que e fixture/harness legado fora do
  runtime.
- **O que falsifica:** algum entrypoint, flag de runtime ou fallback em
  `app/lib` passar a instanciar `LifeCounterScreen`.

#### P2 — `DeckCard` e testado, mas nao e usado na listagem real de decks

- **Classe:** `DeckCard`.
- **Definicao:** `app/lib/features/decks/widgets/deck_card.dart:17`.
- **Busca de uso em producao:** `grep -RIn --include='*.dart' '\bDeckCard\b' app/lib server/lib server/routes`
  encontrou somente `app/lib/features/decks/widgets/deck_card.dart:17` e o
  construtor em `app/lib/features/decks/widgets/deck_card.dart:22`.
- **Uso fora de producao:** `app/test/features/decks/widgets/deck_card_test.dart:9`
  e `app/test/features/decks/widgets/deck_card_overflow_test.dart:47`.
- **Comparacao com tela ativa:** a listagem em
  `app/lib/features/decks/screens/deck_list_screen.dart:606` usa
  `_DeckSpotlightCard`, e `app/lib/features/decks/screens/deck_list_screen.dart:626`
  usa `_DeckGalleryCard`; o arquivo define essas classes em `:989` e `:1401`.
- **Por que parece nao usada:** o widget publico antigo nao aparece em runtime,
  mas ainda possui testes dedicados, que podem dar falsa confianca sobre a
  listagem real.
- **O que valida:** apagar `DeckCard` e seus testes, ou religar a listagem real
  a esse widget se ele ainda for o contrato pretendido.
- **O que falsifica:** algum import de `deck_card.dart` em `app/lib` ou uso
  direto de `DeckCard(...)` em tela ativa.

#### P2 — `DeckProgressChip` nao tem nenhum chamador

- **Classe:** `DeckProgressChip`.
- **Definicao:** `app/lib/features/decks/widgets/deck_progress_indicator.dart:286`.
- **Busca de uso:** `grep -RIn --include='*.dart' '\bDeckProgressChip\b' .`
  encontrou apenas a declaracao em `:286` e o construtor em `:292`.
- **Classe relacionada ativa:** o mesmo arquivo e usado por
  `DeckProgressIndicator`, importado em
  `app/lib/features/decks/screens/deck_details_screen.dart:26` e
  `app/lib/features/decks/widgets/deck_details_overview_tab.dart:10`.
- **Por que parece nao usada:** `DeckProgressChip` nao e instanciado nem em
  producao nem em testes.
- **O que valida:** remover o chip ou adicionar uso real/teste se houver
  necessidade de um componente compacto.
- **O que falsifica:** chamada direta a `DeckProgressChip(...)` em `app/lib` ou
  testes que travem seu contrato como componente planejado.

#### P2 — `LotusPresentationMode` parece utilitario morto

- **Classe:** `LotusPresentationMode`.
- **Definicao:** `app/lib/features/home/lotus/lotus_presentation_mode.dart:4`.
- **Busca de uso:** `grep -RIn --include='*.dart' '\bLotusPresentationMode\b' app/lib app/test app/integration_test`
  encontrou apenas `app/lib/features/home/lotus/lotus_presentation_mode.dart:4`
  e o construtor privado em `:5`.
- **Busca por import:** `grep -RIn --include='*.dart' 'lotus_presentation_mode.dart' app/lib app/test app/integration_test`
  nao retornou ocorrencias.
- **Por que parece nao usada:** nenhum runtime, teste ou integration test chama
  `enter()`/`exit()`, apesar de a classe alterar orientacao e overlays do
  sistema.
- **O que valida:** remover o arquivo ou conectar `enter()`/`exit()` ao ciclo da
  `LotusLifeCounterScreen` com teste de contrato.
- **O que falsifica:** import real de `lotus_presentation_mode.dart` e chamada
  de `LotusPresentationMode.enter/exit`.

### Suspeitas revalidadas e descartadas nesta rodada

- A lista bruta de classes sem referencia cross-file contem muitos falsos
  positivos em widgets privados e classes `State`, por exemplo
  `_DeckDetailsScreenState`, `_HomeScreenState`, `_TradeDetailScreenState` e
  outros auxiliares locais; esses nao foram reportados.
- Classes publicas usadas apenas dentro do mesmo arquivo como DTO/resultado de
  helper tambem nao foram classificadas como defeito sem evidencia adicional.
  Exemplos descartados: `ManaSymbol`, `FallbackManaSymbol`,
  `FallbackColorPip`, `OptimizeProgressDialog` e os DTOs de
  `deck_optimize_flow_support.dart`.
- Nenhuma classe backend foi confirmada como realmente sem uso nesta rodada; a
  maioria dos candidatos backend sem referencia cross-file e DTO interno,
  retorno inferido de service, classe usada por `server/bin`, ou helper
  instanciado dentro do mesmo modulo.

## Rodada focada anterior: Coerencia entre `server/lib` <-> `server/routes` <-> `app/lib`

## Rodada focada: Coerencia entre `server/lib` <-> `server/routes` <-> `app/lib`

Escopo desta rodada: somente coerencia de contratos, ownership e consumo entre
helpers de `server/lib`, handlers de `server/routes` e consumidores em
`app/lib`. Nao foi executada auditoria ampla de classes sem uso, funcoes nao
chamadas, imports/ciclos, tabelas PostgreSQL ou duplicacao geral.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativo.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo no inicio da rodada.
- `git rev-parse --short HEAD`: `d2b189fc`.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local.

Resultado:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 174.
- Imports quebrados: 0.

Limitacao atual: o auditor estrutural continua util para mapa bruto de classes,
imports, tabelas e nomes duplicados, mas nao entende contratos app-facing nem
propagacao de ownership entre provider, rota e helper. Os achados abaixo foram
produzidos por leitura direta focada usando `grep`, porque `rg` nao esta
instalado neste shell local.

### Achados confirmados

#### P1 — `POST /ai/optimize` ainda perde ownership ao atravessar `routes -> lib`

- **Contrato app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:10`-`:23`
  monta o payload com `deck_id`, `archetype`, `bracket`, `keep_theme` e
  `intensity`; `app/lib/features/decks/providers/deck_provider_support_ai.dart:56`
  envia `POST /ai/optimize`.
- **Handler:** `server/routes/ai/optimize/index.dart:401`-`:405` le
  `userId` de forma tolerante, mas `server/routes/ai/optimize/index.dart:549`-`:558`
  chama `optimize_request.loadOptimizeDeckContext(...)` sem passar `userId`.
- **Helper:** `server/lib/ai/optimize_request_support.dart:53`-`:62` nao recebe
  `userId`; a query do deck em
  `server/lib/ai/optimize_request_support.dart:63`-`:73` usa
  `SELECT name, format FROM decks WHERE id = @id`, e as queries de cartas em
  `server/lib/ai/optimize_request_support.dart:87`-`:137` usam apenas
  `WHERE dc.deck_id = @id`.
- **Comparacao segura:** `server/routes/decks/[id]/index.dart:288`-`:317`
  usa `FROM decks WHERE id = @deckId AND user_id = @userId`; `server/routes/decks/[id]/analysis/index.dart:16`-`:25`
  tambem escopa por `deckId + userId` antes de ler analise.
- **Por que e incoerente:** o app trata optimize como acao sobre deck privado
  do usuario autenticado, mas a fronteira de helper carrega qualquer deck por
  UUID.
- **O que valida:** `loadOptimizeDeckContext` receber `userId`, consultar o deck
  por `id + user_id` ou por regra publica explicita, e testes owner vs non-owner
  para caminhos sync e async.
- **O que falsifica:** contrato documentado e testado provando que optimize
  aceita deck publico/alheio por design sem expor composicao privada.

#### P1 — `POST /ai/archetypes` e consumido pelo app, mas carrega deck/cartas sem owner

- **Contrato app:** `app/lib/features/decks/providers/deck_provider_support_mutation.dart:168`-`:173`
  chama `POST /ai/archetypes` com `{deck_id: deckId}`.
- **Handler:** `server/routes/ai/archetypes/index.dart:27`-`:35` le o
  `deck_id` e o `Pool`, mas nao le `context.read<String>()`; a query do deck em
  `server/routes/ai/archetypes/index.dart:39`-`:42` usa
  `SELECT name, format FROM decks WHERE id = @id`, e a query de cartas em
  `server/routes/ai/archetypes/index.dart:53`-`:62` usa `WHERE dc.deck_id = @id`.
- **Middleware:** `server/routes/ai/_middleware.dart:16`-`:20` aplica auth,
  limite de plano e rate limit, entao a rota e autenticada/custosa, mas o
  handler nao usa o usuario autenticado para escopar o deck.
- **Por que e incoerente:** as opcoes de arquétipo derivam da lista real do deck
  privado, mas qualquer UUID existente pode ser analisado por um usuario
  autenticado.
- **O que valida:** escopar `POST /ai/archetypes` por `deck_id + user_id` antes
  de montar prompt/cache/reference profile e adicionar teste non-owner.
- **O que falsifica:** contrato explicito para analisar apenas decks publicos ou
  compartilhados, com filtro `is_public=true` ou regra de acesso equivalente.

#### P1 — Polling de optimize aceita job com `user_id = NULL`

- **Contrato app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:74`-`:87`
  trata `202` como job async e
  `app/lib/features/decks/providers/deck_provider_support_ai.dart:190`-`:194`
  faz polling em `/ai/optimize/jobs/$jobId`.
- **Criacao:** `server/routes/ai/optimize/index.dart:459`-`:464` passa o
  `userId` para `OptimizeJobStore.create`, mas esse `userId` pode ser `null`
  porque foi lido de forma tolerante em `server/routes/ai/optimize/index.dart:401`-`:405`.
- **Store:** `server/lib/ai/optimize_job.dart:50`-`:64` persiste `user_id` com
  parametro nullable.
- **Polling:** `server/routes/ai/optimize/jobs/[id].dart:26`-`:28` le o usuario
  autenticado e carrega o job, mas `server/routes/ai/optimize/jobs/[id].dart:39`-`:47`
  bloqueia apenas quando `job.userId != null && job.userId != userId`. Jobs
  nulos ficam legiveis para qualquer usuario com o `job_id`.
- **Por que e incoerente:** o app nao tem conceito de job publico, e a rota fica
  sob `/ai` autenticado.
- **O que valida:** exigir `userId` nao nulo para jobs app-facing e retornar 404
  quando `job.userId == null`, salvo uma rota interna separada e documentada.
- **O que falsifica:** teste provando que nenhum job app-facing pode ser criado
  sem usuario e que o estado nulo tem politica segura.

#### P2 — Endpoints experimentais de deck/AI continuam sem ownership antes de promocao app-facing

- **Endpoints:** `GET /decks/:id/simulate`, `POST /decks/:id/recommendations`,
  `POST /ai/simulate-matchup`, `POST /ai/weakness-analysis`.
- **Evidencia de rotas:**
  - `server/routes/decks/[id]/simulate/index.dart:13`-`:26` le cartas por
    `WHERE dc.deck_id = @deckId`, sem ler `context.read<String>()`.
  - `server/routes/decks/[id]/recommendations/index.dart:23`-`:27` consulta
    `SELECT name, format, description FROM decks WHERE id = @deckId`, e
    `server/routes/decks/[id]/recommendations/index.dart:39`-`:58` le cartas
    por `dc.deck_id = @deckId`.
  - `server/routes/ai/simulate-matchup/index.dart:23`-`:38` le
    `my_deck_id`/`opponent_deck_id` e chama `_getDeckData`; essa funcao em
    `server/routes/ai/simulate-matchup/index.dart:76`-`:103` usa
    `SELECT id, name, format FROM decks WHERE id = @id` e cartas por
    `dc.deck_id = @id`.
  - `server/routes/ai/weakness-analysis/index.dart:17`-`:31` aceita `deck_id`
    e consulta `SELECT name, format FROM decks WHERE id = @id`; as cartas sao
    lidas em `server/routes/ai/weakness-analysis/index.dart:41`-`:60` por
    `dc.deck_id = @id`.
- **Evidencia app/contrato:** busca focada em `app/lib` nao encontrou chamadas
  para esses endpoints; `server/doc/API_CONTRACTS_AND_DATA_MAP.md:152`-`:153`
  e `:285`-`:286` marca os consumidores como `not proven`/experimentais.
- **Por que e incoerente:** as rotas vivem em namespaces autenticados
  (`server/routes/decks/_middleware.dart:7`-`:8` e
  `server/routes/ai/_middleware.dart:16`-`:20`), mas nao aplicam o padrao de
  owner dos endpoints estaveis de deck.
- **O que valida:** antes de expor no app, escopar `deck_id`/`my_deck_id` por
  `user_id`, definir regra separada para oponente publico/meta deck e adicionar
  teste non-owner.
- **O que falsifica:** decisao explicita de manter esses endpoints internos ou
  remove-los da superficie app-facing, com contrato atualizado e sem chamada em
  `app/lib`.

#### P2 — `/community/decks/following` segue como branch magico em rota dinamica

- **Contrato app:** `app/lib/features/social/providers/social_provider.dart:550`-`:584`
  chama `/community/decks/following?page=...&limit=20` e registra o endpoint
  como `/community/decks/following`.
- **Handler:** `server/routes/community/decks/[id].dart:10`-`:12` trata
  `id == 'following'` como caso especial e desvia para `_getFollowingFeed`.
- **Implementacao:** `server/routes/community/decks/[id].dart:294`-`:410`
  implementa o feed dentro do arquivo de detalhe dinamico; `find
  server/routes/community/decks -maxdepth 3 -type f` mostrou apenas
  `index.dart` e `[id].dart`, sem `following/index.dart`.
- **Contrato documentado:** `server/doc/API_CONTRACTS_AND_DATA_MAP.md:77`
  ja registra o risco de manutencao e recomenda rota dedicada.
- **Por que e incoerente:** a URI app-facing representa uma colecao/feed, mas o
  arquivo fisico e a dispatch rule tratam `following` como valor magico de
  `:id`.
- **O que valida:** criar `server/routes/community/decks/following/index.dart`
  ou teste de contrato explicito cobrindo `GET /community/decks/following` e
  `GET /community/decks/:id`.
- **O que falsifica:** decisao documentada de manter o branch por compatibilidade
  com teste que trave o comportamento.

### Suspeitas revalidadas e descartadas nesta rodada

- `POST /ai/rebuild` nao foi reaberto: `server/routes/ai/rebuild/index.dart:16`
  le `userId`, e o carregamento inicial em `server/routes/ai/rebuild/index.dart:70`
  parte de query com deck/user antes de carregar cartas.
- `GET /decks/:id/analysis` nao foi reaberto: `server/routes/decks/[id]/analysis/index.dart:18`-`:25`
  le `userId` e filtra `decks` por `id + user_id` antes de consultar cartas.
- A afirmacao historica de que `POST /ai/optimize`, `GET /ai/optimize/jobs/:id`
  e `POST /ai/archetypes` estavam saneados em `origin/master@65f30387` nao foi
  sustentada pelo checkout auditado (`d2b189fc`); os documentos de plano/mapa
  foram ajustados para refletir a evidencia atual.

## Rodada focada anterior: Duplicated or similar logic

## Rodada focada: Duplicated or similar logic

Escopo desta rodada: somente logica duplicada ou similar. Nao foi executada
auditoria ampla de classes sem uso, funcoes nao chamadas, imports/ciclos,
tabelas PostgreSQL ou coerencia geral entre camadas.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: branch remota sincronizada.
- `git checkout codex/hermes-analysis-docs`: branch ja ativo.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo no inicio da rodada.

### Auditor estrutural

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado com
sucesso no Mac local depois da correcao do root/path resolver.

Resultado:

- Arquivos analisados: 167.
- Classes encontradas: 167.
- Tabelas PostgreSQL referenciadas: 85.
- Problemas identificados pelo relatorio gerado: 174.
- Imports quebrados: 0.

Limitacao atual: para duplicacao, o auditor ainda usa colisao de nomes de
funcoes como sinal bruto. A lista inclui falsos positivos esperados (`toString`,
`print`, callbacks chamados `Function`, wrappers finos de rota e helpers locais
sem semantica compartilhada). Os achados abaixo foram mantidos apenas quando a
leitura direta confirmou mesma intencao de dominio ou corpo equivalente.

### Achados confirmados

#### P1 — Heuristicas semanticas de combo/engine/payoff/enabler/wincon seguem divergindo em dois classificadores

- **Simbolos:** `_looksLikeWincon`, `_looksLikeComboPiece`,
  `_looksLikeEngine`, `_looksLikePayoff`, `_looksLikeEnabler`.
- **Evidencia 1:** `server/lib/ai/functional_card_tags.dart:319`-`:335`
  chama os helpers para tags v1; as definicoes em
  `server/lib/ai/functional_card_tags.dart:859`-`:906` usam `oracle` +
  `normalizedName` e incluem sentinelas por nome como `thassa's oracle`,
  `isochron scepter`, `dramatic reversal`, `blood artist`, `greaves` e
  `boots`.
- **Evidencia 2:** `server/lib/ai/optimization_functional_roles.dart:113`-`:117`
  chama helpers com os mesmos nomes para `classifyOptimizationFunctionalRole`;
  as definicoes em `server/lib/ai/optimization_functional_roles.dart:370`-`:397`
  usam apenas `oracle` e padroes diferentes.
- **Por que parece duplicado/similar:** ambos classificam os mesmos papeis
  semanticos de alto nivel, mas mantem heuristicas independentes.
- **Risco:** a analise funcional pode explicar uma carta como `combo_piece`,
  `engine`, `payoff`, `enabler` ou `wincon`, enquanto o pipeline de optimize
  atribui outro papel para a mesma carta.
- **O que valida:** extrair uma fonte compartilhada de sinais semanticos ou
  adicionar testes cruzados para cartas sentinela.
- **O que falsifica:** contrato/testes demonstrando que os classificadores
  divergem por design e que essa divergencia e esperada nos fluxos de analise e
  optimize.

#### P2 — `getMainType` e `calculateCmc` duplicam estatisticas de deck privado e publico

- **Simbolos:** `getMainType`, `calculateCmc`.
- **Evidencia 1:** `server/routes/decks/[id]/index.dart:405`-`:435` define
  `getMainType` e `calculateCmc` na rota privada; os helpers alimentam
  `groupedMainBoard` e `manaCurve` em `server/routes/decks/[id]/index.dart:452`
  e `:464`.
- **Evidencia 2:** `server/routes/community/decks/[id].dart:91`-`:117` define
  os mesmos helpers na rota publica; o uso equivalente aparece em
  `server/routes/community/decks/[id].dart:133` e `:141`.
- **Por que parece duplicado/similar:** as duas rotas constroem tipo principal,
  curva de mana e distribuicao de cores a partir de `cardsList` com regras quase
  iguais.
- **Risco:** um ajuste de regra de CMC/tipo pode chegar a uma rota e nao a outra,
  fazendo o mesmo deck exibir estatisticas diferentes para dono e comunidade.
- **O que valida:** helper compartilhado de estatisticas de deck, com fixture
  comum para resposta privada e publica.
- **O que falsifica:** testes de contrato provando que as respostas devem
  divergir e que ambas as implementacoes locais estao travadas por fixtures.

#### P2 — `_isBasicLandName` ainda tem variantes de normalizacao no backend

- **Simbolo:** `_isBasicLandName` / `isBasicLandName`.
- **Evidencia 1:** `server/lib/ai/optimize_runtime_support.dart:285` expoe
  `isBasicLandName`; a regra privada em
  `server/lib/ai/optimize_runtime_support.dart:4184`-`:4197` aceita nomes
  exatos e snow lands com hifen.
- **Evidencia 2:** `server/lib/generated_deck_validation_service.dart:752`-`:763`
  aceita snow lands por `startsWith('snow-covered ...')`.
- **Evidencia 3:** `server/lib/meta/meta_deck_reference_support.dart:890`-`:903`
  aceita snow lands com espaco (`snow covered plains`), sem hifen.
- **Evidencia 4:** `server/routes/ai/commander-reference/index.dart:621`-`:628`
  reconhece apenas as seis basics nao snow.
- **Por que parece duplicado/similar:** todos os trechos respondem a mesma
  pergunta de dominio ("este nome e terreno basico?"), mas normalizam casos
  diferentes.
- **Risco:** validacao, optimize, referencia de meta e commander-reference podem
  discordar sobre snow lands ou nomes normalizados.
- **O que valida:** centralizar a regra em utilitario de dominio e adicionar
  testes para `Wastes`, snow lands com hifen e variantes normalizadas.
- **O que falsifica:** testes por contexto mostrando que cada variante e
  exigida por contrato diferente.

#### P2 — Boilerplate de `request_id` e `invalid_payload` segue repetido em rotas sociais

- **Simbolos:** `_requestId`, `_logInvalidPayload`.
- **Evidencia:** `_requestId` tem corpo equivalente em
  `server/routes/trades/index.dart:330`-`:336`,
  `server/routes/trades/[id]/messages.dart:228`-`:234`,
  `server/routes/conversations/[id]/messages.dart:247`-`:253`,
  `server/routes/trades/[id]/respond.dart:154`-`:160`,
  `server/routes/trades/[id]/status.dart:260`-`:266` e
  `server/routes/users/[id]/follow/index.dart:97`-`:103`.
- **Evidencia adicional:** `_logInvalidPayload` repete leitura tolerante de
  usuario, prefixo `[social_write] invalid_payload`, `request_id` e ids de
  recurso em `server/routes/trades/index.dart:338`-`:352`,
  `server/routes/trades/[id]/messages.dart:236`-`:252`,
  `server/routes/conversations/[id]/messages.dart:255`-`:271`,
  `server/routes/trades/[id]/respond.dart:162`-`:178` e
  `server/routes/trades/[id]/status.dart:268`-`:284`.
- **Por que parece duplicado/similar:** a responsabilidade e identica, variando
  apenas endpoint e campo extra.
- **Risco:** formato de log, fallback de `x-request-id` ou sanitizacao de usuario
  podem divergir entre trades/conversas/follow.
- **O que valida:** helper compartilhado de social write logging aceitando
  endpoint e campos extras.
- **O que falsifica:** decisao explicita de manter logs por rota, com teste que
  preserve formato equivalente.

#### P2 — SQL de trust em trades e duplicado entre lista e detalhe

- **Simbolos:** `_trustStatsSql`, `_responseTimeSql`, `_shippingTimeSql`,
  `_buildTrustInsight`.
- **Evidencia 1:** `server/routes/trades/index.dart:557`-`:601` define os tres
  SQL snippets para estatisticas, tempo de resposta e tempo de envio usados na
  listagem de trades.
- **Evidencia 2:** `server/routes/trades/[id]/index.dart:260`-`:304` define os
  mesmos tres snippets para o detalhe de trade.
- **Por que parece duplicado/similar:** listagem e detalhe calculam exatamente o
  mesmo bloco de trust para sender/receiver via `LEFT JOIN LATERAL`.
- **Risco:** alteracoes futuras em trust score, status considerados ou janela de
  tempo podem ser aplicadas em uma rota e esquecidas na outra.
- **O que valida:** mover snippets e builder de trust para helper compartilhado
  de trades, com teste para list/detail.
- **O que falsifica:** diferenca intencional documentada entre trust de lista e
  trust de detalhe.

#### P3 — Normalizacao de `condition` de carta esta duplicada nas mutacoes de deck

- **Simbolo:** `_validateCondition`.
- **Evidencia 1:** `server/routes/decks/[id]/cards/index.dart:397`-`:403`
  normaliza `condition` para `NM`, `LP`, `MP`, `HP` ou `DMG`, com fallback
  `NM`.
- **Evidencia 2:** `server/routes/decks/[id]/cards/set/index.dart:243`-`:248`
  repete a mesma regra para ajuste de quantidade/condicao.
- **Por que parece duplicado/similar:** ambas as mutacoes de deck aceitam o
  mesmo campo app-facing e aplicam a mesma allow-list.
- **Risco:** se a lista de condicoes mudar ou ganhar mapeamento mais rico, uma
  rota pode aceitar valores que a outra normaliza para `NM`.
- **O que valida:** extrair `normalizeCardCondition` compartilhado e testar as
  duas rotas ou o helper.
- **O que falsifica:** contrato documentado dizendo que as rotas podem normalizar
  condicao de formas diferentes.

### Suspeitas revalidadas e descartadas nesta rodada

- A duplicacao direta entre `server/routes/ai/optimize/index.dart` e
  `server/lib/ai/optimize_runtime_support.dart` para
  `matchesFunctionalNeed`, `scoreOptimizeReplacementCandidate`,
  `shouldRetryOptimizeWithAiFallback`,
  `computeOptimizeStructuralRecoverySwapTarget` e
  `isOptimizeStructuralRecoveryScenario` segue descartada: a rota possui
  wrappers finos que delegam para `optimize_support` em
  `server/routes/ai/optimize/index.dart:56`-`:132`.
- `resolveOptimizeArchetype` ainda e similar, mas o duplicado real fica entre
  `server/lib/ai/optimize_runtime_support.dart:3369`-`:3389` e
  `server/lib/ai/deck_state_analysis.dart:573`-`:584`; o wrapper da rota apenas
  delega.
- Colisoes do auditor como `toString`, `print`, `Function`, `add`, `set` e
  `_toInt` nao foram promovidas a achados sem prova de mesma regra de dominio.

## Rodada focada anterior: Correcao do auditor estrutural

Escopo desta rodada: corrigir o proprio `structure_auditor.py` antes de usar a
contagem de imports quebrados como evidência de produto.

### Resultado

- `docs/hermes-analysis/scripts/structure_auditor.py` agora resolve o root do
  repo por `MTGIA_REPO_ROOT` ou `Path.cwd()`, evitando o caminho fixo
  `/opt/data/workspace/mtgia` em execucoes locais.
- Imports relativos agora sao resolvidos a partir do diretorio do arquivo Dart
  que contem o import, alinhado ao comportamento do analyzer.
- Imports `package:server/...`, `package:manaloom/...` e o alias historico
  `package:ai/...` sao resolvidos apenas quando pertencem ao repositorio;
  pacotes externos continuam fora do escopo do auditor estrutural.
- O script preserva rodadas manuais do `STRUCTURE_AUDIT.md` e substitui somente
  o bloco gerado automaticamente.
- Nova execucao: `Imports quebrados: 0`.

### Validacao

- `MTGIA_REPO_ROOT=/Users/desenvolvimentomobile/.manaloom-agents/mtgia python3 docs/hermes-analysis/scripts/structure_auditor.py`
- `python3 -m py_compile docs/hermes-analysis/scripts/structure_auditor.py`

### Impacto no backlog

O P0 de falso-positivo em massa de imports fica **resolvido para a ferramenta**.
As rodadas historicas abaixo foram preservadas como contexto, mas as referencias
antigas a 178 imports quebrados nao devem mais ser usadas como bug real.

> Data: 2026-05-28 17:47 UTC
> Rotacao local Codex: `module-coherence-server-lib-routes-app-lib`

## Rodada focada: Coerencia entre `server/lib` ↔ `server/routes` ↔ `app/lib`

Escopo desta rodada: somente coerencia de contratos, ownership e consumo entre
helpers de `server/lib`, handlers de `server/routes` e consumidores em
`app/lib`. Nao foi executada auditoria ampla de classes sem uso, funcoes nao
chamadas, imports, ciclos, tabelas PostgreSQL ou duplicacao geral.

### Limitacao da ferramenta

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado conforme
o protocolo, mas falhou antes de gerar relatorio valido porque o script ainda usa
`BASE = Path("/opt/data/workspace/mtgia")` e tentou criar
`/opt/data/workspace/mtgia/docs/hermes-analysis`, encerrando no Mac local com
`PermissionError: [Errno 13] Permission denied: '/opt/data'`.

Resultado: os achados abaixo foram produzidos por inspecao manual focada em
rotas chamadas por `app/lib`, rotas autenticadas que aceitam `deck_id` e
contratos experimentais marcados como `not proven` no app. Nao foi inventada
saida do auditor.

### Achados confirmados

#### P1 — `POST /ai/optimize` continua recebendo `deck_id` do app sem escopo de owner no helper de contexto

- **Contrato app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:10`-`:23`
  monta payload com `deck_id`, `archetype`, `bracket`, `keep_theme` e
  `intensity`; `app/lib/features/decks/providers/deck_provider_support_ai.dart:56`
  envia `POST /ai/optimize`.
- **Handler:** `server/routes/ai/optimize/index.dart:401`-`:405` tenta ler
  `userId` do contexto autenticado; `server/routes/ai/optimize/index.dart:549`-`:558`
  chama `optimize_request.loadOptimizeDeckContext(...)` com `deckId`,
  `targetArchetype`, `requestMode`, `intensity`, `bracket` e `keepTheme`, mas
  nao passa `userId`.
- **Helper:** `server/lib/ai/optimize_request_support.dart:53`-`:62` nao
  recebe `userId`; a query do deck em
  `server/lib/ai/optimize_request_support.dart:63`-`:73` usa
  `SELECT name, format FROM decks WHERE id = @id`, e a query de cartas em
  `server/lib/ai/optimize_request_support.dart:87`-`:137` usa apenas
  `WHERE dc.deck_id = @id`.
- **Comparacao segura:** `server/routes/decks/[id]/index.dart:288`-`:317`
  usa o padrao `FROM decks WHERE id = @deckId AND user_id = @userId` para
  leitura app-facing de deck privado.
- **Por que e incoerente:** o app trata optimize como acao sobre deck do usuario
  autenticado, mas a fronteira `routes -> lib` perde o requisito de ownership
  antes de carregar deck/cartas.
- **Risco:** usuario autenticado que obtenha UUID de deck alheio pode
  potencialmente disparar analise/otimizacao sobre composicao privada e consumir
  trabalho de IA.
- **O que valida:** alterar `loadOptimizeDeckContext` para receber `userId` e
  consultar `decks` com `id + user_id` ou regra publica explicita; adicionar
  teste owner vs non-owner para caminhos sync e async de `POST /ai/optimize`.
- **O que falsifica:** contrato documentado e testado provando que optimize
  aceita decks publicos/alheios por design, com autorizacao explicita e sem
  expor composicao privada.

#### P1 — `POST /ai/archetypes` e consumido pelo app, mas tambem carrega deck/cartas sem ownership

- **Contrato app:** `app/lib/features/decks/providers/deck_provider_support_mutation.dart:168`-`:173`
  chama `POST /ai/archetypes` com `{deck_id: deckId}` para buscar opcoes de
  otimizacao.
- **Middleware:** `server/routes/ai/_middleware.dart:16`-`:20` aplica
  `authMiddleware`, `aiPlanLimitMiddleware` e `aiRateLimit`, portanto a rota
  esta em namespace autenticado/custoso de IA.
- **Handler:** `server/routes/ai/archetypes/index.dart:27`-`:32` aceita
  `deck_id`; `server/routes/ai/archetypes/index.dart:39`-`:42` consulta
  `SELECT name, format FROM decks WHERE id = @id`; e
  `server/routes/ai/archetypes/index.dart:54`-`:62` consulta cartas com
  `WHERE dc.deck_id = @id`. O handler nao le `context.read<String>()` nem
  filtra por `decks.user_id`.
- **Cobertura existente:** `server/test/ai_archetypes_flow_test.dart:157`-`:234`
  cobre cache/resposta positiva, e
  `server/test/error_contract_test.dart:894`-`:934` cobre `deck_id` ausente e
  deck inexistente; nao ha prova non-owner nessas evidencias.
- **Por que e incoerente:** a rota e app-facing, usa credito/rate limit de IA e
  retorna opcoes geradas a partir da lista real do deck, mas aceita qualquer UUID
  de deck existente em vez de aplicar a mesma fronteira de owner dos endpoints
  de deck privado.
- **Risco:** usuario autenticado pode obter opcoes de arquétipo derivadas de deck
  privado de outro usuario, revelando comandante/amostra de cartas via prompt e
  diagnosticos.
- **O que valida:** escopar o deck por `id + user_id` antes de montar prompt,
  cache key e reference profile; adicionar teste owner vs non-owner para
  `POST /ai/archetypes`.
- **O que falsifica:** decisao de produto documentada que a rota analisa apenas
  decks publicos/alheios por design, com query filtrando `is_public=true` ou
  contrato separado para deck compartilhado.

#### P1 — Polling de jobs async ainda aceita jobs sem `user_id`

- **Contrato app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:74`-`:87`
  trata `202` de optimize como job async e
  `app/lib/features/decks/providers/deck_provider_support_ai.dart:190`-`:194`
  faz polling em `/ai/optimize/jobs/$jobId`.
- **Store:** `server/lib/ai/optimize_job.dart:25`-`:30` permite
  `String? userId`; `server/lib/ai/optimize_job.dart:47`-`:64` persiste
  `user_id` nullable.
- **Criação atual:** `server/routes/ai/optimize/index.dart:457`-`:464` e
  `server/routes/ai/optimize/index.dart:1041`-`:1048` passam o `userId`
  capturado, mas ele ainda pode ser nulo porque o handler o captura de forma
  tolerante em `server/routes/ai/optimize/index.dart:401`-`:405`.
- **Handler de polling:** `server/routes/ai/optimize/jobs/[id].dart:26`-`:28`
  le o usuario autenticado e carrega o job, mas
  `server/routes/ai/optimize/jobs/[id].dart:39`-`:47` so bloqueia quando
  `job.userId != null && job.userId != userId`; jobs com `user_id = NULL`
  ficam legiveis para qualquer usuario com o `job_id`.
- **Por que e incoerente:** o app nao tem conceito de job publico e o endpoint
  fica sob `/ai` autenticado, mas a regra de acesso preserva um estado nulo que
  enfraquece a fronteira de usuario.
- **O que valida:** exigir `userId` nao nulo ao criar jobs app-facing e retornar
  404 quando `job.userId == null` no polling, salvo rota interna separada.
- **O que falsifica:** prova de que nenhum job async app-facing pode ser criado
  sem usuario e teste explicito cobrindo a politica para `user_id = NULL`.

#### P2 — Endpoints experimentais de deck/AI seguem sem ownership e sem consumidor app provado

- **Endpoints:** `GET /decks/:id/simulate`, `POST /decks/:id/recommendations`,
  `POST /ai/simulate-matchup`, `POST /ai/weakness-analysis`.
- **Evidencia de rotas:**
  - `server/routes/decks/[id]/simulate/index.dart:13`-`:26` le cartas com
    `WHERE dc.deck_id = @deckId`, sem buscar `context.read<String>()` nem
    validar `decks.user_id`.
  - `server/routes/decks/[id]/recommendations/index.dart:16`-`:27` consulta
    `SELECT name, format, description FROM decks WHERE id = @deckId`, e
    `server/routes/decks/[id]/recommendations/index.dart:39`-`:58` le cartas
    por `dc.deck_id = @deckId`, tambem sem `user_id`.
  - `server/routes/ai/simulate-matchup/index.dart:24`-`:38` le
    `my_deck_id`/`opponent_deck_id` e chama `_getDeckData`; essa funcao em
    `server/routes/ai/simulate-matchup/index.dart:76`-`:103` usa
    `SELECT id, name, format FROM decks WHERE id = @id` e cartas por
    `dc.deck_id = @id`.
  - `server/routes/ai/weakness-analysis/index.dart:17`-`:35` aceita `deck_id`
    e consulta `SELECT name, format FROM decks WHERE id = @id`; as cartas sao
    lidas em `server/routes/ai/weakness-analysis/index.dart:42`-`:60` por
    `dc.deck_id = @id`.
- **Evidencia app/contrato:** `grep -RInE` por esses endpoints em `app/lib`
  nao encontrou chamadas; `server/doc/API_CONTRACTS_AND_DATA_MAP.md:152`-`:153`
  e `:285`-`:286` marca consumidores como `not proven`/experimentais.
- **Por que e incoerente:** rotas autenticadas em `server/routes/decks/_middleware.dart:7`-`:8`
  e `server/routes/ai/_middleware.dart:16`-`:20` nao aplicam a regra de owner
  dos endpoints de deck ja consumidos pelo app.
- **O que valida:** antes de expor no app, escopar `deck_id`/`my_deck_id` por
  `user_id` e definir regra separada para oponente publico/meta deck; adicionar
  teste non-owner para cada rota mantida.
- **O que falsifica:** decisao explicita de tornar esses endpoints internos ou
  remove-los da superficie app-facing, com contrato atualizado e sem chamadas em
  `app/lib`.

#### P2 — `/community/decks/following` continua acoplado a branch especial em rota dinamica

- **Contrato app:** `app/lib/features/social/providers/social_provider.dart:563`-`:565`
  chama `/community/decks/following?page=...&limit=20` e
  `app/lib/features/social/providers/social_provider.dart:581`-`:585` registra
  o endpoint como `/community/decks/following`.
- **Handler:** `find server/routes/community/decks -maxdepth 3 -type f` mostra
  apenas `server/routes/community/decks/index.dart` e
  `server/routes/community/decks/[id].dart`; nao existe
  `server/routes/community/decks/following/index.dart`.
- **Branch especial:** `server/routes/community/decks/[id].dart:10`-`:12`
  trata `id == 'following'` como caso especial e desvia para
  `_getFollowingFeed`.
- **Por que e incoerente:** a URI consumida pelo app representa feed/colecao,
  mas esta implementada como valor magico dentro do handler de detalhe
  `/community/decks/:id`.
- **O que valida:** criar rota dedicada
  `server/routes/community/decks/following/index.dart` ou teste de contrato que
  preserve explicitamente esse caso especial.
- **O que falsifica:** decisao documentada de manter o branch magico por
  compatibilidade, com teste cobrindo `GET /community/decks/following` e
  `GET /community/decks/:id`.

### Suspeitas revalidadas e descartadas nesta rodada

- `POST /ai/rebuild` continua fora dos achados de incoerencia de ownership:
  `app/lib/features/decks/providers/deck_provider_support_ai.dart:120`-`:168`
  envia `deck_id`, e a rota ja foi revalidada na rodada anterior como escopando
  o deck por `id + user_id` antes de carregar cartas e criar draft.
- `GET /cards?set=...` e notificacoes `direct_message` nao foram reabertas nesta
  rodada porque a revalidacao anterior ja tinha evidencias compatíveis e o foco
  atual encontrou riscos de maior impacto em `deck_id` autenticado.

## Rodada focada anterior: PostgreSQL tables not used
> Data: 2026-05-28 15:00 UTC
> Rotacao local Codex: `postgresql-tables-not-used`

## Rodada focada: PostgreSQL tables not used

Escopo desta rodada: somente tabelas PostgreSQL sem uso, write-only ou com uso
persistente incoerente. Nao foi executada auditoria ampla de classes, funcoes,
imports, ciclos, duplicacao ou coerencia geral entre camadas.

### Limitacao da ferramenta

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado conforme
o protocolo, mas falhou antes de gerar relatorio valido porque o script ainda usa
`BASE = Path("/opt/data/workspace/mtgia")` e tentou criar
`/opt/data/workspace/mtgia/docs/hermes-analysis`, encerrando no Mac local com
`PermissionError: [Errno 13] Permission denied: '/opt/data'`.

Resultado: os achados abaixo foram produzidos por inspecao manual focada em
definicoes `CREATE TABLE`, referencias SQL (`FROM`, `JOIN`, `INSERT INTO`,
`UPDATE`, `DELETE FROM`) e consumidores em `server/`, `app/` e docs de contrato.
Nao foi inventada saida do auditor.

### Achados confirmados

#### P2 — `deck_matchups` continua write-only no produto atual

- **Tabela:** `deck_matchups`
- **Definicao:** `server/database_setup.sql:162`-`:170`.
- **Escrita confirmada:** `server/routes/ai/simulate-matchup/index.dart:360`
  faz `INSERT INTO deck_matchups (...) ON CONFLICT (...) DO UPDATE`.
- **Leitura/consumo encontrado:** `grep -RInE` por `FROM/JOIN/UPDATE/DELETE`
  em `server/` e `app/` encontrou somente a escrita acima; nao ha
  `SELECT ... FROM deck_matchups` em rotas, libs ou consumidores Flutter.
- **Por que parece nao usada:** `POST /ai/simulate-matchup` calcula e retorna o
  resultado na propria chamada, mas o snapshot salvo em
  `deck_matchups.win_rate/notes` nao alimenta cache, historico, ranking,
  dashboard ou contrato app-facing. `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
  marca `POST /ai/simulate-matchup` como consumidor `not proven`.
- **O que valida:** adicionar ou localizar consumidor real que leia
  `deck_matchups`, por exemplo historico/cached matchup, dashboard operacional
  ou reuso em nova simulacao.
- **O que falsifica:** um `SELECT ... FROM deck_matchups` em rota/lib consumida
  pelo app ou por job operacional documentado.

#### P2 — `deck_weakness_reports` acumula registros sem fluxo de leitura ou resolucao

- **Tabela:** `deck_weakness_reports`
- **Definicao:** `server/database_setup.sql:363`-`:376` e
  `server/bin/migrate_create_missing_tables.dart:97`.
- **Escrita confirmada:** `server/routes/ai/weakness-analysis/index.dart:374`
  faz `INSERT INTO deck_weakness_reports (...) ON CONFLICT DO NOTHING`.
- **Leitura/consumo encontrado:** `grep -RInE` por `FROM/JOIN/UPDATE/DELETE`
  em `server/` e `app/` encontrou somente a escrita acima; nao ha leitura da
  tabela nem fluxo que atualize `addressed`.
- **Por que parece nao usada:** `POST /ai/weakness-analysis` devolve
  `weaknesses` na resposta imediata, mas o dado persistido nao e listado,
  reaberto, marcado como tratado ou usado em analise futura. O campo
  `addressed` existe no schema (`server/database_setup.sql:371`) sem update
  confirmado.
- **O que valida:** criar/identificar endpoint, job ou UI que leia relatorios
  persistidos e atualize `addressed` quando o usuario corrige a fraqueza.
- **O que falsifica:** uma leitura real da tabela fora de migration/audit/teste,
  ou decisao explicita de manter a tabela apenas como log bruto com retencao.

#### P3 — `ml_prompt_feedback` tem helper de insert sem chamador e so aparece como contador operacional

- **Tabela:** `ml_prompt_feedback`
- **Definicao:** `server/bin/migrate_ml_knowledge.dart:159`-`:195`.
- **Escrita potencial:** `server/lib/ml_knowledge_service.dart:251`-`:284`
  define `MLKnowledgeService.recordFeedback` e faz
  `INSERT INTO ml_prompt_feedback (...)`.
- **Leitura/consumo encontrado:** `server/routes/ai/ml-status/index.dart:98`
  executa apenas `SELECT COUNT(*)::int as c FROM ml_prompt_feedback`.
- **Evidencia de nao acionamento:** `grep -RIn "recordFeedback" server app`
  encontrou somente a definicao em `server/lib/ml_knowledge_service.dart:251`;
  nao ha rota, provider ou job chamando o insert.
- **Por que parece nao usada:** a tabela foi criada para feedback de usuario,
  mas nenhum fluxo app/backend registra feedback. O unico uso runtime confirmado
  e um contador em endpoint interno de status, que nao consome o conteudo para
  treinamento, ranking, prompts ou produto.
- **O que valida:** ligar um fluxo real de feedback pos-otimizacao ou job que
  consuma `ml_prompt_feedback` para refinar prompts/modelo, com teste de contrato.
- **O que falsifica:** chamada existente de `recordFeedback` nao capturada nesta
  busca, trigger externo documentado, ou decisao de manter a tabela apenas como
  placeholder sem coleta ativa.

#### P3 — Tabelas raw do Commander Reference Deck Corpus sao persistidas, mas o produto le apenas o agregado

- **Tabelas:** `commander_reference_decks` e
  `commander_reference_deck_cards`.
- **Definicao:** `server/lib/ai/commander_reference_deck_corpus_support.dart:1177`
  e `:1200`.
- **Escrita confirmada:** `server/lib/ai/commander_reference_deck_corpus_support.dart:1245`
  insere em `commander_reference_decks`, `:1329` apaga cards antigos por
  `source_deck_key` e `:1345` insere em `commander_reference_deck_cards`.
- **Leitura/consumo encontrado:** a busca por `FROM/JOIN commander_reference_decks`
  e `FROM/JOIN commander_reference_deck_cards` em `server/` e `app/` nao
  encontrou leituras dessas tabelas. O caminho de produto le o agregado
  `commander_reference_deck_analysis` em
  `server/lib/ai/commander_reference_deck_corpus_support.dart:389`, e esse
  agregado e populado em `:1394`.
- **Por que parece uso parcial/incoerente:** os detalhes raw de deck/cartas
  parecem servir apenas como trilha de auditoria/reprocessamento no mesmo apply,
  enquanto generate consome somente `average_role_counts`, `top_cards` e
  `theme_counts` do agregado. Isso pode ser intencional, mas hoje nao ha
  consumidor de produto ou job que releia os raws para recomputar o agregado.
- **O que valida:** documentar essas tabelas como lineage/audit com retencao, ou
  adicionar job/endpoint que leia os raws para reprocessar o agregado e auditar
  cards aceitos/rejeitados.
- **O que falsifica:** `SELECT/JOIN` real sobre as tabelas raw em rota/lib/job
  operacional ou decisao de remover a persistencia raw e manter somente o
  agregado consumido.

### Suspeitas revalidadas e descartadas nesta rodada

- `battle_simulations` nao foi classificada como nao usada: a rota
  `server/routes/ai/simulate/index.dart:206` insere simulacoes e
  `server/bin/ml_extract_features.dart:76` le `FROM battle_simulations` para
  extracao de features.
- `ai_user_preferences` nao foi classificada como nao usada:
  `server/lib/ai/optimize_runtime_support.dart` le e persiste preferencias de
  IA.
- `card_semantic_tags_v2`, `card_function_tags`, `card_role_scores`,
  `commander_card_synergy` e `optimize_rejection_penalties` nao foram tratados
  como tabelas nao usadas: ha backfills/jobs e consumo por analysis/optimize ou
  candidate-quality metadata.
- `commander_reference_deck_analysis` nao foi tratada como nao usada: e lida por
  `loadCommanderReferenceDeckCorpusGuidance` e participa da versao/cache de
  generate.
- Tabelas operacionais como `schema_migrations`, `sync_state`, `sync_log`,
  `rate_limit_events`, `ai_logs`, `ai_optimize_jobs`, `ai_generate_jobs` e
  `activation_funnel_events` possuem referencias de leitura/escrita ou finalidade
  operacional explicita e nao entraram como achados.

## Rodada focada anterior: Coerencia entre `server/lib` ↔ `server/routes` ↔ `app/lib`
> Data: 2026-05-28 12:51 UTC
> Rotacao local Codex: `module-coherence-server-lib-routes-app-lib`

## Rodada focada: Coerencia entre `server/lib` ↔ `server/routes` ↔ `app/lib`

Escopo desta rodada: somente coerencia de contratos, ownership e consumo entre
helpers de `server/lib`, handlers de `server/routes` e consumidores em
`app/lib`. Nao foi executada auditoria ampla de classes sem uso, funcoes nao
chamadas, imports, ciclos, tabelas PostgreSQL ou duplicacao geral.

### Limitacao da ferramenta

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado conforme
o protocolo, mas falhou antes de gerar relatorio valido porque o script ainda usa
`BASE = Path("/opt/data/workspace/mtgia")` e tentou criar
`/opt/data/workspace/mtgia/docs/hermes-analysis`, encerrando no Mac local com
`PermissionError: [Errno 13] Permission denied: '/opt/data'`.

Resultado: os achados abaixo foram produzidos por inspecao manual focada em
rotas chamadas por `app/lib` e em endpoints experimentais documentados como
`not proven` no app. Nao foi inventada saida do auditor.

### Achados confirmados

#### P1 — `POST /ai/optimize` recebe `deck_id` do app, mas o loader de contexto nao escopa o deck por dono

- **Contrato app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:10`-`:23`
  monta payload com `deck_id`, `archetype`, `bracket`, `keep_theme` e
  `intensity`; `app/lib/features/decks/providers/deck_provider_support_ai.dart:56`
  envia `POST /ai/optimize`.
- **Handler:** `server/routes/ai/optimize/index.dart:401`-`:405` le `userId`
  do contexto autenticado e `server/routes/ai/optimize/index.dart:545`-`:558`
  chama `optimize_request.loadOptimizeDeckContext(...)` passando `deckId`, mas
  nao passa `userId`.
- **Helper:** `server/lib/ai/optimize_request_support.dart:53`-`:62` nao recebe
  `userId`; a query do deck em `server/lib/ai/optimize_request_support.dart:63`-`:73`
  usa `SELECT name, format FROM decks WHERE id = @id`, e a query de cartas em
  `server/lib/ai/optimize_request_support.dart:87`-`:137` usa apenas
  `WHERE dc.deck_id = @id`.
- **Por que e incoerente:** o app chama optimize para deck privado do usuario
  autenticado, e rotas estaveis de deck usam ownership explicito, por exemplo
  `server/routes/decks/[id]/index.dart:300`-`:317` consulta
  `FROM decks WHERE id = @deckId AND user_id = @userId`. O caminho de optimize
  atravessa `server/routes` para `server/lib` sem carregar o mesmo requisito.
- **Risco:** um usuario autenticado que obtenha um UUID de deck alheio pode
  potencialmente disparar analise/otimizacao sobre esse deck, expondo composicao
  privada e consumindo trabalho de IA.
- **O que valida:** alterar `loadOptimizeDeckContext` para receber `userId` e
  consultar `decks` com `id + user_id` ou uma regra publica explicita; adicionar
  teste owner vs non-owner para `POST /ai/optimize`, incluindo caminho `202`
  async e caminho sync.
- **O que falsifica:** contrato documentado e testado provando que optimize
  aceita decks publicos/alheios por design, com autorizacao explicita e resposta
  que nao exponha lista privada.

#### P1 — Polling de jobs async aceita jobs sem `user_id`, embora o app trate `job_id` como recurso autenticado

- **Contrato app:** `app/lib/features/decks/providers/deck_provider_support_ai.dart:74`-`:87`
  trata `202` de optimize como job async e
  `app/lib/features/decks/providers/deck_provider_support_ai.dart:190`-`:194`
  faz polling em `/ai/optimize/jobs/$jobId`.
- **Store:** `server/lib/ai/optimize_job.dart:25`-`:30` permite criar jobs com
  `String? userId`; `server/lib/ai/optimize_job.dart:47`-`:64` persiste
  `user_id` nullable.
- **Handler:** `server/routes/ai/optimize/jobs/[id].dart:26` le o usuario
  autenticado, mas `server/routes/ai/optimize/jobs/[id].dart:39`-`:47` so
  bloqueia quando `job.userId != null && job.userId != userId`; jobs com
  `user_id = NULL` ficam legiveis para qualquer usuario com o `job_id`.
- **Por que e incoerente:** o app nao tem conceito de job publico; o endpoint
  fica sob `/ai` autenticado, mas a regra de acesso permite um estado nulo que
  enfraquece a fronteira de usuario.
- **Risco:** se algum job antigo, fallback em memoria, falha de contexto ou
  criacao interna persistir `user_id = NULL`, o resultado pode ser lido por outro
  usuario que conheca o ID.
- **O que valida:** exigir `userId` nao nulo em `OptimizeJobStore.create` para
  jobs user-facing e retornar 404 quando `job.userId == null` no endpoint de
  polling, exceto se houver rota interna separada.
- **O que falsifica:** prova de que nenhum job async app-facing pode ser criado
  sem usuario e teste de regressao cobrindo explicitamente a politica para
  `user_id = NULL`.

#### P2 — Endpoints experimentais de deck/AI usam `deck_id` autenticado sem ownership e nao tem consumidor app provado

- **Endpoints:** `GET /decks/:id/simulate`, `POST /decks/:id/recommendations`,
  `POST /ai/simulate-matchup`, `POST /ai/weakness-analysis`.
- **Evidencia de rotas:**
  - `server/routes/decks/[id]/simulate/index.dart:13`-`:26` le cartas com
    `WHERE dc.deck_id = @deckId`, sem buscar `context.read<String>()` nem
    validar `decks.user_id`.
  - `server/routes/decks/[id]/recommendations/index.dart:16`-`:27` consulta
    `SELECT name, format, description FROM decks WHERE id = @deckId`, e
    `server/routes/decks/[id]/recommendations/index.dart:39`-`:58` le cartas
    por `dc.deck_id = @deckId`, tambem sem `user_id`.
  - `server/routes/ai/simulate-matchup/index.dart:24`-`:38` le
    `my_deck_id`/`opponent_deck_id` e chama `_getDeckData`; essa funcao em
    `server/routes/ai/simulate-matchup/index.dart:76`-`:103` usa
    `SELECT id, name, format FROM decks WHERE id = @id` e cartas por
    `dc.deck_id = @id`.
  - `server/routes/ai/weakness-analysis/index.dart:17`-`:35` aceita `deck_id`
    e consulta `SELECT name, format FROM decks WHERE id = @id`; as cartas sao
    lidas em `server/routes/ai/weakness-analysis/index.dart:42`-`:60` por
    `dc.deck_id = @id`.
- **Evidencia app/contrato:** `rg` nao encontrou chamadas desses endpoints em
  `app/lib`; `server/doc/API_CONTRACTS_AND_DATA_MAP.md:152`-`:153` e `:285`-`:286`
  marca os consumidores como `not proven`/experimentais.
- **Por que e incoerente:** essas rotas vivem em namespaces autenticados
  (`server/routes/decks/_middleware.dart:7`-`:8` e
  `server/routes/ai/_middleware.dart:16`-`:20`), mas nao aplicam a mesma regra
  de ownership dos endpoints de deck consumidos pelo app. Como o app ainda nao
  consome esses contratos, a incoerencia pode ficar invisivel ate alguem ligar a
  UI.
- **Risco:** ao serem reutilizados pelo app, podem expor estatisticas,
  recomendacoes ou listas derivadas de deck privado de outro usuario.
- **O que valida:** antes de expor no app, escopar `my_deck_id`/`deck_id` por
  `user_id` e definir regra separada para oponente publico/meta deck; adicionar
  teste non-owner para cada rota mantida.
- **O que falsifica:** decisao explicita de tornar esses endpoints internos ou
  remove-los da superficie app-facing, com contrato atualizado e sem chamadas em
  `app/lib`.

#### P2 — `/community/decks/following` e app-facing, mas esta acoplado a branch especial de rota dinamica

- **Contrato app:** `app/lib/features/social/providers/social_provider.dart:563`-`:584`
  chama `/community/decks/following?page=...&limit=20` e registra o endpoint
  como `/community/decks/following`.
- **Handler:** nao existe `server/routes/community/decks/following/index.dart`;
  `server/routes/community/decks/[id].dart:10`-`:12` trata
  `id == 'following'` como caso especial e desvia para `_getFollowingFeed`.
- **Por que e incoerente:** a URI consumida pelo app representa uma colecao/feed,
  mas esta implementada como valor magico dentro do handler de detalhe
  `/community/decks/:id`, que tambem atende `GET /community/decks/:id` e
  `POST /community/decks/:id`.
- **Risco:** manutencao futura pode alterar o handler de detalhe ou validacao de
  UUID de `:id` e quebrar o feed de seguidores sem tocar no provider social; a
  documentacao tambem fica menos rastreavel porque o arquivo fisico nao expressa
  o contrato app-facing.
- **O que valida:** criar rota dedicada
  `server/routes/community/decks/following/index.dart` ou teste de contrato que
  preserve explicitamente esse caso especial.
- **O que falsifica:** decisao documentada de manter o branch magico por
  compatibilidade, com teste cobrindo `GET /community/decks/following` e
  `GET /community/decks/:id` no mesmo arquivo.

### Suspeitas revalidadas e descartadas nesta rodada

- `direct_message` nao foi classificado como incoerente: o backend cria
  notificacoes com `type: 'direct_message'` e `referenceId` de conversa em
  `server/routes/conversations/[id]/messages.dart:206`-`:217`, enquanto o app
  navega para `/messages/$refId` em
  `app/lib/features/notifications/screens/notification_screen.dart:152`-`:154`
  e no push coordinator em
  `app/lib/core/services/realtime_notification_coordinator.dart:117`-`:119`.
- `GET /cards?set=...` nao foi classificado como incoerente:
  `app/lib/features/collection/screens/set_cards_screen.dart:126`-`:128` envia
  `set` e `dedupe=true`, e `server/routes/cards/index.dart:17`-`:23`,
  `:136`-`:140` normaliza e aplica `setFilter`.
- `POST /ai/rebuild` nao foi classificado como incoerente:
  `server/routes/ai/rebuild/index.dart:61`-`:78` escopa o deck por
  `id + user_id` antes de carregar cartas e criar draft para o usuario.

## Rodada focada anterior: Duplicated or similar logic
> Data: 2026-05-28 12:40 UTC
> Rotacao local Codex: `duplicated-or-similar-logic`

## Rodada focada: Duplicated or similar logic

Escopo desta rodada: somente logica duplicada ou similar. Nao foi executada
auditoria ampla de classes sem uso, funcoes nao chamadas, imports, ciclos,
tabelas PostgreSQL ou coerencia geral entre camadas.

### Limitacao da ferramenta

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado conforme
o protocolo, mas falhou antes de gerar relatorio valido porque o script ainda usa
`BASE = Path("/opt/data/workspace/mtgia")` e tentou criar
`/opt/data/workspace/mtgia/docs/hermes-analysis` no Mac local, encerrando com
`PermissionError: [Errno 13] Permission denied: '/opt/data'`.

Resultado: os achados abaixo foram produzidos por inspeção manual focada em
helpers com mesmo nome/intencao e trechos de resposta equivalentes, usando `rg`
e leitura direta dos arquivos. Nao foi inventada saida do auditor.

### Achados confirmados

#### P1 — Heuristicas semanticas de combo/engine/payoff/enabler/wincon divergem em dois classificadores

- **Simbolos:** `_looksLikeWincon`, `_looksLikeComboPiece`,
  `_looksLikeEngine`, `_looksLikePayoff`, `_looksLikeEnabler`.
- **Evidencia 1:** `server/lib/ai/functional_card_tags.dart:319`,
  `:323`, `:327`, `:331`, `:335` chama esses helpers para tags v1, e as
  definicoes em `server/lib/ai/functional_card_tags.dart:859`-`:906` usam
  `oracle` + `normalizedName`.
- **Evidencia 2:** `server/lib/ai/optimization_functional_roles.dart:113`-`:117`
  chama helpers com os mesmos nomes para `classifyOptimizationFunctionalRole`,
  e as definicoes em `server/lib/ai/optimization_functional_roles.dart:370`-`:397`
  usam apenas `oracle` e um conjunto diferente de padroes.
- **Por que parece duplicado/similar:** ambos os modulos tentam classificar os
  mesmos papeis semanticos de alto nivel, mas com heuristicas independentes.
  Exemplo: `functional_card_tags.dart` trata nomes conhecidos como
  `thassa's oracle`, `isochron scepter`, `dramatic reversal`, `blood artist`,
  `greaves` e `boots`; `optimization_functional_roles.dart` nao consulta nome
  da carta nesses helpers.
- **Risco:** uma carta pode aparecer como `combo_piece`, `engine`, `payoff`,
  `enabler` ou `wincon` na analise funcional e receber outro papel no pipeline
  de optimize, criando drift entre explicabilidade e decisao de swap.
- **O que valida:** extrair uma fonte compartilhada de sinais semanticos ou
  adicionar testes cruzados que provem que a divergencia entre tags v1 e role
  classifier e intencional.
- **O que falsifica:** documentacao/testes mostrando que os dois classificadores
  possuem contratos diferentes por design e que cartas sentinela relevantes
  continuam coerentes nos dois fluxos.

#### P2 — `getMainType` e `calculateCmc` duplicam montagem de resposta de deck privado e publico

- **Simbolos:** `getMainType`, `calculateCmc`.
- **Evidencia 1:** `server/routes/decks/[id]/index.dart:405`-`:436` define
  `getMainType` e `calculateCmc` dentro da rota de deck privado; o mesmo bloco
  usa esses helpers em `server/routes/decks/[id]/index.dart:452` e `:464` para
  `mainBoard` e `manaCurve`.
- **Evidencia 2:** `server/routes/community/decks/[id].dart:91`-`:117` define
  helpers equivalentes na rota de deck publico; o uso equivalente aparece em
  `server/routes/community/decks/[id].dart:133` e `:141`.
- **Por que parece duplicado/similar:** as duas rotas constroem agrupamento por
  tipo, curva de mana e distribuicao de cores a partir de `cardsList`, com regras
  praticamente iguais para tipo principal e CMC.
- **Risco:** correcao de regra de CMC/tipo pode ser aplicada em uma rota e
  esquecida na outra, fazendo o mesmo deck apresentar estatisticas diferentes
  quando visto pelo dono e pela comunidade.
- **O que valida:** mover estatisticas compartilhadas para um helper de resposta
  de deck e cobrir deck privado/publico com o mesmo conjunto de fixtures.
- **O que falsifica:** testes de contrato provando que as respostas devem divergir
  e que as duas implementacoes locais estao travadas por fixtures equivalentes.

#### P2 — `_isBasicLandName` aparece com quatro variantes no backend

- **Simbolo:** `_isBasicLandName` / `isBasicLandName`.
- **Evidencia 1:** `server/lib/ai/optimize_runtime_support.dart:285` expoe
  `isBasicLandName`, mas a regra privada em
  `server/lib/ai/optimize_runtime_support.dart:4184`-`:4197` compara nomes
  exatos com hifen para snow-covered lands.
- **Evidencia 2:** `server/lib/generated_deck_validation_service.dart:752`-`:764`
  aceita `startsWith('snow-covered ...')`.
- **Evidencia 3:** `server/lib/meta/meta_deck_reference_support.dart:890`-`:903`
  aceita snow lands com espaco (`snow covered plains`) em vez de hifen.
- **Evidencia 4:** `server/routes/ai/commander-reference/index.dart:621`-`:629`
  reconhece apenas as seis basics nao snow.
- **Por que parece duplicado/similar:** todos os trechos respondem a mesma
  pergunta de dominio ("este nome e terreno basico?"), mas normalizam e aceitam
  casos diferentes.
- **Risco:** validacao, optimize, referencia de meta e commander-reference podem
  discordar sobre snow-covered lands ou nomes normalizados, especialmente em
  fluxos de singleton/legality.
- **O que valida:** centralizar a regra em um utilitario de dominio e adaptar os
  chamadores para normalizacao unica.
- **O que falsifica:** testes por contexto mostrando que cada variante menor e
  exigida por contrato diferente, incluindo casos com `Wastes` e snow lands.

#### P2 — Boilerplate de `request_id` e `invalid_payload` repetido em rotas sociais

- **Simbolos:** `_requestId`, `_logInvalidPayload`.
- **Evidencia:** `_requestId` aparece com corpo equivalente em
  `server/routes/trades/index.dart:330`-`:336`,
  `server/routes/trades/[id]/messages.dart:228`-`:234`,
  `server/routes/conversations/[id]/messages.dart:247`-`:253`,
  `server/routes/trades/[id]/respond.dart:154`-`:160`,
  `server/routes/trades/[id]/status.dart:260`-`:266` e
  `server/routes/users/[id]/follow/index.dart:97`-`:103`.
- **Evidencia adicional:** `_logInvalidPayload` repete o padrao de ler usuario,
  montar log `[social_write] invalid_payload` e anexar `request_id` em
  `server/routes/trades/index.dart:338`-`:352`,
  `server/routes/trades/[id]/messages.dart:236`-`:252`,
  `server/routes/conversations/[id]/messages.dart:255`-`:271`,
  `server/routes/trades/[id]/respond.dart:162`-`:178` e
  `server/routes/trades/[id]/status.dart:268`-`:284`.
- **Por que parece duplicado/similar:** a responsabilidade e identica
  (extrair `RequestTrace` com fallback e padronizar log de payload invalido),
  variando apenas endpoint e id de recurso.
- **Risco:** mudancas futuras no formato de log, fallback de `x-request-id` ou
  sanitizacao de usuario podem ficar inconsistentes entre trades e conversas.
- **O que valida:** helper compartilhado para social write logging aceitando
  endpoint e campos extras, com testes unitarios pequenos.
- **O que falsifica:** decisao explicita de manter logs por rota para evitar
  dependencia compartilhada, com teste que confira formato equivalente.

### Suspeitas revalidadas e ajustadas nesta rodada

- A duplicacao direta entre `server/routes/ai/optimize/index.dart` e
  `server/lib/ai/optimize_runtime_support.dart` para
  `matchesFunctionalNeed`, `scoreOptimizeReplacementCandidate`,
  `shouldRetryOptimizeWithAiFallback`, `computeOptimizeStructuralRecoverySwapTarget`,
  `isOptimizeStructuralRecoveryScenario` e `resolveOptimizeArchetype` nao foi
  confirmada como corpo duplicado nesta rodada: a rota possui wrappers finos que
  delegam para `optimize_support` em `server/routes/ai/optimize/index.dart:56`-`:132`.
- Ainda ha duplicacao/similaridade real em `resolveOptimizeArchetype`:
  `server/lib/ai/optimize_runtime_support.dart:3369`-`:3389` e
  `server/lib/ai/deck_state_analysis.dart:573`-`:584` resolvem requested vs
  detected archetype com listas genericas diferentes (`goodstuff`/`unknown` em
  um lado; `general`/`tempo` em outro).

## Rodada focada anterior: PostgreSQL tables not used
> Data: 2026-05-28 12:33 UTC
> Rotacao local Codex: `postgresql-tables-not-used`

### Escopo da rodada anterior

Escopo desta rodada: somente tabelas PostgreSQL sem uso ou com uso incoerente.
Nao foi executada auditoria ampla de classes, funcoes, imports ou duplicacao.

### Limitacao da ferramenta

`python3 docs/hermes-analysis/scripts/structure_auditor.py` foi executado conforme
o protocolo, mas falhou antes de gerar relatorio valido porque o script ainda usa
`BASE = Path("/opt/data/workspace/mtgia")` e tentou criar
`/opt/data/workspace/mtgia/docs/hermes-analysis` no Mac local, encerrando com
`PermissionError: [Errno 13] Permission denied: '/opt/data'`.

Resultado: os dados abaixo foram produzidos por inspeção manual do schema e de
referencias SQL em `server/`, sem inventar saida do auditor.

### Achados confirmados

#### P2 — `deck_matchups` é write-only no produto atual

- **Tabela:** `deck_matchups`
- **Definicao:** `server/database_setup.sql:162`
- **Escrita confirmada:** `server/routes/ai/simulate-matchup/index.dart:360` faz
  `INSERT INTO deck_matchups (...) ON CONFLICT (...) DO UPDATE`.
- **Leitura/consumo encontrado:** nenhum `SELECT ... FROM deck_matchups` em
  `app/`, `server/lib/` ou `server/routes/`; `rg` encontrou apenas a escrita da
  rota, definicoes/migrations e scripts/audits.
- **Por que parece nao usada:** a rota `POST /ai/simulate-matchup` retorna o
  resultado calculado na propria chamada, mas o snapshot salvo em
  `deck_matchups.win_rate/notes` nao alimenta cache, historico, ranking, UI ou
  contrato app-facing. `server/doc/API_CONTRACTS_AND_DATA_MAP.md` tambem marca
  `POST /ai/simulate-matchup` com consumidor `not proven`.
- **O que valida:** adicionar ou localizar um consumidor real que leia
  `deck_matchups`, por exemplo historico/cached matchup, dashboard ou reuso na
  simulacao.
- **O que falsifica:** um `SELECT ... FROM deck_matchups` em rota/lib consumida
  pelo app ou por job operacional documentado.

#### P2 — `deck_weakness_reports` acumula registros sem fluxo de leitura

- **Tabela:** `deck_weakness_reports`
- **Definicao:** `server/database_setup.sql:363` e
  `server/bin/migrate_create_missing_tables.dart:97`
- **Escrita confirmada:** `server/routes/ai/weakness-analysis/index.dart:374`
  faz `INSERT INTO deck_weakness_reports (...) ON CONFLICT DO NOTHING`.
- **Leitura/consumo encontrado:** nenhum `SELECT ... FROM deck_weakness_reports`
  em `app/`, `server/lib/` ou `server/routes`; `rg` encontrou somente a escrita,
  definicoes/migrations e artefatos de auditoria.
- **Por que parece nao usada:** `POST /ai/weakness-analysis` calcula e devolve
  `weaknesses` na resposta imediata, mas o dado persistido nao e listado,
  reaberto, marcado como `addressed` ou usado em analise futura. O campo
  `addressed` existe no schema e nao possui fluxo de update no codigo auditado.
- **O que valida:** criar/identificar endpoint, job ou UI que leia relatórios
  persistidos e atualize `addressed` quando o usuario corrige a fraqueza.
- **O que falsifica:** uma leitura real da tabela fora de migration/audit/teste,
  ou decisao explicita de manter a tabela apenas como log bruto com retencao.

### Suspeitas revalidadas e descartadas nesta rodada

- `battle_simulations` nao foi classificada como nao usada: a rota
  `server/routes/ai/simulate/index.dart:206` insere simulacoes e
  `server/bin/ml_extract_features.dart:75` le `FROM battle_simulations` para
  extracao de features.
- `ai_user_preferences` nao foi classificada como nao usada:
  `server/lib/ai/optimize_runtime_support.dart:3910` le preferencias e
  `server/lib/ai/optimize_runtime_support.dart:3947` persiste preferencias.
- Tabelas ML auxiliares como `card_meta_insights`, `synergy_packages`,
  `archetype_patterns`, `ml_prompt_feedback`, `format_staples`,
  `ai_logs`, `ai_optimize_cache` e `activation_funnel_events` possuem
  referencias de leitura/escrita em rotas, libs ou jobs operacionais e nao foram
  tratadas como achados de "nao usadas" nesta rotacao.

## Historico gerado pelo auditor estrutural anterior

## Arquivos Mapeados
- `server/lib/`: 81 arquivos
- `server/routes/`: 86 arquivos
- **Total**: 167 arquivos

## Classes por Arquivo
- `AggressiveCandidateQualitySignal` → `server/lib/ai/optimize_runtime_support.dart`
- `AiGenerateJob` → `server/lib/ai_generate_job.dart`
- `AiGenerateJobStore` → `server/lib/ai_generate_job.dart`
- `AiGenerateOpenAiTimeoutSelection` → `server/lib/ai_generate_performance_support.dart`
- `AiLogService` → `server/lib/ai_log_service.dart`
- `ArchetypeCountersService` → `server/lib/archetype_counters_service.dart`
- `ArchetypePattern` → `server/lib/ml_knowledge_service.dart`
- `AuthService` → `server/lib/auth_service.dart`
- `BattleResult` → `server/lib/ai/battle_simulator.dart`
- `BattleSimulator` → `server/lib/ai/battle_simulator.dart`
- `BracketFilterDecision` → `server/lib/edh_bracket_policy.dart`
- `BracketPolicy` → `server/lib/edh_bracket_policy.dart`
- `BracketTagResult` → `server/lib/edh_bracket_policy.dart`
- `CandidateFunctionTag` → `server/lib/ai/candidate_quality_data_support.dart`
- `CandidateRoleScore` → `server/lib/ai/candidate_quality_data_support.dart`
- `CardInsight` → `server/lib/ml_knowledge_service.dart`
- `CardRecommendation` → `server/lib/ml_knowledge_service.dart`
- `CardResolutionDecision` → `server/lib/card_resolution_support.dart`
- `CardValidationService` → `server/lib/card_validation_service.dart`
- `ColorIdentityBackfillDecision` → `server/lib/mtg_data_integrity_support.dart`
- `CommanderReferenceArchetypeStatsLoadResult` → `server/lib/ai/commander_reference_card_stats_support.dart`
- `CommanderReferenceCardStat` → `server/lib/ai/commander_reference_card_stats_support.dart`
- `CommanderReferenceCardStatsLoadResult` → `server/lib/ai/commander_reference_card_stats_support.dart`
- `CommanderReferenceCardStatsResolution` → `server/lib/ai/commander_reference_card_stats_support.dart`
- `CommanderReferenceCommanderCardResolution` → `server/lib/ai/commander_reference_card_stats_support.dart`
- `CommanderReferenceCorpusPackages` → `server/lib/ai/commander_reference_deck_corpus_support.dart`
- `CommanderReferenceCorpusSummary` → `server/lib/ai/commander_reference_deck_corpus_support.dart`
- `CommanderReferenceDeckAnalysis` → `server/lib/ai/commander_reference_deck_corpus_support.dart`
- `CommanderReferenceDeckCardInput` → `server/lib/ai/commander_reference_deck_corpus_support.dart`
- `CommanderReferenceDeckCorpusGuidance` → `server/lib/ai/commander_reference_deck_corpus_support.dart`
- `CommanderReferenceDeckInput` → `server/lib/ai/commander_reference_deck_corpus_support.dart`
- `CommanderReferenceReadinessInputs` → `server/lib/ai/commander_reference_readiness_support.dart`
- `CommanderReferenceReadinessRuntimeProof` → `server/lib/ai/commander_reference_readiness_support.dart`
- `CommanderReferenceReadinessScorecard` → `server/lib/ai/commander_reference_readiness_support.dart`
- `CommanderShellMetadata` → `server/lib/meta/meta_deck_commander_shell_support.dart`
- `CompleteBuildAccumulator` → `server/lib/ai/optimize_complete_support.dart`
- `Database` → `server/lib/database.dart`
- `DeckArchetypeAnalyzer` → `server/routes/ai/optimize/index.dart`
- `DeckArchetypeAnalyzerCore` → `server/lib/ai/optimize_state_support.dart`
- `DeckOptimizationState` → `server/routes/ai/optimize/index.dart`
- `DeckOptimizationStateResult` → `server/lib/ai/optimize_state_support.dart`
- `DeckOptimizerService` → `server/lib/ai/otimizacao.dart`
- `DeckRulesException` → `server/lib/deck_rules_service.dart`
- `DeckRulesService` → `server/lib/deck_rules_service.dart`
- `DeckThemeProfile` → `server/routes/ai/optimize/index.dart`
- `DeckThemeProfileResult` → `server/lib/ai/optimize_state_support.dart`
- `DistributedRateLimiter` → `server/lib/distributed_rate_limiter.dart`
- `EdhTop16TournamentEntry` → `server/lib/meta/external_commander_deck_expansion_support.dart`
- `EdhrecAverageDeckCard` → `server/lib/ai/edhrec_service.dart`
- `EdhrecAverageDeckData` → `server/lib/ai/edhrec_service.dart`
- `EdhrecCard` → `server/lib/ai/edhrec_service.dart`
- `EdhrecCommanderData` → `server/lib/ai/edhrec_service.dart`
- `EdhrecService` → `server/lib/ai/edhrec_service.dart`
- `EndpointCache` → `server/lib/endpoint_cache.dart`
- `EndpointMetricSnapshot` → `server/lib/request_metrics_service.dart`
- `ExpandedDeckCard` → `server/lib/meta/external_commander_deck_expansion_support.dart`
- `ExpandedTopDeckDeck` → `server/lib/meta/external_commander_deck_expansion_support.dart`
- `ExternalCommanderMetaCandidate` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `ExternalCommanderMetaCandidateIllegalCard` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `ExternalCommanderMetaCandidateLegalityEvidence` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `ExternalCommanderMetaCandidateLegalityRepository` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `ExternalCommanderMetaCandidateUnresolvedCard` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `ExternalCommanderMetaCandidateValidationResult` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `ExternalCommanderMetaControlledSourcePolicy` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `ExternalCommanderMetaEligibilityBatch` → `server/lib/meta/external_commander_meta_operational_runner_support.dart`
- `ExternalCommanderMetaEligibilityDecision` → `server/lib/meta/external_commander_meta_operational_runner_support.dart`
- `ExternalCommanderMetaImportConfig` → `server/lib/meta/external_commander_meta_import_support.dart`
- `ExternalCommanderMetaOperationalConfig` → `server/lib/meta/external_commander_meta_operational_runner_support.dart`
- `ExternalCommanderMetaPersistencePlan` → `server/lib/meta/external_commander_meta_import_support.dart`
- `ExternalCommanderMetaPromotionConfig` → `server/lib/meta/external_commander_meta_promotion_support.dart`
- `ExternalCommanderMetaPromotionInsertPlan` → `server/lib/meta/external_commander_meta_promotion_support.dart`
- `ExternalCommanderMetaPromotionIssue` → `server/lib/meta/external_commander_meta_promotion_support.dart`
- `ExternalCommanderMetaPromotionPlan` → `server/lib/meta/external_commander_meta_promotion_support.dart`
- `ExternalCommanderMetaPromotionResult` → `server/lib/meta/external_commander_meta_promotion_support.dart`
- `ExternalCommanderMetaPromotionSnapshot` → `server/lib/meta/external_commander_meta_promotion_support.dart`
- `ExternalCommanderMetaStagingConfig` → `server/lib/meta/external_commander_meta_staging_support.dart`
- `ExternalCommanderMetaStagingPlan` → `server/lib/meta/external_commander_meta_staging_support.dart`
- `ExternalCommanderMetaValidationIssue` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `FormatStaplesService` → `server/lib/ai/format_staples_service.dart`
- `FunctionalCardTag` → `server/lib/ai/functional_card_tags.dart`
- `FunctionalDeckSummary` → `server/lib/ai/functional_card_tags.dart`
- `FunctionalReport` → `server/lib/ai/optimization_validator.dart`
- `GameAction` → `server/lib/ai/battle_simulator.dart`
- `GameCard` → `server/lib/ai/battle_simulator.dart`
- `GeneratedDeckRepository` → `server/lib/generated_deck_validation_service.dart`
- `GeneratedDeckValidationResult` → `server/lib/generated_deck_validation_service.dart`
- `GeneratedDeckValidationService` → `server/lib/generated_deck_validation_service.dart`
- `GoldfishResult` → `server/lib/ai/goldfish_simulator.dart`
- `GoldfishSimulator` → `server/lib/ai/goldfish_simulator.dart`
- `HateCardsService` → `server/lib/ai/hate_cards_service.dart`
- `ImportListParseResult` → `server/lib/import_list_service.dart`
- `InternalAiRequestToken` → `server/lib/internal_ai_request_token.dart`
- `Log` → `server/lib/logger.dart`
- `MLContext` → `server/lib/ml_knowledge_service.dart`
- `MLKnowledgeService` → `server/lib/ml_knowledge_service.dart`
- `Magic` → `server/routes/ai/generate/index.dart`
- `ManaAnalysis` → `server/routes/decks/[id]/analysis/index.dart`
- `MarketMoversCache` → `server/lib/market_movers.dart`
- `MatchupAnalyzer` → `server/lib/ai/goldfish_simulator.dart`
- `MatchupResult` → `server/lib/ai/goldfish_simulator.dart`
- `MetaDeckAnalyticsContext` → `server/lib/meta/meta_deck_analytics_support.dart`
- `MetaDeckFormatDescriptor` → `server/lib/meta/meta_deck_format_support.dart`
- `MetaDeckReferenceCandidate` → `server/lib/meta/meta_deck_reference_support.dart`
- `MetaDeckReferenceQueryParts` → `server/lib/meta/meta_deck_reference_support.dart`
- `MetaDeckReferenceSelectionResult` → `server/lib/meta/meta_deck_reference_support.dart`
- `MonteCarloComparison` → `server/lib/ai/optimization_validator.dart`
- `MtgTop8EventDeckRow` → `server/lib/meta/mtgtop8_meta_support.dart`
- `MulliganReport` → `server/lib/ai/optimization_validator.dart`
- `NotificationService` → `server/lib/notification_service.dart`
- `OpenAiRuntimeConfig` → `server/lib/openai_runtime_config.dart`
- `OptimizationSemanticV2EnforcementDecision` → `server/lib/ai/optimization_functional_roles.dart`
- `OptimizationSwapGateResult` → `server/lib/ai/optimization_quality_gate.dart`
- `OptimizationValidator` → `server/lib/ai/optimization_validator.dart`
- `OptimizeDeckContextData` → `server/lib/ai/optimize_request_support.dart`
- `OptimizeDeckContextException` → `server/lib/ai/optimize_request_support.dart`
- `OptimizeIntensityConfig` → `server/lib/ai/optimize_runtime_support.dart`
- `OptimizeJob` → `server/lib/ai/optimize_job.dart`
- `OptimizeJobStore` → `server/lib/ai/optimize_job.dart`
- `OptimizeStageTelemetry` → `server/lib/ai/optimize_stage_telemetry.dart`
- `ParsedMetaDeckCardEntry` → `server/lib/meta/meta_deck_card_list_support.dart`
- `ParsedMetaDeckCardList` → `server/lib/meta/meta_deck_card_list_support.dart`
- `PlanService` → `server/lib/plan_service.dart`
- `PlayerState` → `server/lib/ai/battle_simulator.dart`
- `PostgresExternalCommanderMetaCandidateLegalityRepository` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `PostgresGeneratedDeckRepository` → `server/lib/generated_deck_validation_service.dart`
- `PushNotificationService` → `server/lib/push_notification_service.dart`
- `RateLimiter` → `server/lib/rate_limit_middleware.dart`
- `RebuildException` → `server/lib/ai/rebuild_guided_service.dart`
- `RebuildGuidedService` → `server/lib/ai/rebuild_guided_service.dart`
- `RebuildResult` → `server/lib/ai/rebuild_guided_service.dart`
- `RebuildScopeDecision` → `server/lib/ai/rebuild_guided_service.dart`
- `RebuildTargetProfile` → `server/lib/ai/rebuild_guided_service.dart`
- `ReferenceGeneratedCardsIdentityFilterResult` → `server/lib/ai/commander_reference_generate_fallback_support.dart`
- `ReferenceGeneratedDeckEvaluation` → `server/lib/ai/commander_reference_card_stats_support.dart`
- `RequestMetricsService` → `server/lib/request_metrics_service.dart`
- `RequestTrace` → `server/lib/request_trace.dart`
- `SemanticCardAnalysisV2` → `server/lib/ai/functional_card_tags.dart`
- `SwapFunctionalAnalysis` → `server/lib/ai/optimization_validator.dart`
- `SynergyEngine` → `server/lib/ai/sinergia.dart`
- `SynergyPackage` → `server/lib/ml_knowledge_service.dart`
- `ThemeCheck` → `server/lib/ai/theme_contextual_rules_service.dart`
- `ThemeContextualRule` → `server/lib/ai/theme_contextual_rules_service.dart`
- `ThemeContextualRulesService` → `server/lib/ai/theme_contextual_rules_service.dart`
- `ThemeValidationResult` → `server/lib/ai/theme_contextual_rules_service.dart`
- `UserPlanSnapshot` → `server/lib/plan_service.dart`
- `ValidationReport` → `server/lib/ai/optimization_validator.dart`
- `_CacheItem` → `server/lib/endpoint_cache.dart`
- `_CachedAverageDeckResult` → `server/lib/ai/edhrec_service.dart`
- `_CachedResult` → `server/lib/ai/edhrec_service.dart`
- `_CardData` → `server/lib/deck_rules_service.dart`
- `_DeckMetrics` → `server/routes/decks/[id]/ai-analysis/index.dart`
- `_DeckStats` → `server/lib/ai/goldfish_simulator.dart`
- `_EndpointMetricBucket` → `server/lib/request_metrics_service.dart`
- `_ExternalCommanderMetaParsedCardEntry` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `_InfluencedCardInsight` → `server/lib/meta/meta_deck_reference_support.dart`
- `_LandTrimContext` → `server/lib/ai/optimization_quality_gate.dart`
- `_MarketMoversCacheEntry` → `server/lib/market_movers.dart`
- `_ParsedTradeItems` → `server/routes/trades/index.dart`
- `_PasswordPreparation` → `server/lib/auth_service.dart`
- `_PlayDecision` → `server/lib/ai/battle_simulator.dart`
- `_PromotionDeckProfile` → `server/lib/meta/external_commander_meta_promotion_support.dart`
- `_QueryBuilder` → `server/routes/cards/index.dart`
- `_RankedMetaDeckReference` → `server/lib/meta/meta_deck_reference_support.dart`
- `_ResolvedExternalCommanderMetaCardEntry` → `server/lib/meta/external_commander_meta_candidate_support.dart`
- `_SimCard` → `server/routes/decks/[id]/simulate/index.dart`
- `_TelemetryQuery` → `server/routes/ai/optimize/telemetry/index.dart`
- `_WeightedCard` → `server/lib/ai/rebuild_guided_service.dart`

## Imports Potencialmente Quebrados
- Nenhum import quebrado encontrado

## Funções Públicas (primeiros 5 por arquivo)
- `server/lib/ai/aggressive_candidate_meta_signal_support.dart` (194 linhas): isCommanderCandidateLegalityAllowed, isExternalCommanderCandidateTrusted, confidenceLabel, scoreAggressiveMetaSignal, bracketScopeForMetaSignal
- `server/lib/ai/battle_simulator.dart` (880 linhas): resetForNewTurn, toString, drawCard, shuffle
- `server/lib/ai/candidate_quality_data_support.dart` (693 linhas): normalizeCandidateQualityKey, normalizeCandidateQualityRole, add, inferCandidateBudgetTier, inferCandidateBracketScope
- `server/lib/ai/commander_reference_card_stats_support.dart` (1368 linhas): normalizeCommanderReferenceCardName, buildCommanderReferenceCardStatsPrompt, buildCommanderReferenceArchetypeStatsPrompt
- `server/lib/ai/commander_reference_deck_corpus_support.dart` (1490 linhas): normalizeCommanderReferenceDeckText, buildReferenceDeckKey, buildCommanderReferenceDeckCorpusPrompt, shouldUseCompactCommanderReferenceCorpusPrompt, classifyCommanderReferenceDeckCardRole
- `server/lib/ai/commander_reference_generate_fallback_support.dart` (370 linhas): addCard
- `server/lib/ai/commander_reference_profile_support.dart` (543 linhas): normalizeCommanderReferenceName, normalizeCommanderReferenceConfidence, isLoreholdCommanderReferenceCandidate, isReferenceProfileConfidenceUsable, commanderReferenceConfidenceRank
- `server/lib/ai/commander_reference_readiness_support.dart` (495 linhas): block
- `server/lib/ai/deck_state_analysis.dart` (586 linhas): detectArchetype, addReason, resolveOptimizeArchetype
- `server/lib/ai/edhrec_service.dart` (466 linhas): cleanupCache, isHighSynergy, toString
- `server/lib/ai/functional_card_tags.dart` (1053 linhas): count, add, normalizeFunctionalCardName
- `server/lib/ai/hate_cards_service.dart` (160 linhas): generatePromptContext
- `server/lib/ai/optimization_functional_roles.dart` (399 linhas): looksLikeOptimizationBoardWipeText, looksLikeOptimizationRampText, looksLikeOptimizationLandSearchText, classifyOptimizationFunctionalRole
- `server/lib/ai/optimize_complete_support.dart` (1560 linhas): calculateCompleteMaxBasicAdditions, addUnique, rebalanceCompleteDeckForLandDeficit, mergeUniqueSpells
- `server/lib/ai/optimize_deck_support.dart` (180 linhas): commanderSignalsSpellslinger, commanderSignalsArtifacts, commanderSignalsEnchantments
- `server/lib/ai/optimize_runtime_support.dart` (4198 linhas): normalizeOptimizeReasoning, resolveOptimizeMode, clampRequestedSwapCount, shouldUseAsyncOptimizeExecutor, isBasicLandName
- `server/lib/ai/optimize_stage_telemetry.dart` (85 linhas): start, stop, logSummary
- `server/lib/ai/optimize_state_support.dart` (982 linhas): detectArchetype, assessManaBase, assessManaCurve, calculateConfidence, addReason
- `server/lib/ai/otimizacao.dart` (1046 linhas): addAll
- `server/lib/ai/rebuild_guided_service.dart` (1748 linhas): addWeight, toString
- `server/lib/ai/theme_contextual_rules_service.dart` (109 linhas): archetypeToTheme
- `server/lib/ai_generate_performance_support.dart` (197 linhas): normalizeAiGeneratePrompt, normalizeAiGenerateFormat, normalizeAiGenerateBracket, normalizeAiGenerateCommanderName, buildAiGenerateCacheKey
- `server/lib/ai_log_service.dart` (236 linhas): Function
- `server/lib/auth_middleware.dart` (85 linhas): getUserId
- `server/lib/auth_service.dart` (297 linhas): hashPassword, verifyPassword, normalizeEmail, normalizeUsername, generateToken
- `server/lib/card_validation_service.dart` (248 linhas): sanitizeCardName
- `server/lib/color_identity.dart` (61 linhas): isWithinCommanderIdentity
- `server/lib/deck_rules_service.dart` (503 linhas): toString
- `server/lib/endpoint_cache.dart` (37 linhas): set, clearExpired
- `server/lib/generated_deck_validation_service.dart` (819 linhas): addLookupName
- `server/lib/health_readiness_support.dart` (21 linhas): readinessStatusCode
- `server/lib/import_card_lookup_service.dart` (451 linhas): cleanImportLookupKey, foldImportLookupKey, canonicalizeImportLookupName, normalizeLocalizedImportName
- `server/lib/internal_ai_request_token.dart` (22 linhas): matches
- `server/lib/log_sanitizer.dart` (59 linhas): sanitizeLogMessage
- `server/lib/logger.dart` (40 linhas): d, print, i, print, w
- `server/lib/market_movers.dart` (240 linhas): normalizeMarketMoversLimit, toInt, set
- `server/lib/meta/external_commander_deck_expansion_support.dart` (638 linhas): edhTop16TournamentIdFromUrl
- `server/lib/meta/external_commander_meta_candidate_support.dart` (1333 linhas): addName, normalizeCommanderMetaFormat, normalizeExternalCommanderMetaValidationStatus, canonicalizeExternalCommanderMetaSourceName
- `server/lib/meta/external_commander_meta_promotion_support.dart` (748 linhas): buildMetaDeckCardListFingerprint
- `server/lib/meta/meta_deck_analytics_support.dart` (85 linhas): classifyMetaDeckSource
- `server/lib/meta/meta_deck_card_list_support.dart` (93 linhas): parseMetaDeckCardList, isCommanderMetaFormat, normalizeMetaDeckCardName
- `server/lib/meta/meta_deck_commander_shell_support.dart` (356 linhas): metaDeckNeedsCommanderShellRefresh, inferCommanderStrategyArchetypeFromCardNames
- `server/lib/meta/meta_deck_format_support.dart` (181 linhas): normalizeCommanderMetaScope, commanderMetaScopeLabel, metaDeckAnalyticsFormatKey
- `server/lib/meta/meta_deck_reference_support.dart` (938 linhas): buildMetaDeckEvidenceText
- `server/lib/meta/mtgtop8_meta_support.dart` (166 linhas): extractMtgTop8Placement, resolveMtgTop8Url
- `server/lib/ml_knowledge_service.dart` (502 linhas): generatePromptContext
- `server/lib/notification_service.dart` (140 linhas): createFromActorDeferred, Function
- `server/lib/observability.dart` (249 linhas): isSentryEnabled
- `server/lib/openai_runtime_config.dart` (150 linhas): shouldUseFallbackForInvalidApiKey, modelFor, intFor
- `server/lib/rate_limit_middleware.dart` (402 linhas): Function, Function, buildClientIdentifierFromHeaders, isAllowed, cleanup
- `server/lib/request_metrics_service.dart` (107 linhas): add, record
- `server/lib/request_trace.dart` (58 linhas): generateRequestId, resolveRequestId
- `server/lib/sets_catalog_contract.dart` (61 linhas): safeSetCatalogLimit, safeSetCatalogPage, resolveSetStatus
- `server/routes/ai/optimize/index.dart` (3498 linhas): resolveOptimizeArchetype, shouldRetryOptimizeWithAiFallback, matchesFunctionalNeed, scoreOptimizeReplacementCandidate, isOptimizeStructuralRecoveryScenario
- `server/routes/community/decks/[id].dart` (428 linhas): getMainType, calculateCmc
- `server/routes/decks/[id]/index.dart` (538 linhas): getMainType, calculateCmc

## Tabelas PostgreSQL Referenciadas no Código
- `LATERAL`: 9 referências
- `activation_funnel_events`: 1 referências
- `ai_generate_jobs`: 1 referências
- `ai_logs`: 3 referências
- `ai_optimize_cache`: 1 referências
- `ai_optimize_fallback_telemetry`: 3 referências
- `ai_optimize_jobs`: 1 referências
- `ai_user_preferences`: 1 referências
- `archetype_counters`: 2 referências
- `archetype_patterns`: 2 referências
- `canonical_sets`: 2 referências
- `card_function_tags`: 4 referências
- `card_legalities`: 12 referências
- `card_localized_names`: 1 referências
- `card_meta_insights`: 6 referências
- `card_role_scores`: 2 referências
- `card_semantic_tags_v2`: 5 referências
- `cards`: 45 referências
- `checks`: 1 referências
- `commander_card_synergy`: 2 referências
- `commander_reference_card_stats`: 1 referências
- `commander_reference_deck_analysis`: 1 referências
- `commander_reference_deck_cards`: 1 referências
- `commander_reference_decks`: 1 referências
- `commander_reference_profiles`: 5 referências
- `conversations`: 4 referências
- `current_trade`: 2 referências
- `deck_cards`: 25 referências
- `deck_usage`: 1 referências
- `decks`: 24 referências
- `direct_messages`: 4 referências
- `external_commander_meta_candidates`: 1 referências
- `filtered_sets`: 1 referências
- `follower_counts`: 2 referências
- `following_counts`: 2 referências
- `format_staples`: 1 referências
- `have`: 1 referências
- `history`: 2 referências
- `information_schema`: 6 referências
- `input_names`: 1 referências
- `inserted`: 1 referências
- `jsonb_to_recordset`: 1 referências
- `latest`: 1 referências
- `meta_decks`: 6 referências
- `ml_learning_state`: 1 referências
- `ml_prompt_feedback`: 1 referências
- `movers`: 1 referências
- `notifications`: 2 referências
- `offer`: 1 referências
- `offering_items`: 1 referências
- `optimization_analysis_logs`: 2 referências
- `optimize_candidate_quality_summary`: 1 referências
- `optimize_rejection_penalties`: 2 referências
- `owned`: 1 referências
- `paged_users`: 1 referências
- `penalty_rows`: 1 referências
- `previous_prices`: 1 referências
- `price_history`: 3 referências
- `public_deck_counts`: 2 referências
- `rate_limit_events`: 1 referências
- `regexp_matches`: 9 referências
- `requested`: 1 referências
- `requesting_items`: 1 referências
- `role_rows`: 1 referências
- `rules`: 1 referências
- `sets`: 6 referências
- `sync_state`: 1 referências
- `synergy_packages`: 2 referências
- `synergy_rows`: 1 referências
- `tag_rows`: 1 referências
- `theme_contextual_rules`: 1 referências
- `today_prices`: 1 referências
- `totals`: 1 referências
- `trade_items`: 2 referências
- `trade_messages`: 3 referências
- `trade_offers`: 6 referências
- `trade_status_history`: 3 referências
- `unnest`: 2 referências
- `updated`: 2 referências
- `user_binder_items`: 6 referências
- `user_follows`: 6 referências
- `user_plans`: 1 referências
- `users`: 19 referências
- `validation`: 2 referências
- `want`: 1 referências

## Problemas Estruturais Identificados
- `server/lib/ai/candidate_quality_data_support.dart` referencia `semantic_tags_v2` mas não faz INSERT/UPDATE
- `server/lib/ai/functional_card_tags.dart` referencia `semantic_tags_v2` mas não faz INSERT/UPDATE
- `server/lib/ai/optimization_functional_roles.dart` referencia `semantic_tags_v2` mas não faz INSERT/UPDATE
- `server/lib/ai/optimize_request_support.dart` referencia `semantic_tags_v2` mas não faz INSERT/UPDATE
- `server/routes/ai/optimize/index.dart` referencia `semantic_tags_v2` mas não faz INSERT/UPDATE
- `server/routes/decks/[id]/analysis/index.dart` referencia `semantic_tags_v2` mas não faz INSERT/UPDATE
- Classe `AggressiveCandidateQualitySignal` é definida mas potencialmente não é usada em outros arquivos
- Classe `AiGenerateOpenAiTimeoutSelection` é definida mas potencialmente não é usada em outros arquivos
- Classe `ArchetypePattern` é definida mas potencialmente não é usada em outros arquivos
- Classe `BattleResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `BracketFilterDecision` é definida mas potencialmente não é usada em outros arquivos
- Classe `BracketTagResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `CandidateFunctionTag` é definida mas potencialmente não é usada em outros arquivos
- Classe `CandidateRoleScore` é definida mas potencialmente não é usada em outros arquivos
- Classe `CardRecommendation` é definida mas potencialmente não é usada em outros arquivos
- Classe `ColorIdentityBackfillDecision` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceArchetypeStatsLoadResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceCardStatsLoadResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceCardStatsResolution` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceCommanderCardResolution` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceCorpusPackages` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceCorpusSummary` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceDeckAnalysis` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceDeckCardInput` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceDeckInput` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceReadinessInputs` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceReadinessRuntimeProof` é definida mas potencialmente não é usada em outros arquivos
- Classe `CommanderReferenceReadinessScorecard` é definida mas potencialmente não é usada em outros arquivos
- Classe `EdhTop16TournamentEntry` é definida mas potencialmente não é usada em outros arquivos
- Classe `EdhrecAverageDeckCard` é definida mas potencialmente não é usada em outros arquivos
- Classe `EdhrecCard` é definida mas potencialmente não é usada em outros arquivos
- Classe `EndpointMetricSnapshot` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExpandedDeckCard` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExpandedTopDeckDeck` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaCandidateIllegalCard` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaCandidateLegalityEvidence` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaCandidateLegalityRepository` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaCandidateUnresolvedCard` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaEligibilityBatch` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaEligibilityDecision` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaImportConfig` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaOperationalConfig` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaPersistencePlan` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaPromotionConfig` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaPromotionInsertPlan` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaPromotionIssue` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaPromotionPlan` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaPromotionResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaPromotionSnapshot` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaStagingConfig` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaStagingPlan` é definida mas potencialmente não é usada em outros arquivos
- Classe `ExternalCommanderMetaValidationIssue` é definida mas potencialmente não é usada em outros arquivos
- Classe `FunctionalReport` é definida mas potencialmente não é usada em outros arquivos
- Classe `GameAction` é definida mas potencialmente não é usada em outros arquivos
- Classe `GameCard` é definida mas potencialmente não é usada em outros arquivos
- Classe `GeneratedDeckValidationResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `ImportListParseResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `MLContext` é definida mas potencialmente não é usada em outros arquivos
- Classe `ManaAnalysis` é definida mas potencialmente não é usada em outros arquivos
- Classe `MatchupResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `MetaDeckAnalyticsContext` é definida mas potencialmente não é usada em outros arquivos
- Classe `MetaDeckReferenceQueryParts` é definida mas potencialmente não é usada em outros arquivos
- Classe `MonteCarloComparison` é definida mas potencialmente não é usada em outros arquivos
- Classe `MulliganReport` é definida mas potencialmente não é usada em outros arquivos
- Classe `OptimizationSemanticV2EnforcementDecision` é definida mas potencialmente não é usada em outros arquivos
- Classe `OptimizationSwapGateResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `ParsedMetaDeckCardEntry` é definida mas potencialmente não é usada em outros arquivos
- Classe `PlayerState` é definida mas potencialmente não é usada em outros arquivos
- Classe `PostgresExternalCommanderMetaCandidateLegalityRepository` é definida mas potencialmente não é usada em outros arquivos
- Classe `RebuildResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `RebuildScopeDecision` é definida mas potencialmente não é usada em outros arquivos
- Classe `RebuildTargetProfile` é definida mas potencialmente não é usada em outros arquivos
- Classe `ReferenceGeneratedCardsIdentityFilterResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `ReferenceGeneratedDeckEvaluation` é definida mas potencialmente não é usada em outros arquivos
- Classe `SwapFunctionalAnalysis` é definida mas potencialmente não é usada em outros arquivos
- Classe `SynergyPackage` é definida mas potencialmente não é usada em outros arquivos
- Classe `ThemeCheck` é definida mas potencialmente não é usada em outros arquivos
- Classe `UserPlanSnapshot` é definida mas potencialmente não é usada em outros arquivos
- Classe `_CacheItem` é definida mas potencialmente não é usada em outros arquivos
- Classe `_CachedAverageDeckResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `_CachedResult` é definida mas potencialmente não é usada em outros arquivos
- Classe `_CardData` é definida mas potencialmente não é usada em outros arquivos
- Classe `_DeckMetrics` é definida mas potencialmente não é usada em outros arquivos
- Classe `_DeckStats` é definida mas potencialmente não é usada em outros arquivos
- Classe `_EndpointMetricBucket` é definida mas potencialmente não é usada em outros arquivos
- Classe `_ExternalCommanderMetaParsedCardEntry` é definida mas potencialmente não é usada em outros arquivos
- Classe `_InfluencedCardInsight` é definida mas potencialmente não é usada em outros arquivos
- Classe `_LandTrimContext` é definida mas potencialmente não é usada em outros arquivos
- Classe `_MarketMoversCacheEntry` é definida mas potencialmente não é usada em outros arquivos
- Classe `_ParsedTradeItems` é definida mas potencialmente não é usada em outros arquivos
- Classe `_PasswordPreparation` é definida mas potencialmente não é usada em outros arquivos
- Classe `_PlayDecision` é definida mas potencialmente não é usada em outros arquivos
- Classe `_PromotionDeckProfile` é definida mas potencialmente não é usada em outros arquivos
- Classe `_QueryBuilder` é definida mas potencialmente não é usada em outros arquivos
- Classe `_RankedMetaDeckReference` é definida mas potencialmente não é usada em outros arquivos
- Classe `_ResolvedExternalCommanderMetaCardEntry` é definida mas potencialmente não é usada em outros arquivos
- Classe `_SimCard` é definida mas potencialmente não é usada em outros arquivos
- Classe `_TelemetryQuery` é definida mas potencialmente não é usada em outros arquivos
- Classe `_WeightedCard` é definida mas potencialmente não é usada em outros arquivos
- Arquivos grandes (>500 linhas):
  - `server/lib/ai/optimize_runtime_support.dart`: 4198 linhas
  - `server/routes/ai/optimize/index.dart`: 3498 linhas
  - `server/lib/ai/rebuild_guided_service.dart`: 1748 linhas
  - `server/routes/ai/generate/index.dart`: 1656 linhas
  - `server/lib/ai/optimize_complete_support.dart`: 1560 linhas
  - `server/lib/ai/commander_reference_deck_corpus_support.dart`: 1490 linhas
  - `server/lib/ai/commander_reference_card_stats_support.dart`: 1368 linhas
  - `server/lib/meta/external_commander_meta_candidate_support.dart`: 1333 linhas
  - `server/lib/ai/functional_card_tags.dart`: 1053 linhas
  - `server/lib/ai/otimizacao.dart`: 1046 linhas
  - `server/lib/ai/optimize_state_support.dart`: 982 linhas
  - `server/lib/meta/meta_deck_reference_support.dart`: 938 linhas
  - `server/lib/ai/optimization_validator.dart`: 891 linhas
  - `server/lib/ai/battle_simulator.dart`: 880 linhas
  - `server/lib/generated_deck_validation_service.dart`: 819 linhas
  - `server/lib/meta/external_commander_meta_promotion_support.dart`: 748 linhas
  - `server/lib/ai/candidate_quality_data_support.dart`: 693 linhas
  - `server/routes/cards/resolve/index.dart`: 691 linhas
  - `server/routes/trades/index.dart`: 649 linhas
  - `server/routes/ai/commander-reference/index.dart`: 641 linhas
  - `server/lib/meta/external_commander_deck_expansion_support.dart`: 638 linhas
  - `server/lib/ai/goldfish_simulator.dart`: 606 linhas
  - `server/lib/ai/deck_state_analysis.dart`: 586 linhas
  - `server/routes/ai/archetypes/index.dart`: 564 linhas
  - `server/routes/decks/[id]/recommendations/index.dart`: 560 linhas
  - `server/routes/decks/[id]/ai-analysis/index.dart`: 552 linhas
  - `server/lib/ai/commander_reference_profile_support.dart`: 543 linhas
  - `server/routes/decks/[id]/index.dart`: 538 linhas
  - `server/routes/decks/[id]/analysis/index.dart`: 521 linhas
  - `server/lib/deck_rules_service.dart`: 503 linhas
  - `server/lib/ml_knowledge_service.dart`: 502 linhas
  - `server/lib/ai/optimization_quality_gate.dart`: 501 linhas
- Funções com nomes duplicados:
  - `Function` em: server/lib/ai_log_service.dart, server/lib/notification_service.dart, server/lib/rate_limit_middleware.dart, server/lib/rate_limit_middleware.dart, server/lib/rate_limit_middleware.dart
  - `_generateId` em: server/lib/ai/optimize_job.dart, server/lib/ai_generate_job.dart
  - `_getCmc` em: server/lib/ai/goldfish_simulator.dart, server/lib/ai/goldfish_simulator.dart, server/lib/ai/optimization_quality_gate.dart, server/lib/ai/optimization_validator.dart
  - `_hasResearchPayloadValue` em: server/lib/meta/external_commander_meta_candidate_support.dart, server/lib/meta/external_commander_meta_staging_support.dart
  - `_intValue` em: server/lib/ai/commander_reference_deck_corpus_support.dart, server/lib/ai/commander_reference_readiness_support.dart
  - `_isBasicLandName` em: server/lib/ai/optimize_runtime_support.dart, server/lib/generated_deck_validation_service.dart, server/lib/meta/meta_deck_reference_support.dart, server/routes/ai/commander-reference/index.dart
  - `_isLand` em: server/lib/ai/goldfish_simulator.dart, server/lib/ai/optimization_validator.dart
  - `_logInvalidPayload` em: server/routes/conversations/[id]/messages.dart, server/routes/trades/[id]/messages.dart, server/routes/trades/[id]/respond.dart, server/routes/trades/[id]/status.dart, server/routes/trades/index.dart
  - `_looksLikeComboPiece` em: server/lib/ai/functional_card_tags.dart, server/lib/ai/optimization_functional_roles.dart
  - `_looksLikeEnabler` em: server/lib/ai/functional_card_tags.dart, server/lib/ai/optimization_functional_roles.dart
  - `_looksLikeEngine` em: server/lib/ai/functional_card_tags.dart, server/lib/ai/optimization_functional_roles.dart
  - `_looksLikePayoff` em: server/lib/ai/functional_card_tags.dart, server/lib/ai/optimization_functional_roles.dart
  - `_looksLikeWincon` em: server/lib/ai/functional_card_tags.dart, server/lib/ai/optimization_functional_roles.dart
  - `_readInt` em: server/lib/meta/external_commander_meta_operational_runner_support.dart, server/lib/meta/external_commander_meta_staging_support.dart
  - `_readListLength` em: server/lib/meta/external_commander_meta_operational_runner_support.dart, server/lib/meta/external_commander_meta_staging_support.dart
  - `_requestId` em: server/routes/conversations/[id]/messages.dart, server/routes/trades/[id]/messages.dart, server/routes/trades/[id]/respond.dart, server/routes/trades/[id]/status.dart, server/routes/trades/index.dart, server/routes/users/[id]/follow/index.dart
  - `_responseTimeSql` em: server/routes/trades/[id]/index.dart, server/routes/trades/index.dart
  - `_shippingTimeSql` em: server/routes/trades/[id]/index.dart, server/routes/trades/index.dart
  - `_sourceCount` em: server/lib/ai/commander_reference_card_stats_support.dart, server/lib/ai/commander_reference_profile_support.dart
  - `_stableDeckSeed` em: server/lib/ai/goldfish_simulator.dart, server/lib/ai/optimization_validator.dart
  - `_stableHash` em: server/lib/ai/optimize_runtime_support.dart, server/routes/ai/archetypes/index.dart
  - `_sumQuantities` em: server/lib/meta/meta_deck_card_list_support.dart, server/routes/import/index.dart, server/routes/import/to-deck/index.dart
  - `_toInt` em: server/lib/ai/optimize_runtime_support.dart, server/routes/ai/ml-status/index.dart, server/routes/ai/optimize/telemetry/index.dart, server/routes/binder/[id]/index.dart, server/routes/community/marketplace/index.dart, server/routes/trades/[id]/index.dart, server/routes/trades/index.dart
  - `_trustStatsSql` em: server/routes/trades/[id]/index.dart, server/routes/trades/index.dart
  - `_validateCondition` em: server/routes/decks/[id]/cards/index.dart, server/routes/decks/[id]/cards/set/index.dart
  - `add` em: server/lib/ai/candidate_quality_data_support.dart, server/lib/ai/functional_card_tags.dart, server/lib/request_metrics_service.dart
  - `addReason` em: server/lib/ai/deck_state_analysis.dart, server/lib/ai/optimize_state_support.dart
  - `addUnique` em: server/lib/ai/optimize_complete_support.dart, server/lib/ai/optimize_runtime_support.dart
  - `calculateCmc` em: server/routes/community/decks/[id].dart, server/routes/decks/[id]/index.dart
  - `computeOptimizeStructuralRecoverySwapTarget` em: server/lib/ai/optimize_runtime_support.dart, server/routes/ai/optimize/index.dart
  - `detectArchetype` em: server/lib/ai/deck_state_analysis.dart, server/lib/ai/optimize_state_support.dart
  - `generatePromptContext` em: server/lib/ai/hate_cards_service.dart, server/lib/ml_knowledge_service.dart
  - `getMainType` em: server/routes/community/decks/[id].dart, server/routes/decks/[id]/index.dart
  - `isOptimizeStructuralRecoveryScenario` em: server/lib/ai/optimize_runtime_support.dart, server/routes/ai/optimize/index.dart
  - `matchesFunctionalNeed` em: server/lib/ai/optimize_runtime_support.dart, server/routes/ai/optimize/index.dart
  - `print` em: server/lib/logger.dart, server/lib/logger.dart, server/lib/logger.dart, server/lib/logger.dart
  - `resolveOptimizeArchetype` em: server/lib/ai/deck_state_analysis.dart, server/lib/ai/optimize_runtime_support.dart, server/routes/ai/optimize/index.dart
  - `scoreOptimizeReplacementCandidate` em: server/lib/ai/optimize_runtime_support.dart, server/routes/ai/optimize/index.dart
  - `set` em: server/lib/endpoint_cache.dart, server/lib/market_movers.dart
  - `shouldRetryOptimizeWithAiFallback` em: server/lib/ai/optimize_runtime_support.dart, server/routes/ai/optimize/index.dart
  - `toString` em: server/lib/ai/battle_simulator.dart, server/lib/ai/edhrec_service.dart, server/lib/ai/rebuild_guided_service.dart, server/lib/deck_rules_service.dart

## Gaps Conhecidos (manual)
- `card_function_tags` / `card_semantic_tags_v2`: fluxo core de analysis/optimize ja usa multi-tags; rotas experimentais de recommendations/weakness ainda precisam convergir antes de promocao app-facing
- `card_deck_profiles`: 670 perfis, mas `filterUnsafeOptimizeSwapsByCardData` não consulta
- `semantic_layer_v2`: default `disabled`, modo `partial` existe e tem teste de contrato; habilitar apenas em ambiente controlado com scorecard
- `archetype_patterns`: 69 registros, não validado contra código

## Rodada focada: Semantica de cartas no runtime
> Data: 2026-05-28 13:41 UTC
> Rotacao local Codex: `local-manaloom-card-semantics-audit`

Escopo desta rodada: nomes de cartas hardcoded em codigo de produto/runtime,
drift entre `functional_tags`, `semantic_tags_v2` e classificacao funcional do
optimize, e pontos onde utilidade ainda e inferida por nome ou por regra
unidimensional. A leitura priorizou `server/lib`, `server/routes` e `app/lib`.
Testes, docs, exemplos de UI, corpus e artefatos foram usados apenas para
separar fixtures permitidas de logica runtime.

### Setup executado

- `pwd` confirmou o root do repositorio:
  `/Users/desenvolvimentomobile/.manaloom-agents/mtgia`.
- `git fetch --all --prune`: sem saida relevante.
- `git checkout codex/hermes-analysis-docs`: branch ja ativo e atualizado.
- `git pull --ff-only origin codex/hermes-analysis-docs`: `Already up to date`.
- `git status --short`: limpo antes das edicoes documentais desta rodada.

### Revalidacao apos ajustes na `master`
> Data: 2026-05-28 15:26 UTC
> Comando: `manaloom-fix-verifier-copilot.sh --target master`
> Commit verificado: `00437690` (`origin/master`)

Resultado: **PARTIAL**. Os pontos abaixo foram removidos do backlog ativo desta
rodada porque o verificador confirmou correcao na `master`:

- `summarizeFunctionalTagsForDeck` agora usa/documenta a prioridade
  `functional_tags_then_semantic_v2_then_heuristic`.
- O optimize preserva conjuntos de roles via `optimizationFunctionalRolesForCard`
  e calcula `role_delta` multi-role.
- Existem testes focados cobrindo semantic v2 e perda secundaria multi-tag.
- `API_CONTRACTS_AND_DATA_MAP.md` e `server/manual-de-instrucao.md` documentam
  prioridade semantica, multi-tags, diagnosticos de optimize e fallback policy.

Atualizacao Copilot 2026-05-28: `origin/master@65f30387` resolveu tambem as
politicas por nome restantes apontadas abaixo via
`server/lib/ai/commander_fallback_policy.dart`, alem de hardening owner-scoped
em `POST /ai/archetypes`.

Nota local 2026-05-29: esta conclusao historica nao se aplica ao checkout
`codex/hermes-analysis-docs@7014a2cc` auditado nesta rodada. A revalidacao local
nao encontrou `commander_fallback_policy.dart` e confirmou novamente politicas
por nome em runtime; ver a secao "Card semantics audit" no topo deste arquivo e
o plano atualizado em `PLANO_CORRECAO.md`.

Permanecem ativos somente os achados abaixo que nao foram marcados como
resolvidos por esta atualizacao.

#### P1 - Politicas por nome ainda nao estao totalmente centralizadas/versionadas

- **Status historico em `origin/master@65f30387`: RESOLVIDO para as listas
  apontadas pelo verificador.**
- **Status local em `codex/hermes-analysis-docs@7014a2cc`: REABERTO.** Fallbacks
  universais de Commander, premium lands, high-power e candidate-quality premium
  nao estao centralizados em `commander_fallback_policy.dart` neste checkout.
- **Evidencia revalidada:** o verificador encontrou scoring/listas como
  `premiumLandNames` em `server/lib/ai/optimize_runtime_support.dart` e conjuntos
  premium/high-power em `server/lib/ai/candidate_quality_data_support.dart`.
- **Por que ainda e risco:** parte da decisao de utilidade/bracket/score segue
  embutida no codigo em vez de estar em uma policy versionada, tabela/config ou
  dados semanticos auditaveis.
- **O que valida:** mover as excecoes restantes para modulo/tabela/config de
  policy com versao, `source`, `reason`, `bracket_scope` e testes focados.
- **O que falsifica:** documentacao e testes que declarem explicitamente essas
  excecoes como politica de produto intencional e versionada.

#### P2 - Endpoints experimentais de recomendacao/weakness seguem legacy, mas nao sao fluxo app-facing confirmado

- **Simbolos:** `POST /decks/:id/recommendations`,
  `POST /ai/weakness-analysis`.
- **Status:** `PASS with caveat` na revalidacao. Os contratos os marcam como
  experimentais/not-proven/advisory e nao foi encontrado consumidor direto no
  app; a pendencia permanece apenas antes de exposicao futura ou promocao a
  fluxo de produto.
- **Evidencia 1:** `server/routes/decks/[id]/recommendations/index.dart:110`-`:130`
  conta ramp/draw/removal/wipes/protection por `oracle_text` local, sem
  `functional_tags` ou `semantic_tags_v2`. Quando faltam terrenos Commander,
  `server/routes/decks/[id]/recommendations/index.dart:262`-`:267` adiciona
  `Command Tower` diretamente.
- **Evidencia 2:** `server/routes/ai/weakness-analysis/index.dart:114`-`:163`
  tambem conta categorias por `oracle_text`, `type_line`, `cmc` e dois nomes
  (`teferi's protection`, `heroic intervention`), sem v2. As recomendacoes sao
  listas fixas de nomes em `server/routes/ai/weakness-analysis/index.dart:206`-`:248`
  e `server/routes/ai/weakness-analysis/index.dart:266`-`:285`.
- **Evidencia 3:** `server/doc/API_CONTRACTS_AND_DATA_MAP.md:152` e
  `server/doc/API_CONTRACTS_AND_DATA_MAP.md:286` marcam esses endpoints como
  experimentais/not proven para consumo app atual.
- **Por que ainda e risco:** se essas rotas forem ligadas ao app, o usuario recebera
  recomendacoes que parecem produto runtime, mas ainda sao one-dimensional e
  parcialmente name-based, sem a camada semantica v2 que o fluxo core ja tenta
  carregar.
- **O que valida:** antes de expor no app, reusar `summarizeFunctionalTagsForDeck`
  e candidate-quality/semantic data, e trocar listas fixas por query filtrada por
  role, legalidade, identidade de cor, bracket e disponibilidade.
- **O que falsifica:** decisao explicita de manter essas rotas apenas como
  demos/diagnosticos internos, com contrato removido da superficie app-facing.

### Ocorrencias permitidas ou descartadas

- Testes, fixtures, corpus e artefatos com nomes como `Sol Ring`,
  `Command Tower`, `Thassa's Oracle`, `Isochron Scepter` e `Blood Artist` foram
  tratados como permitidos quando servem de fixture ou prova de regressao
  (`server/test/**`, `server/test/artifacts/**`).
- Exemplos de UX/contrato tambem foram tratados como permitidos:
  placeholders de import em `app/lib/features/decks/screens/deck_import_screen.dart`,
  `app/lib/features/decks/widgets/deck_import_list_dialog.dart`,
  mensagens de erro em `server/routes/import/**`, comentarios de
  `/cards/resolve/batch` e comentarios de limpeza de nome em
  `server/lib/card_validation_service.dart`.
- `server/lib/ai/prompt.md` e `server/lib/ai/prompt_complete.md` contem nomes
  em texto de prompt. Isso e runtime prompt material, mas nao foi classificado
  nesta rodada como decisao direta por nome porque a decisao final ainda passa
  por validacao/quality gate. O risco relevante ficou documentado nos pontos em
  que o codigo escolhe, ranqueia ou classifica nomes diretamente.
