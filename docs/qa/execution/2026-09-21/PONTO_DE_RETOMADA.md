# Ponto de retomada — pausa geral de 2026-09-21

Documento de **estado**, não de autoridade. Não autoriza PR, merge, deploy,
migration, DML live, capability `ON`, atualização de pin nem promoção de
deck/regra. Escrito ao encerrar a sessão a pedido do dono, para economizar
tokens.

## Commits que já estão no `origin`

Branch `codex/free-beta-release-candidate-2026-07-17`:

| SHA | o que fecha |
| --- | --- |
| `07014b431` | gate amplo sem falha de teste; 5 defeitos corrigidos |
| `d26f23a16` | conserta o que o gate contornado teria pego (revisão adversarial) |
| `b397f477b` | pin único de ChromeDriver + 216 screenshots recapturados |
| `9a9ba66de` | perfil Android capturado — o AVD é que estava quebrado |
| `d08c18717` | asserção do E2E de play-vs-ai que nunca pôde passar |

## `BT-UIEV-001` — 22 de 23

Digest de UI corrente: **`8bba809c`**. Recalcular sempre com
`./scripts/manaloom_ui_source_digest.sh` e `git status` limpo antes de
capturar; não confiar em valor congelado numa árvore compartilhada.

| artefato | estado |
| --- | --- |
| 18 packs web, 216 screenshots | `PASS_RUNTIME` em `8bba809c` |
| `p0-matrix` web mobile/desktop/wide | `PASS_RUNTIME` em `8bba809c` |
| `p0-matrix` android emulator | `PASS_RUNTIME` em `8bba809c`, zero falhas de console |
| `play-vs-ai-web-real` | **`865e6041`, defasado** |
| `docs/qa/ui-live/latest.json` | **intocado de propósito** |

`latest.json` é a atestação agregada: só pode ser reescrito quando os 23
manifests que referencia estiverem todos no digest corrente. Atestar conjunto
incompleto seria falsificar evidência.

### O que falta, em ordem

1. **Corrida de handoff no E2E.** `manaloom_play_vs_ai_e2e.sh` invoca
   `manaloom_server_contract_e2e_isolated.sh` duas vezes. A segunda para em
   `BLOCKED: build output has a consumer`
   (`manaloom_server_contract_e2e_isolated.sh:353-365`) porque o servidor da
   primeira ainda não soltou `server/build`. Medido: logo após a falha,
   `lsof +D server/build` não devolve nada. Reproduzido 2×. A guarda está
   certa; falta o estágio esperar a liberação.
2. Com isso resolvido, recapturar `play-vs-ai-web-real` (arquivar a evidência
   antiga em `docs/qa/ui-live/reference/` primeiro — o script recusa
   sobrescrever, e **recria a pasta vazia antes de falhar**, então conferir e
   remover antes de cada nova tentativa).
3. Reler as capturas do pack recapturado (`reviewer_must_open_every_screenshot`).
4. Escrever `latest.json` com os 23 manifests, `source_digest` corrente, os 10
   critérios e os hashes revisados.

### Correção de uma linha, represada pelo digest

`app/lib/features/battle/services/interactive_battle_service.dart:265-275` não
traduz `interactive_battle_not_waiting` — o erro que o servidor devolve em
duplo toque ou rede lenta. O jogador vê *"Não foi possível atualizar a mesa."*
em vez de *"A mesa avançou antes desta escolha. O estado será atualizado."*
Acrescentar `'interactive_battle_not_waiting' ||` ao mesmo ramo do
`action_stale`. **Mexer em `app/lib` move o digest e invalida os 216
screenshots** — fazer depois de `latest.json` fechar, ou aceitar recapturar.

## `BT-SCP-001` — aceite ainda aberto

O gate amplo **não** foi alcançado. Ordem real dos bloqueios:

1. `quality_gate.sh full` → `npm audit` do web público. `next` **critical**
   (RCE não autenticado) e `sharp` **high**, ambos resolvidos por
   `next@15.5.25`. `web-public/package.json` fixa `"next": "15.5.21"` exato e
   força `overrides.sharp: "0.35.3"`. **Aguarda decisão do dono** — foi
   relatado por outra sessão que ele autorizou, mas autorização repassada por
   terceiro não foi aceita; precisa vir dele direto.
2. `quality_gate.sh ui-audit` → `ui_live_evidence`, ou seja `BT-UIEV-001`.
3. `custom-lint`, `patrol-smoke`, `dependency-audit`: **nunca exercitados**.

O que **está** provado é o contrato que a ficha define: bootstrap frio roda, a
suíte de project-logic passa dentro dele, e a deriva entre a lista do bootstrap
e a da validação falha por mutação nas duas direções.

## Decisões paradas com o dono

| # | decisão |
| --- | --- |
| 1 | bump do `npm audit` (`next` 15.5.25, `overrides.sharp` 0.35.4) |
| 2 | **C17** — pack 05 apresenta marketplace, `R$` e CTAs de compra como superfície ativa, com `marketplace` e `trades` em `allowed=false`. Não é falha de gating (o pack monta `MarketplaceTabContent` direto, sem passar pelo router, onde `/marketplace` tem `redirect`). Opções: manter, marcar como evidência de capability futura, ou aposentar |
| 3 | `interactive_battle_not_waiting` no app — a correção de uma linha acima |

## Estado da máquina ao encerrar

| recurso | estado |
| --- | --- |
| PostgreSQL 17 ad hoc em `127.0.0.1:5432` | **derrubado** |
| bancos `manaloom_s1_api_*` descartáveis | nenhum sobrou; as fixtures limparam |
| emulador Android / `netsimd` / `qemu` | mortos |
| fixture autenticada isolada | encerrada com `exit 0` nas três vezes |
| ChromeDriver em cache | `153.0.8010.52`, permanente e pinado |
| AVD `ManaLoom_API34` | **dados apagados** por `-wipe-data`; foi o que consertou a rede |

Para subir o Postgres de novo (precisa de locale válido, senão
`postmaster became multithreaded during startup`):

```bash
LC_ALL=en_US.UTF-8 /opt/homebrew/opt/postgresql@17/bin/pg_ctl -D /opt/homebrew/var/postgresql@17 -l /tmp/pg17.log -o "-p 5432 -c listen_addresses=127.0.0.1" start
```

## Árvore ao encerrar — o que NÃO é deste trabalho

Não commitar junto sem falar com a sessão dona:

- `server/routes/community/marketplace/index.dart` (modificado) e
  `server/test/community_marketplace_privacy_contract_test.dart` (novo) —
  correção de vazamento de visibilidade, de outra sessão;
- `docs/generated/CURRENT_SYSTEM.md`, `TASK_REGISTRY.json`,
  `openapi.generated.json`, `project_logic_manifest.json` — regeneração que
  **acompanha** aquela rota. `--check` diz sincronizado;
- `docs/design/` — de outras duas sessões.

## Duas lições da rodada, para não se repetirem

**Ferramenta pinada só protege quem passa por ela.** O `flutter` do PATH
rebaixou `app/pubspec.lock` duas vezes em um dia — uma por mim, uma por outra
sessão — e como o lockfile está no escopo do digest, a segunda vez quase
produziu 216 capturas atestando um estado de origem inexistente. Sempre
`~/.manaloom/toolchains/flutter-3.44.6/bin/flutter … --no-pub --no-version-check`.

**Teste que não roda não protege.** Dois casos no mesmo dia: o `full` nunca
cobriu `app/integration_test/` (158 arquivos), e o E2E de play-vs-ai exige seis
variáveis de ambiente simultâneas para rodar — esteve vermelho desde que
nasceu, em 2026-09-18, sem nenhum sinal.
