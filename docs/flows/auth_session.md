# Fluxo `auth_session` — Autenticação, recuperação de senha, verificação de email e sessão

Estado: documentação de apoio, não autoritativa · gerado em 2026-09-21 sobre o commit d26f23a16 · verificação estática (nenhum teste foi executado) · **revisado adversarialmente em 2026-09-21 — ver §11**

Convenção: caminhos relativos à raiz do repo. `app/...:N` e `server/...:N` são arquivo:linha lidos neste commit.

---

## 1. Resumo e veredito

| Eixo | Veredito | Base |
| --- | --- | --- |
| IMPLEMENTADO | **sim** | 9 arquivos de rota em `server/routes/auth/` + `server/routes/auth/_middleware.dart`; 6 telas em `app/lib/features/auth/screens/` + `app/lib/features/profile/profile_screen.dart`; 1 provider (`auth_provider.dart`, 788 linhas), 1 serviço (`account_security_service.dart`), 1 cofre de token (`app/lib/core/security/auth_token_store.dart`); 3 tabelas (`users`, `password_reset_tokens`, `email_verification_tokens`) em `server/database_setup.sql:7-117`. |
| ALCANÇÁVEL HOJE | **parcial** | É a **única** jornada alcançável: login, recuperação, verificação, troca de senha, revogação de sessões e perfil não exigem nenhuma capability — estão no allowlist do plano de controle (`server/lib/release_capability_policy.dart:590-620`). **Exceção: auto-cadastro está fechado.** `POST /auth/register` exige `account_registration` (`server/lib/release_capability_policy.dart:385-387`), e essa capability está `off`/`allowed:false` em `server/config/release_capabilities.json` — como **todas as 29**. O app espelha isso redirecionando `/register` → `/login` (`app/lib/main.dart:320-329`). Sem uma conta pré-existente, não há entrada no produto. |
| PROVADO | **parcial** | Há teste de comportamento real para: política de senha na rota de registro (`server/test/register_password_contract_test.dart`), negação de `POST /auth/register` pelo middleware raiz (`server/test/release_capability_policy_test.dart:418-437`), bucket de rate limit de credenciais (`server/test/rate_limit_middleware_test.dart:169-244`), preservação/limpeza de sessão local em `initialize()` (`app/test/features/auth/providers/auth_provider_initialize_test.dart`), rotação de token no app (`app/test/features/auth/providers/auth_provider_security_test.dart`) e telas de recuperação/verificação com serviço falso. **Mas:** o E2E que realmente prova reset→change→revoke ponta a ponta (`server/test/account_security_live_test.dart`) fica **fora de qualquer execução padrão** — não pelo `skip:` do arquivo, e sim porque `server/dart_test.yaml` restringe o `paths:` default a 50 arquivos que não o incluem e o preset `all-local` exclui as tags `live || live_backend || live_db_write` que ele declara em `:1` (corrigido na revisão adversarial; ver §11); os widget tests de login/registro substituem `login()`/`register()` por stubs que sempre retornam `true` (`app/test/features/auth/screens/auth_screens_test.dart:14-29`), logo **nenhum teste de app exercita o par app↔servidor de login**; e `splash_screen_redirect_test.dart` apesar do nome **não instancia `SplashScreen`** — testa só funções puras de `auth_redirect.dart`. |

Em uma frase: o fluxo é o único caminho vivo do produto e está tecnicamente coerente nos pontos de segurança que importam (hash, `auth_version`, token opaco com hash, fail-closed), mas o contrato de resposta de **`POST /auth/change-password` / `POST /auth/revoke-sessions` devolve um `user` truncado que o app grava por cima do usuário completo** (achado A1), o **Splash decide para onde ir antes de a validação de token terminar** (achado A2), **logout não revoga nada no servidor** (achado A4) e **o link de recuperação de senha é inutilizável em dispositivo já logado** (achado A11, encontrado na revisão adversarial).

```mermaid
sequenceDiagram
  autonumber
  participant U as Pessoa
  participant App as Flutter (Splash/Login/Profile)
  participant API as dart_frog (/auth/*)
  participant PG as PostgreSQL
  App->>API: GET /capabilities (boot, fail-closed)
  API-->>App: matriz das 29 capabilities
  App->>API: GET /auth/me (se há token salvo)
  API->>PG: users por id + confere authVersion do JWT
  API-->>App: 200 {user} | 401 (sessão morta)
  U->>App: email + senha em /login
  App->>API: POST /auth/login {email, password}
  API->>PG: SELECT users por email (deleted_at IS NULL)
  API->>API: bcrypt verify + JWT(userId, username, authVersion, 24h)
  API-->>App: 200 {token, user{id,username,email,email_verified}}
  App->>App: AuthTokenStore.write (Keychain/Keystore) + prefs user_data
  U->>App: "Esqueci minha senha"
  App->>API: POST /auth/forgot-password {email}
  API->>PG: INSERT password_reset_tokens (sha256 do token, 20 min)
  API-->>App: 202 mensagem neutra (corpo neutro; latência não — A12)
  U->>App: /reset-password?token=...
  App->>API: POST /auth/reset-password {token, new_password}
  API->>PG: consome token + auth_version += 1 (invalida todos os JWT)
  U->>App: Perfil → "Trocar senha"
  App->>API: POST /auth/change-password {current_password, new_password}
  API->>PG: FOR UPDATE, bcrypt, auth_version += 1
  API-->>App: 200 {token, user{id,username,email}}  %% sem email_verified
  App->>App: substitui token e SOBRESCREVE o usuário local (A1)
```

---

## 2. Jornada passo a passo

| # | Passo | Tela / widget | Provider / serviço no app | Método + endpoint | Handler no servidor | Serviço / dados |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Boot: buscar a matriz de capabilities | — (`initState` do app) | `ReleaseCapabilitiesProvider.refresh()` `app/lib/core/config/release_capabilities.dart:273-304`, disparado em `app/lib/main.dart:298` | `GET /capabilities` | `server/routes/capabilities/index.dart:8-14` | `ReleaseCapabilityPolicy.load()` lê `server/config/release_capabilities.json`; qualquer falha → `denied()` no app (`:313-317`) |
| 2 | Boot: restaurar sessão do disco | `SplashScreen` `app/lib/features/auth/screens/splash_screen.dart:50-71` | `AuthProvider.initialize()` → `_initializeFromDisk()` `app/lib/features/auth/providers/auth_provider.dart:62-156`; token vem de `AuthTokenStore.read()` `app/lib/core/security/auth_token_store.dart:68,125-146` | — (disco: Keychain/Keystore/WebCrypto + `SharedPreferences['user_data']`) | — | Migra a chave legada `auth_token` de `SharedPreferences` para o cofre uma única vez (`:131-145`) |
| 3 | Boot: validar o token com o backend | idem | `_validateTokenWithBackend()` `app/lib/features/auth/providers/auth_provider.dart:599-627` | `GET /auth/me` (header `Authorization: Bearer`) | `server/routes/auth/me.dart:13-47` | `AuthService.getUserFromToken()` `server/lib/auth_service.dart:313-348`: confere assinatura, `deleted_at IS NULL` e `payload.authVersion == users.auth_version` |
| 4 | Boot: decidir destino | `SplashScreen._initializeApp` `:50-71` | `resolveAuthenticatedLocation` / `buildAuthLocation` `app/lib/features/auth/auth_redirect.dart:29-44` | — | — | Destino padrão vem de `defaultAuthenticatedLocation` (`auth_provider.dart:48-50`): `/onboarding/core-flow` no primeiro uso, senão `/home` |
| 5 | Tela de login | `LoginScreen` `app/lib/features/auth/screens/login_screen.dart:146-212` (campos), `:248-286` (CTA) | — | — | — | `registrationAllowed` é injetado pelo roteador (`app/lib/main.dart:447-454`) a partir de `ReleaseCapability.accountRegistration` |
| 6 | Enviar credenciais | `_handleLogin` `login_screen.dart:51-87` | `AuthProvider.login()` `auth_provider.dart:159-240` | `POST /auth/login` `{email, password}` | `server/routes/auth/login.dart:16-87` | `AuthService.login()` `server/lib/auth_service.dart:259-308`: `SELECT ... FROM users WHERE (email=@e OR LOWER(email)=@e) AND deleted_at IS NULL`, `bcrypt.checkpw`, `generateToken(userId, username, authVersion)` com TTL de 24 h (`:49`) |
| 7 | Persistir sessão | — | `_saveCredentials()` `auth_provider.dart:485-518` | — | — | `AuthTokenStore.write` confirma a gravação relendo do cofre (`auth_token_store.dart:70-84`); `user_data` vai em `SharedPreferences` |
| 8 | Cadastro (fechado hoje) | `RegisterScreen` `app/lib/features/auth/screens/register_screen.dart:82-140` | `AuthProvider.register()` `auth_provider.dart:243-338` | `POST /auth/register` `{username, email, password, legal_accepted, terms_version, privacy_version}` | `server/routes/auth/register.dart:20-157` | `AuthService.register()` `server/lib/auth_service.dart:133-250` em `runTx`: checa username/email, INSERT em `users` + `user_plans` + `email_verification_tokens`; `LegalAcceptancePolicy.parse` `server/lib/legal_policy.dart:19-47` |
| 9 | Entrega do email de verificação | — | — | — (efeito colateral do passo 8) | `register.dart:93-112` | `EmailVerificationDeliveryService().deliver(...)`; falha é capturada e vira `verification_sent: false` — **nunca** derruba o registro |
| 10 | Pós-cadastro → verificar email | `register_screen.dart:115-129` faz `context.go('/verify-email?...&delivery=...')` | `emailVerificationDeliveryStatus` `auth_provider.dart:277-281`, modelo em `app/lib/features/auth/models/email_verification_delivery_result.dart:10-29` | — | — | Redundância no roteador: `app/lib/main.dart:398-411` também manda `/register` → `/verify-email` quando `user.emailVerified == false` |
| 11 | Verificar email por link | `VerifyEmailScreen._verify` `app/lib/features/auth/screens/verify_email_screen.dart:74-104` (auto-dispara em `initState`/`didUpdateWidget`, `:44,53-56`) | `AccountSecurityService.verifyEmail()` `app/lib/features/auth/account_security_service.dart:44-57` | `POST /auth/verify-email` `{token}` | `server/routes/auth/verify-email.dart:7-31` | `AuthService.verifyEmail()` `server/lib/auth_service.dart:398-447`: busca por `sha256(token)`, `FOR UPDATE OF t,u`, exige `consumed_at IS NULL` e `expires_at > now`, grava `email_verified_at` e consome todos os tokens do usuário |
| 12 | Reenviar verificação | `VerifyEmailScreen._resend` `:106-136` | `AccountSecurityService.resendEmailVerification()` `account_security_service.dart:59-83` | `POST /auth/resend-verification` (corpo `{}`, exige Bearer) | `server/routes/auth/resend-verification.dart:10-60` | `AuthService.createEmailVerificationRequest()` `auth_service.dart:350-396`: `FOR UPDATE`, consome pendentes, insere novo hash; já verificado → 200 `already_verified` |
| 13 | Pedir recuperação de senha | `ForgotPasswordScreen._submit` `app/lib/features/auth/screens/forgot_password_screen.dart:37-61` | `AccountSecurityService.requestPasswordReset()` `account_security_service.dart:10-24` | `POST /auth/forgot-password` `{email}` | `server/routes/auth/forgot-password.dart:13-68` | `AuthService.createPasswordResetRequest()` `auth_service.dart:452-500`: TTL de 20 min, consome tokens ativos, grava só o `sha256`. Resposta **sempre** 202 com a mesma frase (`:10-11`), conta existindo ou não — mas o trabalho executado antes da resposta difere (`:26-49`), ver A12 |
| 14 | Definir nova senha pelo link | `ResetPasswordScreen._submit` `app/lib/features/auth/screens/reset_password_screen.dart:41-66`; token vem de `?token=` (`app/lib/main.dart:466-471`) | `AccountSecurityService.resetPassword()` `account_security_service.dart:26-42` | `POST /auth/reset-password` `{token, new_password}` | `server/routes/auth/reset-password.dart:7-36` | `AuthService.resetPassword()` `auth_service.dart:503-576`: `FOR UPDATE OF t,u`, valida política, proíbe repetir a senha atual, `auth_version = auth_version + 1` — mata **todos** os JWT |
| 15 | Trocar senha autenticado | `ProfileScreen._changePassword` `app/lib/features/profile/profile_screen.dart:439-470` (diálogo `:1915`) | `AuthProvider.changePassword()` → `_rotateAuthenticatedSession()` `auth_provider.dart:340-415` | `POST /auth/change-password` `{current_password, new_password}` | `server/routes/auth/change-password.dart:7-33` | `AuthService._rotateAuthenticationVersion()` `auth_service.dart:603-674`: `FOR UPDATE`, bcrypt da senha atual, `auth_version += 1`, consome resets pendentes, devolve token novo |
| 16 | Encerrar outras sessões | `ProfileScreen._revokeSessions` `profile_screen.dart:474-501` (diálogo `:2035`) | `AuthProvider.revokeOtherSessions()` `auth_provider.dart:349-354` | `POST /auth/revoke-sessions` `{current_password}` | `server/routes/auth/revoke-sessions.dart:7-38` | Mesmo `_rotateAuthenticationVersion` sem `newPassword`; resposta acrescenta `sessions_revoked: true` |
| 17 | Expiração detectada em runtime | qualquer tela | `ApiClient._parseResponse` `app/lib/core/api/api_client.dart:623-627` → handler registrado em `app/lib/main.dart:282` → `AuthProvider.expireSession()` `auth_provider.dart:443-459` | — (reação a 401 de qualquer endpoint) | — | `isSessionInvalidatingUnauthorized` `api_client.dart:97-117` só dispara em 401 com sinal de token/sessão, e **exclui** `invalid_password` / `current_password_invalid` |
| 18 | Sair | `ProfileScreen` `profile_screen.dart:740-744` e `:411` | `AuthProvider.logout()` `auth_provider.dart:418-434` | **nenhuma chamada HTTP** | — | Limpa cofre + `user_data` + cache em memória. Veja achado A4 |
| 19 | Reação da aplicação à troca de conta / logout | — | `_onAuthChanged` `app/lib/main.dart:953-1006` | `GET /capabilities` de novo (`:1003`) | idem passo 1 | `_releaseCapabilitiesProvider.reset()` invalida a matriz do dono anterior antes de qualquer rebusca |

---

## 3. Capabilities e portões

### 3.1 Servidor (`server/routes/_middleware.dart:105-144`)

Toda requisição passa por `ReleaseCapabilityPolicy.decisionFor` **antes** de conectar no PostgreSQL (`:146-161`). Três saídas negativas:

- capability exigida e `allowed:false` → **404 `capability_unavailable`**;
- rota não classificada e fora do allowlist → **404 `capability_route_unclassified`** (`release_capability_policy.dart:169-178`);
- configuração inválida → **503 `capability_policy_invalid`** com as 29 forçadas `off` (`:629-644`).

Para este fluxo:

| Requisição | Capability exigida | Fonte |
| --- | --- | --- |
| `POST /auth/register` | **`account_registration`** | `release_capability_policy.dart:385-387` (vale para qualquer método no caminho) |
| `POST /auth/login` | — (plano de controle) | `:601` |
| `POST /auth/forgot-password` | — | `:602` |
| `POST /auth/reset-password` | — | `:603` |
| `POST /auth/change-password` | — | `:604` |
| `POST /auth/resend-verification` | — | `:605` |
| `POST /auth/revoke-sessions` | — | `:606` |
| `POST /auth/verify-email` | — | `:607` |
| `GET /auth/me` | — | `:608` |
| `GET /users/me`, `PATCH /users/me`, `DELETE /users/me`, `POST /users/me/export` (era GET até 2026-09-23; agora exige a senha no corpo), `GET /users/me/plan`, `GET /users/me/blocks` | — | `:609-614` |
| `GET /capabilities` | — | `:592` (corrigido: `:593` é `GET /ready`) |

O allowlist é **exato por método e caminho**: `GET /auth/future` ou `POST /auth/me` caem em 404 `capability_route_unclassified`, não em 405 (testado em `server/test/release_capability_policy_test.dart:340-360`).

### 3.2 App (`app/lib/core/config/release_capabilities.dart:350-534`)

O snapshot inicial é `denied()` (`:256`) e qualquer falha de refresh volta a `denied()` (`:313-317`): backend inalcançável equivale a tudo desligado. Para este fluxo só existe uma regra:

```
if (path == '/register' && !capabilities.isAllowed(ReleaseCapability.accountRegistration))
    return _replacePath(uri, '/login');     // release_capabilities.dart:358-361
```

Ela é **duplicada** em `app/lib/main.dart:320-329`, que roda antes no `redirect` do `GoRouter` e preserva o `?redirect=` via `buildAuthLocation`. Na prática a regra de `ReleaseCapabilityRouteGuard` para `/register` é código morto.

`/login`, `/forgot-password`, `/reset-password`, `/verify-email`, `/legal`, `/profile` e `/` **não** têm regra de capability no app — coerente com o allowlist do servidor.

### 3.3 Os nomes batem dos dois lados?

Sim, e há um teste que prova a igualdade exata dos 29 nomes entre o enum do app e o JSON do servidor: `app/test/core/config/release_capability_surface_contract_test.dart:162-177`. `account_registration` ↔ `ReleaseCapability.accountRegistration` (`release_capabilities.dart:8`).

### 3.4 O que o usuário vê quando está negado

| Situação | O que acontece |
| --- | --- |
| Deep link `/register` com `account_registration` off | Redirect silencioso para `/login`, preservando `?redirect=`. Sem mensagem explicando que o cadastro está fechado. |
| Tela `/login` com cadastro off | O bloco "Não tem uma conta? / Criar conta" simplesmente não é renderizado (`login_screen.dart:289-315`). Nenhum texto diz que a beta está fechada. |
| `POST /auth/register` chamado mesmo assim (cliente antigo, curl) | 404 com `{"error":"capability_unavailable","capability":"account_registration","policy_version":...,"policy_digest_sha256":...}`. |
| `/capabilities` indisponível no boot | `loadState = unavailable`, snapshot `denied()` → `/register` fecha, e todas as outras rotas com capability caem para `/home`. O fluxo auth em si continua funcionando porque não depende de capability. |

---

## 4. Contrato app↔servidor (por endpoint)

| Endpoint | App envia | Servidor lê | Servidor devolve | App lê | Divergência |
| --- | --- | --- | --- | --- | --- |
| `POST /auth/login` | `email`, `password` (`auth_provider.dart:171-174`) | `email` (trim), `password` (`login.dart:23-24`) | 200 `{token, user{id,username,email,email_verified}}` (`login.dart:45-56`) | `token`, `user` via `User.fromJson` (`auth_provider.dart:182-183`) | OK. `User.fromJson` (`user.dart:37-56`) lê 11 campos que o login não manda e cai nos defaults (`profile_visibility:'public'`, `location_visibility:'private'`, …) — ver A3. |
| `POST /auth/register` | `username`, `email`, `password`, `legal_accepted`, `terms_version`, `privacy_version` (`auth_provider.dart:262-269`) | os 6 (`register.dart:26-39`) | 201 `{token, user{...,email_verified:false}, verification_sent, [test_verification_token]}` | `verification_sent` (via `EmailVerificationDeliveryResult.fromJson`), `token`, `user` | OK. `test_verification_token` só existe fora de produção com aprovação explícita (`email_verification_policy.dart:20-26`) e o app o ignora. |
| `GET /auth/me` | header Bearer | header (`me.dart:18-19`) | 200 `{user{id,username,email,display_name,avatar_url,email_verified}}` (`auth_service.dart:339-346`; o docstring da própria rota em `me.dart:11` ainda promete `{id, username, email}` — defasado, ver A13) | `user` via `User.fromJson` e **grava em disco** (`auth_provider.dart:613-621`) | **Divergente**: falta `location_state`, `location_city`, `trade_notes` e as 6 chaves de visibilidade que `GET /users/me` devolve (`server/routes/users/me/index.dart:64-70`). Ver A3. |
| `POST /auth/verify-email` | `token` (`account_security_service.dart:45-47`) | `token` (`verify-email.dart:13`) | 200 `{email_verified:true, message}` | só `message` (`account_security_service.dart:56`) | `email_verified` é ignorado pelo app — inofensivo, mas o estado real vem depois de `refreshProfile()` (`verify_email_screen.dart:84-85`). |
| `POST /auth/resend-verification` | corpo `{}` + Bearer | não lê corpo; só o header (`resend-verification.dart:14-19`) | 202 `{email_verified:false, verification_sent, message}` ou 200 `{email_verified:true, already_verified:true, message}` | `verification_sent`, `message`, `already_verified` (`email_verification_delivery_result.dart:14-28`) | OK — o app aceita 200 **e** 202 (`account_security_service.dart:64`). |
| `POST /auth/forgot-password` | `email` (`account_security_service.dart:11-13`) | `email` (`forgot-password.dart:20-24`) | **202** `{message, [test_reset_token]}` | exige exatamente 202 (`account_security_service.dart:15`) | OK. Corpo inválido/ausente não é erro: o handler trata como email vazio (`:22-24`). |
| `POST /auth/reset-password` | `token`, `new_password` | idem (`reset-password.dart:13-14`) | 200 `{password_reset:true, message}` / 400 `{error, message}` | só o status e `message` | OK. `password_reset` é ignorado. |
| `POST /auth/change-password` | `current_password`, `new_password` (`auth_provider.dart:345`) | idem (`change-password.dart:18-19`) | 200 `{token, user{id,username,email}}` (`auth_service.dart:778-781`) | `token` e `user` via `User.fromJson`, **sobrescreve o usuário local** (`auth_provider.dart:382-398`) | **Divergente e com efeito visível**: sem `email_verified`, `display_name`, `avatar_url`. Ver A1. |
| `POST /auth/revoke-sessions` | `current_password` | idem (`revoke-sessions.dart:18`) | 200 `{token, user{id,username,email}, sessions_revoked:true, message}` | `token`, `user`; `sessions_revoked` e `message` **não são lidos** no caminho de sucesso (`auth_provider.dart:381-399`) | Mesmo A1. Além disso o app monta a própria frase de sucesso (`profile_screen.dart:489-491`) e descarta a do servidor. |
| `GET /users/me` | Bearer | — | 200 `{user{...completo..., email_verified}}` (`users/me/index.dart:34-70`) | `user` completo (`auth_provider.dart:643-650`) | OK — é a única fonte completa do usuário. |
| `PATCH /users/me` | subconjunto de 11 campos (`auth_provider.dart:690-704`) | — | 200 `{user}` | `user` (`:720-736`) | OK. |
| `GET /capabilities` | — | — | 200 envelope de 10 chaves + 29 capabilities (`release_capability_policy.dart:198-211`) | valida chaves exatas e o invariante `allowed == (release_capability == 'on')` (`release_capabilities.dart:70-91,193-208`) | OK — validação estrita simétrica dos dois lados. |

**Endpoint que ninguém chama:** não há `POST /auth/logout` nem nada equivalente; `logout()` é 100 % local (`auth_provider.dart:418-434`). Ver A4.

**Endpoint chamado que não existe:** nenhum. Todos os 9 arquivos de `server/routes/auth/` têm um chamador no app, exceto nada.

---

## 5. Dados (tabelas e migrações)

| Tabela | Colunas relevantes | Onde nasce | Quem escreve |
| --- | --- | --- | --- |
| `users` | `id uuid pk`, `username text unique`, `email text unique`, `password_hash`, `auth_version int not null default 0`, `password_changed_at`, `terms_version`/`terms_accepted_at`, `privacy_version`/`privacy_accepted_at`, `email_verified_at`, `deleted_at` | `server/database_setup.sql:7-34` (DDL) e `:50-71` (ALTERs idempotentes) | `AuthService.register` (INSERT), `verifyEmail` (`email_verified_at`), `resetPassword` e `_rotateAuthenticationVersion` (`password_hash`, `auth_version`, `password_changed_at`), `user_data_privacy_service.dart:936-959` (anonimização no delete) |
| `password_reset_tokens` | `user_id fk cascade`, `token_hash char(64) unique`, `expires_at`, `consumed_at` | `server/database_setup.sql:95-105`, índice parcial em `:103-105` | `createPasswordResetRequest` (INSERT), `resetPassword` e `_rotateAuthenticationVersion` (consomem) |
| `email_verification_tokens` | mesma forma | `server/database_setup.sql:107-117` | `register`, `createEmailVerificationRequest`, `verifyEmail` |
| `user_plans` | `user_id pk`, `plan_name`, `status` | `server/database_setup.sql:37-46` | `register` faz `INSERT ... ON CONFLICT DO NOTHING` (`auth_service.dart:209-216`) |

Migração versionada: `044` cria o par `users.email_verified_at` + `email_verification_tokens` e tem política de rollback `manualOnly` (asseverado em `server/test/email_verification_contract_test.dart:14-34`).

Invariantes criptográficas em uso:
- senha: bcrypt com salt por hash; senhas acima de 72 bytes são pré-hasheadas em SHA-256 e marcadas com o prefixo `bcrypt_sha256$` (`auth_service.dart:21,56-76,717-731`);
- tokens de reset/verificação: 32 bytes de `Random.secure()`, base64url, e **só o SHA-256 vai ao banco** (`auth_service.dart:701-708`);
- JWT: `{userId, username, authVersion, iat}`, TTL de 24 h (`auth_service.dart:93-102`); `JwtSecretPolicy.validate` recusa segredo curto ou marcador previsível em produção (`auth_service.dart:35-40`, testado em `server/test/auth_runtime_policy_test.dart:26-93`).

---

## 6. Estados e erros

| Estado | Tratado? | Onde |
| --- | --- | --- |
| Carregando (login/registro) | Sim | `AuthStatus.loading` troca o CTA por um spinner (`login_screen.dart:224-247`); as telas de recuperação usam `_submitting` (`forgot_password_screen.dart:38`, `reset_password_screen.dart:42`) |
| Carregando (boot) | Parcial | O roteador segura rotas protegidas enquanto `status` é `loading`/`initial` e guarda o destino em `?redirect=` (`main.dart:359-383`). Mas o Splash não espera a validação — **A2** |
| Vazio | n/a | Não há listas neste fluxo |
| Validação de formulário | Sim | Login: email com `@` e senha ≥ 6 (`login_screen.dart:161-169,203-211`). Registro/reset: `validateRegistrationPassword` com mínimo de 12, denylist e proibição de dados da conta (`app/lib/features/auth/password_policy.dart:4-36`), espelhando `server/lib/password_policy.dart:7-51`. **Incoerência menor:** o mínimo de 6 no login contradiz o mínimo de 12 da política real (ver A7) |
| Erro de rede / timeout | Sim | `FriendlyErrorMapper.fromException` classifica `SocketException`/`ClientException`/host lookup e devolve copy de offline (`friendly_error_mapper.dart:328-334`); GET tem 1 retry transitório (`api_client.dart:307-347`), **POST não tem retry** — correto para operações não idempotentes |
| 401 / expiração de sessão | Sim | `ApiClient.isSessionInvalidatingUnauthorized` (`api_client.dart:97-117`) → `expireSession()` (`auth_provider.dart:443-459`), que muda o estado **síncrono** para o `GoRouter` capturar a URI protegida, e limpa o disco só se os valores ainda baterem (`:461-482`). 401 de validação de domínio (`invalid_password`, `current_password_invalid`) fica local ao formulário |
| 401 no boot | Sim | Só 401 remove a sessão; 429, 5xx, timeout e rede preservam (`auth_provider.dart:108-124`). É a única regra do fluxo em `traceability` de `docs/project_logic_contracts.json` e tem teste dedicado |
| 403 de capability | n/a neste fluxo | Nenhuma rota de auth devolve 403 por capability (o portão devolve 404) |
| 404 de capability | Parcial | `POST /auth/register` devolve 404, mas o app nunca chega lá porque redireciona antes. Se chegasse, `FriendlyErrorMapper` mostraria "Não encontramos o conteúdo solicitado" — copy sem sentido para "cadastro fechado" |
| 429 (rate limit) | Sim | 5 req/min por cliente em produção, 200 em dev (`rate_limit_middleware.dart:150-158`); o app mostra "Muitas tentativas em sequência…" (`friendly_error_mapper.dart:118-120,312-314`) e **não** derruba a sessão local (`auth_provider.dart:610-612`) |
| Offline / retry | Parcial | Há copy de offline por fluxo (`OfflineProductFlow.authentication`, `friendly_error_mapper.dart:236-238`), mas **nenhum botão "tentar de novo"** nas telas de auth — o usuário tem de tocar no CTA outra vez |
| Concorrência: duplo toque | Parcial | `forgot`, `reset`, `resend`, `changePassword` e `revokeSessions` têm guarda booleana explícita. **`LoginScreen._handleLogin` não tem** (`login_screen.dart:51-87`); depende do `AuthStatus.loading` trocar o widget e do contador `_authGeneration` no provider. Ver A6 |
| Concorrência: `initialize()` reentrante | Sim | Dedupe por `_initializeFuture` + `_authGeneration` (`auth_provider.dart:62-82`), e toda escrita tardia é descartada por comparação de geração |
| Concorrência: token trocado durante gravação | Sim | `_saveCredentials` reverte a escrita no cofre se a geração mudou no meio (`auth_provider.dart:500-503,508-511`) |
| Job assíncrono em andamento | n/a | Não há job assíncrono neste fluxo |
| CORS / preflight | Sim | `CorsPolicy` valida origem e preflight antes de qualquer coisa (`server/routes/_middleware.dart:71-103`) |

**Não tratados:**
- não há tela ou mensagem para "cadastro fechado" (§3.4);
- a resposta de erro do servidor pode conter texto técnico bruto do PostgreSQL e o app o exibe (A5);
- `logout` não invalida o token no servidor (A4);
- o app não tem contagem regressiva nem `Retry-After` visível no 429, embora o servidor mande `retry_after`, `retry_after_seconds` e `retry_after_ms` (`rate_limit_middleware.dart:99-120`).

---

## 7. Testes por passo e lacunas

| # | Passo | Teste que exercita | O que de fato afirma |
| --- | --- | --- | --- |
| 1 | `GET /capabilities` | `app/test/core/config/release_capabilities_test.dart`; `app/test/core/config/release_capability_surface_contract_test.dart:162-177`; `server/test/release_capability_policy_test.dart` | Comportamento real: parsing estrito do envelope, `denied()` em falha, e igualdade exata dos 29 nomes entre app e `server/config/release_capabilities.json` |
| 2–3 | Restaurar e validar sessão | `app/test/features/auth/providers/auth_provider_initialize_test.dart` | Comportamento real com `ApiClient` falso: 401 limpa tudo; 429/500/503/timeout/`ClientException` preservam; token sem usuário, usuário sem token e JSON quebrado são removidos com copy explícita. **Não cobre** `/auth/me` 200 devolvendo `user` — o fake devolve `{}` (`:30`) |
| 2 | Cofre de token | `app/test/core/security/auth_token_store_test.dart` | Comportamento real do backend seguro e da migração da chave legada |
| 4 | Decidir destino no boot | `app/test/features/auth/screens/splash_screen_redirect_test.dart` | **Só funções puras** de `auth_redirect.dart`. **Não instancia `SplashScreen`** apesar do nome — a corrida de A2 não é exercitada |
| 5 | Tela de login | `app/test/features/auth/screens/auth_screens_test.dart:46-114`; `app/test/ui/manaloom_auth_ui_audit_test.dart`; `app/test/ui/ui_keyboard_focus_matrix_test.dart:238-266` | Presença de chaves, semântica de campo/obscured, ordem de foco, e que "Criar conta" some com registro fechado. É verificação de presença/posição, não de comportamento de rede |
| 6 | `POST /auth/login` | `app/test/features/auth/screens/auth_screens_test.dart:176-226` (stub que sempre retorna `true`, `:14-29`); `server/test/auth_flow_integration_test.dart:26-75` (**fora da execução padrão**) | No app: só que o deep link protegido é retomado. No servidor: normalização de email/username. **Corrigido na revisão:** o `skip:` do arquivo (`:11-14`) só dispara com `RUN_INTEGRATION_TESTS=0` **explícito**; quem rodar `dart test test/auth_flow_integration_test.dart` com a variável ausente vê **falha vermelha**, não `SKIP`. O que o tira da execução padrão é `server/dart_test.yaml` (não está no `paths:` default; preset `all-local` exclui as tags `live` declaradas em `:1`) |
| 7 | Persistir sessão | `auth_provider_security_test.dart:61-84` | Comportamento real: após `changePassword`, o cofre e o provider guardam o token novo |
| 8 | `POST /auth/register` | `server/test/register_password_contract_test.dart` (invoca o handler de verdade, pré-DB); `server/test/release_capability_policy_test.dart:418-437` (nega via middleware raiz, 404 `capability_unavailable`); `server/test/auth_flow_integration_test.dart:77-114` (**skip**) | Códigos estáveis `password_too_short`/`weak_password`; negação da capability antes do handler e do PG |
| 8 | Consentimento legal | `server/test/legal_consent_contract_test.dart`; `server/test/legal_consent_live_test.dart` (**skip**) | Contrato: produção sempre exige as versões atuais |
| 9–10 | Entrega do email e pós-cadastro | `app/test/features/auth/screens/auth_screens_test.dart:228-288` | Que `/register` navega para `/verify-email?redirect=...`. Não exercita `verification_sent` vindo do servidor |
| 11–12 | Verificar / reenviar | `app/test/features/auth/screens/verify_email_screen_test.dart` (6 casos); `app/test/features/auth/account_security_service_test.dart:77-121` | Comportamento real com serviço falso: verificação automática pelo link, troca de token na mesma rota, resposta velha não vence, falha de entrega não manda o usuário olhar a caixa de entrada, `already_verified` |
| 11 | `POST /auth/verify-email` no servidor | `server/test/email_verification_contract_test.dart` | **Verificação por string**: lê `database_setup.sql` e o SQL da migração 044 procurando substrings, e lê 4 arquivos `_middleware.dart` procurando `verifiedEmailForMutations()`. Só `:36-53` testa comportamento (`isVerifiedEmailRequired`). **O handler `verify-email.dart` não é invocado por nenhum teste** |
| 13–14 | Forgot / reset | `app/test/features/auth/screens/account_security_screens_test.dart`; `app/test/features/auth/account_security_service_test.dart:27-75` | Comportamento real com `ApiClient` falso: validação de email, resposta neutra, token ausente/reusado com copy de recuperação, e que exceção crua nunca vaza |
| 13–16 | Cadeia reset→change→revoke no servidor | `server/test/account_security_live_test.dart:70-189` (**skip** sem backend + PG) | Quando roda, é o teste mais forte do fluxo: token de reset de uso único, expirado rejeitado, `auth_version` invalidando `tokenA`/`tokenB`, senha antiga recusada, `tokenC` morto após troca, `tokenD` morto após revogação |
| 15–16 | Rotação no app | `auth_provider_security_test.dart:61-133` | Troca bem-sucedida substitui o token atomicamente; revogação falha preserva a sessão; `logout` limpa erro. **Não afirma nada sobre `user.emailVerified` depois da rotação** — é exatamente o ponto cego de A1 (o fake em `:21-28` já reproduz o `user` truncado do servidor) |
| 15–16 | Diálogos no perfil | `app/test/features/profile/profile_screen_test.dart:282-345` | Só validação local dos diálogos ("Informe sua senha atual."), obscurecimento e cancelamento. **Nunca confirma a operação**, portanto não há teste do estado pós-troca |
| 17 | Expiração em runtime | `auth_provider_security_test.dart:135-161` | `expireSession` limpa token, usuário, cofre e `user_data`, e põe a mensagem de sessão expirada |
| 18 | Logout | `auth_provider_security_test.dart:110-133` | Limpa estado local. **Nenhum teste afirma que o token continua válido no servidor** |
| 19 | Reset de capabilities na troca de conta | `app/test/core/config/release_capability_surface_contract_test.dart:179-205` | **Verificação por string** sobre `lib/main.dart` (conta ocorrências de `_releaseCapabilitiesProvider.reset()` e procura trechos literais, inclusive um com quebra de linha e indentação exatas). Não exercita comportamento e quebra com qualquer reformatação |
| — | Rate limit | `server/test/rate_limit_middleware_test.dart:168-248` | Comportamento real: `GET /auth/me` não consome nem sofre o bucket; `POST /auth/login` (`:168-201`) e `POST /auth/register` (`:203-225`) sofrem; recuperação e rotação compartilham o mesmo bucket (`:227-248`). **Corrigido na revisão: esse teste prova 6 dos 8 caminhos de `isAuthCredentialAttempt` — o loop em `:228-233` cobre só `forgot-password`, `reset-password`, `change-password` e `revoke-sessions`. `POST /auth/verify-email` e `POST /auth/resend-verification` não aparecem em nenhum teste do arquivo** |
| — | Evidência visual | `app/integration_test/app_existing_user_visual_audit_test.dart:372-513` | Roda o `ManaLoomApp` de verdade e captura `splash_boot`, `login_empty`, `register_*`, `forgot_password_empty`, `reset_password_invalid_link`, `verify_email_signed_out`, `legal_*`, `profile_success`. Exige backend isolado com `account_registration` ligada (`scripts/manaloom_authenticated_visual_qa_isolated.sh:297-339`) |

### Passos sem nenhum teste (6)

1. **Passo 4 — decisão do Splash** (`splash_screen.dart:50-71`): nenhum teste instancia a tela com um `AuthProvider` lento.
2. **Passo 3 — `/auth/me` 200 com `user`**: o caminho que sobrescreve `user_data` (`auth_provider.dart:613-621`) nunca é exercitado.
3. **Passo 11 servidor — `server/routes/auth/verify-email.dart`**: handler jamais invocado em teste determinístico.
4. **Passo 12 servidor — `server/routes/auth/resend-verification.dart`**: idem.
5. **Passos 15–16 — estado do usuário depois da rotação**: nenhum teste olha `auth.user` além do token.
6. **Passo 18 — validade do token após logout**: não há prova nem contraprova.
7. *(acrescentado na revisão adversarial)* **Bucket de rate limit de `POST /auth/verify-email` e `POST /auth/resend-verification`**: os dois estão em `isAuthCredentialAttempt` (`rate_limit_middleware.dart:355-356`) mas nenhum teste de `server/test/rate_limit_middleware_test.dart` os menciona.
8. *(acrescentado na revisão adversarial)* **Redirect de `/reset-password` e `/forgot-password` para quem já está autenticado** (`app/lib/main.dart:334-338` e `:414-424`): nenhum teste monta o `GoRouter` real com sessão viva e um link de recuperação. Ver A11.

### Testes que só verificam string/posição

- `app/test/core/config/release_capability_surface_contract_test.dart:8-160` e `:179-205` — `File(...).readAsStringSync()` + `contains`/`isNot(contains)`.
- `server/test/email_verification_contract_test.dart:19-34` e `:55-68` — SQL e middlewares lidos como texto.
- `app/test/ui/manaloom_auth_ui_audit_test.dart`, `ui_accessibility_matrix_test.dart:162,170`, `ui_keyboard_focus_matrix_test.dart` — presença de chaves, contraste, ordem de foco.

---

## 8. Achados

| id | Tipo | Severidade | Achado | Arquivo:linha | Como provar |
| --- | --- | --- | --- | --- | --- |
| **A1** | bug provável | **alta** | `POST /auth/change-password` e `POST /auth/revoke-sessions` devolvem `user` só com `{id, username, email}`. O app roda `User.fromJson` nesse mapa e **substitui** o usuário completo, então `emailVerified`, `displayName` e `avatarUrl` viram `false`/`null` — e são gravados em `SharedPreferences['user_data']`. Efeito visível imediato: quem tem email verificado vê o selo virar "Email pendente" e o aviso "Seu email ainda precisa ser verificado" aparecer logo após trocar a senha, sem sair da tela de perfil (que só chama `refreshProfile()` no `initState`). | Servidor: `server/lib/auth_service.dart:778-782`. App: `app/lib/features/auth/providers/auth_provider.dart:382-398`; `app/lib/features/auth/models/user.dart:54` (`emailVerified: json['email_verified'] == true`). UI afetada: `app/lib/features/profile/profile_screen.dart:991-998` e `:1390-1400`. Refresh só no `initState`: `:213-227` | Teste a escrever em `app/test/features/auth/providers/auth_provider_security_test.dart`: fazer o fake de `/auth/login` devolver `user` com `'email_verified': true`, chamar `changePassword`, e afirmar `auth.user!.emailVerified == true`. Hoje falha. Correção: incluir `email_verified`, `display_name` e `avatar_url` em `AccountSecurityResult.toJson()`, **ou** fazer `_rotateAuthenticatedSession` fundir com `currentUser` via `copyWith` em vez de `User.fromJson`. Prova viva: perfil com email verificado → "Trocar senha" → conferir o selo. |
| **A2** | bug provável | **alta** | O `SplashScreen` nunca espera a validação do token. `MyApp.initState` já disparou `_authProvider.initialize()` (`main.dart:299`), o que coloca `_status` em `loading` de forma síncrona; quando o Splash chama `initialize()` de novo, o guard `if (_status != AuthStatus.initial) return;` faz a chamada retornar na hora. O Splash então espera só os 650 ms de dwell e navega por `authProvider.isAuthenticated`, que ainda é `false` se `GET /auth/me` demorar mais que isso. Resultado: sessão válida e rede lenta → o usuário vê a tela de login piscar antes de o roteador corrigir para `/home`. | `app/lib/features/auth/screens/splash_screen.dart:50-71` (`startedAt` antes do `await` que não espera); `app/lib/features/auth/providers/auth_provider.dart:62-65` (early return); `app/lib/main.dart:299` | Teste de widget a escrever: `AuthProvider` falso cujo `GET /auth/me` resolve depois de 2 s, montar `SplashScreen` com `pumpWidget` + `pump(Duration(seconds:1))` e afirmar que **não** houve `context.go('/login')`. Correção: expor um `Future` público da inicialização em andamento (devolver `_initializeFuture` mesmo quando o status já saiu de `initial`) e aguardá-lo no Splash. Prova viva: simulador iOS com a rede throttled em "3G lenta" e sessão salva. |
| **A3** | incoerência app↔servidor | média | `GET /auth/me` devolve um usuário reduzido (sem `location_state`, `location_city`, `trade_notes` e sem as 6 chaves de visibilidade), mas o boot roda `User.fromJson` nele e **grava por cima** do `user_data` completo que `GET /users/me` havia salvo. Todo boot frio degrada o usuário persistido para os defaults do código (`profile_visibility: 'public'`, `location_visibility: 'private'`, …). **A degradação dos dados é real e verificada. O efeito visível que a primeira versão deste documento afirmava ("/profile exibe 'Perfil público' para quem escolheu privado") foi REFUTADO na revisão adversarial e está corrigido aqui:** hoje a capability `profiles_public` está `off` como as outras 28, então `access.profilesPublic == false` (`profile_screen.dart:47-48`) e o selo renderiza **"Perfil não publicado"** (`profile_screen.dart:985-986`), sem nunca olhar `_profileVisibility`; o seletor de visibilidade sequer é construído (`:1302`) e `updateProfile` manda `profileVisibility: null` (`:325`). Ou seja: **IMPLEMENTADO** (a perda de dados acontece), **não ALCANÇÁVEL hoje** em termos de dano visível, **não PROVADO** por teste. O dano aparece no dia em que `profiles_public` for ligada — e aí em duas formas: o selo errado e, pior, o `PATCH /users/me` do formulário gravando `public` de volta no servidor (`profile_screen.dart:260,325`) por cima da escolha do usuário. | Servidor: `server/lib/auth_service.dart:339-346` (payload reduzido) vs `server/routes/users/me/index.dart:56-72` (payload completo; as 6 chaves de visibilidade + `email_verified` em `:64-70`). App: `app/lib/features/auth/providers/auth_provider.dart:613-621`; defaults em `app/lib/features/auth/models/user.dart:47-53`; gate que hoje esconde o efeito: `app/lib/features/profile/profile_screen.dart:985-986,1302,325` | Teste a escrever em `auth_provider_initialize_test.dart`: pré-carregar `user_data` com `profile_visibility: 'private'`, fazer o fake de `/auth/me` devolver 200 com o `user` reduzido, rodar `initialize()` e afirmar que `prefs.getString('user_data')` ainda contém `"private"`. Hoje falha (o fake em `:30` devolve `{}` e nunca exercita o caminho). Correção: fundir com o usuário salvo (`copyWith`) em vez de reconstruir, ou fazer `/auth/me` devolver a mesma forma de `/users/me`. **Não use o selo de `/profile` como prova viva enquanto `profiles_public` estiver off** — inspecione `SharedPreferences['user_data']` direto. |
| **A4** | segurança | média | Não existe rota de logout no servidor; `logout()` só apaga o cofre e o `user_data` locais. O JWT emitido continua válido por até 24 h (`_tokenDuration`, `auth_service.dart:49`) e `auth_version` não muda. Quem capturou o token antes do logout continua autenticado. O produto oferece "Encerrar outras sessões" (que rotaciona `auth_version`), mas "Sair" não. | `app/lib/features/auth/providers/auth_provider.dart:418-434`; `server/routes/auth/` não contém `logout.dart`; TTL em `server/lib/auth_service.dart:49` | Prova viva: capturar o Bearer de uma sessão, tocar em "Sair", e chamar `GET /auth/me` com o token capturado — hoje devolve 200. Correção possível: `POST /auth/logout` que incremente `auth_version` (encerra todas as sessões) ou uma denylist de `jti`. Se a decisão for deliberada, registrar em `docs/` que "Sair" é local. |
| **A5** | segurança / ux-funcional | média | `login.dart` e `register.dart` classificam **toda** `Exception` como 400 e repassam `e.toString()` no corpo. Uma falha de infraestrutura (pool caído, violação de constraint em corrida de registro) vira erro do cliente com texto técnico do PostgreSQL. E o `FriendlyErrorMapper` usa uma *denylist* (`_looksTechnical`): uma mensagem como `Severity.error 23505: duplicate key value violates unique constraint "users_username_key"` não casa com nenhum termo proibido, então **é exibida literalmente** no snackbar. | `server/routes/auth/login.dart:57-72`; `server/routes/auth/register.dart:135-142`; `app/lib/core/utils/friendly_error_mapper.dart:316-318` (`if (!_looksTechnical(text)) return text;`) e `:344-368` (a denylist) | Teste unitário a escrever em `app/test/core/utils/friendly_error_mapper_test.dart`: `FriendlyErrorMapper.fromStatusCode(400, body: {'message': 'Severity.error 23505: duplicate key value violates unique constraint "users_username_key"'}, context: FriendlyErrorContext.authRegister)` e afirmar que o retorno **não** contém `constraint`. Hoje falha. Correção: no servidor, só repassar mensagens de exceções de negócio conhecidas e devolver 503 no resto; no app, trocar a denylist por allowlist de códigos. |
| **A6** | ux-funcional | baixa | `LoginScreen._handleLogin` não tem guarda de reentrância. A proteção é indireta: o `Consumer` troca o `InkWell` por um `Container` quando `status == loading`, e `_authGeneration` descarta a chamada mais antiga. Se duas chamadas escaparem (toque programático, teste, gesto em frames consecutivos antes do rebuild), a primeira retorna `false` com `errorMessage == null` e o `else` mostra o snackbar genérico "Erro ao fazer login" enquanto a segunda autentica com sucesso. | `app/lib/features/auth/screens/login_screen.dart:51-87` e `:265-270`; geração em `app/lib/features/auth/providers/auth_provider.dart:160,180` | **Hipótese** sobre a facilidade de reproduzir com o dedo; o caminho de código é certo. Teste de widget: chamar `tester.tap` duas vezes sem `pump` entre elas com um provider cujo `login` demora, e afirmar que não aparece nenhum `SnackBar` de erro. Correção: `bool _submitting` como nas outras 5 telas do fluxo. |
| **A7** | incoerência | baixa | O validador de senha do login exige mínimo de **6** caracteres, mas a política real (registro, reset e troca, cliente e servidor) exige **12**. Nenhuma senha aceita pelo sistema tem menos de 12, então a regra de 6 nunca protege nada e a mensagem "Senha deve ter no mínimo 6 caracteres" contradiz o helper "Use 12+ caracteres" que o usuário acabou de ver no reset. | `app/lib/features/auth/screens/login_screen.dart:203-211` vs `app/lib/features/auth/password_policy.dart:1,13-15` e `server/lib/password_policy.dart:4,13-18` | Teste de widget: digitar uma senha de 8 caracteres no login e afirmar que o formulário **não** é considerado válido por um limite diferente do da política. Correção trivial: validar só "não vazio" no login (o servidor decide), ou usar `registrationPasswordMinimumLength`. |
| **A8** | doc-defasada | baixa | O comentário de `authRateLimit` afirma que "apenas `POST /auth/login` e `POST /auth/register`" consomem o bucket, mas `isAuthCredentialAttempt` lista **8** caminhos, incluindo `/auth/verify-email` e `/auth/resend-verification`. O mesmo texto defasado está repetido no middleware da pasta (`server/routes/auth/_middleware.dart:6-7`: "5 tentativas de login/registro por minuto"). Consequência prática: um escritório atrás de NAT compartilha 5 tentativas/minuto entre login, reset, troca de senha, verificação e reenvio. | `server/lib/rate_limit_middleware.dart:360-365` e `server/routes/auth/_middleware.dart:4-10` (comentários) vs `rate_limit_middleware.dart:340-358` (código) | **Corrigido na revisão adversarial:** a versão anterior dizia "basta corrigir o comentário porque `rate_limit_middleware_test.dart:227-244` já prova os 8". **Não prova.** O arquivo de teste cobre `POST /auth/login` (`:168-201`), `POST /auth/register` (`:203-225`) e os 4 de recuperação/rotação (`:227-248`) = **6 de 8**. `POST /auth/verify-email` e `POST /auth/resend-verification` não aparecem em nenhum teste. Então: corrigir os dois comentários **e** estender o loop de `:228-233` para os 8 caminhos. Se o compartilhamento de bucket for indesejado, separar `auth_credentials` de `auth_recovery` e provar com um teste por bucket. |
| **A9** | incoerencia-app-servidor | baixa | `currentTermsVersion`/`currentPrivacyVersion` são literais **duplicados** em `app/lib/features/commercial/legal_policy.dart:1-2` e `server/lib/legal_policy.dart:1-2`. Hoje batem (`2026-08-05` / `2026-07-21`), mas nada trava a igualdade: se um lado subir a versão, todo `POST /auth/register` passa a devolver 400 `legal_acceptance_required` em produção — e, com o cadastro fechado, ninguém perceberia até reabrir. | `app/lib/features/commercial/legal_policy.dart:1-2`; `server/lib/legal_policy.dart:1-2`; consumo em `app/lib/features/auth/screens/register_screen.dart:110-111` e `server/lib/legal_policy.dart:36-37` | Teste a escrever no app, no mesmo molde do que já compara os 29 nomes de capability (`app/test/core/config/release_capability_surface_contract_test.dart:162-177`): ler `../server/lib/legal_policy.dart` e afirmar que os dois literais coincidem com os do app. |
| **A11** | bug provável | **média** | *(achado novo da revisão adversarial)* **Quem já está logado neste dispositivo não consegue usar o link de recuperação de senha.** `/reset-password` está na lista `isAuthRoute` do `redirect` do `GoRouter` (`main.dart:334-338`), e a regra `if (isAuthRoute && _authProvider.isAuthenticated)` (`:414-424`) devolve `resolveAuthenticatedLocation(...)`. Como o deep link é `/reset-password?token=XYZ` e **não** traz `?redirect=`, `normalizePostAuthRedirect(null)` devolve `null` e o destino vira `defaultAuthenticatedLocation` → `/home`. O token é descartado e **nenhuma mensagem é mostrada**. Nos dois modos: app já aberto → salto imediato; app aberto pelo link → a tela renderiza (é `isBootSafeRoute`, `:362-369`) e é arrancada assim que `initialize()` conclui com sessão válida. Esse é exatamente o cenário de "acho que minha conta foi invadida, vou trocar a senha pelo email" no telefone onde a pessoa está logada. `/forgot-password` tem o mesmo tratamento. | `app/lib/main.dart:334-338` (lista `isAuthRoute`), `:414-424` (o redirect), `:362-369` (janela de boot que deixa a tela aparecer); tela afetada: `app/lib/features/auth/screens/reset_password_screen.dart:41-66` | Teste de widget a escrever: montar o `GoRouter` real de `main.dart` com um `AuthProvider` autenticado, navegar para `/reset-password?token=abc` e afirmar que a localização final **não** é `/home`. Hoje falha. Correção: tirar `/reset-password` de `isAuthRoute` (o token é a credencial, não a sessão), ou tratá-lo como rota neutra igual a `/verify-email`, que já está fora da lista de propósito. Prova viva: web, logado, colar `/reset-password?token=qualquer-coisa` na barra de endereço — cai em `/home` sem aviso. |
| **A12** | segurança | baixa | *(achado novo da revisão adversarial)* **A neutralidade de `POST /auth/forgot-password` é só no corpo, não no tempo.** O handler só entra no caminho caro quando `email.isNotEmpty && email.contains('@')` (`forgot-password.dart:27`); dentro dele, conta existente ⇒ `createPasswordResetRequest` (transação no PostgreSQL) **e** `PasswordResetDeliveryService().deliver(...)` (rede); conta inexistente ⇒ `createPasswordResetRequest` devolve `null` e a entrega nem é tentada (`:32-38`). O 202 e a frase são idênticos, mas a latência não é — o que reabre a enumeração de contas que o desenho quis fechar. O diagrama da §1 dizia "202 mensagem neutra (sem enumeração)"; leia "corpo neutro". | `server/routes/auth/forgot-password.dart:26-49` (o ramo caro), `:59-67` (resposta idêntica), `:10-11` (a frase) | Não dá para provar com teste de unidade determinístico. Prova viva: com o backend isolado, medir `curl -w '%{time_total}'` em 20 chamadas com email existente vs 20 com email inexistente e comparar as medianas. Correção: enfileirar a entrega fora do ciclo de resposta, ou responder 202 imediatamente e fazer o trabalho em background. |
| **A13** | doc-defasada | baixa | *(achado novo da revisão adversarial)* Três docstrings **dentro do código** descrevem contratos que o código não cumpre mais, e nenhum teste os cobre: `server/routes/auth/me.dart:11` promete `{ user: { id, username, email } }` quando a rota devolve 6 campos; `server/routes/auth/login.dart:12` promete `{token, user: {id, username, email}}` sem `email_verified`, que a rota manda desde `:53`; `server/routes/auth/_middleware.dart:6-7` repete o texto errado do bucket de rate limit (ver A8). São a mesma classe de defeito de A8, em arquivos que este documento listava como "implementação" sem nunca abrir o cabeçalho. | `server/routes/auth/me.dart:11`; `server/routes/auth/login.dart:12`; `server/routes/auth/_middleware.dart:6-7` | Correção textual. Vale mais como sinal: os contratos de resposta de auth não têm nenhum teste de forma (schema) — só `release_capability_surface_contract_test.dart` faz comparação estrutural, e só de capabilities. |
| **A14** | incoerência app↔servidor | baixa | *(achado novo da revisão adversarial)* `VerifyEmailScreen._verify` chama `auth.refreshProfile()` depois do sucesso (`verify_email_screen.dart:84-85`), mas `_resend()` **não** chama nada equivalente no ramo `already_verified` (`:106-136`): ele só faz `setState(_verified = result.alreadyVerified)`. Resultado: quem toca em "Reenviar" e descobre que o email já estava verificado vê a tela dizer "verificado" enquanto `auth.user.emailVerified` continua `false` em memória e em `user_data`. Só se auto-corrige ao visitar `/profile` (que chama `refreshProfile()` no `initState`, `profile_screen.dart:213-227`). | `app/lib/features/auth/screens/verify_email_screen.dart:84-85` (o que faz certo) vs `:106-136` (o que não faz); consumidores do estado: `app/lib/features/profile/profile_screen.dart:992,995,1390` | Teste de widget a acrescentar em `verify_email_screen_test.dart`: serviço falso devolvendo `already_verified: true` e afirmar que `AuthProvider.refreshProfile()` foi chamado. Hoje falha. Correção: chamar `refreshProfile()` também em `_resend()` quando `result.alreadyVerified`. |
| **A10** | ux-funcional | baixa | Cadastro fechado é **silencioso**. O deep link `/register` redireciona para `/login` sem mensagem, e a tela de login apenas omite o bloco "Criar conta". Quem recebeu um convite ou um link antigo não descobre por que não consegue criar conta. O servidor, por sua vez, responde 404 — que o `FriendlyErrorMapper` traduziria como "Não encontramos o conteúdo solicitado". | `app/lib/main.dart:320-329`; `app/lib/features/auth/screens/login_screen.dart:289-315`; `app/lib/core/utils/friendly_error_mapper.dart:95-105` | Teste de widget: montar `LoginScreen(registrationAllowed: false)` e afirmar a presença de um aviso explicando a beta fechada (hoje não existe nada a encontrar). Decisão de produto antes de teste. |

---

## 9. Divergências em relação aos contratos existentes

| Contrato | O que declara | O que o disco mostra |
| --- | --- | --- |
| `docs/project_logic_contracts.json` → `flows[auth_session].entrypoints` | 4 entrypoints: `/login`, `/register`, `/forgot-password`, `/verify-email` | Faltam **`/`** (Splash, que é quem decide o destino e é a `initialLocation` do roteador, `app/lib/main.dart:305,441-445`), **`/reset-password`** (`:466-471`), **`/legal`** (`:472-477`, alcançável e usado pelo consentimento do registro) e **`/profile`** (`:842-845`, onde vivem troca de senha e revogação de sessões). |
| idem → `implementation` | 6 arquivos | Faltam, entre outros: `server/routes/auth/_middleware.dart`, `server/routes/auth/me.dart`, `server/routes/auth/forgot-password.dart`, `server/routes/auth/reset-password.dart`, `server/routes/auth/change-password.dart`, `server/routes/auth/revoke-sessions.dart`, `server/routes/auth/verify-email.dart`, `server/routes/auth/resend-verification.dart`, `server/lib/password_policy.dart`, `server/lib/legal_policy.dart`, `server/lib/email_verification_policy.dart`, `server/lib/rate_limit_middleware.dart`, `app/lib/core/api/api_client.dart`, `app/lib/features/auth/account_security_service.dart`, `app/lib/features/auth/auth_redirect.dart`, `app/lib/features/profile/profile_screen.dart`. |
| idem → `storage` | `users`, `password_reset_tokens`, `email_verification_tokens` | Correto, mas incompleto: `register` também escreve em `user_plans` (`server/lib/auth_service.dart:209-216`). |
| idem → `tests` | 3 arquivos | Dos 3, `server/test/auth_flow_integration_test.dart` **fica fora da execução padrão por `server/dart_test.yaml`** — não está no `paths:` default e declara `@Tags(['live','live_backend','live_db_write'])` em `:1`, que o preset `all-local` exclui; o `skip:` de `:11-14` só age com `RUN_INTEGRATION_TESTS=0` explícito (corrigido na revisão adversarial). `server/test/auth_runtime_policy_test.dart` cobre política de segredo/proxy, não o fluxo. O contrato **não cita** os testes que hoje mais provam o fluxo: `server/test/account_security_live_test.dart`, `server/test/register_password_contract_test.dart`, `server/test/rate_limit_middleware_test.dart`, `app/test/features/auth/providers/auth_provider_initialize_test.dart`, `app/test/features/auth/account_security_service_test.dart`, `app/test/features/auth/screens/verify_email_screen_test.dart`. |
| idem → `sequence` (4 arestas) | "Pessoa → Flutter → Auth API → PostgreSQL → Flutter" | Omite a aresta que hoje define o alcance: `Flutter → GET /capabilities` no boot, e o portão fail-closed do middleware raiz antes de qualquer handler. O diagrama da §1 corrige isso. |
| `docs/MAPA_OPERACIONAL_DO_PROJETO.md:77` | "Rotas alcançáveis hoje: **10** — `/`, `/login`, `/forgot-password`, `/reset-password`, `/verify-email`, `/legal`, `/home`, `/onboarding/core-flow`, `/plans`, `/profile`" | **Confere** com o código lido. |
| `docs/MAPA_OPERACIONAL_DO_PROJETO.md:84-92` | "Só uma jornada funciona hoje: `auth_session` — e mesmo ela sem auto-cadastro" | **Confere**: `account_registration` `off` em `server/config/release_capabilities.json` e redirect em `app/lib/main.dart:320-329`. |
| `server/lib/rate_limit_middleware.dart:362-365` (doc no código) | "Only credential submissions (`POST /auth/login` and `POST /auth/register`) consume this bucket" | Falso — são 8 caminhos (achado A8). O mesmo texto errado se repete em `server/routes/auth/_middleware.dart:6-7` (A13). |
| `docs/project_logic_contracts.json` (forma) | Este documento falava em `flows[auth_session]` | Nota de precisão: `flows` é uma **lista**, não um mapa; o bloco do fluxo começa em `docs/project_logic_contracts.json:319` (`"id": "auth_session"` em `:320`). |
| `docs/MANALOOM_E2E_RELEASE_CONTRACT.md` | Define perfis de execução e regra de `SKIP` ("um `SKIP` precisa declarar pré-requisito e comando de ativação; não pode ser apresentado como `PASS`") | Os 5 testes vivos de auth declaram uma mensagem em `skip:` ("Teste live desativado por `RUN_INTEGRATION_TESTS=0`.") que **não traz nem pré-requisito nem comando de ativação** — o real (backend em `TEST_API_BASE_URL`, PG com `DB_NAME`/`DB_USER`/`DB_PASS`, `MANALOOM_PASSWORD_RESET_TEST_RESPONSE`, `account_registration` ligada) está espalhado pelo corpo. **Pior:** essa mensagem só aparece quando alguém passa `RUN_INTEGRATION_TESTS=0`; com a variável ausente o teste **roda e falha** contra `http://127.0.0.1:8082` (`auth_flow_integration_test.dart:16-17`, `account_security_live_test.dart:19-20`), o que é justamente o `SKIP` disfarçado de outra cor que o contrato quer evitar. O que de fato protege a execução padrão é `server/dart_test.yaml` (`paths:` restrito + preset `all-local` com `exclude_tags`). Ver §10. |
| `docs/BREWTACT_DECKBUILDER_AI_CURRENT_FLOW_2026-08-12.md` | Não trata de auth | Sem divergência aplicável. |
| `docs/LAYOUT_TEST_MAP.md` | Cita auth só indiretamente (`app_full_non_life_counter_visual_capture_smoke_test.dart`, linha 106) | Os 8 goldens de auth que existem em disco (`splash_boot`, `login_empty`, `register_empty`, `register_consent_*`, `forgot_password_empty`, `reset_password_invalid_link`, `verify_email_signed_out`, `legal_*`, `profile_success`) vêm de `app_existing_user_visual_audit_test.dart`, que o mapa não nomeia. |

---

## 10. Rodada 2: comandos e roteiro de prova viva

### 10.1 Comandos determinísticos (não rodar agora — outra sessão está usando a máquina)

```bash
# App — unidade e widget do fluxo (raiz: app/)
flutter test test/features/auth test/features/profile/profile_screen_test.dart \
  test/core/security/auth_token_store_test.dart \
  test/core/api/api_client_request_id_test.dart \
  test/core/utils/friendly_error_mapper_test.dart \
  test/core/config/release_capabilities_test.dart \
  test/core/config/release_capability_surface_contract_test.dart

# Servidor — determinístico, sem rede nem PG (raiz: server/)
RUN_INTEGRATION_TESTS=0 JWT_SECRET=hermes-local-test-secret dart test \
  test/auth_service_test.dart \
  test/auth_runtime_policy_test.dart \
  test/auth_release_preflight_contract_test.dart \
  test/password_policy_test.dart \
  test/register_password_contract_test.dart \
  test/email_verification_contract_test.dart \
  test/legal_consent_contract_test.dart \
  test/rate_limit_middleware_test.dart \
  test/release_capability_policy_test.dart

# Gate amplo declarado para este fluxo
./scripts/quality_gate.sh quick
```

### 10.2 Comandos vivos (exigem backend + PostgreSQL de teste)

Pré-requisitos: servidor dart_frog em `TEST_API_BASE_URL` com `ENVIRONMENT=development`; PostgreSQL com `DB_HOST`/`DB_PORT`/`DB_NAME`/`DB_USER`/`DB_PASS`; `account_registration` **ligada** (os 3 primeiros registram usuário); exposição de token de teste habilitada para o reset.

```bash
# raiz: server/
RUN_INTEGRATION_TESTS=1 \
TEST_API_BASE_URL=http://127.0.0.1:8082 \
DB_HOST=127.0.0.1 DB_PORT=5432 DB_NAME=... DB_USER=... DB_PASS=... \
MANALOOM_PASSWORD_RESET_TEST_RESPONSE=<aprovação exigida por password_reset_delivery_service.dart> \
MANALOOM_EMAIL_VERIFICATION_TEST_RESPONSE=I_UNDERSTAND_VERIFICATION_TOKENS_ARE_TEST_ONLY \
dart test \
  test/auth_flow_integration_test.dart \
  test/account_security_live_test.dart \
  test/auth_token_rotation_live_test.dart \
  test/email_verification_live_test.dart \
  test/legal_consent_live_test.dart
```

Para ligar `account_registration` sem tocar em `server/config/release_capabilities.json`, o caminho aprovado é o override isolado:
`MANALOOM_E2E_ISOLATED_RUNTIME=1`, `MANALOOM_CONFIRM_ISOLATED_RELEASE_CAPABILITIES=I_UNDERSTAND_THIS_IS_DISPOSABLE_TEST_ONLY` e `MANALOOM_ISOLATED_RELEASE_CAPABILITIES_FILE=<arquivo absoluto em $TMPDIR>` (validado em `server/lib/release_capability_policy.dart:346-375`), exatamente como `scripts/manaloom_authenticated_visual_qa_isolated.sh:297-372` faz.

### 10.3 Testes novos a escrever antes da rodada 2

| Achado | Arquivo alvo | Asserção |
| --- | --- | --- |
| A1 | `app/test/features/auth/providers/auth_provider_security_test.dart` | login com `email_verified: true` → `changePassword` → `auth.user!.emailVerified` continua `true` |
| A2 | novo `app/test/features/auth/screens/splash_screen_test.dart` | `AuthProvider` com `/auth/me` de 2 s: em 1 s o Splash não navegou para `/login` |
| A3 | `app/test/features/auth/providers/auth_provider_initialize_test.dart` | `/auth/me` 200 com `user` reduzido não apaga `profile_visibility: 'private'` de `user_data` |
| A5 | `app/test/core/utils/friendly_error_mapper_test.dart` | mensagem com `duplicate key value violates unique constraint` não é repassada ao usuário |
| A9 | `app/test/core/config/release_capability_surface_contract_test.dart` | literais de `currentTermsVersion`/`currentPrivacyVersion` iguais em app e servidor |
| lacuna 3 e 4 | novo `server/test/email_verification_routes_test.dart` | invocar `verify-email.dart` e `resend-verification.dart` com contexto falso e afirmar 400 `email_verification_token_invalid` e 401 sem Bearer |
| **A11** | novo `app/test/features/auth/router_recovery_link_test.dart` | `GoRouter` real + `AuthProvider` autenticado + `/reset-password?token=abc` ⇒ a localização final **não** é `/home` |
| **A14** | `app/test/features/auth/screens/verify_email_screen_test.dart` | serviço falso com `already_verified: true` ⇒ `refreshProfile()` chamado |
| **A8 (lacuna 7)** | `server/test/rate_limit_middleware_test.dart` | estender o loop de `:228-233` para os 8 caminhos de `isAuthCredentialAttempt`, incluindo `/auth/verify-email` e `/auth/resend-verification` |

### 10.4 Roteiro curto de prova viva

**Pré-requisitos comuns:** backend isolado (`scripts/manaloom_authenticated_visual_qa_isolated.sh`) com a política isolada que liga `account_registration`; PostgreSQL de fixture; app iniciado com `--dart-define=API_BASE_URL=<backend isolado>`; um usuário de fixture com email **verificado** e outro **não verificado**.

**Web (mais rápido, cobre A1/A3/A10):**
1. `flutter run -d chrome --dart-define=API_BASE_URL=...`, entrar com o usuário verificado.
2. Ir a `/profile`, fotografar o selo "Email verificado".
3. "Trocar senha" → confirmar com a senha atual e uma nova de 12+ caracteres.
4. **Sem recarregar**, fotografar o selo de novo. Se virou "Email pendente" e apareceu o aviso de verificação, **A1 está confirmado**.
5. Em `/profile`, deixar o perfil privado e salvar. Matar a aba, reabrir com a rede desligada (DevTools → Offline) e abrir `/profile`: se o selo diz "Perfil público", **A3 está confirmado**.
6. Abrir `/register` direto na URL: deve cair em `/login` sem nenhuma mensagem (**A10**).

**Simulador iOS (cobre A2/A4):**
1. Entrar com o usuário verificado, matar o app.
2. Ativar o Network Link Conditioner em "Edge"/"3G lento" e abrir o app: se a tela de login pisca antes de ir para `/home`, **A2 está confirmado**.
3. Com a rede normal e a sessão ativa, capturar o Bearer (log do `ApiClient`, `[🌐 ApiClient] GET ...`, ou proxy local).
4. Tocar em "Sair".
5. `curl -H "Authorization: Bearer <token>" $API/auth/me` — se devolver 200, **A4 está confirmado**.

**Recuperação de senha (cobre os passos 13–14 sem servidor de email):** com `MANALOOM_PASSWORD_RESET_TEST_RESPONSE` habilitado, `POST /auth/forgot-password` devolve `test_reset_token` no corpo; abrir `/reset-password?token=<token>` no app **numa aba/instalação deslogada** (ver A11 — logado o roteador arranca a tela), definir a nova senha, e confirmar que o login com a senha antiga passa a devolver 401 e que a sessão que estava aberta em outro dispositivo cai no próximo request (`auth_version` incrementado).

---

## 11. Verificação adversarial (2026-09-21, segunda passada)

Segunda leitura, cética, sobre o mesmo commit `d26f23a16`. Objetivo declarado: derrubar o documento. Regime: **somente leitura**, nenhum teste executado, nenhum processo Flutter/Dart iniciado.

### 11.1 Afirmações arquivo:linha conferidas uma a uma

Abri o arquivo em cada caso. 26 citações checadas; **20 exatas, 5 com desvio de 1–2 linhas (conteúdo certo), 1 errada**.

| Afirmação do documento | Veredito |
| --- | --- |
| `server/lib/auth_service.dart:778-782` — `AccountSecurityResult.toJson()` devolve `{id, username, email}` | **Confere** (o bloco é `:778-781`; conteúdo exato) |
| `app/lib/features/auth/providers/auth_provider.dart:382-398` — `_rotateAuthenticatedSession` substitui o usuário | **Confere.** A substituição literal é `:384-386` (`rawUser is Map<String,dynamic> ? User.fromJson(rawUser) : currentUser`) e `:397` (`_user = nextUser`) |
| `app/lib/features/auth/models/user.dart:54` — `emailVerified: json['email_verified'] == true` | **Confere, linha exata** |
| `app/lib/features/auth/screens/splash_screen.dart:50-71` — `_initializeApp`, `startedAt` antes do `await` | **Confere, faixa exata** |
| `app/lib/features/auth/providers/auth_provider.dart:62-65` — guard `if (_status != AuthStatus.initial) return;` | **Confere.** E o guard de `_initializeFuture` (`:67-71`) vem **depois** dele, logo não salva o Splash |
| `app/lib/main.dart:299` — `unawaited(_authProvider.initialize())` no `initState` | **Confere, linha exata** (e `:282` para `setSessionExpiredHandler`, `:298` para `refresh()` das capabilities) |
| `app/lib/features/auth/providers/auth_provider.dart:613-621` — `/auth/me` 200 grava por cima de `user_data` | **Confere, faixa exata** |
| `server/lib/auth_service.dart:340-347` — payload reduzido de `getUserFromToken` | **Desvio de 1.** O `return {` é `:339` e o payload `:340-345`; o método é `:312-347`. Corrigido no §4 |
| `server/routes/users/me/index.dart:64-70` — as 6 chaves de visibilidade | **Confere** (`:64-69` visibilidade, `:70` `email_verified`) |
| `server/routes/auth/login.dart:57-72` e `register.dart:135-142` — toda `Exception` vira 400 com `e.toString()` | **Confere, faixas exatas** |
| `app/lib/core/utils/friendly_error_mapper.dart:316-318` e `:344-368` — `_looksTechnical` é denylist | **Confere.** Simulei a string do exemplo contra os 22 termos: nenhum casa, e nenhum ramo anterior casa (`username` bate mas o segundo termo — `already`/`exists`/`uso`/`cadastrado` — não) ⇒ o texto cru é devolvido |
| `app/lib/features/auth/screens/login_screen.dart:51-87` (sem guarda) e `:203-211` (mínimo 6) | **Confere, faixas exatas** |
| `app/lib/features/auth/screens/login_screen.dart:289-315` — bloco "Criar conta" condicional | **Confere, faixa exata** |
| `server/lib/rate_limit_middleware.dart:340-358` (8 caminhos) vs `:360-365` (comentário) | **Confere, faixas exatas** |
| `app/lib/features/commercial/legal_policy.dart:1-2` e `server/lib/legal_policy.dart:1-2` | **Confere**: literais idênticos (`2026-08-05` / `2026-07-21`), duplicados sem trava |
| `server/lib/release_capability_policy.dart:385-387` — `/auth/register` ⇒ `account_registration` | **Confere, faixa exata**; e sim, ignora o método |
| `server/lib/release_capability_policy.dart:601-614` — allowlist das rotas de auth e `users/me` | **Confere, linha a linha** |
| `server/lib/release_capability_policy.dart:593` — `GET /capabilities` | **ERRADO.** `GET /capabilities` é `:592`; `:593` é `GET /ready`. Corrigido |
| `server/routes/_middleware.dart:105-144` (portão) antes de `:146-161` (PostgreSQL) | **Confere** |
| `server/config/release_capabilities.json` — 29 capabilities, todas `off`/`allowed:false` | **Confere.** Contei: 29 chaves, zero com `release_capability == 'on'` ou `allowed == true` |
| `app/test/core/config/release_capability_surface_contract_test.dart:162-177` — igualdade dos 29 nomes | **Confere, faixa exata.** E é teste de comportamento de verdade (lê o JSON e compara conjuntos), não string |
| `app/test/core/config/release_capability_surface_contract_test.dart:196-199` — asserção com `\n` e indentação exatas | **Confere, faixa exata.** É de fato frágil a qualquer reformatação |
| `server/test/release_capability_policy_test.dart:418-437` — 404 antes do handler | **Confere, faixa exata**, e o teste afirma `handlerCalled == false` |
| `app/test/features/auth/screens/splash_screen_redirect_test.dart` nunca instancia `SplashScreen` | **Confere.** `grep SplashScreen` no arquivo: zero ocorrências |
| `app/test/features/auth/providers/auth_provider_initialize_test.dart:30` — o fake devolve `{}` | **Confere, linha exata** |
| `app/test/features/auth/providers/auth_provider_security_test.dart:21-28` — o fake já reproduz o `user` truncado | **Confere, faixa exata** |
| `server/test/rate_limit_middleware_test.dart:227-244` "prova os 8" | **ERRADO.** O teste vai até `:248` e o loop (`:228-233`) tem 4 caminhos. Com `login` (`:168`) e `register` (`:203`), o arquivo prova **6 de 8**. Corrigido em §7 e A8 |
| `docs/MAPA_OPERACIONAL_DO_PROJETO.md:77` (10 rotas) e `:84-92` (auth_session única viva) | **Confere** |
| `docs/LAYOUT_TEST_MAP.md` não nomeia `app_existing_user_visual_audit_test.dart` | **Confere** (`grep` só encontra `app_full_non_life_counter_visual_capture_smoke_test.dart`, `:106`) |
| `docs/project_logic_contracts.json` → entrypoints 4 / implementation 6 / storage 3 / tests 3 / sequence 4 | **Confere item a item.** Nota de forma: `flows` é lista, bloco em `:319-320` |

### 11.2 Achados julgados

| id | Veredito | Por quê |
| --- | --- | --- |
| **A1** | **Confirmado** | Vi os dois lados. `AccountSecurityResult.toJson()` (`auth_service.dart:778-781`) devolve 3 campos; `change-password.dart:21` e `revoke-sessions.dart:20-26` mandam esse mapa; `_rotateAuthenticatedSession` (`auth_provider.dart:384-386,397`) reconstrói o `User` com `fromJson` e `_saveCredentials` (`:485-518`) grava `user.toJson()` em `user_data`. O selo é incondicional (`profile_screen.dart:992-998` — **sem** gate de capability, ao contrário do selo de perfil) e o aviso em `_buildSecurityActions` (`:1386-1400`) é chamado sem condição de `/profile` (`:1219`). `_changePassword` (`:439-472`) não chama `refreshProfile()` depois do sucesso, e o `initState` (`:213-227`) só roda uma vez. Alcançável hoje: **sim** — `/profile`, `GET /users/me` e `POST /auth/change-password` estão todos no allowlist do plano de controle |
| **A2** | **Confirmado** | A ordem é a que o documento descreve: `MyApp.initState` chama `initialize()` (`main.dart:299`), o corpo de `_initializeFromDisk` roda **síncrono** até o primeiro `await` (`auth_provider.dart:85-91`), deixando `_status = loading`; o `SplashScreen.initState` (`:46-47`) vem depois, e o `await authProvider.initialize()` (`splash_screen.dart:52`) bate no guard `:63-65` e volta na hora. O dwell é fixo em 650 ms a partir de `startedAt` (`:51,54-58`). Confirmei também o destino: `context.go('/login')`, o `redirect` deixa passar porque `/login` é `isBootSafeRoute` (`main.dart:362-369`), e só quando `initialize()` termina o `refreshListenable` reexecuta o redirect e a regra `isAuthRoute && isAuthenticated` (`:414-424`) corrige para `/home`. O flash é o comportamento do código. O que **não** está provado é o tamanho da janela em rede real |
| **A3** | **Confirmado quanto à perda de dados, com a consequência REESCRITA** | A degradação é real (§11.1). Mas tentei reproduzir o efeito declarado e ele **não existe hoje**: o selo de perfil é `!access.profilesPublic ? 'Perfil não publicado' : …` (`profile_screen.dart:985-986`), `profiles_public` está `off` como as outras 28, o seletor de visibilidade nem é construído (`:1302`) e o save manda `null` (`:325`). Ou seja, o documento confundiu IMPLEMENTADO com ALCANÇÁVEL — o defeito está no disco e fica invisível até `profiles_public` ser ligada. Texto corrigido em A3, inclusive com a consequência **pior** que o original não viu: com a capability ligada, um save do formulário reescreve `profile_visibility` para `public` no servidor |
| **A4** | **Confirmado** | `ls server/routes/auth/` tem 9 handlers e nenhum `logout.dart`; `git grep logout` em `server/routes` e `server/lib` só acha um comentário sobre FCM (`users/me/fcm-token/index.dart:14`). `logout()` (`auth_provider.dart:418-434`) é 100 % local e não toca `auth_version`. TTL de 24 h em `auth_service.dart:49`. A assimetria com "Encerrar outras sessões" (que rotaciona, `auth_service.dart:603-674`) é real |
| **A5** | **Confirmado** | Os dois lados verificados (§11.1). Ressalva de alcance que o documento não fez: o ramo de **registro** está fechado hoje (404 do portão antes do handler), então a superfície viva de A5 é só `POST /auth/login` — onde o que escapa são falhas de infraestrutura, não colisão de constraint |
| **A6** | **Plausível, não provado** | O que é **certo**: `_handleLogin` (`login_screen.dart:51-87`) não tem guarda; se duas chamadas passarem, a primeira volta `false` sem `errorMessage` (`auth_provider.dart:180` compara a geração e retorna antes de escrever a mensagem) e o `else` de `:81-86` mostra o snackbar genérico. O que **não** é provado é a reprodutibilidade: a proteção indireta existe (o `Consumer` troca o `InkWell`, e `login()` põe `loading` de forma síncrona em `:164`), então seria preciso dois toques dentro do mesmo frame. O documento já marcava isso como hipótese; mantido |
| **A7** | **Confirmado** | `login_screen.dart:203-211` exige 6; `app/lib/features/auth/password_policy.dart` e `server/lib/password_policy.dart` exigem 12; o helper do reset diz "Use 12+ caracteres" (`reset_password_screen.dart:108`). A regra de 6 é inalcançável na prática e a mensagem contradiz a política |
| **A8** | **Confirmado no defeito, evidência corrigida** | O comentário está errado (e repetido em `routes/auth/_middleware.dart:6-7`, que o documento não tinha visto). Mas a frase "já existe teste dos 8, basta corrigir o comentário" é **falsa**: o teste cobre 6. Corrigido |
| **A9** | **Confirmado** | Literais duplicados e idênticos hoje, sem nenhuma trava. O molde de teste sugerido é viável: `release_capability_surface_contract_test.dart:162-177` já lê `../server/config/...` do diretório `app/`, logo ler `../server/lib/legal_policy.dart` funciona no mesmo esquema |
| **A10** | **Confirmado** | `main.dart:320-329` redireciona sem mensagem; `login_screen.dart:289-315` só omite o bloco. Não existe nenhum texto sobre beta fechada em nenhuma das duas telas |
| **passos sem teste (6)** | **Confirmado, e são 8** | Os 6 se sustentam um a um. Acrescentei dois: o bucket de rate limit de `verify-email`/`resend-verification` e o redirect de `/reset-password` com sessão viva (A11) |
| **testes só de string** | **Confirmado, com uma ressalva** | `release_capability_surface_contract_test.dart:8-160` e `:179-205` e `email_verification_contract_test.dart:19-33,55-68` são mesmo leitura de arquivo + `contains`. Mas o documento incluía no mesmo balaio `:162-177`, que **não** é teste de string: ele desserializa o JSON do servidor e compara conjuntos de chaves. Diferença registrada em §3.3 |
| **capability (única jornada, sem auto-cadastro)** | **Confirmado** | 29 chaves, zero `on`; `/auth/register` ⇒ `account_registration` (`:385-387`); 404 antes do handler provado em `release_capability_policy_test.dart:418-437`; app redireciona em `main.dart:320-329` |
| **`project_logic_contracts.json` defasado** | **Confirmado** | Extraí o bloco e conferi campo a campo: 4 entrypoints, 6 arquivos de implementação, 3 tabelas, 3 testes, 4 arestas. Todas as ausências listadas no §9 procedem |

**Nada foi refutado por inteiro.** Caiu uma consequência (o efeito visível de A3) e caíram duas evidências (o "prova os 8" de A8, o "skip por padrão" do `auth_flow_integration_test.dart`).

### 11.3 O que a primeira passada não viu

Rastreei de ponta a ponta dois endpoints e uma tela que o documento tratava de raspão:

- **`POST /auth/forgot-password`** (`server/routes/auth/forgot-password.dart` inteiro → `AuthService.createPasswordResetRequest` → `PasswordResetDeliveryService`): corpo neutro confirmado, **latência não neutra** ⇒ **A12**.
- **`POST /auth/resend-verification`** (`server/routes/auth/resend-verification.dart` inteiro → `AccountSecurityService:59-83` → `VerifyEmailScreen._resend:106-136`): o ramo `already_verified` não sincroniza o usuário local ⇒ **A14**. De passagem: o 401 sem Bearer usa `error: 'invalid_session'`, e `ApiClient.isSessionInvalidatingUnauthorized` (`:96-117`) **não** o transforma em expiração de sessão porque exige `hasAuthenticationToken` — comportamento correto, sem achado.
- **`ResetPasswordScreen` + o `redirect` do roteador** (`reset_password_screen.dart` inteiro + `main.dart:334-338,414-424`): o link de recuperação é inutilizável em dispositivo logado ⇒ **A11**, o achado mais importante desta passada.
- **Docstrings dentro do código** (`me.dart:11`, `login.dart:12`, `routes/auth/_middleware.dart:6-7`) ⇒ **A13**.

Também **testei e descartei** uma hipótese própria: o latch estático `ApiClient._sessionExpiryDispatched` parecia capaz de silenciar expirações depois da primeira, mas `setToken` o rearma a cada token novo (`api_client.dart:54-56`, `:90-91`). Sem defeito.

### 11.4 Confiança

**Média-alta.** As citações arquivo:linha são boas (1 errada e 5 com desvio de linha em 26 checadas), o veredito dos três eixos se sustenta, e os achados de severidade alta (A1, A2) foram confirmados lendo o código dos dois lados. O que puxa a confiança para baixo é a categoria de erro que apareceu duas vezes: **afirmar que um teste prova mais do que prova** (A8) e **afirmar que um teste é pulado quando ele falha** (`auth_flow_integration_test.dart`) — ambas do tipo que só uma execução real desfaz, e nenhuma execução foi feita nesta sessão nem na anterior. Enquanto os comandos da §10.1 não rodarem, todo "PROVADO" deste documento continua sendo "existe um arquivo de teste que parece cobrir isso", não "isso passou".
