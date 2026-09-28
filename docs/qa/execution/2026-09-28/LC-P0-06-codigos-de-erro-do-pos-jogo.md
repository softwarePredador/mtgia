# Receipt — LC-P0-06, parte do servidor: 404 e 409 do pós-jogo com `error_code` — 2026-09-28

- Tarefa: `LC-P0-06` (achado 14 dos fluxos; A1–A4 de `docs/flows/life_counter_post_game.md`),
  parte do servidor, feita pela Frente B (deck e trocas) na branch
  `deck/rodada2-2026-09-24`, sobre `bbcbce8dd`. É a decisão 23 da coordenação
  (`~/.manaloom/coordenacao/receipts/decisoes-pendentes.md`): o rascunho do app reconhecia a
  nota inexistente pela frase e o 409 de partida repetida pela falta de `current_note`.
- Contrato seguido: o de erro tipado do `BT-AUTH-001` (D-21, `server/lib/public_error_contract.dart`
  na integração). Nas rotas de deck, a frase fica em `error` e o código estável em
  `error_code`; o middleware da integração não sobrescreve um código que a rota já mandou.
- Nada tocou a produção. Sem migration. Nenhum arquivo do app.

## O que mudou

- `server/lib/retention/post_game_error_contract.dart` (novo): os códigos e os corpos dos
  404 e 409 do pós-jogo.

  | Status | Código em `error_code` | Quando |
  | --- | --- | --- |
  | 404 | `deck_not_found` | deck de outra conta, ou que sumiu no meio do upsert (GET, POST, DELETE e linha do tempo) |
  | 404 | `post_game_note_not_found` | DELETE de nota que este deck nunca teve; POST com o id de nota de outra conta |
  | 409 | `post_game_play_session_conflict` | a partida (`play_session_id`) já tem uma nota viva neste deck (`uq_post_game_notes_play_session`) |
  | 409 | `post_game_note_deleted` | a nota foi apagada em outro aparelho (tombstone), com `current_note` |
  | 409 | `post_game_revision_conflict` | `base_revision` ou `If-Match` diferente da revisão atual |

- O 409 mantém `error: post_game_conflict`, que o cliente atual e
  `post_game_two_client_live_test.dart` comparam, e ganha o motivo em `error_code` e uma
  frase própria em `message`. As frases dos 404 não mudaram.
- `PostGameConflictException` e `PostGameNoteNotFoundException` levam o código. A violação
  de unicidade (`23505`) olha o nome da constraint: o índice da partida vira
  `post_game_play_session_conflict`; a corrida no id da nota, `post_game_revision_conflict`.
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`: as linhas do GET, POST e DELETE das notas e da
  linha do tempo trazem os códigos.

## Evidência

| Teste | Onde | Resultado |
| --- | --- | --- |
| `server/test/post_game_note_error_codes_db_live_test.dart` (novo): as rotas reais contra o PostgreSQL | PostgreSQL 17 descartável da frente (`LC_ALL=C`, só em `127.0.0.1`, `migrations=65 latest=073`), parado e apagado no fim | 5/5 |
| Todos os testes de banco do servidor (25 arquivos) | o mesmo PostgreSQL | 144 passam; 1 falha anterior, fora desta tarefa: a mesma do receipt do `BT-KPI-001` (`interactive_battle_store_live_test.dart:657`, 42601, "deck lifecycle serializes create/delete and finalize/delete without replay loss") |
| `post_game_error_contract_test.dart` (novo), `post_game_note_sync_contract_test.dart` e `api_contracts_data_map_guard_test.dart` (com o caso novo dos códigos) e a suíte de foco | unitário, com o manifesto regenerado, dentro da trava, antes do commit | 44/44 (8 arquivos) |

Os 5 casos do teste de banco:

- a segunda nota da mesma partida é 409 `post_game_play_session_conflict`, com
  `error: post_game_conflict`;
- salvar de novo uma nota apagada é 409 `post_game_note_deleted`, com `current_note`;
- revisão antiga no upsert e no DELETE é 409 `post_game_revision_conflict`;
- deck de outra conta é 404 `deck_not_found` no GET, no POST, no DELETE e na linha do tempo;
- DELETE de nota que o deck nunca teve e POST com o id de nota de outra conta são 404
  `post_game_note_not_found`.

## Mutações

6 mutações e 12 execuções (`~/.manaloom/coordenacao/deck/mutations.py lc06err`). Todas
morreram no teste de banco. As mutações E1, E4 e E5 morreram também no unitário; E2, E3 e
E6 estão em caminhos da rota e do serviço que só o banco exercita. Cada arquivo foi
restaurado e conferido por hash.

| Mutação | O que muda | Resultado |
| --- | --- | --- |
| E1 | a violação do índice da partida vira conflito de revisão | falhou (esperado), no unitário e no banco |
| E2 | a nota apagada perde o código próprio | falhou (esperado), no banco |
| E3 | o DELETE de nota inexistente responde `deck_not_found` | falhou (esperado), no banco |
| E4 | o 404 sai sem `error_code` | falhou (esperado), no unitário e no banco |
| E5 | o 409 perde `error: post_game_conflict` | falhou (esperado), no unitário e no banco |
| E6 | o POST com o id de nota de outra conta responde `deck_not_found` | falhou (esperado), no banco |

## O app

O rascunho do `LC-P0-06` da raia do app
(`~/.manaloom/coordenacao/deck/app_draft/patches/0005-*.patch`) foi ajustado para ler os
códigos. O DELETE só apaga o tombstone com `post_game_note_not_found`, ou com a frase da
nota, para o servidor antigo. O 409 escolhe o tipo pelo `error_code` e só cai na falta de
`current_note` quando o código não vem. O app segue fechado até as recapturas; o commit
dele é da raia do app.

## O que fica de fora

- O 400 do pós-jogo (carta fora da revisão, achado A2) continua só com a frase; na
  integração, o middleware do `BT-AUTH-001` acrescenta `code: request_invalid`.
- `base_revision` e `If-Match` continuam sem ser enviados pelo app (achado A5).
