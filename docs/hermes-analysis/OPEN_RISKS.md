# Hermes Analysis: Open Risks

> Riscos abertos do ManaLoom. Atualizado em 2026-05-29T20:15Z (E2E logic audit).
> Este arquivo nao substitui os documentos canonicos; resume a leitura operacional atual.

## P0 — Bloqueante

### Ambiente de validacao do agente Hermes
Hermes consegue ler e auditar o repositorio. O container Hermes agora possui
Dart/Flutter para checks Linux (`dart test`, `flutter analyze`), mas continua
sem iPhone Simulator, Android emulator, camera/scanner/OCR e prova visual real.

Impacto: validacoes Linux sao possiveis, mas qualquer evidencia de layout/runtime
mobile precisa continuar sendo provada no Mac local com iPhone Simulator ou
dispositivo fisico, conforme o caso.

Observacao: esta limitacao nao se aplica automaticamente ao workspace local
Codex/desenvolvedor, onde Flutter/Dart podem estar disponiveis e devem ser usados
para prova viva quando possivel.

### Credenciais QA nao podem ficar versionadas
Historicamente a memoria continha email/senha/user ID de QA. Mesmo sendo uma
conta de teste, isso nao deve ficar em branch publica.

Impacto: risco operacional e habito ruim de documentar segredo/identificador
sensivel em Markdown.

Recomendacao: manter apenas referencias sanitizadas e mover credenciais para
cofre/local env/handoff privado.

## P1 — Alto

### Gargalos de manutencao
Validacao em `origin/master` 771c9318 (2026-05-28) confirmou tamanhos atuais:
- `server/routes/ai/optimize/index.dart` (3495 linhas) — rota gigante
- `server/lib/ai/optimize_runtime_support.dart` (4197 linhas) — logica densa
- `app/lib/features/home/life_counter_screen.dart` (6400 linhas) — tela/engine nativa grande
- `app/lib/features/home/lotus/lotus_visual_skin.dart` (1991 linhas) — CSS Lotus/WebView proprio
- `app/lib/features/decks/screens/deck_details_screen.dart` (1705 linhas) — caindo, mas ainda grande
- `app/lib/features/decks/providers/deck_provider.dart` (1226 linhas) — residual/orquestracao voltou a crescer

### Sentry mobile nao verificado
`SENTRY_MOBILE_TOOLCHAIN_BLOCKED=1` — compilacao nativa falha timeout (120s+).
Tentativas em macOS, Android emulator e iOS wireless falharam por toolchain, nao por codigo.
O smoke encerra classificavelmente, mas sem event_id confirmado.

### Cobertura de testes do app abaixo do ideal
25 telas mapeadas no fluxo core. Auditoria de codigo em `origin/master` 771c9318 confirmou que a cobertura melhorou em alguns pontos, mas ainda nao e ampla:
- `community_screen.dart` (1729 linhas) — sem teste de widget unitario; ha runtime em `profile_community_runtime_test.dart`
- `trade_detail_screen.dart` (1479 linhas) — cobertura de widget parcial em `trade_confirmation_flow_test.dart`, sem baseline amplo de layout/status/chat
- `binder_screen.dart` (1628 linhas) — sem teste de widget dedicado para `BinderTabContent`
- `marketplace_screen.dart` (566 linhas) — ja tem `marketplace_screen_overflow_test.dart` cobrindo overflow e estados loading/error/empty
- `binder_item_editor.dart` (1025 linhas) — sem teste de widget
- `profile_screen.dart` (590 linhas) — teste funcional existe, mas segue sem golden/baseline visual
- `chat_screen.dart` — sem teste widget dedicado; falha de carregamento pode cair no empty state e falha de envio limpa o rascunho antes de sucesso
- `market_screen.dart` / `MarketProvider` — estados loading/erro/empty/needs-data/cache/refresh sem cobertura deterministica dedicada
Sem cobertura ampla, regressao visual ou logica pode passar despercebida.

### Telas criticas do fluxo core ainda grandes
Auditoria confirmou tamanhos reais no codigo:
- `deck_details_screen.dart` (1705 linhas) — ainda concentra AppBar + 3 abas + acoes
- `community_screen.dart` (1729 linhas) — 4 tabs + sub-tab aninhada
- `trade_detail_screen.dart` (1479 linhas) — timeline, chat, status, itens, trust
- `binder_screen.dart` (1628 linhas) — listas, editor, filtros
- `deck_optimize_sheet_widgets.dart` (1215 linhas) — sheet de otimizacao
- `deck_analysis_tab.dart` (1632 linhas) — functional tags + graficos

### AppBar community_screen com fontWeight 800 foge do tema Onda 6
**RESOLVIDO** pelo commit `91885194` (Polish secondary shell headers).
O titleTextStyle foi alterado de w800 para w700, alinhando com AppBarTheme.
Movido para riscos resolvidos na tabela abaixo.

### life_counter_screen.dart ainda tem cores hardcoded no Flutter nativo
Auditoria confirmou muitas referencias `Color(0x...)` e `Colors.` no
`life_counter_screen.dart`. O Lotus WebView recebeu skin premium por jogador em
`lotus_visual_skin.dart`, mas o arquivo Flutter nativo segue fora do contrato
estrito de tokens.

Impacto: risco de deriva visual se a tela nativa for usada/alterada sem passar
pelo skin Lotus.

Recomendacao: separar o risco em duas trilhas:
- Lotus skin: validar por prova viva de overlays, settings, card search e mesa.
- Flutter nativo: extrair tokens locais/semanticos ou documentar excecao de cores
  de jogo.

### Life Counter Lotus: pendencias da task de perfeicao
Task formal `docs/TASK_LIFE_COUNTER_PERFEICAO_2026-03-26.md` define 8 gaps.
Auditoria em `master` confirmou que a task ainda nao esta fechada, mas o status
nao e mais "todos abertos": os commits `9a2bb38b` e `ca0c8d52` adicionaram
prova viva para mesa 4p com cores por jogador, history, settings e card search.

Status granular:
- **OPEN:** geometria fina 2p/3p/4p, centragem otica, hub central, DICE overlay,
  PLAYERS overlay, commander damage, motion final e side-by-side final.
- **PARTIAL_PROVEN:** mesa 4p com controles visiveis, cores por jogador,
  history overlay, settings overlay e card search overlay com CSS premium
  e smoke tests dedicados.
- **NEEDS_BENCHMARK_COMPARISON:** todos os itens ainda precisam de comparacao
  lado a lado com `dddddd/` antes de marcar a task como DONE.

### Arquivos criticos continuam grandes
Validacao em `origin/master` 771c9318 (2026-05-28) confirmou os maiores gargalos
registrados no Technical Map:
- `server/routes/ai/optimize/index.dart`: 3495 linhas
- `server/lib/ai/optimize_runtime_support.dart`: 4197 linhas
- `app/lib/features/home/life_counter_screen.dart`: 6400 linhas
- `app/lib/features/home/lotus/lotus_visual_skin.dart`: 1991 linhas
- `app/lib/features/decks/providers/deck_provider.dart`: 1226 linhas

Impacto: gargalos de manutencao permanecem relevantes; Lotus visual skin cresceu
alem do mapa anterior e deve ser tratado como superficie visual propria.

Recomendacao: manter Technical Map sincronizado e tratar quebra modular como P1
quando voltar ao core de IA/decks/Lotus.

### x-request-id sem correlacao ponta a ponta
Backend ja gera e propaga. Script de validacao existe (`validate_request_id_ready.sh`).
A correlacao mobile → backend em device real NAO foi confirmada.

### POST /ai/optimize sem escopo de ownership no carregamento do deck
Auditoria em `origin/master` 771c9318 confirmou que `server/routes/ai/optimize/index.dart`
le `userId`, mas chama `loadOptimizeDeckContext` sem passa-lo; em
`server/lib/ai/optimize_request_support.dart`, a query de deck usa apenas
`WHERE id = @id` e as cartas usam apenas `WHERE dc.deck_id = @id`. Rotas de
mutacao de deck usam o padrao mais seguro `WHERE id = @deckId AND user_id = @userId`.

Impacto: usuario autenticado pode potencialmente disparar otimizacao/analise de
um deck que nao possui se obtiver o UUID, expondo composicao privada e gastando
trabalho de IA.

Recomendacao: passar `userId` para o loader, escopar a query por dono ou regra
publica explicita, rejeitar antes de criar job async e adicionar testes owner vs
non-owner.

### Jobs async de optimize aceitam leitura de job com `user_id = NULL`
`server/routes/ai/optimize/jobs/[id].dart` so bloqueia quando `job.userId != null &&
job.userId != userId`; jobs nulos ficam legiveis para qualquer usuario com o ID.
Como a criacao async recebe `userId` nullable, o contrato deve exigir owner nao
nulo para jobs user-facing ou retornar 404 para jobs sem dono salvo excecao interna.

### Semantic Layer v2 partial tem helper testado, mas nao rota `POST /ai/optimize`
A rota le `SEMANTIC_LAYER_V2_OPTIMIZE_ENFORCEMENT` e tem branch 422
`OPTIMIZE_SEMANTIC_V2_REJECTED`, mas a cobertura atual exercita helpers em
`optimization_validator_test.dart`; nao ha teste de rota/response shape para
`blocked_by_semantic_v2` em modo partial. Antes de habilitar partial fora de
staging/controlado, adicionar teste de integracao de rota.

### Filler de optimize/complete aplica bracket com `currentDeckCards: const []`
Alguns loaders em `optimize_runtime_support.dart` filtram candidatos por bracket
sem considerar o deck atual e `loadGuaranteedNonBasicFillers` faz fallback com
`bracket: null` quando falta preencher. Isso pode reduzir determinismo de budget
de bracket em complete/rebuild/top-up. Threadar estado atual/virtual para todos
os loaders e registrar fallback sem bracket quando intencional.

### Fonte de verdade e deriva documental
`docs/CONTEXTO_PRODUTO_ATUAL.md` foi atualizado pela ultima vez em 2026-03-25.
`server/manual-de-instrucao.md` tem entradas ate 2026-05-21 — ha 2 meses de decisoes nao refletidas na fonte de verdade oficial.
Doc desatualizado pode levar a decisoes baseadas em prioridades antigas.

## P2 — Medio

### IA e resultados experimentais
- `/ai/optimize`, `/ai/generate`, `/ai/rebuild` sao experimentais
- Resultados de IA nao sao prova rigida de poder/jogabilidade
- Erros 500 podem surgir em casos extremos (cartas sem dados, comandantes sem profile)

### Scanner/OCR deferido
Scanner, camera, OCR e MLKit fora do escopo non-scanner.
Plugins nativos tem warnings de build no simulador iOS (MLImage.framework).
Quando scanner voltar ao escopo, precisara de validacao em device fisico.

### GET /community/decks/following como caso especial
Implementado como branch magico em `server/routes/community/decks/[id].dart`
(trata `id == 'following'` como feed de seguidores).
Risco de manutencao: recomendacao documentada e criar rota dedicada.

### Golden tests requerem baseline versionada
O novo golden test do hero da home (`home_hero_sma135m.png`) adiciona risco de falha
em CI se o viewport, DPR ou fontes mudarem. A baseline precisa ser atualizada
manualmente com `--update-goldens` e revisao visual do PNG gerado.

### Premium Visual System pode mascarar bugs funcionais
Os commits recentes (3eebd0f6, 63 arquivos) focam quase exclusivamente em
refinamento visual. O risco e que problemas funcionais no core de decks passem
despercebidos enquanto o time foca em aparencia premium. Monitorar se `flutter analyze`
e `flutter test` continuam verdes apos mudancas visuais.

### Payloads grandes podem afetar performance mobile
Deck details, optimize response e public deck detail incluem 100 cartas + analise.
Performance em device de baixo custo (SM A135M) precisa ser monitorada.

### Rate limit Scryfall para sync multi-idioma
Sync de nomes localizados para todos os idiomas precisa ser parcelado.
Apenas `pt` foi sincronizado (38.594 aliases); `es, fr, de, it, ja, ko, ru, zhs, zht` pendentes.

## P3 — Baixo

### Dependencias nativas pesadas
Firebase Core/Messaging/Performance + MLKit + Camera + Sentry aumentam build time e superficie de erro nativo.
Problemas de compilacao em novas plataformas ou versoes do Flutter sao provaveis.

### Trust/price sparse data
Marketplace trust so existe para usuarios com historico de trades.
Price history pode ser vazio para cartas sem dados. A UI precisa tolerar estados parciais.

### Legacy shapes na API
- `GET /decks` retorna array JSON bruto (vs `{data, page, limit, total}` das rotas novas)
- `GET /ready` deprecado em favor de `/health/ready`

## Riscos Resolvidos (para referencia)

| Risco | Resolucao | Data |
|-------|-----------|------|
| Onboarding perdia `format` | Main.dart agora propaga formato | 2026-03-23 |
| Home sugeria "nenhum deck" antes do fetch | HomeScreen agora busca ao abrir | 2026-03-23 |
| Score do OptimizationValidator oscilava | Seed estavel implementada | 2026-03-23 |
| `server/dart test` falhava sem servidor | RUN_INTEGRATION_TESTS opt-in | 2026-03-23 |
| AppBar community_screen com fontWeight 800 foge do tema Onda 6 | Commit 91885194 corrigiu w800 para w700 | 2026-05-26 |

## Regras de monitoramento

- Toda mudanca no core de decks precisa manter `flutter analyze` + `flutter test` verde
- Toda mudanca em contrato app-facing precisa atualizar `API_CONTRACTS_AND_DATA_MAP.md`
- Toda mudanca de UI runtime precisa consultar `UI_TEST_SURFACE_MAP.md`
- O corpus de resolucao Commander (19/19 passando) e gate recorrente

## Riscos E2E Pipeline (2026-05-29)

### P1 — Drift entre classificadores funcionais
**Local:** `server/lib/ai/optimization_functional_roles.dart:55-58`
`classifyOptimizationFunctionalRole()` não consulta `functional_tags` persistidas como fonte primária. Usa apenas `semantic_tags_v2` + heurísticas de oracle text. O `summarizeFunctionalTagsForDeck` (usado no deck analysis) prioriza `functional_tags → semantic_v2 → heuristic`. Isso causa inconsistência: deck analysis diz `draw`, optimize diz `utility` para a mesma carta.
**Impacto:** Trocas sugeridas pela IA podem remover cartas que o Analysis considerava essenciais.
**Recomendação:** Alinhar `classifyOptimizationFunctionalRole()` para consultar `functional_tags` persistidas.

### P1 — Doc incompleta do flag `SEMANTIC_LAYER_V2_EXPANDED_CRITICAL_ROLES`
**Local:** `server/doc/API_CONTRACTS_AND_DATA_MAP.md` (pós-3f7d784f)
A documentação menciona apenas `true` como valor truthy, mas o código aceita `1/true/yes/on/expanded`.
**Impacto:** Configuradores não descobrem todos os valores válidos sem ler código.
**Recomendação:** Listar todos os valores aceitos na documentação.

### P2 — `looksLikePayoff` frágil para payoffs de dano direto
**Local:** `server/lib/ai/optimization_functional_roles.dart:388-392`
Não detecta "whenever a creature enters, deal N damage" (Impact Tremors, Guttersnipe).
**Impacto:** Payoffs de dano direto nunca são classificados como `payoff`.
**Recomendação:** Adicionar padrões para "deals *damage* to any target" combinado com triggers ETB/cast.
