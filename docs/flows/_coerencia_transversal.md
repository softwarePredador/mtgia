# Coerência transversal BrewTact — cliente ↔ servidor ↔ capabilities

Auditoria mecânica, somente leitura, sobre `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
na branch `codex/free-beta-release-candidate-2026-07-17` (HEAD `9a9ba66de`).

Nada foi executado (sem `flutter`, `dart`, `npm`, servidor ou emulador). Tudo abaixo é
leitura estática de código: `server/routes`, `app/lib`, `server/config`, `app/test`,
`server/test`. Onde eu não pude provar por execução, digo exatamente qual prova viva
fecharia a questão.

## Como ler este relatório: três eixos que este projeto confunde

| Eixo | Significado aqui | Onde se verifica |
| --- | --- | --- |
| **IMPLEMENTADO** | Existe código que faz a coisa | arquivo:linha no `server/routes` ou `app/lib` |
| **ALCANÇÁVEL HOJE** | A política de capabilities deixa a requisição chegar ao handler e a rota do app abrir | `server/config/release_capabilities.json` + `server/routes/_middleware.dart:105` + `app/lib/core/config/release_capabilities.dart:350` |
| **PROVADO** | Existe teste/gate que exercita o caminho | `server/test`, `app/test`, `app/integration_test` |

**Fato de partida que domina todo o resto:** o arquivo de política efetivamente
carregado, `server/config/release_capabilities.json`, tem **as 29 capabilities com
`allowed=false` e `release_capability="off"`** (commit `b2d3fc04f`,
*"chore: establish BrewTact free beta all-off baseline"*, sem diff local). Isso é
intencional e está documentado em `docs/status/CURRENT_PRODUCT_DECISION.md:5`
(`NO_GO_PUBLIC_RELEASE`) e na matriz da linha 57 em diante.

Consequência mecânica: hoje **nenhuma** rota de produto é ALCANÇÁVEL. O middleware
(`server/routes/_middleware.dart:110-144`) devolve `404 {"error":"capability_unavailable"}`
para 82 dos 120 endpoints, antes de tocar PostgreSQL. Só as 38 combinações rota+método
do plano de controle respondem. Portanto, toda leitura de "funciona" neste relatório é
sobre IMPLEMENTADO, nunca sobre ALCANÇÁVEL, salvo quando eu disser o contrário.

---

## 1. Varredura mecânica: o que extraí

| Extração | Total | Script |
| --- | --- | --- |
| Endpoints do servidor (dart_frog, caminho = pastas, método = `HttpMethod.*` no handler) | **120 rotas / 158 pares rota+método** | `_extract_server.py` |
| Chamadas HTTP do app com caminho literal/interpolado | **128** | `_extract_app2.py` |
| Chamadas HTTP do app com caminho em variável | **14** (todas resolvidas à mão, ver §2.3) | idem |
| Alvos de `go`/`push`/`replace` no app | 44 caminhos distintos | `_nav.py` |

Conferência contra o artefato gerado: `docs/generated/openapi.generated.json` lista 121
paths — os meus 120 mais `/community/decks/following`, que é o alias declarado em
`docs/project_logic_contracts.json` (`api_route_aliases`) e resolvido dentro do handler
`server/routes/community/decks/[id]/index.dart:17`. **Zero drift** entre a minha varredura
e o OpenAPI gerado.

---

## 2. Cruzamento app → servidor

### 2.1 Chamadas do app para endpoint inexistente ou método não aceito

**Nenhuma.** As 128 chamadas literais + 14 dinâmicas resolvem todas para um par
rota+método que o handler aceita.

Dois casos exigiram inspeção porque o casamento estrutural era ambíguo. Registro para
que ninguém os reabra como bug:

| Chamada do app | Por que parecia quebrada | Por que não está |
| --- | --- | --- |
| `GET /binder/stats` — `app/lib/features/binder/providers/binder_provider.dart:896`<br>`GET /binder/availability?card_ids=` — `app/lib/features/cards/providers/card_provider.dart:342` | Casam com `/binder/{id}`, que também aceita `PUT`/`DELETE` de item | `server/routes/binder/[id]/index.dart:13-14` intercepta `id == 'stats'` e `id == 'availability'` antes de qualquer lookup |
| `GET /ai/generate/jobs/latest?active=` — `deck_provider_support_generation.dart:439`<br>`GET /ai/optimize/jobs/latest?` — `deck_provider_support_ai.dart:339` | Casam com `/ai/{generate,optimize}/jobs/{id}` | `server/routes/ai/generate/jobs/[id].dart:18,29` e `server/routes/ai/optimize/jobs/[id].dart:28,39` tratam `id == 'latest'` e recusam método ≠ GET |
| `GET /community/decks/following?page=` — `social_provider.dart:734` | Casa com `/community/decks/{id}` | `server/routes/community/decks/[id]/index.dart:17` desvia para `handleCommunityFollowingFeed`; o alias está declarado em `docs/project_logic_contracts.json` |
| `DELETE /community/decks/{id}/comments/{commentId}` — `community_provider.dart:451-455` | Meu extrator cortou na interpolação e marcou `DELETE /community/decks/{id}/comments` | A string é concatenada em duas linhas; o caminho final existe em `server/routes/community/decks/[id]/comments/[commentId]/index.dart` com `DELETE` |
| `GET /community/trade-matches$query` — `community_provider.dart:527` | `$query` parecia parte do caminho | `community_provider.dart:522-524`: `$query` é `''` ou `'?deck_id=...'` |
| `GET /decks/{id}/battle-preflight` — `battle_replay_service.dart:468` | Sem `mode`, o servidor exigiria `battle_batch` mesmo no fluxo interativo | `battle_replay_service.dart:466-471` envia `&mode=interactive|simulation`, casando com `server/lib/release_capability_policy.dart:413-418` |

**Isto é o ponto forte do repositório.** A superfície HTTP app↔servidor está alinhada.

### 2.2 Endpoints sem nenhum chamador no app

Removi da lista os que só pareciam órfãos porque o caminho é montado em variável
(§2.3). Sobram 26 pares rota+método:

| Endpoint | Capability exigida | Intencional? | Evidência |
| --- | --- | --- | --- |
| `GET /` | plano de controle | **Sim** — raiz/ops | `server/routes/index.dart` |
| `GET /ready`, `GET /health`, `/health/live`, `/health/ready`, `/health/metrics`, `/health/dashboard`, `/health/ai-history`, `/health/commercial` | plano de controle | **Sim** — ops/health, consumidos por deploy e smoke | `server/lib/release_capability_policy.dart:593-600` |
| `POST /billing/webhook` | `billing_checkout` | **Sim** — webhook do provedor, nunca do app | `server/routes/billing/webhook/index.dart` |
| `GET /moderation/reports`, `PUT /moderation/reports/{id}` | plano de controle | **Sim** — backoffice; não existe tela de moderação no app | `server/routes/moderation/reports/` |
| `GET /reports/{id}` | plano de controle | **Sim** — relatório público compartilhável, consumido pela web pública | `server/routes/reports/[id].dart` |
| `POST /content-reports/{id}/appeals` | plano de controle | **Não** — não há tela de apelação; o usuário denuncia (`POST /content-reports`) mas não pode recorrer | `server/routes/content-reports/[id]/appeals/index.dart`; zero ocorrências de `appeals` em `app/lib` |
| `POST /community/decks/{id}/reports` | plano de controle | **Não** — duplicata funcional. O app denuncia deck por `POST /content-reports` (`social_provider.dart:461`, `community_provider.dart:479`). Este endpoint faz a mesma coisa via `CommunityEngagementService.reportContent` e nunca é chamado | `server/routes/community/decks/[id]/reports/index.dart:28` |
| `GET /rules` | `catalog_private` | **Não** — nenhuma tela consome as regras | zero ocorrências de `/rules` em `app/lib` |
| `GET /cards/{id}/rulings` | `catalog_private` | **Não** — o detalhe de carta não mostra rulings | zero ocorrências de `rulings` em `app/lib` |
| `GET /market/card/{cardId}` | `catalog_private` | **Não** — o app só usa `/market/movers` (`market_provider.dart:46`) | zero ocorrências de `market/card` em `app/lib` |
| `GET /decks/{id}/post-game-timeline` | `decks_private` | **Não** — a tela de pós-jogo só usa `post-game-notes` (`post_game_note_store.dart:37,69,80`) | zero ocorrências de `post-game-timeline` em `app/lib` |
| `GET /ai/commander-reference` | `ai_generate_rebuild` | **Não, e contradiz o contrato** — `docs/project_logic_contracts.json` declara `/ai/commander-reference` como *entrypoint* do fluxo `deck_ai`, mas nenhuma tela chama | zero ocorrências em `app/lib` |
| `GET /ai/ml-status`, `POST /ai/simulate-matchup`, `POST /ai/weakness-analysis`, `GET /ai/optimize/telemetry`, `POST /decks/{id}/recommendations`, `GET /decks/{id}/simulate` | `legacy_ai_routes` | **Sim** — `implementation_status: contained_legacy`; ausência de chamador é a contenção funcionando | `server/lib/release_capability_policy.dart:446-454`; `server/config/release_capabilities.json` |
| `POST /users/me/plan/checkout` | `billing_checkout` | **Sim** — oferta única é beta gratuita (`CURRENT_PRODUCT_DECISION.md:34`) | — |

### 2.3 Endpoints que só pareciam órfãos (caminho em variável)

Corrijo aqui o falso positivo mais provável de um auditor apressado. Todos **têm**
chamador:

| Endpoint | Chamador real |
| --- | --- |
| `GET /capabilities` | `app/lib/core/config/release_capabilities.dart:251` (`static const endpoint`) e `:281` |
| `POST /auth/change-password`, `POST /auth/revoke-sessions` | `app/lib/features/auth/providers/auth_provider.dart:348` e `:355`, executados em `_rotateAuthenticatedSession` → `auth_provider.dart:371` |
| `GET /community/marketplace` | `app/lib/features/binder/providers/binder_provider.dart:1277` (monta query) → `:1285` |
| `GET /community/trade-matches` | `app/lib/features/community/providers/community_provider.dart:527` |
| `GET /decks/{id}/battle-replays/{replayId}` | `app/lib/features/battle/services/battle_replay_service.dart:331` |
| `GET`/`POST /decks/{id}/battle-replays/{replayId}/annotations` | `battle_replay_service.dart:354` e `:393`, via `_annotationEndpoint` (`:554`) |
| `DELETE .../annotations/{annotationId}` | `battle_replay_service.dart:427` |
| `GET /binder` (com filtros) | `binder_provider.dart:822-834` e `:1096-1111` |
| `GET /conversations/{id}/messages` | `message_provider.dart:306-310` |
| `GET /sets` | `set_cards_screen.dart:92-95` e `sets_catalog_screen.dart:105` |
| `GET /ai/commander-learning` | `deck_provider.dart:1050-1054` |

---

## 3. Capabilities: ids, mapa rota→capability e classificação de rota

### 3.1 Ids: alinhados

| Fonte | Quantidade |
| --- | --- |
| Servidor — `releaseCapabilityKeys`, `server/lib/release_capability_policy.dart:15-45` | 29 |
| App — `enum ReleaseCapability`, `app/lib/core/config/release_capabilities.dart:7-41` | 29 |

**Conjuntos idênticos.** Nenhum id existe só de um lado. E o contrato é mais forte que
a igualdade de nomes: `ReleaseCapabilitiesSnapshot.fromJson`
(`release_capabilities.dart:119-125`) exige que o payload de `/capabilities` traga
**exatamente** essas 29 chaves — sobra ou falta derruba o snapshot inteiro para
`denied()`. O servidor sempre emite as 29 (`release_capability_policy.dart:208-210`).

### 3.2 Toda rota do servidor está classificada

Rodei a reimplementação de `requiredCapabilityForRequest` + `isReleaseCapabilityControlPlaneRequest`
sobre os 158 pares rota+método: **zero rotas não classificadas**. Nenhuma cai no
`capability_route_unclassified` de `release_capability_policy.dart:172-177`.

E isto é **PROVADO**, não só verificado por mim: `server/test/release_capability_policy_test.dart:309`
(`'every route handler is classified or explicitly control-plane'`) varre
`Directory('routes')` recursivamente e falha se qualquer handler novo não tiver
capability nem entrada no plano de controle. É o gate certo, no lugar certo.

Distribuição (pares rota+método):

| Capability | Pares | Capability | Pares |
| --- | --- | --- | --- |
| plano de controle | 38 | `trades` | 8 |
| `decks_private` | 16 | `collection_private` | 7 |
| `battle_batch` | 11 | `legacy_ai_routes` | 6 |
| `ai_analyze_optimize_advisory` | 9 | `direct_messages` | 6 |
| `catalog_private` | 9 | `ai_generate_rebuild` | 5 |
| `battle_coach` | 5 | `social_push` | 5 |
| `follows` | 4 | `gallery_public` | 4 |
| `deck_replace_all` | 3 | `billing_checkout` | 2 |
| `comments` | 2 | demais (`battle_live`, `binder_public`, `marketplace`, `profiles_public`, `user_search`, `learning_reads`, `account_registration`) | 1 cada |

### 3.3 Divergências app ↔ servidor na granularidade

Os ids batem; **o que não bate é a exigência por tela**. Em três casos o guard do app é
estritamente mais rígido que o servidor, o que torna a capability isolada inútil:

| Rota do app | O app exige (`release_capabilities.dart`) | O servidor exige para os endpoints que a tela chama | Efeito |
| --- | --- | --- | --- |
| `/community/user/:userId` | `profiles_public` **e** `follows` **e** `gallery_public` **e** `binder_public` **e** `direct_messages` **e** `trades` (`:419-429`) | `GET /community/users/{id}` → só `profiles_public` (`release_capability_policy.dart:480-482`) | Abrir só `profiles_public` não torna o perfil público alcançável: o app manda para `/home`. A tela é tudo-ou-nada |
| `/community/decks/:deckId` | `gallery_public` **e** `profiles_public` **e** `comments` **e** `trades` (`:431-439`) | `GET /community/decks/{id}` → só `gallery_public` (`:467-470`) | Abrir só `gallery_public` não torna a galeria navegável até o detalhe do deck |
| `/community?tab=1` | `gallery_public` **e** `follows` (`:444-447`) | `GET /community/decks/following` → só `follows` (`:464-466`) | Consistente com o feed precisar da galeria, mas o acoplamento não está declarado em nenhum doc |

Não classifico como bug: é uma decisão de empacotamento (a tela realmente dispara
chamadas das 6 capabilities). Classifico como **incoerência de contrato**: o servidor
sugere que `profiles_public` sozinho serve, o app diz que não, e nenhum documento
registra o acoplamento. Quem for abrir a matriz gradualmente vai tropeçar nisto.

Uma quarta divergência, essa sim morta:

| Sintoma | Local |
| --- | --- |
| Os dois portões do app tratam `/binder` como rota protegida/guardada, mas **não existe `GoRoute` `/binder`** no roteador. O fichário é `BinderTabContent` embutido em `/collection?tab=0` (`collection_screen.dart:102-104`) | `app/lib/core/config/release_capabilities.dart:472-473` e `app/lib/main.dart:346` |

### 3.4 `battle_live`: capability viva, superfície deliberadamente morta

| Eixo | Estado |
| --- | --- |
| IMPLEMENTADO | Sim, ponta a ponta: `GET /ai/battle/jobs/{id}/live` (`server/routes/ai/battle/jobs/[id]/live/index.dart`), cliente em `app/lib/features/battle/services/battle_job_gateway.dart:125`, tela em `app/lib/features/battle/screens/battle_live_spectator_screen.dart` |
| ALCANÇÁVEL HOJE | **Não**, por dois motivos independentes: `battle_live` está `off`, e `battleLiveRouteLocation` (`battle_live_spectator_screen.dart:16`) produz `/decks/{id}/battle-live/{jobId}`, caminho **que não existe no `GoRouter`** |
| PROVADO | Sim, a exclusão é blindada: `app/test/core/config/release_capability_surface_contract_test.dart:112-147` falha se `main.dart` passar a conter `path: 'battle-live/:jobId'` ou `BattleLiveSpectatorScreen`, e se `battle_replays_screen.dart` mencionar `battleLiveRouteLocation(` ou `Acompanhar ao vivo` |

Está correto e bem defendido. Registro só o resíduo: a tela e o helper continuam
compilando no bundle do app sem nenhum caminho que os alcance.

---

## 4. Sessão e erro: um portão central e meia dúzia de vazamentos

### 4.1 O que é central — e funciona

O tratamento de sessão expirada é **único e central**:

- `ApiClient._parseResponse` (`app/lib/core/api/api_client.dart:623-627`) é o **único**
  ponto que dispara o encerramento de sessão. Toda resposta de todo verbo passa por ele.
- O critério está isolado e testável: `isSessionInvalidatingUnauthorized`
  (`api_client.dart:97-117`). Ele exige 401 **e** token em memória **e** um sinal textual
  de sessão (`token`, `invalid_session`, `authentication_required`, `faça login novamente`…),
  e **exclui explicitamente** `invalid_password` / `current_password_invalid`
  (`api_client.dart:103-105`) — ou seja, errar a senha na troca de senha não derruba a
  sessão. É a distinção certa.
- O handler é registrado uma vez, em `app/lib/main.dart:282`
  (`ApiClient.setSessionExpiredHandler(_authProvider.expireSession)`) e desregistrado em
  `main.dart:1178`.
- `_sessionExpiryDispatched` (`api_client.dart:51,56,625`) é um latch que impede rajada
  de logouts quando várias chamadas paralelas devolvem 401 no mesmo instante.

**Não existe fluxo de refresh token.** Não há rota `/auth/refresh` no servidor (varri
`server/routes`: zero) nem `refreshToken` no app. O modelo é token único +
`auth_version` no banco + `POST /auth/revoke-sessions`. Isso é coerente, não é lacuna —
mas é um fato de arquitetura que não está dito em lugar nenhum dos docs que li.

### 4.2 O que **não** é central: `404 capability_unavailable`

A string `capability_unavailable` **não aparece uma única vez em `app/lib`**. O app nunca
lê o campo `error` que o middleware devolve em `server/routes/_middleware.dart:128-143`
(que inclui `capability`, `release_capability`, `policy_version`, `policy_digest_sha256`).

Cada feature trata o 404 do seu jeito, e três casos traduzem "capability fechada" em
mensagem errada:

| Local | Código | O que o usuário vê quando a capability está `off` |
| --- | --- | --- |
| `app/lib/features/decks/providers/deck_provider_support_ai.dart:302-306` | `if (response.statusCode == 404) throw Exception('A otimização demorou mais que o esperado. Inicie uma nova tentativa.')` | **Pior caso.** Diz que demorou e **convida a repetir** uma chamada que nunca pode dar certo enquanto `ai_analyze_optimize_advisory` estiver fechada |
| `app/lib/features/decks/providers/deck_provider_support_generation.dart:442` | `if (response.statusCode == 404) return null;` | Silêncio. `ai_generate_rebuild` fechada vira "não há job em andamento" |
| `app/lib/features/decks/providers/deck_provider_support_ai.dart:340` | `if (response.statusCode == 404) return null;` | Idem para optimize |
| `app/lib/features/social/providers/social_provider.dart:319-320` | `_profileError = 'Usuário não encontrado'` | `profiles_public` fechada vira "usuário não existe" — afirmação falsa sobre o dado |
| `app/lib/core/utils/friendly_error_mapper.dart:95-104` | fallback genérico `'Não encontramos o conteúdo solicitado.'` | Mesma confusão, no caminho padrão |

Hoje isso quase nunca aparece, porque o guard do app (§5) barra a tela antes da chamada.
Mas **o guard e o servidor podem discordar**, e é exatamente aí que a mensagem errada
sai. Ver 4.3.

### 4.3 A janela em que os dois portões discordam

Este é o achado de sessão/erro mais concreto.

```
main.dart:298   unawaited(_releaseCapabilitiesProvider.refresh());   // não bloqueia
main.dart:426   ReleaseCapabilityRouteGuard.redirectFor(
                  capabilities: _releaseCapabilitiesProvider.snapshot, ...)
```

`redirectFor` (`release_capabilities.dart:351-355`) recebe **só o snapshot**, nunca o
`loadState`. E enquanto `refresh()` está em voo o snapshot é
`ReleaseCapabilitiesSnapshot.denied()` (`release_capabilities.dart:275`), indistinguível
de "capability negada".

O portão de boot que segura o app na splash (`main.dart:360-387`) só espera **auth**
(`AuthStatus.loading/initial`). A `SplashScreen` faz `await authProvider.initialize()`
(`splash_screen.dart:51-52`) e imediatamente `context.go(...)` (`:62`) — sem esperar
`/capabilities`.

Consequência: com token válido em disco e um deep link para `/decks/<id>`, se `auth`
resolver antes de `/capabilities` responder, o guard vê `denied()` e devolve `/home`
(`release_capabilities.dart:520-523`). O parâmetro `?redirect=` que preservava o destino
já foi consumido pela splash, então **não há volta**: quando as capabilities chegam e o
`refreshListenable` (`main.dart:300-303`) reexecuta o redirect, o usuário já está em
`/home` e fica lá.

- **Severidade:** alta na Web (deep link, F5, restauração de aba) e em push
  (`realtime_notification_coordinator.dart:98` faz `_router.go(route)`).
- **Como provar:** teste de widget que injeta um `ReleaseCapabilitiesFetcher`
  (`release_capabilities.dart:233-234`, já existe o ponto de injeção) com `Completer`
  atrasado, boota com `initialLocation: '/decks/abc'` e token válido, e afirma que a
  localização final é `/decks/abc` e não `/home`. Hoje não encontrei teste assim em
  `app/test` nem em `app/integration_test`.
- **Correção mínima:** passar `loadState` para `redirectFor` e devolver `null`
  (sem redirecionar) enquanto for `initial`/`loading`, ou segurar a splash até
  `loadState != loading`.

---

## 5. Navegação

### 5.1 Rotas do `GoRouter` sem nenhum ponto de entrada na UI

Varri `go`/`push`/`replace`/`pushReplacement` em todo o `app/lib`, resolvendo também os
helpers (`playVsAiRouteLocation`, `tradeMatchesRouteLocation`, `createTradeRouteLocation`,
`openLifeCounterRoute`, `openCardDetailRoute`, `battleReplaysRouteLocation`,
`marketplaceRouteLocation`, `quotesRouteLocation`, `wishlistRouteLocation`,
`cardDetailRouteLocation`, `lifeCounterRouteLocation`).

Estas rotas existem no roteador e **ninguém navega para elas**:

| Rota | Declaração | Situação |
| --- | --- | --- |
| `/trades` | `main.dart:873` | `TradeInboxScreen` só aparece em `main.dart`. O inbox real do produto é `TradeInboxTabContent`, embutido em `/collection?tab=2` (`collection_screen.dart:106`). A rota é uma segunda cópia da mesma tela, alcançável só por URL |
| `/collection/sets` | `main.dart:787` | `SetsCatalogScreen` é embutido em `/collection` tab "sets" (`collection_screen.dart:107`) e em `card_search_screen.dart:462`. O **filho** `/collection/sets/:code` (`main.dart:791`) é navegado (`sets_catalog_screen.dart:177`), então o "voltar" na Web cai numa rota que nada linka |
| `/collection/latest-set` | `main.dart:783` | `LatestSetCollectionScreen` só aparece em `main.dart` |
| `/upgrade` | `main.dart:737` | `UpgradeScreen` só aparece em `main.dart` |
| `/checkout` | `main.dart:741` | `CheckoutScreen` só aparece em `main.dart`; ela própria navega **para fora** (`checkout_screen.dart:69` → `/plans`) |
| `/market` | `main.dart:800` | Redireciona para `quotesRouteLocation` = `/community?tab=3` (`trade_route_contract.dart:3`). Ninguém navega para `/market` |
| `/marketplace` | `main.dart:804` | Redireciona para `marketplaceRouteLocation` = `/collection?tab=1` (`trade_route_contract.dart:1`). Ninguém navega para `/marketplace` |
| `/quotes` | `main.dart:808` | Redireciona para `/community?tab=3`. Ninguém navega para `/quotes` |
| `/decks/:id/battle-coach` | `main.dart:715` | Alias legado → `playVsAiRouteLocation`. `battleCoachRouteLocation` (`battle_coach_screen.dart:29`, `@Deprecated`) tem **zero** chamadores |
| `/decks/:id/battle-coach/:sessionId` | `main.dart:706` | Idem; `battleCoachSessionRouteLocation` (`battle_coach_screen.dart:34`) tem **zero** chamadores |
| `/reset-password` | `main.dart:466` | Só deep link do e-mail de recuperação; nenhum `go`/`push` no app. Provavelmente intencional, mas não há teste que prove que o link do e-mail bate neste caminho |

Nota de nomenclatura que atrapalha a leitura: **`/marketplace` leva à coleção e
`/market`/`/quotes` levam à comunidade** — o inverso do que os nomes sugerem
(`trade_route_contract.dart:1-3`). Os três estão sob a mesma capability `marketplace`
(`release_capabilities.dart:495-499`), então funcionalmente fecha; a confusão é humana.

### 5.2 `go`/`push` para caminho que não existe

Um caso, e está contido:

| Origem | Caminho produzido | Estado |
| --- | --- | --- |
| `battleLiveRouteLocation` — `app/lib/features/battle/screens/battle_live_spectator_screen.dart:16-18` | `/decks/{deckId}/battle-live/{jobId}` | **Não existe `GoRoute` correspondente** em `main.dart`. Nenhum chamador hoje, e `app/test/core/config/release_capability_surface_contract_test.dart:139` proíbe `battle_replays_screen.dart` de voltar a usar o helper. Risco residual: um `push` futuro usando o helper falha silenciosamente |

Nenhum outro alvo de navegação aponta para caminho inexistente.

### 5.3 Resíduo no portão de rota protegida

`main.dart:339-357` lista `isProtectedRoute` por prefixo. Dois pontos:

- `/binder` (`main.dart:346`) — condição morta, não existe a rota (§3.3).
- `/marketplace` é coberto por acidente: `location.startsWith('/market')`
  (`main.dart:344`) casa `/marketplace` também. Funciona, mas por coincidência de prefixo,
  não por intenção declarada.

---

## 6. Achados priorizados

| # | Tipo | Sev. | Achado | Arquivo:linha |
| --- | --- | --- | --- | --- |
| 1 | bug-provável | alta | Guard de capability não distingue "carregando" de "negado": deep link autenticado pode cair em `/home` e não voltar | `app/lib/core/config/release_capabilities.dart:351`; `app/lib/main.dart:298,426`; `app/lib/features/auth/screens/splash_screen.dart:51-62` |
| 2 | ux-funcional | alta | `404 capability_unavailable` vira "A otimização demorou mais que o esperado. Inicie uma nova tentativa." — convida a repetir o impossível | `app/lib/features/decks/providers/deck_provider_support_ai.dart:302-306` |
| 3 | estado-não-tratado | alta | O app nunca lê `capability_unavailable`; zero ocorrências em `app/lib`. Não há tradução central de negação de capability | `server/routes/_middleware.dart:128-143` ↔ `app/lib/core/utils/friendly_error_mapper.dart:95-104` |
| 4 | ux-funcional | média | `profiles_public` fechada vira "Usuário não encontrado" (afirmação falsa sobre o dado) | `app/lib/features/social/providers/social_provider.dart:319-320` |
| 5 | estado-não-tratado | média | Capability fechada vira "nenhum job em andamento" em dois pollers | `deck_provider_support_generation.dart:442`; `deck_provider_support_ai.dart:340` |
| 6 | capability | média | App exige 6 capabilities para `/community/user/:userId`; servidor exige 1. `profiles_public` sozinha é inútil e o acoplamento não está documentado | `app/lib/core/config/release_capabilities.dart:419-429` ↔ `server/lib/release_capability_policy.dart:480-482` |
| 7 | capability | média | Mesmo padrão em `/community/decks/:deckId`: app exige 4, servidor exige 1 | `app/lib/core/config/release_capabilities.dart:431-439` ↔ `server/lib/release_capability_policy.dart:467-470` |
| 8 | ux-funcional | média | `/trades` e `/collection/sets` duplicam telas que só existem como aba. "Voltar" na Web leva a rotas que nada linka | `app/lib/main.dart:873,787` ↔ `collection_screen.dart:106,107` |
| 9 | passo-sem-teste | média | Não existe gate que cruze chamadas HTTP do app com as rotas do servidor. O alinhamento de hoje é sorte revisada, não contrato | nada em `app/test`/`app/integration_test` lê `server/routes` ou `openapi.generated.json` |
| 10 | incoerência-app-servidor | média | `POST /community/decks/{id}/reports` nunca é chamado; o app denuncia por `POST /content-reports`. Dois caminhos de denúncia, um morto | `server/routes/community/decks/[id]/reports/index.dart:28` vs `social_provider.dart:461`, `community_provider.dart:479` |
| 11 | doc-defasada | média | `docs/project_logic_contracts.json` declara `/ai/commander-reference` como entrypoint do fluxo `deck_ai`, mas nenhuma tela chama | `docs/project_logic_contracts.json` (`flows[deck_ai].entrypoints`) |
| 12 | ux-funcional | baixa | `POST /content-reports/{id}/appeals` implementado sem nenhuma tela: o usuário denuncia mas não pode recorrer | `server/routes/content-reports/[id]/appeals/index.dart` |
| 13 | outro | baixa | `battleLiveRouteLocation` produz rota inexistente; tela e helper seguem no bundle sem caminho | `app/lib/features/battle/screens/battle_live_spectator_screen.dart:16-18` |
| 14 | outro | baixa | Condição morta `/binder` nos dois portões do app; não existe a rota | `app/lib/core/config/release_capabilities.dart:472-473`; `app/lib/main.dart:346` |
| 15 | outro | baixa | Ramo inalcançável em `_firstAllowedCommunityLocation`: o `tab=1` exige `galleryPublic`, mas o ramo anterior já retornou se `galleryPublic` fosse permitida | `app/lib/core/config/release_capabilities.dart:563-568` |
| 16 | outro | baixa | Aliases legados mortos: `battleCoachRouteLocation` e `battleCoachSessionRouteLocation` com zero chamadores; rotas `/decks/:id/battle-coach*` sem entrada | `app/lib/features/battle/screens/battle_coach_screen.dart:29,34`; `app/lib/main.dart:706,715` |
| 17 | doc-defasada | baixa | Não há refresh token no produto (nenhuma rota `/auth/refresh`, nenhum `refreshToken` no app); nenhum doc lido declara isso | `server/routes/auth/`; `app/lib/core/api/api_client.dart` |
| 18 | outro | baixa | `timeoutForEndpoint` trata `/recommendations` como endpoint de IA com 2 min, mas o app nunca chama esse caminho | `app/lib/core/api/api_client.dart:196-203` |

---

## 7. O que está certo e deve ser preservado

Não é elogio vago; é o que a varredura mecânica confirmou e que qualquer refatoração
precisa manter:

1. **Zero chamadas quebradas.** 142 chamadas HTTP do app, todas com endpoint e método
   existentes. Inclusive os cinco casos de roteamento por caso especial (`stats`,
   `availability`, `latest` ×2, `following`), todos tratados no handler.
2. **Zero rotas não classificadas**, e com gate que impede regressão:
   `server/test/release_capability_policy_test.dart:309`.
3. **Ids de capability idênticos**, com validação de conjunto exato nos dois lados
   (`release_capability_policy.dart:301` e `release_capabilities.dart:122-125`).
4. **Expiração de sessão centralizada em um único ponto**, com a exclusão correta de
   401 de domínio (`api_client.dart:97-117`).
5. **Fail-closed real nos dois portões**, incluindo o caso de config ausente/inválida
   (`release_capability_policy.dart:257-260,629-644` → `configuration_status: invalid_fail_closed`)
   e o snapshot `denied()` no app.
6. **`battle_live` contido por teste, não por disciplina**
   (`app/test/core/config/release_capability_surface_contract_test.dart:112-147`).

---

## 8. Limites desta auditoria

- Nada foi executado. **Nenhum achado aqui é PROVADO por prova viva**; todos são
  leitura estática. Para cada achado de severidade alta indiquei em §4.3 e na tabela
  §6 qual teste fecharia a questão.
- Não avaliei correção de regra de MTG, qualidade de deck, desempenho nem visual.
- A árvore de trabalho tem alterações não commitadas (`server/routes/community/marketplace/index.dart`
  ganhou filtros de privacidade de dono — visibilidade de fichário/perfil e bloqueios).
  Li o arquivo no estado da árvore, não no `HEAD`; isso não muda caminho nem método da rota.
- O estado all-OFF de `server/config/release_capabilities.json` é o do commit
  `b2d3fc04f`, sem diff local. Ele descreve o repositório, **não** prova o que está
  implantado em produção — conforme `docs/status/CURRENT_PRODUCT_DECISION.md:30-31`.
