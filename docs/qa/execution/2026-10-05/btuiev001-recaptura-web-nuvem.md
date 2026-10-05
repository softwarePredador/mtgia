# Receipt de trabalho — BT-UIEV-001: ajustes do gate e recaptura Web na nuvem

Status: `PARCIAL · GATE_NAO_FECHADO · 15/23_MANIFESTS_NO_DIGEST_CORRENTE`

Não autoriza merge, deploy, migration, DML live, capability `ON` nem promoção
de deck/regra. `docs/qa/ui-live/latest.json` ficou intocado de propósito: ele só
pode ser reescrito quando os 23 manifests estiverem no mesmo digest.

## Identidade

- Base: `master` em `d34d450f8` (integração `71ab7bdf` + correções do #21)
- Digest de UI antes: `8bba809c…` (22/23 manifests nele; faltava o Jogar contra IA)
- Digest de UI depois dos ajustes: `4fc91724eb8a8f8a64e53725dd245086c3689c06ec2e0ecd63c0fe6ece6637af`
- Ambiente: container Linux x86_64 na nuvem, sem KVM; Flutter pinado `3.44.6`
  (Dart `3.12.2`), Chromium `141.0.7390.37` (Playwright) com ChromeDriver
  `141.0.7390.37` do Chrome for Testing via `MANALOOM_CHROMEDRIVER_BIN`, sob
  `xvfb-run`; Java 17, XMage pinado e PostgreSQL 16 de loopback descartável
- Agente: Claude Code (Anthropic)
- Autorização: o dono aprovou em 2026-10-05, no card da thread de captura, os
  três ajustes abaixo e o uso da frase de aprovação só para o PostgreSQL, a API
  e o XMage descartáveis deste container

## Ajustes no gate (todos dentro do digest de UI)

1. `scripts/manaloom_play_vs_ai_e2e.sh` (D-80): o nome do navegador deixou de
   ser o literal `Codex in-app Chromium`. A corrida declara agente e navegador
   em `MANALOOM_PLAY_VS_AI_BROWSER_NAME`, que vai para o contrato de dispositivo,
   para o `browser-ready.json` e para a checagem da conclusão. Sem o valor, o
   modo browser falha fechado.
2. `scripts/manaloom_server_contract_e2e_isolated.sh`: a guarda
   `BLOCKED: build output has a consumer` espera até 30 s pela liberação de
   `server/build` antes de bloquear (corrida de handoff de 2026-09-21). Ela
   continua fechada se o consumidor não sair.
3. `scripts/manaloom_ui_live_evidence_gate.sh`: `--index-p0-matrix` aceita
   `MANALOOM_P0_INDEX_SCOPE=web|android|all` (padrão `all`, comportamento
   anterior). Com `web`, indexa os três perfis Web sem atestar Android; com
   `android`, só o perfil Android. O agregado continua exigindo os quatro.

## Recaptura

| pacote | perfis | telas | resultado |
| --- | --- | --- | --- |
| 02 collection-import | 3 | 21 | `PASS_RUNTIME` em `4fc91724` |
| 03 deck-workshop | 3 | 36 | `PASS_RUNTIME` em `4fc91724` |
| 05 social-trade | 3 | 48 | `PASS_RUNTIME` em `4fc91724` |
| 06 onboarding-intent | 3 | 15 | `PASS_RUNTIME` em `4fc91724` |
| 07 visual-system | 3 | 30 | `PASS_RUNTIME` em `4fc91724` |
| 08 critical-overlays | 3 | — | não capturado (ver abaixo) |

As 150 telas foram abertas em 15 pranchas de contato, uma por manifest. Nenhum
bloqueio novo. Seguem os follow-ups já registrados: miniaturas de fallback nas
cartas do Fichário, truncamento de títulos longos no clamp (`Marina —
Arquivista de Co…`, `Izzet Phoenix…`), telas desktop/wide com estado único
subutilizando o canvas, e o pack 05 mostrando Marketplace, `Venda`, `Compra` e
preços, que segue rotulado como evidência de capability futura (D-40, C17).

## O que não fechou, e por quê

- **08 critical-overlays:** o script roda a suíte de widgets antes de capturar,
  e o golden `goldens/deck_gallery_card_1880.png` falha no Linux com 1,28% de
  pixels diferentes (baseline gerada no macOS). É a mesma classe dos 4 goldens
  que já falhavam no Linux. Recapturar no Mac.
- **P0 Web (3 perfis) e `play-vs-ai-web-real`:** os dois dependem de
  `manaloom_server_contract_e2e_isolated.sh`, que só tem guarda de egress
  loopback-only para macOS (`sandbox-exec`) e responde
  `BLOCKED: não há guard de egress loopback-only suportado neste sistema` no
  Linux. A guarda está certa; falta um equivalente Linux, que é decisão à parte.
- **P0 Android:** exige emulador ou aparelho, e este container não tem KVM.

Com isso, 15 dos 23 manifests do agregado estão em `4fc91724`. Os 8 restantes
(critical overlays ×3, P0 ×4 e Jogar contra IA) ficam para a sessão no Mac,
no mesmo digest, desde que nada no escopo de `manaloom_ui_source_digest.sh`
mude antes. Depois disso, a revisão visual completa reescreve o `latest.json`.

## Para a sessão no Mac

```bash
./scripts/manaloom_critical_overlays_states_visual_qa.sh
# matriz P0: fixture autenticada + manaloom_p0_runtime_capture.sh nos 4 perfis,
# depois --index-p0-matrix (scope all)
MANALOOM_PLAY_VS_AI_BROWSER_NAME="<agente> via <navegador>" \
MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_PLAY_VS_AI_BROWSER_QA=1 ./scripts/manaloom_play_vs_ai_e2e.sh
```

O `play-vs-ai-web-real` atual precisa ser arquivado antes (o runner recusa
diretório existente). Confira `./scripts/manaloom_ui_source_digest.sh` igual a
`4fc91724…` antes de começar.
