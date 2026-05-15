# Full flow state and documentation audit - 2026-05-15

## Scope

Objetivo: limpar orientacao documental antiga e verificar fluxos com risco de
estado stale no app ManaLoom, sem reabrir Scanner/camera/OCR.

Escopo verificado:

- documentacao em `docs/`, `app/doc/`, `server/doc/` e handoffs;
- providers/telas app-facing de Community, Binder/Marketplace, Messages,
  Notifications, Trades e Decks;
- contratos recentes de unread counts, import-to-deck e mutacoes que afetam
  listas/counters;
- testes focados de providers e widgets.

## Documentation cleanup

Mudancas aplicadas:

- `docs/README.md` foi refeito como indice curto das fontes canônicas atuais;
- documentos antigos de marco/abril foram reclassificados como historicos;
- `app/doc/runtime_flow_handoffs/README.md` agora aponta para evidencias
  recentes e marca Scanner/camera/OCR como deferred no escopo non-scanner;
- `server/manual-de-instrucao.md` e `app/doc/APP_AUDIT_2026-04-29.md` foram
  atualizados com a auditoria e os patches aplicados.

Decisao: nao deletar relatórios/proofs antigos rastreados porque eles sustentam
decisoes anteriores e evidencias de regressao. A limpeza foi feita removendo
essas referencias da trilha ativa.

## State refresh fixes applied

### Community decks

Problema: `fetchPublicDecks(reset: true)` podia ser bloqueado por uma busca
anterior em andamento, deixando filtro novo vazio/stale.

Patch: geracao de requisicao (`_fetchGeneration`) e aceite de reset enquanto
busca anterior ainda roda. Resposta atrasada antiga e ignorada.

### Binder and Marketplace

Problema: `fetchMyBinder`, `fetchMarketplace` e `fetchPublicBinder` tinham risco
similar de resposta atrasada ou reset bloqueado por loading anterior.

Patch: geracoes separadas para Binder, Marketplace e Public Binder; reset passa
a iniciar uma nova requisicao e respostas antigas nao sobrescrevem estado atual.

### Messages

Problema: resposta atrasada de mensagens da conversa A podia sobrescrever a
lista quando usuario ja estava na conversa B.

Patch: `fetchMessages` ignora payload quando existe conversa ativa diferente da
requisitada.

### Previously closed in same audit thread

- Conversation read consome/retorna unread autoritativo.
- Notifications read-all consome/retorna unread autoritativo.
- Direct message send atualiza inbox.
- Trade status/respond atualiza linha da lista.
- Import-to-deck atualiza deck selecionado e retorna `deck_id`/`total_cards`.
- Binder `list_type` remove item da aba filtrada quando migra de lista.

## Remaining non-blocking risks

- Scanner/camera/OCR permanece deferred.
- Provas runtime fisicas devem ser reexecutadas apenas quando forem objetivo da
rodada; os testes desta auditoria foram unit/provider/widget.
- Existem muitos proof folders historicos versionados; reduzir isso exigiria uma
politica de artefatos separada para nao apagar evidencia usada em handoffs.
- Logout cross-provider state reset ainda merece uma suite dedicada maior, mas
os providers principais ja possuem `clearAllState` e os riscos de fetch tardio
mais evidentes foram tratados nesta rodada.

## Validation commands

Executados nesta rodada:

```bash
cd app && flutter analyze lib/features/community/providers/community_provider.dart lib/features/binder/providers/binder_provider.dart lib/features/messages/providers/message_provider.dart test/features/community/providers/community_provider_test.dart test/features/binder/providers/binder_provider_test.dart test/features/messages/providers/message_provider_test.dart --no-version-check
cd app && flutter test test/features/community/providers/community_provider_test.dart test/features/binder/providers/binder_provider_test.dart test/features/messages/providers/message_provider_test.dart --no-version-check
cd app && flutter analyze lib/features/decks/widgets/deck_diagnostic_panel.dart test/features/decks/widgets/deck_diagnostic_panel_test.dart --no-version-check
cd app && flutter test test/features/decks/widgets/deck_diagnostic_panel_test.dart --no-version-check
cd app && flutter analyze lib test --no-version-check
cd app && flutter test test --no-version-check
```

Resultado: PASS nos testes/analyzes focados e na suite Flutter completa. A
primeira tentativa da suite completa expôs um mock antigo em
`home_screen_test.dart` que ainda sobrescrevia `fetchDecks()` sem o parametro
`silent`; o mock foi corrigido e a suite completa fechou verde.
