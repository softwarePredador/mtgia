# ADR 0004 — Polling e checkpoints duráveis do Live Spectator

- Estado: aceito
- Data: 2026-07-26
- Programa: `BL5–BL6`
- Rollout: desabilitado por padrão

## Contexto

O Live Spectator precisa mostrar progresso público enquanto o XMage executa sem
transformar o replay em checkpoint restaurável, sem expor zonas ocultas e sem
depender da memória de um processo para retomar a leitura. Pausar a interface
também não pode ser confundido com pausar o engine.

SSE/WebSocket adicionariam estado operacional antes de existir evidência de que
polling limitado é insuficiente. O sidecar XMage, por sua vez, consegue emitir
eventos incrementais, mas seu registro process-local não é fonte durável.

## Decisão

1. O transporte inicial é polling autenticado em
   `GET /ai/battle/jobs/:id/live`, com cursor HMAC opaco e limite fechado.
2. `battle_job_live_records`, criada pela migration 055, persiste registros
   públicos normalizados, fingerprints de deduplicação e checkpoints internos.
   PostgreSQL é a verdade durável.
3. O `BattleLiveRegistry` do sidecar XMage é transporte transitório e limitado:
   no máximo 64 streams, 20 mil registros por stream e 15 minutos de retenção.
4. Cada poll valida owner, job, engine, request e process identity. Mudança de
   processo permite uma releitura corretiva a partir de `after=-1`; fingerprint
   e sequência impedem duplicação pública.
5. O sidecar omite zonas ocultas e opções privadas. O backend aplica uma
   segunda allowlist antes de persistir ou responder.
6. O replay terminal persistido pode preencher registros públicos ausentes.
   Nenhum estado parcial é tratado como replay restaurável.
7. Pausar no Flutter pausa somente playback/renderização local; polling e
   engine continuam. Reconexão retoma pelo último cursor aceito.
8. Cancelamento continua cooperativo nos limites definidos pelo ADR 0002.

## Flags e falha fechada

- backend: `BATTLE_LIVE_SPECTATOR_ENABLED=false`;
- Flutter: `ENABLE_BATTLE_LIVE_SPECTATOR=false`.

Quando o backend está desligado, ele responde o mesmo 404 genérico antes de
consultar o job. Quando o app está desligado, ele não cria/lista jobs Live nem
inicia polling. Readiness do Live só é exigida quando o recurso está
explicitamente habilitado.

## Limites e privacidade

- um poll faz no máximo uma leitura bounded do sidecar;
- timeout padrão do source é 2 segundos;
- corpo do source é limitado a 8 MiB;
- o endpoint aceita `limit=1..100`;
- registros internos de checkpoint nunca entram na resposta;
- IDs de usuário, lease, request fingerprint e correlação interna não entram
  em eventos/métricas públicos;
- mão/biblioteca do oponente, prompts, opções e mensagens não allowlisted nunca
  são armazenados no stream público.

## Consequências

- refresh, queda de rede e restart do backend não perdem o progresso já
  persistido;
- o sidecar pode reiniciar sem virar fonte de verdade;
- polling adiciona latência de poucos segundos, aceitável para espectador;
- SSE/WebSocket ficam adiados até medição demonstrar benefício;
- Live continua somente leitura e não aproxima Coach Mode de um GO.

## Rollback e release

Desabilitar as duas flags remove a superfície sem apagar jobs, replays ou
registros públicos existentes. Migration/DDL live, deploy, carga no alvo,
Android físico/TalkBack e smoke autenticado da mesma SHA continuam sujeitos ao
contrato E2E e não são autorizados por este ADR.

## Provas

- `server/test/battle_live_cursor_contract_test.dart`
- `server/test/battle_live_source_client_test.dart`
- `server/test/battle_live_service_test.dart`
- `server/test/battle_live_store_live_test.dart`
- `services/xmage-sidecar/src/test/java/com/manaloom/xmage/BattleLiveRegistryTest.java`
- `app/test/features/battle/screens/battle_live_spectator_screen_test.dart`
- `docs/qa/MANALOOM_BATTLE_LAB_BL6_EVIDENCE_2026-07-26.md`
