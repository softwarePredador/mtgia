# Receipt — LC-P0-06: 409 e 404 do pós-jogo no app — 2026-10-05

- Branch `claude/frente-contador-de-vida-ibnawb`. Raia do app, escrita do zero sobre os códigos do servidor (`server/lib/retention/post_game_error_contract.dart`, receipt de 2026-09-28). O rascunho antigo da raia do app, que vivia fora do repositório, não foi usado. Nada tocou a produção.
- `post_game_note_store.dart`: o cliente lança `PostGameRemoteRejection` com status, `error`, `error_code`, `message` e `current_note`. Rejeição definitiva (400, 404 de nota, 409, 413, 422) no salvamento desfaz a gravação local e lança `PostGameNoteRejectedException`; rede, 401, 5xx e a capability desligada mantêm a nota no outbox.
- DELETE: o tombstone só sai com 2xx, `post_game_note_not_found` (ou a frase antiga do servidor) ou `post_game_note_deleted`. Qualquer outro 404 (capability, deck de outra conta) mantém a nota apagada, e o próximo carregamento não a ressuscita.
- Nota recusada em segundo plano sai do outbox e da lista local; `takeSyncRejections` entrega o motivo uma vez.
- `post_game_notes_screen.dart`: a frase do servidor aparece no painel de erro, sem "Tentar novamente" e com o formulário preenchido.

## Evidência

- `app/test/features/retention/post_game_note_store_test.dart`, grupo `LC-P0-06` com o `ApiPostGameNoteRemoteClient` real sobre um `ApiClient` falso: segunda nota da partida (409 com código e sem código), 503 e capability mantêm pendente, três 404 que não ressuscitam a nota, três respostas que encerram o tombstone, rejeição em segundo plano avisada uma vez.
- `app/test/features/retention/post_game_notes_screen_resilience_test.dart`: o 409 mostra a frase sem botão de repetir e mantém o formulário; a rejeição em segundo plano aparece uma vez.
- `app/test/features/retention/post_game_card_evidence_test.dart` ganhou o caso do `LC-P0-05`: partida longa com a revisão no mesmo instante mantém o seletor de cartas.

Falta: a prova viva da seção 10 do fluxo (segunda nota, apagar com a capability desligada) no lote do `BT-UIEV-001`.
