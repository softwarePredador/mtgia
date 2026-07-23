# ManaLoom UI Test Surface Map

Este mapa define os contratos mínimos para agentes e harnesses de runtime
validarem telas sem depender apenas de texto visível, ordem de widgets ou timing
de animação.

## Regras para novos fluxos testáveis

- Todo fluxo que muda dado persistente deve ter pelo menos uma `Key` estável no
  gatilho da ação, uma no container/modal aberto e uma no item selecionável.
- Runtime visual deve validar UI e confirmar o resultado por API quando a ação
  altera deck, binder, trade, marketplace, mensagem, profile ou coleção.
- Texto continua sendo evidência visual, mas não deve ser o seletor primário
  quando existe `Key`.
- Bottom sheets e dialogs não devem ser empilhados sem contrato explícito. Antes
  de abrir um picker secundário, fechar o dialog atual ou usar uma rota/sheet
  única.
- Screenshots devem ser capturados nos checkpoints `antes`, `ação aberta` e
  `resultado final` para fluxos P1.

## Inventário executável de rotas e superfícies — S3-01

A fonte estruturada do inventário é
`app/test/ui/fixtures/ui_surface_inventory.json` e o guard é
`app/test/ui/ui_surface_inventory_test.dart`. O documento continua descrevendo
as keys e os contratos de interação; o JSON classifica toda a superfície
descoberta no código e o teste impede dívida silenciosa.

Baseline da beta Web + Android em 2026-07-21:

| Tipo | Quantidade classificada |
|---|---:|
| `GoRoute` | 38 |
| `ShellRoute` | 1 |
| `MaterialPageRoute` | 6 |
| Dialogs | 37 |
| Bottom sheets | 22 |
| Menus | 5 |
| Tabs | 11 |
| Navegação responsiva | 2 |
| Transientes (`SnackBar`) | 92 |
| **Total** | **214** |

Cada ocorrência pertence a um contrato de domínio que declara:

- job da superfície e owner;
- source of truth;
- estados relevantes;
- situação/contrato de stable key;
- criticidade;
- ação, sucesso e recuperação;
- política de deep link.

As 38 rotas também declaram path canônico, tela/destino e escopo
`active`, `deferred_by_scope` ou `compatibility_redirect`. O Scanner permanece
explicitamente deferido e `/market` é apenas compatibilidade para
`/community?tab=3`; nenhum deles é contabilizado como tela ativa própria.

O guard compara a ordem real de todas as `GoRoute`, os arquivos que contêm
superfícies imperativas e a contagem por tipo. Adicionar, remover ou trocar uma
dessas superfícies sem atualizar o contrato faz o `ui-audit` falhar. Execute:

```bash
cd app
/Users/desenvolvimentomobile/.manaloom/toolchains/flutter-3.44.6/bin/flutter \
  test test/ui/ui_surface_inventory_test.dart --no-version-check --no-pub
```

`partial:` em `stable_key` não é crédito de conclusão: registra dívida já
classificada para S3-02/S3-05. `not_applicable:` só é permitido quando a
superfície não possui UI própria ativa, como redirect de compatibilidade ou
feature removida do escopo do artefato.

## Matriz executável de estados — S3-02

`app/test/ui/fixtures/ui_state_matrix.json` classifica, nos mesmos 18 domínios
do inventário, os 15 estados canônicos: loading, progress, partial, stale,
loading-more, saving, optimistic, disabled, empty, error, retry, offline,
session-expired, permission-denied e success. Cada domínio decide todos como
`covered` ou `not_applicable`; não existe estado omitido implicitamente.

O guard `app/test/ui/ui_state_matrix_test.dart` confirma:

- igualdade entre os domínios da matriz e do inventário de superfícies;
- partição completa e sem duplicidade dos 15 estados;
- existência de sources, anchors e testes executáveis declarados;
- política explícita de preservação de entrada;
- política sanitizada de erro;
- carregamentos de página usando `AppStatePanel.loading`, região viva com
  anúncio único e indicador de progresso;
- ausência de expressões que renderizam exception/payload técnico diretamente
  em screens/widgets.

O estado optimistic permanece `not_applicable` nos fluxos atuais: mutations
visíveis aguardam confirmação do backend ou mostram progresso. Introduzir
update otimista exige classificar rollback/conflito no JSON e adicionar teste
antes de o `ui-audit` aceitar a mudança.

## Matriz executável de viewports — S3-03

`app/test/ui/fixtures/ui_viewport_matrix.json` declara 16 casos canônicos:
mobile 320×568, 390×844 e 412×915; tablet 768×1024 e 1024×768 landscape;
boundaries 599/600, 839/840, 1199/1200 e 1599/1600; desktop 1280×900,
1440×900 e 1920×1080. Cada caso possui orientação e classe responsiva
explícitas.

O guard `app/test/ui/ui_viewport_matrix_test.dart` confirma:

- igualdade dos 18 domínios com o inventário S3-01 e existência dos testes
  widget declarados;
- ownership exato de cada breakpoint por `AppTheme.viewportClassForWidth`;
- gutter, max-width e ausência de overflow de `ResponsivePageFrame` em toda a
  matriz;
- stack em 1199 e dois panes em 1200 para `AdaptiveMasterDetail`;
- evidência obrigatória de texto 200% e teclado virtual de 320 px;
- Home real em todos os tamanhos e Deck Generate com campo focado e CTA
  alcançável mesmo com teclado + texto 200%.

Execute a matriz declarada:

```bash
cd app
jq -r '"test/ui/ui_viewport_matrix_test.dart", \
  "test/core/widgets/responsive_page_frame_test.dart", \
  "test/core/theme/app_theme_test.dart", .domain_evidence[][]' \
  test/ui/fixtures/ui_viewport_matrix.json | sort -u | \
  xargs /Users/desenvolvimentomobile/.manaloom/toolchains/flutter-3.44.6/bin/flutter \
  test --no-version-check --no-pub
```

## Matriz executável de acessibilidade móvel — S3-04

`app/test/ui/fixtures/ui_accessibility_matrix.json` mantém os mesmos 18
domínios e exige evidência para labels, roles/state, live-status, alvo 48 px,
texto 200%, contraste WCAG, redundância além da cor e ordem de leitura.

O guard `app/test/ui/ui_accessibility_matrix_test.dart`:

- rejeita domínio sem teste widget executável;
- rejeita `IconButton` ativo sem tooltip nativo;
- calcula contraste dos pares canônicos (4.5:1 para texto normal e 3:1 para
  texto grande/controle/foco);
- mantém TalkBack e VoiceOver como `pending_physical` até haver roteiro manual
  executado de verdade.

O helper `expectManaLoomBaselineAccessibility` executa em conjunto alvo Android
de 48 px, nome acessível para alvos tocáveis e contraste de texto. Ele já é
usado por Auth, Commercial, navegação móvel, painel de estado, Binder, Home,
Card Detail e Deck Generate com teclado + texto 200%.

## Matriz executável de teclado e foco Web — S3-05

`app/test/ui/fixtures/ui_keyboard_focus_matrix.json` mapeia Tab, Shift+Tab,
Enter, Space, Escape, trap e restauração de foco em modal, browser back, foco
visível e reduced motion para provas executáveis. O guard
`app/test/ui/ui_keyboard_focus_matrix_test.dart` usa as telas reais de Login,
ações do shell e o editor de descrição do deck; ele também impede que a parte
manual seja confundida com `PASS` enquanto houver itens em `remaining`.

O roteiro no build Web real validou `/login` e as rotas autenticadas críticas
com Tab/Shift+Tab, Enter/Space, foco visível, Escape, trap/restauração de foco,
browser back e reduced motion, sem erro de console. O fixture registra `pass`;
essa prova continua separada da validação manual em leitores de tela físicos.

## Matriz executável de navegação e retomada — S3-06

`app/test/ui/fixtures/ui_navigation_resume_matrix.json` torna explícitos sete
contratos de continuidade: redirect protegido, expiração de sessão em runtime,
tabs por query com back/forward, deep links de Battle e Card Detail, além dos
rascunhos de Generate e Import. O guard
`app/test/ui/ui_navigation_resume_matrix_test.dart` exige fonte e teste atuais
para cada cenário.

Battle/Replays agora usa `/decks/:id/battle-replays`. Card Detail usa
`/cards/:cardId`: o objeto em memória é apenas um fast path e o refresh resolve
o mesmo `card_id` pela API/backend PostgreSQL. Collection e Community mantêm a
tab normalizada na URL. Generate e Import persistem somente o formulário não
salvo, com chave separada pelo id do usuário, e removem o rascunho após sucesso.
401 de token inválido/expirado encerra a sessão; `invalid_password`, 429, 5xx,
timeout e rede a preservam.

Execute:

```bash
cd app
flutter test --no-pub test/ui/ui_navigation_resume_matrix_test.dart \
  test/features/collection/collection_screen_responsive_test.dart \
  test/features/community/screens/community_screen_responsive_test.dart \
  test/features/decks/screens/deck_flow_entry_screens_test.dart
```

## Regressão visual autenticada — S3-07

`app/test/ui/fixtures/ui_authenticated_visual_matrix.json` fixa 20
checkpoints canônicos e os estados sucesso, vazio, erro, modal, acima e abaixo
da dobra. Cada checkpoint foi capturado no mesmo fixture PostgreSQL/API
descartável em quatro plataformas:

| Plataforma | Dimensão capturada | Capturas |
|---|---:|---:|
| Web mobile | 390×844 | 20 |
| Web desktop | 1440×900 | 20 |
| Web wide | 1920×1080 | 20 |
| Android físico Samsung SM-A135M | 1080×2408 | 20 |

Os 80 PNGs aprovados vivem em `app/test/ui/goldens/runtime`. O comparador
`app/tool/authenticated_visual_diff.dart` rejeita arquivo ausente/inesperado,
dimensão diferente e razão de pixels alterados acima de `0.001`; divergências
são materializadas em `app/test/ui/failures/runtime`.

O harness `scripts/manaloom_authenticated_visual_qa_isolated.sh` cria usuário,
card, deck e set representativo somente no banco descartável, usa imagem
same-origin, nunca cadastra durante a captura e remove credencial, banco e
listeners ao encerrar. Textos relativos a tempo usam
`MANALOOM_VISUAL_FIXTURE_MODE=true`, mantendo o baseline determinístico sem
alterar o comportamento normal do app.

No Android, o runner oficial `flutter drive` não aceita `--release` fora da
Web. A prova física usa `--profile`, com `kDebugMode=false`, e registra esse
limite explicitamente na matriz; não é apresentada como release.

## Onboarding e primeiro uso — S3-08

O destino autenticado é resolvido por `resolveAuthenticatedLocation`: um deep
link explícito e seguro tem prioridade; sem ele, `AuthProvider` escolhe Home ou
`/onboarding` a partir do estado persistido por usuário. O contrato local
versionado diferencia `pending`, `completed` e `skipped`; storage ausente,
payload inválido ou versão futura nunca concede conclusão silenciosa.

Keys estáveis do fluxo:

- `onboarding-scroll-view`;
- `onboarding-format-dropdown`;
- `onboarding-storage-notice` e `onboarding-storage-retry`;
- `onboarding-generate-action` e `onboarding-import-action`;
- `onboarding-complete-action` e `onboarding-skip-action`.

O teste widget `test/features/home/onboarding_core_flow_screen_test.dart` cobre
320×568, texto 200%, falha/retry de persistência, formato e foco. Ele é parte
explícita do `quality_gate.sh ui-audit`. O runtime
`integration_test/onboarding_first_run_runtime_test.dart` usa API/PostgreSQL
descartáveis e valida retomada após reconstrução, skip, logout/login e ausência
de repetição do onboarding em Android físico.

Execute o guard e o diff:

```bash
cd app
flutter test --no-pub test/ui/ui_authenticated_visual_matrix_test.dart \
  test/tool/authenticated_visual_diff_test.dart

dart run tool/authenticated_visual_diff.dart \
  --baseline test/ui/goldens/runtime \
  --actual <capturas-da-mesma-execucao> \
  --failure test/ui/failures/runtime \
  --threshold 0.001 \
  --summary <pixel-diff.json>
```

## Decks / Card Entry / Commander Edition

| Superfície | Rota/Tela | Key estável | Contrato esperado | Validação recomendada |
|---|---|---|---|---|
| Card no deck | `DeckDetailsScreen` aba `Cartas` | `deck-card-<cardId>` | Abre detalhes da carta do deck. | `find.byKey`, screenshot antes da ação. |
| Dialog de carta do deck | Dialog de detalhes | `deck-card-details-dialog-<cardId>` | Mostra nome, mana, type line e metadados de edição. | `find.byKey` + texto `SET #collector`. |
| Trocar edição | Dialog de carta do deck | `deck-card-change-edition-<cardId>` | Fecha o dialog atual e abre o picker de edições. | Tap por key; garantir que o dialog antigo saiu. |
| Picker de edição | Bottom sheet | `deck-edition-picker-sheet-<currentCardId>` | Lista edições sem bloquear toque por modal anterior. | `find.byKey` + screenshot do sheet. |
| Título do picker | Bottom sheet | `deck-edition-picker-title` | Para comandante: `Escolher edição do comandante`. | Texto como evidência visual, key como âncora. |
| Opção de edição | Bottom sheet | `deck-edition-option-<newCardId>` | Seleciona impressão específica pelo `card_id`. | Tap por key, não por índice de `ListTile`. |
| Pós-troca de comandante | API `GET /decks/:id` | N/A | Exatamente 1 comandante; card escolhido não aparece em `main_board`. | Conferir `commander.length == 1` e ausência nas 99. |
| Dialog criar deck | `DeckListScreen` | `deck-create-dialog` | Modal de criação aberto no `Overlay`. | `find.byKey`; não usar `AlertDialog`/índice. |
| Campos criar deck | `DeckListScreen` | `deck-create-name-field`, `deck-create-format-field`, `deck-create-description-field`, `deck-create-public-switch` | Preenche nome/formato/descrição/visibilidade. | `enterText`/tap por key. |
| Ações criar deck | `DeckListScreen` | `deck-create-cancel-button`, `deck-create-submit-button` | Cancela ou cria deck. | Tap por key + API/lista. |
| Lista de decks | `DeckListScreen` | `deck-list`, `deck-list-row-<deckId>`, `deck-list-empty-create-button`, `deck-list-empty-generate-button`, `deck-list-fab-menu`, `deck-list-menu-create`, `deck-list-menu-generate`, `deck-list-menu-import` | Lista/FAB não dependem de copy para abrir fluxos. | O menu e o dialog vivem no `Overlay`; localizar por key global. |
| Ações do deck | `DeckDetailsScreen` | `deck-details-optimize-button`, `deck-details-menu`, `deck-details-menu-import-list` | Abre optimize e importar lista sem depender de ícone/texto do menu. | Tap por key; texto como evidência visual. |
| Análise funcional | `DeckAnalysisTab` aba `Análise` | `deck-analysis-functional-section-<deckId>`, `deck-analysis-functional-origin-<deckId>`, `deck-analysis-functional-bucket-<deckId>-<ramp|draw|removal|wipes|protection|tutor|recursion|wincon>`, `deck-analysis-functional-count-<deckId>-<bucket>`, `deck-analysis-functional-samples-<deckId>-<bucket>`, `deck-analysis-functional-sample-<deckId>-<bucket>-<index>` | Consome `/decks/:id/analysis` e mostra contagens + amostras de `functional_tags`; quando `sample_details` v2 existe, exibe motivo amigável, confidence, speed e mana efficiency com fallback para `samples`/`stats.composition` legado. | Usar keys por deck/bucket; texto só como evidência da origem/cobertura. |
| Estados análise funcional | `DeckAnalysisTab` aba `Análise` | `deck-analysis-functional-loading`, `deck-analysis-functional-error`, `deck-analysis-functional-empty`, `deck-analysis-functional-retry-button`, `deck-analysis-functional-refresh-button` | Diferencia loading, erro amigável e resposta sem contagens. | Validar ausência de erro técnico cru e retry por key. |
| Importar lista no deck | `DeckDetailsScreen` dialog | `deck-import-list-dialog`, `deck-import-list-dialog-field`, `deck-import-list-dialog-replace-switch`, `deck-import-list-dialog-submit-button`, `deck-import-list-dialog-cancel-button` | Cola lista no deck atual e opcionalmente substitui cartas. | `enterText` e tap por key; validar refresh/API. |
| Estados importar lista | `DeckDetailsScreen` dialog | `deck-import-list-dialog-error`, `deck-import-list-dialog-not-found` | Expõe erro amigável e linhas não encontradas. | Texto como evidência visual ancorado por key. |
| Importar lista full-screen | `DeckImportScreen` | `deck-import-screen`, `deck-import-screen-name-field`, `deck-import-screen-format-field`, `deck-import-screen-commander-field`, `deck-import-screen-description-field`, `deck-import-screen-list-field`, `deck-import-screen-example-button`, `deck-import-screen-count-status`, `deck-import-screen-error`, `deck-import-screen-submit-button` | Cria deck a partir de lista colada. | Usar keys de tela para testes widget/runtime. |
| Editar quantidade de carta | `DeckCardEditDialog` | `deck-card-edit-quantity-field` | Edita quantidade de carta não-comandante. | `enterText` por key. |
| Editar descrição | Dialog de descrição | `deck-description-editor-field`, `deck-description-editor-cancel-button`, `deck-description-editor-save-button` | Edita plano/descrição do deck. | `enterText` e salvar por key. |

## Auth / Profile

| Superfície | Rota/Tela | Key estável | Contrato esperado | Validação recomendada |
|---|---|---|---|---|
| Email login | `LoginScreen` | `login-email-field` | Preenche credencial sem depender de índice de `TextField`. | `enterText` por key. |
| Senha login | `LoginScreen` | `login-password-field` | Preenche senha. | `enterText` por key. |
| Entrar | `LoginScreen` | `login-submit-button` | Executa login e navega para shell autenticado. | Tap por key + validar rota. |
| Abrir cadastro | `LoginScreen` | `login-open-register-button` | Navega para cadastro. | Tap por key. |
| Usuário cadastro | `RegisterScreen` | `register-username-field` | Preenche username. | `enterText` por key. |
| Email cadastro | `RegisterScreen` | `register-email-field` | Preenche email. | `enterText` por key. |
| Senha cadastro | `RegisterScreen` | `register-password-field` | Preenche senha. | `enterText` por key. |
| Confirmar senha | `RegisterScreen` | `register-confirm-password-field` | Confirma senha. | `enterText` por key. |
| Criar conta | `RegisterScreen` | `register-submit-button` | Cria sessão autenticada. | Tap por key + validar shell. |
| Editar avatar | `ProfileScreen` | `profile-avatar-edit-button` | Abre dialog de avatar. | Tap por key + screenshot. |
| Dialog avatar | `ProfileScreen` | `profile-avatar-dialog` | Permite aplicar/remover URL. | `find.byKey`. |
| URL avatar | `ProfileScreen` | `profile-avatar-url-field` | Edita URL. | `enterText` por key. |
| Aplicar avatar | `ProfileScreen` | `profile-avatar-apply-button` | Atualiza campo local. | Tap por key. |
| Nome público | `ProfileScreen` | `profile-display-name-field` | Edita display name. | `enterText` por key. |
| Estado/cidade | `ProfileScreen` | `profile-state-field`, `profile-city-field` | Edita localização. | Selecionar/enter por key. |
| Observações de troca | `ProfileScreen` | `profile-trade-notes-field` | Edita texto público de troca. | `enterText` por key. |
| Salvar perfil | `ProfileScreen` | `profile-save-button` | Persiste perfil. | Tap por key + API. |
| Atalhos coleção | `ProfileScreen` | `profile-open-binder-button`, `profile-open-marketplace-button` | Abrem fichário/marketplace. | Tap por key. |
| Busca de usuários | `UserSearchScreen` | `user-search-field`, `user-search-clear-button`, `user-search-list`, `user-search-row-<userId>` | Busca perfis e abre perfil público. | `enterText` e tap por key baseada em `user.id`. |
| Loading busca de usuários | `UserSearchScreen` | `user-search-loading` | Mantém consulta e anuncia busca em andamento. | `find.byKey` + semantics. |

## Search / Sets

| Superfície | Rota/Tela | Key estável | Contrato esperado | Validação recomendada |
|---|---|---|---|---|
| Campo de busca de cartas | `CardSearchScreen` | `card-search-field` | Digita nome/código para buscar cartas. | `enterText` por key. |
| Loading busca cartas | `CardSearchScreen` | `card-search-loading` | Diferencia carregamento inicial de resultado vazio. | `find.byKey`. |
| Erro busca cartas | `CardSearchScreen` | `card-search-error` | Falha de `/cards` nao deve aparecer como lista vazia. | `find.byKey` + retry quando query existir. |
| Vazio busca cartas | `CardSearchScreen` | `card-search-empty-state` | Estado inicial ou nenhum resultado. | `find.byKey`; validar ausencia de erro. |
| Tabs de busca | `CardSearchScreen` | `cardSearchTabs` | Alterna `Cartas` e `Coleções`. | Tap por texto visível ou índice apenas após localizar key. |
| Lista de resultados | `CardSearchScreen` | `card-search-results-list` | Renderiza resultados de `/cards`. | Screenshot + contagem mínima. |
| Resultado de carta | `CardSearchScreen` | `card-search-result-<cardId>` | Linha com nome, edição e restrições Commander. | `find.byKey` + texto como evidência. |
| Imagem/detalhe de carta | `CardSearchScreen` | `card-search-image-<cardId>` | Abre `CardDetailScreen`. | Tap por key e validar detalhe. |
| Adicionar carta | `CardSearchScreen` | `card-search-add-<cardId>` | Abre dialog ou adiciona conforme modo. | Tap por key; validar API/estado. |
| Dialog adicionar carta | `CardSearchScreen` | `card-search-add-dialog-<cardId>` | Permite quantidade/comandante quando aplicável. | Screenshot + confirmação por API. |
| Confirmar adicionar carta | `CardSearchScreen` | `card-search-add-confirm-<cardId>` | Persiste card no deck/binder. | Tap por key. |
| Lista de coleções | `SetsCatalogScreen` | `setsCatalogList` | Renderiza `/sets`. | `find.byKey`, screenshot. |
| Loading de coleções | `SetsCatalogScreen` | `sets-catalog-loading` | Região viva anuncia carregamento sem confundir com catálogo vazio. | `find.byKey` + semantics. |
| Campo de coleções | `SetsCatalogScreen` | `setsSearchField` | Busca por nome/código. | `enterText` por key. |
| Linha de coleção | `SetsCatalogScreen` | `set-tile-<setCode>` | Abre coleção específica. | Tap por key. |
| Lista de cards do set | `SetCardsScreen` | `setCardsList` | Renderiza `/cards?set=<code>`. | `find.byKey`. |
| Loading de cards do set | `SetCardsScreen` | `set-cards-loading` | Região viva anuncia a coleção em carregamento. | `find.byKey` + semantics. |
| Estado vazio do set | `SetCardsScreen` | `setCardsEmptyState` | Coleção futura/parcial ou sem cartas locais. | `find.byKey` + copy como evidência. |
| Card do set | `SetCardsScreen` | `set-card-<cardName>` | Abre detalhe ou prova presença. | Preferir key; nomes duplicados exigem API quando necessário. |

## Binder / Marketplace / Trades

| Superfície | Rota/Tela | Key estável | Contrato esperado | Validação recomendada |
|---|---|---|---|---|
| Tabs da coleção | `CollectionScreen` | `collection-hub-tabs` | Alterna Fichário, Marketplace, Trades e Coleções. | Localizar key antes de selecionar tab. |
| Atalho catálogo | `CollectionScreen` | `collection-open-sets-catalog` | Abre catálogo de coleções. | Tap por key. |
| Atalho última edição | `CollectionScreen` | `collection-open-latest-set` | Abre latest set. | Tap por key. |
| Dashboard do fichário | `BinderTabContent` | `binder-stats-dashboard` | Mostra resumo de coleção. | Screenshot + validar números por API quando possível. |
| Cards totais/únicas/duplicadas | `BinderTabContent` | `binder-stat-total`, `binder-stat-unique`, `binder-stat-duplicates` | Métricas principais visíveis. | Texto como evidência visual. |
| Busca do fichário | `BinderTabContent` | `binder-search-field` | Filtra binder. | `enterText` por key. |
| Lista do fichário | `BinderTabContent` | `binder-list-<have|want>` | Renderiza itens do binder. | `find.byKey`. |
| Loading fichário | `BinderTabContent` | `binder-list-loading-<have|want>` | Diferencia carregamento inicial de lista vazia. | `find.byKey`. |
| Erro fichário | `BinderTabContent` | `binder-list-error-<have|want>` | Falha de `/binder` nao deve aparecer como lista vazia. | `find.byKey` + retry `binder-list-retry-<have|want>`. |
| Vazio fichário | `BinderTabContent` | `binder-list-empty-<have|want>` | Estado real sem itens no filtro/lista. | `find.byKey`; validar ausencia de erro. |
| Card do fichário | `BinderTabContent` | `binder-item-card-<binderItemId>` | Abre editor do item. | Tap por key + API. |
| Ação adicionar no fichário | `BinderTabContent` | `binder-add-card-action` | Abre busca para adicionar. | Tap por key. |
| Ação scanner no fichário | `BinderTabContent` | `binder-scan-card-action` | Scanner, fora de escopo quando explicitamente ignorado. | Não usar em non-scanner QA. |
| Editor foil | `BinderItemEditor` | `binder-editor-foil-switch` | Liga/desliga foil. | Tap por key + validar request. |
| Editor trade/sale | `BinderItemEditor` | `binder-editor-for-trade-switch`, `binder-editor-for-sale-switch` | Define disponibilidade pública. | Tap por key. |
| Editor preço | `BinderItemEditor` | `binder-editor-price-field` | Preço opcional. | `enterText` por key. |
| Editor notas | `BinderItemEditor` | `binder-editor-notes-field` | Nota privada/pública conforme contrato atual. | `enterText` por key. |
| Editor condição/idioma | `BinderItemEditor` | `binder-editor-condition-<condition>`, `binder-editor-language-<language>` | Seleciona condição e idioma. | Tap por key. |
| Editor quantidade | `BinderItemEditor` | `binder-editor-quantity-decrement`, `binder-editor-quantity-value`, `binder-editor-quantity-increment` | Ajusta quantidade. | Tap por key + validar valor. |
| Salvar/remover item | `BinderItemEditor` | `binder-editor-save-button`, `binder-editor-remove-button` | Persiste ou remove item. | Tap por key + API. |
| Busca marketplace | `MarketplaceTabContent` | `marketplace-search-field` | Filtra marketplace. | `enterText` por key. |
| Lista marketplace | `MarketplaceTabContent` | `marketplace-list` | Renderiza `/community/marketplace`. | Screenshot + latência. |
| Loading marketplace | `MarketplaceTabContent` | `marketplace-list-loading` | Diferencia carregamento inicial de marketplace vazio. | `find.byKey`. |
| Erro marketplace | `MarketplaceTabContent` | `marketplace-list-error` | Falha de marketplace nao deve aparecer como lista vazia. | `find.byKey` + retry `marketplace-list-retry`. |
| Vazio marketplace | `MarketplaceTabContent` | `marketplace-list-empty` | Estado real sem cards para filtros atuais. | `find.byKey`; validar ausencia de erro. |
| Card marketplace | `MarketplaceTabContent` | `marketplace-item-card-<marketItemId>` | Mostra item, preço, trust e ações. | `find.byKey`. |
| Dono do item | `MarketplaceTabContent` | `marketplace-owner-<ownerId>` | Abre perfil público. | Tap por key quando seguro. |
| Propor trade/compra | `MarketplaceTabContent` | `marketplace-propose-trade-<marketItemId>` | Abre criação de trade. | Tap por key + confirmar review. |
| Tipo de proposta | `CreateTradeScreen` | `create-trade-type-trade`, `create-trade-type-sale`, `create-trade-type-mixed` | Seleciona fluxo de troca/compra/misto. | Tap por key. |
| Adicionar itens | `CreateTradeScreen` | `create-trade-add-item-requested`, `create-trade-add-item-offered` | Abre picker de itens. | Tap por key + seleção. |
| Item selecionado | `CreateTradeScreen` | `create-trade-selected-item-<requested|offered>-<index>` | Mostra item escolhido. | `find.byKey`. |
| Quantidade item | `CreateTradeScreen` | `create-trade-item-decrement-<prefix>-<index>`, `create-trade-item-quantity-<prefix>-<index>`, `create-trade-item-increment-<prefix>-<index>` | Ajusta quantidade na proposta. | Tap por key. |
| Remover item | `CreateTradeScreen` | `create-trade-item-remove-<prefix>-<index>` | Remove item da proposta. | Tap por key. |
| Pagamento | `CreateTradeScreen` | `create-trade-payment-field`, `create-trade-payment-method-<pix|transfer|other>` | Define valor e método. | `enterText`/tap por key. |
| Mensagem da proposta | `CreateTradeScreen` | `create-trade-message-field` | Mensagem opcional. | `enterText` por key. |
| Review da proposta | `CreateTradeScreen` | `create-trade-review-dialog`, `create-trade-review-back-button`, `create-trade-review-confirm-button` | Usuário revisa antes de enviar. | Screenshot + tap por key. |
| Ações de trade | `TradeDetailScreen` | `trade-action-accept`, `trade-action-decline`, `trade-action-cancel`, `trade-action-ship`, `trade-action-confirm-delivery`, `trade-action-complete`, `trade-action-dispute` | Mudam status com confirmação quando crítico. | Tap por key + validar status via API. |
| Loading de trades | `TradeInboxScreen` / `TradeDetailScreen` | `trade-inbox-loading`, `trade-detail-loading-state` | Lista e detalhe anunciam carregamento sem mascarar vazio/erro. | `find.byKey` + semantics. |
| Dialog de envio | `TradeDetailScreen` | `trade-ship-confirm-dialog` | Coleta rastreio/método antes de marcar enviado. | Screenshot + campos por key. |
| Campo rastreio | `TradeDetailScreen` | `trade-ship-tracking-field` | Rastreio opcional. | `enterText` por key. |
| Método de envio | `TradeDetailScreen` | `trade-ship-method-field` | Método seguro. | Selecionar por key. |
| Confirmar envio | `TradeDetailScreen` | `trade-ship-confirm-button` | Muda status para enviado. | Tap por key + API. |
| Chat de trade | `TradeDetailScreen` | `trade-message-field`, `trade-message-send-button` | Envia mensagem presa ao trade. | `enterText` + tap por key. |

## Community

| Superfície | Rota/Tela | Key estável | Contrato esperado | Validação recomendada |
|---|---|---|---|---|
| Tabs comunidade | `CommunityScreen` | `community-tabs` | Alterna Explorar, Seguindo, Usuários e Cotações. | Localizar TabBar por key; texto só como evidência. |
| Busca Explorar | `_ExploreTab` | `community-explore-search-field`, `community-explore-search-clear-button` | Busca decks públicos. | `enterText` por key + submit. |
| Filtros Explorar | `_ExploreTab` | `community-explore-format-chip-<format|all>` | Filtra decks por formato. | Tap por key. |
| Lista Explorar | `_ExploreTab` | `community-explore-deck-list`, `community-explore-deck-row-<deckId>`, `community-explore-deck-owner-<ownerId>` | Abre deck público ou perfil do dono. | Usar IDs vindos do setup/API em runtime. |
| Estados Explorar | `_ExploreTab` | `community-explore-loading`, `community-explore-error`, `community-explore-retry`, `community-explore-empty` | Diferencia loading/erro/vazio no feed público. | Validar erro por key antes de copy. |
| Lista Seguindo | `_FollowingFeedTab` | `community-following-deck-list`, `community-following-deck-row-<deckId>` | Abre decks dos seguidos. | `find.byKey` + screenshot. |
| Estados Seguindo | `_FollowingFeedTab` | `community-following-loading`, `community-following-error`, `community-following-retry`, `community-following-empty` | Diferencia loading/erro/vazio do feed seguido. | Validar erro por key antes de copy. |
| Busca Usuários inline | `_UserSearchTab` | `community-users-search-field`, `community-users-search-clear-button`, `community-users-list`, `community-users-row-<userId>` | Busca perfis na aba Comunidade. | `enterText` e tap por key baseada em `user.id`. |
| Estados Usuários | `_UserSearchTab` | `community-users-loading`, `community-users-error`, `community-users-empty-query`, `community-users-empty` | Diferencia busca inicial, falha e zero resultados. | `find.byKey`; texto como evidência visual. |

## Messages / Notifications

| Superfície | Rota/Tela | Key estável | Contrato esperado | Validação recomendada |
|---|---|---|---|---|
| Campo de chat direto | `ChatScreen` | `chat-message-field` | Preenche mensagem direta. | `enterText` por key. |
| Loading chat direto | `ChatScreen` | `chat-loading-state` | Carregamento inicial não se confunde com conversa vazia. | `find.byKey` + semantics. |
| Enviar chat direto | `ChatScreen` | `chat-message-send-button` | Persiste mensagem em `/conversations/:id/messages`. | Tap por key + API. |
| Lista de conversas | `MessageInboxScreen` | `messages-inbox-list` | Renderiza `/conversations` e atualiza por foreground/polling leve. | `find.byKey` + contagem por API. |
| Conversa individual | `MessageInboxScreen` | `message-conversation-tile-<conversationId>` | Abre `/messages/:conversationId` com contexto estável para tap de FCM. | Tap por key ou deep link por rota. |
| Loading inbox | `MessageInboxScreen` | `messages-inbox-loading` | Diferencia carregamento inicial de lista vazia. | `find.byKey`; nao depender de spinner anonimo. |
| Erro inbox | `MessageInboxScreen` | `messages-inbox-error` | Falha de `/conversations` nao deve aparecer como inbox vazio. | `find.byKey` + retry por texto/key de acao. |
| Inbox vazio | `MessageInboxScreen` | `messages-inbox-empty` | Estado realmente sem conversas. | `find.byKey`; validar ausencia de erro. |
| Lista de notificações | `NotificationScreen` | `notifications-list` | Renderiza notificações. | `find.byKey`. |
| Notificação individual | `NotificationScreen` | `notification-tile-<notificationId>` | Abre contexto e marca como lida quando aplicável. | Tap por key. |
| Ler todas | `NotificationScreen` | `notifications-read-all-button` | Marca todas como lidas. | Tap por key + API. |
| Loading notificações | `NotificationScreen` | `notifications-loading` | Diferencia carregamento inicial de lista vazia. | `find.byKey`; nao depender de spinner anonimo. |
| Erro notificações | `NotificationScreen` | `notifications-error` | Falha de `/notifications` nao deve aparecer como lista vazia. | `find.byKey` + retry por texto/key de acao. |
| Notificações vazias | `NotificationScreen` | `notifications-empty` | Estado realmente sem notificações. | `find.byKey`; validar ausencia de erro. |

## Optimize

| Superfície | Rota/Tela | Key estável | Contrato esperado | Validação recomendada |
|---|---|---|---|---|
| Preview de optimize | `OptimizationPreviewDialog` | `optimize-preview-dialog` | Mostra plano antes de aplicar. | `find.byKey` + screenshot. |
| Intensidade | `OptimizationConfigSection` | `optimize-intensity-light`, `optimize-intensity-focused`, `optimize-intensity-aggressive`, `optimize-intensity-rebuild` | Seleciona intensidade sem depender de texto. | Tap por key. |
| Manter tema | `OptimizationConfigSection` | `optimize-keep-theme-switch` | Mantém plano principal do deck quando possível. | Tap por key. |
| Estratégia atual | `CurrentStrategySection` | `optimize-apply-current-strategy-button` | Aplica estratégia detectada. | Tap por key. |
| Sugestão de remoção | `OptimizationPreviewDialog` | `optimize-suggestion-remove-<index>` | Permite desmarcar remoção. | Tap por key; validar seleção parcial. |
| Sugestão de adição | `OptimizationPreviewDialog` | `optimize-suggestion-add-<index>` | Permite desmarcar adição. | Tap por key; validar seleção parcial. |
| Aplicar preview | `OptimizationPreviewDialog` | `optimize-preview-apply-button` | Aplica somente swaps selecionados. | Tap por key; validar deck final por API. |
| Diagnóstico local | `DeckDiagnosticPanel` | `deck-diagnostic-panel`, `deck-diagnostic-summary-badge`, `deck-diagnostic-metric-<label>`, `deck-diagnostic-insight-<index>` | Âncoras para no-op/gate local sem depender só de copy. | `find.byKey` para bloco e métrica; texto como evidência. |
| Resultado informativo | `OutcomeInfoDialog` | `optimize-outcome-info-dialog` | Exibe no-op seguro, near-peak ou falha de rebuild sem expor erro cru. | `find.byKey`; texto apenas classifica o motivo. |
| Rebuild guiado | `GuidedRebuildActionDialog` | `optimize-rebuild-guided-dialog`, `optimize-rebuild-guided-cancel-button`, `optimize-rebuild-guided-create-button` | Explica rebuild como ação de produto. | Tap por key; não expor erro técnico cru. |
| Erros amigáveis | Optimize flow | `optimize-ai-error-snackbar`, `optimize-apply-error-snackbar` | Fallback quando backend/job falha sem preview aplicável. | `find.byKey` + garantir ausência de copy técnica sensível. |

## Generate

| Superfície | Rota/Tela | Key estável | Contrato esperado | Validação recomendada |
|---|---|---|---|---|
| Formato do deck | `DeckGenerateScreen` | `deck-generate-format-field` | Seleciona formato. | Seleção por key. |
| Comandante opcional | `DeckGenerateScreen` | `deck-generate-commander-field` | Envia `commander_name` para `/ai/generate` em Commander/Brawl quando preenchido, preservando omissão no legado. | `enterText` por key + validar payload do provider/API. |
| Prompt | `DeckGenerateScreen` | `deck-generate-prompt-field` | Descreve deck. | `enterText` por key. |
| Gerar | `DeckGenerateScreen` | `deck-generate-submit-button` | Dispara `/ai/generate` sync/async. | Tap por key + polling. |
| Nome do deck gerado | `DeckGenerateScreen` | `deck-generate-name-field` | Edita nome antes de salvar. | `enterText` por key. |
| Salvar deck gerado | `DeckGenerateScreen` | `deck-generate-save-button` | Persiste deck gerado. | Tap por key + API. |

## Life Counter / Lotus

| Superfície | Rota/Tela | Key estável | Contrato esperado | Validação recomendada |
|---|---|---|---|---|
| Lotus loading | `LotusLoadingOverlay` | `lotus-loading-overlay` | Shell carregando contador. | `find.byKey` + screenshot. |
| Lotus erro/retry | `LotusErrorOverlay` | `lotus-error-overlay`, `lotus-error-retry-button` | Erro de shell com retry seguro. | Tap retry por key; copy como evidência. |
| Sheet estado jogador | Life Counter nativo | `life-counter-native-player-state-sheet` | Overlay principal de estado do jogador. | Usar root key e ações internas já mapeadas. |
| Sheet dados | Life Counter nativo | `life-counter-native-dice-sheet` | Overlay de dado/moeda/high roll. | Usar root key e botões internos já mapeados. |
| Sheet configurações | Life Counter nativo | `life-counter-native-settings-sheet` | Overlay de ajustes do contador. | Usar root key e `life-counter-native-settings-save`. |
| Sheet busca carta | Life Counter nativo | `life-counter-native-card-search-sheet` | Overlay de busca de carta sem Scanner/OCR. | Usar root key e campos internos já mapeados. |

## Runtime helper

`app/integration_test/runtime_test_helpers.dart` centraliza esperas e sessão:

- `pumpUntil`, `pumpUntilFound`, `pumpUntilAbsent`;
- `pumpUntilAnyFound`;
- `clearRuntimeAuth`;
- `seedAuthenticatedSession`;
- `captureRuntimeCheckpoint`;
- `expectNoRawTechnicalErrorText`.

Novos harnesses devem usar esse helper antes de criar funções locais duplicadas.

## Harnesses migrados - 2026-05-08

Os harnesses abaixo foram migrados para usar os anchors deste mapa e o helper
comum de runtime:

| Harness | Melhoria aplicada | Fallback ainda aceito |
|---|---|---|
| `sets_search_catalog_runtime_test.dart` | Busca de cartas por `card-search-field` e esperas por helper comum. | Tabs ainda usam texto como evidência visual. |
| `deck_generate_async_runtime_test.dart` | Cadastro, prompt, gerar, nome e salvar por keys estáveis. | Estados visuais de progresso continuam validados por copy. |
| `deck_runtime_m2006_test.dart` | Cadastro, criar deck, importar lista, estratégia atual, intensidade, preview/no-op/rebuild/erro amigável de optimize por keys estáveis. | Nome do tab/rota ainda aparece como evidência visual. |
| `profile_community_runtime_test.dart` | Campos de perfil, UserSearchScreen, busca Explore e Users da Comunidade por keys estáveis. | Conteúdo de deck público ainda usa texto como evidência visual depois do tap por key. |
| `binder_marketplace_trade_runtime_test.dart` | Binder editor, marketplace search, review de trade, ações de status, chat, notificações e direct messages por keys estáveis e helper comum. | Alguns textos de confirmação permanecem como evidência visual. |
| `sets_catalog_runtime_test.dart` | Catálogo de coleções usa helper comum e abre sets por `set-tile-<setCode>`. | Título/nome da coleção segue como evidência visual. |
| `collection_entrypoints_runtime_test.dart` | Entry points de coleção usam helper comum de runtime. | Tabs ainda usam texto como evidência visual. |
| `app_full_non_life_counter_visual_capture_smoke_test.dart` | Criar deck e Generate usam keys de dialog/prompt/CTA; helpers genéricos foram removidos. | Navegação ampla do shell ainda usa labels das tabs como evidência visual. |
| `lorehold_generate_reference_stats_runtime_test.dart` | Cadastro, CTA de generate em lista vazia, comandante, prompt, salvar preview e abrir deck salvo por keys estáveis. | Labels de navegação `Decks`/`Meus Decks` seguem como evidência visual. |
| `strixhaven_commander_profiles_runtime_test.dart` | Cadastro/login, generate Commander com `commander_name`, preview, salvar, abrir Deck Detail e validar decks por keys estáveis e API real. | Labels de navegação `Decks`/`Meus Decks` seguem como evidência visual; screenshots ficam como markers sanitizados. |
| `commander_reference_sprint3_lot_c_app_runtime_test.dart` | Cadastro/login, Generate Commander com `commander_name`, preview, salvar, abrir Deck Detail e validar Brago/Purphoros por keys estáveis e API real. | Labels de navegação `Decks`/`Meus Decks` seguem como evidência visual; Purphoros e cobertura app-runtime adjunta, nao segundo promovido backend. |

## Checkpoints obrigatórios para agentes

1. Consultar este arquivo antes de criar ou alterar harness de runtime.
2. Consultar `server/doc/API_CONTRACTS_AND_DATA_MAP.md` antes de validar estado
   persistente via backend.
3. Se um teste precisar usar `find.text` ou `find.byType` em fluxo P1, registrar
   por que não existe key e propor a key mínima.
4. Se um modal/sheet abre mas o toque falha, investigar camada sobreposta antes
   de aumentar timeout.
5. Registrar screenshots locais em pasta ignorada de `app/doc/runtime_flow_proofs_*`.

## Backlog de mapeamento

- Wrappers visuais restantes: substituir validacoes apenas por texto quando
  houver lista/card/container acionavel ainda sem key. Após esta rodada, os
  fallbacks conhecidos ficam principalmente em labels de tabs, confirmações
  modais e evidência visual não-acionável.
- Helpers específicos de Life Counter que fazem polling de estado/snapshot não
  são duplicatas do helper comum de widget tree; migrar caso virem espera
  genérica de Finder.
- Scanner/câmera/OCR: permanece fora de escopo quando o release for
  explicitamente non-scanner.
