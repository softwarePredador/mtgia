# Receipt — BT-DB-003: ensaio de upgrade na estrutura do dump da produção — 2026-09-28

- **Tarefa:** o item 2 da seção `BT-DB-003` em `decisoes-pendentes.md`. O objetivo era antecipar
  se as migrations 058 a 074 aplicam na forma real da produção. O modelo sintético do teste de
  banco não cobre os gatilhos, as funções e os CHECK que a produção tem.
- **Autorização:** coordenação, em 2026-09-28, com quatro condições:
  - o dump local mais novo só é lido;
  - só a estrutura e o ledger de migrations são restaurados;
  - nada do dump vai para arquivo, receipt ou log;
  - o cluster é apagado no fim.
- **Executado por:** Frente C (banco e operação). Nada tocou a produção: sem SSH, sem banco
  remoto, sem deploy.
- **Este receipt registra só nomes de objetos, contagens e resultados.** Nenhuma linha de dado,
  definição de objeto ou trecho do dump.

## Como rodou

| Item | Valor |
| --- | --- |
| Dump | `backups/manaloom-postgres/manaloom-postgres-20260923T005128Z.dump`, do checkout principal, só leitura (`pg_restore`) |
| Modo | `estrutura`: `pg_restore --schema-only` mais só as linhas de `public.schema_migrations` |
| PostgreSQL | 17.9 local e descartável: só `127.0.0.1`, sem socket, dentro de `sandbox-exec` sem rede externa |
| Código | prévia do código integrado, num clone descartável sem tocar em `wt/integ`: `integracao/2026-09-23` (`cd3bcc8ad`) mais as pontas atuais das três frentes, servidor `16b4a7d52`, deck `9c45f2ae1` e banco `1266aee35` |
| Migrations da prévia | 71: da 001 à 074, sem a 066, a 070 e a 071 |
| Invólucro | chama `rehearse()` de `scripts/manaloom_migration_rehearsal.py` sem gravar o `rehearsal.json` nem o `.md`, e grava só nomes, contagens e resultados. Ele fica fora do repositório, em `~/.manaloom/coordenacao/banco/ensaio_estrutura_producao.py` |

A prévia foi montada por merges num clone `--shared` e esparso. As listas de migrations viraram
a união em ordem numérica, e o bootstrap ficou com os dois lados.

Antes do ensaio na produção, a prévia passou por três conferências:
- `dart analyze` do runner, limpo;
- a regra dos gatilhos, o preflight e o SQL literal: 31 verdes;
- o teste de banco do ensaio nos fixtures: 5 de 5.

## Resultado

| Etapa | Resultado |
| --- | --- |
| Restauração | 1.132 tabelas; só `public.schema_migrations` com linhas; 0 linha de dado |
| Preflight | perfil `canonico`; ledger na 057; 14 pendentes (058 a 065, 067 a 069, 072 a 074) |
| Upgrade | `rc 0` até a 074; o ledger ficou igual ao do banco novo (71) |
| Reaplicação | sem mudança |
| Rollback pelo restore do mesmo dump | idêntico ao de antes (0 diferença de catálogo) |
| Reforward | igual ao upgrade |
| Payload | 98 tabelas, 0 linha, nenhuma mudança |
| Cluster | apagado |

**A cadeia inteira aplica na forma real da produção.** Nenhuma migration falhou, e nenhuma
mexeu fora do que declara.

### Pós-checagem contra o banco novo

- **18.789 diferenças, das quais 18.779 estão na lista fechada.** Por categoria:
  - 1 schema e 1.053 tabelas, a maior parte do schema de auditoria (D-49);
  - 17.564 colunas;
  - 27 restrições, 6 chaves estrangeiras, 118 índices, 2 views e 8 sequências.
- **10 ficaram fora da lista.** Todas estão em categorias que a auditoria da `BT-DB-001` não leu:

| Categoria | Tipo | Objeto | Leitura |
| --- | --- | --- | --- |
| restrições | só no banco novo | `account_deletion_receipts.account_deletion_receipts_deletion_mode_check` | a mesma regra com outro nome: na produção é `chk_account_deletion_mode` |
| restrições | só na produção | `account_deletion_receipts.chk_account_deletion_mode` | idem |
| restrições | só no banco novo | `user_binder_items.user_binder_items_list_type_check` | a mesma coluna com outro nome: na produção é `chk_list_type` |
| restrições | só na produção | `user_binder_items.chk_list_type` | idem |
| restrições | só no banco novo | `post_game_notes.post_game_notes_revision_check` | repete a `chk_post_game_notes_revision` (038), que os dois têm |
| restrições | só no banco novo | `ml_prompt_feedback.chk_ml_prompt_feedback_effectiveness_score` | a produção não tem |
| restrições | só no banco novo | `notifications.notifications_type_check` | a produção não tem |
| restrições | só no banco novo | `user_binder_items.user_binder_items_currency_check` | a produção não tem |
| gatilhos | só no banco novo | `ml_prompt_feedback`: gatilho de conta ativa de `user_id` | a produção não tem a chave `ml_prompt_feedback.user_id` (D-50); a trava vem com ela |
| tipos | só na produção | `poststatus` (enum) | acompanha a tabela `posts`, só da produção e sem uso no código |

- **Entrada da lista fechada sem ocorrência: 1,** `user_binder_items_list_type_check` como
  divergente. A diferença real era o nome.
- **Para onde vão:** a `BT-DB-005` trata as dez (receipt próprio): adota os nomes da produção, e o
  que depende do dono vai para `decisoes-pendentes.md`.

## O que isto não prova

- Os passos que dependem de dado:
  - o retrato de aceites da 062;
  - os NOT NULL da D-67;
  - as chaves da D-50.

  O modo `estrutura` não tem linha. O ensaio com o dump novo, no modo `completo`, é do lote de
  deploy, com a palavra do dono.
- A forma da produção depois de 2026-09-23. O dump é de antes da 058.
