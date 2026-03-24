# Checklist Final de Go-Live

## Core e UX
- [ ] Fluxo `criar -> analisar -> otimizar` validado ponta a ponta
- [ ] Onboarding de 3 passos validado em sessão limpa
- [ ] Estado vazio guiado com CTA principal testado

## Segurança e operação
- [ ] `ENVIRONMENT=production` aplicado
- [ ] `JWT_SECRET` forte e rotacionável
- [ ] Rate limiting distribuído ativo
- [ ] Política de logs sem segredos confirmada
- [x] `Sentry` backend validado com ingestão real
- [ ] `Sentry` app validado com ingestão real
- [ ] `x-request-id` ponta a ponta validado
- [x] `GET /ready` publicado e validado
- [x] Runbook EasyPanel publicado e conferido

Observações da rodada `2026-03-24`:
- ambiente publicado respondeu `200` em `GET /health` e `GET /ready`
- `x-request-id: manual-req-20260324` foi ecoado corretamente no response de `GET /ready`
- backend `Sentry` foi revalidado nesta rodada com ingestão real (`event_id=70168f941de24cf4923eb87bb6d38a5d`)
- o smoke operacional repetível do domínio publicado agora está formalizado em `scripts/validate_request_id_ready.sh`
- a execução desse smoke depende de `API_BASE_URL`, `PUBLIC_API_BASE_URL` ou `EASYPANEL_DOMAIN` preenchido no `server/.env`
- o smoke publicado foi validado com sucesso nesta rodada:
  - `/health` -> `200`
  - `/health/ready` -> `200`
  - `/ready` -> `200`
  - o mesmo `x-request-id` foi ecoado nas 3 respostas
- o smoke móvel agora encerra com timeout explícito e classifica bloqueio de toolchain com `SENTRY_MOBILE_TOOLCHAIN_BLOCKED=1`
- ainda falta fechar a validação ponta a ponta partindo do app e a ingestão real do app no `Sentry`
- o retry do smoke mobile em `macos` continuou preso no build nativo; a pendência do app segue sendo de toolchain/execução, não de integração de código
- o smoke mobile agora falha de forma classificável: em `macos` com timeout de `20s`, encerrou com `SENTRY_MOBILE_TOOLCHAIN_BLOCKED=1` e `exit 124`
- o bloqueio Android por Kotlin incompatível foi removido ao atualizar o KGP para `2.2.0`, mas o smoke em `emulator-5554` ainda não concluiu dentro da janela de `240s`/`300s`

## IA e custo
- [ ] Limites por plano Free/Pro ativos
- [ ] Retorno de paywall (`402`) validado
- [ ] Telemetria de uso/custo por usuário validada (`/users/me/plan`)

## Dados e sincronização
- [ ] `sync_cards.dart` incremental diário ativo
- [ ] `sync_rules.dart` rotina periódica ativa
- [ ] `sync_prices.dart` rotina periódica ativa
- [ ] `sync_state` e `sync_log` com últimas execuções OK

## Performance e escala
- [ ] Índices críticos aplicados (migrações até 012)
- [ ] Cache de endpoints quentes validado (`/cards`, `/sets`)
- [ ] Teste de carga básico executado (`bin/load_test_core_flow.dart`)
- [ ] `CAPACITY_PLAN_10K_MAU.md` revisado

## Qualidade
- [ ] `./scripts/quality_gate.ps1 quick` verde
- [ ] `./scripts/quality_gate.ps1 full` verde
- [ ] Sem erros de analyze/lint relevantes
