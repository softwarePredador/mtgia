# Documentação de fluxos do BrewTact — índice

**Estado deste conjunto**

- **Documentação de apoio, não autoritativa.** As fontes de verdade continuam sendo
  `docs/project_logic_contracts.json`, `docs/MAPA_OPERACIONAL_DO_PROJETO.md` e
  `docs/status/CURRENT_PRODUCT_DECISION.md`. Onde este conjunto diverge deles, a divergência
  está registrada na §9 de cada documento — não é autorização para mudar nada.
- **Gerado em 2026-09-21 sobre o commit `d26f23a16`** (branch `codex/free-beta-release-candidate-2026-07-17`).
  Os dois últimos documentos (`battle_replay.md`, `release_operations.md`) e
  `_coerencia_transversal.md` declaram `9a9ba66de` como base de releitura.
- **Verificação estática. Nenhum teste foi executado**, nenhum servidor subiu, nenhum
  emulador/simulador foi aberto, nenhum endpoint foi chamado. Todo "PROVADO" aqui significa
  *"existe um arquivo de teste que parece cobrir isso"*, nunca *"isso passou"*.
- **Somente leitura no repositório.** Nada dentro de
  `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia` foi criado, alterado ou apagado
  por esta rodada.

**Validade das citações no HEAD atual (conferido nesta rodada)**

O HEAD hoje é `d15beb05b`, quatro commits à frente da base declarada. Rodei
`git diff --name-only d26f23a16..HEAD` filtrando `app/lib/`, `server/lib/`, `server/routes/` e
`server/config/`: **resultado vazio**. Nenhum código de produção mudou entre a base e o HEAD —
os quatro commits mexeram em `docs/`, `scripts/` (fixação de ChromeDriver), evidências de UI e
dois arquivos de teste. Portanto **todo `arquivo:linha` deste conjunto ainda resolve no HEAD**.

**Uma exceção, e ela é importante:** a árvore de trabalho tem uma alteração **não commitada** em
`server/routes/community/marketplace/index.dart` (+24/-1) que **corrige o achado A2 de
`social_trade.md`** — as três checagens de privacidade agora existem em `:40-41` (`u.binder_visibility`,
`u.profile_visibility`) e `:47` (`FROM user_blocks b`). Junto veio
`server/test/community_marketplace_privacy_contract_test.dart` (105 linhas), **não rastreado pelo git
e que é teste de string**: `File('routes/community/marketplace/index.dart').readAsStringSync()` +
`contains(...)` (`:19,28,35,54`). Ou seja: o buraco de privacidade foi tampado no disco, mas o teste
que o guarda passaria com o comportamento quebrado desde que as strings continuassem lá.

---

## Como ler

Este projeto confunde três coisas com frequência. Todos os documentos daqui as separam, e você
deve ler cada veredito sabendo qual eixo ele responde:

| Eixo | O que significa | Onde se verifica |
| --- | --- | --- |
| **IMPLEMENTADO** | Existe código no disco que faz a coisa | `arquivo:linha` em `app/lib/` ou `server/routes/` |
| **ALCANÇÁVEL HOJE** | A política de capabilities deixa a requisição chegar ao handler **e** a rota do app abrir | `server/config/release_capabilities.json` + `server/routes/_middleware.dart:105-144` + `app/lib/core/config/release_capabilities.dart:350-534` |
| **PROVADO** | Existe teste ou evidência que **exercita** o caminho | `server/test/`, `app/test/`, `app/integration_test/`, `docs/qa/ui-live/` |

**O fato que domina tudo:** `server/config/release_capabilities.json`
(`policy_version: brewtact_free_beta_2026-08-13`) tem **29 capabilities, todas com
`release_capability: "off"` e `allowed: false`** — conferido programaticamente nesta rodada
(29 chaves, 0 ligadas). Consequência mecânica: hoje **nenhuma rota de produto é alcançável**.
O middleware devolve `404 {"error":"capability_unavailable"}` para 82 dos 120 endpoints, antes de
tocar o PostgreSQL. Só as 38 combinações rota+método do plano de controle respondem. Isso é
intencional (`docs/status/CURRENT_PRODUCT_DECISION.md:5` → `NO_GO_PUBLIC_RELEASE`).

Portanto: quando um documento diz "funciona", ele está falando de **IMPLEMENTADO**. As duas
únicas superfícies com alguma alcançabilidade hoje são `auth_session` (login, recuperação,
verificação, perfil — sem auto-cadastro) e o plano de controle de `release_operations`.

Estrutura fixa de cada documento por fluxo: §1 veredito · §2 jornada passo a passo ·
§3 capabilities e portões · §4 contrato app↔servidor · §5 dados · §6 estados e erros ·
§7 testes por passo e lacunas · §8 achados · §9 divergências de contrato · §10 rodada 2
(comandos + prova viva) · §11 verificação adversarial.

**§11 é a seção mais valiosa.** É onde o próprio documento foi atacado: cada `arquivo:linha` foi
reconferido abrindo o arquivo, cada achado foi julgado (confirmado / plausível / refutado) e
achados novos foram acrescentados. Se você só tem tempo para uma seção, leia a §11 do fluxo que
te interessa antes da §1.

---

## Resumo por fluxo

Os 11 fluxos previstos existem. **Nenhum ficou NÃO DOCUMENTADO.**

| Fluxo | Impl. | Alcanç. hoje | Provado | Passos | Passos s/ teste | Achados (total · alta) | Confiança | Documento |
| --- | --- | --- | --- | ---: | ---: | --- | --- | --- |
| Autenticação, recuperação, verificação e sessão | sim | **parcial** — única jornada viva; auto-cadastro fechado (`release_capability_policy.dart:385-387`) | parcial | 19 | **8** | 14 · 2 | média-alta | [`auth_session.md`](auth_session.md) |
| Home, onboarding, notificações e retenção | sim (Home/onboarding/notif.); "retenção/growth" não é jornada própria | **parcial** — `/home` e `/onboarding` abrem mas vazias; `/notifications` negada | parcial | 24 | 5 | 17 · 3 | média-alta (o próprio doc rebaixa a média nos pontos de runtime) | [`home_onboarding_notifications.md`](home_onboarding_notifications.md) |
| Catálogo de cartas, sets, impressões, rulings e regras | sim | **não** (`catalog_private` off) | parcial — há PNG em `docs/qa/ui-live/current/ux-pack-01-*` | 11 | 8 | 26 · 4 | **média** | [`card_catalog.md`](card_catalog.md) |
| Fichário/coleção: import, editor, matches, scanner | sim | **não** (`collection_private`, `scanner`, `trades` off) | parcial | 19 | 6 | 21 · 3 | média nos achados / alta nos vereditos de eixo | [`binder_collection_scanner.md`](binder_collection_scanner.md) |
| Ciclo de vida do deck | sim | **não** (`decks_private` off) | parcial, **fraco no servidor** | 19 | 3 | 27 · 6 | média-alta | [`deck_lifecycle.md`](deck_lifecycle.md) |
| IA de deck: gerar, otimizar, completar, rebuild, explicar | sim | **não** | parcial, fraco no que importa | 29 | 7 | 12 · 2 | média-alta | [`deck_ai.md`](deck_ai.md) |
| Battle: jogar contra IA, coach, mesa ao vivo, replays | sim | **não** | parcial | 17 | 1 | 21 · 2 | média | [`battle_replay.md`](battle_replay.md) |
| Contador de vida e pós-jogo | sim | **não** (`life_counter_local`, `decks_private` off) | parcial | 18 | 5 | 18 · 4 | **média** | [`life_counter_post_game.md`](life_counter_post_game.md) |
| Comunidade, perfis, marketplace, trades, mensagens, moderação | sim (com lacuna funcional declarada) | **não** (10 capabilities off) | parcial | 36 | 6 | 20 · 2 | **média** | [`social_trade.md`](social_trade.md) |
| Comercial: planos, upgrade, checkout, cobrança e cotas de IA | **parcial** — upgrade/checkout só como aviso | **parcial** — `/plans` alcançável | parcial, fraco onde importa | 15 | 5 | 23 · 1 | **alta** | [`commercial_plans.md`](commercial_plans.md) |
| Plataforma: capabilities, middleware, health/ready, observabilidade, release | sim | **sim** (plano de controle) | parcial | 12 | 5 | 24 · 5 | média | [`release_operations.md`](release_operations.md) |

**Vereditos adversariais (§11 de cada documento)**

| Fluxo | Confirmados | Plausíveis | Refutados / rebaixados | Novos na §11 |
| --- | ---: | ---: | ---: | ---: |
| `battle_replay` | 15 | 1 | 2 | 6 |
| `release_operations` | 20 | 2 | 0 | 5 |
| `auth_session` | 9 dos 10 originais + 4 blocos agregados | 1 (A6) | 0 por inteiro (caíram 1 consequência e 2 evidências) | 4 (A11–A14) |
| `deck_lifecycle` | 17 | 1 (A6) | 1 rebaixado (A7), 1 com sub-afirmação removida (A10) | 7 (A21–A27) |
| `binder_collection_scanner` | 11 de A1–A14 | — | 1 refutado, 1 rebaixado, 1 corrigido | 7 (A15–A21) |
| `card_catalog` | maioria dos 18 originais | A8 mantido como plausível | várias citações deslocadas; A10 tinha afirmação falsa | 8 (A19–A26) |
| `social_trade` | A1, A2, A4, A5, A13 "visíveis a olho nu" + demais | — | 1 refutado como bug de UX (A7 → código morto) | 4 (A18–A21) |
| `commercial_plans` | 16 originais, todos com base no código | — | 0 por completo; A1 e A4 rebaixados/corrigidos | 7 (A17–A23) |
| `deck_ai` | A1, A2(404), A3–A9, A11, A12 | — | A10 caiu; metade de A2 caiu; 1 lacuna de teste caiu | A13 (entrou pela §7) |
| `home_onboarding_notifications` | referências de produção bateram todas | — | erros concentrados na leitura de evidência viva e de skip | 4 (A14–A17) |
| `life_counter_post_game` | A1–A9 resistiram | A11 mantido como hipótese | 0 por inteiro; A10 corrigido, A2 rebaixado | 3 (A16–A18) |

> Só as duas primeiras linhas vêm de contagem feita no lote de origem. As demais foram lidas por
> mim nas §11 de cada documento e são aproximações honestas: vários documentos declaram o veredito
> em prosa, não em tabela contável.

**Transversal (não é fluxo):**
[`_coerencia_transversal.md`](_coerencia_transversal.md) — varredura mecânica cliente↔servidor:
120 rotas / 158 pares rota+método no servidor, 142 chamadas HTTP no app, **zero chamadas quebradas**,
**zero rotas não classificadas**, e zero drift contra `docs/generated/openapi.generated.json`.
18 achados priorizados. · [`_nao_coberto.md`](_nao_coberto.md) — crítica de completude.

---

## Os 15 achados mais graves do conjunto

Critério: severidade **alta** **e** veredito **confirmado** (ou plausível de altíssima confiança,
marcado como tal) na verificação adversarial. Ordem: exposição/segurança primeiro, depois perda de
dado, depois quebra visível ao usuário.

Cinco destes eu reconferi abrindo o arquivo nesta rodada — estão marcados **[reconferido]**.

| # | Achado | Arquivo:linha | Origem |
| --- | --- | --- | --- |
| 1 | **`GET /cards/printings?sync=true` é anônimo, escreve no banco e chama a Scryfall.** Não existe `_middleware.dart` sob `server/routes/cards`; o handler faz até 30 `INSERT … ON CONFLICT DO UPDATE` em `cards` e `INSERT … ON CONFLICT DO NOTHING` em `sets` depois de duas `http.get` sem `.timeout()`. A guarda `data.length <= 1` não neutraliza: nome ainda não indexado a satisfaz por definição, e para carta de impressão única ela é verdadeira **para sempre**. **[reconferido]** — confirmei a ausência de `server/routes/{cards,sets,rules}/_middleware.dart`. | `server/routes/cards/printings/index.dart:23`, `:44-64`, `:309-484`; ausência de `server/routes/cards/_middleware.dart` | `card_catalog.md` A9 |
| 2 | **O OpenAPI gerado mente sobre a superfície anônima.** A regra é `if (!publicPaths.contains(apiPath)) 'security': [...]` — a **omissão** em `public_api_paths` vira afirmação positiva de que a rota é autenticada. `/cards`, `/cards/printings`, `/cards/resolve`, `/cards/{id}/rulings` e `/rules` aparecem com `bearerAuth` no artefato em disco, e nenhuma delas tem middleware de auth. Qualquer auditoria ou SDK gerado a partir do spec conclui o oposto da verdade. | `tools/project_logic/lib/project_logic_generator.dart:3642-3645`, `:3677-3680`; `docs/generated/openapi.generated.json`; `docs/project_logic_contracts.json:302-317` | `card_catalog.md` A20 + A10 |
| 3 | **`GET /community/marketplace` expunha fichário ignorando `binder_visibility`, `profile_visibility` e `user_blocks`** — as três checagens existem nos endpoints irmãos (`[userId].dart:136-158`, `community_engagement_service.dart:330-356`) e não existiam aqui; a rota nem lia o observador. **[reconferido] — já corrigido na árvore de trabalho, ainda não commitado** (`:40-41`, `:47`), com teste acompanhante que é `contains()` sobre o fonte. Enquanto não houver commit, o achado é real no HEAD. | HEAD: `server/routes/community/marketplace/index.dart:30-34`; árvore: `:36-52` | `social_trade.md` A2 |
| 4 | **Crescimento sem teto de métrica, explorável hoje por chamador anônimo.** `RequestMetricsService` usa `'<MÉTODO> <path cru>'` como chave, com IDs embutidos, e o mapa **nunca é podado** (até 200 latências por bucket). `GET /reports/<id>` é plano de controle explícito e anônimo, então cada id distinto cria um bucket permanente; `/health/metrics` e `/health/dashboard` serializam o mapa inteiro. | `server/lib/release_capability_policy.dart:471-473`, `:584-585`; `server/routes/reports/[id].dart:7`; `server/lib/request_metrics_service.dart:66-…`; `server/routes/_middleware.dart:201-205` | `release_operations.md` 3 + 15 |
| 5 | **Existe um TERCEIRO portão fail-closed de capability e nenhum documento o menciona.** `server/bin/manaloom_ops_daemon.py` lê o **mesmo** `release_capabilities.json` (`:54`), tem seu próprio fail-closed (`:145-197`), sua própria trava de caminho canônico (`:200-205`), 16 jobs cron (`:565-709`) filtrados por `JOB_REQUIRED_CAPABILITIES` (`:711-746`) — com 29/29 off, **15 dos 16 jobs não rodam** — e sobe um `ThreadingHTTPServer` próprio com `GET /health` na porta 8080 (`:395-465`), que não é rota dart_frog. Isso **contradiz** `release_operations.md:19,288` e `docs/MAPA_OPERACIONAL_DO_PROJETO.md` §2, que falam em "os dois portões". | `server/bin/manaloom_ops_daemon.py:54,145-205,395-465,565-709,711-746`; contradiz `docs/MAPA_OPERACIONAL_DO_PROJETO.md:62-70` | `_nao_coberto.md` §3.6(m) |
| 6 | **O seletor de cartas do pós-jogo está morto na travessia que vem do contador.** `GET /decks/{id}` devolve `'deck_version_at': DateTime.now().toUtc()…` — carimbo novo **a cada requisição**, e é a única origem desse campo no servidor. A tela exige `loadedVersion.isAtSameMomentAs(requestedVersion)`; os dois nunca coincidem depois que o cache de 5 min do `DeckProvider` expira, isto é, depois de qualquer partida de verdade. **[reconferido]** — `:831` confere exatamente. | `server/routes/decks/[id]/index.dart:831`; `app/lib/features/retention/screens/post_game_notes_screen.dart:299-306`; `app/lib/features/decks/providers/deck_provider.dart:77` | `life_counter_post_game.md` A16 |
| 7 | **Segunda nota da mesma partida é rejeitada para sempre, em silêncio.** Índice único `(user_id, deck_id, play_session_id)`; a tela mantém `playSessionId` fixo e o formulário reabre limpo depois de salvar → `23505` → `409`. O outbox engole o erro e reenvia em toda abertura, enquanto a UI afirma "será sincronizada em breve". | `server/database_setup.sql:2339`; `server/lib/retention/post_game_note_service.dart:438-443`; `app/lib/features/retention/services/post_game_note_store.dart:174-177`; `post_game_notes_screen.dart:189,198-207` | `life_counter_post_game.md` A1 |
| 8 | **`deleteNote` trata 404 como sucesso e a nota ressuscita.** 404 também é `capability_unavailable` (`_middleware.dart:128`), `Deck nao encontrado` e "nota ainda não sincronizada". O app remove o tombstone, o servidor mantém a linha, e o próximo `loadNotes` traz a nota de volta. | `app/lib/features/retention/services/post_game_note_store.dart:83-85`, `:199-200`; `server/routes/_middleware.dart:128` | `life_counter_post_game.md` A3 |
| 9 | **A primeira tela autenticada da free beta não é `/home` — é `/onboarding/core-flow`, e hoje é beco sem saída.** `_needsOnboarding` nasce `true` e só vira `false` pelo armazenamento local; sob a política vigente a tela não tem nenhum objetivo selecionável. **[reconferido]** — `auth_provider.dart:32` é literalmente `bool _needsOnboarding = true;`. | `app/lib/features/auth/providers/auth_provider.dart:32`, `:48-50`, `:564`; `app/lib/main.dart:418-421`, `:518-528`; `onboarding_core_flow_screen.dart:403-417` | `release_operations.md` 23 |
| 10 | **O portão de rota do app nega tudo durante cada refresh de capabilities.** `refresh()` faz `_snapshot = denied(); _loadState = loading; _notifyIfMounted();` **antes** da chamada HTTP; o `GoRouter` tem `refreshListenable: Listenable.merge([...])`, então o `redirect` reavalia na hora com o snapshot negado. Efeito: o usuário é expulso de `/notifications` a cada retomada do app. | `app/lib/core/config/release_capabilities.dart:273-277`; `app/lib/main.dart:303-306`, `:422-431` | `home_onboarding_notifications.md` A14 (novo na §11) |
| 11 | **`POST /auth/change-password` e `/auth/revoke-sessions` devolvem `user` truncado e o app grava por cima do usuário completo.** `AccountSecurityResult.toJson()` devolve `{id, username, email}`; `_rotateAuthenticatedSession` reconstrói com `User.fromJson` e persiste em `SharedPreferences['user_data']`, então `emailVerified`/`displayName`/`avatarUrl` viram `false`/`null`. Quem tinha email verificado vê o selo virar "Email pendente" logo após trocar a senha. **Alcançável hoje** — as três rotas estão no allowlist. **[reconferido]** — `auth_service.dart:778-781` devolve exatamente os 3 campos. | `server/lib/auth_service.dart:778-781`; `app/lib/features/auth/providers/auth_provider.dart:384-386`, `:397`, `:485-518`; `app/lib/features/auth/models/user.dart:54`; UI: `profile_screen.dart:991-998`, `:1386-1400` | `auth_session.md` A1 |
| 12 | **O Splash decide para onde ir antes de a validação do token terminar.** `MyApp.initState` já disparou `initialize()`, o que põe `_status` em `loading` sincronamente; a segunda chamada bate no guard `if (_status != AuthStatus.initial) return;` e volta na hora. O Splash espera só os 650 ms de dwell e navega por `isAuthenticated`, ainda `false` se `GET /auth/me` demorar mais. Sessão válida + rede lenta = a tela de login pisca. | `app/lib/features/auth/screens/splash_screen.dart:50-71`; `app/lib/features/auth/providers/auth_provider.dart:62-65`; `app/lib/main.dart:299`, `:362-369`, `:414-424` | `auth_session.md` A2 |
| 13 | **Três ações de deck não passam pelo gate de `deck_replace_all` no app, mas o servidor exige.** Remover carta (swipe → `PUT /decks/:id`), trocar edição (`onShowEditionPicker` é passado incondicionalmente, ao contrário do `onShowAiExplanation` logo acima) e aplicar otimização (`applyWithIds`/`addBulk`, gateados só por `aiAnalyzeOptimizeAdvisory`). Com `decks_private` ON e `deck_replace_all` OFF — combinação que a política permite — a UI oferece a ação e o servidor responde 404. | `app/lib/features/decks/screens/deck_details_screen.dart:1161-1209`, `:1694`, `:2100`; `server/lib/release_capability_policy.dart:389-397` | `deck_lifecycle.md` A1, A2, A20 + `deck_ai.md` A1 |
| 14 | **Assimetria de capability abre telas cujos endpoints são negados — e o app mente sobre o motivo.** `/collection/import` é guardado só por `collection_private`, mas depende de `POST /cards/resolve/batch` e `GET /cards/printings`, que exigem `catalog_private`. Pior: `/trades/create/:receiverId` é guardado só por `trades` e chama `GET /community/binders/:userId`, que exige `binder_public`; o app então afirma **"A oferta não está mais pública ou disponível."** — frase factualmente falsa, porque quem está desligado é a capability, não a oferta. | `app/lib/core/config/release_capabilities.dart:470-493`, `:485-488`; `app/lib/features/trades/screens/create_trade_screen.dart:149-158`, `:739-743`; `server/lib/release_capability_policy.dart:505-508`, `:509-536`; `binder_provider.dart:1182-1192` | `binder_collection_scanner.md` A2 + A15 |
| 15 | **`capability_unavailable` chega cru na tela, em inglês, como texto de produto.** O corpo da negação é `{"error":"capability_unavailable"}` sem `message`; `_messageFromBody` faz `body['error'] ?? body['message']` e devolve o texto quando `!_looksTechnical(text)` — e nenhum dos 22 termos da denylist casa. A mesma raiz produz "interaction_blocked", "trades_not_allowed", "idempotency_conflict" na tela, e em um caminho vira **"A otimização demorou mais que o esperado. Inicie uma nova tentativa."**, que convida a repetir o impossível. Zero ocorrências de `capability_unavailable` em todo o `app/lib`. | `app/lib/core/utils/friendly_error_mapper.dart:266`, `:316-318`, `:344-368`; `server/routes/_middleware.dart:128-143`; `app/lib/features/decks/providers/deck_provider_support_ai.dart:302-306`; `server/routes/trades/[id]/messages.dart:324-332` | `_coerencia_transversal.md` 2 e 3 + `deck_ai.md` A2 + `deck_lifecycle.md` A5 + `release_operations.md` 1 + `social_trade.md` A3 |

**Achados de severidade alta que ficaram de fora da lista de 15** (estão nos documentos por fluxo):
`binder A1` (dois testes de integração não podem passar como estão — montam `CollectionScreen` sem
`ReleaseCapabilitiesProvider` — e o gate não os executa porque `quality_gate.sh:112-113` roda
`flutter test` sem alvo, ou seja, só `test/`); `battle_replay A1` (polling sem backoff nem parada em
erro permanente) e `A13` (as 4 rotas de `ai/battle/sessions/**` só têm teste que lê o fonte como
texto); `card_catalog A1` (exceção de rede na busca vira "Nenhuma carta encontrada");
`home A1` (4 nomes de evento de ativação que o servidor rejeita com 400) e `A2`;
`social_trade A1` (excluir o próprio comentário sempre falha: app exige 204, servidor responde 200);
`commercial_plans A2` (`GET /users/me/plan` — o único endpoint alcançável do fluxo — não tem teste
nenhum); `deck_lifecycle A15` e `A21`; `platform 2` (retry adiciona `x-retry-attempt`, header ausente
do CORS, o que quebra o retry no alvo Flutter Web).

---

## O que ficou de fora

Base: [`_nao_coberto.md`](_nao_coberto.md), auditoria de completude feita depois dos 11 documentos.

**Cobertura de rota: completa.** As 120 rotas de servidor e as 46 rotas reais de app aparecem em
algum documento. Higiene para quem for reconferir por script: 15 rotas só aparecem pelo **path
HTTP**, não pelo caminho de arquivo.

**Todo o buraco está em superfície não-rota:**

- **5 dos 16 `_middleware.dart` do servidor não aparecem em uma linha de documento nenhum** —
  `import/`, `trades/`, `content-reports/`, `decks/[id]/ai-analysis/`, `decks/[id]/recommendations/`.
  Dois fatos decorrem disso e não estão escritos em lugar nenhum: (a) a fronteira de e-mail
  verificado é **assimétrica** (exigem: `binder`, `community`, `conversations`, `trades`,
  `content-reports`; não exigem: `decks`, `import`, `users`, `notifications`, `ai`) — então
  `POST /import/to-deck` cria deck sem e-mail verificado enquanto `POST /binder` é bloqueado com 403;
  (b) `decks/[id]/recommendations` monta `aiPlanLimitMiddleware()` e é, ao mesmo tempo, classificada
  como rota sem chamador no app.
- **31 dos 32 arquivos do contador de vida** e **15 dos 22 do host Lotus**, o canal de plataforma e a
  `MainActivity` nativa (`MainActivity.kt:14,29-43`).
- **4 bottom sheets / diálogos** sem uma linha.
- **O egress de e-mail transacional.**
- **O terceiro portão fail-closed** (item 5 da lista acima).
- **O site público inteiro (`web-public/`)** — 8 páginas + `healthz`/`robots`/`sitemap`, consumindo
  `GET /reports/{id}`. É **a superfície mais alcançável do produto hoje** e não tem dono em contrato
  nenhum.
- **136 dos 143 arquivos de `server/bin`**, onde mora a maior parte da escrita de dado de produto
  (~20 `cron_*.sh` que mutam `cards`, `sets`, `price_history`, `format_staples`, `card_combos`,
  `card_battle_rules`, `commander_learned_decks`).

**Fluxos que o contrato precisa declarar (5):** `home_onboarding_notifications`, `commercial_plans`,
`binder_collection_scanner` (hoje esmagado junto com `card_catalog` dentro de `card_collection`),
`public_web` e `ops_cron_learning`. Além disso, `release_operations` ↔ `release_operations` é
**divergência de nome** entre documento e contrato — alinhar um dos dois.

**Limites que valem para o conjunto inteiro:**

- **Nada foi executado.** Nenhum achado aqui é PROVADO por prova viva.
- Não foram avaliados: correção de regra de MTG, qualidade de deck, desempenho, nem qualidade visual.
- O estado all-OFF descreve o **repositório**, não prova o que está implantado em produção
  (`docs/status/CURRENT_PRODUCT_DECISION.md:30-31`).
- Contagens declaradas nas §1 foram corrigidas para baixo ou para cima em vários documentos durante
  a §11. Trate número solto de §1 com desconfiança; número de §11 já passou por conferência.

---

## Rodada 2 — execução

Nada disto foi rodado. A ordem abaixo é de **custo crescente e de dependência**: o que decide o
comportamento de todos os outros fluxos vem primeiro, e a prova viva vem só depois que o
determinístico estiver verde.

**Pré-condição operacional:** use `MANALOOM_NODE_BIN=/opt/homebrew/opt/node@22/bin/node` onde houver
hook/gate; nunca `--no-verify`. Toda prova viva exige **runtime isolado** — a política vigente é
all-off e o app não sai da tela "Beta em preparação" sem ele:
`MANALOOM_ISOLATED_RELEASE_CAPABILITIES_FILE=<caminho absoluto>` **e**
`MANALOOM_CONFIRM_ISOLATED_RELEASE_CAPABILITIES=I_UNDERSTAND_THIS_IS_DISPOSABLE_TEST_ONLY`
(`server/lib/release_capability_policy.dart:7-13,205-230`) — sem a segunda variável a política vira
inválida e **tudo responde 503**, não 404.

### Fase 0 — determinístico, sem banco e sem rede

Ordem sugerida. Cada bloco é independente; pare no primeiro vermelho.

**0.1 `release_operations`** — é o portão que decide todo o resto.

```bash
cd .../server
dart test test/release_capability_policy_test.dart test/health_readiness_support_test.dart \
  test/root_liveness_contract_test.dart test/root_security_headers_contract_test.dart \
  test/root_error_logging_contract_test.dart test/root_product_identity_test.dart \
  test/admin_access_support_test.dart test/cors_policy_test.dart test/observability_test.dart
dart test test/deploy_rollback_convergence_contract_test.dart \
  test/ops_sidecar_digest_release_contract_test.dart test/flutter_web_deploy_contract_test.dart \
  test/data_model_migration_test.dart test/runtime_schema_migration_contract_test.dart
python3 test/release_sbom_scope_test.py
cd .../app
flutter test test/core/config/release_capabilities_test.dart \
  test/core/config/release_capability_surface_contract_test.dart \
  test/core/config/launch_features_test.dart test/core/api/api_client_request_id_test.dart
cd ... && ./scripts/manaloom_release_ops_contract_test.sh
```

**0.2 `auth_session`** — única jornada viva.

```bash
cd .../app
flutter test test/features/auth test/features/profile/profile_screen_test.dart \
  test/core/security/auth_token_store_test.dart test/core/api/api_client_request_id_test.dart \
  test/core/utils/friendly_error_mapper_test.dart
cd .../server
RUN_INTEGRATION_TESTS=0 JWT_SECRET=hermes-local-test-secret dart test \
  test/auth_service_test.dart test/auth_runtime_policy_test.dart \
  test/auth_release_preflight_contract_test.dart test/password_policy_test.dart \
  test/register_password_contract_test.dart test/email_verification_contract_test.dart \
  test/legal_consent_contract_test.dart test/rate_limit_middleware_test.dart
```

**0.3 `card_catalog`** — onde estão os dois achados de segurança anônima.

```bash
cd .../server
RUN_INTEGRATION_TESTS=0 JWT_SECRET=dev-secret dart test \
  test/cards_route_test.dart test/sets_route_test.dart test/card_query_contract_test.dart \
  test/card_identity_support_test.dart test/card_resolution_support_test.dart \
  test/printing_identity_flow_contract_test.dart test/collection_availability_route_contract_test.dart \
  test/collection_availability_contract_test.dart test/cards_reserved_schema_contract_test.dart
cd .../app
flutter test test/features/cards/ test/features/collection/ test/core/widgets/card_artwork_test.dart \
  test/core/widgets/cached_card_image_test.dart test/core/widgets/card_image_source_policy_guard_test.dart
```

**0.4 `deck_lifecycle`** · `server`: os 20 arquivos `test/deck_*`, `test/import_*` com
`--exclude-tags "live || live_backend || live_db_write || live_external"`; `app`:
`flutter test test/features/decks/`.

**0.5 `deck_ai`** · `server`: os 27 `test/ai_*`, `test/optimiz*`, `test/commander_*`,
`test/deck_optimization_*` com as mesmas tags excluídas; `app`: `test/features/decks/providers/`,
`test/features/decks/widgets/deck_optimize_*`, `test/features/commercial/ai_usage_meter_test.dart`.

**0.6 `binder_collection_scanner`** · `server`: `test/binder_route_test.dart`,
`test/binder_item_contract_test.dart`, `test/binder_import_contract_test.dart`; `app`:
`test/features/binder/`, `test/features/scanner/`, `test/features/collection/collection_screen_responsive_test.dart`.

**0.7 `social_trade`** · `app`: `test/features/{community,social,messages,trades}`; `server`:
`RUN_INTEGRATION_TESTS=0 JWT_SECRET=local_social_audit dart test test/release_capability_policy_test.dart …`.

**0.8 `life_counter_post_game`** · `app`: `flutter test --no-pub test/features/retention/`,
`test/features/home/life_counter_route_test.dart`, `test/features/home/lotus_life_counter_screen_test.dart`;
`server`: `test/post_game_note_sync_contract_test.dart` (é só string — roda em segundos).

**0.9 `battle_replay`** · `server`: `dart test --exclude-tags "live || …" test/battle_*_test.dart test/interactive_battle_*_test.dart`;
`app`: `flutter test test/features/battle --no-pub --reporter compact --timeout 2m`.

**0.10 `home_onboarding_notifications`** · `app`: `test/features/home/`, `test/features/notifications/`,
`test/core/services/{activation_funnel,realtime_notification_coordinator,push_notification}_service_test.dart`,
`test/ui/ui_state_matrix_test.dart`, `test/ui/ui_authenticated_visual_matrix_test.dart`,
`test/ui/ui_live_evidence_policy_test.dart`; `server`: `test/activation_events_contract_test.dart`,
`test/push_notification_service_test.dart`, `test/social_runtime_schema_contract_test.dart`.

**0.11 `commercial_plans`** · `app`: `flutter test test/features/commercial/`,
`test/core/config/release_capabilities_test.dart`, `test/ui/manaloom_commercial_ui_audit_test.dart`,
`test/ui/ui_live_evidence_policy_test.dart`; `server`: `test/plan_service_test.dart`,
`test/plan_checkout_contract_test.dart`, `test/payment_provider_url_test.dart`,
`test/ai_middleware_order_contract_test.dart`.
*(Nota já corrigida no documento: `release_capability_surface_contract_test.dart` **não** toca este
fluxo — grep por `plans`/`upgrade`/`checkout`/`billingCheckout` nele retorna zero.)*

**0.12 Gate amplo, para fechar a fase** · `MANALOOM_NODE_BIN=/opt/homebrew/opt/node@22/bin/node ./scripts/quality_gate.sh quick`
e depois `full`. **Atenção:** `quality_gate.sh:112-113` roda `flutter test` sem alvo, ou seja, **não
executa `app/integration_test/`** — é por isso que o achado `binder A1` (dois testes de integração que
não podem passar) nunca foi detectado.

### Fase 1 — integração e runtime isolado (PostgreSQL descartável, capabilities forçadas)

Ordem: comece pelos fluxos onde a prova fecha um achado alto.

1. **`card_catalog`** — `./scripts/manaloom_authenticated_visual_qa_isolated.sh` (sobe PG descartável,
   força capabilities `on`, captura PNG). Prova dirigida de A9:
   `curl -i 'http://localhost:8080/cards/printings?name=Sol+Ring&sync=true'` **sem** `Authorization`,
   depois `SELECT count(*) FROM cards WHERE name='Sol Ring'` antes/depois. Prova de A20:
   `python3 -c "import json;d=json.load(open('docs/generated/openapi.generated.json'));print({k:[m.get('security') for m in d['paths'][k].values()] for k in ['/cards','/rules']})"`.
2. **`binder_collection_scanner`** — `./scripts/manaloom_binder_import_visual_qa.sh` e
   `flutter test integration_test/binder_dashboard_runtime_test.dart integration_test/collection_entrypoints_runtime_test.dart`.
   Esperado hoje: **timeout** em "Fichário" — é a confirmação viva de A1. Para A2 e A15: política
   isolada com `collection_private=on, catalog_private=off` (abrir `/collection/import` e colar
   `1 Sol Ring`) e `trades=on, binder_public=off` (tocar "Propor troca").
3. **`life_counter_post_game`** — roteiro de 7 passos do §10.2. Reproduzir A16 abrindo o pós-jogo a
   partir de um replay de batalha (manda `deckVersionAt = summary.createdAt`, o seletor bloqueia
   deterministicamente); reproduzir A1 salvando uma **segunda** nota sem sair da tela e conferindo
   `post-game-pending-sync = 1` com uma única linha no `SELECT`.
4. **`home_onboarding_notifications`** — roteiro web em 390x844 e 1440x900. Passo 2 e 4 provam A1
   (DevTools: esperado **400** para `onboarding_goal_selected` e `onboarding_task_started`).
   Para A14: forçar um `refresh()` de capabilities com `/notifications` aberta e observar a expulsão.
5. **`social_trade`** — roteiro de ~12 minutos com dois usuários verificados e policy isolada com as
   10 capabilities sociais. Passo dedicado a A1 (excluir comentário próprio) e a A4/A18
   (`marketplace=on, catalog_private=off` → `/community?tab=3`; `marketplace=on, collection_private=off`
   → `/marketplace` cai em `/home` mesmo com o endpoint respondendo 200).
6. **`commercial_plans`** — **Prova A leva 5 minutos e roda na política vigente**, sem nada isolado:
   login → Perfil → confirmar ausência do medidor de IA → `/plans` → navegar manualmente para
   `/upgrade` e `/checkout` e capturar as três telas idênticas;
   `curl -i -X POST <API>/billing/webhook` → esperado 404 `capability_unavailable` (achado A7);
   `curl -i <API>/users/me/plan -H "Authorization: Bearer <jwt>"` → 200 com `ai_monthly_limit=120`.
   É a prova viva mais barata do conjunto inteiro — comece por ela.
7. **`auth_session`** — comandos vivos exigem `account_registration` **ligada** em runtime isolado,
   `MANALOOM_PASSWORD_RESET_TEST_RESPONSE` e
   `MANALOOM_EMAIL_VERIFICATION_TEST_RESPONSE=I_UNDERSTAND_VERIFICATION_TOKENS_ARE_TEST_ONLY`:
   `test/{auth_flow_integration,account_security_live,auth_token_rotation_live,email_verification_live,legal_consent_live}_test.dart`.
   Prova de A2: simulador iOS com rede em "3G lenta" e sessão salva. Prova de A11: abrir
   `/reset-password?token=…` num dispositivo já logado.
8. **`release_operations`** — roteiro de 6 `curl`. O passo 5 (`/health/metrics` com
   `X-ManaLoom-Ops-Key`, repetindo o passo 3 com **IDs diferentes** e vendo o número de buckets
   crescer) é a prova viva dos achados 3 e 15.

### Fase 2 — pesado, com aprovação explícita

Nada aqui roda sem autorização do dono — há escrita em banco e chamada externa paga.

- **`deck_lifecycle` live** — `RUN_INTEGRATION_TESTS=1 MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL … dart test --tags live_db_write test/{decks_crud,decks_incremental_add,deck_crud_atomicity_live,import_to_deck_flow,deck_validation_state_live,deck_pricing_live}_test.dart`.
- **`deck_ai` live** — exige `OPENAI_API_KEY` (sem ela `/ai/optimize` responde 503
  `provider_unavailable`): `test/{ai_generate_create_optimize_flow,ai_optimize_flow,ai_archetypes_flow,deck_optimization_apply_rollback_live}_test.dart`, mais
  `manaloom_deck_ai_learning_gate.sh`, `manaloom_deep_ai_alignment_tester.sh`,
  `manaloom_ai_prompt_eval.sh`, `manaloom_deck_quality_gate.sh`.
- **`battle_replay`** — `./scripts/quality_gate.sh battle-lab`, depois `battle` (sobe PG descartável),
  depois `RUN_INTERACTIVE_BATTLE_DB_TESTS=1 … test/interactive_battle_store_live_test.dart`, e por
  último `./scripts/manaloom_play_vs_ai_e2e.sh` (E2E real com XMage fixado). Pré-requisito que
  costuma ser esquecido: **dois decks Commander validados de exatamente 100 cartas e 1 comandante**,
  senão o preflight devolve `blocked` e o roteiro para no passo 3.
- **`life_counter_post_game`** — `test/post_game_two_client_live_test.dart` (única prova real do
  servidor de pós-jogo).
- **`commercial_plans` Prova B** — `MANALOOM_CONFIRM_POSTGRES_WRITES=<frase-aprovada> dart test test/ai_postgres_atomicity_live_test.dart`
  (única prova real de contabilidade de cota).

### Testes que precisam ser escritos antes de a rodada 2 ter valor

Sem estes, rodar tudo acima devolve verde sem provar nada — é a crítica recorrente das §7:

1. **Contrato cruzado dos dois portões**: tabela `{rota do app → endpoint que a tela chama}`
   asserindo `redirectFor(rota, caps) == null ⟺ decisionFor(endpoint, caps).allowed`. Falha hoje em
   `/community?tab=3`, `/marketplace`, `/collection/matches`, `/collection/import` e
   `/trades/create/:receiverId`. Fecha `binder A2`, `binder A15`, `social A4`, `social A18`, `social A19`.
2. **Handlers de rota invocados in-process** para `cards`, `sets`, `decks`, `binder` e
   `ai/battle/sessions/**`. O molde já existe e funciona:
   `server/test/battle_replay_routes_security_test.dart:8-13` importa e chama os handlers. Hoje esses
   cinco conjuntos só têm `File(...).readAsStringSync()` + `contains(...)`.
3. **Gate que derive a superfície anônima do disco** (pastas de `server/routes` sem `_middleware.dart`)
   e a compare com `public_api_paths` **e** com `security` em `openapi.generated.json`. Fecha
   `card_catalog A9`, `A10` e `A20` de uma vez.
4. **Tradução central de `capability_unavailable`** no app, com teste em
   `friendly_error_mapper_test.dart`: `fromStatusCode(404, body:{'error':'capability_unavailable'})`
   não deve conter a string crua. Fecha o achado transversal 15 nos cinco fluxos onde ele aparece.
