# Receipt — DCK-P0-04: pedido durável do Generate e materialização no servidor — 2026-09-28

- Tarefa: `DCK-P0-04`, Frente B (deck e trocas) da coordenação do MVP, branch
  `deck/rodada2-2026-09-24`, sobre `52150809e` (DCK-P1-04).
- Decisões do dono aplicadas: D-29 (prompt bruto retido por 30 dias e fora de
  `decks.description`) e D-25 (depende do inventário de retenção do `BT-PRIV-003`).
- Aceite do backlog: "Resultado A nunca salva como controles B; cliente não injeta lista;
  cross-device reidrata a entrada original."
- Nada tocou a produção: sem SSH, sem banco live, sem deploy. A migration `069` está só no
  código. Os testes de banco rodaram num PostgreSQL 17 descartável da frente (`LC_ALL=C`,
  só em `127.0.0.1`, sem socket Unix), criado do zero por `server/database_setup.sql` e
  `server/bin/migrate.dart` (`migrations=63 latest=069`), parado e apagado no fim.
- Só servidor. A parte do app (ler o pedido, mostrar o resultado, materializar com o artefato
  e parar de mandar lista e prompt ao `POST /decks`) fica pendente na raia do app, que está
  bloqueada até a sessão do gate commitar as recapturas.

## O que mudou

1. **Migration `069` (`create_ai_generate_requests`).**
   - Tabela `ai_generate_requests`: dono, `request_key` (única por dono), impressão do
     pedido, job, formato, controles, prompt, `prompt_purged_at`, estado, resultado com o
     hash canônico, `can_materialize` e o deck materializado (`ON DELETE SET NULL`).
     `CHECK`s: prompt apagado leva a impressão junto; resultado e hash andam juntos; só
     materializa com resultado.
   - `deck_change_events.description_redacted_at` e o gatilho do ledger aceitando uma única
     mudança: a redação governada da descrição, na transação marcada pela limpeza
     (`manaloom.deck_ledger_redaction = d29_prompt_retention`), com todo o resto igual.
     Qualquer outro `UPDATE` continua recusado.
   - Rollback `emptyOnly`: o down só roda sem pedido gravado e sem descrição redigida.
2. **Pedido durável.** O `POST /ai/generate` assíncrono grava o pedido logo depois de criar
   o job e devolve `generate_request_id` e `request_url`. A mesma `request_key` com outro
   pedido dá 409 `ai_job_idempotency_conflict`. Quando o job termina, o pedido guarda o
   resultado e se ele pode virar deck (a mesma regra do salvar: sem mock, sem carta
   inválida, estrutura válida).
3. **Reidratação em outro aparelho.** `GET /ai/generate/requests/latest` (ou pelo id) devolve
   a entrada original enquanto o prompt existe e, para resultado que pode virar deck, o
   `DeckReviewArtifact v1` do tipo `generate_materialize` (dono, pedido, hash do resultado,
   hash dos controles, 24 h). Pedido de outra pessoa é 404 `generate_request_not_found`.
4. **Materialização no servidor.** `POST /ai/generate/requests/:id/materialize` recebe só o
   artefato e, se quiser, o nome. O deck nasce do resultado e dos controles gravados:
   controles mudados dão 409 `generate_review_invalid` com `constraints_mismatch`; sem
   artefato, 428; repetir devolve o mesmo deck (`replayed: true`); o deck nasce privado,
   sem descrição. O `POST /decks` recusa corpo com `generate_request_id` (400
   `generate_materialize_required`): o cliente não injeta a lista. Criar o deck exige
   e-mail verificado, como o `POST /decks` (BT-AUTH-010).
5. **Retenção (D-29).** A limpeza por prazo da D-70 (`retention_cleanup_apply_v1`, desligada
   até a ativação supervisionada) ganhou duas regras de redação:
   `ai_generate_requests_prompt_30d` (prompt e impressão; o pedido fica) e
   `deck_change_events_description_30d` (texto de descrição do ledger). Desfazer uma mudança
   redigida dá 409 `deck_undo_redacted`, e o histórico marca `description_redacted` e
   `can_undo: false`.
6. **Privacidade e operação.** Inventário de retenção (JSON e Markdown), seção
   `data.ai_activity.generate_requests` da exportação, exclusão de conta, capability
   `ai_generate_rebuild` cobrindo `/ai/generate/requests/`, leitura e materialização sem
   cota de IA, e as travas de última migration (readiness, deploy, contratos de ops,
   gerador do project logic) em `069`.

## Evidência

| Teste | Onde | Resultado |
| --- | --- | --- |
| `server/test/ai_generate_request_db_live_test.dart` | PostgreSQL descartável | 8/8 |
| `server/test/retention_cleanup_db_live_test.dart` | PostgreSQL descartável, com as regras novas | 6/6 |
| privacidade no banco (`privacy_account_deletion`, `privacy_data_inventory`, `privacy_deletion_outbox`, `privacy_export`, `privacy_trade_items`) | PostgreSQL descartável | 43/43 |
| deck no banco (ledger, edição incremental, artefato, validação estrita, import em duas fases, relatório de deck apagado) | PostgreSQL descartável | 51/51 |
| suíte de foco (30 arquivos: Generate, middleware de IA, capabilities, readiness, contratos de API, privacidade, retenção, migrations, project logic, contenção e CRUD de deck), com o manifesto regenerado | unitário | 190/190 |

Os 8 casos do teste de banco do Generate:

- o pedido guarda a entrada original e é idempotente pela chave;
- outro aparelho reidrata o último pedido; outra pessoa não o vê;
- materializar cria o deck do resultado, privado e sem o prompt, uma vez;
- resultado A nunca salva como controles B;
- sem artefato, artefato adulterado ou de outro pedido: nada é criado;
- resultado sem condição de virar deck ou com carta fora do catálogo;
- o `POST /decks` não aceita lista de um pedido do Generate;
- D-29: a limpeza apaga o prompt e o texto de descrição do ledger; o gatilho recusa cinco
  redações com um único defeito cada (sem a marca da limpeza, outra coluna, outro texto,
  sem `description_redacted_at`, outra chave dos metadados); o desfazer não inventa a
  descrição.

## Mutações

19 mutações, 0 sobreviventes. Cada mutação de código foi aplicada no worktree, os testes
rodaram e o arquivo foi restaurado e conferido por hash
(`~/.manaloom/coordenacao/deck/mutations.py dck004`). As de schema foram aplicadas numa cópia
do `server/`, com o banco descartável recriado dela e o teste de banco rodando com o código
sem mutação (`draft/schema_mutants_004.py`).

| Mutação | O que muda | Resultado |
| --- | --- | --- |
| G1 | materializar sem conferir os controles | falhou (esperado) |
| G2 | materializar aceita artefato inválido | falhou (esperado) |
| G3 | artefato de outro pedido vale | falhou (esperado) |
| G4 | repetir materializa de novo | falhou (esperado) |
| G5 | deck com descrição preenchida | falhou (esperado) |
| G6 | deck materializado nasce público | falhou (esperado) |
| G7 | mesma chave com outro pedido passa | falhou (esperado) |
| G8 | resultado bloqueado vira deck | falhou (esperado) |
| G9 | pedido de outra pessoa aparece | falhou (esperado) |
| G10 | `POST /decks` aceita lista do Generate | falhou (esperado) |
| G11 | prompt nunca é apagado | falhou (esperado) |
| G12 | redação do ledger sem a marca da sessão | falhou (esperado) |
| G13 | desfazer restaura descrição redigida | falhou (esperado) |
| G14 | resultado sempre materializável | falhou (esperado) |
| S1 | gatilho aceita a redação sem a marca da limpeza | falhou (esperado) |
| S2 | gatilho aceita redação que muda a operação | falhou (esperado) |
| S3 | gatilho aceita trocar o texto por outro | falhou (esperado) |
| S4 | gatilho aceita redação sem `description_redacted_at` | falhou (esperado) |
| S5 | gatilho aceita redação que mexe em outra chave dos metadados | falhou (esperado) |

## O que fica de fora

- Raia do app: ler o pedido, mostrar o resultado, materializar com o artefato e parar de
  mandar a lista e o prompt ao `POST /decks` (`deck_generate_screen.dart`).
- O prompt já gravado em descrições de decks existentes fica como está (pendente de decisão
  do dono).
- Aplicar a `069` e ativar a limpeza por prazo na produção pedem a palavra do dono; a IA
  segue desligada na produção.
