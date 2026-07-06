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
- serviço público atual:
  - projeto: `evolution`
  - app: `cartinhas`
  - source no novo servidor: `image`
  - imagem: `localhost:5000/manaloom/cartinhas:latest`
  - Dockerfile de origem: `server/Dockerfile`

### Nota operacional 2026-07-06

No novo servidor EasyPanel (`evolution-cartinhas.2ta7qx.easypanel.host`), o
serviço `evolution/cartinhas` está configurado como source `image`, não como
source Git. Portanto, chamar apenas `services.app.deployService` pelo EasyPanel
reinicia a imagem já pinada no Docker Swarm; isso não reconstrói o código do
`master`.

Fluxo correto para publicar backend nesse servidor:

1. Confirmar que `HEAD == origin/master` no checkout local.
2. Enviar apenas a árvore commitada de `server/` para o servidor:
   `git archive HEAD:server`.
3. No servidor, construir e publicar no registry local:
   `docker build -t localhost:5000/manaloom/cartinhas:<sha-curto> -t localhost:5000/manaloom/cartinhas:latest .`
   e `docker push` das duas tags.
4. Atualizar o service Swarm com update `stop-first`, porque a porta host
   `18080` impede start-first/zero-downtime em nó único:
   `docker service update --update-order stop-first --image localhost:5000/manaloom/cartinhas:latest ... evolution_cartinhas`.
5. Definir `GIT_SHA=<sha-completo>` e `SENTRY_RELEASE=<sha-completo>` no service.
6. Validar `/health`, `/ready`, `/health/ready`, request-id e banco.

Primeiro deploy image-based validado em 2026-07-06:

- commit: `02270f1c38adb8540cd4745418862d6374a96d34`
- imagem publicada: `localhost:5000/manaloom/cartinhas:02270f1c38ad`
- `/health.git_sha`: `02270f1c38adb8540cd4745418862d6374a96d34`
- `/ready`: `ready`, banco healthy, `card_count=34331`
- `scripts/validate_request_id_ready.sh`: `READY_VALIDATION_OK=1`

Se um commit posterior alterar apenas documentação fora de `server/`, não
reconstruir o binário por isso. Retaggear a imagem validada para o novo SHA e
atualizar `GIT_SHA`/`SENTRY_RELEASE` é suficiente para manter a prova pública de
`master` atual sem criar churn de rebuild.

### Nota operacional 2026-06-15

O serviço `evolution/cartinhas` já esteve configurado como source `github`
archive. Nesse modo, o EasyPanel falhava antes do build com:

```text
curl: (23) Failure writing output to destination
gzip: stdin: unexpected end of file
tar: Unexpected EOF in archive
```

A correção operacional aplicada foi trocar a source do app para `git`, mantendo o
mesmo repositório, branch `master` e path `/server`. Depois disso o build voltou a
passar (`dart_frog build`) e o deploy público confirmou o SHA esperado em
`GET /health`.

Se o erro de archive voltar em outro serviço, validar nesta ordem:

1. Confirmar espaço e saúde do host via painel.
2. Rodar `settings.systemPrune` pelo EasyPanel apenas se houver acúmulo de
   imagens antigas.
3. Preferir source `git` para este app, evitando o fluxo de GitHub archive.
4. Validar `GET /health` e `GET /ready` no domínio publicado.

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
4. Subir/redeployar o serviço backend no EasyPanel:
   - projeto `evolution`
   - app `cartinhas`
   - ação `services.app.deployService`
5. Validar no domínio publicado:
   - `bash scripts/validate_request_id_ready.sh`
   - `curl -fsS https://evolution-cartinhas.2ta7qx.easypanel.host/health`
   - `curl -fsS https://evolution-cartinhas.2ta7qx.easypanel.host/ready`
6. Confirmar logs e ausência de segredos em payloads de erro.

Precondição para o script:

- `API_BASE_URL`, `PUBLIC_API_BASE_URL` ou `EASYPANEL_DOMAIN` preenchido no `server/.env`

## Smoke operacional pós-deploy

### Liveness e readiness

1. `bash scripts/validate_request_id_ready.sh`

Esperado:

- `200 OK`
- `x-request-id` presente na resposta
- quando enviado pelo cliente, o mesmo `x-request-id` deve voltar

Status atual:

- `bash scripts/validate_request_id_ready.sh` já fechou verde no domínio publicado

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
