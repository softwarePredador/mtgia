# Commander Reference Sprint 2 Final - 2026-05-13

## Resultado final

**PASS WITH RISKS.**

O Sprint 2 Commander Reference Expansion fechou com cinco comandantes promovidos
para mini-batch controlado e um comandante bloqueado. Nao houve alteracao de
runtime, app mobile, scanner/camera/OCR, endpoints app-facing ou shape de
`/ai/generate`.

## Evidencias consolidadas

- Tracker:
  `server/doc/COMMANDER_REFERENCE_SPRINT2_TRACKER_2026-05-13.md`.
- Corpus prep:
  `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT2_CORPUS_PREP_2026-05-13.md`.
- Apply/idempotencia:
  `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT2_APPLY_2026-05-13.md`.
- Public proof:
  `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT2_PUBLIC_PROOF_2026-05-13.md`.
- Contrato:
  `server/doc/API_CONTRACTS_AND_DATA_MAP.md`.
- Historico operacional:
  `server/manual-de-instrucao.md`.

## Comandantes promovidos

| Commander | Identidade | Archetype/lane coberto | Corpus/apply/idempotencia | Public proof | Scorecard final |
| --- | --- | --- | --- | --- | --- |
| `Kinnan, Bonder Prodigy` | GU | Simic ramp/combo com lane casual/cEDH explicita | PASS, 4/4 decks aceitos | PASS 5/5 | PASS, score 100, `ready_for_mini_batch` |
| `Muldrotha, the Gravetide` | BGU | Sultai graveyard recursion/self-mill/value | PASS, 4/4 decks aceitos | PASS 5/5 | PASS, score 100, `ready_for_mini_batch` |
| `Yuriko, the Tiger's Shadow` | UB | Dimir ninjas/topdeck tempo | PASS, 4/4 decks aceitos | PASS 5/5 | PASS, score 100, `ready_for_mini_batch` |
| `Winota, Joiner of Forces` | RW | Boros combat engine, non-human enablers e humans payoff | PASS, 4/4 decks aceitos | PASS 5/5 | PASS, score 100, `ready_for_mini_batch` |
| `Atraxa, Praetors' Voice` | WUBG | Proliferate umbrella com lanes counters/superfriends/infect | PASS, 5/5 decks aceitos | PASS 5/5 | PASS, score 100, `ready_for_mini_batch` |

## Comandantes bloqueados

| Commander | Identidade | Archetype/lane | Evidencia positiva | Bloqueio | Menor correcao recomendada |
| --- | --- | --- | --- | --- | --- |
| `Korvold, Fae-Cursed King` | BRG | Jund sacrifice/treasure/value | Corpus/apply/idempotencia PASS, public proof HTTP/validation/profile/stats/corpus 5/5 | `core_package_weak` e `public_runtime_gate_not_passed`; timeout fallback 2/5; score 90 | Reforcar corpus/core package de sacrifice/treasure/value ate `corpus_core_package_strong`, repetir public proof em janela rate-limit-safe e exigir timeout fallback 0/5 antes de promocao. |

## Cobertura de archetypes

Cobertura promovida:

- Simic ramp/combo com separacao de bracket/power lane.
- Sultai graveyard recursion e permanentes reutilizaveis.
- Dimir ninjas/topdeck manipulation.
- Boros combat/Winota engine.
- WUBG proliferate/counters/superfriends/infect com lanes separadas.

Cobertura bloqueada:

- Jund sacrifice/treasure/value para Korvold ainda nao pode virar guidance forte
  porque o core package e a prova runtime publica nao passaram sem risco.

## Cobertura de cores

| Escopo | Cobertura |
| --- | --- |
| Cores individuais entre promovidos | W, U, B, R e G aparecem ao menos uma vez. |
| Pares promovidos | GU, UB, RW. |
| Tres cores promovidas | BGU. |
| Quatro cores promovidas | WUBG. |
| Cinco cores promovidas | Ainda nao coberto no Sprint 2. |
| Mono-color promovido | Ainda nao coberto no Sprint 2. |
| Paridades/gaps relevantes | Faltam mono-color e varias guildas com corpus+public proof, especialmente WU, UR, WB, RG e GW. |

## p50/p95 por comandante

| Commander | p50 | p95 | Timeout fallback | Observacao |
| --- | ---: | ---: | ---: | --- |
| `Kinnan, Bonder Prodigy` | 927ms | 998ms | 0/5 | Caminho deterministico Commander Reference. |
| `Korvold, Fae-Cursed King` | 20223ms | 24991ms | 2/5 | Caminho runtime/core package ainda arriscado; nao promovido. |
| `Muldrotha, the Gravetide` | 894ms | 939ms | 0/5 | Caminho deterministico Commander Reference. |
| `Yuriko, the Tiger's Shadow` | 893ms | 910ms | 0/5 | Caminho deterministico Commander Reference. |
| `Winota, Joiner of Forces` | 887ms | 945ms | 0/5 | Caminho deterministico Commander Reference. |
| `Atraxa, Praetors' Voice` | 904ms | 914ms | 0/5 | Caminho deterministico Commander Reference. |

## Scorecards

| Commander | Score | Status | Blockers/warnings | Decisao |
| --- | ---: | --- | --- | --- |
| `Kinnan, Bonder Prodigy` | 100 | `ready_for_mini_batch` | vazio | `promoted=true` |
| `Korvold, Fae-Cursed King` | 90 | `profile_ready_needs_proof` | `core_package_weak`, `public_runtime_gate_not_passed` | `promoted=false` |
| `Muldrotha, the Gravetide` | 100 | `ready_for_mini_batch` | vazio | `promoted=true` |
| `Yuriko, the Tiger's Shadow` | 100 | `ready_for_mini_batch` | vazio | `promoted=true` |
| `Winota, Joiner of Forces` | 100 | `ready_for_mini_batch` | vazio | `promoted=true` |
| `Atraxa, Praetors' Voice` | 100 | `ready_for_mini_batch` | vazio | `promoted=true` |

## Contrato `/ai/generate`

`server/doc/API_CONTRACTS_AND_DATA_MAP.md` foi consultado e nao precisou mudar.
O Sprint 2 nao alterou metodo, rota, request body, campos de resposta, fonte de
dados app-facing nem consumidor mobile. A compatibilidade permanece:

- `generated_deck` e `validation` continuam a fonte app-facing de verdade.
- `commander_name` continua sendo o campo recomendado para ativar guidance exata
  em Commander/Brawl quando o usuario escolhe um comandante.
- Diagnostics de Commander Reference, profile, card stats, corpus, timings e cache
  seguem opcionais/experimentais.
- O mobile continua proibido de chamar APIs externas de MTG/IA diretamente; o
  backend permanece dono de sync, cache, meta, calculos e orquestracao de IA.

## Riscos remanescentes

| Risco | Impacto | Mitigacao operacional |
| --- | --- | --- |
| Korvold com core package fraco | Guidance Jund pode ficar generico ou lento | Bloquear promocao ate novo corpus/core package e public proof sem fallback. |
| Rate limit publico em provas de lote | Summaries podem misturar falhas operacionais com qualidade real | Executar Sprint 3 em janelas rate-limit-safe e reexecutar summaries limpos. |
| Expansao em massa | Regressao de tema, identidade de cor ou latencia em `/ai/generate` | Manter batches pequenos e gates por comandante. |
| Lanes competitivas misturadas com casual | Deck casual pode receber shell cEDH indevido | Exigir lane/bracket explicito em corpus e scorecard para comandantes de combo. |
| Diagnostics opcionais tratados como obrigatorios | Drift de contrato mobile | Manter diagnostics opcionais e documentar qualquer mudanca no contrato. |
| Payload sensivel em artifacts | Vazamento de credenciais ou prompts/decklists | Persistir somente summaries sanitizados e repetir secret scan antes de commit. |

## Criterio obrigatorio para Sprint 3

Sprint 3 so deve adicionar/promover novos comandantes depois de repetir, por
comandante, o gate completo:

1. Corpus publico/offline preparado com fontes Commander claras, sem scraping em
   runtime e sem decklists completas em prompt/runtime.
2. Dry-run DB-backed PASS com comandante resolvido, `commander_quantity=1`,
   `main_quantity=99`, `unresolved=0`, `off_color=0` e singleton limpo fora de
   terrenos basicos.
3. Apply somente depois de dry-run PASS.
4. Idempotencia provada com segunda execucao preservando os mesmos gates.
5. Public proof sanitizado 5/5 de `POST /ai/generate` com `commander_name`, sem
   registrar credenciais, token, prompt completo ou decklists geradas.
6. Scorecard read-only final PASS, `score=100`,
   `status=ready_for_mini_batch`, `expansion_ready=true`, blockers/warnings
   vazios, `validation_ok`, comandante preservado, `main_quantity=99`,
   profile/stats/corpus usados, invalid/off-identity `0` e timeout fallback `0`.

Qualquer comandante que falhar em uma etapa fica `BLOCKED` ou
`PASS WITH RISKS`, mas nao pode ser tratado como guidance forte.

## Fila recomendada para Sprint 3

| Prioridade | Commander | Motivo |
| ---: | --- | --- |
| 1 | `Krenko, Mob Boss` | Fecha lacuna mono-red e testa go-wide tokens/aggro sem depender de multicolor. |
| 2 | `Light-Paws, Emperor's Voice` | Fecha lacuna mono-white e separa Voltron/auras de white goodstuff. |
| 3 | `Niv-Mizzet, Parun` | Cobre UR spellslinger/combo com separacao clara de power lane. |
| 4 | `Teysa Karlov` | Cobre WB aristocrats/tokens e testa death triggers dobrados. |
| 5 | `Meren of Clan Nel Toth` | Cobre BG graveyard recursion/sacrifice value sem colapsar com Muldrotha. |
| 6 | `Korvold, Fae-Cursed King` retry | Reentrar somente depois de reforco do core package e prova publica sem timeout fallback. |

## Validacao documental

- `git diff --check`: deve ser executado no fechamento deste commit.
- Secret scan documental: deve verificar este relatorio, o tracker e o manual para
  evitar chaves, tokens, DSNs, URLs de banco, credenciais, prompts completos ou
  decklists geradas.
