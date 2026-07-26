# Evidência BL4 — Homologação local do Battle Lab

- Data: 2026-07-26
- Resultado: `PARTIAL_BLOCKED_PHYSICAL_AND_RELEASE`
- Build Web: release, base `/app/`, sem CDN de recursos

| Task | Estado | Evidência |
|---|---|---|
| BL4-01 | `PASS_LOCAL` | contratos, migrations 052–055, pins e fixtures versionados; project logic regenerado e `--check` verde |
| BL4-02 | `PASS_LOCAL` | erros auth/owner, conflito, validação, quota, timeout, engine/persistência e truncamento possuem estados/retry fechados |
| BL4-03 | `PARTIAL_AUTOMATED_BLOCKED_DEVICE` | timeline 20k, payloads/limites e contratos de performance passaram; p50/p95 de list/detail/scrub/filtros/série em Web/Android alvo não foram medidos |
| BL4-04 | `PASS_LOCAL` | IDOR, cursor, hidden zones, body limits, rate limits, logs/redaction e soft delete testados |
| BL4-05 | `BLOCKED_ANDROID_PHYSICAL` | widget/Web, teclado, texto 200% e reduced motion cobertos; sem aparelho Android/TalkBack na rodada |
| BL4-06 | `PASS_LOCAL_AUTOMATED_BLOCKED_DEVICE_RELEASE` | `battle-lab` e schema PostgreSQL oficial fecharam na árvore final; mutações live, Android físico e release seguem não autorizados/não disponíveis |
| BL4-07 | `PASS_LOCAL_EVIDENCE` | esta evidência pertence ao commit da entrega; SHA/branch publicados e resultado do pre-push ficam no handoff final |

## Gates da árvore final

Resultados confirmados na árvore que forma o commit desta entrega:

- Flutter Battle antes da integração final: 95/95;
- telas Flutter finais: 35/35;
- matrizes UI/inventário: 11/11;
- Web de imagens: 5/5 e VM de imagens: 10/10;
- backend BL5: 86/86;
- backend BL6: 57/57;
- PostgreSQL BL5 migrations 001–055 + fault/concurrency/executor: verde;
- PostgreSQL BL6 owner/IDOR/checkpoint/dedupe/restart/cascade: 1/1;
- engine capabilities: 95/95; XMage strategy: 29/29;
- `quality_gate.sh battle-lab`: exit 0; backend, Flutter, Battle canônico,
  performance determinística, retenção e project logic verdes;
- `quality_gate.sh full`: duas execuções consecutivas com exit 0; cada rodada
  executou 39 lotes backend, análise Flutter sem issues, 1.252 testes Flutter
  + 1 skip declarado, lint/build de 13 rotas Web, audit de produção com
  0 vulnerabilidades e 17 contratos de performance;
- `manaloom_local_ci.sh schema`: exit 0; 77 tabelas, 6 views, 91 FKs e
  55 migrations conferem com o manifesto;
- o mesmo gate schema exercitou jobs, leases, métricas redigidas, owner/IDOR,
  dedupe, checkpoints, restart e cascade no PostgreSQL loopback descartável;
- project logic: 8 artefatos sincronizados e 17/17 testes do gerador,
  incluindo ordem de FK composta;
- build Web release com base `/app/`, sem CDN, servido em
  `http://127.0.0.1:8088/app/`.

O resultado do pre-push e o smoke final do artefato Flutter Web são registrados
no handoff do commit publicado. Qualquer skip de device/live permanece no
handoff e não muda automaticamente para PASS.

## Bloqueios

- nenhum Android físico estava disponível;
- nenhum alvo live foi autorizado para migration/deploy/smoke;
- same-SHA publicado, health/readiness implantado, Sentry/FCM e TalkBack
  continuam critérios de release.

Logo, a conclusão correta é local parcial e release `NO_GO`.
