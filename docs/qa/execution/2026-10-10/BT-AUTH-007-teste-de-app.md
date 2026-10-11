# Receipt — BT-AUTH-007: o teste de app da troca de senha — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que este receipt prova:** o teste de app que o aceite pedia ("Depois de trocar a senha, e-mail
  verificado, nome e avatar continuam iguais no app; teste de servidor e de app").
- **O que não muda:** o código do app. O teste fixa o comportamento que o `master` `1f525a1c1` já tem.
- **O que falta para o PASS:** o `full` verde no SHA candidato. Nada tocou a produção.

## O comportamento

O servidor devolve o usuário completo depois de `POST /auth/change-password` e de
`POST /auth/revoke-sessions`, no formato de `GET /users/me`.
- **Commit do servidor:** `5a7a3d9a8` (fix(BT-AUTH-007): return the full user after a password change).
- **No ar:** desde 2026-09-23 às 08:08 UTC (`166aaed57`).
- **Teste do servidor:** `server/test/account_security_full_user_test.dart`.

O app troca o usuário guardado pelo da resposta, na memória e no aparelho
(`_rotateAuthenticatedSession` em `app/lib/features/auth/providers/auth_provider.dart`). Faltava o teste do
lado do app.

## O teste

`app/test/features/auth/providers/auth_provider_password_change_keeps_profile_test.dart` tem dois casos.
1. **Fluxo:** login com o perfil completo e depois a troca de senha.
2. **Fluxo:** login com o perfil completo e depois encerrar as outras sessões.

Nos dois casos:
- as respostas têm as mesmas chaves que o teste do servidor fixa;
- a resposta da troca traz um usuário diferente do login: o mesmo `id`, com nome, avatar, cidade e
  `updated_at` novos, como se o perfil tivesse mudado em outro aparelho. Assim o teste prova que o app
  adota o usuário que o servidor manda, e não só que ele não perde campos (revisão de 2026-10-10);
- o teste confere, no `AuthProvider`, o token novo, o e-mail verificado, o nome, o avatar e a cidade da
  resposta e mais dois campos de perfil;
- confere também, no `user_data` guardado no `SharedPreferences`, o e-mail verificado, o nome e o avatar
  da resposta.
  É o que o próximo boot carrega.

`app/test/features/auth/` não é raiz do digest de UI (`scripts/manaloom_ui_source_digest.sh`), então o
commit não move a prova de UI.

## Execução e mutações

### Rodada 1

Rodado em 2026-10-10 no worktree da frente de governança, a partir do `master` `1f525a1c1`. Toolchain fixado:
Flutter 3.44.6 e Dart 3.12.2. Tudo rodou dentro da trava FIFO da coordenação.

| Passo | Resultado |
| --- | --- |
| `flutter pub get --enforce-lockfile` | ok |
| `dart format --set-exit-if-changed` no teste | ok |
| `flutter analyze` no teste | "No issues found!" |
| o teste novo, na base | `+2`: "All tests passed!" |
| vizinhos: `auth_provider_security_test.dart` e `models/user_test.dart` | `+11`: "All tests passed!" |
| **M1:** o app troca o usuário guardado pelo usuário truncado de antes (só `id`, `username` e `email`) no lugar de `User.fromJson(rawUser)`, em `_rotateAuthenticatedSession` | `+0 -2`: os dois casos falham no e-mail verificado (`Expected: true`, `Actual: <false>`) |
| **M2:** `User.toJson` deixa de gravar `avatar_url`, e o usuário guardado no aparelho perde o avatar | `+0 -2`: os dois casos falham no avatar guardado (`Actual: <null>`) |
| o teste novo, de novo na base | `+2`: "All tests passed!" |

Depois de cada mutação, o arquivo foi restaurado da cópia e conferido com `cmp` contra ela e com
`git diff --quiet` contra o `HEAD`. Os dois ficaram idênticos.

### Rodada 2 (revisão de 2026-10-10)

A revisão achou um buraco: na rodada 1, a troca devolvia o mesmo usuário do login, então trocar
`User.fromJson(rawUser)` por `currentUser` em `_rotateAuthenticatedSession` passava. O app podia
ignorar o usuário do servidor e o teste não via. A rodada 2 roda o teste novo, com o usuário diferente
na resposta, no worktree da frente de governança em `32a2659e5` (o `master` `eac4f401b` mais esta branch).
Mesmo toolchain, dentro da trava FIFO.

| Passo | Resultado |
| --- | --- |
| **M3** contra o teste da rodada 1: `currentUser` no lugar de `User.fromJson(rawUser)` | `+2`: "All tests passed!": a mutação sobrevivia |
| `dart format --set-exit-if-changed` no teste novo | ok |
| `flutter analyze` no teste novo | "No issues found!" |
| o teste novo, na base | `+2`: "All tests passed!" |
| **M1:** o usuário truncado (só `id`, `username` e `email` da resposta) no lugar de `User.fromJson(rawUser)` | `+0 -2`: "Some tests failed."; o primeiro erro: esperado `true`, veio `<false>` |
| **M2:** `User.toJson` sem `avatar_url` | `+0 -2`: "Some tests failed."; o primeiro erro: esperado `'https://example.invalid/avatar-novo.png'`, veio `<null>` |
| **M3:** `currentUser` no lugar de `User.fromJson(rawUser)` | `+0 -2`: "Some tests failed."; o primeiro erro: esperado `'Jogadora Renomeada'`, veio `'Jogadora Um'` |
| o teste novo, de novo na base | `+2`: "All tests passed!" |
| vizinhos: `auth_provider_security_test.dart` e `models/user_test.dart` | `+11`: "All tests passed!" |

Cada mutação foi aplicada a partir de uma cópia do arquivo e desfeita com ela. Depois de cada uma, o
arquivo foi conferido com `cmp` contra a cópia e com `git diff --quiet` contra o `HEAD`. Os dois ficaram
idênticos.
