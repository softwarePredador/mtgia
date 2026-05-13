# Commander Reference Sprint 2 Tracker - 2026-05-13

## Objetivo

Abrir o Sprint 2 de expansao Commander Reference com uma fila pequena,
diversa e auditavel de novos comandantes. O sprint deve repetir o gate provado no
Sprint 1 antes de qualquer promocao controlada: corpus publico/offline, dry-run,
apply, idempotencia, public proof sanitizado de `/ai/generate`, scorecard
read-only e decisao explicita de promocao.

Este tracker nao altera runtime, app mobile, endpoints app-facing, contratos de
payload, scanner, camera ou OCR.

## Referencias lidas

- `server/doc/RELATORIO_COMMANDER_REFERENCE_READINESS_SCORECARD_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_READINESS_MINI_BATCH_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_MINI_BATCH_COVERAGE_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_DECK_CORPUS_LOREHOLD_2026-05-12.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_DECK_CORPUS_PROSPER_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_DECK_CORPUS_AESI_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_DECK_CORPUS_EDGAR_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_DECK_CORPUS_DINA_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_DECK_CORPUS_ZIMONE_2026-05-13.md`
- `app/doc/runtime_flow_handoffs/lorehold_reference_stats_sm_a135m_2026-05-11.md`
- `app/doc/runtime_flow_handoffs/lorehold_final_deck_validation_sm_a135m_2026-05-11.md`

## Criterios de aceite

Um comandante so pode mudar para `promoted=DONE` se todos os criterios abaixo
forem provados e documentados:

1. Corpus publico/offline preparado com fontes Commander claras, sem scraping em
   runtime e sem copiar decklists completas para prompt/runtime.
2. `dry_run=DONE` com comandante resolvido, `commander_quantity=1`,
   `main_quantity=99`, `unresolved=0`, `off_color=0` e sem singleton violations
   fora de terrenos basicos.
3. `apply=DONE` somente depois de dry-run PASS.
4. `idempotency=DONE` com segunda execucao de apply preservando os mesmos gates.
5. `public_proof=DONE` com prova sanitizada 5/5 de `POST /ai/generate` usando
   `commander_name`, sem token, e-mail, senha, prompt completo ou decklist gerada
   persistidos.
6. `readiness_scorecard=DONE` com `PASS`, `score=100`,
   `status=ready_for_mini_batch`, `expansion_ready=true`, blockers/warnings
   vazios, `validation_ok`, comandante preservado, `main_quantity=99`,
   profile/stats/corpus usados, invalid/off-identity `0` e timeout fallback `0`.
7. Compatibilidade preservada: `/ai/generate` continua usando `generated_deck` e
   `validation` como fonte de verdade; diagnostics de Commander Reference seguem
   opcionais/experimentais.

## Comandantes alvo

Status inicial do Sprint 2: todos os campos comecam em `PENDING`.

| Prioridade | Commander | Cobertura esperada | corpus_prepared | dry_run | apply | idempotency | public_proof | readiness_scorecard | promoted |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `Krenko, Mob Boss` | Mono-red go-wide tokens/aggro | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| 2 | `Light-Paws, Emperor's Voice` | Mono-white Voltron/auras | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| 3 | `Niv-Mizzet, Parun` | Izzet spellslinger/combo | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| 4 | `Teysa Karlov` | Orzhov aristocrats/tokens | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| 5 | `Meren of Clan Nel Toth` | Golgari graveyard recursion/sacrifice value | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| 6 | `Kinnan, Bonder Prodigy` | Simic ramp/combo with explicit casual/cEDH lanes | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |

## Observacoes por alvo

| Commander | Nota inicial |
| --- | --- |
| `Krenko, Mob Boss` | Preenche lacuna mono-color e testa token density/low curve sem confundir com Goblins generico fora de Commander. |
| `Light-Paws, Emperor's Voice` | Deve separar Voltron/auras de white goodstuff; exigir protecao, evasion e aura packages coerentes. |
| `Niv-Mizzet, Parun` | Deve separar lane casual spellslinger de combo/power alto; se freshness ou corpus bloquear Parun, qualquer troca para `Niv-Mizzet, the Firemind` exige atualizacao deste tracker antes de executar. |
| `Teysa Karlov` | Deve diferenciar Orzhov aristocrats/tokens de Dina BG e Edgar Mardu; foco em death triggers dobrados. |
| `Meren of Clan Nel Toth` | Deve diferenciar graveyard recursion dedicado de sacrifice generico; monitorar loops e power creep. |
| `Kinnan, Bonder Prodigy` | Exige lane casual/cEDH explicita para nao distorcer bracket; nao promover combo competitivo como default casual. |

## Riscos

| Risco | Impacto | Mitigacao |
| --- | --- | --- |
| Expansao em massa sem gate | Regressao de qualidade, off-theme ou off-identity em `/ai/generate` | Manter todos os alvos em PENDING ate passarem pelo fluxo completo. |
| Fontes publicas virarem decklist copiada | Risco de qualidade, copyright e overfitting | Usar somente sinais agregados: roles, recorrencia, pacotes e contagens sanitizadas. |
| Freshness do banco para cartas novas | Dry-run pode bloquear por unresolved | Preferir backfill oficial auditable ou projection marcada explicitamente, como nos casos Dina/Zimone. |
| Lanes de poder misturadas | Casual pode receber shell cEDH/combo indevido | Separar budget/casual/optimized/cEDH nos artifacts e no scorecard. |
| Diagnostics opcionais tratados como obrigatorios pelo app | Drift de contrato app-facing | Manter `generated_deck` e `validation` como fonte de verdade; diagnostics continuam opcionais. |
| Secrets em artifacts/provas publicas | Vazamento de token, e-mail, senha, prompt sensivel ou decklist | Persistir apenas summaries sanitizados e executar scan antes de commit. |

## Rollback

- Este tracker e a referencia curta no manual sao documentais; rollback de docs
  deve remover ou corrigir apenas os arquivos alterados neste commit.
- Para qualquer futuro apply de corpus do Sprint 2, rollback operacional deve
  remover somente registros associados ao `source_deck_key`/commander do corpus
  aplicado, preservando cards, legalidades, profiles e demais corpus ja
  promovidos.
- Se public proof ou scorecard falhar, manter `promoted=PENDING`, documentar o
  bloqueio no relatorio do comandante e nao ativar guidance forte.
- Se houver suspeita de payload sensivel persistido, bloquear promocao, remover o
  artifact afetado do versionamento e regenerar apenas resumo sanitizado.

## Status final de abertura

**PASS WITH RISKS** para abertura do Sprint 2: a fila esta definida e todos os
alvos iniciam bloqueados por gate (`PENDING`). Os riscos sao conhecidos e a
promocao continua condicionada a provas por comandante.
