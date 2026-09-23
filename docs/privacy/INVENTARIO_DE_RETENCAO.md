# Inventário de retenção de dados (BT-PRIV-003)

Lifecycle: `SUPPORTING_REFERENCE · NO_PRIORITY_AUTHORITY`. Levantado em 2026-09-23 sobre
`47dc3b698`. A fonte legível por máquina é
[`data_retention_inventory.json`](data_retention_inventory.json); este texto só resume.

## Como é conferido

- `server/test/privacy_data_inventory_test.dart` roda na suíte do servidor e compara o JSON com
  `project_logic_manifest.json#/database`, que o gerador de project logic extrai do baseline, das
  58 migrations e do SQL do backend. Tabela ou coluna nova sem classificação faz o teste falhar.
  Ele também confere os prazos decididos pelo dono e se o modo de exclusão declarado bate com
  `server/lib/user_data_privacy_service.dart`.
- `server/test/privacy_data_inventory_db_live_test.dart` confere o mesmo JSON contra o
  `information_schema` e as FKs de um PostgreSQL descartável migrado
  (`RUN_PRIVACY_DB_TESTS=1` e `DB_*`).
- A exportação (`BT-PRIV-001`) usa este inventário como allowlist:
  `server/lib/privacy/privacy_export_allowlist.dart` espelha as colunas marcadas para sair, e
  `server/test/privacy_export_allowlist_test.dart` falha se os dois divergirem.

## O que está no inventário

- **79 tabelas** do schema versionado. **44 têm dado pessoal**: 42 de titulares de conta, 1 da
  equipe de moderação e 1 com nome público de jogador de torneio externo. As outras 35 são
  catálogo, referência, controle ou operação.
- Para cada tabela: finalidade, dono no código, prazo, quem apaga, se entra na exportação e como
  sai na exclusão, e a exceção legal quando há.
- Para as **39 tabelas exportadas**, a classificação de cada uma das 517 colunas: `include`,
  `person_ref` ou `deck_ref` (pseudônimo quando é de outra pessoa), `entity_ref`, ou `omit_*`
  (segredo, hash, estado interno, conteúdo de terceiro, UUID do catálogo).
- **6 views**, **20 tabelas e 3 colunas que só existem na produção** (receipt de 2026-09-22; uma
  das colunas, `ml_prompt_feedback.user_rating`, é dado pessoal e fica fora da exportação) e **13 artefatos
  fora do banco**: caches em memória, sidecars, logs, Sentry, provedores externos, backups,
  aparelho e o arquivo da exportação.

## Prazos já decididos

| Decisão | Regra | Onde | Situação em `47dc3b698` |
| --- | --- | --- | --- |
| D-23 | caches com TTL de até 24 h | `ai_optimize_cache`, EndpointCache | cache do Optimize vence em 6 h; o EndpointCache não tem teto e guarda entradas vencidas |
| D-29 | prompt bruto do Generate por 30 dias, fora de `decks.description` | `decks.description`, `ai_generate_jobs.result` | o app grava o prompt na descrição do deck; armazenamento com prazo é o `DCK-P0-04` |
| D-30 | purga da lixeira em 30 dias | `decks.deleted_at` | não existe; é o `DCK-P0-06` |
| D-32 | jobs de IA por 24 h | `ai_generate_jobs`, `ai_optimize_jobs` | o código apaga em 30 min; é o `BT-AI-032` |
| D-23 | backups não são reescritos; rotação entra na política | backups | prazo de rotação ainda não decidido |

## Resumo por classe

| Classe | Tabelas | Prazo | Quem apaga | Exportação | Exclusão |
| --- | --- | --- | --- | --- | --- |
| Conta | `users`, `user_plans`, `ai_user_preferences` | enquanto a conta existir | exclusão de conta | sim | `users` pseudonimizada, o resto apagado |
| Conteúdo | `decks`, `deck_cards`, `user_binder_items`, `post_game_notes`, `shared_deck_reports`, `deck_comments`, `deck_matchups`, `deck_weakness_reports` | enquanto a conta existir | exclusão de conta e cascata por deck | sim | apagado |
| Atividade | `activation_funnel_events`, `deck_optimization_events`, `deck_learning_events`, `ml_prompt_feedback`, `ai_optimize_fallback_telemetry` | sem prazo, exceto telemetria (180 dias) | exclusão de conta; job de limpeza | sim | apagado |
| IA em execução | `ai_logs`, `ai_generate_jobs`, `ai_optimize_jobs`, `ai_optimize_cache` | 180 dias; 24 h decidido para jobs; 6 h no cache | job de limpeza e o próprio serviço | sim, sem hashes | apagado |
| Battle e replays | `battle_simulations`, `battle_simulation_attempts`, `battle_jobs`, `battle_job_live_records`, `interactive_battle_sessions`, `interactive_battle_records`, `battle_replay_annotations` | sem prazo | exclusão de conta | sim, sem hashes nem payload interno | apagado; as simulações de outras pessoas contra o deck do titular ficam com elas, anonimizadas (D-23) |
| Social | `user_follows`, `user_blocks`, `user_block_events`, `conversations`, `direct_messages`, `notifications` | enquanto as contas existirem | exclusão de conta | sim, com pseudônimo para a outra pessoa | seguir, bloqueios e notificações apagados; mensagens do titular substituídas; trilha de bloqueios sem a pessoa |
| Trocas | `trade_offers`, `trade_items`, `trade_messages`, `trade_status_history` | mantidas depois da exclusão | ninguém | sim | anonimizadas, porque são registro entre duas partes |
| Moderação | `content_reports`, `content_report_appeals`, `moderation_actions` | mantidas depois da exclusão | ninguém | denúncias e recursos do titular | denúncia, recurso e ação do moderador anonimizados |
| Segurança | `password_reset_tokens`, `email_verification_tokens`, `rate_limit_events` | 20 min, 24 h e 24 h de validade | job de limpeza só para `rate_limit_events` | não | apagados |
| Controle de privacidade | `account_deletion_receipts`, `privacy_deleted_deck_tombstones`, `privacy_keyring` | sem prazo | ninguém | não | mantidos, sem identificar a pessoa |

## Lacunas que o inventário expõe

1. **Nenhum prazo automático roda em produção hoje.** O job `manaloom_ai_runtime_cleanup`
   (`ai_logs`, telemetria, `rate_limit_events`, jobs de IA) exige a capability
   `ai_analyze_optimize_advisory`, que está OFF (`server/bin/manaloom_ops_daemon.py:712`).
2. **Exportação** (corrigida no `BT-PRIV-001`, 2026-09-23): em `47dc3b698`, 25 relações saíam
   pela linha inteira (`to_jsonb`), com `request_fingerprint`, `request_key`, `cache_key` e
   hashes de deck, e IDs de outras pessoas saíam crus. Agora cada seção sai só com as colunas
   deste inventário, IDs de terceiros viram pseudônimos válidos só no arquivo, e as cinco
   tabelas que ficavam de fora entraram.
3. **Exclusão** (parte corrigida no `BT-PRIV-002`, 2026-09-23): bloqueios e tokens do titular
   agora saem; eventos de bloqueio, recursos, ações de moderação e a evidência da denúncia ficam sem a
   pessoa; as simulações de outras pessoas contra o deck público do titular ficam com elas,
   anonimizadas (D-23); relação ausente para a exclusão. Segue aberto: o outbox da D-23 exige
   tabela nova (proposta de DDL com a coordenação), e jobs e sessões de Jogar contra IA de outras
   pessoas guardam o hash e a lista do deck de quem saiu (`BT-BAT-002`).
4. **Fora do banco**: o EndpointCache passou a ter teto de 24 h e a limpar as entradas vencidas,
   e o Sentry do servidor não recebe mais o ID do usuário (`BT-PRIV-002`). Seguem abertos: o
   Sentry do app ainda identifica o usuário (raia do app); o SQLite do Hermes guarda decklists de
   contas excluídas (contido por `learning_writes` OFF, `BT-AI-030`); logs têm `user_id` cru
   (`BT-SEC-AI-002`); a exclusão não limpa o aparelho.
5. **Sem prazo definido**: eventos de ativação, replays e simulações, notificações, feedback de
   IA, relatórios compartilhados vencidos, notas pós-jogo apagadas, sessões expiradas e tokens
   usados ou vencidos.

## Pendente de decisão do dono

- Tabela nova para o outbox da exclusão (D-23): migration nova é decisão; a proposta de DDL foi
  relatada à coordenação e não está aplicada.
- Prazo de rotação dos backups (D-23 manda registrá-lo na política).
- Prazo de retenção de analytics (`activation_funnel_events`), replays e simulações,
  notificações e feedback de IA.
- Prazo de retenção de trocas e registros de moderação mantidos depois da exclusão, e base legal
  do nome público de jogador em `external_commander_meta_candidates` (advogado, `BT-LEGAL-001`).
- Retenção declarada pelos provedores: Sentry, OpenAI e Resend. Conferir no painel ou contrato
  de cada um e registrar no JSON.
