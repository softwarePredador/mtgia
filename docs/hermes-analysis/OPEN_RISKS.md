# Hermes Analysis: Open Risks

> Riscos abertos do ManaLoom. Atualizado em 2026-05-26.
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
- `server/routes/ai/optimize/index.dart` (~2745 linhas) — rota gigante
- `server/lib/ai/optimize_runtime_support.dart` (~2842 linhas) — logica densa
- `deck_details_screen.dart` (~1445 linhas) — caindo, mas ainda grande
- `deck_provider.dart` (~899 linhas) — residual, quase orquestracao pura

### Sentry mobile nao verificado
`SENTRY_MOBILE_TOOLCHAIN_BLOCKED=1` — compilacao nativa falha timeout (120s+).
Tentativas em macOS, Android emulator e iOS wireless falharam por toolchain, nao por codigo.
O smoke encerra classificavelmente, mas sem event_id confirmado.

### Cobertura de testes do app abaixo do ideal
25 telas mapeadas no fluxo core. Auditoria de codigo confirmou:
- `community_screen.dart` (1725 linhas, 40 classes) — sem teste de widget
- `trade_detail_screen.dart` (1479 linhas) — sem teste de widget
- `binder_screen.dart` (1628 linhas) — sem teste de widget
- `marketplace_screen.dart` (851 linhas) — sem teste de widget
- `binder_item_editor.dart` (1025 linhas) — sem teste de widget
- `profile_screen.dart` (588 linhas) — refatorado, sem golden test
Sem cobertura ampla, regressao visual ou logica pode passar despercebida.

### Telas criticas do fluxo core ainda grandes
Auditoria confirmou tamanhos reais no codigo:
- `deck_details_screen.dart` (1705 linhas) — ainda concentra AppBar + 3 abas + acoes
- `community_screen.dart` (1725 linhas, 40 classes) — 4 tabs + sub-tab aninhada
- `trade_detail_screen.dart` (1479 linhas) — timeline, chat, status, itens, trust
- `binder_screen.dart` (1628 linhas) — listas, editor, filtros
- `deck_optimize_sheet_widgets.dart` (1215 linhas) — sheet de otimizacao
- `deck_analysis_tab.dart` (1632 linhas) — functional tags + graficos

### AppBar community_screen com fontWeight 800 foge do tema Onda 6
`community_screen.dart` define `titleTextStyle` com `w800` manualmente, enquanto o AppBarTheme define `w700`. Diferenca visual intencional ou residuo de refatoracao.

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

### Arquivos criticos cresceram alem do ultimo mapa
Validacao local em 2026-05-25 indicou tamanhos maiores que os registrados no
mapa anterior:
- `server/routes/ai/optimize/index.dart`: 3495 linhas
- `server/lib/ai/optimize_runtime_support.dart`: 4197 linhas
- `app/lib/features/decks/providers/deck_provider.dart`: 1226 linhas

Impacto: gargalos de manutencao maiores do que o digest inicial sugeria.

Recomendacao: atualizar o Technical Map e tratar a quebra modular como P1 quando
voltar ao core de IA/decks.

### x-request-id sem correlacao ponta a ponta
Backend ja gera e propaga. Script de validacao existe (`validate_request_id_ready.sh`).
A correlacao mobile → backend em device real NAO foi confirmada.

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

## Regras de monitoramento

- Toda mudanca no core de decks precisa manter `flutter analyze` + `flutter test` verde
- Toda mudanca em contrato app-facing precisa atualizar `API_CONTRACTS_AND_DATA_MAP.md`
- Toda mudanca de UI runtime precisa consultar `UI_TEST_SURFACE_MAP.md`
- O corpus de resolucao Commander (19/19 passando) e gate recorrente
