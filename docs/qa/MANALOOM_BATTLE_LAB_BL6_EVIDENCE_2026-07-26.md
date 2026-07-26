# Evidência BL6 — Live Spectator

- Data: 2026-07-26
- Resultado: `PASS_LOCAL_FEATURE_OFF_WITH_DEVICE_BLOCK`
- Transporte: `polling_long_polling`
- Storage durável: PostgreSQL migration 055

| Task | Estado | Evidência |
|---|---|---|
| BL6-01 | `PASS_LOCAL` | `battle_live_cursor_v1` entrega somente eventos/snapshots allowlisted, cursorados e novamente sanitizados no backend |
| BL6-02 | `PASS_LOCAL` | polling bounded escolhido; SSE/WebSocket adiados por ADR 0004 |
| BL6-03 | `PASS_LOCAL` | Flutter mostra job/progresso/engine, mesa pública, stack/combat e timeline; pausa é apenas local |
| BL6-04 | `PASS_LOCAL` | cursor HMAC, dedupe, checkpoint e `next_cursor` retomam sem duplicação; terminal abre replay |
| BL6-05 | `PASS_LOCAL` | offline/retry preserva estado; mudança de processo reread uma vez; timeout/5xx não fabricam terminal |
| BL6-06 | `PASS_LOCAL_CONTRACT` | sidecar limita 64 streams, 20 mil registros/stream e 15 min; poll/source/body possuem limites; carga no alvo não executada |
| BL6-07 | `BLOCKED_ANDROID_AND_LIVE` | Web/widget/auth/IDOR/reconexão passam; Android físico/TalkBack e smoke no alvo permanecem pendentes |

## Backend e segurança

- `BATTLE_LIVE_SPECTATOR_ENABLED=false` por padrão e 404 genérico antes do
  lookup;
- source timeout 2 s, corpo até 8 MiB, sem retry interno e com validação
  request/process identity;
- checkpoint/fingerprint internos nunca saem da API;
- backfill terminal lê replay persistido sem tratar o stream como checkpoint
  restaurável;
- privacidade/export/delete e readiness opt-in cobrem
  `battle_job_live_records`.

## App

- `ENABLE_BATTLE_LIVE_SPECTATOR=false` por padrão;
- rota `/decks/:id/battle-live/:jobId`;
- jobs recentes, retry idempotente, deep link e replay terminal;
- pause, buffer/jump latest, cancelamento em duas etapas, lifecycle e atalhos
  `Space`, `R`, `End`;
- nenhuma persistência Battle em `shared_preferences`.

## Validação

- backend focado/operacional: 57/57;
- PostgreSQL owner scope, IDOR, checkpoint, dedupe, restart e cascade: 1/1,
  também integrado ao gate oficial de schema;
- Flutter Battle antes da integração final: 95/95; telas finais: 35/35;
- Maven cobre registry bounded/eviction/paginação e identidade;
- build Web release local concluído com Live opt-in.

O endpoint e a tela estão implementados, mas rollout continua desligado e
release permanece `NO_GO`.
