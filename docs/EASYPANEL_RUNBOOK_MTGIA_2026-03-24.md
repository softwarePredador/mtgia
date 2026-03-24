# EasyPanel Runbook - MTGIA

> Runbook operacional inicial formalizado em `2026-03-24`.
> Baseado no padrão validado do `carMatch`, mas adaptado ao backend Dart Frog do `mtgia`.

## Estado atual

- backend containerizado em `server/Dockerfile`
- porta interna do app: `8080`
- readiness operacional disponível em:
  - `GET /health`
  - `GET /health/ready`
  - `GET /ready`
- `Sentry` backend já validado com ingestão real
- `Sentry` app implementado; ingestão real ainda depende do smoke mobile concluir em device/toolchain real

## Regra de segurança

- não versionar credenciais reais de EasyPanel, Sentry ou Postgres
- manter valores reais apenas no painel e em `.env` local ignorado
- usar este documento como contrato de nomes, sequência de deploy e validação

## Serviço backend

Arquivo-base:

- `server/Dockerfile`

Comportamento atual:

- build de produção via `dart_frog build`
- processo sobe com:
  - `dart build/bin/server.dart --hostname 0.0.0.0 --port ${PORT:-8080}`

No EasyPanel:

- o domínio deve apontar para HTTP `:8080`
- `PORT` pode ser injetado pelo painel; o container já faz fallback para `8080`

## Variáveis mínimas no EasyPanel

### Obrigatórias

- `ENVIRONMENT=production`
- `APP_VERSION=<git-sha-ou-versao>`
- `DB_HOST`
- `DB_PORT`
- `DB_NAME`
- `DB_USER`
- `DB_PASS`
- `JWT_SECRET`
- `RATE_LIMIT_DISTRIBUTED=true`

### Observabilidade

- `SENTRY_DSN`
- `SENTRY_ENVIRONMENT=production`
- `SENTRY_RELEASE=<git-sha-ou-versao>`
- `SENTRY_TRACES_SAMPLE_RATE=0.05`
- `SENTRY_ENABLE_LOGS=false`

### Operação / automação

- `SENTRY_AUTH_TOKEN`
- `SENTRY_ORG_SLUG`
- `SENTRY_TEAM_SLUG`
- `SENTRY_BACKEND_PROJECT_SLUG`
- `SENTRY_MOBILE_PROJECT_SLUG`
- `EASYPANEL_BASE_URL`
- `EASYPANEL_PROJECT_NAME`
- `EASYPANEL_APP_NAME`
- `EASYPANEL_DOMAIN`
- `EASYPANEL_AUTH_HEADER`
- `EASYPANEL_AUTH_SCHEME`
- `EASYPANEL_API_TOKEN`

### App Flutter

Essas variáveis não são lidas diretamente pelo app em runtime no EasyPanel, mas precisam existir no ambiente de release/build local ou CI:

- `SENTRY_MOBILE_DSN`
- `SENTRY_ENVIRONMENT`
- `SENTRY_RELEASE`
- `SENTRY_TRACES_SAMPLE_RATE`

## Ordem de deploy recomendada

1. Confirmar que `server/.env.example` e os secrets do painel estão alinhados.
2. Validar localmente:
   - `cd server && dart analyze`
   - `cd server && dart test`
   - `./scripts/quality_gate_resolution_corpus.sh`
3. Validar observabilidade:
   - `./scripts/validate_sentry_backend_ingestion.sh`
4. Subir/redeployar o serviço backend no EasyPanel.
5. Validar no domínio publicado:
   - `GET /health`
   - `GET /ready`
   - `GET /` com e sem `x-request-id`
6. Confirmar logs e ausência de segredos em payloads de erro.

## Smoke operacional pós-deploy

### Liveness e readiness

1. `GET /health`
2. `GET /health/ready`
3. `GET /ready`

Esperado:

- `200 OK`
- `x-request-id` presente na resposta
- quando enviado pelo cliente, o mesmo `x-request-id` deve voltar

### Observabilidade backend

1. rodar `./scripts/validate_sentry_backend_ingestion.sh`
2. confirmar:
   - `SENTRY_BACKEND_EVENT_ID=...`
   - `SENTRY_BACKEND_SMOKE_TAG=smoke_id:...`

### Fluxo core mínimo

1. autenticar com conta de teste
2. abrir deck existente
3. chamar optimize
4. confirmar preview/apply/validate

## Critério de pronto operacional

Para considerar o backend pronto para release via EasyPanel:

- `GET /ready` validado no domínio publicado
- `Sentry` backend validado com ingestão real
- `x-request-id` preservado ponta a ponta
- quality gate do corpus verde
- envs obrigatórias formalizadas

## Pendências restantes desta frente

- validar ingestão real do `Sentry` app em device/toolchain funcional
- enriquecer o `/ready` quando worker/fila entrarem na Sprint 3/4
- formalizar automação por API do EasyPanel se isso virar rotina
