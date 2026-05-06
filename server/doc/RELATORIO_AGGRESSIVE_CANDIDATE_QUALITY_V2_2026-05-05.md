# Relatorio Aggressive Candidate Quality v2 - Etapas 1, 2 e 3

Data: 2026-05-05

## Atualizacao 2026-05-06 - runtime iPhone 15 da UI de diagnostics

**PASS WITH RISKS.** A UI mobile que consome `optimize_diagnostics.aggressive_candidate_quality` foi provada no iPhone 15 Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` (`com.apple.CoreSimulator.SimRuntime.iOS-17-4`) contra backend local real `http://127.0.0.1:8082`.

| Validacao | Resultado |
|---|---|
| Backend health `http://127.0.0.1:8082/health` | PASS, `healthy` |
| `flutter analyze lib/features/decks test/features/decks --no-version-check` | PASS |
| `flutter test test/features/decks --no-version-check` | PASS, `+153` |
| `flutter analyze lib/features/decks test/features/decks integration_test/deck_runtime_m2006_test.dart --no-version-check` | PASS |
| `flutter test integration_test/deck_runtime_m2006_test.dart -d "iPhone 15" ...8082` | PASS, `03:26 +1` |

O fluxo real abriu deck Commander completo, selecionou `Agressivo`, enviou `POST /ai/optimize -> 202 (183ms)`, fez polling de job e terminou em safe no-op/quality rejected. A tela exibiu dialog de produto com:

| Campo UI | Valor observado |
|---|---|
| Mensagem | `A IA encontrou ideias, mas o gate bloqueou as inseguras para preservar seu deck.` |
| Candidatos analisados | `74` |
| Pares avaliados | `37` |
| Swaps seguros retornados | `7` |
| Principal bloqueio | `limite de mudanças da intensidade escolhida` |

Evidencias locais ignoradas pelo git: `app/doc/runtime_flow_proofs_2026-05-06_iphone15_simulator/deck_runtime_m2006_test_iphone15_8082.log` e `09_quality_rejected_blocker.png`. A prova nao exibiu payload bruto, buckets crus, JWT, secrets, prompts completos, `DATABASE_URL`, `SENTRY_DSN`, crash, overflow, modal preso, timeout cru ou 4xx/5xx user-facing. O backend temporario 8082 foi encerrado ao final e a porta ficou livre.

Risco residual: `low_candidate_coverage` nao veio nesta resposta live; portanto a linha de baixa cobertura ficou **NOT PROVEN nesta execucao** e segue coberta por teste widget/parser. O scanner fisico/camera/OCR ficou **DEFERRED**, fora do escopo.

## Atualizacao 2026-05-06 - consumo UI dos diagnostics

**PASS WITH RISKS.** A camada mobile passou a consumir `optimize_diagnostics.aggressive_candidate_quality` como diagnostico agregado e opcional no branch `intensity=aggressive` sem swaps seguros/quality rejected. A UI mostra copy derivada, nao payload bruto: candidatos analisados, pares avaliados, swaps seguros retornados, principal bloqueio traduzido e baixa cobertura quando `low_candidate_coverage=true`.

Backend contract: failed jobs async de `/ai/optimize/jobs/:id` agora preservam `quality_error.optimize_diagnostics` quando o executor sync interno retorna 422, permitindo que o app explique o mesmo safe no-op em fluxos `202 -> failed`. O quality gate, legalidade, identidade de cor, bracket, preservacao de comandante e validacao final permanecem inalterados.

Validacao: `flutter analyze lib/features/decks test/features/decks --no-version-check` PASS; `flutter test test/features/decks --no-version-check` PASS `+153`; `cd server && dart analyze routes/ai/optimize/index.dart` PASS. Runtime iPhone 15 nao foi reexecutado nesta atualizacao; scanner fisico/camera/OCR segue fora do escopo.

## Resultado

**PASS.** Foi criada uma base de dados aditiva, idempotente e DB-backed para melhorar candidatos do `optimize` aggressive sem inserir novas cartas e sem alterar `cards`, `card_legalities`, `cards.color_identity` ou regras de bracket/legalidade.

## Resultado etapa 2

**PASS WITH RISKS.** A etapa 2 extraiu sinais consumiveis de meta/sinergia para pools aggressive, materializou rows idempotentes com `source='aggressive_meta_signal_v1'` em `commander_card_synergy` e `card_role_scores`, e gerou artefatos nao sensiveis em `server/test/artifacts/aggressive_candidate_quality_2026-05-05/`.

## Resultado etapa 3

**PASS WITH RISKS.** O runtime do `/ai/optimize` passou a consumir os sinais locais no caminho deterministic-first de `intensity=aggressive`: gera uma reserva maior que o alvo nominal, ranqueia pares por role score, function tags, commander synergy, bracket/budget advisory e penalidades historicas antes do quality gate, e expoe diagnosticos agregados sem relaxar legalidade, color identity, bracket, preservacao de comandante ou validacao final.

Riscos restantes: a prova live depende de backend local e dados atuais; quando o pool e fraco ou o gate final rejeita, o resultado correto continua sendo safe no-op/low coverage. Budget tier ainda pode ser `unknown` para parte relevante dos dados e os sinais sao advisory, nao autorizacao.

## Atualizacao 2026-05-06 - runtime iPhone 15 apos consumo dos sinais

**PASS WITH RISKS.** A rodada mobile/runtime foi executada em `master` contra backend local real `http://127.0.0.1:8082` no iPhone 15 Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` (`com.apple.CoreSimulator.SimRuntime.iOS-17-4`). O app selecionou `Agressivo`, enviou `intensity=aggressive`, recebeu `202` de `/ai/optimize` em `169ms`, fez polling em `/ai/optimize/jobs/:id` e exibiu o branch seguro de quality gate rejeitado sem crash, overflow, timeout cru, modal preso ou erro bruto para o usuario.

| Validacao | Resultado |
|---|---|
| Backend health `http://127.0.0.1:8082/health` | PASS, `healthy` |
| `TEST_API_BASE_URL=http://127.0.0.1:8082 dart test test/ai_optimize_flow_test.dart --tags live -r expanded` | PASS, `02:45 +10 ~1` |
| `flutter analyze lib/features/decks test/features/decks --no-version-check` | PASS |
| `flutter test test/features/decks --no-version-check` | PASS, `00:19 +147` |
| `flutter test integration_test/deck_runtime_m2006_test.dart -d "iPhone 15" ...8082` | PASS, `02:58 +1` |

Evidencia: `app/doc/runtime_flow_handoffs/deck_runtime_iphone15_simulator_2026-05-05.md` e proof folder local ignorado `app/doc/runtime_flow_proofs_2026-05-06_iphone15_simulator/`.

Limite da rodada: o backend retornou safe no-op/quality rejected, entao preview aplicavel, desmarcacao e apply parcial ficaram **NOT PROVEN nesta execucao**. Isso preserva o contrato esperado: quando os sinais aggressive nao produzem swaps seguros suficientes depois do gate, o app nao aplica mudancas arriscadas. O marcador `optimize_diagnostics.aggressive_candidate_quality` nao apareceu no log app desta rodada porque a UI nao consome diagnostics e o resultado async falho nao foi impresso como payload final.

Leitura de produto: manter `aggressive_candidate_quality` como diagnostico operacional por enquanto. Para UI futura, derivar copy agregada de `low_candidate_coverage`/buckets de rejeicao, sem exibir buckets crus nem payload tecnico.

## Escopo entregue

- Novo helper testavel: `server/lib/ai/candidate_quality_data_support.dart`.
- Novo comando operacional: `server/bin/candidate_quality_data_foundation.dart`.
- Novo teste: `server/test/candidate_quality_data_support_test.dart`.
- Novas tabelas aditivas:
  - `card_function_tags`
  - `card_role_scores`
  - `commander_card_synergy`
  - `optimize_rejection_penalties`
- Nova view aditiva:
  - `optimize_candidate_quality_summary`
- Indices para lookup por tag/role/commander/penalidade.

## Etapa 3 - Consumo runtime pelo aggressive

### Mudanca implementada

- `server/lib/ai/optimize_runtime_support.dart`
  - Novo carregador `loadAggressiveCandidateQualitySignals` para `card_role_scores`, `card_function_tags`, `commander_card_synergy` e `optimize_rejection_penalties`.
  - Novo ranking `rankAggressiveCandidateQualityPairs` com score advisory por:
    - alinhamento entre role removido e role do candidato;
    - `source='aggressive_meta_signal_v1'`;
    - `role_score`, `function_confidence`, `synergy_score` e `evidence_count`;
    - penalidade historica de rejeicao;
    - penalidade advisory para bracket/budget incompatíveis.
  - O `aggressive` gera ate 3x o target como pool interno, ranqueia antes do quality gate e entrega ate 2x o target para o gate usar como reserva; a resposta final e capada pelo target de intensidade.
- `server/routes/ai/optimize/index.dart`
  - Passa `intensity=aggressive` para a shortlist deterministica.
  - Mantem `filterUnsafeOptimizeSwapsByCardData`, color identity, bracket policy e `OptimizationValidator` como gate final.
  - Expoe `optimize_diagnostics.aggressive_candidate_quality` com:
    - `requested_target_swaps`;
    - `removal_candidates`;
    - `replacement_candidates`;
    - `pairs_generated`;
    - `rejected_reason_buckets`;
    - `returned_swaps`;
    - `safety_reduced_scope`;
    - `low_candidate_coverage`;
    - `ranked_before_quality_gate`;
    - `candidate_sources`.

### Reason buckets

Os motivos do gate sao agregados sem expor payload sensivel:

| Bucket | Significado |
|---|---|
| `incomplete_card_data` | dados insuficientes para validar o par |
| `role_mismatch` | troca muda papel funcional de forma insegura |
| `curve_or_role_mismatch` | delta de CMC/role torna a troca arriscada |
| `mana_or_land_safety` | protecao de mana/terreno bloqueou |
| `quality_gate_rejected` | rejeicao geral do gate |
| `scope_cap` | candidatos excedentes ficaram como reserva apos cap de intensidade |

### Testes adicionados

- `server/test/optimize_runtime_support_test.dart`
  - prova que ranking aggressive usa role/synergy/meta signals antes do gate;
  - prova que aggressive consegue expor mais swaps seguros aprovados que focused quando ha 12 oportunidades seguras;
  - prova safe no-op com reason buckets quando o gate rejeita todos os pares.

### Validacao etapa 3

```bash
cd server && dart analyze lib/ai/optimize_runtime_support.dart routes/ai/optimize/index.dart test/optimize_runtime_support_test.dart
cd server && dart test test/optimize_runtime_support_test.dart test/optimization_quality_gate_test.dart
cd server && dart format lib/ai/optimize_runtime_support.dart routes/ai/optimize/index.dart test/optimize_runtime_support_test.dart && dart analyze lib routes test
cd server && TEST_API_BASE_URL=http://127.0.0.1:8082 dart test test/ai_optimize_flow_test.dart test/optimization_quality_gate_test.dart test/optimization_pipeline_integration_test.dart test/optimize_complete_support_test.dart test/external_commander_meta_promotion_support_test.dart test/optimize_runtime_support_test.dart
cd server && TEST_API_BASE_URL=http://127.0.0.1:8082 dart run bin/run_commander_only_optimization_validation.dart --dry-run
cd app && flutter analyze lib/features/decks test/features/decks --no-version-check
cd app && flutter test test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart --no-version-check
```

Resultado:

| Comando | Resultado |
|---|---|
| Analyzer focado backend | PASS |
| Testes focados `optimize_runtime_support` + `optimization_quality_gate` | PASS |
| `dart analyze lib routes test` | PASS |
| Suite backend live em 8082 | PASS, `02:44 +77 ~1`, skip preexistente/esperado no teste parametrizado |
| Commander-only dry-run em 8082 | PASS, 19 candidatos seriam validados; sem mutacao |
| App analyze decks | PASS |
| App tests decks focados | PASS, `00:07 +46` |

Baseline observado antes de subir backend: `ai_optimize_flow_test.dart` falhava com `Connection refused` em `127.0.0.1:8082`, igual ao comportamento esperado quando a suite live roda sem servidor. Apos subir backend 8082, a suite passou.

### Evidencia de qualidade

| Pergunta | Evidencia |
|---|---|
| Usa tags/scores/meta signals? | `rankAggressiveCandidateQualityPairs` promove candidato com `source='aggressive_meta_signal_v1'`, `role_score`, `function_confidence`, `synergy_score` e `evidence_count`; teste unitario cobre o ranking. |
| Gera mais candidatos que o target? | `intensity=aggressive` usa ate 3x o target para busca e ate 2x como reserva antes do gate, com cap final no target. |
| Quality gate intacto? | `filterUnsafeOptimizeSwapsByCardData`, bracket policy, color identity e `OptimizationValidator` permanecem depois do ranking; teste cobre safe no-op quando o gate rejeita tudo. |
| Rejection buckets expostos? | `optimize_diagnostics.aggressive_candidate_quality.rejected_reason_buckets` agrega motivos sem payload sensivel. |
| Legalidade/color identity/bracket preservados? | As queries continuam partindo de candidatos ja filtrados por legalidade/identidade/bracket, e o endpoint revalida antes de responder. |

## Guardrails

- O comando default e `--dry-run`; sem `--apply` nao executa escrita.
- O apply usa `INSERT ... ON CONFLICT DO UPDATE` e chaves primarias naturais para evitar duplicidade.
- A selecao canonica de printings usa desempate deterministico por `c.id`.
- A poda remove apenas linhas obsoletas das fontes geradas por este comando:
  - `deterministic_heuristic_v1`
  - `meta_decks_cooccurrence_v1`
  - `quality_gate_history_v1`
- Tags e scores nao sobrescrevem legalidade, identidade de cor, bracket ou dados source-of-truth.
- O SQL de sample pools mantem filtros de Commander legality e `color_identity <@ commander_identity`.
- Nao houve IA offline nem chamada externa em request path.

## Comandos executados

```bash
cd server && dart analyze lib/ai/candidate_quality_data_support.dart bin/candidate_quality_data_foundation.dart test/candidate_quality_data_support_test.dart
cd server && dart test test/candidate_quality_data_support_test.dart
cd server && dart run bin/candidate_quality_data_foundation.dart --dry-run --artifact-dir=test/artifacts/aggressive_candidate_quality_v2_2026-05-05
cd server && dart run bin/candidate_quality_data_foundation.dart --apply --artifact-dir=test/artifacts/aggressive_candidate_quality_v2_2026-05-05
cd server && dart run bin/candidate_quality_data_foundation.dart --apply --artifact-dir=test/artifacts/aggressive_candidate_quality_v2_2026-05-05/idempotence
cd server && dart run bin/candidate_quality_data_foundation.dart --dry-run --artifact-dir=test/artifacts/aggressive_candidate_quality_v2_2026-05-05/post_fix_dry_run
cd server && dart run bin/candidate_quality_data_foundation.dart --apply --artifact-dir=test/artifacts/aggressive_candidate_quality_v2_2026-05-05/post_fix_apply
cd server && dart run bin/candidate_quality_data_foundation.dart --apply --artifact-dir=test/artifacts/aggressive_candidate_quality_v2_2026-05-05/final_idempotence
cd server && dart run bin/mtg_data_integrity.dart --artifact-dir=test/artifacts/mtg_data_integrity_2026-05-05_acqv2
cd server && dart analyze bin lib routes test
cd server && dart test test/sets_route_test.dart test/cards_route_test.dart test/candidate_quality_data_support_test.dart
```

## Cobertura medida

Fonte: `server/test/artifacts/aggressive_candidate_quality_v2_2026-05-05/final_idempotence/summary_apply.json`.

| Metrica | Valor |
|---|---:|
| `cards` no banco | 33774 |
| cards canonicas escaneadas | 33312 |
| cards com tags deterministicas | 20002 |
| cobertura de tags | 60.04% |
| `card_function_tags` final | 33011 |
| `card_role_scores` final | 30988 |
| `commander_card_synergy` final | 5000 |
| `optimize_rejection_penalties` final | 358 |
| `card_meta_insights` disponiveis | 33274 |
| `meta_decks` disponiveis | 650 |
| `optimization_analysis_logs` disponiveis | 534 |

## Tags funcionais

| Tag | Linhas |
|---|---:|
| sacrifice | 5610 |
| graveyard | 4723 |
| removal | 4700 |
| token | 3912 |
| draw | 3619 |
| ramp | 3092 |
| mana_fixing | 1606 |
| protection | 1234 |
| recursion | 1209 |
| board_wipe | 834 |
| aristocrats | 702 |
| tutor | 633 |
| counterspell | 439 |
| wincon | 402 |
| stax | 149 |
| combo_piece | 147 |

## Role scores, bracket e budget

- Role score rows: 30988.
- Bracket scopes:
  - `any`: 27209
  - `bracket_2_4`: 3637
  - `bracket_3_4`: 142
- Budget tier atual: `unknown` para 30988 rows porque os campos de preco canonicos analisados estavam sem valor confiavel para essa etapa. Isso foi mantido explicito, sem inferencia artificial.

## Synergy e sample pools

`commander_card_synergy` foi derivada apenas de coocorrencia em `meta_decks` Commander/cEDH, com `evidence_count >= 2`, limite inicial de 5000 linhas e sem adicionar cartas.

Sample pools gerados em `sample_candidate_pools.json`:

| Shell / Commander | Identidade | Guardrails |
|---|---|---|
| Spider-Man 2099 | U/R | legal/restricted/null + subset de color identity |
| Kraum, Ludevic's Opus | U/R | legal/restricted/null + subset de color identity |
| Thrasios, Triton Hero | G/U | legal/restricted/null + subset de color identity |

Exemplos de candidatos filtrados: `Arcane Signet`, `Counterspell`, `Fierce Guardianship`, `Force of Negation`, `Birds of Paradise`, `Delighted Halfling`. O sample mostra `bracket_scope`, `legal_status` e `color_identity` para auditar que tags nao viram bypass.

## Penalidades de rejeicao

`optimize_rejection_penalties` recebeu 358 linhas agregadas a partir de `optimization_analysis_logs` falhos/reprovados. A tabela guarda apenas nomes de carta, commander/archetype agregados, contagem e penalidade; nao armazena prompt, JWT, user id, payload sensivel ou secrets.

## Dry-run/apply e idempotencia

Dry-run inicial:

- `db_mutations=false`.
- `card_function_tags`, `card_role_scores`, `commander_card_synergy`, `optimize_rejection_penalties` permaneceram em 0.

Apply final:

- `db_mutations=true`.
- `cards`, `card_meta_insights`, `meta_decks` e `optimization_analysis_logs` mantiveram os mesmos contadores antes/depois.
- Somente tabelas novas/aditivas receberam linhas.

Idempotencia final:

| Tabela | Pre | Post |
|---|---:|---:|
| card_function_tags | 33011 | 33011 |
| card_role_scores | 30988 | 30988 |
| commander_card_synergy | 5000 | 5000 |
| optimize_rejection_penalties | 358 | 358 |

Antes da correção deterministica, o dry-run `post_fix_dry_run` apontou stale rows geradas pela propria fonte: 6 tags, 3 role scores e 69 synergies. O apply `post_fix_apply` removeu somente essas linhas geradas, retornando aos contadores canonicos. O apply `final_idempotence` confirmou stale rows = 0.

## Auditoria MTG data integrity complementar

Fonte: `server/test/artifacts/mtg_data_integrity_2026-05-05_acqv2`.

| Item | Valor |
|---|---:|
| grupos duplicados `LOWER(sets.code)` | 82 |
| `cards.color_identity IS NULL` | 0 |
| candidatos de backfill deterministicos | 0 |
| unresolved color identity | 0 |

Esses contadores foram medidos em dry-run apenas. A etapa nao alterou sets nem color identity.

## Rollback / reversibilidade

Rollback seguro da etapa, se necessario:

```sql
DROP VIEW IF EXISTS optimize_candidate_quality_summary;
DROP TABLE IF EXISTS optimize_rejection_penalties;
DROP TABLE IF EXISTS commander_card_synergy;
DROP TABLE IF EXISTS card_role_scores;
DROP TABLE IF EXISTS card_function_tags;
```

Rollback parcial de dados gerados, preservando schema:

```sql
DELETE FROM card_function_tags WHERE source = 'deterministic_heuristic_v1';
DELETE FROM card_role_scores WHERE source = 'deterministic_heuristic_v1';
DELETE FROM commander_card_synergy WHERE source = 'meta_decks_cooccurrence_v1';
DELETE FROM optimize_rejection_penalties WHERE source = 'quality_gate_history_v1';
```

Nenhum rollback toca em `cards`, `card_legalities`, `sets`, `decks` ou dados de usuario.

## Validacao

- `dart analyze lib/ai/candidate_quality_data_support.dart bin/candidate_quality_data_foundation.dart test/candidate_quality_data_support_test.dart`: PASS.
- `dart test test/candidate_quality_data_support_test.dart`: PASS.
- `dart analyze bin lib routes test`: PASS.
- `dart test test/sets_route_test.dart test/cards_route_test.dart test/candidate_quality_data_support_test.dart`: PASS, 11 testes.
- Dry-run/apply/idempotencia DB-backed: PASS.

## Gaps e proximas etapas

- Historico: o consumo runtime pelo `/ai/optimize` nao foi ligado nas etapas 1/2; a etapa 3 conectou os sinais ao caminho `intensity=aggressive` sem transformar sinais em bypass de gate.
- Budget tier ficou `unknown` por falta de preco confiavel na selecao canonica atual.
- Tags sao heuristicas deterministicamente inferidas, nao revisadas manualmente; `source` e `confidence` permitem auditoria posterior.
- Duplicate set-code cleanup permanece fora desta etapa; contagem atual e 82 grupos.

---

## Etapa 2 - Extracao de sinais meta/sinergia

### Pipeline resumido

O novo comando `server/bin/candidate_quality_meta_signals.dart` roda sobre dados locais ja aceitos pelo pipeline:

1. `meta_decks` Commander/cEDH aceitos.
2. `external_commander_meta_candidates` apenas quando `subformat=competitive_commander`, `validation_status IN ('validated','staged','promoted')` e `legal_status IN ('legal','valid','warning_reviewed')`.
3. `commander_reference_profiles` apenas como enriquecimento EDHREC/cache local, nunca como prova cEDH.
4. `card_role_scores` e `card_function_tags` da etapa 1 para role/sinal funcional.
5. `optimize_rejection_penalties` como democao historica, nao como banimento absoluto.

O comando exclui lands dos sinais de candidato aggressive, exige legalidade Commander `legal/restricted/null`, exige `cards.color_identity` subset da identidade resolvida do comandante/shell, e nao grava qualquer payload de usuario, JWT, prompt, secret ou URL privada.

### Comandos executados

```bash
cd server && dart format lib/ai/aggressive_candidate_meta_signal_support.dart bin/candidate_quality_meta_signals.dart test/aggressive_candidate_meta_signal_support_test.dart
cd server && dart analyze lib/ai/aggressive_candidate_meta_signal_support.dart bin/candidate_quality_meta_signals.dart test/aggressive_candidate_meta_signal_support_test.dart
cd server && dart test test/aggressive_candidate_meta_signal_support_test.dart
cd server && dart run bin/candidate_quality_meta_signals.dart --dry-run --artifact-dir=test/artifacts/aggressive_candidate_quality_2026-05-05/dry_run
cd server && dart run bin/candidate_quality_meta_signals.dart --apply --artifact-dir=test/artifacts/aggressive_candidate_quality_2026-05-05/apply
cd server && dart run bin/candidate_quality_meta_signals.dart --apply --artifact-dir=test/artifacts/aggressive_candidate_quality_2026-05-05/idempotence
cd server && dart analyze bin/candidate_quality_meta_signals.dart lib/ai/aggressive_candidate_meta_signal_support.dart test/aggressive_candidate_meta_signal_support_test.dart
cd server && dart test test/aggressive_candidate_meta_signal_support_test.dart test/candidate_quality_data_support_test.dart
cd server && dart analyze bin lib routes test
cd server && dart test
```

### Artefatos gerados

Diretorio principal:

- `server/test/artifacts/aggressive_candidate_quality_2026-05-05/dry_run/`
- `server/test/artifacts/aggressive_candidate_quality_2026-05-05/apply/`
- `server/test/artifacts/aggressive_candidate_quality_2026-05-05/idempotence/`

Arquivos principais:

- `summary_dry_run.json`
- `summary_apply.json`
- `coverage_summary.json`
- `candidate_signals.json`
- `package_clusters.json`
- `role_replacements.json`
- `budget_premium_alternatives.json`
- `commander_profile_enrichment.json`
- `commander_signal_rows.csv`

### Cobertura real medida

Fonte: `server/test/artifacts/aggressive_candidate_quality_2026-05-05/idempotence/summary_apply.json`.

| Metrica | Valor |
|---|---:|
| `meta_decks` totais | 650 |
| `meta_decks` Commander/cEDH escaneados | 385 |
| candidatos externos confiaveis escaneados | 9 |
| `commander_reference_profiles` escaneados | 18 |
| decks com identidade de comandante resolvida | 360 |
| decks com identidade desconhecida | 34 |
| decks com sinais candidatos | 360 |
| rows planejadas/aplicadas em `commander_card_synergy` | 2179 |
| rows planejadas/aplicadas em `card_role_scores` | 910 |
| stale rows antes do apply idempotente | 0 |

Cobertura por formato/subformato:

| Formato | Decks |
|---|---:|
| cEDH / `competitive_commander` | 232 |
| EDH / `duel_commander` | 162 |

Cobertura por fonte/formato:

| Fonte/formato | Decks |
|---|---:|
| `mtgtop8|cEDH` | 214 |
| `mtgtop8|EDH` | 162 |
| `external|cEDH` | 9 |
| `external:EDHTop16|cEDH` | 9 |

Top identidades de cor resolvidas:

| Identidade | Decks |
|---|---:|
| UR | 34 |
| WUBRG | 28 |
| UBR | 25 |
| WUBR | 25 |
| UG | 23 |
| WUB | 18 |
| WUBG | 16 |
| BR | 15 |
| G | 15 |
| UBG | 15 |

Principais gaps de identidade (`not_proven` para persistencia): `Kefka, Court Mage`, `Ral, Monsoon Mage`, `Terra, Magical Adept`, `Brigid, Clachan's Heart`, `Etali, Primal Conqueror`, `Aang, at the Crossroads` e outros comandantes novos/UB ainda nao resolvidos localmente.

### Sinais por commander/archetype/color identity

Representantes provados em `candidate_signals.json`:

| Shell | Subformato | Identidade | Linhas de sinal | Leitura estrategica |
|---|---|---|---:|---|
| Kinnan, Bonder Prodigy | competitive_commander | UG | 107 | ramp/combo de mana positiva, dorks/fast mana, tutor e protecao de combo |
| Kraum, Ludevic's Opus + Tymna the Weaver | competitive_commander | WUBR | 94 | shell blue farm/consultation-breach: draw barato, tutor density, stack interaction e janelas de protecao |
| Thrasios, Triton Hero + Tymna the Weaver | competitive_commander | WUBG | 143 | partner goodstuff/combo-control: ramp eficiente, tutor, draw, stack interaction e stax/protecao |
| Spider-Man 2099 | duel_commander | UR | 126 | aggro/tempo Duel Commander; separado de cEDH para nao contaminar multiplayer |

Exemplos de top cards por role, todos advisory e ainda sujeitos aos gates finais:

| Shell | Role | Exemplos com evidencia alta |
|---|---|---|
| Kinnan | ramp | Chrome Mox, Elvish Mystic, Mana Vault, Mox Amber, Mox Diamond, Mox Opal |
| Kinnan | removal/stack | Fierce Guardianship, Flusterstorm, Force of Will, Mental Misstep |
| Kraum + Tymna | tutor/draw | Demonic Tutor, Enlightened Tutor, Esper Sentinel, Mystic Remora, Rhystic Study |
| Thrasios + Tymna | tutor/protection | Demonic Tutor, Vampiric Tutor, Silence, Grand Abolisher, Veil of Summer |
| Spider-Man 2099 | tempo/removal | Force Spike, Galvanic Discharge, Ghostfire Slice, Spell Snare |

### Package clusters

`package_clusters.json` guarda pares que coocorrem por shell, com `evidence_count`, `confidence`, subformato e freshness local. A leitura util para optimize/generate e por pacote, nao por popularidade isolada:

- Kinnan: fast mana/dork + tutor/untap/protecao.
- Kraum/Tymna: draw engine + tutor + free/cheap interaction + breach/consultation protection window.
- Thrasios/Tymna: partner goodstuff com ramp, tutor, stax/protecao e draw persistente.
- Spider-Man 2099: pacote UR tempo/aggro de Duel Commander; deve ficar fora de pools cEDH multiplayer.

### Role replacements

`role_replacements.json` cruza penalidades historicas de qualidade com candidatos de mesmo role e evidencia meta. Exemplos gerados:

| Rejeitado/demovido | Role | Substituto sinalizado | Evidencia |
|---|---|---|---|
| Brainstorm | draw | Esper Sentinel | high, evidence_count 23 |
| Lotus Petal | ramp | Lion's Eye Diamond | high, evidence_count 23 |
| Vandalblast | removal | Spell Snare | high, evidence_count 29 |
| Blasphemous Act | wipe | Demonic Consultation | high, evidence_count 22 |

Interpretacao: esses exemplos nao significam que a carta rejeitada e sempre fraca; significam que ela apareceu em historico de rejeicao/quality gate neste contexto agregado. O consumo correto e democao contextual + substituto de mesmo role, nunca banimento global.

### Budget/premium

`budget_premium_alternatives.json` foi gerado, mas a maioria dos roles retornou `price_gap=not_proven_price_data_sparse` porque os campos canonicos `price_usd/price_usd_foil` continuam sem cobertura confiavel para esses printings. Portanto nenhum sinal de budget/premium deve ser promovido como decisao de produto nesta etapa.

### Evidencia e confianca

Cada row persistida por `aggressive_meta_signal_v1` inclui em `evidence`:

- `source`
- `subformat`
- `confidence`
- `evidence_count`
- `deck_count`
- `freshness`
- `forced_swap=false`

Categorias de confianca:

- `high`: evidencia alta/fresca ou fonte competitiva forte.
- `medium_high`/`medium`: evidencia suficiente, mas menos robusta.
- `low`: evidencia limitada ou stale.
- `not_proven`: nao persistido quando identidade do comandante nao resolve ou evidencia nao passa o minimo.

### Dry-run/apply/idempotencia

Dry-run:

- `db_mutations=false`
- `card_role_scores`: 30988 antes/depois
- `commander_card_synergy`: 5000 antes/depois
- `commander_signal_rows_planned`: 2179
- `role_score_rows_planned`: 910

Apply:

| Tabela | Pre | Post |
|---|---:|---:|
| `card_role_scores` | 30988 | 31898 |
| `commander_card_synergy` | 5000 | 7179 |
| `meta_decks` | 650 | 650 |
| `external_commander_meta_candidates` | 10 | 10 |
| `commander_reference_profiles` | 18 | 18 |
| `optimize_rejection_penalties` | 358 | 358 |

Idempotencia:

| Tabela | Pre | Post |
|---|---:|---:|
| `card_role_scores` | 31898 | 31898 |
| `commander_card_synergy` | 7179 | 7179 |
| `stale_generated_rows_before_apply.card_role_scores` | 0 | 0 |
| `stale_generated_rows_before_apply.commander_card_synergy` | 0 | 0 |

### Rollback parcial da etapa 2

```sql
DELETE FROM card_role_scores WHERE source = 'aggressive_meta_signal_v1';
DELETE FROM commander_card_synergy WHERE source = 'aggressive_meta_signal_v1';
```

Nenhum rollback parcial toca em `cards`, `card_legalities`, `sets`, `decks`, `meta_decks`, `external_commander_meta_candidates`, `commander_reference_profiles` ou dados de usuario.

### Fatos provados vs interpretacao

Fatos provados por codigo/banco:

- Existem 650 `meta_decks`, 10 `external_commander_meta_candidates`, 18 `commander_reference_profiles`.
- 385 decks Commander/cEDH locais foram escaneados.
- 9 candidatos externos passaram o filtro local de confianca.
- 2179 rows foram aplicadas em `commander_card_synergy` e 910 em `card_role_scores` com `source='aggressive_meta_signal_v1'`.
- Os dados aplicados sao idempotentes.

Interpretacao estrategica:

- Kinnan deve alimentar pools de ramp/combo, nao generic GU value.
- Kraum/Tymna e Thrasios/Tymna devem alimentar pools cEDH de draw/tutor/interaction/protection por pacote.
- Spider-Man 2099 deve alimentar apenas Duel Commander/tempo UR.

`not_proven`:

- Nenhuma pesquisa web nova foi usada nesta etapa.
- `commander_reference_profiles` nao prova contexto cEDH.
- `created_at/updated_at` local nao e data real do evento externo.
- Budget/premium ainda nao e confiavel.

### Menores proximas acoes tecnicas

1. Ligar um provider read-only no runtime do optimize que leia `aggressive_meta_signal_v1` apenas como bonus/democao, nunca como bypass de legalidade/cor/bracket.
2. Corrigir/validar identidades dos comandantes novos que ficaram em `unknown_commander_labels`.
3. Melhorar role classifier para evitar mislabels conhecidos, especialmente roles genericos em cartas de combo.
4. Separar package clusters multi-card no runtime em vez de promover cartas isoladas por popularidade.
5. Reprocessar preco canonico antes de usar budget/premium como criterio real.
