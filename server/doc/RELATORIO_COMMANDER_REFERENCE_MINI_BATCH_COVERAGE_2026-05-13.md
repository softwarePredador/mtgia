# Commander Reference Mini-Batch Coverage - 2026-05-13

## Verdict

**PASS WITH RISKS.**

O mini-batch controlado de Commander Reference fechou com 6 comandantes prontos
para promocao controlada: `Lorehold, the Historian`, `Prosper, Tome-Bound`,
`Aesi, Tyrant of Gyre Strait`, `Edgar Markov`, `Dina, Essence Brewer` e
`Zimone, Infinite Analyst`.

Todos passaram por corpus/reference pipeline, scorecard read-only e prova
publica sanitizada de `/ai/generate` com `commander_name`. A promocao nao
autoriza expansao massiva: cada novo comandante deve repetir o mesmo gate de
batch antes de guidance forte ou caminho deterministico.

Scanner, camera, OCR, app mobile runtime novo, rotas app-facing novas e
alteracoes de runtime ficaram fora do escopo desta consolidacao.

## Estado consolidado

| Commander | Cores | Arquetipo coberto | Corpus aceito | Scorecard final | Prova publica | p50 | p95 | Decisao |
| --- | --- | --- | ---: | --- | --- | ---: | ---: | --- |
| `Lorehold, the Historian` | RW | Boros topdeck/miracle big spells, copy/spellslinger, interaction fair | 3 | `PASS`, score `100`, `ready_for_mini_batch` | 5/5 HTTP 200, validation, commander, profile/stats/corpus; fallback 0/5 | 980ms | 1648ms | Pronto |
| `Prosper, Tome-Bound` | BR | Rakdos exile/treasure value, control/artifacts, cEDH lane como contexto separado | 4 | `PASS`, score `100`, `ready_for_mini_batch` | 5/5 HTTP 200, validation, commander, profile/stats/corpus; timeout fallback 0/5 | 870ms | 1332ms | Pronto |
| `Aesi, Tyrant of Gyre Strait` | GU | Simic lands/landfall/ramp/value, extra land drops e inevitabilidade | 4 | `PASS`, score `100`, `ready_for_mini_batch` | 5/5 HTTP 200, validation, commander, profile/stats/corpus; timeout fallback 0/5 | 987ms | 1234ms | Pronto |
| `Edgar Markov` | BRW | Mardu Vampire typal, go-wide aggro, lords, aristocrats/drain | 4 | `PASS`, score `100`, `ready_for_mini_batch` | 5/5 HTTP 200, validation, commander, profile/stats/corpus; timeout fallback 0/5 | 866ms | 867ms | Pronto |
| `Dina, Essence Brewer` | BG | Golgari sacrifice, lifegain/drain, aristocrats, tokens/recursion | 5 | `PASS`, score `100`, `ready_for_mini_batch` | 5/5 HTTP 200, validation, commander, profile/stats/corpus; timeout fallback 0/5 | 1018ms | 1354ms | Pronto com risco de freshness |
| `Zimone, Infinite Analyst` | GU | Simic X-spells, +1/+1 counters, big mana, scalable finishers | 5 | `PASS`, score `100`, `ready_for_mini_batch` | 5/5 HTTP 200, validation, commander, profile/stats/corpus; timeout fallback 0/5 | 878ms | 1185ms | Pronto com risco de freshness |

## Cobertura de cores

| Cor / identidade | Cobertura atual |
| --- | --- |
| W | Lorehold, Edgar |
| U | Aesi, Zimone |
| B | Prosper, Edgar, Dina |
| R | Lorehold, Prosper, Edgar |
| G | Aesi, Dina, Zimone |
| Identidades testadas | Boros RW, Rakdos BR, Simic GU, Mardu BRW, Golgari BG |
| Gaps relevantes | Mono-color, Azorius WU, Dimir UB, Izzet UR, Selesnya GW, Orzhov WB, Gruul RG, 4-color e 5-color ainda nao foram cobertos por corpus+prova publica deste gate |

O conjunto ja cobre as cinco cores individualmente, mas ainda nao cobre a
diversidade completa de identidades de cor nem arquetipos como Voltron,
graveyard recursion dedicado, Izzet spells/combo, Orzhov aristocrats,
mono-color go-wide e commanders 4/5-color.

## Provas publicas e artifacts

As provas publicas usaram o backend
`https://evolution-cartinhas.8ktevp.easypanel.host` e artifacts sanitizados. Os
artifacts registram somente resumo operacional: status, contagens, duracoes,
flags de diagnostics e marcadores de seguranca. Nao registram token, email,
senha, prompt completo ou decklist gerada.

| Commander | Public proof | Readiness final |
| --- | --- | --- |
| Lorehold | `server/test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/public_expanded/summary.json` | `server/test/artifacts/commander_reference_readiness_2026-05-13/readiness_scorecard_summary.json` |
| Prosper | `server/test/artifacts/commander_reference_deck_corpus_prosper_2026-05-13/public_proof/summary.json` | `server/test/artifacts/commander_reference_readiness_prosper_public_2026-05-13/readiness_scorecard_summary.json` |
| Aesi | `server/test/artifacts/commander_reference_deck_corpus_aesi_2026-05-13/public_proof/summary.json` | `server/test/artifacts/commander_reference_readiness_aesi_public_2026-05-13/readiness_scorecard_summary.json` |
| Edgar | `server/test/artifacts/commander_reference_deck_corpus_edgar_2026-05-13/public_proof/summary.json` | `server/test/artifacts/commander_reference_readiness_edgar_public_2026-05-13/readiness_scorecard_summary.json` |
| Dina | `server/test/artifacts/commander_reference_deck_corpus_dina_2026-05-13/public_proof/summary.json` | `server/test/artifacts/commander_reference_readiness_dina_public_2026-05-13/readiness_scorecard_summary.json` |
| Zimone | `server/test/artifacts/commander_reference_deck_corpus_zimone_2026-05-13/public_proof/summary.json` | `server/test/artifacts/commander_reference_readiness_zimone_public_2026-05-13/readiness_scorecard_summary.json` |

Relatorios-base lidos para esta consolidacao:

- `server/doc/RELATORIO_COMMANDER_REFERENCE_DECK_CORPUS_LOREHOLD_2026-05-12.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_DECK_CORPUS_PROSPER_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_DECK_CORPUS_AESI_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_DECK_CORPUS_EDGAR_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_DECK_CORPUS_DINA_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_DECK_CORPUS_ZIMONE_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_READINESS_SCORECARD_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_READINESS_MINI_BATCH_2026-05-13.md`
- `app/doc/runtime_flow_handoffs/lorehold_reference_stats_sm_a135m_2026-05-11.md`
- `app/doc/runtime_flow_handoffs/lorehold_final_deck_validation_sm_a135m_2026-05-11.md`

## Scorecard e criterios de promocao

O gate operacional que promoveu cada comandante exige:

1. comandante resolvido no banco;
2. profile disponivel com confidence utilizavel;
3. card stats disponiveis sem unresolved;
4. corpus aceito com decks suficientes;
5. core package forte;
6. deck deterministico valido com `main_quantity=99`;
7. public proof 5/5 de `/ai/generate` com `commander_name`;
8. `validation_ok`, comandante preservado, profile/stats/corpus usados;
9. `invalid_cards_total=0`, `off_identity_total=0`;
10. sem timeout fallback.

Lorehold provou caminho sem fallback nos 5 probes de corpus v4/v5. Prosper,
Aesi, Edgar, Dina e Zimone marcaram `is_mock=true`/`fallback=true` nos payloads
publicos, mas sem timeout, sem erro de validacao e com profile/stats/corpus
ativos. Pelo scorecard v2, isso e caminho deterministico reference-guided valido,
nao fallback de timeout.

## Contrato `/ai/generate`

Nao houve drift real no contrato app-facing de `/ai/generate` durante o
fechamento deste mini-batch.

O contrato documentado em `server/doc/API_CONTRACTS_AND_DATA_MAP.md` permanece
estavel:

- o app continua enviando `prompt`, `format`, `async` e, quando preenchido,
  `commander_name`;
- `generated_deck` e `validation` continuam sendo a fonte de verdade;
- `diagnostics.reference_profile_used`,
  `diagnostics.reference_card_stats_used` e
  `diagnostics.reference_deck_corpus_used` seguem opcionais/experimentais;
- novos sinais de corpus/profile sao agregados sanitizados e nao tornam campos
  obrigatorios;
- o mobile nao chama EDHREC, Scryfall, MTGJSON, OpenAI ou qualquer API MTG
  externa diretamente.

Por isso, `server/doc/API_CONTRACTS_AND_DATA_MAP.md` nao foi alterado nesta
consolidacao.

## Riscos conhecidos

| Risco | Impacto | Mitigacao |
| --- | --- | --- |
| Dina e Zimone usam projecao local-resolvivel | As paginas EDHREC originais tinham cartas Secrets of Strixhaven ainda ausentes no banco local | Manter artifacts marcados como projection; opcionalmente auditar backfill oficial via Scryfall antes de exigir fidelidade literal |
| `fallback=true` deterministico em 5/5 para Prosper/Aesi/Edgar/Dina/Zimone | Pode ser confundido com fallback de timeout/OpenAI | Scorecard v2 diferencia: timeout 0/5, validation OK, profile/stats/corpus usados |
| Cobertura de identidades ainda parcial | Expansao massiva pode favorecer arquetipos ja cobertos | Proxima fila deve preencher mono-color, Izzet, Orzhov, Voltron e graveyard |
| EDHREC e fontes publicas sao offline/baixo volume | Risco de copyright/qualidade se decklists forem copiadas em runtime | Consumir somente roles, pacotes e contagens agregadas; nunca injetar decklist integral |
| Latencia e cache variam por deploy | Provas sao evidencias pontuais | Manter p50/p95 e 5/5 public proof como requisito de promocao por batch |

## Proxima fila recomendada

Priorizar uma fila pequena, diversa e com profiles ja conhecidos antes de novo
batch:

| Prioridade | Commander | Por que |
| ---: | --- | --- |
| 1 | `Krenko, Mob Boss` | Preenche mono-red, go-wide tokens/aggro e pressao de baixa curva |
| 2 | `Light-Paws, Emperor's Voice` | Preenche mono-white Voltron/auras, eixo ainda ausente |
| 3 | `Niv-Mizzet, Parun` ou `Niv-Mizzet, the Firemind` | Preenche Izzet spellslinger/combo com risco de poder a separar por lane |
| 4 | `Teysa Karlov` | Preenche Orzhov aristocrats/tokens sem confundir com Golgari Dina |
| 5 | `Meren of Clan Nel Toth` | Preenche graveyard recursion dedicado e sacrifice/value de longo prazo |
| 6 | `Kinnan, Bonder Prodigy` | Preenche Simic ramp/combo competitivo; exigir lane casual/cEDH explicita para nao distorcer bracket |

Cada item deve passar pelo mesmo fluxo: preparar corpus offline, dry-run,
apply/idempotencia, scorecard, public proof 5/5 e promocao controlada.

## Regra operacional resultante

Nao liberar expansao massiva de Commander Reference sem gate de batch. Para cada
novo comandante:

1. preparar corpus publico/offline com fontes Commander claras;
2. rodar `--dry-run` e bloquear se houver unresolved, off-color, commander
   quantity incorreta, main quantity diferente de 99 ou singleton violations;
3. aplicar somente depois de dry-run PASS;
4. provar idempotencia com segundo `--apply`;
5. rodar scorecard read-only;
6. executar public proof 5/5 sanitizado de `/ai/generate`;
7. promover apenas com scorecard `PASS`, `score=100`, `ready_for_mini_batch`,
   blockers/warnings vazios e sem timeout fallback;
8. documentar riscos, artifacts e compatibilidade de contrato.

## Resultado final

**PASS WITH RISKS**: mini-batch pronto para promocao controlada, contrato
`/ai/generate` estavel, sem alteracao de runtime, mas expansao massiva continua
bloqueada ate cada novo comandante passar pelo mesmo gate.
