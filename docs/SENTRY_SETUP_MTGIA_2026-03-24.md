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
- último `event_id` observado localmente: `2e20bce6e7244d089e6ce59f88166bf8`
- última tag de correlação gerada: `smoke_id:mtgia-smoke-19d20a4744a`

Esses valores servem como evidência da primeira ingestão real do backend nesta rodada.

## O que falta validar operacionalmente

- ingestão real no projeto Sentry do app
- finalizar o smoke mobile em device/toolchain real; o build macOS local está operacional, mas ainda ficou preso no ciclo nativo de compilação e não devolveu `event_id`
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

## Próximo passo natural

Depois de fechar a rodada final do app core, a continuação correta desta frente é:

1. validar ingestão real do app em ambiente controlado
2. publicar o runbook operacional do `/ready`
3. formalizar o runbook EasyPanel do `mtgia`
4. só então ampliar para Redis/worker/heartbeat
