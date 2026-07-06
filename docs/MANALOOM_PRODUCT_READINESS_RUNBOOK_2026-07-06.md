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
  - `GET /health/ai-history`: serie historica de requisicoes de IA por bucket
    `day` ou `hour`.
- Scripts operacionais:
  - `scripts/manaloom_product_smoke.sh`: smoke ponta a ponta no stack novo.
  - `scripts/manaloom_ai_generation_benchmark.sh`: benchmark real de
    `/ai/generate`, com contagem de mocks e status `pass/degraded`.
  - `scripts/manaloom_easypanel_backup.sh`: backup `pg_dump -Fc`.
  - `scripts/manaloom_validate_restore.sh`: restore em Postgres temporario.
  - `scripts/manaloom_install_remote_backup_cron.sh`: instala backup diario e
    validacao semanal de restore no EasyPanel novo.
  - `scripts/manaloom_commercial_quality_gate.sh`: health, ready, commercial,
    replica do servico, cron de backup, ultimo dump, smoke produto e benchmark
    de IA em uma unica saida `pass/fail`.
  - `scripts/manaloom_ai_paywall_e2e.sh`: cria usuario temporario, esgota o
    limite Free via `ai_logs`, valida `402` em generate/optimize/rebuild/explain
    e limpa o usuario.
  - `scripts/manaloom_mobile_authenticated_qa.sh`: roda QA autenticada no
    simulador iOS, cobre cadastro, superficies principais, planos/checkout/legal
    e paywall visual.
  - `scripts/manaloom_deploy_backend_image.sh`: publica o backend via imagem no
    registry local do EasyPanel novo e atualiza `evolution_cartinhas`.
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
curl -fsS 'https://evolution-cartinhas.2ta7qx.easypanel.host/health/ai-history?days=30&bucket=day'
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
scripts/manaloom_ai_paywall_e2e.sh
scripts/manaloom_easypanel_backup.sh
scripts/manaloom_validate_restore.sh backups/manaloom-postgres/<arquivo>.dump
scripts/manaloom_install_remote_backup_cron.sh
MANALOOM_AI_BENCHMARK_RUNS=3 scripts/manaloom_commercial_quality_gate.sh
```

Para restore completo em ambiente temporario:

```bash
MANALOOM_RESTORE_MODE=full scripts/manaloom_validate_restore.sh backups/manaloom-postgres/<arquivo>.dump
```

O restore padrao usa `schema` para ser rapido em validacao recorrente. O modo
`full` deve ser usado em janela controlada ou maquina com espaco suficiente.

Evidencia de 2026-07-06:

- Backup remoto automatico instalado no EasyPanel novo:
  `17 2 * * * ... # manaloom-postgres-backup`.
- Validacao remota de restore instalada:
  `47 3 * * 0 ... # manaloom-postgres-restore-check`.
- Backup real do Postgres novo:
  `/opt/manaloom/backups/postgres/manaloom-postgres-20260706T173318Z.dump`.
- Tamanho validado: `279087037` bytes.
- Restore `schema` validado em Postgres 17 temporario remoto.
- Restore `full` validado em Postgres 17 temporario remoto.
- Resultado dos restores: `82` tabelas publicas restauradas.
- Deploy backend final validado no SHA
  `076ba55a6e9f7a1f00d5c2dfd59065e1c4c8463c`.
- Smoke de produto final: `status=ok`.
- Quality gate comercial:
  `docs/qa/runtime/manaloom-commercial-quality-gate-20260706T175234Z/summary.json`
- Deploy backend QA final validado no SHA
  `361c6f27e0064e04eb82b74ad3c4b1b2d17f4240`.
- QA mobile autenticado:
  `docs/qa/runtime/mobile-authenticated-qa-20260706T181142Z/summary.json`.
- Paywall autenticado de IA:
  `docs/qa/runtime/ai-paywall-e2e-20260706T182103Z/summary.json`.
- Quality gate comercial com historico de IA:
  `docs/qa/runtime/manaloom-commercial-quality-gate-20260706T182123Z/summary.json`.
  com `status=pass`, `service_replicas=1/1`, `successful_runs=2`,
  `mock_response_count=0`, `cron_lines=2` e `issues=[]`.
- Login Flutter Web local validado em
  `http://127.0.0.1:8088/app/#/login`, sem `RangeError` e sem erros de console.
