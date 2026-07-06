# ManaLoom Product Readiness Runbook - 2026-07-06

## Pronto sem dependencias externas

- Backlog ativo:
  - `docs/MANALOOM_ACTIVE_PRODUCT_BACKLOG_2026-07-06.md`
  - todos os itens que estavam como "falta" foram movidos para
    `EM_ANDAMENTO`, `CONCLUIDO_PARCIAL` ou `EM_ANDAMENTO_BLOQUEADO_EXTERNO`.
- Billing interno protegido por feature flag:
  - `POST /users/me/plan/checkout`
  - ativa Pro somente com `MANALOOM_INTERNAL_CHECKOUT_ENABLED=true` ou `ALLOW_INTERNAL_PRO_ACTIVATION=true`.
  - sem flag e sem URL externa, retorna `payment_provider_not_configured`.
- Webhook de billing:
  - `POST /billing/webhook`
  - exige `MANALOOM_BILLING_PROVIDER` e `MANALOOM_BILLING_WEBHOOK_SECRET`.
  - valida HMAC SHA-256 em `x-manaloom-webhook-signature` ou `x-signature`.
  - nao ativa plano automaticamente ate o adaptador real do provedor ser implementado.
- Pos-jogo com sync:
  - `GET/POST /decks/:id/post-game-notes`
  - `DELETE /decks/:id/post-game-notes/:noteId`
  - `GET /decks/:id/post-game-timeline`
  - app Flutter continua offline com `SharedPreferences` e sincroniza quando autenticado.
- Comunidade e trade:
  - `GET/POST /community/decks/:id/comments`
  - `POST /community/decks/:id/reports`
  - `GET /community/trade-matches`
  - `GET /community/decks/:id` inclui `visual_analysis` e `comments_summary`.
- Relatorios publicos:
  - `POST /decks/:id/reports`
  - `GET /reports/:id`
  - app tenta criar link publico ao compartilhar preview de otimizacao.
  - Next.js reativou `/reports/[id]` sem dados mockados.
- Metricas comerciais e operacionais:
  - `GET /health/metrics`: latencia e erro por endpoint em memoria.
  - `GET /health/dashboard`: request metrics, IA e resumo comercial.
  - `GET /health/commercial`: funil, IA, planos, relatorios e retencao.
- Scripts operacionais:
  - `scripts/manaloom_product_smoke.sh`: smoke ponta a ponta no stack novo.
  - `scripts/manaloom_ai_generation_benchmark.sh`: benchmark real de
    `/ai/generate`, com contagem de mocks e status `pass/degraded`.
  - `scripts/manaloom_easypanel_backup.sh`: backup `pg_dump -Fc`.
  - `scripts/manaloom_validate_restore.sh`: restore em Postgres temporario.
- Hosts publicos default alinhados para:
  - API: `https://evolution-cartinhas.2ta7qx.easypanel.host`
  - web publico: `https://evolution-manaloom-web-public.2ta7qx.easypanel.host`

## Configurar quando dependencias externas existirem

- Dominio:
  - apontar `manaloom.com` para Next.js publico.
  - apontar `/app` para Flutter Web logado via rewrite/proxy.
  - configurar `NEXT_PUBLIC_SITE_URL=https://manaloom.com`.
  - configurar `MANALOOM_PUBLIC_SITE_URL=https://manaloom.com`.
- Pagamento:
  - escolher provedor e setar `MANALOOM_BILLING_PROVIDER`.
  - setar `MANALOOM_PRO_CHECKOUT_URL`, `MANALOOM_BILLING_SUCCESS_URL`, `MANALOOM_BILLING_CANCEL_URL`.
  - setar `MANALOOM_BILLING_WEBHOOK_SECRET` com segredo real do provedor.
  - implementar adaptador que transforma evento pago em `PlanService.activatePro(userId)`.
- Juridico:
  - revisar termos, privacidade e disclaimer antes de trafego publico pago.

## Validacao minima apos deploy

```bash
curl -fsS https://evolution-cartinhas.2ta7qx.easypanel.host/health
curl -fsS https://evolution-cartinhas.2ta7qx.easypanel.host/ready
curl -fsS https://evolution-cartinhas.2ta7qx.easypanel.host/health/commercial
curl -I https://evolution-manaloom-web-public.2ta7qx.easypanel.host/pricing
curl -I https://evolution-manaloom-web-public.2ta7qx.easypanel.host/reports/nao-existe
```

Esperado:

- health/ready respondem 200.
- commercial responde 200 com funil agregado, sem dados pessoais.
- pricing responde 200.
- report inexistente responde 404; report criado pelo app responde 200.

## Rotina operacional em andamento

```bash
scripts/manaloom_product_smoke.sh
MANALOOM_AI_BENCHMARK_RUNS=3 scripts/manaloom_ai_generation_benchmark.sh
scripts/manaloom_easypanel_backup.sh
scripts/manaloom_validate_restore.sh backups/manaloom-postgres/<arquivo>.dump
```

Para restore completo em ambiente temporario:

```bash
MANALOOM_RESTORE_MODE=full scripts/manaloom_validate_restore.sh backups/manaloom-postgres/<arquivo>.dump
```

O restore padrao usa `schema` para ser rapido em validacao recorrente. O modo
`full` deve ser usado em janela controlada ou maquina com espaco suficiente.

Evidencia de 2026-07-06:

- Backup real do Postgres novo gerado em `backups/manaloom-postgres/`.
- Restore schema validado em Postgres 17 temporario remoto.
- Resultado do restore: `80` tabelas publicas restauradas.
- Deploy backend final validado no SHA
  `7cd6fbf5eb99192bd7346933f4e3220734e1ec2e`.
- Smoke de produto final: `status=ok`.
- Benchmark de IA final: sem mock em producao; status pode ficar `degraded`
  quando a IA retorna deck invalido e a API responde 422, que e o
  comportamento esperado sem fallback mock.
