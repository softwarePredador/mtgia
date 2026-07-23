# ManaLoom - evidência da Sprint 7 (Social e segurança)

Data: 2026-07-23
Branch: `codex/free-beta-release-candidate-2026-07-17`
HEAD base observado: `776b9e25d514aabc3ee6351549c1fd6dd0088884`
Owner: `/root`

## Decisão

**Sprint 7: `PASS`.**

Community, mensagens e trades permanecem no escopo do produto. O fechamento
adiciona denúncia transversal, bloqueio bilateral, moderação auditável,
privacidade por allowlist, mensagens idempotentes com rascunho persistente e
leituras que nunca reapresentam conteúdo moderado.

Nenhuma migration ou versão foi promovida ao servidor público nesta etapa. Os
contratos novos foram executados em PostgreSQL descartável; o aparelho físico
usou somente endpoints já disponíveis para provar o coordinator de realtime.

## Resultado por task

| Task | Estado | Evidência principal |
|---|---|---|
| S7-01 | PASS | denúncia de deck, comentário, perfil e mensagens; motivo/confirmação; duplicata 409 e rate limit PostgreSQL 429 |
| S7-02 | PASS | bloqueio bilateral corta perfil, feed, follow, mensagens, notificações e novas trades; desbloqueio explícito/auditado |
| S7-03 | PASS | fila operacional protegida, SLA, ação transacional, evidência, auditoria e apelação |
| S7-04 | PASS | allowlists de perfil, Binder, localização, mensagens, trades e notas; negativos entre dois usuários |
| S7-05 | PASS | draft persistente, request id estável, retry idempotente, unread/realtime/deep link e cleanup físico |
| S7-06 | PASS | máquina de estados e disponibilidade concorrente; aviso P2P na criação e detalhe |
| S7-07 | PASS | feed/follow/comentários com paginação, bloqueio, exclusão e estados de UI |
| S7-08 | PASS | conjunto social permanece acessível porque S7-01 a S7-07 fecharam |

## Contrato implementado

### Banco e backend

A migration `051_close_social_safety_contract`:

- adiciona visibilidade fechada ao usuário;
- cria `user_blocks`, ações/auditoria de moderação e apelações;
- amplia `content_reports` com estado, SLA e evidência operacional;
- adiciona `client_request_id` e `moderation_status` às mensagens diretas e de
  trade;
- instala unicidade para retry por remetente e request id.

`SocialSafetyService` centraliza validação do alvo, limite distribuído,
duplicata, bloqueio/desbloqueio, fila, ação e apelação. Rotas de feed, perfil,
Binder, follow, notificações, conversas e trades aplicam o bloqueio nos dois
sentidos. Comentários e mensagens removidos são filtrados na lista, no total,
no unread e no detalhe embutido.

O feed `/community/decks/following` tem um único serviço canônico. O dispatch
mínimo mantido na rota dinâmica existe apenas porque a precedência gerada pelo
Dart Frog pode interpretar `following` como id; ambos os caminhos chamam a
mesma implementação.

### App

- um diálogo único coleta motivo e detalhes de denúncia;
- deck, comentário, perfil, mensagem direta e mensagem de trade expõem a ação;
- perfil público e chat permitem bloqueio com confirmação;
- o perfil próprio lista bloqueados e exige desbloqueio explícito;
- privacidade é editável com controles de vocabulário fechado;
- rascunhos de chat direto e trade são persistidos por canal;
- o mesmo UUID é reutilizado somente enquanto o conteúdo do retry não muda;
- sucesso 200 idempotente e 201 novo são deduplicados localmente;
- exclusão do comentário próprio atualiza a lista sem esconder falha;
- o coordinator envia foreground para notificações e exatamente um domínio:
  mensagens ou trades.

## Provas determinísticas

Flutter aprovado: `3.44.6`; Dart irmão: `3.12.2`.

```text
flutter test \
  test/features/community test/features/messages test/features/social \
  test/features/trades test/features/auth/models/user_test.dart \
  test/features/profile/profile_screen_test.dart \
  test/core/services/message_draft_store_test.dart \
  test/core/services/realtime_notification_coordinator_test.dart

87/87 PASS
```

Os testes cobrem provider, telas, denúncia, privacidade, bloqueados, drafts,
idempotência e dispatch de realtime. A análise focada do app e do servidor
terminou sem issues.

```text
dart test server/test/data_model_migration_test.dart
29/29 PASS

dart analyze <serviço, rotas e testes S7>
No issues found
```

## PostgreSQL/API descartável

O harness aplicou todas as 51 migrations em banco loopback efêmero e executou,
no mesmo servidor isolado:

```text
social_safety_live_test.dart
social_trading_live_test.dart
profile_community_live_test.dart
collection_availability_live_test.dart

5/5 PASS
migration_count=51
summary_sha256=f34f8e4b45c6d3c48d4d826e778f879bb1d1de88504b586760dfdb02be82601a
```

Esse run provou dois usuários, IDOR/ownership, bloqueio bilateral, transações
de trade e disponibilidade concorrente. A extensão focada de segurança passou
separadamente com:

```text
social_safety_live_test.dart
PASS
summary_sha256=94ea6d1239a554a1358c647a7b414936a8fd37f865f32e1dc20848a35c39af6f
```

Ela inclui remoção de mensagem de trade tanto da lista quanto do detalhe e
limite distribuído: as dez primeiras denúncias do usuário são aceitas e a
décima primeira retorna 429 com `Retry-After`.

O harness registrou cleanup, encerrou API/cluster e removeu o PostgreSQL
temporário em ambas as execuções.

## Gate completo do checkout

Depois das provas focadas, o checkout inteiro foi revalidado com o SDK pinado:

```text
./scripts/manaloom_local_ci.sh full

exit_code=0
project_logic=PASS
backend=1713/1713 PASS
flutter=1130 PASS + 1 SKIP Web-only declarado
public_web=lint/build/smoke PASS; npm_audit=0 vulnerabilities
ui_audit=48/48 PASS
custom_lint=PASS
patrol_smoke=9/9 PASS
dependency_audit=PASS
schema=73 tables, 6 views, 76 foreign keys, 51 migrations
```

O PostgreSQL do gate foi criado somente em loopback, comparado com o manifesto
e destruído ao final. Nenhuma conexão externa ou mutação de produto ocorreu.

## Realtime no SM-A135M

O teste integrado atual foi compilado e instalado no Android físico
`R58T300SREH` com Flutter `3.44.6`:

```text
flutter test integration_test/realtime_notifications_runtime_test.dart \
  -d R58T300SREH --no-pub --reporter expanded

1/1 PASS em 32 s
```

No backend público atual, o teste criou dois usuários QA, atualizou badge/lista
por direct message, abriu o deep link da conversa, atualizou trade aceita e
enviada e confirmou a timeline. O teardown passou a excluir ambas as contas
pela API de privacidade; uma busca posterior pelo marcador
`qa_rt_19f8f48afc8` retornou `remaining=0`.

A entrega FCM real em foreground, background e tap já possui prova física em
`app/doc/runtime_flow_handoffs/push_delivery_android_sm_a135m_2026-05-11.md`.
S8-06 ainda exige repetir esse transporte no artefato final da mesma SHA; a
Sprint 7 prova aqui a semântica de mensagens/realtime, não assina o release.

## Incidentes rejeitados

- uma primeira tentativa usou por engano o Flutter global `3.41.6`, falhou na
  verificação Gradle antes de compilar e alterou duas versões transitivas do
  lockfile; o lock foi restaurado e essa tentativa não conta como evidência;
- o primeiro harness físico concluído revelou contas QA sem cleanup. O resíduo
  foi removido pela API, o teardown foi corrigido e o teste foi repetido;
- nenhuma credencial, token, conteúdo privado ou operações key foi registrada.

## Limites

- migration 051 continua somente versionada/testada até uma etapa de promoção
  com backup, precheck e autorização;
- não houve deploy, promoção de regra, escrita Hermes ou apply no PostgreSQL
  live;
- TalkBack e VoiceOver manuais continuam na exceção física S3-04 e não foram
  usados para afirmar este `PASS`.
