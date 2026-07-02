# ManaLoom App Audit Adjustments Closure

Data: 2026-07-01
Status: `SAFE_FIXES_APPLIED_AND_VALIDATED`

## Escopo executado

Foram aplicados os ajustes seguros levantados na auditoria profunda do app:

- login/runtime web apontando para backend publico por padrao, sem fixar host local;
- request id compativel com Flutter Web;
- logs de requisicao usando path do endpoint, sem poluir testes com host publico;
- inicializacao de auth idempotente, evitando validacoes duplicadas de token;
- fallback web para o contador Lotus, sem tentar instanciar WebView no navegador;
- suporte app/backend para `cards.is_reserved` como metadado aditivo;
- auditoria PostgreSQL read-only para decks sem `user_id`;
- contratos de API documentados para os campos novos;
- teste golden da home estabilizado com pump finito.

Fora de escopo neste corte: iOS, AAB/APK, billing server-side, alteracao direta em PostgreSQL e template React publico.

## Decisoes

### Decks sem usuario

A auditoria PostgreSQL encontrou `13` decks com `user_id IS NULL`.

Classificacao:

- `public_count`: `0`;
- `populated_count`: `13`;
- `commander_count`: `13`;
- `pg_registered_private_commander_count`: `13`;
- todos seguem o padrao privado `PG REGISTERED ... Rafael Paste 2026-06-24`;
- todos possuem `total_quantity = 100`.

Decisao: nao deletar e nao atribuir owner automaticamente. Se esses decks precisarem aparecer no produto, preparar pacote PostgreSQL explicito com precheck, apply, rollback e validacao.

Evidencia: `docs/qa/MANALOOM_DATA_MODEL_AUDIT_2026-07-01.md`.

### `cards.is_reserved`

O campo passou a ser tratado como metadado de risco/display, sem efeito automatico em preco, trade, venda ou bloqueio de uso.

Entradas preservadas:

- MTGJSON `isReserved` nos syncs;
- Scryfall `reserved` nos caminhos backend-owned de resolve/printings.

Saidas expostas:

- `/cards`;
- `/cards/resolve`;
- `/cards/printings`;
- `/decks/:id`;
- `/binder`;
- `/community/binders/:userId`;
- `/community/marketplace`.

Consumo no app:

- modelos de deck/scanner/card provider;
- binder e marketplace;
- badge `Reserved` em deck details, binder e marketplace.

### Assets e rotas vivas

Assets declarados em `app/pubspec.yaml`:

- `assets/branding/`: 4 arquivos, todos referenciados por auth/home/splash/teste golden;
- `assets/symbols/`: usados por simbolos de cores/mana em decks;
- `assets/lotus/`: usado pela tela Lotus/life counter e pelo skin visual;
- fontes `Dosis`, `Inter`, `Fraunces` continuam referenciadas.

Nao foi removido asset neste corte.

Rotas principais revisadas em `app/lib/main.dart`:

- publicas tecnicas: `/`, `/login`, `/register`;
- app logado: `/home`, `/decks`, `/collection`, `/market`, `/community`, `/profile`, `/messages`, `/notifications`, `/trades`;
- comercial interno: `/plans`, `/upgrade`, `/checkout`, `/legal`;
- nativa protegida no web: `/life-counter`.

### Artefatos fora do commit

Foram deixados fora do commit por nao pertencerem ao ajuste seguro do app/backend:

- `app/.metadata` e `app/ios/Runner/SceneDelegate.swift`, por envolverem plataforma iOS;
- `web-public/`, por ser template publico React e incluir `node_modules`/`.next`;
- artefatos XMage/PG330 em `docs/hermes-analysis/`, por serem trabalho paralelo de cartas/battle.

## Validacoes executadas

```sh
dart format ...
python3 -m py_compile server/bin/sync_cards_full_fast.py
python3 -m py_compile app/tool/serve_flutter_web_app.py
dart run bin/audit_data_model_links.dart --require-db --json-output ../docs/qa/MANALOOM_DATA_MODEL_AUDIT_2026-07-01.json --markdown-output ../docs/qa/MANALOOM_DATA_MODEL_AUDIT_2026-07-01.md
flutter analyze --no-version-check
dart analyze
flutter test test/core/api/api_client_request_id_test.dart test/features/auth/providers/auth_provider_log_sanitization_test.dart test/features/decks/models/deck_card_item_test.dart test/features/scanner/services/scanner_card_search_service_test.dart test/features/binder/providers/binder_provider_test.dart test/core/widgets/platform_unavailable_screen_test.dart --no-version-check --reporter compact
dart test test/cards_route_test.dart test/sync_cards_test.dart test/api_contracts_data_map_guard_test.dart test/data_model_migration_test.dart -r expanded
dart test -r expanded
flutter test test/features/home/home_screen_test.dart --no-version-check --reporter compact
flutter test test --no-version-check --reporter compact --concurrency=1
flutter build web --base-href /app/ --no-version-check
rg -n '<base href="/app/"|flutter_bootstrap\.js|ManaLoom' app/build/web/index.html
git diff --check
```

Resultados:

- `flutter analyze`: PASS, sem issues;
- `dart analyze`: PASS, sem issues;
- testes focados app: PASS;
- testes focados server: PASS;
- server completo: PASS, `626` testes, `9` skips por fixtures ausentes esperadas;
- Flutter completo: PASS, `592` testes;
- Flutter Web build: PASS, `app/build/web` gerado com `<base href="/app/">`;
- `git diff --check`: PASS.

## Pendencias reais remanescentes

- Decidir se os decks privados `PG REGISTERED` sem owner devem continuar invisiveis ou receber owner via pacote PostgreSQL aprovado.
- Integrar DSN Sentry real no build/deploy sem versionar segredo.
- Publicar Flutter Web sob `/app/` com fallback SPA no proxy final.
- Tratar template React publico em goal separado, sem misturar `node_modules`/`.next`.
