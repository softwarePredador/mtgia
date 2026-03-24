# Sentry Setup Operacional - MTGIA

> Setup operacional implementado em `2026-03-24`.
> Usa como referência o desenho validado no `carMatch`, mas adaptado ao stack Dart/Flutter do `mtgia`.

## O que foi implementado

### Backend

- `Sentry` inicializado sob demanda em `server/lib/observability.dart`
- captura de exceções não tratadas no middleware global em `server/routes/_middleware.dart`
- `x-request-id` propagado no backend:
  - reutiliza header inbound quando existir
  - gera um novo quando não existir
  - devolve o mesmo valor no header de resposta
- rota curta `GET /ready` publicada em `server/routes/ready/index.dart`
- CORS atualizado para aceitar `X-Request-Id`

### App

- `Sentry` inicializado em `app/lib/core/observability/app_observability.dart`
- captura global de:
  - `FlutterError`
  - `PlatformDispatcher.onError`
- `x-request-id` enviado em toda request do `ApiClient`
- erros de transporte do `ApiClient` passam a poder ser capturados no Sentry
- `AppLogger.error(...)` passa a encaminhar erro real para observabilidade quando houver exceção associada
- observer de navegação adiciona tag básica de rota
- contexto de usuário autenticado passa a ser sincronizado no Sentry

## Fontes de credenciais

As credenciais reais **não** devem ser copiadas para o repositório.

O outro projeto já possui, localmente, as chaves necessárias em:

- `/Users/desenvolvimentomobile/Documents/rafa/carMatch/backend/.env`

Esse arquivo foi usado apenas como mapa de nomes de variáveis. Os valores não devem ser replicados em documentação, código nem commit.

## Variáveis esperadas

### Backend (`server/.env`)

- `SENTRY_DSN`
- `SENTRY_ENVIRONMENT`
- `SENTRY_RELEASE`
- `SENTRY_TRACES_SAMPLE_RATE`

### App Flutter (`--dart-define`)

- `SENTRY_DSN`
- `SENTRY_ENVIRONMENT`
- `SENTRY_RELEASE`
- `SENTRY_TRACES_SAMPLE_RATE`

## Exemplo de execução do app

```bash
./scripts/flutter_run_with_local_sentry.sh
```

O script lê `server/.env` localmente e injeta no app:

- `SENTRY_MOBILE_DSN` quando existir
- senão faz fallback para `SENTRY_DSN`
- `SENTRY_ENVIRONMENT`
- `SENTRY_RELEASE`
- `SENTRY_TRACES_SAMPLE_RATE`

## Smoke operacional do app

Arquivo:

- `app/integration_test/mobile_sentry_smoke_test.dart`

Script local:

```bash
./scripts/validate_sentry_mobile_local.sh
```

Esse script:

- lê `server/.env`
- injeta `SENTRY_MOBILE_DSN` ou fallback para `SENTRY_DSN`
- executa o smoke de integração do app
- imprime `SENTRY_MOBILE_SMOKE_TAG=smoke_id:...` para busca posterior no Sentry
- encerra com timeout configurável (`MOBILE_SENTRY_BUILD_TIMEOUT_SECONDS`, default `120`)
- em caso de bloqueio no build/toolchain, imprime `SENTRY_MOBILE_TOOLCHAIN_BLOCKED=1`

Validação completa com ingestão:

```bash
./scripts/validate_sentry_mobile_ingestion.sh
```

## Exemplo de backend local

```bash
cd server
cp .env.example .env
# preencher SENTRY_DSN e afins no .env local
dart_frog dev
```

## Smoke real do backend

```bash
cd server
dart run bin/sentry_smoke.dart
```

Ou em modo validacao completa:

```bash
./scripts/validate_sentry_backend_ingestion.sh
```

Saída esperada:

- `SENTRY_SMOKE_EVENT_ID=...`
- `SENTRY_SMOKE_TAG=smoke_id:...`

Esse `smoke_id` pode ser usado para localizar o evento no Sentry sem depender de texto da exceção.

Validação real executada em `2026-03-24`:

- `dart run bin/sentry_smoke.dart` -> evento enviado com sucesso
- `./scripts/validate_sentry_backend_ingestion.sh` -> ingestão confirmada por `event_id`
- último `event_id` observado localmente: `70168f941de24cf4923eb87bb6d38a5d`
- última tag de correlação gerada: `smoke_id:mtgia-smoke-19d2119aadd`

Esses valores servem como evidência da primeira ingestão real do backend nesta rodada.

## O que falta validar operacionalmente

- ingestão real no projeto Sentry do app
- finalizar o smoke mobile em device/toolchain real; tanto o build macOS local quanto a tentativa no emulador Android (`emulator-5554`) ficaram presos no ciclo nativo de compilação e nao devolveram `event_id`
- retry desta rodada em `macos` confirmou o mesmo bloqueio: mais de `60s` em build nativo, apenas com warnings do SDK Swift do `Sentry`, sem chegar à execução do teste
- a versao atual do smoke mobile ja classifica esse caso de forma repetível: em `macos`, com `MOBILE_SENTRY_BUILD_TIMEOUT_SECONDS=20`, o script encerrou com `SENTRY_MOBILE_TOOLCHAIN_BLOCKED=1` e `exit 124`
- no Android, o bloqueio de incompatibilidade Kotlin foi corrigido ao atualizar `org.jetbrains.kotlin.android` para `2.2.0` em `app/android/settings.gradle.kts`
- após esse ajuste, o smoke em `emulator-5554` deixou de falhar por compilação Kotlin incompatível, mas ainda nao concluiu dentro da janela de `240s`/`300s`, sem chegar a emitir `SENTRY_MOBILE_EVENT_ID`
- correlação manual de um erro entre:
  - app request
  - `x-request-id`
  - backend response
  - evento capturado
- release/versionamento por ambiente publicado
- documentação de EasyPanel com variáveis reais desse projeto

## Estado atual do `/ready`

O backend agora expõe:

- `GET /health`
  - liveness simples
- `GET /health/ready`
  - readiness detalhado histórico
- `GET /ready`
  - alias curto operacional para deploy, smoke e probes externos

Validação local executada em `2026-03-24`:

- `GET /health/ready` -> `200`
- `x-request-id` gerado automaticamente quando ausente
- `x-request-id` preservado quando enviado pelo cliente
- `GET /ready` publicado compartilhando a mesma lógica de readiness
- o smoke operacional repetível do domínio publicado ficou formalizado em:

```bash
./scripts/validate_request_id_ready.sh
```

O script exige uma URL explícita via uma destas variáveis no `server/.env`:

- `API_BASE_URL`
- `PUBLIC_API_BASE_URL`
- `EASYPANEL_DOMAIN`

Validação publicada executada nesta rodada:

- `bash scripts/validate_request_id_ready.sh` -> `READY_VALIDATION_OK=1`
- `/health`, `/health/ready` e `/ready` responderam `200`
- o mesmo `x-request-id` foi ecoado nas 3 respostas

## Próximo passo natural

Depois de fechar a rodada final do app core, a continuação correta desta frente é:

1. validar ingestão real do app em ambiente controlado
2. publicar o runbook operacional do `/ready`
3. formalizar o runbook EasyPanel do `mtgia`
4. só então ampliar para Redis/worker/heartbeat
