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

## Search / Sets

| Superfície | Rota/Tela | Key estável | Contrato esperado | Validação recomendada |
|---|---|---|---|---|
| Campo de busca de cartas | `CardSearchScreen` | `card-search-field` | Digita nome/código para buscar cartas. | `enterText` por key. |
| Tabs de busca | `CardSearchScreen` | `cardSearchTabs` | Alterna `Cartas` e `Coleções`. | Tap por texto visível ou índice apenas após localizar key. |
| Lista de resultados | `CardSearchScreen` | `card-search-results-list` | Renderiza resultados de `/cards`. | Screenshot + contagem mínima. |
| Resultado de carta | `CardSearchScreen` | `card-search-result-<cardId>` | Linha com nome, edição e restrições Commander. | `find.byKey` + texto como evidência. |
| Imagem/detalhe de carta | `CardSearchScreen` | `card-search-image-<cardId>` | Abre `CardDetailScreen`. | Tap por key e validar detalhe. |
| Adicionar carta | `CardSearchScreen` | `card-search-add-<cardId>` | Abre dialog ou adiciona conforme modo. | Tap por key; validar API/estado. |
| Dialog adicionar carta | `CardSearchScreen` | `card-search-add-dialog-<cardId>` | Permite quantidade/comandante quando aplicável. | Screenshot + confirmação por API. |
| Confirmar adicionar carta | `CardSearchScreen` | `card-search-add-confirm-<cardId>` | Persiste card no deck/binder. | Tap por key. |
| Lista de coleções | `SetsCatalogScreen` | `setsCatalogList` | Renderiza `/sets`. | `find.byKey`, screenshot. |
| Campo de coleções | `SetsCatalogScreen` | `setsSearchField` | Busca por nome/código. | `enterText` por key. |
| Linha de coleção | `SetsCatalogScreen` | `set-tile-<setCode>` | Abre coleção específica. | Tap por key. |
| Lista de cards do set | `SetCardsScreen` | `setCardsList` | Renderiza `/cards?set=<code>`. | `find.byKey`. |
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
| Dialog de envio | `TradeDetailScreen` | `trade-ship-confirm-dialog` | Coleta rastreio/método antes de marcar enviado. | Screenshot + campos por key. |
| Campo rastreio | `TradeDetailScreen` | `trade-ship-tracking-field` | Rastreio opcional. | `enterText` por key. |
| Método de envio | `TradeDetailScreen` | `trade-ship-method-field` | Método seguro. | Selecionar por key. |
| Confirmar envio | `TradeDetailScreen` | `trade-ship-confirm-button` | Muda status para enviado. | Tap por key + API. |
| Chat de trade | `TradeDetailScreen` | `trade-message-field`, `trade-message-send-button` | Envia mensagem presa ao trade. | `enterText` + tap por key. |

## Messages / Notifications

| Superfície | Rota/Tela | Key estável | Contrato esperado | Validação recomendada |
|---|---|---|---|---|
| Campo de chat direto | `ChatScreen` | `chat-message-field` | Preenche mensagem direta. | `enterText` por key. |
| Enviar chat direto | `ChatScreen` | `chat-message-send-button` | Persiste mensagem em `/conversations/:id/messages`. | Tap por key + API. |
| Lista de notificações | `NotificationScreen` | `notifications-list` | Renderiza notificações. | `find.byKey`. |
| Notificação individual | `NotificationScreen` | `notification-tile-<notificationId>` | Abre contexto e marca como lida quando aplicável. | Tap por key. |
| Ler todas | `NotificationScreen` | `notifications-read-all-button` | Marca todas como lidas. | Tap por key + API. |

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

## Generate

| Superfície | Rota/Tela | Key estável | Contrato esperado | Validação recomendada |
|---|---|---|---|---|
| Formato do deck | `DeckGenerateScreen` | `deck-generate-format-field` | Seleciona formato. | Seleção por key. |
| Prompt | `DeckGenerateScreen` | `deck-generate-prompt-field` | Descreve deck. | `enterText` por key. |
| Gerar | `DeckGenerateScreen` | `deck-generate-submit-button` | Dispara `/ai/generate` sync/async. | Tap por key + polling. |
| Nome do deck gerado | `DeckGenerateScreen` | `deck-generate-name-field` | Edita nome antes de salvar. | `enterText` por key. |
| Salvar deck gerado | `DeckGenerateScreen` | `deck-generate-save-button` | Persiste deck gerado. | Tap por key + API. |

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
| `deck_runtime_m2006_test.dart` | Cadastro, estratégia atual e intensidade de optimize por keys estáveis. | Dialogs de criar deck/importar lista ainda dependem de texto/campo enquanto não houver keys dedicadas. |
| `profile_community_runtime_test.dart` | Campos e salvar perfil por keys estáveis. | Busca de usuários/comunidade ainda depende de campo textual sem key dedicada. |
| `binder_marketplace_trade_runtime_test.dart` | Binder editor, marketplace search, review de trade, ações de status, chat, notificações e direct messages por keys estáveis. | Alguns wrappers de lista ainda usam texto para evidência visual. |

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

- Criar deck: adicionar keys dedicadas ao dialog de nome/formato e ao botao de
  confirmar, removendo fallback por texto/campo em harnesses de deck runtime.
- Importar lista: adicionar keys ao dialog, campo de lista e botao de importar.
- Community/user search: adicionar keys aos campos de busca e rows acionaveis.
- Optimize diagnostics: mapear keys especificas para diagnostico de no-op/gate
  quando a UI precisar validar esses blocos sem depender de copy.
- Life Counter/Lotus: manter keys existentes e mapear overlays principais neste
  arquivo.
- Wrappers visuais restantes: substituir validacoes apenas por texto quando
  houver lista/card/container acionavel ainda sem key.
- Scanner/câmera/OCR: permanece fora de escopo quando o release for
  explicitamente non-scanner.
