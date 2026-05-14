# Commander Reference Sprint 3 Lote B Plan - 2026-05-14

## Resultado de abertura

**PASS_WITH_RISKS** para preparar o Lote B em modo offline/dry-run, sem apply no
banco.

`master` local estava sincronizada com `origin/master` antes da coleta, e
`/health` publico retornou `git_sha=f4ec0d3c056d811f033d061cfaf0afefa82d30fb`,
igual ao HEAD local. O fechamento app runtime do Lote A foi lido. Este plano nao
altera runtime, endpoint app-facing, app mobile, scanner, camera ou OCR.

## Referencias locais lidas

- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_A_FINAL_2026-05-13.md`
- `server/doc/COMMANDER_REFERENCE_SPRINT2_TRACKER_2026-05-13.md`
- `server/doc/COMMANDER_REFERENCE_SPRINT3_PLAN_2026-05-13.md`
- `server/doc/COMMANDER_REFERENCE_SPRINT3_TRACKER_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_A_CORPUS_PREP_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_A_PUBLIC_PROOF_2026-05-13.md`
- `server/manual-de-instrucao.md`

## Separacao de evidencias

### Fatos locais/database

- Lote A terminou **PASS_WITH_RISKS**: backend/public proof PASS e runtime app real
  PASS_WITH_RISKS no Android fisico, com risco ambiental de rede e iOS Simulator
  ainda bloqueado por dependencia de scanner.
- Lote B recomendado pelo fechamento do Lote A: `Meren of Clan Nel Toth`,
  `Korvold, Fae-Cursed King` retry, `Sythis, Harvest's Hand` e
  `Urza, Lord High Artificer`.
- Korvold permaneceu bloqueado no Sprint 2 por `core_package_weak`,
  `public_runtime_gate_not_passed` e timeout fallback `2/5`; o retry exige corpus
  mais forte antes de qualquer promocao.
- O gate minimo antes de futuro apply continua: comandante resolvido,
  `commander_quantity=1`, `main_quantity=99`, `unresolved=0`, `off_color=0`,
  singleton limpo fora de terrenos basicos e dry-run com `db_mutations=false`.

### Achados web-derived

As fontes alvo sao paginas publicas EDHREC Average Deck, coletadas uma vez em
baixo volume para artifact offline. Cada fonte incluida precisa provar contexto
Commander por rotulo externo `Average Deck for ...`, `total_card_count=100`,
comandante no slot `commander` e main deck com 99 cartas.

### Interpretacao operacional

O Lote B maximiza diversidade ainda faltante: graveyard BG, sacrifice/treasure
Jund, enchantress GW e mono-blue artifacts/control/combo. Urza e Korvold devem
manter lanes de poder explicitas para nao transformar shell high-power/cEDH em
default casual.

## Candidatos selecionados

| Prioridade | Commander | Cor | Arquetipo | Risco de corpus | Criterio de aceite para avancar |
| ---: | --- | --- | --- | --- | --- |
| 5 | `Meren of Clan Nel Toth` | BG | Graveyard recursion, sacrifice value, toolbox creatures | Overlap com Muldrotha e fontes recentes com cartas ausentes no DB local. | 3+ fontes Commander aceitas, `unresolved=0`, `off_color=0`, 1/99, recursion/toolbox evidente e sem loops high-power como default. |
| 6 | `Korvold, Fae-Cursed King` retry | BRG | Sacrifice, treasure, value/aristocrats | Historico Sprint 2: core package fraco e timeout fallback. | Corpus reforcado em treasure/sacrifice/aristocrats; futuro public proof 5/5, timeout fallback 0/5 e scorecard 100 antes de promocao. |
| 7 | `Sythis, Harvest's Hand` | GW | Enchantress value, enchantment draw/ramp, aura support | Pode colapsar com Light-Paws Voltron ou enchantments goodstuff. | Separar enchantress value de Voltron; provar draw/ramp/protection, zero unresolved/off-color e deck gerado sem virar aura-Voltron puro. |
| 8 | `Urza, Lord High Artificer` | U | Artifacts, control, combo | Forte vies high-power/cEDH/stax; risco de combo/stax como default casual. | Lanes `artifacts`, `control`, `combo` e `budget` separadas; nao promover se public proof sugerir stax/combo duro fora da intencao/bracket. |

## Execucao planejada do Lote B

Artifacts esperados:
`server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/<safe_commander>/corpus.json`
e
`server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/<safe_commander>/dry_run/`.

Status deste lote:

| Commander | corpus_prepared | dry_run | apply | idempotency | public_proof | readiness_scorecard | promoted |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Meren of Clan Nel Toth` | DONE | DONE, PASS | APPLY_NOT_RUN | PENDING | PENDING | PENDING | false |
| `Korvold, Fae-Cursed King` | DONE | DONE, PASS | APPLY_NOT_RUN | PENDING | PENDING | PENDING | false |
| `Sythis, Harvest's Hand` | DONE | DONE, PASS | APPLY_NOT_RUN | PENDING | PENDING | PENDING | false |
| `Urza, Lord High Artificer` | DONE | DONE, PASS | APPLY_NOT_RUN | PENDING | PENDING | PENDING | false |

## Guardrails

1. Nao executar `--apply` neste lote/commit.
2. Nao persistir token, JWT, Sentry DSN, `DATABASE_URL`, `OPENAI_API_KEY`,
   credenciais QA, prompts completos ou payload sensivel.
3. Nao depender de EDHREC ou API nao oficial em runtime; os JSONs sao artifacts
   offline auditaveis.
4. Nao misturar cEDH/high-power com casual Commander sem lane explicita.
5. Manter scanner, camera e OCR fora do escopo.

## Proximas acoes tecnicas minimas

1. Revisar manualmente os packages extraidos dos dry-runs, especialmente Korvold e
   Urza.
2. Se aprovado, rodar novo dry-run pre-apply e so entao `--apply` controlado em
   commit/tarefa futura.
3. Depois de apply futuro, executar idempotencia, public proof 5/5 e readiness
   scorecard com runtime summary antes de qualquer promocao.
