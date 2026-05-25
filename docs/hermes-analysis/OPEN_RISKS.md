# Hermes Analysis: Open Risks

> Riscos abertos do ManaLoom. Atualizado em 2026-05-25.
> Este arquivo nao substitui os documentos canonicos; resume a leitura operacional atual.

## P0 — Bloqueante

### Ambiente de validacao do agente
Hermes consegue ler e auditar o repositorio, mas o container NAO possui Dart ou Flutter SDK.
Impacto: `dart test`, `flutter analyze` e `flutter test` nao podem ser executados aqui.
Recomendacoes de codigo sem validacao local devem ser marcadas explicitamente.

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
25 telas mapeadas no fluxo core. Poucas tem teste de widget/smoke dedicado.
A maior protecao esta em widgets especificos e no backend.
Sem cobertura ampla, regressao visual ou logica pode passar despercebida.

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