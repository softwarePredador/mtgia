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

- Binder/Fichário: adicionar keys para editor, filtros, dashboard e ações de
  add/edit/delete.
- Marketplace/Trades: adicionar keys para review de proposta, status actions,
  chat e notificações.
- Optimize: adicionar keys para intensidade, diagnostics, preview, seleção
  parcial e apply.
- Sets/Search: adicionar keys para tabs, filtros e card/set result rows.
- Life Counter/Lotus: manter keys existentes e mapear overlays principais neste
  arquivo.
