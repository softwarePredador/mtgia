# Commander Reference Deck Corpus Roles v2 — 2026-05-13

## Verdict

**PASS** para o refinamento do classificador de roles do corpus Lorehold.

O objetivo era reduzir o bucket generico `other` antes de expandir o corpus
para mais comandantes. O corpus de `Lorehold, the Historian` foi reprocessado
com roles especificos de spellslinger/topdeck/big spells.

## Roles adicionados

- `spellslinger`;
- `miracle_topdeck`;
- `exile_value`;
- `big_spell_payoff`;
- `recursion`;
- `ritual_treasure`.

## Resultado agregado

| Role | Antes | Depois |
| --- | ---: | ---: |
| `other` | `27.00` | `13.00` |
| `miracle_topdeck` | `0.00` | `4.33` |
| `big_spell_payoff` | `0.00` | `7.67` |
| `ritual_treasure` | `0.00` | `10.00` |
| `spellslinger` | `0.00` | `3.67` |
| `exile_value` | `0.00` | `3.67` |
| `recursion` | `0.00` | `4.33` |
| `protection` | `2.33` | `3.67` |

Outros roles tambem foram redistribuidos:

- `lands`: `32.00`;
- `interaction`: `4.33`;
- `draw_value`: `2.67`;
- `creature`: `3.67`;
- `board_wipe`: `2.00`;
- `win_condition`: `1.33`;
- `ramp`: `3.67`.

## Comandos executados

```bash
cd server && dart test test/commander_reference_deck_corpus_support_test.dart -r expanded
cd server && dart run bin/commander_reference_deck_corpus.dart --corpus-json=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/lorehold_edhrec_deckpreview_corpus.json --dry-run --artifact-dir=test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/dry_run
cd server && dart run bin/commander_reference_deck_corpus.dart --corpus-json=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/lorehold_edhrec_deckpreview_corpus.json --apply --artifact-dir=test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/apply
cd server && dart run bin/commander_reference_deck_corpus.dart --corpus-json=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/lorehold_edhrec_deckpreview_corpus.json --apply --artifact-dir=test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/apply_idempotency
cd server && dart analyze lib routes test
cd server && dart test test/commander_reference_deck_corpus_support_test.dart test/ai_generate_performance_support_test.dart test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart -r expanded
```

## Correcao de falsos positivos

A primeira passada publica mostrou que a nova taxonomia estava semanticamente
melhor, mas ainda havia falso positivo em roles relevantes:

- `Deflecting Swat` caiu como `big_spell_payoff`; agora e `protection`.
- `Hit the Mother Lode` e `Call Forth the Tempest` agora priorizam
  `big_spell_payoff` antes de heuristicas de topdeck.

Tambem foi ajustado o budget default do caminho OpenAI com referencia
Commander/Brawl de `20s` para `24s`. O caminho legado sem referencia continua
usando o timeout existente.

## Artifacts

- `server/test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/dry_run/lorehold_the_historian_dry_run_summary.json`;
- `server/test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/apply/lorehold_the_historian_apply_summary.json`;
- `server/test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/apply_idempotency/lorehold_the_historian_apply_summary.json`.

## Riscos

- O classificador ainda e heuristico e focado em Lorehold; ao expandir para
  outros arquétipos, novos roles devem ser adicionados com testes.
- A primeira prova publica v2 antes do ajuste de timeout preservou legalidade,
  mas subiu fallback por timeout. A expansao para novos comandantes permanece
  bloqueada ate a prova publica pos-deploy do ajuste de `24s`.

## Prova publica pos-deploy

Backend publico: `353ab5737e407a802eaac78733bdde53303f9ab6`.

| Modo | HTTP 200 | Validacao | Lorehold preservado | Corpus usado | Fallback | Overlap top40 medio | p95 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| com `commander_name` | `5/5` | `5/5` | `5/5` | `5/5` | `1/5` | `11.6` | `24922ms` |
| sem `commander_name` | `5/5` | `5/5` | `0/5` | `0/5` | `5/5` | `0.0` | `12667ms` |

Comparacao com a prova publica anterior (`9909e0b`):

- antes com corpus: fallback `0/5`, overlap medio `16.2`, p95 `21034ms`;
- agora com roles v2 + timeout `24s`: fallback `1/5`, overlap medio `11.6`,
  p95 `24922ms`;
- baseline sem comandante piorou na amostra atual e nao preservou Lorehold.

Conclusao: a taxonomia ficou semanticamente mais correta e reduz `other`, mas
o gate de expansao nao foi atingido porque a prova publica piorou fallback,
overlap e latencia contra a rodada anterior. Nao expandir corpus ainda.

Artifact:
`server/test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/public_expanded/summary.json`.

## Iteracao Lorehold Reference Off-Color Fix v4

### Diagnostico v3

O artefato publico v3 mostrou `5/5` HTTP 200, `5/5`
`validation.is_valid=true`, `5/5` Lorehold preservado, `main_quantity=99` e
fallback `0/5`, mas tambem registrou auto-reparo off-color em `4/5` probes com
comandante. O artefato sanitizado nao preservou nomes de cartas e nao ha
decklists brutas versionadas; portanto os nomes exatos das cartas removidas em
v3 ficam **not_proven**.

A auditoria local dos sinais persistidos indica:

- Reference Card Stats de Lorehold ja possui auditoria off-color antes do apply;
- o corpus Lorehold continua aceito com `off_color_count=0`;
- o fallback deterministico manual e Boros/colorless, mas podia aceitar uma carta
  ruim se ela entrasse futuramente por stats/corpus/profile;
- a causa mais provavel do reparo publico v3 e inferencia do modelo a partir de
  conhecimento generico de miracle/topdeck, nao uma carta off-color persistida em
  profile/card_stats/corpus. Probabilidade por origem:
  - profile/card_stats/corpus: **not_proven** para nomes, baixo sinal local;
  - archetype reuse: nao usado nos probes exatos de Lorehold;
  - fallback: nao usado nos probes v3 com comandante;
  - prompt/OpenAI: causa mais provavel porque o reparo ocorreu antes do validator
    em respostas OpenAI sem fallback.

### Mudancas v4

- Cache/prompt policy de `/ai/generate` com reference guidance:
  `ai_generate_reference_prompt_v3`.
- Prompt do Commander Reference Profile reforcado para proibir inferencia de
  pacotes genericos off-color e omitir carta com identidade incerta.
- Pre-validacao reference-guided filtra a lista candidata da OpenAI contra a
  identidade do profile antes do `GeneratedDeckValidationService`; se a remocao
  deixa a lista curta, recompõe com fallback deterministico reference-guided.
- Fallback deterministico ignora exemplos de `avoid_patterns`, reduzindo risco de
  candidatos off-color caso dados ruins cheguem por stats/corpus/profile.
- Nenhum timeout foi aumentado e nenhuma validacao foi enfraquecida.

### Comandos locais v4

```bash
cd server && dart format lib/ai/commander_reference_generate_fallback_support.dart lib/ai/commander_reference_profile_support.dart routes/ai/generate/index.dart test/commander_reference_card_stats_support_test.dart test/commander_reference_profile_support_test.dart
cd server && dart test test/commander_reference_card_stats_support_test.dart test/commander_reference_profile_support_test.dart -r expanded
cd server && dart analyze lib routes test
cd server && dart test test/commander_reference_deck_corpus_support_test.dart test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart test/ai_generate_performance_support_test.dart -r expanded
cd server && dart run bin/commander_reference_deck_corpus.dart --corpus-json=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/lorehold_edhrec_deckpreview_corpus.json --dry-run --artifact-dir=test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/dry_run
cd server && dart run bin/commander_reference_deck_corpus.dart --corpus-json=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/lorehold_edhrec_deckpreview_corpus.json --apply --artifact-dir=test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/apply
cd server && dart run bin/commander_reference_deck_corpus.dart --corpus-json=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/lorehold_edhrec_deckpreview_corpus.json --apply --artifact-dir=test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/apply_idempotency
```

### Reprocessamento v4

| Modo | Status | Decks | Accepted | Rejected | Off-color |
| --- | --- | ---: | ---: | ---: | ---: |
| dry-run | `PASS` | `3` | `3` | `0` | `0` |
| apply | `PASS` | `3` | `3` | `0` | `0` |
| apply idempotente | `PASS` | `3` | `3` | `0` | `0` |

### Gate pre-prova publica

Status: **not_proven** ate deploy e prova publica expandida do novo SHA.

## Proximo gate

Antes de expandir para novos comandantes, ajustar guidance/prompt de corpus
para recuperar aderencia top40 sem depender de fallback. Candidatos:

- separar cards obrigatorios/core package de cards apenas contextuais;
- reduzir tokens do prompt mantendo top packages mais importantes;
- medir `reference_deck_evaluation` por roles, nao apenas overlap top40;
- repetir prova publica ate atingir fallback `0/5` ou justificar
  explicitamente a latencia/risco.

## Iteracao de recuperacao — corpus packages v2

### Diagnostico da regressao

Roles v2 reduziu `other`, mas a prova publica nao melhorou porque o prompt ainda
enviava uma lista plana de cartas recorrentes e medias de roles. Com roles mais
granulares, sinais de alta recorrencia, identidade tematica e suporte funcional
ficaram misturados com cartas contextuais de baixo valor. Isso aumentou pressao
de prompt sem dizer ao modelo o que era core, o que era tematico e o que era
apenas contexto.

### Mudancas implementadas

- Corpus guidance v2 separa sinais em `core_package`, `theme_package`,
  `support_package` e `optional_contextual`.
- O prompt de `/ai/generate` agora envia apenas top roles e linhas compactas de
  core/theme/support; `optional_contextual` fica diagnostics-only.
- A versao de cache mudou para `reference_deck_corpus_v2:*`, incluindo os
  pacotes no material do hash.
- O fallback deterministico reference-guided usa Reference Card Stats + corpus
  core/theme/support antes de expected packages e terreno basico, em vez de
  depender do filler generico.
- Diagnostics opcionais adicionados:
  `corpus_package_counts` e `corpus_packages.{core_package,theme_package,
  support_package,optional_contextual}`.

### Comandos executados na iteracao

```bash
git pull --ff-only origin master
cd server && dart test test/commander_reference_deck_corpus_support_test.dart test/commander_reference_card_stats_support_test.dart -r expanded
cd server && dart analyze lib routes test
cd server && dart test test/commander_reference_deck_corpus_support_test.dart test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart test/ai_generate_performance_support_test.dart -r expanded
cd server && dart run bin/commander_reference_deck_corpus.dart --corpus-json=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/lorehold_edhrec_deckpreview_corpus.json --dry-run --artifact-dir=test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/dry_run
cd server && dart run bin/commander_reference_deck_corpus.dart --corpus-json=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/lorehold_edhrec_deckpreview_corpus.json --apply --artifact-dir=test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/apply
cd server && dart run bin/commander_reference_deck_corpus.dart --corpus-json=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/lorehold_edhrec_deckpreview_corpus.json --apply --artifact-dir=test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/apply_idempotency
```

### Reprocessamento Lorehold

| Modo | Status | Decks | Accepted | Rejected |
| --- | --- | ---: | ---: | ---: |
| dry-run | `PASS` | `3` | `3` | `0` |
| apply | `PASS` | `3` | `3` | `0` |
| apply idempotente | `PASS` | `3` | `3` | `0` |

Artifacts atualizados:

- `server/test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/dry_run/lorehold_the_historian_dry_run_summary.json`;
- `server/test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/apply/lorehold_the_historian_apply_summary.json`;
- `server/test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/apply_idempotency/lorehold_the_historian_apply_summary.json`.

### Gate

Status antes da prova publica do novo SHA: **not_proven**.

## Prova publica packages v2 pos-deploy

Backend publico:
`https://evolution-cartinhas.8ktevp.easypanel.host`.

SHA publico exato: `5cbd8a99b39c7a5d655dd08b79f15a48bfc9e23f`.

Commits inspecionados:

- `140d3b1eed4d0aed29bed188aa95d8e0f1987d12` — base sincronizada antes da
  sprint;
- `5cbd8a99b39c7a5d655dd08b79f15a48bfc9e23f` — deploy publico packages v2;
- `353ab5737e40240f0374c854164ecb79cf701be2` — prova publica Roles v2 final
  usada como regressao imediata.

Comandos adicionais executados:

```bash
git commit -m "Improve commander reference generate quality" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
git push origin master
python3 <poll /health ate git_sha=5cbd8a9>
python3 <public proof 5 Lorehold + 5 baseline, artifact sanitizado>
```

| Modo | HTTP 200 | Validacao | Lorehold preservado | Main 99 | Profile | Card stats | Corpus | Fallback | Timeout fallback | Overlap top40 medio | p50 | p95 | Max |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| com `commander_name` | `5/5` | `5/5` | `5/5` | `5/5` | `5/5` | `5/5` | `5/5` | `0/5` | `0/5` | `12.8` | `16363ms` | `17931ms` | `18244ms` |
| sem `commander_name` | `5/5` | `5/5` | `0/5` | `5/5` | `0/5` | `0/5` | `0/5` | `5/5` | `5/5` | `0.0` | `12685ms` | `12716ms` | `12722ms` |

Resultado de seguranca e validade:

- sem comandante nas 99 em `10/10`;
- sem erro de identidade de cor observado em `10/10`;
- corpus packages expostos em diagnostics no caminho com comandante:
  `core_package=26`, `theme_package=5`, `support_package=5`,
  `optional_contextual=4`;
- `reference_deck_evaluation.off_theme=0` em `5/5` com comandante;
- role coverage com comandante cobriu consistentemente
  `topdeck_miracle_setup`, `miracle_haymakers`,
  `spell_payoffs_copy_engines`, `interaction_and_resets` e `lands`;
- baseline sem comandante permaneceu valido, mas caiu sempre em fallback e nao
  ativou profile/card stats/corpus.

Comparacao:

- contra Roles v2 final, packages v2 melhorou fallback `1/5 -> 0/5`, p95
  `24922ms -> 17931ms` e overlap `11.6 -> 12.8`;
- contra a melhor prova anterior, packages v2 ainda nao recuperou overlap
  `16.2`, embora tenha mantido fallback `0/5` e melhorado p95
  `21034ms -> 17931ms`.

Classificacao: **PASS WITH RISKS**. A expansao para novos comandantes continua
bloqueada porque a aderencia top40 ainda nao bateu a melhor prova publica
anterior. O proximo passo tecnico e ajustar a selecao do prompt para aumentar
aderencia sem sacrificar fallback/latencia, possivelmente reduzindo duplicidade
entre profile expected packages, card stats e corpus core.

Artifact:
`server/test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/public_expanded/summary.json`.

## Iteracao Lorehold Reference Adherence v3

### Diagnostico v2

O artefato packages v2 tinha fallback `0/5` e p95 `17931ms`, mas a aderencia
top40 media ficou `12.8`. A leitura foi que o modelo recebia core/theme/support
com budgets parecidos e sem uma metrica pos-validacao de cobertura de core. O
`core_package` tinha 26 sinais, mas parte importante do primeiro bloco era land
ou papel generico, enquanto `optional_contextual` continuava citado no prompt.

### Mudancas implementadas

- Prompt/cache policy `reference_deck_corpus_v3:*`.
- Prompt v3 remove `optional_contextual` do texto enviado ao modelo, filtra lands
  da media de roles e limita core promptado a no maximo 2 lands.
- Ordenacao de prompt prioriza roles nao-land de core:
  `miracle_topdeck`, `big_spell_payoff`, `spellslinger/ritual_treasure`,
  `tutor/exile_value/draw_value`, `ramp`, interacao/protecao e depois lands.
- Classificador do corpus reconhece `tutor` e alguns removals/protecoes
  Lorehold que antes caiam como `other`.
- Diagnostics opcionais de runtime adicionados:
  `reference_deck_corpus_evaluation.{policy_version,core_package_available,
  core_package_matched,core_package_coverage_ratio,package_coverage,
  role_coverage}`.
- A primeira prova publica v3 em `be8e3ca` recuperou overlap medio `15.6` e
  manteve fallback `0/5`, mas acionou auto-reparo off-color em `5/5` respostas e
  p95 `23574ms`; antes de nova prova, o prompt de Commander Reference Profile
  foi reforcado para split/MDFC/adventure/aftermath/back-face e a cache key de
  generate reference-guided passou a incluir `ai_generate_reference_prompt_v2`.
- Nenhuma mudanca em timeout, validacao, singleton, color identity ou preservacao
  do comandante.

### Comandos executados na iteracao v3

```bash
cd server && dart format lib/ai/commander_reference_deck_corpus_support.dart routes/ai/generate/index.dart test/commander_reference_deck_corpus_support_test.dart
cd server && dart test test/commander_reference_deck_corpus_support_test.dart test/commander_reference_card_stats_support_test.dart -r expanded
cd server && dart run bin/commander_reference_deck_corpus.dart --corpus-json=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/lorehold_edhrec_deckpreview_corpus.json --dry-run --artifact-dir=test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/dry_run
cd server && dart run bin/commander_reference_deck_corpus.dart --corpus-json=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/lorehold_edhrec_deckpreview_corpus.json --apply --artifact-dir=test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/apply
cd server && dart run bin/commander_reference_deck_corpus.dart --corpus-json=test/artifacts/commander_reference_deck_corpus_lorehold_2026-05-12/lorehold_edhrec_deckpreview_corpus.json --apply --artifact-dir=test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/apply_idempotency
cd server && dart analyze lib routes test
cd server && dart test test/commander_reference_deck_corpus_support_test.dart test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart test/ai_generate_performance_support_test.dart -r expanded
```

### Reprocessamento v3

| Modo | Status | Decks | Accepted | Rejected |
| --- | --- | ---: | ---: | ---: |
| dry-run | `PASS` | `3` | `3` | `0` |
| apply | `PASS` | `3` | `3` | `0` |
| apply idempotente | `PASS` | `3` | `3` | `0` |

Roles agregados apos v3:

- `other`: `9.67` (v2: `13.00`);
- `tutor`: `3.67`;
- `interaction`: `5.33`;
- `big_spell_payoff`: `7.67`;
- `ritual_treasure`: `10.00`;
- `miracle_topdeck`: `4.33`.

### Prova publica v3 final

Backend publico:
`https://evolution-cartinhas.8ktevp.easypanel.host`.

SHA publico exato:
`036ff6570fc2257f7397252940c5424a157d4bad`.

Commits inspecionados:

- `104c146` — base sincronizada no inicio da sprint;
- `be8e3cabc52f3485b62e25ac7f9332f04ff96fc0` — v3 prefinal, melhorou
  overlap mas mostrou auto-reparo off-color;
- `036ff6570fc2257f7397252940c5424a157d4bad` — prompt de identidade reforcado.

Comandos adicionais executados:

```bash
git commit -m "Improve commander reference generate quality" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
git push origin master
python3 <poll /health ate git_sha=be8e3ca>
python3 <public proof 5 Lorehold + 5 baseline, artifact sanitizado>
cd server && dart analyze lib routes test
cd server && dart test test/commander_reference_deck_corpus_support_test.dart test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart test/ai_generate_performance_support_test.dart -r expanded
git commit -m "Improve commander reference generate quality" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
git push origin master
python3 <poll /health ate git_sha=036ff65>
python3 <public proof 5 Lorehold + 5 baseline, artifact sanitizado>
```

| Modo | HTTP 200 | Validacao | Lorehold preservado | Main 99 | Profile | Card stats | Corpus | Fallback | Timeout fallback | Off-color repair | Overlap top40 medio | Core matched avg | Core coverage avg | p50 | p95 | Max |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| com `commander_name` | `5/5` | `5/5` | `5/5` | `5/5` | `5/5` | `5/5` | `5/5` | `0/5` | `0/5` | `4/5` | `14.6` | `12.4/26` | `0.4769` | `19621ms` | `23684ms` | `24456ms` |
| sem `commander_name` | `5/5` | `5/5` | `0/5` | `5/5` | `0/5` | `0/5` | `0/5` | `5/5` | `5/5` | `0/5` | `0.0` | `0.0/26` | `0.0` | `12649ms` | `12678ms` | `12685ms` |

Resultado de validade e aderencia:

- comandante preservado e fora das 99 em `5/5`;
- `main_quantity=99` e `validation.is_valid=true` em `5/5`;
- fallback `0/5`, melhor que Roles v2 e igual packages v2;
- overlap top40 medio `14.6`, melhor que packages v2 `12.8`, mas ainda abaixo
  da melhor prova anterior `16.2`;
- core package matched medio `12.4/26`, claramente acima do baseline `0.0/26`;
- role coverage observou `miracle_topdeck`, `big_spell_payoff`,
  `ritual_treasure`, `tutor`, `draw_value`, `ramp`, `lands` e interacao em
  diferentes probes;
- p95 `23684ms`, acima do alvo preferencial `<=20000ms` e acima de packages v2
  `17931ms`;
- auto-reparo off-color apareceu em `4/5` respostas com comandante, apesar da
  lista final validada ficar legal apos reparo.

Classificacao: **BLOCKED** para expansao de corpus. A sprint melhorou aderencia
top40 e core coverage sem perder fallback, mas nao atingiu o gate de off-color e
latencia. Nao expandir para novos comandantes.

Proxima acao tecnica:

- reduzir causas de off-color antes do validator, possivelmente com allowlist
  R/W/colorless derivada dos pacotes ou retry deterministico quando houver
  `Auto-reparo: removidas ... fora da identidade de cor`;
- medir se uma selecao ainda mais compacta de prompt reduz p95 sem derrubar
  overlap/core coverage.

Artifact:
`server/test/artifacts/commander_reference_deck_corpus_lorehold_roles_v2_2026-05-13/public_expanded/summary.json`.
