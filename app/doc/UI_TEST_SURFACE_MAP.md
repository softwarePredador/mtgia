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
| Busca marketplace | `MarketplaceTabContent` | `marketplace-search-field` | Filtra marketplace. | `enterText` por key. |
| Lista marketplace | `MarketplaceTabContent` | `marketplace-list` | Renderiza `/community/marketplace`. | Screenshot + latência. |
| Card marketplace | `MarketplaceTabContent` | `marketplace-item-card-<marketItemId>` | Mostra item, preço, trust e ações. | `find.byKey`. |
| Dono do item | `MarketplaceTabContent` | `marketplace-owner-<ownerId>` | Abre perfil público. | Tap por key quando seguro. |
| Propor trade/compra | `MarketplaceTabContent` | `marketplace-propose-trade-<marketItemId>` | Abre criação de trade. | Tap por key + confirmar review. |
| Ações de trade | `TradeDetailScreen` | `trade-action-accept`, `trade-action-decline`, `trade-action-cancel`, `trade-action-ship`, `trade-action-confirm-delivery`, `trade-action-complete`, `trade-action-dispute` | Mudam status com confirmação quando crítico. | Tap por key + validar status via API. |
| Dialog de envio | `TradeDetailScreen` | `trade-ship-confirm-dialog` | Coleta rastreio/método antes de marcar enviado. | Screenshot + campos por key. |
| Campo rastreio | `TradeDetailScreen` | `trade-ship-tracking-field` | Rastreio opcional. | `enterText` por key. |
| Método de envio | `TradeDetailScreen` | `trade-ship-method-field` | Método seguro. | Selecionar por key. |
| Confirmar envio | `TradeDetailScreen` | `trade-ship-confirm-button` | Muda status para enviado. | Tap por key + API. |

## Optimize

| Superfície | Rota/Tela | Key estável | Contrato esperado | Validação recomendada |
|---|---|---|---|---|
| Preview de optimize | `OptimizationPreviewDialog` | `optimize-preview-dialog` | Mostra plano antes de aplicar. | `find.byKey` + screenshot. |
| Sugestão de remoção | `OptimizationPreviewDialog` | `optimize-suggestion-remove-<index>` | Permite desmarcar remoção. | Tap por key; validar seleção parcial. |
| Sugestão de adição | `OptimizationPreviewDialog` | `optimize-suggestion-add-<index>` | Permite desmarcar adição. | Tap por key; validar seleção parcial. |
| Aplicar preview | `OptimizationPreviewDialog` | `optimize-preview-apply-button` | Aplica somente swaps selecionados. | Tap por key; validar deck final por API. |

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

- Binder/Fichário: adicionar keys para todos os campos do editor e filtros
  avançados restantes.
- Marketplace/Trades: mapear chat, notificações, review completo de proposta e
  inbox.
- Optimize: mapear seletor de intensidade, diagnostics/no-op e jobs async.
- Life Counter/Lotus: manter keys existentes e mapear overlays principais neste
  arquivo.
