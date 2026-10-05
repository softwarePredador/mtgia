# Receipt — DCK-P0-06: lixeira de decks, restaurar e purga governada — 2026-09-28

- Tarefa: `DCK-P0-06`, Frente B (deck e trocas) da coordenação do MVP, branch
  `deck/rodada2-2026-09-24`, sobre `fc50debe7` (DCK-P0-04).
- Decisões do dono aplicadas: D-30 (purga em 30 dias; deck na lixeira não conta em limite nem
  em aprendizado e entra na exportação; restaurar não republica relatório) e D-19
  (`/reports/:id` segue público, mas morre com o deck apagado).
- Aceite do backlog: "DELETE não apaga cards imediatamente; some de todas as superfícies;
  restore íntegro e privado." A onda 02 pede ainda que a purga tenha janela e auditoria; o
  ensaio de restauração de backup é da infraestrutura e fica de fora.
- Mantido: o relatório compartilhado de deck apagado segue sem ser servido (`5850540d7`). O
  filtro de leitura continua valendo para o estoque antigo, e agora o `DELETE` também
  despublica o relatório de vez, então restaurar não o traz de volta.
- Nada tocou a produção: sem SSH, sem banco live, sem deploy. A migration `072` está só no
  código. Os testes de banco rodaram num PostgreSQL 17 descartável da frente (`LC_ALL=C`,
  só em `127.0.0.1`, sem socket Unix), criado do zero por `server/database_setup.sql` e
  `server/bin/migrate.dart` do worktree (`migrations=64 latest=072`), parado e apagado no fim.
- Só servidor. A tela da lixeira, o restaurar e o texto de confirmação do apagar são da raia
  do app, que está bloqueada até a sessão do gate commitar as recapturas.

## O que mudou

1. **Migration `072` (`deck_trash_lifecycle`).** O `CHECK` de operação do ledger aceita
   `deck_delete` e `deck_restore`, e o índice parcial `idx_decks_user_trash`
   (`user_id, deleted_at DESC WHERE deleted_at IS NOT NULL`) serve a lixeira e a purga.
   Rollback `emptyOnly`: o down só roda sem deck na lixeira e sem evento de lixeira. Com
   deck na lixeira, o código antigo o mostraria como vivo.
2. **Apagar vira ir para a lixeira.** O `DELETE /decks/:id` segue com a trava de ciclo de vida
   do Battle, o `If-Match` e a recusa com partida em andamento, e segue respondendo 204.
   Na mesma transação:
   - marca `decks.deleted_at` e tira o deck da galeria (`is_public` falso);
   - despublica os relatórios do deck;
   - sobe a revisão e grava `deck_delete` no ledger.

   Nada é apagado: cartas, ledger, notas, comentários e o resto ficam até a purga. Deck que
   já está na lixeira responde 404.
3. **Some de todas as superfícies.**
   - As rotas de `/decks/:id` respondem 404 `deck_not_found` pelo guarda novo
     `server/routes/decks/[id]/_middleware.dart`, para qualquer pessoa. Só o
     `POST /decks/:id/restore` passa. Rota nova sob `/decks/:id` já nasce protegida.
   - A mudança de conteúdo também recusa o deck dentro da trava da linha
     (`lockDeckForMutation`), o que fecha a corrida com o `DELETE`.
   - Fora de `/decks/:id`, as leituras filtram `deleted_at`: `GET /decks` (lista e cores),
     a prévia do import em deck existente, o Optimize (configurações, contexto com e sem
     telemetria, acesso), arquétipos, rebuild, as duas rotas legadas, o relatório novo e a
     repetição da materialização do Generate (409 `generate_deck_in_trash`, sem criar outro
     deck). Comunidade, fichário, Battle e notas já filtravam.
   - `server/test/deck_trash_surface_guard_test.dart` falha quando um arquivo novo de
     `routes/` ou `lib/` lê `decks` fora de `/decks/:id` sem o filtro. As exceções ficam numa
     lista, com o motivo.
4. **Aprendizado, limite e exportação.**
   - `bin/ml_extract_features.dart` só lê deck vivo.
   - `bin/pull_learning_events.py` só manda ao Hermes evento de deck vivo. O de deck na
     lixeira espera e volta a sair se o deck for restaurado; o de deck que não existe mais
     não sai.
   - Não há limite de decks no servidor hoje.
   - A exportação e a exclusão da conta já pegavam todos os decks do titular, e agora isso
     está provado com um deck na lixeira (`deleted_at` na exportação).
5. **Lixeira e restaurar.**
   - `GET /decks/trash` lista a lixeira do dono, com `purge_after` (`deleted_at` + 30 dias).
   - `POST /decks/:id/restore` devolve o deck íntegro e privado, sobe a revisão e grava
     `deck_restore`. Os relatórios seguem despublicados. Responde 404
     `deck_not_in_trash` para deck vivo, de outra pessoa ou inexistente, e 409 com
     `If-Match` de outra revisão.
   - Restaurar é rota nova sob `/decks`, então exige e-mail verificado, pela regra que falha
     fechado. O desfazer do histórico recusa `deck_delete` e `deck_restore` (409
     `deck_undo_unsupported`, `can_undo` falso).
6. **Purga governada.** A limpeza por prazo da D-70 (`retention_cleanup_apply_v1`) ganhou três
   regras, e o prazo das regras agora pode contar de outra coluna (`ageColumn`):
   - `shared_deck_reports_trashed_deck_30d`;
   - `deck_learning_events_trashed_deck_30d`;
   - `decks_trash_30d`, contada de `deleted_at`.

   As cópias sem cascata saem antes, e o deck sai por último, com a cascata. O recibo leva
   só contagens. A limpeza segue desligada até a ativação supervisionada. O inventário de
   retenção (JSON e Markdown) declara as purgas por tabela, e o teste confere o código e o
   inventário nos dois sentidos.
7. **Contratos e travas.**
   - `server/doc/API_CONTRACTS_AND_DATA_MAP.md`: linhas de `DELETE`, `GET /decks/trash`,
     `POST /decks/:id/restore`, histórico e desfazer, e a seção nova.
   - Capabilities: as três rotas ficam em `decks_private`.
   - A classificação de e-mail verificado das rotas de `/decks` inclui as novas.
   - As travas de última migration vão para `072`: readiness, deploy, contratos de ops e o
     gerador do project logic.
   - O teste live de CRUD que se chamava "cascade delete" foi renomeado.

## Evidência

| Teste | Onde | Resultado |
| --- | --- | --- |
| `server/test/deck_trash_db_live_test.dart` | PostgreSQL descartável | 10/10 |
| `server/test/retention_cleanup_db_live_test.dart` | PostgreSQL descartável, com as regras da lixeira na semeadura | 6/6 |
| `server/test/shareable_report_deleted_deck_db_live_test.dart` | PostgreSQL descartável: estoque antigo, deck marcado por fora, apagar e restaurar | 1/1 |
| Generate, deck e privacidade no banco (`ai_generate_request`, ledger, edição incremental, artefato, estrita, import em duas fases, `privacy_*`) | PostgreSQL descartável | 101/101 |
| suíte de foco (lixeira, retenção, revisão, capabilities, e-mail verificado, contratos de API, privacidade, readiness, migrations, relatórios, Generate, Optimize), com o manifesto regenerado, dentro da trava, antes do commit | unitário | 237/237 (35 arquivos) |

Os 10 casos do teste de banco da lixeira:

- apagar manda para a lixeira: nada sai do banco, o deck deixa a galeria e o relatório morre;
- deck na lixeira some das rotas de `/decks/:id`, e só o restaurar passa;
- a mudança de conteúdo recusa deck na lixeira mesmo sem o guarda;
- deck na lixeira some das superfícies fora de `/decks/:id`;
- repetir a materialização do Generate não devolve deck da lixeira como vivo;
- a lixeira lista só os decks apagados do dono, com a data da purga;
- restaurar devolve o deck íntegro (mesmas linhas de carta) e privado, sem republicar o
  relatório;
- lixeira e restaurar ficam no histórico, sem desfazer;
- deck na lixeira entra na exportação e fica fora do aprendizado (extração de features e
  pull do Hermes);
- a limpeza por prazo apaga de vez o deck com mais de 30 dias na lixeira, com cartas,
  ledger, relatório e evento de aprendizado. O de 29 dias fica intacto, e o deck vivo
  antigo e o relatório dele também.

## Mutações

34 mutações, 0 sobreviventes.

- **Código.** São 32 mutações e 35 execuções (`~/.manaloom/coordenacao/deck/mutations.py dck006`).
  Cada mutação foi aplicada no worktree, os testes rodaram, e o arquivo foi restaurado e
  conferido por hash. A T8 troca a rota da lista inteira por uma versão sem nenhum filtro,
  porque as quatro variantes do SQL são iguais.
- **Schema.** São 2 mutações (`draft/schema_mutants_006.py`). O banco descartável foi recriado de
  uma cópia do `server/` com a 072 mutada, e o teste de banco rodou com o código sem
  mutação.

| Mutação | O que muda | Resultado |
| --- | --- | --- |
| T1 | `DELETE` apaga de vez | falhou (esperado) |
| T2 | `DELETE` deixa o deck na galeria | falhou (esperado) |
| T3 | `DELETE` não despublica o relatório | falhou (esperado) |
| T4 | `DELETE` sem evento no ledger | falhou (esperado) |
| T5 | guarda deixa passar deck na lixeira | falhou (esperado) |
| T6 | guarda barra o restaurar | falhou (esperado) |
| T7 | trava da mudança sem o filtro da lixeira | falhou (esperado) |
| T8 | lista de decks mostra a lixeira | falhou (esperado) |
| T9 | prévia do import enxerga a lixeira | falhou (esperado) |
| T10 | configurações do Optimize enxergam a lixeira | falhou (esperado) |
| T11 | contexto do Optimize com telemetria enxerga a lixeira | falhou (esperado) |
| T12 | contexto do Optimize sem telemetria enxerga a lixeira | falhou (esperado) |
| T13 | acesso do Optimize enxerga a lixeira | falhou (esperado) |
| T14 | arquétipos enxergam a lixeira | falhou (esperado) |
| T15 | rebuild enxerga a lixeira | falhou (esperado) |
| T16 | rota legada enxerga a lixeira | falhou (esperado) |
| T17 | relatório nasce de deck na lixeira | falhou (esperado) |
| T18 | repetir a materialização devolve deck da lixeira | falhou (esperado) |
| T19 | lixeira mostra deck de outra pessoa | falhou (esperado) |
| T20 | lixeira mostra deck vivo | falhou (esperado) |
| T21 | restaurar aceita deck vivo | falhou (esperado) |
| T22 | restaurar republica o deck | falhou (esperado) |
| T23 | restaurar ignora o `If-Match` | falhou (esperado) |
| T24 | desfazer aceita a lixeira | falhou (esperado) |
| T25 | histórico oferece desfazer a lixeira | falhou (esperado) |
| T26 | purga conta da criação do deck | falhou (esperado) |
| T27 | purga não apaga os relatórios | falhou (esperado) |
| T28 | purga não apaga os eventos de aprendizado | falhou (esperado) |
| T29 | purga apaga deck com menos de 30 dias na lixeira | falhou (esperado) |
| T30 | aprendizado lê deck da lixeira | falhou (esperado) |
| T31 | pull do Hermes leva evento de deck fora de uso | falhou (esperado) |
| T32 | lixeira vira mudança de conteúdo (sai do `CHECK` do código) | falhou (esperado) |
| S1 | `CHECK` da 072 sem `deck_delete` | falhou (esperado) |
| S2 | `CHECK` da 072 sem `deck_restore` | falhou (esperado) |

## O que fica de fora

- **Raia do app:** a tela da lixeira, o restaurar e o texto de confirmação do apagar, que
  diz que o deck vai para a lixeira por 30 dias.
- **Produção:** aplicar a `072`, ativar a limpeza por prazo e fazer o ensaio de restauração
  de backup pedem a palavra do dono.
- **Decisões pendentes do dono**, em `~/.manaloom/coordenacao/receipts/decisoes-pendentes.md`:
  - a purga levar junto os relatórios e os eventos de aprendizado do deck;
  - apagar de vez antes dos 30 dias;
  - o estoque antigo de relatórios órfãos na produção;
  - a mudança de comportamento do pull do Hermes.
- **Lacuna que já existia:** a cópia no SQLite do Hermes de eventos sincronizados antes de o
  deck ir para a lixeira (`BT-AI-030`).
