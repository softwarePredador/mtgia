# ManaLoom Product Readiness Runbook - 2026-07-06

## Pronto sem dependencias externas

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
  - app Flutter continua offline com `SharedPreferences` e sincroniza quando autenticado.
- Relatorios publicos:
  - `POST /decks/:id/reports`
  - `GET /reports/:id`
  - app tenta criar link publico ao compartilhar preview de otimizacao.
  - Next.js reativou `/reports/[id]` sem dados mockados.
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
curl -I https://evolution-manaloom-web-public.2ta7qx.easypanel.host/pricing
curl -I https://evolution-manaloom-web-public.2ta7qx.easypanel.host/reports/nao-existe
```

Esperado:

- health/ready respondem 200.
- pricing responde 200.
- report inexistente responde 404; report criado pelo app responde 200.
