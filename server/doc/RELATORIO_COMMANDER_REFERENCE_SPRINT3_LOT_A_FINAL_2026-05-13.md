# Commander Reference Sprint 3 Lote A Final - 2026-05-13

## Resultado final

**PASS_WITH_RISKS**, atualizado em 2026-05-14 com prova app runtime real.

O Lote A esta fechado para backend/public proof e agora tambem tem prova app
runtime real para dois comandantes promovidos de arquetipos diferentes. Os quatro
comandantes foram preparados, aplicados com idempotencia, provados 5/5 em
`POST /ai/generate` publico e promovidos para `ready_for_mini_batch`; em
2026-05-14, `Krenko, Mob Boss` e `Teysa Karlov` passaram por register/login,
Generate Commander com `commander_name`, preview, save, Deck Details e
`/decks/:id/validate` no Android fisico `SM A135M`.

O fechamento permanece **PASS_WITH_RISKS** porque a prova Android dependeu de
workaround ambiental de rede celular (o Wi-Fi do aparelho timeoutou no app para
`/health`) e o fallback iPhone 15 Simulator continua bloqueado por
`MLImage.framework`/scanner. Scanner, camera e OCR ficaram fora do escopo.

## Fontes locais lidas

- `server/doc/COMMANDER_REFERENCE_SPRINT3_PLAN_2026-05-13.md`
- `server/doc/COMMANDER_REFERENCE_SPRINT3_TRACKER_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_A_CORPUS_PREP_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_A_PUBLIC_PROOF_2026-05-13.md`
- `app/doc/runtime_flow_handoffs/commander_reference_sprint3_lot_a_app_2026-05-13.md`
- `app/doc/APP_AUDIT_2026-04-29.md`
- `app/doc/runtime_flow_handoffs/commander_reference_sprint3_lot_a_app_2026-05-14.md`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `server/manual-de-instrucao.md`

`server/doc/API_CONTRACTS_AND_DATA_MAP.md` foi consultado e nao foi alterado:
nao houve mudanca de rota, payload, response shape, diagnostics app-facing,
async job, data source ou consumidor mobile. `commander_name` e diagnostics de
Commander Reference continuam opcionais/backward-compatible.

## Escopo e seguranca

Incluido: consolidacao documental do fechamento, leitura dos relatorios Sprint 3
Lote A, runtime app real no Android primario, correcao segura do harness, API
map e manual; decisao de promocao do Lote A; recomendacao para o Lote B;
validacao com analyze/testes focados, `git diff --check` e scan local de
secrets.

Fora do escopo: alterar backend, repetir public proof completo, mudar contrato
app-facing, scanner/camera/OCR, persistir prompts completos, decklists
completas, tokens, JWT, Sentry DSN, `DATABASE_URL`, `OPENAI_API_KEY`, senhas ou
e-mails QA.

## Promovidos

| Commander | Cor | Arquetipo/tema | Corpus/apply | Public proof | p50 | p95 | Readiness | Promoted |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `Krenko, Mob Boss` | R | Goblin typal, go-wide tokens, haste/aggro | 4/4 decks aceitos; dry-run/apply/idempotencia PASS; unresolved=0; off_color=0; main 99 | PASS 5/5; timeout fallback 0/5; invalid/off-id 0 | 888ms | 1233ms | score 100, `ready_for_mini_batch` | true |
| `Light-Paws, Emperor's Voice` | W | Auras, Voltron, protection/evasion | 4/4 decks aceitos; dry-run/apply/idempotencia PASS; unresolved=0; off_color=0; main 99 | PASS 5/5; timeout fallback 0/5; invalid/off-id 0 | 873ms | 952ms | score 100, `ready_for_mini_batch` | true |
| `Niv-Mizzet, Parun` | UR | Spellslinger, draw-damage, control/combo lanes | 5/5 decks aceitos; dry-run/apply/idempotencia PASS; unresolved=0; off_color=0; main 99 | PASS 5/5; timeout fallback 0/5; invalid/off-id 0 | 857ms | 981ms | score 100, `ready_for_mini_batch` | true |
| `Teysa Karlov` | WB | Aristocrats, tokens, death triggers/sacrifice | 5/5 decks aceitos; dry-run/apply/idempotencia PASS; unresolved=0; off_color=0; main 99 | PASS 5/5; timeout fallback 0/5; invalid/off-id 0 | 856ms | 908ms | score 100, `ready_for_mini_batch` | true |

## App runtime 2026-05-14

| Item | Status | Evidencia | Impacto |
| --- | --- | --- | --- |
| App runtime Lote A fim a fim no `SM A135M` | PASS | `app/doc/runtime_flow_handoffs/commander_reference_sprint3_lot_a_app_2026-05-14.md` | Prova register/login -> Generate Commander -> preview -> save -> Deck Details -> validate para Krenko/Teysa no backend publico. |
| Krenko app/API | PASS | `validation_ok=true`, `main_qty=99`, `total_with_commander=100`, `commander_count=1`, `commander_in_99_count=0`, `off_identity_count=0` | Mono-red Goblins aggro provado no app. |
| Teysa app/API | PASS | `validation_ok=true`, `main_qty=99`, `total_with_commander=100`, `commander_count=1`, `commander_in_99_count=0`, `off_identity_count=0` | Orzhov aristocrats provado no app. |

## Bloqueados ou nao provados

| Item | Status | Evidencia | Impacto |
| --- | --- | --- | --- |
| Android Wi-Fi `SM A135M` | PASS_WITH_RISKS | No Wi-Fi, app timeoutou em `/health` apos 15s; no celular, `/health` e fluxo completo passaram. | Manter rede celular como workaround ate diagnosticar DNS/rede do Wi-Fi. |
| iPhone 15 Simulator | BLOCKED | Build bloqueado por arquitetura nativa MLImage/Scanner no simulador Apple Silicon. | Impede fallback iOS sem isolar/atualizar dependencia nativa. |

## App proof

Prova app real do Lote A: **PASS_WITH_RISKS**.

Fatos comprovados nos runtime handoffs:

- repo `master` sincronizado durante a rodada;
- backend publico respondeu `/health` com `status=healthy`;
- build/install Android do app passaram;
- Android fisico e iPhone 15 Simulator foram descobertos;
- harness especifico criado em
  `app/integration_test/commander_reference_sprint3_lot_a_app_runtime_test.dart`;
- em 2026-05-14, o harness foi corrigido para usar
  `runtime_test_helpers.dart` em vez de helpers locais duplicados;
- Krenko e Teysa foram selecionados para cobrir arquetipos distintos;
- Krenko e Teysa passaram no app real com 99 main, comandante unico fora das 99,
  100 cartas totais, `validation_ok=true` e 0 off-identity;
- nenhum scanner/camera/OCR foi usado.

Nao provado nesta atualizacao: iPhone 15 Simulator, porque o Android primario
passou e o blocker `MLImage.framework`/scanner permanece conhecido.

## Riscos remanescentes

1. **Ambiente Android:** runtimes publicos no `SM A135M` podem exigir rede
   celular enquanto o Wi-Fi local timeoutar HTTP app-side para o backend publico.
2. **Operacao:** se o deploy publico mudar de `git_sha`, repetir public proof
   antes de usar a evidencia para decisao de release.
3. **Qualidade Commander:** Niv-Mizzet e futuros comandantes high-power precisam
   manter lanes casual/combo/control explicitas para nao contaminar decks casuais.
4. **Dependencia iOS:** MLImage/Scanner segue bloqueando o target iOS Simulator;
   isso afeta testes mobile mesmo quando scanner esta fora do fluxo.
5. **Privacidade:** continuar salvando somente summaries sanitizados; nao gravar
   prompts completos, decklists completas, tokens, JWTs, e-mails QA ou env vars.

## Recomendacao GO/NO-GO para Lote B

**GO condicionado para iniciar o Lote B em modo backend/offline controlado.**

Autorizado para Lote B:

- preparar corpus offline e DB-backed para `Meren of Clan Nel Toth`,
  `Korvold, Fae-Cursed King` retry, `Sythis, Harvest's Hand` e
  `Urza, Lord High Artificer`;
- executar dry-run, apply controlado, apply de idempotencia, contagens DB-backed,
  public proof 5/5 e readiness scorecard por comandante;
- promover somente comandantes com `score=100`,
  `status=ready_for_mini_batch`, `runtime_public_gate_passed=true`,
  timeout fallback 0/5, unresolved=0, off_color=0, invalid=0 e core package forte.

**NO-GO para ampliar guidance sem ressalvas** se algum comandante do Lote B
repetir warning relevante, fallback de timeout, `score<100`,
`public_runtime_gate_not_passed` ou core package fraco. A prova app do Lote A
nao esta mais bloqueada no Android primario, mas deve manter o risco ambiental de
rede documentado.

## Proximo lote recomendado

| Prioridade | Commander | Cor | Tema | Risco principal | Guardrail minimo |
| ---: | --- | --- | --- | --- | --- |
| 5 | `Meren of Clan Nel Toth` | BG | Graveyard recursion, sacrifice value, toolbox creatures | Overlap com Muldrotha e loops high-power sem bracket explicito. | Corpus diferenciar BG recursion/toolbox, unresolved=0, off_color=0, public proof 5/5 sem fallback. |
| 6 | `Korvold, Fae-Cursed King` retry | BRG | Sacrifice, treasure, value/combo | Historico Sprint 2 com `core_package_weak` e timeout fallback 2/5. | So promover se core package sacrifice/treasure/value for forte, score 100 e timeout 0/5. |
| 7 | `Sythis, Harvest's Hand` | GW | Enchantress value | Colapsar com Light-Paws Voltron ou aura-goodstuff. | Separar enchantress value de Voltron, provar engine de draw/ramp/protection. |
| 8 | `Urza, Lord High Artificer` | U | Artifacts, control, combo | Vies high-power/cEDH/stax como default casual. | Lane casual/high-power explicita; excluir pecas proibidas; public proof sem fallback. |

## Decisao

Resultado final: **PASS_WITH_RISKS**.

Lote A backend/public proof esta fechado e promovido para mini-batch controlado,
com prova app real PASS_WITH_RISKS no Android primario. Lote B pode comecar em
modo controlado mantendo os mesmos gates de corpus, public proof e runtime app
antes de qualquer ampliacao de guidance.
