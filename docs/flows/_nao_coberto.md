# O que ficou de fora da documentação de fluxos — crítica de completude

Data: 2026-09-21 (rodada 2, refeita depois que `battle_replay.md` e `release_operations.md`
foram reescritos às 23:21/23:22). Repo lido em modo somente-leitura: nenhum arquivo do
repositório foi alterado, nenhum teste, build, emulador ou servidor foi executado.

Documentos auditados: os 11 `.md` de `scratchpad/flows/` que não começam com `_`.
**Os 11 fluxos previstos existem — nenhum ficou NÃO DOCUMENTADO.**

Convenção mantida em toda a página:

- **IMPLEMENTADO** = existe código no disco.
- **ALCANÇÁVEL HOJE** = a política de capability (`server/config/release_capabilities.json`,
  `policy_version: brewtact_free_beta_2026-08-13`, **29 capabilities, todas `allowed: false`**)
  deixa chegar lá.
- **PROVADO** = existe teste ou evidência que exercita o caminho.

---

## 0. Método e veredito

1. Grep literal dos 120 caminhos de `_all_server_routes.txt` nos 11 `.md`; para os que
   falharam, segundo grep pelo **path HTTP** (vários documentos citam a rota pelo endpoint e
   não pelo arquivo).
2. Grep de cada caminho de rota de `app/lib/main.dart` (`_all_app_routes.txt`) nos 11 `.md`.
3. Varredura de superfície **não-rota**: os 16 `_middleware.dart` de `server/routes`
   (excluídos do inventário de 120 por construção), `showModalBottomSheet`, `showDialog`,
   `MethodChannel`, `Timer.periodic`, FCM, deep links (AndroidManifest + Info.plist),
   os 143 arquivos de `server/bin`, os 95 de `scripts/`, `web-public/`, `services/`,
   `.github/`, e-mail transacional e webhooks.
4. Conferência programática de todos os caminhos de `implementation`/`tests`/`gates`/
   `canonical_documents`/`traceability` de `docs/project_logic_contracts.json` contra o disco.

**Veredito em uma linha:** a cobertura de **rota** está completa — as 120 rotas de servidor e
as 46 rotas reais de app aparecem em algum documento. Todo o buraco está em **superfície
não-rota**, e ele é grande: **5 middlewares de servidor**, **31 dos 32 arquivos do contador de
vida**, **15 dos 22 arquivos do host Lotus**, o canal de plataforma e a `MainActivity` nativa,
4 bottom sheets/diálogos, o egress de e-mail transacional, **um terceiro portão fail-closed de
capability que nenhum documento cita**, um site público inteiro (`web-public/`) e
**136 dos 143 arquivos de `server/bin`**, onde mora a maior parte da escrita de dado de produto.

---

## 1. Rotas de servidor fora de todos os documentos: **nenhuma**

O grep literal por caminho de arquivo falhou em 15 rotas; as 15 aparecem pelo path HTTP.
Registro para ninguém refazer o trabalho:

| Arquivo de rota | Onde de fato aparece |
|---|---|
| `server/routes/ai/commander-reference/index.dart` | `deck_ai.md:175,177` (rota órfã) |
| `server/routes/ai/ml-status/index.dart` | `deck_ai.md:114,175` |
| `server/routes/ai/optimize/telemetry/index.dart` | `deck_ai.md:114,175` |
| `server/routes/ai/simulate-matchup/index.dart` | `deck_ai.md:55,114,175` |
| `server/routes/ai/weakness-analysis/index.dart` | `deck_ai.md:114,175` |
| `server/routes/community/decks/[id]/reports/index.dart` | `deck_lifecycle.md`, `social_trade.md` |
| `server/routes/conversations/[id]/read.dart` | `social_trade.md` |
| `server/routes/decks/[id]/battle-replays/[replayId]/annotations/[annotationId].dart` | `battle_replay.md` |
| `server/routes/decks/[id]/recommendations/index.dart` | `deck_ai.md:114,175,177`; `deck_lifecycle.md:163` |
| `server/routes/decks/[id]/simulate/index.dart` | `deck_ai.md:55,114,175`; `deck_lifecycle.md:163` |
| `server/routes/health/ai-history/index.dart` | `release_operations.md` |
| `server/routes/health/dashboard/index.dart` | `release_operations.md` |
| `server/routes/moderation/reports/[id]/index.dart` | `social_trade.md:201`, `release_operations.md` |
| `server/routes/users/[id]/following/index.dart` | `social_trade.md:41,46,174,179` |
| `server/routes/users/me/export/index.dart` | `auth_session.md` |

Higiene: quem reconferir cobertura por script precisa casar **path HTTP**, não caminho de arquivo.

---

## 2. Rotas de app fora de todos os documentos: **nenhuma** — mas a declaração do último lote erra em 4 pontos

As 46 rotas reais aparecem em algum `.md`. `_all_app_routes.txt` lista 48 linhas `path:` porque
`/` e `/verify-email` aparecem duas vezes cada — uma na checagem de rota boot-safe
(`app/lib/main.dart:363-371`) e outra na `GoRoute` de verdade.

| Erro na lista declarada pelo lote | Realidade no código |
|---|---|
| `/decks/import` não declarado | Existe (`app/lib/main.dart:569`, `DeckImportScreen`); documentado em `deck_lifecycle.md:325,530` |
| `/decks/:id/post-game` não declarado | Existe (`app/lib/main.dart:616-655`, `PostGameNotesScreen`); documentado em `life_counter_post_game.md` |
| `/trades/create/:receiverId` não declarado | Existe (`app/lib/main.dart:877-897`, `CreateTradeScreen`); documentado em `social_trade.md` e `binder_collection_scanner.md` |
| `/decks/:id/battle-coach` declarado duas vezes, uma como rota e uma como redirect | Só existe como redirect (`app/lib/main.dart:715-722`). `battle_replay.md:81` registra certo; a declaração do lote é que está errada |

Nota: `/life-counter` é `lifeCounterRoutePath`, constante em
`app/lib/features/home/life_counter_route.dart:4`, usada em `app/lib/main.dart:305,357,492`.

---

## 3. Superfícies **não-rota** fora de todos os documentos

Agrupadas pelo fluxo-destino.

### 3.0 → todos os fluxos de servidor: **5 `_middleware.dart` sem uma linha em lugar nenhum** *(achado novo desta rodada)*

`server/routes` tem 16 `_middleware.dart`. O inventário de 120 rotas os exclui por construção,
então ninguém os auditou. Onze estão citados; **cinco não aparecem em nenhum dos 11 `.md`**:

| Middleware | O que aplica | Fluxo-destino | Teste |
|---|---|---|---|
| `server/routes/import/_middleware.dart:8` | só `authMiddleware()` | `deck_lifecycle` | nenhum que o nomeie |
| `server/routes/trades/_middleware.dart:6` | `verifiedEmailForMutations()` + `authMiddleware()` | `social_trade` | `server/test/email_verification_contract_test.dart:58` (leitura de string) |
| `server/routes/content-reports/_middleware.dart:7` | `verifiedEmailForMutations()` + `authMiddleware()` | `social_trade` | **nenhum** — o teste de e-mail verificado lista só 4 arquivos (`:57-60`) e este não está entre eles |
| `server/routes/decks/[id]/ai-analysis/_middleware.dart:7-10` | `aiRateLimit()` + `aiPlanLimitMiddleware()` + `authMiddleware()` | `deck_ai` / `commercial_plans` | `server/test/ai_middleware_order_contract_test.dart:137` (leitura de string) |
| `server/routes/decks/[id]/recommendations/_middleware.dart:7-10` | idem | `deck_ai` | `server/test/ai_middleware_order_contract_test.dart:141` |

Dois fatos que decorrem daí e que **nenhum documento estabelece**:

1. **A fronteira de e-mail verificado é assimétrica e a assimetria não está escrita.**
   Exigem e-mail verificado para mutação: `binder`, `community`, `conversations`, `trades`,
   `content-reports`. **Não exigem**: `decks` (`server/routes/decks/_middleware.dart:8`),
   `import` (`:8`), `users` (`:6`), `notifications` (`:6`), `ai` (`server/routes/ai/_middleware.dart:63-89`).
   Consequência concreta: `POST /import/to-deck` cria deck sem e-mail verificado, enquanto
   `POST /binder` é bloqueado com 403 `email_verification_required`
   (`server/lib/verified_email_middleware.dart:38-47`). Isso pode ser desenho (privado x público),
   mas é uma regra de produto não declarada em nenhum dos 11 documentos nem no contrato.
2. **Duas rotas `/decks/**` consomem cota de IA por middleware próprio.** `deck_ai.md:158`
   registra isso para `ai-analysis`; para `recommendations` não há registro nenhum — e
   `recommendations` é exatamente uma das rotas que `deck_ai.md:114,175` classifica como
   "sem chamador no app". Ou seja: uma rota órfã com `aiPlanLimitMiddleware()` montado.

Classificação: IMPLEMENTADO sim; ALCANÇÁVEL hoje conforme a capability da rota abaixo deles;
PROVADO só por asserção de string sobre o fonte (nenhum middleware é montado em teste).

### 3.1 → `life_counter_post_game`

#### (a) 31 dos 32 arquivos de `app/lib/features/home/life_counter/` não são nomeados

`life_counter_post_game.md` nomeia **um** arquivo do diretório: `life_counter_session_store.dart`.
Ficam de fora, sem passo, store, estado de erro ou teste declarado:

- **14 folhas nativas** `life_counter_native_*_sheet.dart` (card_search, commander_damage,
  day_night, dice, game_modes, game_timer, history, player_appearance, player_counter,
  player_state, set_life, settings, table_state, turn_tracker).
- **6 motores/estado**: `life_counter_dice_engine.dart`, `life_counter_tabletop_engine.dart`,
  `life_counter_turn_tracker_engine.dart`, `life_counter_game_timer_engine.dart`,
  `life_counter_game_timer_state.dart`, `life_counter_day_night_state.dart`.
- **8 stores/transfers**: `life_counter_history_store.dart`, `life_counter_history_transfer.dart`,
  `life_counter_settings_store.dart`, `life_counter_settings_catalog.dart`,
  `life_counter_player_appearance_profile_store.dart`,
  `life_counter_player_appearance_transfer.dart`,
  `life_counter_game_timer_state_store.dart`, `life_counter_day_night_state_store.dart`.
- `life_counter_session.dart`, `life_counter_settings.dart`, `life_counter_history.dart`.

**Quem chama:** o bundle web dispara `open-native-*` via
`app/lib/features/home/lotus/lotus_native_surface_bridge.dart`; o despacho está em
`app/lib/features/home/lotus_life_counter_screen.dart:737-870`, com a allowlist dos 5 tipos que
exigem `targetPlayerIndex` em `:115-121`.
**Capability:** `life_counter_local` — rota `/life-counter` negada em `release_capabilities.dart:363-364`; entrada da Home condicionada em `home_screen.dart:114,123,160`.
**Teste:** 13 das 14 folhas têm teste de widget em `app/test/features/home/`.
**`life_counter_native_commander_damage_sheet.dart` não tem teste nenhum** — e é justamente uma
das que dependem de `targetPlayerIndex` vindo do bundle web.

Isto importa mais do que parece: a memória do projeto declara o contador como **régua visual e
funcional do app inteiro**. O fluxo que deveria servir de padrão é o que tem a maior razão
código-documentado/código-total de todos os 11.

#### (b) Erro de contagem no próprio documento: "16 folhas" são **14**

`life_counter_post_game.md:69` e `:89` dizem "16 folhas". São 14: contei os tipos
`open-native-*` distintos (`git grep -oh "open-native-[a-z-]*" app/lib` → 14 tipos + o prefixo
solto) e os arquivos `*_sheet.dart` do diretório; os dois números fecham em 14. A própria linha
`:69` lista 14 nomes entre parênteses.

#### (c) `MethodChannel 'manaloom/life_counter_lifecycle'` e a `MainActivity` nativa — zero menção

- **Lado Dart:** `app/lib/features/home/lotus_life_counter_screen.dart:107-109`.
- **Lado Android:** `app/android/app/src/main/kotlin/com/mtgia/mtg_app/MainActivity.kt:13,22-26`
  cria o canal; `:45-52` emite `userLeaveHint` em `onUserLeaveHint()`; `:54+` emite
  `activityPaused` em `onPause()`.
- **Por que importa:** é a **terceira** ponte do contador (além dos bridges JS de
  `lotus_js_bridges.dart:78-118` e do `lotus_native_surface_bridge.dart`), e a seção 2 do
  documento descreve só as duas primeiras. Grep por `MethodChannel` e `MainActivity` nos 11
  `.md` = **zero**.
- **Teste:** nenhum documento aponta um; o lado Kotlin não tem teste no repo.

#### (d) 15 dos 22 arquivos de `app/lib/features/home/lotus/` não são nomeados

Fora de todos os documentos: `lotus_host.dart`, `lotus_default_host.dart`,
`lotus_default_host_native.dart`, `lotus_webview_contract.dart`, `lotus_web_document.dart`,
`lotus_shell_policy.dart`, `lotus_presentation_mode.dart`, `lotus_visual_skin.dart`,
`lotus_ui_snapshot.dart`, `lotus_ui_snapshot_store.dart`, `lotus_storage_snapshot_store.dart`,
`lotus_lifecycle_diagnostic_store.dart`, `lotus_life_counter_session_adapter.dart`,
`lotus_life_counter_settings_adapter.dart`, `lotus_life_counter_game_timer_adapter.dart`.

O documento cita `lotus_js_bridges.dart`, `lotus_native_surface_bridge.dart`,
`lotus_host_controller.dart`, `lotus_host_overlays.dart`, `lotus_default_host_web.dart`,
`lotus_storage_snapshot.dart` e `lotus_runtime_flags.dart`. O buraco relevante é
`lotus_shell_policy.dart` + `lotus_webview_contract.dart`: é onde a política de casca e o
contrato de WebView vivem, e o achado A14 do próprio documento (sandbox
`allow-scripts`+`allow-same-origin` em `lotus_default_host_web.dart:70-73`) só pode ser avaliado
com esses dois na mesa.

### 3.2 → `home_onboarding_notifications`

#### (e) Bottom sheet `_PlayEntrySheet` — a porta de entrada do "Jogar agora"

- **O que é:** `showModalBottomSheet<_PlayEntrySelection>` em
  `app/lib/features/home/home_screen.dart:132-147`, construído por `_openPlayEntry` (`:112`).
- **Quem chama:** a Home. É a superfície que decide entre retomar sessão, encerrar sessão,
  partida rápida e partida com deck (`:150-175`).
- **Capability:** o sheet **consulta três capabilities antes de montar** —
  `_lifeCounterAllowed` (`:114`), `ReleaseCapability.decksPrivate` (`:115`) e
  `ReleaseCapability.learningWrites` (`:116-118`) — e reconsulta depois do `await` do store
  (`:122-127`), o que é o padrão correto e não está documentado.
- **Situação:** `life_counter_post_game.md:64` cita `_openPlayEntry` como passo 1, mas o
  **sheet** (`_PlayEntrySheet`), suas 4 ações e a tripla checagem de capability não aparecem;
  grep por `_PlayEntrySheet` nos 11 `.md` = zero. `home_onboarding_notifications.md` não tem
  nenhuma menção a bottom sheet.
- **Teste:** nenhum documento aponta um.

#### (f) Canal de notificação Android `manaloom_notifications` — zero menção

- **O que é:** `MainActivity.kt:14,29-43` cria o `NotificationChannel` com id
  `manaloom_notifications`, nome "BrewTact" e `IMPORTANCE_DEFAULT`.
- **Por que importa:** `home_onboarding_notifications.md` documenta `push_notification_service.dart`,
  `POST /users/me/fcm-token` e o `NotificationPermissionBoundary`, mas não o canal — e no
  Android 8+ um push sem canal correspondente **não aparece**. É o elo nativo que decide se o
  fluxo de push funciona no dispositivo.
- **Teste:** nenhum no repo para o lado Kotlin.

### 3.3 → `deck_lifecycle`

#### (g) Bottom sheet de evidência do diagnóstico — zero menção, e já é PROVADO

- **O que é:** `_showDiagnosticEvidenceSheet` em
  `app/lib/features/decks/widgets/deck_diagnostic_panel.dart:605-625`, aberto de `:171` e `:202`.
- **Quem chama:** `DeckDiagnosticPanel`, montado em
  `app/lib/features/decks/widgets/deck_details_overview_tab.dart:321`, dentro de `/decks/:id`.
- **Capability:** herdada de `decks_private` pela rota; o painel não consulta capability.
- **Teste:** **existe** — `app/test/features/decks/widgets/deck_diagnostic_panel_test.dart:333-345`.
- **Situação:** grep por `deck_diagnostic_panel` nos 11 `.md` = **zero**. É IMPLEMENTADO +
  PROVADO e mesmo assim invisível. `deck_lifecycle.md:335` cita `DeckDiagnosticPanel` só de
  passagem, ao criticar `docs/LAYOUT_TEST_MAP.md`.

#### (h) Diálogo seletor de comandante — zero menção, e esconde dependência de capability

- **O que é:** `DeckCommanderSelector._openPicker` em
  `app/lib/features/decks/widgets/deck_commander_selector.dart:31-46` abre o `showDialog`
  `_CommanderPickerDialog` (`:291-587`).
- **Quem chama:** `app/lib/features/decks/screens/deck_generate_screen.dart:1222` e
  `app/lib/features/decks/screens/deck_list_screen.dart:288` — os **dois** pontos de criação de
  deck Commander.
- **Capability — este é o ponto:** o picker chama `CardProvider.searchCommanderCandidates`
  (`app/lib/features/cards/providers/card_provider.dart:119-156`) → `_fetchPage` →
  `GET /cards?name=…&commander_format=…` (`:190-192`). `GET /cards` é **`catalog_private`**.
  Portanto **criar deck Commander (`decks_private`) tem dependência dura e não declarada de
  `catalog_private`**. `card_catalog.md:409` flagra o acoplamento no sentido catálogo→deck;
  ninguém registra o inverso.
- **Teste:** a chave `deck-create-commander-search-field`
  (`deck_commander_selector.dart:459`) não aparece em nenhum `.md` nem em `docs/LAYOUT_TEST_MAP.md`.

### 3.4 → `social_trade`

#### (i) Dois bottom sheets de binder/trade sem menção

| Superfície | Onde | Quem chama | Capability | Teste |
|---|---|---|---|---|
| Ações sobre item de binder alheio (`_onInteract`) | `app/lib/features/social/screens/user_profile_screen.dart:1230-1250` | aba de binder do perfil público, `listType` `have`/`want` | `binder_public` + `trades` pela rota | nenhum nomeado |
| Seletor de item da proposta (`_showItemPicker`) | `app/lib/features/trades/screens/create_trade_screen.dart:809-830` | `/trades/create/:receiverId`, os dois lados da proposta | `trades` | nenhum nomeado |

`social_trade.md` e `binder_collection_scanner.md` citam os dois **arquivos**, nunca as duas
folhas. O `_showItemPicker` é o único caminho para escolher o que se oferece numa troca — é o
passo central do fluxo comercial entre usuários.

#### (j) `TradeProposalDeepLink` — e o fato de que **não existe deep link de SO**

- **O que é:** `app/lib/features/trades/trade_route_contract.dart:68-99`, parser de
  `?type=&item=&source=&deck=&counter=` consumido em `app/lib/main.dart:881` para montar
  `CreateTradeScreen`.
- **Teste:** `app/test/features/trades/trade_route_contract_test.dart:28,46,55` — PROVADO.
- **Situação:** grep por `TradeProposalDeepLink` nos 11 `.md` = zero.
- **Fato que nenhum documento estabelece:** **não há deep link de sistema operacional neste app.**
  `app/android/app/src/main/AndroidManifest.xml:57-60` tem só o `intent-filter`
  `MAIN`/`LAUNCHER` — nenhum `android:scheme`, `android:host` ou `autoVerify`.
  `app/ios/Runner/Info.plist` não tem `CFBundleURLTypes` nem associated-domains. Logo o
  "deep link" de trade é contrato de query-string **interno ao roteador**, alcançável só por
  navegação dentro do app. Precisa estar escrito: a ausência muda a superfície de ataque e
  muda o que um push consegue abrir.

#### (k) Crons de preço, staples e combos — os escritores dos números que o fluxo exibe

| Cron | Alvo | Tabelas escritas |
|---|---|---|
| `server/bin/cron_sync_prices.sh:15` | `server/bin/sync_prices.dart:121` | `price_history` |
| `server/bin/cron_sync_prices_mtgjson.sh:47` | `sync_prices_mtgjson_fast.dart` | preços |
| `server/bin/cron_snapshot_price_history.sh:33` | `snapshot_price_history.dart:26` | `price_history` |
| `server/bin/cron_sync_staples.sh:34` | `sync_staples.dart:319,440` | `format_staples`, `sync_log` |
| `server/bin/cron_sync_combos.sh:35` | `sync_combos.dart` | `card_combos` (`:503` DELETE, `:600` INSERT), `combo_cards` (`:630,650`), `card_function_tags` (`:694,708`), `data_source_snapshots` (`:515`) |

Tabelas sem uma menção nos 11 documentos: `card_combos`, `combo_cards`, `format_staples`,
`data_source_snapshots`, `sync_state`. `social_trade.md:211` nomeia `price_history` mas nunca
quem a escreve: o documento descreve `/market`, `/quotes` e `/marketplace` sem dizer de onde
vem o número na tela.

### 3.5 → `auth_session`

#### (l) Egress de e-mail transacional (Resend + webhook arbitrário) — praticamente sem documentação

- **O que é:** `server/lib/account_email_delivery_transport.dart` (318 linhas), dois provedores:
  **Resend**, endpoint fixo `https://api.resend.com/emails` (`:11`), e um ramo **webhook
  genérico** cuja URL e token vêm de variáveis de ambiente (`:115-140`, com validação de
  esquema/host/`userInfo` e exigência de HTTPS em produção em `:131-136`). Seleção do provedor
  em `:104-112`; configuração em `server/lib/account_email_delivery_config.dart`.
- **Quem chama:** `server/lib/email_verification_delivery_service.dart:4-17` e
  `server/lib/password_reset_delivery_service.dart`, consumidos por
  `server/routes/auth/register.dart` e `server/routes/auth/resend-verification.dart`;
  preflight em `server/bin/auth_runtime_preflight.dart`.
- **Capability:** os endpoints de auth são plano de controle (allowlist em
  `server/lib/release_capability_policy.dart:590-620`), então o egress **é alcançável hoje**
  sempre que houver credencial no ambiente — diferente de quase todo o resto do produto.
- **Teste:** `server/test/account_email_delivery_transport_test.dart`,
  `server/test/user_facing_brand_contract_test.dart` — PROVADO.
- **Situação:** `auth_session.md:328` cita `password_reset_delivery_service.dart` uma vez,
  dentro de um bloco de env. Grep por `account_email_delivery` e
  `email_verification_delivery_service` nos 11 `.md` = **zero**; as 14 ocorrências de "resend"
  em `auth_session.md` são todas da rota `/auth/resend-verification`, não do provedor.
  Um fluxo de autenticação que documenta 8 caminhos de rate limit e não documenta **para onde o
  e-mail sai** está incompleto no ponto que mais importa para privacidade.

### 3.6 → `release_operations`

#### (m) **Existe um TERCEIRO portão fail-closed de capability, e nenhum documento o menciona**

Achado mais grave da auditoria: contradiz um contrato que dois documentos declaram verificado.

- **O que é:** `server/bin/manaloom_ops_daemon.py` (1.170 linhas).
  - `_load_release_policy` (`:145-197`) lê **o mesmo** `server/config/release_capabilities.json`
    (`:54`); envelope inválido ⇒ `ReleasePolicy(False, digest, {})` (`:194,196`) — **fail-closed**.
  - `_load_runtime_release_policy` (`:200-205`) recusa qualquer caminho que não seja o canônico,
    devolvendo política inválida — trava de caminho que os outros dois portões não têm.
  - Registro `JOBS` (`:565-709`): **16 jobs**, cada um com sua expressão cron.
  - `JOB_REQUIRED_CAPABILITIES` (`:711-734`) mapeia cada job para capabilities do **mesmo
    vocabulário do servidor**: `ai_analyze_optimize_advisory`, `learning_writes`,
    `catalog_private`, `battle_batch`.
  - `_jobs_for_release_policy` (`:737-746`) filtra: um job só roda se **todas** as suas
    capabilities estiverem `allowed`. Com 29/29 `off`, **15 dos 16 jobs não rodam**; o único
    isento é `hermes_cron_governor_report` (`:731-734`, comentado como o único housekeeping
    sem capability).
  - `_start_disabled_ops_health` (`:395-465`) sobe um `ThreadingHTTPServer` que responde
    **`GET /health`** (404 em qualquer outro path, `:413-415`) na porta
    `MANALOOM_NATIVE_BATTLE_PORT` (default **8080**, `:455`), devolvendo `policy_digest_sha256`,
    `operational_mode: safe_housekeeping_only`, `engine_contract` e o estado de
    `battle_batch`/`learning_writes` (`:416-441`). **Não é rota dart_frog** e não está em
    `_all_server_routes.txt`.
- **Correção da rodada anterior:** a versão anterior deste arquivo dizia "17 jobs". São **16**
  (contagem de `name=` em `:565-709` e de chaves em `JOB_REQUIRED_CAPABILITIES`), e dois deles
  — `manaloom_new_card_candidate_review` (`:608-615`, cron `40 */6 * * *`, `catalog_private`) e
  `manaloom_card_data_gap_review` (`:618-622`, cron `50 */6 * * *`, `catalog_private`) — não
  tinham sido listados.
- **Teste:** `server/test/manaloom_ops_daemon_test.py`; o contrato de `/health` é reasserido no
  deploy por `scripts/manaloom_deploy_ops_image.sh:366` (digest da política, `len==29`, todas
  `off`, `enabled_jobs == ['hermes_cron_governor_report']`).
- **Contradição documental:** `release_operations.md:19` afirma "os dois portões são coerentes
  entre si" e `:288` dá `docs/MAPA_OPERACIONAL_DO_PROJETO.md:62-70` como "confere integralmente".
  Confere para os dois portões que a MAPA descreve — mas existe um terceiro consumidor do mesmo
  arquivo de política, com seu próprio fail-closed, sua própria trava de caminho e sua própria
  superfície HTTP. `git grep release_capabilities.json` fora de `docs/` dá exatamente três
  consumidores de runtime: `server/lib/release_capability_policy.dart:7`,
  `app/test/core/config/release_capability_surface_contract_test.dart:166` (espelho do portão do
  app) e `server/bin/manaloom_ops_daemon.py:54`. Grep por `ops_daemon`,
  `JOB_REQUIRED_CAPABILITIES` nos 11 `.md` = **zero**.
- **Classificação:** IMPLEMENTADO sim; ALCANÇÁVEL hoje **parcialmente** (1 de 16 jobs);
  PROVADO sim; **DOCUMENTADO não**.

#### (n) A porta 8080 é disputada entre o daemon de ops e o sidecar de batalha nativa

`server/bin/native_battle_sidecar.py:324` usa **a mesma** `MANALOOM_NATIVE_BATTLE_PORT`
(default 8080) e serve `POST /simulate` (`:285`) e `/cards/coverage` (`:282`). O
`_start_disabled_ops_health` do daemon ocupa essa porta justamente para anunciar
`engine_contract: disabled_by_release_capability` no lugar do motor. Isso é o mecanismo pelo qual
"o motor nativo está desligado" vira verdade observável — e não está escrito em lugar nenhum.
`native_battle_sidecar.py` e `native_battle_worker.py`: zero menção nos 11 `.md`
(`battle_replay.md` documenta os sidecars XMage/Forge de `services/`, que são outros).

#### (o) Site público `web-public/` (Next.js) — fluxo inteiro sem documento

- **O que é:** aplicação Next.js separada: 8 páginas públicas + 3 rotas de infraestrutura —
  `web-public/src/app/page.tsx`, `pricing/page.tsx`, `blog/page.tsx`, `blog/[slug]/page.tsx`,
  `legal/terms/page.tsx`, `legal/privacy/page.tsx`, `legal/disclaimer/page.tsx`,
  `reports/[id]/page.tsx`, `healthz/route.ts`, `robots.ts`, `sitemap.ts`.
- **Quem chama:** o público geral. `reports/[id]` consome `GET /reports/{id}`, que é anônimo por
  desenho (`server/routes/reports/[id].dart:7-23`, sem `authMiddleware`; liberado por regex em
  `server/lib/release_capability_policy.dart:584-585`) e está em `public_api_paths` do contrato.
- **Capability:** nenhuma. **É a superfície de produto mais alcançável que existe hoje**, mais
  do que o app.
- **Teste/gate:** `web-public/tests/free-beta-offer-contract.mjs`,
  `scripts/manaloom_public_web_surface_contract_test.sh`, `scripts/manaloom_public_web_smoke.sh`;
  deploy por `scripts/manaloom_deploy_public_web.sh`.
- **Situação:** grep por `web-public`, `manaloom_deploy_public_web`, `manaloom_public_web_smoke`
  nos 11 `.md` = **zero**. `release_operations.md` documenta o deploy do backend, dos sidecars
  e do Flutter web e **pula o site público**. `commercial_plans.md` documenta `/plans`,
  `/upgrade` e `/checkout` do app e não menciona que existe uma página `pricing` pública com
  contrato de oferta testado.
- **Ligação cruzada:** `release_operations.md:267` já registra que `GET /reports/<id>` deixa
  qualquer anônimo inflar o mapa de métricas. O consumidor legítimo dessa rota
  (`web-public/src/app/reports/[id]/page.tsx`) não é nomeado em lugar nenhum, o que torna
  impossível avaliar o custo de fechar a rota.

#### (p) Dois outros orquestradores de cron sem menção

| Arquivo | O que faz | Teste |
|---|---|---|
| `server/bin/hermes_lab_cron_bootstrap.py` (551 linhas) | instala um **segundo** conjunto de crons (laboratório Hermes); agenda `sync_battle_card_rules_pg.py` (`:110`), `gate.py` (`:72,83,93,103,203-221`) e `hermes_docs_branch_sync.sh` (`:448`) | `server/test/hermes_lab_cron_bootstrap_test.py` |
| `server/bin/audit_easypanel_cron_runtime.py` | audita a configuração de cron do runtime de produção | `server/test/audit_easypanel_cron_runtime_test.py` |

Grep por ambos nos 11 `.md` = zero. `sync_battle_card_rules_pg.py` escreve em Postgres: é mutação
de dado de produto agendada **fora** do daemon com portão de capability.

#### (q) Cobertura de `scripts/` e ausência de CI declarativa

Dos 95 itens de `scripts/`, **22 aparecem em algum `.md`**; 73 não. Entre os ausentes, os que
importam por mutarem ou publicarem produto: `manaloom_deploy_ops_image.sh` (deploy do daemon do
achado (m)), `manaloom_deploy_public_web.sh`, `manaloom_publish_android_release.sh`,
`manaloom_build_android_release.sh`, `manaloom_install_remote_backup_cron.sh`,
`manaloom_offsite_backup.sh`, `manaloom_full_restore_drill.sh`, `manaloom_validate_restore.sh`,
`manaloom_easypanel_backup.sh`, `manaloom_release_capabilities_contract_test.sh`,
`manaloom_release_observability_gate.sh`, `manaloom_project_logic.sh` (gerador do
`project_logic_manifest.json`).
Fato adicional que nenhum documento estabelece: **`.github/` não tem `workflows/`** — só
`AGENT_POLICY.md`, `instructions/` e `agents/`. Não existe CI declarativa no repo; todo portão é
script local + hook (`scripts/manaloom_install_local_hooks.sh`). `release_operations.md` fala
em "portões" sem dizer quem os dispara.

### 3.7 → `card_catalog`

#### (r) Crons que escrevem `cards`, `sets` e legalidades — nenhum documentado como passo

Só **7 dos 143** arquivos de `server/bin` aparecem em algum `.md` — `battle_job_worker.dart`,
`migrate.dart`, `sync_cards.dart`, `sync_rulings.dart`, `sync_staples.dart`, `sync_status.dart`,
`verify_schema.dart` — e mesmo esses aparecem como nome solto, nunca como passo com tabela,
agendamento e capability.

| Cron | Alvo | Tabelas escritas |
|---|---|---|
| `server/bin/cron_sync_cards.sh:19,61` | `sync_cards.dart` (855 linhas) | `cards` (`:700`), `sets` (`:568`), `card_legalities` (`:847`), `sync_log` (`:373`), `sync_state` (`:301`) |
| `server/bin/cron_sync_rulings.sh:34` | `sync_rulings.dart` | rulings de carta |
| `server/bin/sync_card_legalities_from_scryfall.sh` | job `manaloom_sync_card_legalities_from_scryfall` (`manaloom_ops_daemon.py:598-605`), cron `30 */6 * * *`, capability **`catalog_private`** (`:715`) | `card_legalities` |
| `server/bin/manaloom_new_card_candidate_review.sh` | job `:608-615`, cron `40 */6 * * *`, `catalog_private` (`:716`) | revisão de candidatos a carta nova |
| `server/bin/manaloom_card_data_gap_review.sh` | job `:618-622`, cron `50 */6 * * *`, `catalog_private` (`:717`) | revisão de lacuna de dado de carta |
| `server/bin/sync_localized_card_names.dart:244` | — | `card_localized_names` |
| `server/bin/seed_database.dart:79`, `seed_legalities.dart:35`, `seed_rules.dart:126` | — | `cards`, `card_legalities`, `rules` |
| `server/bin/backfill_card_image_urls.py`, `backfill_card_combat_metadata.py`, `backfill_card_identity_columns.dart` | — | colunas de `cards` |

**Por que importa para este fluxo:** `card_catalog.md:279` critica o `CURRENT_PRODUCT_DECISION`
por chamar o catálogo de "read-only" e aponta que `GET /cards/printings?sync=true` escreve em
`cards`/`sets` (achado A9). O argumento fica pela metade: a escrita **dominante** no catálogo não
vem da rota, vem desses crons. `sync_state` não aparece em nenhum `.md`.

### 3.8 → `deck_ai`

#### (s) Job de retenção que apaga as tabelas que o documento descreve

- **O que é:** `server/bin/cron_cleanup_optimize_telemetry.sh:8` →
  `server/bin/cleanup_optimize_telemetry.dart` (309 linhas):
  `DELETE FROM ai_optimize_fallback_telemetry` (`:230`), `ai_logs` (`:237,246`),
  `rate_limit_events` (`:256`), `ai_generate_jobs` (`:264`), `ai_optimize_jobs` (`:272`).
- **Quem chama:** job `manaloom_ai_runtime_cleanup` (`manaloom_ops_daemon.py:567-582`), cron
  `10 4 * * *`, capability **`ai_analyze_optimize_advisory`** (`:712`). Retenções por env:
  `TELEMETRY_RETENTION_DAYS` (`:38`), `AI_LOG_RETENTION_DAYS` (`:63`),
  `RATE_LIMIT_EVENT_RETENTION_HOURS` (`:54`) e **`AI_JOB_RETENTION_MINUTES`** (`:72`).
- **Por que fere o documento:** `deck_ai.md` gasta seções inteiras em job assíncrono, retomada e
  cancelamento de `ai_generate_jobs`/`ai_optimize_jobs` sem registrar que **um cron os apaga por
  janela de minutos**. Retomada de job e retenção são o mesmo assunto, documentados em lados
  opostos do silêncio.
- `ai_optimize_fallback_telemetry` e `rate_limit_events`: zero menção nos 11 `.md`.

#### (t) Pipeline de aprendizado (`learning_writes`) — escritores nunca nomeados

`deck_ai.md` nomeia `commander_learned_decks` e `deck_learning_events` como storage, mas não
nomeia nenhum processo que os alimenta:

| Script | Job no daemon | Cron | Capability |
|---|---|---|---|
| `server/bin/pull_learning_events.sh` | `pull_learning_events` (`:584-590`) | `0 * * * *` | `learning_writes` (`:713`) |
| `server/bin/auto_sync_learned_decks.sh` | `auto_sync_learned_decks` (`:591-597`) | `0 */2 * * *` | `learning_writes` (`:714`) |
| `server/bin/auto_promote_learned_decks.sh` | `auto_promote_learned_decks` (`:646-651`) | `30 */6 * * *` | `learning_writes` (`:722`) |
| `server/bin/manaloom_knowledge_import.sh` | `manaloom_knowledge_import` (`:689-693`) | `20 */12 * * *` | `learning_writes` (`:730`) |
| `server/bin/master_optimizer_preflight.sh` | `master_optimizer_preflight` (`:682-686`) | `15 * * * *` | `ai_analyze_optimize_advisory` + `battle_batch` (`:725-728`) |
| `server/bin/hermes_mana_base_validator.sh` | `hermes_mana_base_validator` (`:696-700`) | `45 */6 * * *` | `ai_analyze_optimize_advisory` (`:731`) |
| `server/bin/cron_snapshot_edhrec.sh:39` → `snapshot_edhrec.dart` | fora do daemon | — | sem gate de capability |

Grep por `pull_learning_events`, `master_optimizer_preflight`, `snapshot_edhrec` nos 11 `.md` = zero.

### 3.9 → `battle_replay`

#### (u) Promoção automática de regra de carta e jobs de estratégia

| Item | Onde | Observação |
|---|---|---|
| `server/bin/auto_promote_battle_rules.py:205` | `UPDATE card_battle_rules SET` | tem teste próprio (`server/bin/test_auto_promote_battle_rules.py`); zero menção nos `.md` |
| `server/bin/manaloom_battle_rule_review_queue.sh` | job `:625-629`, cron `55 */6 * * *`, `battle_batch` (`:718`) | zero menção |
| `server/bin/manaloom_battle_rule_focused_evidence.sh` | job `:632-636`, cron `56 */6 * * *`, `battle_batch` (`:719`) | zero menção |
| `server/bin/manaloom_battle_rule_promotion_gate.sh` | job `:639-643`, cron `58 */6 * * *`, `battle_batch` (`:720`) | zero menção |
| `server/bin/manaloom_battle_strategy_audit.sh` | dois jobs — horário (`:653-665`) e noturno (`:669-678`, cron `5 6 * * *`) — ambos `battle_batch` (`:723-724`) | zero menção |

`battle_replay.md:283` observa que o contrato lista `card_battle_rules` e `deck_matchups` como
storage do fluxo mas "nenhuma das duas é tocada pelas rotas desta jornada". Está certo — e a
conclusão que falta é: elas são tocadas **por estes jobs**. A crítica identificou o sintoma e
parou antes da causa.

### 3.10 Superfícies verificadas e **já cobertas** (registro para não reabrir)

- Push/FCM lado Dart: `app/lib/core/services/push_notification_service.dart:88-104`
  (`onBackgroundMessage`, `onMessage`, `onMessageOpenedApp`), `POST /users/me/fcm-token`,
  `NotificationPermissionBoundary` — cobertos em `home_onboarding_notifications.md`.
  (O canal Android que os torna visíveis **não** está — achado (f).)
- Webhook de cobrança: `server/routes/billing/webhook/index.dart` e
  `server/lib/billing/payment_provider.dart` — cobertos em `commercial_plans.md`.
- Bottom sheets / diálogos cobertos: `binder_item_editor`, `card_printing_picker`,
  `deck_details_dialogs`, `deck_optimize_dialogs` / `_OptimizationSheet`
  (`deck_details_screen.dart:1751`), `social_report_dialog`, `deck_import_list_dialog`,
  `deck_card_edit_dialog`, `ai_usage_gate`.
- Polling (`Timer.periodic`): mensagens (`message_provider.dart:150`, `chat_screen.dart:65`,
  `message_inbox_screen.dart:27`), notificações (`notification_provider.dart:72`,
  `notification_screen.dart:28`) e trades (`trade_detail_screen.dart:63`) cobertos em
  `home_onboarding_notifications.md` e `social_trade.md`; polling do Battle em
  `battle_replay.md:229,255`.
- Worker `server/bin/battle_job_worker.dart` — coberto em `battle_replay.md`.
- Sidecars `services/xmage-sidecar` e `services/forge-sidecar` — cobertos em `battle_replay.md`.
- Superfície de moderação sem cliente (`/moderation/reports*`, `/content-reports/:id/appeals`) —
  registrada em `social_trade.md:68,201` (mas o middleware de `content-reports`, não — achado 3.0).
- 11 dos 16 `_middleware.dart` — citados (ver 3.0 para os 5 que faltam).

---

## 4. Os 8 fluxos de `docs/project_logic_contracts.json` × o que foi documentado

### 4.1 Arquivos declarados que sumiram do disco: **nenhum**

Conferi programaticamente 257 caminhos de `implementation`, `tests`, `gates` e `sequence` dos 8
fluxos, mais `canonical_documents` e `traceability`. **Zero ausentes** (as 4 "faltas" do script
são frases de `sequence.message` com barra, não caminhos). O contrato **não tem referência morta**
— o problema é o oposto: ele declara pouco demais.

### 4.2 `entrypoints` que existem mas mentem sobre a superfície

| Fluxo | Entrypoint declarado | Problema |
|---|---|---|
| `deck_lifecycle` | `/import` | **não é rota de app** — é `server/routes/import/index.dart` (`deck_lifecycle.md:325`) |
| `deck_lifecycle` | `/decks/generate` | pertence a `deck_ai` (capability `ai_generate_rebuild`) |
| `deck_lifecycle` | faltam `/decks/:id`, `/decks/:id/search`, `/decks/:id/scan` | é onde a edição acontece |
| `card_collection` | `/cards`, `/sets` | mistura path de servidor com rota de app no mesmo campo; a rota de app é `/cards/:cardId`, e `/sets` não existe no app (o equivalente é `/collection/sets`) |
| `battle_replay` | `/decks/{id}/battle-coach`, `.../battle-coach/{sessionId}` | **redirect-only** (`app/lib/main.dart:706-722`), com helpers `@Deprecated` (`battle_coach_screen.dart:28-35`) — `battle_replay.md:81` |
| `battle_replay` | `/ai/battle/jobs/{id}/live` | sem chamador alcançável no app (`battle_replay.md:281`) |
| `deck_ai` | `/ai/commander-reference` | rota órfã: 1.225 linhas de handler sem chamador Flutter, declarada entrypoint (`deck_ai.md:175-177`) |
| `auth_session` | os 4 declarados | faltam `/`, `/reset-password`, `/legal` e `/profile`, todos parte da jornada (`auth_session.md:276`) |
| `release_operations` | `"quality gates"`, `"release scripts"` | não são paths, são rótulos — impossível verificar por script |

Acrescento desta rodada: **nenhum fluxo declara `_middleware.dart` em `implementation`, exceto
`social_trade`** (que declara `server/routes/community/_middleware.dart` e é justamente onde
`social_trade.md:394` observa que o arquivo tem 10 linhas e não é onde a lógica mora). O portão
de capability do servidor — `server/routes/_middleware.dart` — não é `implementation` de nenhum
dos 8 fluxos, embora seja pré-condição de todos.

### 4.3 Fluxos novos que precisam ser declarados

Os documentos produziram **11** fluxos; o contrato declara **8**:

| Documento | Fluxo no contrato | Situação |
|---|---|---|
| `auth_session.md` | `auth_session` | 1:1 |
| `deck_lifecycle.md` | `deck_lifecycle` | 1:1 |
| `deck_ai.md` | `deck_ai` | 1:1 |
| `battle_replay.md` | `battle_replay` | 1:1 |
| `life_counter_post_game.md` | `life_counter_post_game` | 1:1 |
| `social_trade.md` | `social_trade` | 1:1 |
| `release_operations.md` | `release_operations` | **nome divergente** — alinhar um dos dois |
| `card_catalog.md` + `binder_collection_scanner.md` | `card_collection` | **um contrato para dois fluxos**: catálogo (`catalog_private`) e binder/scanner/import (`collection_private`, `scanner`, `binder_public`) têm capabilities, storage e telas distintos |
| `home_onboarding_notifications.md` | — | **NÃO DECLARADO** |
| `commercial_plans.md` | — | **NÃO DECLARADO** |

**A declarar (5 fluxos):**

1. **`home_onboarding_notifications`** — `/home`, `/onboarding/core-flow`, `/notifications`,
   `/profile`; `POST /users/me/fcm-token`, `/notifications*`, `POST /users/me/activation-events`
   (`app/lib/core/services/activation_funnel_service.dart:130`); `push_notification_service.dart`,
   `RealtimeNotificationCoordinator` (`app/lib/main.dart:906+`), `NotificationPermissionBoundary`,
   **e o canal Android `manaloom_notifications` (`MainActivity.kt:14,29-43`)**.
2. **`commercial_plans`** — `/plans`, `/upgrade`, `/checkout`, `/legal`;
   `GET/PUT /users/me/plan`, `POST /users/me/plan/checkout`, `POST /billing/webhook`;
   `server/lib/billing/payment_provider.dart`, `server/lib/plan_middleware.dart`;
   gate `scripts/manaloom_commercial_quality_gate.sh`.
   (Hoje a cota de IA é pré-condição de `deck_ai`, que *está* declarado — `commercial_plans.md:267`.)
3. **`binder_collection_scanner`** — separar de `card_collection`: `/collection`,
   `/collection/import`, `/collection/matches`, `/collection/latest-set`, `/decks/:id/scan`;
   `server/routes/binder/**`, `server/routes/binder/_middleware.dart`,
   `server/routes/community/binders/[userId].dart`; capabilities `collection_private`,
   `scanner`, `binder_public`, `trades`.
4. **`public_web`** — `web-public/**` (8 páginas + `healthz`/`robots`/`sitemap`), consumindo
   `GET /reports/{id}`; testes `web-public/tests/free-beta-offer-contract.mjs` e
   `scripts/manaloom_public_web_surface_contract_test.sh`; deploy
   `scripts/manaloom_deploy_public_web.sh`. **É a superfície mais alcançável do produto hoje e
   não tem dono em nenhum contrato.**
5. **`ops_cron_learning`** (fluxo próprio ou seção nomeada de `release_operations`) —
   `server/bin/manaloom_ops_daemon.py` com os 16 jobs e o `JOB_REQUIRED_CAPABILITIES`;
   `server/bin/hermes_lab_cron_bootstrap.py`; os ~20 `cron_*.sh` que mutam `cards`, `sets`,
   `price_history`, `format_staples`, `card_combos`, `card_battle_rules`,
   `commander_learned_decks`; deploy por `scripts/manaloom_deploy_ops_image.sh`.
   Hoje esse conjunto é **o maior escritor de dado de produto do sistema** e não aparece em
   nenhum dos 8 contratos, nem em `storage`, nem em `gates`.

### 4.4 Correções de contrato e de documento que decorrem do que foi verificado

1. `docs/MAPA_OPERACIONAL_DO_PROJETO.md` §2 e `release_operations.md:19,288` precisam passar de
   "**os dois portões**" para **três**, incluindo
   `server/bin/manaloom_ops_daemon.py:145-205,711-746`.
2. `life_counter_post_game.md:69,89` — trocar "16 folhas" por **14**, e acrescentar que
   `life_counter_native_commander_damage_sheet.dart` é a única sem teste.
3. `release_operations.storage` declara só `schema_migrations` e `sync_log`. Faltam, no mínimo,
   `sync_state` (`sync_cards.dart:301`) e `data_source_snapshots` (`sync_combos.dart:515`).
4. `card_collection.storage` não lista `card_localized_names`, `card_combos`, `combo_cards`,
   `format_staples` — todas escritas por cron do catálogo.
5. `deck_ai.storage` não lista `ai_optimize_fallback_telemetry` nem `ai_logs`, que o job de
   retenção apaga (`cleanup_optimize_telemetry.dart:230,237`).
6. `battle_replay.entrypoints` deve marcar `/decks/{id}/battle-coach*` como **redirect
   depreciado**, não como entrypoint.
7. `implementation` de todos os fluxos deve incluir o `_middleware.dart` do seu prefixo, e o
   contrato deve declarar `server/routes/_middleware.dart` como pré-condição comum — hoje o
   portão de capability do servidor não é `implementation` de fluxo nenhum.
8. Declarar a regra de e-mail verificado: quais prefixos exigem
   `verifiedEmailForMutations()` e quais não (achado 3.0), e ampliar
   `server/test/email_verification_contract_test.dart:57-60` para incluir
   `routes/content-reports/_middleware.dart`.
