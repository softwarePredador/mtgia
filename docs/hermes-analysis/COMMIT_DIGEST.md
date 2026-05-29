# Hermes Analysis: Commit Digest

> Acompanhamento continuo dos commits do ManaLoom.
> Atualizado em 2026-05-29T20:15Z (E2E logic coherence audit — 3f7d784f guard expanded roles behind flag).

## Estado atual

- Branch observada: `master`
- HEAD anterior: `c3531df7` (Cover semantic v2 low confidence fallback)
- HEAD atual: **`3f7d784f`** (Guard expanded semantic roles behind flag)
- SHA publicado em producao: **`c98153d655b3660cb69e0ae6d019df6f07dc7967`** (`/health`, 2026-05-27T18:25Z)
- Branch de analise: `codex/hermes-analysis-docs`
- Backend publicado: `https://evolution-cartinhas.8ktevp.easypanel.host`
- SHA publicado confirmado em producao: **`c98153d655b3660cb69e0ae6d019df6f07dc7967`** (`/health`, 2026-05-27T18:25Z)

## Novos commits nesta rodada (2026-05-29)

### `3f7d784f` — Guard expanded semantic roles behind flag (2026-05-29, atual)
- **7 arquivos**, código + doc + testes.
- **Tipo: CODE/FEATURE-FLAG** — Introduz `resolveSemanticV2ExpandedCriticalRoles()` e propaga `expandedCriticalRoles` em todo o pipeline de enforcement. Default seguro: expanded roles ficam review-only. Flag `SEMANTIC_LAYER_V2_EXPANDED_CRITICAL_ROLES` (valores: `1/true/yes/on/expanded`) ativa bloqueio.
- **Validação:** `dart analyze lib/ai/optimization_functional_roles.dart lib/ai/functional_card_tags.dart lib/edh_bracket_policy.dart routes/ai/optimize/index.dart` — sem erros. `dart test` 599/599 PASS.
- **Status Hermes:** P1 encontrada — doc no `API_CONTRACTS_AND_DATA_MAP.md` não lista todos os valores truthy aceitos. P1 encontrada — `classifyOptimizationFunctionalRole` não consulta `functional_tags` persistidas.

### `c3531df7` — Cover semantic v2 low confidence fallback (2026-05-29)
- **1 arquivo**, teste.
- **Tipo: QA/GUARDRAIL** — adiciona teste provando que `semantic_tags_v2` com baixa confiança e role incorreta e ignorado, caindo para heuristica de `oracle_text`.
- **Validação:** `dart analyze bin lib routes test`, `dart test` em `server/` com 613 testes, `dart test test/optimization_quality_gate_test.dart -r expanded`, `git diff --check`, scan simples de secrets, smoke Hermes pos-push.
- **Status Hermes:** reclassifica o achado P2 de fallback como comportamento ja implementado e agora coberto por teste.

### `a466adb6` — Harden deck simulation card ownership
- **2 arquivos**, rota + source guard.
- **Tipo: CODE/SECURITY** — `GET /decks/:id/simulate` agora reforca owner-scope tambem na query de `deck_cards`, via `JOIN decks d ON d.id = dc.deck_id` e `AND d.user_id = CAST(@userId AS uuid)`.
- **Validação:** `dart analyze bin lib routes test`, `dart test` em `server/` com 612 testes, `dart test test/experimental_deck_ai_authorization_source_test.dart -r expanded`, `git diff --check`, scan simples de secrets, smoke Hermes pos-push.
- **Status Hermes:** fecha a recomendacao P2 de defense-in-depth em `simulate/index.dart`.

### `1463732a` — Clarify payoff functional tag rules
- **2 arquivos**, codigo + testes.
- **Tipo: CODE/QA** — Refatora `_looksLikePayoff` para branches explicitos, removendo a fragilidade de precedencia apontada no `LOGIC_COHERENCE_REPORT_2026-05-29.md`.
- **Validação:** `dart analyze bin lib routes test`, `dart test` em `server/` com 612 testes, `dart test test/functional_card_tags_test.dart -r expanded`, `git diff --check`, scan simples de secrets, smoke Hermes pos-push.
- **Status Hermes:** fecha o achado P1 de payoff; `Impact Tremors` segue como payoff e `The One Ring` fica `draw+protection`, nao `payoff`.

### `dafffc1b` — Remove unused backend helper APIs
- **4 arquivos**, codigo + testes.
- **Tipo: CODE/HIGIENE** — Remove helpers publicos sem chamador runtime: `tryGetRequestId`, `normalizedCommanderReferenceCandidate`, `buildCandidateQualitySamplePoolSql` e `extractMtgTop8FormatCodeFromSourceUrl`.
- **Validação:** `dart analyze bin lib routes test`, `dart test` em `server/` com 612 testes, testes focados de request trace, Commander Reference, MTGTop8 e candidate quality, `git diff --check`, scan simples de secrets, smoke Hermes pos-push.
- **Status Hermes:** reduz a pendencia de "helpers publicos sem chamador"; `PerformanceService` permanece como API publica intencional de observabilidade mobile, nao como item para remocao automatica.

### `a830f9f3` — Make local test server wrapper analyzable
- **1 arquivo**, wrapper operacional.
- **Tipo: CODE/INFRA** — `server/bin/local_test_server.dart` deixou de importar `.dart_frog/server.dart` estaticamente e passou a executar o artefato gerado como processo filho.
- **Validação:** `dart analyze bin/local_test_server.dart`, smoke local em `PORT=18082`, shutdown por `SIGTERM`, backend analyze/test completo.

### `4913a733` — Expose optimize bracket diagnostics
- **1 arquivo**, **+XX linhas** (route diagnostics)
- **Tipo: CODE** — Expondo bracket policy diagnostics no response body

### `1aa4da71` — Enforce bracket state in optimize fillers
- **loadBroadCommanderNonLandFillers**: `currentDeckCards` passado em 3 chamadas que antes usavam `const []` — bracket policy agora via estado real do deck durante construção.

### `a018ee17` — Fix optimize authorization and chat error states
- **Auth**: `/ai/optimize` agora verifica `userId != null` antes de processar; `verifyOptimizeDeckAccess` chamado ANTES de `OptimizeJobStore.create`.
- **Chat**: `chat_screen.dart` — erro de send agora preserva texto no controller + mostra SnackBar.

### `cf225841` — Preserve semantic v2 multi-tags in optimize
- **functional_card_tags.dart**: `FunctionalDeckSummary` source priority mudou de `persisted_then_heuristic` para `functional_tags_then_semantic_v2_then_heuristic`.
- **`_looksLikePayoff`**: correção parcial — adicionado filtro `!oracle.contains('costs {')` e `!oracle.contains('costs {1} less')` mas com precedência de operadores frágil (ver P1 no LOGIC_COHERENCE_REPORT).

### `aa3ee1ba` — Centralize basic land detection
- **basic_land_utils.dart** (novo): 4 funções (`normalizeBasicLandName`, `isBasicLandName`, `isBasicLandTypeLine`, `isBasicLandCard`). Migrado em 6 arquivos.

### `00437690` — Centralize commander fallback policy
- **commander_fallback_policy.dart** (novo, 237 linhas): 8 constantes + 1 função `commanderFoundationNamesFor()`.
- `candidate_quality_data_support.dart` e `optimize_runtime_support.dart` migrados.

### `81335e26` — Use semantic v2 in functional deck summary
- `summarizeFunctionalTagsForDeck`: prioridade agora é persisted > semantic_v2 > heuristic (antes: persisted > heuristic).

### `65f30387` — Scope archetype deck access by owner
- `/ai/archetypes` route: `AND user_id = CAST(@user_id AS uuid)` adicionado no SQL.

### `25416ec2` — Document semantic v2 optimize scorecard
- Scorecard runner atualizado com fixture `optimize_scorecard_disabled_public_cf225841.json` (393 linhas).

### `2396956e` — Wire sync cards utilities into pipeline
- **sync_cards_utils.dart** (novo) + **sync_cards.dart** refatorado (-181 linhas).

### `5c327b76` — Centralize candidate quality name policies
- `candidate_quality_data_support.dart` migra para `commander_fallback_policy.dart`.

### `e9940672` — Document ready alias contract
- Documentação apenas.

### `2999c346` — Harden experimental deck AI ownership
- Preparação para ownership enforcement em rotas experimentais.

### `640f4ab4` — Fix community navigation cycle
- `community_deck_detail_screen.dart`: `Navigator.push` → `context.push('/community/user/...')` via go_router.
- `user_profile_screen.dart`: mesmo pattern para CommunityDeckDetailScreen.

---

### `771c9318` — Harden semantic scorecard runner (2026-05-27T18:40Z)
- **3 arquivos**, **+359/-17 linhas** (script Python + relatório + fixture JSON)
- **Tipo: CODE/INFRA** — Robustecimento do runner de scorecard semântico

Commits anteriores mantidos como referência abaixo.
- **5 arquivos**, **+362/-5 linhas** (código + script + testes)
- Autor: softwarePredador (Co-authored-by: Copilot)
- Data: 2026-05-27 15:08 BRT
- **Tipo: CODE** — Melhora o gate de qualidade de otimização para cartas com múltiplas tags funcionais
  - `optimization_quality_gate.dart`: Adiciona `_functionalRolesForGate()` que resolve múltiplas funções por carta via `inferFunctionalCardTags()` + `_gateRoleForFunctionalTag()`. Troca comparação single-role por interseção de sets de roles (`removedRoles.intersection(addedRoles).isNotEmpty`). Mensagens de droppedReasons agora mostram funções completas (`draw+ramp` vs `utility`).
  - `semantic_layer_v2_optimize_scorecard.py`: Adiciona `log_progress()` para debug de timeout global, deadline-based early exit, structured progress events no stderr, elapsed_ms no summary.
  - `optimization_quality_gate_test.dart`: +2 testes novos (preserves critical ramp on multi-tag cards, blocks loss of secondary protection on multi-function swaps).
  - `RELATORIO_OPTIMIZE_MULTITAG_GATE_2026-05-27.md`: Relatório de implementação.
  - `optimize_scorecard_progress_smoke_timeout30.json`: Smoke test fixture.
- **Validação:** `dart test optimization_quality_gate_test.dart` = 13/13 PASS. `dart test` completo = 585 pass / 18 fail (18 pre-existing em auth_service_test.dart, não relacionado).

Commits anteriores mantidos como referência:

### `7329fbbd` — docs: add Hermes semantic validation request
- **1 arquivo**, **+170 linhas** (documentacao)
- Autor: softwarePredador
- Data: 2026-05-26 14:46 BRT
- **Tipo: DOC**

### `f57bb8d3` — Fix semantic role classification fallbacks
- **4 arquivos**, **+142/-6 linhas** (codigo)
- Co-authored-by: Copilot
- Data: 2026-05-26 14:27 BRT
- **Tipo: CODE**

### `91885194` — Polish secondary shell headers (rodada anterior)
- **5 arquivos**, **+52/-54 linhas**
- Co-authored-by: Copilot
- Data: 2026-05-26 10:08 BRT

### `ca0c8d52` — Polish Lotus life counter overlays (rodada anterior)
- **4 arquivos**, **+531/-2 linhas**
- Co-authored-by: Copilot (mesmo autor de softwarePredador)
- Data: 2026-05-25 16:39 BRT

### `3eebd0f6` — Refresh ManaLoom visual system (rodada anterior)
- **63 arquivos**, **+3839/-2093 linhas** — commit massivo
- Co-authored-by: Copilot

## Analise detalhada do commit 3eebd0f6

### Tema e Design System
- `app/lib/core/theme/app_theme.dart` (+225 linhas)
- Novos tokens: `fontMicro` (8px) e `fontTiny` (9px) — escala vai de 8 a 32
- AppBar reformulado: fundo `backgroundAbyss` (antes surfaceSlate), iconTheme com `textSecondary`/22px, titleTextStyle Fraunces
- Novo `FilledButtonThemeData` com brass500 + padding padrao
- OutlinedButton agora usa `brass400` em vez de `frost400`
- Novos arquivos de teste do tema: `app_theme_button_tokens_test.dart`, `app_theme_widget_tokens_test.dart`, `app_theme_token_usage_test.dart`

### Auth (novo shared widget)
- `AuthVisualShell` (225 linhas) — componente compartilhado para telas de auth
- Login screen: -373 linhas (refatorada para usar AuthVisualShell)
- Register screen: -527 linhas (mesma refatoracao)
- Splash screen: ajuste menor

### Home
- Home screen: 435 linhas alteradas
- Novo golden test para hero visual (`home_hero_sma135m.png` baseline)
- Home hero golden: 69KB PNG
- Hero art nova: `home_hero_banner.png` (252KB)
- Logo: `app_logo.png` (1.7MB)

### Community
- Community screen: 871 linhas alteradas (+504/-367) — grande refatoracao visual

### Profile
- Profile screen: 602 linhas alteradas (+388/-214)

### Card Search
- Card search: 240 linhas alteradas (+147/-93)

### Messages/Notifications
- Message inbox: 208 linhas alteradas
- Chat screen: 12 linhas
- Notification screen: 16 linhas

### Testes adicionados
- `home_screen_test.dart`: golden test para hero visual + asserts de novos CTAs
- `app_theme_button_tokens_test.dart`, `app_theme_widget_tokens_test.dart`, `app_theme_token_usage_test.dart`

### Agente UX Design Auditor
- `manaloom-ux-design-auditor.agent.md`: reescrita completa (+767/-207)
- Agente agora tem modelo `gpt-5.5`
- Descricao expandida para "Elite UX/UI auditor for ManaLoom mobile"
- Diretrizes premium de produto: atmosferico, premium, cinematografico, game-native

### Documentacao
- `app/test/README.md`: instrucao para golden test do hero
- Runtime handoff: `manaloom_meus_decks_visual_system_iphone15_2026-05-22.md` (146 linhas)
- Layout uniformity audit: `manaloom_layout_uniformity_audit_iphone15_2026-05-22.md` (158 linhas)

### Assets novos
- `app/assets/branding/app_logo.png` (1.7MB)
- `app/assets/branding/home_hero_banner.png` (252KB)
- `nrelogo.png`, `nrelogos.png`, `slasharat.png` na raiz (arquivos fonte)

## Analise do commit 9a2bb38b — Lotus

- `lotus_visual_skin.dart`: skin CSS injetada no WebView do life counter
- Acabamento premium: cada um dos 4 jogadores agora tem cor de acento propria
  - J1: gold/warm (`#d89a2f`)
  - J2: blue (`#78a8ff`)
  - J3: purple (`#9a7cff`)
  - J4: green (`#4ed691`)
- Player cards com gradientes radiais + box-shadows + blend modes
- Saturação reduzida (0.62 vs 0.84) para aparencia mais cinematica e premium
- Cada player card tem glow, accent-soft e accent-faint como variaveis CSS
- Validacao adicional local em 2026-05-25 confirmou tela principal, radial menu,
  history, settings e card search em iPhone Simulator; ajustes de harness/skin
  posteriores a este HEAD ainda devem ser commitados antes de virarem baseline canonica.

## Analise do commit ca0c8d52 — Lotus Overlays Polish

Este commit expandiu `lotus_visual_skin.dart` em +423 linhas na epoca do commit,
com CSS premium para tres overlays do Lotus WebView. Na higiene semanal de
2026-05-27, o arquivo completo em `origin/master` soma 1991 linhas por incluir
tambem commits anteriores da skin Lotus:

- **Settings overlay** (`Configurações`): posicionamento fixed full-viewport,
  safe-area-aware, fundo gradiente radial + linear, lista de itens com cards
  arredondados (20px), glassmorphism com `linear-gradient(180deg, rgba(13,22,42,0.8), rgba(6,11,24,0.72))`, bordoas sutis e sombra profunda.
- **Life history overlay**: timeline com tipografia `manaloom-display-font`,
  identidade visual consistente.
- **Card search overlay**: titulo `Buscar carta` posicionado, resultados com
  `card-name` estilizado, estrutura de pesquisa integrada ao tema premium.

Tres arquivos de smoke test foram atualizados/criados:
- `life_counter_lotus_card_search_visual_smoke_test.dart` (+59 linhas)
- `life_counter_lotus_settings_visual_smoke_test.dart` (+23 linhas)
- `life_counter_lotus_visual_overlays_smoke_test.dart` (+28 linhas, novo)

**Nao alterado**: backend, contratos API, core de decks, IA, ou outras
superficies do app. O arquivo `lotus_visual_skin.dart` continua sendo CSS
injetado no WebView, fora do sistema de tema Flutter.

**Status dos overlays**: settings, history e card search agora tem skin
premium, mas ainda precisam de prova viva lado a lado com `dddddd/` (baseline
pre-skin) para cada overlay antes de considerar a task de perfeicao fechada.

## Analise do commit 91885194 — Polish secondary shell headers

Este commit padroniza os AppBars de quatro telas secundarias, unificando
as seguintes propriedades em todas elas:

- **toolbarHeight: 54** (antes era 52 na Collection, inexistente nas demais)
- **centerTitle: true** (antes centralizacao era inconsistente)
- **titleTextStyle**: `titleMedium.w700` + `displayFontFamily` + `fontLg + 1`
- **surfaceTintColor: transparent**

### Impacto no design system

1. **Community screen** (`community_screen.dart`):
   - fontWeight: w800 → w700 (resolve o risco P1 documentado em OPEN_RISKS.md)
   - toolbarHeight adicionado (era ausente)
   - centerTitle adicionado

2. **Profile screen** (`profile_screen.dart`):
   - fontWeight: w800 → w700 (mesma correcao)
   - toolbarHeight e centerTitle adicionados

3. **Collection screen** (`collection_screen.dart`):
   - toolbarHeight: 52 → 54
   - **IconButton para `/collection/sets` removido** — o entry point direto para o catalogo de colecoes via AppBar foi eliminado. O acesso permanece via TabBar (aba "Colecoes"). Risco de usabilidade: usuarios que usavam o icone grid_view_rounded para navegacao rapida perdem esse atalho.
   - centerTitle adicionado
   - `go_router` import removido (redundante apos remocao do push)

4. **Market screen** (`market_screen.dart`):
   - **Tracker de cartas monitoradas removido do AppBar**: o badge com `provider.moversData!.totalTracked` nao aparece mais no header. O dado `moversData` continua disponivel no corpo da tela (loading/error states e listagem). Perda de visibilidade do total de cartas monitoradas sem navegacao extra.
   - Removeu padding, centralizou titulo e padronizou estilo

5. **Test file** (`collection_entrypoints_runtime_test.dart`):
   - Migrou de `find.widgetWithText(Tab, 'Marketplace')` para `find.byKey(Key('collection-tab-market'))`
   - Mesmo padrao para Trades, Colecoes e Fichario
   - Torna os testes mais resilientes a mudancas de texto e consistentes com UI_TEST_SURFACE_MAP.md

### Arquivos alterados

| Arquivo | Tipo | Mudanca |
|---------|------|---------|
| `app/lib/features/collection/screens/collection_screen.dart` | UI | AppBar padrao, remocao do atalho sets |
| `app/lib/features/community/screens/community_screen.dart` | UI | w800→w700, centerTitle |
| `app/lib/features/market/screens/market_screen.dart` | UI | AppBar padrao, remocao movers counter |
| `app/lib/features/profile/profile_screen.dart` | UI | w800→w700, centerTitle |
| `app/integration_test/collection_entrypoints_runtime_test.dart` | Test | Keys estaveis em vez de texto |

### Validacoes Linux (Hermes container)

- **dart test**: 599/599 passed (era 589 na rodada anterior)
- **flutter analyze**: No issues found

**Nao alterado**: backend (0 arquivos), contratos API, core de decks, IA, rotas.

## Analise do commit f57bb8d3 — Fix semantic role classification fallbacks

Este commit aplica o patch de fallbacks deterministicos para classificacao de roles
funcionais que foi planejado, validado e simulado em `PATCH_PLAN.md`.

### Mudancas em `optimization_functional_roles.dart`

- **Novas listas curadas**:
  - `_knownWinconNames` (11 cartas: Walking Ballista, Laboratory Maniac, Thassa's Oracle, etc.)
  - `_knownEngineNames` (14 cartas: The One Ring, Rhystic Study, Seedborn Muse, etc.)
  - `_knownComboPieceNames` (11 cartas: Basalt Monolith, Dramatic Reversal, Underworld Breach, etc.)
  - `_knownProtectionNames` (7 cartas: Fierce Guardianship, Deflecting Swat, Heroic Intervention, etc.)
- **Ordem de avaliacao**: listas curadas sao avaliadas ANTES dos fallbacks de oracle text
  (`draw`, `removal`, `ramp`), corrigindo:
  - Walking Ballista: `removal` → `wincon`
  - The One Ring: `draw` → `engine`
  - Basalt Monolith: `ramp` → `combo_piece`
  - Fierce Guardianship: `protection` (agora detectado por nome, nao por regra global de counters)
  - Endurance: `other` → `protection`
- **Nao altera**: `semantic_tags_v2` continue em shadow mode; nenhum enforcement novo

### Mudancas em `edh_bracket_policy.dart`

- Adiciona `hasFreeCast` (oracle contem `without paying`) ao lado da heuristica `hasPitch`
- Fierce Guardianship, Deflecting Swat e Deadly Rollick agora sao detectados como
  `freeInteraction` — antes so `rather than pay` era detectado
- Sem mudanca na logica de contagem de bracket ou categorias existentes

### Testes novos

- `test/optimization_quality_gate_test.dart`: teste parametrizado para os 5 exemplos curados
  (Walking Ballista→wincon, The One Ring→engine, Basalt Monolith→combo_piece,
  Fierce Guardianship→protection, Endurance→protection)
- `test/optimize_runtime_support_test.dart`: teste especifico para Fierce Guardianship
  como `freeInteraction` no bracket system

### Diferenca entre PATCH_PLAN.md e implementacao real

- A lista `_knownWinconNames` no plano inclui `'test of talents'` (12 cartas);
  a implementacao real tem 11 cartas (sem test of talents). A versao real e a
  conservadora e correta — test of talents nao e wincon consistente.
- O plano sugeria uma exclusao de `remove a +1/+1 counter` no bloco de removal;
  a versao real e mais simples: so adiciona verificacao por nome antes do bloco
  de oracle text, sem modificar o bloco de removal. Isso e mais seguro.

### Validacoes Linux (Hermes container)

- **dart test**: 599/599 passed (revalidado em 2026-05-27)
- **flutter analyze --no-pub --no-fatal-infos**: No issues found (revalidado em 2026-05-27)
- **dart analyze** dos 4 arquivos alterados: PASS historico
- **Backend publicado**: `7329fbbd` contem `f57bb8d3` por ancestralidade Git

**Nao alterado**: contratos API, core de decks (app), rotas, visual system, deploy.

## Analise do commit 7329fbbd — docs: add Hermes semantic validation request

- Adiciona `docs/qa/HERMES_VALIDATION_REQUEST_SEMANTIC_FALLBACKS_2026-05-26.md`
- Documento formalizando 10 perguntas que o Hermes deve responder sobre o patch
- Nao altera codigo, rotas, contratos ou UI

### Projeto entrou oficialmente na Onda 6: Premium Visual System
O commit `3eebd0f6` estabelece um **design system premium completo**:
- Tema global refatorado (AppBar, buttons, font scale)
- Componentes visuais compartilhados (AuthVisualShell)
- Golden tests para hero
- Agente UX auditor dedicado com gpt-5.5
- Runtime proofs visuais

### Implicacoes
1. **Design system agora tem testes dedicados** — 3 novos arquivos de teste de tokens
2. **Home hero tem golden test** — baseline visual protegida contra regressao
3. **Auth screens refatoradas** — +225 linhas de componente compartilhado, ~900 linhas removidas das telas
4. **Life counter Lotus atingiu acabamento premium** — CSS skin com identidade por jogador + overlays settings/history/card search premium
5. **Projeto esta usando Copilot como co-author** — commits assinados por Copilot
6. **Agente UX auditor elevado para gpt-5.5** — ambicao de qualidade visual de produto premium

### O que NAO mudou
- Backend: **alterado** — `optimization_functional_roles.dart` e `edh_bracket_policy.dart` receberam o patch
- IA/Rotas: rota de optimize nao foi alterada; a classificacao de roles foi endurecida internamente
- Contratos app/backend: inalterados
- Core de decks: inalterado (nenhuma tela de decks foi tocada)
- Scrum/prioridades Sprint 1/2: mesmas pendencias abertas
- Visual system: inalterado (apenas UM commit de doc, um de IA classificacao)

## Ondas de commit atualizadas (HEAD~80)

| Onda | Periodo | Commits | Tema |
|------|---------|---------|------|
| 6 | 2026-05-25/26 | 4 | **Premium Visual System** — tema global, AuthVisualShell, golden tests, Lotus skin + overlays premium, secondary shell headers unificados, agente UX auditor |
| **7** | **2026-05-26** | **2** | **AI Classification Hardening** — fallbacks deterministicos para roles funcionais (wincon, engine, combo_piece, protection), bracket free-cast detection, doc de validacao semantica |
| 1 | 2026-05-21/25 | 12 | UX Polishing — home, splash, icon, premium UX, card/deck screens |
| 2 | Abril-Maio | ~30 | Semantic Layer v2 |
| 3 | Maio | ~15 | Functional Tags + Localized Import |
| 4 | Abril-Maio | ~50 | Commander Reference |
| 5 | Marco | ~5 | Observabilidade + Infra |

## Direcao do projeto

1. **Premium Visual System** — design system, golden tests, componentes compartilhados, audiencia UX
2. **AI Classification Hardening (ATIVO nesta rodada)** — fallbacks deterministicos para accurate role classification; proximo passo e reavaliar enforcement do Semantic Layer v2
3. **Convergencia para o core** — decks, otimizacao, geracao, analise
4. **Qualidade de IA** — semantic tags, functional tags, Commander Reference
5. **Observabilidade** — Sentry, x-request-id
6. **Produto global** — icon, splash, onboarding

## O que esta fora dos commits recentes / nao consolidado neste digest

- Scanner/OCR — DEFERRED
- Community expansion — manutencao apenas
- Trades/Binder — manutencao apenas
- Carga/thresholds — nao iniciado
- Sentry mobile — pendente
- CHECKLIST_GO_LIVE — desatualizado
- Ajustes locais nao commitados no workspace principal nao contam como `master`
  ate virarem commit/push; este digest observa o `origin/master`.

## Higiene semanal 2026-05-27

- `origin/master` permanece em `7329fbbd`; `git log 7329fbbd..origin/master` vazio.
- `/health.git_sha` confirmou `7329fbbdd0d5ea3e88de50d3c8235e76852380f4`.
- `dart test` no backend: 599/599 passed.
- `flutter analyze --no-pub --no-fatal-infos` no app: No issues found.
- Reconciliacao documental feita sem criar novos riscos de produto: alguns itens de UI foram ajustados para refletir cobertura existente (Profile/Trade/Marketplace) e tamanhos reais (`lotus_visual_skin.dart` agora 1991 linhas em `origin/master`).

## Como atualizar este digest

```bash
cd /opt/data/workspace/mtgia
git fetch --all --prune
BASE_PREVIO=$(git rev-parse origin/codex/hermes-analysis-docs)
# Para ver o que mudou na master desde a ultima analise:
git log --oneline --decorate --stat $BASE_PREVIO..origin/master
```
<!-- commit nonce: 1 -->
