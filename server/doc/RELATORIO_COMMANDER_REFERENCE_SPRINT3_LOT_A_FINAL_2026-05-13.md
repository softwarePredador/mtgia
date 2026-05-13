# Commander Reference Sprint 3 Lote A Final - 2026-05-13

## Resultado final

**PASS_WITH_RISKS.**

O Lote A esta fechado parcialmente para backend/public proof: os quatro
comandantes foram preparados, aplicados com idempotencia, provados 5/5 em
`POST /ai/generate` publico e promovidos para `ready_for_mini_batch`.

O fechamento nao vira **PASS** porque a prova app runtime real ficou **BLOCKED**
por ambiente/device antes de provar register/login -> Generate Commander -> save
-> Deck Details -> validate no app. Scanner, camera e OCR ficaram fora do escopo.

## Fontes locais lidas

- `server/doc/COMMANDER_REFERENCE_SPRINT3_PLAN_2026-05-13.md`
- `server/doc/COMMANDER_REFERENCE_SPRINT3_TRACKER_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_A_CORPUS_PREP_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_A_PUBLIC_PROOF_2026-05-13.md`
- `app/doc/runtime_flow_handoffs/commander_reference_sprint3_lot_a_app_2026-05-13.md`
- `app/doc/APP_AUDIT_2026-04-29.md`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `server/manual-de-instrucao.md`

`server/doc/API_CONTRACTS_AND_DATA_MAP.md` foi consultado e nao foi alterado:
nao houve mudanca de rota, payload, response shape, diagnostics app-facing,
async job, data source ou consumidor mobile. `commander_name` e diagnostics de
Commander Reference continuam opcionais/backward-compatible.

## Escopo e seguranca

Incluido: consolidacao documental do fechamento parcial, leitura dos relatorios
Sprint 3 Lote A, runtime app, API map e manual; decisao de promocao do Lote A;
recomendacao para o Lote B; validacao documental com `git diff --check` e scan
local de secrets.

Fora do escopo: alterar runtime app/backend, repetir public proof, executar
runtime mobile pesado, scanner/camera/OCR, persistir prompts completos,
decklists completas, tokens, JWT, Sentry DSN, `DATABASE_URL`, `OPENAI_API_KEY`,
senhas ou e-mails QA.

## Promovidos

| Commander | Cor | Arquetipo/tema | Corpus/apply | Public proof | p50 | p95 | Readiness | Promoted |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `Krenko, Mob Boss` | R | Goblin typal, go-wide tokens, haste/aggro | 4/4 decks aceitos; dry-run/apply/idempotencia PASS; unresolved=0; off_color=0; main 99 | PASS 5/5; timeout fallback 0/5; invalid/off-id 0 | 888ms | 1233ms | score 100, `ready_for_mini_batch` | true |
| `Light-Paws, Emperor's Voice` | W | Auras, Voltron, protection/evasion | 4/4 decks aceitos; dry-run/apply/idempotencia PASS; unresolved=0; off_color=0; main 99 | PASS 5/5; timeout fallback 0/5; invalid/off-id 0 | 873ms | 952ms | score 100, `ready_for_mini_batch` | true |
| `Niv-Mizzet, Parun` | UR | Spellslinger, draw-damage, control/combo lanes | 5/5 decks aceitos; dry-run/apply/idempotencia PASS; unresolved=0; off_color=0; main 99 | PASS 5/5; timeout fallback 0/5; invalid/off-id 0 | 857ms | 981ms | score 100, `ready_for_mini_batch` | true |
| `Teysa Karlov` | WB | Aristocrats, tokens, death triggers/sacrifice | 5/5 decks aceitos; dry-run/apply/idempotencia PASS; unresolved=0; off_color=0; main 99 | PASS 5/5; timeout fallback 0/5; invalid/off-id 0 | 856ms | 908ms | score 100, `ready_for_mini_batch` | true |

## Bloqueados ou nao provados

| Item | Status | Evidencia | Impacto |
| --- | --- | --- | --- |
| App runtime Lote A fim a fim | BLOCKED | `app/doc/runtime_flow_handoffs/commander_reference_sprint3_lot_a_app_2026-05-13.md` | Nao ha prova app real para Generate -> save -> Deck Details -> validate com Krenko/Teysa nesta rodada. |
| Android fisico `SM A135M` | BLOCKED | Build/install e `/health` passaram, mas o runner travou apos redirect para `/login`; harness antigo reproduziu o sintoma. | Bloqueio ambiental/device, nao falha comprovada do contrato Lote A. |
| iPhone 15 Simulator | BLOCKED | Build bloqueado por arquitetura nativa MLImage/Scanner no simulador Apple Silicon. | Impede fallback iOS sem isolar/atualizar dependencia nativa. |
| Deck Details/validate via app | not proven nesta rodada | O fluxo bloqueou antes da primeira interacao UI. | Manter a prova app como requisito antes de declarar PASS completo de produto. |

## App proof

Prova app real do Lote A: **BLOCKED**.

Fatos comprovados no runtime handoff:

- repo `master` sincronizado durante a rodada;
- backend publico respondeu `/health` com `status=healthy`;
- build/install Android do app passaram;
- Android fisico e iPhone 15 Simulator foram descobertos;
- harness especifico criado em
  `app/integration_test/commander_reference_sprint3_lot_a_app_runtime_test.dart`;
- Krenko e Teysa foram selecionados para cobrir arquetipos distintos;
- nenhum scanner/camera/OCR foi usado.

Nao provado no app nesta rodada: register/login real, chamada Generate Commander
via UI com `commander_name`, preview, save, Deck Details, comandante unico fora
das 99, 100 cartas totais, `validation_ok=true`, ausencia de overflow/modal
preso e ausencia de problemas visuais no fluxo.

## Riscos remanescentes

1. **Produto/app:** Lote A nao tem PASS completo de runtime mobile nesta rodada;
   qualquer comunicacao de produto deve citar backend/public proof, nao app proof.
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

**NO-GO para declarar PASS completo de produto ou ampliar guidance sem ressalvas**
enquanto o app runtime Lote A continuar bloqueado. O Lote B tambem deve bloquear
qualquer comandante que repetir warning relevante, fallback de timeout,
`score<100`, `public_runtime_gate_not_passed` ou core package fraco.

## Proximo lote recomendado

| Prioridade | Commander | Cor | Tema | Risco principal | Guardrail minimo |
| ---: | --- | --- | --- | --- | --- |
| 5 | `Meren of Clan Nel Toth` | BG | Graveyard recursion, sacrifice value, toolbox creatures | Overlap com Muldrotha e loops high-power sem bracket explicito. | Corpus diferenciar BG recursion/toolbox, unresolved=0, off_color=0, public proof 5/5 sem fallback. |
| 6 | `Korvold, Fae-Cursed King` retry | BRG | Sacrifice, treasure, value/combo | Historico Sprint 2 com `core_package_weak` e timeout fallback 2/5. | So promover se core package sacrifice/treasure/value for forte, score 100 e timeout 0/5. |
| 7 | `Sythis, Harvest's Hand` | GW | Enchantress value | Colapsar com Light-Paws Voltron ou aura-goodstuff. | Separar enchantress value de Voltron, provar engine de draw/ramp/protection. |
| 8 | `Urza, Lord High Artificer` | U | Artifacts, control, combo | Vies high-power/cEDH/stax como default casual. | Lane casual/high-power explicita; excluir pecas proibidas; public proof sem fallback. |

## Decisao

Resultado final: **PASS_WITH_RISKS**.

Lote A backend/public proof esta fechado e promovido para mini-batch controlado.
Lote B pode comecar em modo controlado, mas a prova app runtime segue blocker
obrigatorio antes de qualquer PASS completo de produto.
