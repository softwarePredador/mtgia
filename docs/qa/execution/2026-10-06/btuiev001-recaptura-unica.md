# Receipt de trabalho — BT-UIEV-001: recaptura única dos 23 manifests

Status: `PASS · 23/23_MANIFESTS_NO_DIGEST_CORRENTE · latest.json REESCRITO`

Não autoriza merge, deploy, migration, DML live, capability `ON` nem promoção
de deck/regra.

## Identidade

- Base: `master` em `45b7ccdf2` (PRs #20, #22 e #25), depois `4931dd2a` (#26)
- Digest de UI: `a6b70b7b2db3a2ad3c0969da143bb435c01c389de39f9f55f263cbb8f593824f`
- Mudança no escopo do digest feita nesta rodada: só
  `app/integration_test/deck_workshop_visual_runtime_proof_test.dart:549`
  (`findsOneWidget` → `findsAtLeastNWidgets(1)`). Desde o BT-UX-IMG-001 o
  fallback de arte do comandante selecionado também escreve o nome.
- Ambiente: Mac mini arm64, Flutter `3.44.6`, Chrome for Testing
  `153.0.8010.52` headless com ChromeDriver `153.0.8010.52`, AVD
  `manaloom_api34` headless, PostgreSQL 17.9 local em `127.0.0.1:5432`
- Agente: Claude Code (Anthropic). As corridas com as frases de confirmação
  (fixture P0 e Jogar contra IA) foram coladas pelo dono no Terminal.

## Rede durante as capturas

As capturas Web rodaram num Chrome for Testing restrito por
`--host-resolver-rules`: só resolve loopback e `fonts.gstatic.com`. A primeira
tentativa usou `sandbox-exec` só-loopback, mas isso também bloqueava as fontes
do Flutter Web e deixava invisível todo texto `monospace` (o exemplo de
"FORMATOS ACEITOS" no pack 02). As capturas de 2026-10-05 em `4fc91724` tinham
o mesmo defeito e foram todas substituídas aqui.

## Achados do Jogar contra IA

(a) Duas sessões terminaram em "Motor indisponível" com
`IllegalArgumentException` no Turno 4 pré-combate, logo depois de passar a
prioridade. Os logs do XMage e da API isolada não registram a exceção. A
corrida validada atacou no turno 3 e não chegou a esse ponto. Causa em aberto.

(b) Uma sessão foi encerrada por abandono porque o prompt de 60 s expirou
enquanto o driver esperava. É o comportamento esperado do produto.

(c) A tela de replay ainda se chama "Battle Lab" e mostra "Partida cancelada ·
sem resultado" para uma partida concedida (follow-up P1 já registrado).

(d) As cartas aparecem como placeholder de nome sem arte, porque o navegador
restrito não alcança a Scryfall.

(e) O console da página foi amostrado depois de um reload, com 0 erros, mas não
foi gravado durante a partida inteira. Os erros do log do processo do Chrome
são de display link headless e do component updater, sem relação com a página.

## Resultado

| manifest | perfis | telas | resultado |
| --- | --- | --- | --- |
| 02 collection-import | Web ×3 | 7 cada | `PASS_RUNTIME` |
| 03 deck-workshop | Web ×3 | 12 cada | `PASS_RUNTIME` |
| 05 social-trade | Web ×3 | 16 cada | `PASS_RUNTIME` |
| 06 onboarding-intent | Web ×3 | 5 cada | `PASS_RUNTIME` |
| 07 visual-system | Web ×3 | 10 cada | `PASS_RUNTIME` |
| 08 critical-overlays | Web ×3 | 22 cada | `PASS_RUNTIME` |
| P0 | Web 390/1440/1920 | 54/53/53 | `PASS_RUNTIME` |
| P0 | `android_emulator_manaloom_api34` | 54 | `PASS_RUNTIME` |
| `play-vs-ai-web-real` | Web 1440x900 | 9 | `PASS_RUNTIME` + `PASS_VISUAL_REVIEWED` |

Total: 439 capturas (385 Web, 54 Android). Todas foram abertas, sem bloqueio.
`./scripts/manaloom_ui_live_evidence_gate.sh --check` e
`./scripts/quality_gate.sh ui-proof` passaram.

### P0 refeita depois do #26

Na primeira corrida, a P0 Android caiu no `--index-p0-matrix` com 42 entradas
`CachedCardImage falha` (404 de `cards.scryfall.io`). O `normalizeScryfallImageUrl`
trocava a URL loopback da fixture por uma URL do CDN derivada do `scryfall_id`
sintético. O #26 (`4931dd2a`) mantém URLs loopback no runtime E2E isolado. As
quatro P0 foram refeitas na mesma fixture (`20261007T113705Z_12853_5392`), com
HEAD em `4931dd2a` e o digest conferido antes da captura. O log Android ficou
com zero requisições a `cards.scryfall.io` e zero entradas proibidas. Cleanup
da fixture: `pass`, banco removido.

### Jogar contra IA

Relatório `20261006T143054Z_71786_14098`: `result=pass`, browser QA `pass`,
cleanup ok. Sessão `9c7220fc…` concedida, com replay.

## Follow-ups

Os já registrados seguem: canvas subutilizado em desktop/wide, truncamento de
nomes longos, Marketplace/Compra/Venda como evidência de capability futura
(D-40), recuperação de comandante isolada e "Battle Lab" no replay. Novos:
o `IllegalArgumentException` do achado (a) e a concessão rotulada como
cancelada do achado (c).

TalkBack humano, hardware Android e teclado Web real continuam verificações de
release separadas.
