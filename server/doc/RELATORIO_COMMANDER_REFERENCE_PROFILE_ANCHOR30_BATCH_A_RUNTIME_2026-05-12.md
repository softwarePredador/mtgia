# Commander Reference Profiles Anchor 30 Batch A Runtime — 2026-05-12

## Resultado

**PASS WITH RISKS.** O backend publico estava no commit esperado
`d7afb39` e os 8 Commander Reference Profiles Anchor 30 Batch A retornaram
`HTTP 200` em `/ai/generate`, com comandante preservado, `main_quantity=99`,
`validation.is_valid=true`, `reference_profile_used=true` e
`reference_card_stats_used=true`.

A classificacao nao e `BLOCKED`: nao houve 422 sistemico, 5xx, erro de auth
apos registro QA, nem indicio de DB incompleto para o lote. O risco restante era
diagnostico: uma amostra de Chulane retornou `invalid_cards_count=1` mesmo com
validacao final verdadeira. O follow-up de 2026-05-12 nao reproduziu o invalido
em nova amostra publica, confirmou `/cards/resolve` para Chulane e resolveu
35/35 cartas dos pacotes esperados; a classificacao atual e warning reparado
pelo validator/alucinacao isolada nao bloqueante.

Escopo fora deste relatorio: scanner/camera/OCR, secrets, tokens, JWT,
`DATABASE_URL`, `SENTRY_DSN`, `OPENAI_API_KEY`, prompts completos sensiveis e
decklists completas. Os probes registraram apenas resumo sanitizado.

## Commits inspecionados

| Origem | Evidencia |
| --- | --- |
| `master` local | `d7afb39 docs: add anchor 30 commander profiles batch a` |
| `origin/master` | `d7afb39 docs: add anchor 30 commander profiles batch a` |
| `/health` publico | `git_sha_prefix=d7afb39`, `environment=production`, `status=200` |

## Fontes consultadas

- `server/doc/RELATORIO_COMMANDER_REFERENCE_PROFILE_ANCHOR30_BATCH_A_2026-05-12.md`
- `server/doc/COMMANDER_REFERENCE_PROFILE_ANCHOR_30_PLAN_2026-05-12.md`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `server/manual-de-instrucao.md`

## Auth e metodo

- `POST /ai/generate` exige autenticacao no backend publico; foi criado usuario
  QA descartavel e sanitizado via `/auth/register`.
- O token foi usado apenas em memoria e nao foi registrado.
- Cada request usou `format=Commander`, `async=false`, `commander_name` exato
  para os probes principais e prompt curto tematico.
- Atraxa e Kinnan tiveram 3 amostras cada; os outros 6 comandantes tiveram 1
  amostra cada.
- Baselines de Atraxa e Kinnan omitiram `commander_name` para confirmar o
  contraste com o caminho legacy.

## Pass/fail summary

| Criterio | Resultado |
| --- | --- |
| Deploy esperado em `/health` | PASS, `git_sha` inicia com `d7afb39`. |
| Batch A com `commander_name` | PASS, 12/12 probes principais retornaram 200. |
| Cobertura dos 8 comandantes | PASS, 8/8 cobertos. |
| Comandante preservado | PASS, 12/12; Chulane normalizado pela primeira face antes de `//`. |
| `main_quantity=99` | PASS, 12/12. |
| `validation.is_valid=true` | PASS, 12/12. |
| Profile/stats ativos | PASS, 12/12 com `reference_profile_used=true` e `reference_card_stats_used=true`. |
| `unresolved_reference_cards` | PASS, 12/12 com 0. |
| Off-identity aproximado | PASS, 0 observado por buckets de validacao. |
| 422/5xx sistemico | PASS, nenhum observado. |
| Baseline sem `commander_name` | RISK conhecido: valido, mas legacy/fallback, sem profile/stats e sem preservar o comandante pedido. |

## Timing summary

| Grupo | Total | Min | P50 | Max | Observacao |
| --- | ---: | ---: | ---: | ---: | --- |
| Probes principais com `commander_name` | 12 | 633 ms | 8.870 ms | 18.351 ms | Primeira chamada por commander tende a caminho AI/cache-miss; repeticoes quentes caem para ~600-900 ms. |
| Baselines sem `commander_name` | 2 | 12.652 ms | 12.657 ms | 12.662 ms | Ambos retornaram fallback timeout valido e sem diagnostics de profile/stats. |
| `/health` | 1 | 978 ms | 978 ms | 978 ms | Liveness com commit esperado. |
| `/auth/register` | 1 | 788 ms | 788 ms | 788 ms | Usuario QA descartavel sanitizado. |

Latencia concentrada: geracao AI/cache-miss. O caminho de profile/stats ficou
consistente nos diagnostics e nao apareceu como gargalo isolado no payload
sanitizado.

## Generate path matrix

| Caso | Caminho observado |
| --- | --- |
| Atraxa, Praetors' Voice | Exact Commander Reference Profile + Reference Card Stats. |
| Korvold, Fae-Cursed King | Exact Commander Reference Profile + Reference Card Stats. |
| Muldrotha, the Gravetide | Exact Commander Reference Profile + Reference Card Stats. |
| Chulane, Teller of Tales | Exact profile/stats; retorno de commander como face dupla normalizavel. |
| Yuriko, the Tiger's Shadow | Exact Commander Reference Profile + Reference Card Stats. |
| Kinnan, Bonder Prodigy | Exact Commander Reference Profile + Reference Card Stats. |
| Winota, Joiner of Forces | Exact Commander Reference Profile + Reference Card Stats. |
| Prosper, Tome-Bound | Exact Commander Reference Profile + Reference Card Stats. |
| Baseline Atraxa sem `commander_name` | Legacy/fallback, `ai_generation_timed_out`, sem profile/stats e comandante nao preservado. |
| Baseline Kinnan sem `commander_name` | Legacy/fallback, `ai_generation_timed_out`, sem profile/stats e comandante nao preservado. |

Conclusao de contrato: `commander_name` e o gatilho necessario para ativar os
profiles Anchor 30 e preservar o comandante alvo no runtime publico atual.

## Resumo sanitizado por probe

| Probe | Status | Elapsed | Warning/fallback | Commander returned | Preserved | Main | Valid | Invalid | Profile | Stats | On-theme | Unresolved | Off-id approx |
| --- | ---: | ---: | --- | --- | --- | ---: | --- | ---: | --- | --- | ---: | ---: | ---: |
| Atraxa s1 | 200 | 15.384 ms | none | Atraxa, Praetors' Voice | yes | 99 | true | 0 | true | true | 36 | 0 | 0 |
| Atraxa s2 | 200 | 824 ms | none | Atraxa, Praetors' Voice | yes | 99 | true | 0 | true | true | 36 | 0 | 0 |
| Atraxa s3 | 200 | 839 ms | none | Atraxa, Praetors' Voice | yes | 99 | true | 0 | true | true | 36 | 0 | 0 |
| Korvold s1 | 200 | 18.351 ms | none | Korvold, Fae-Cursed King | yes | 99 | true | 0 | true | true | 35 | 0 | 0 |
| Muldrotha s1 | 200 | 8.972 ms | none | Muldrotha, the Gravetide | yes | 99 | true | 0 | true | true | 34 | 0 | 0 |
| Chulane s1 | 200 | 14.778 ms | none | Chulane, Teller of Tales // Chulane, Teller of Tales | yes | 99 | true | 1 | true | true | 35 | 0 | 0 |
| Yuriko s1 | 200 | 13.489 ms | none | Yuriko, the Tiger's Shadow | yes | 99 | true | 0 | true | true | 42 | 0 | 0 |
| Kinnan s1 | 200 | 10.851 ms | none | Kinnan, Bonder Prodigy | yes | 99 | true | 0 | true | true | 35 | 0 | 0 |
| Kinnan s2 | 200 | 633 ms | none | Kinnan, Bonder Prodigy | yes | 99 | true | 0 | true | true | 35 | 0 | 0 |
| Kinnan s3 | 200 | 642 ms | none | Kinnan, Bonder Prodigy | yes | 99 | true | 0 | true | true | 35 | 0 | 0 |
| Winota s1 | 200 | 8.768 ms | none | Winota, Joiner of Forces | yes | 99 | true | 0 | true | true | 36 | 0 | 0 |
| Prosper s1 | 200 | 8.601 ms | none | Prosper, Tome-Bound | yes | 99 | true | 0 | true | true | 35 | 0 | 0 |

## Package keys observados

| Commander | Package keys sanitizados |
| --- | --- |
| Atraxa | `counter_payoffs`, `infect_poison_optional`, `interaction_and_protection`, `proliferate_engines`, `superfriends` |
| Korvold | `aristocrats`, `combo_lines`, `sacrifice_fodder_value`, `sacrifice_outlets`, `tutors_interaction` |
| Muldrotha | `combo_finishers`, `interaction`, `recursion_value`, `self_mill`, `soft_locks_utility` |
| Chulane | `bounce_loop`, `creature_ramp`, `protection_interaction`, `tutors`, `value_creatures` |
| Yuriko | `cedh_combo`, `evasive_enablers`, `high_mv_reveals`, `interaction`, `ninjas`, `topdeck_manipulation` |
| Kinnan | `artifact_mana`, `infinite_mana`, `mana_dorks`, `payoffs`, `tutors_interaction` |
| Winota | `combat_payoffs`, `human_hits`, `nonhuman_enablers`, `protection`, `stax` |
| Prosper | `exile_casting`, `interaction`, `rituals`, `storm_combo`, `treasure_payoffs` |

## Baseline sem `commander_name`

| Baseline | Status | Elapsed | Warning/fallback | Commander returned | Preserved | Main | Valid | Profile | Stats |
| --- | ---: | ---: | --- | --- | --- | ---: | --- | --- | --- |
| Atraxa prompt-only | 200 | 12.662 ms | `ai_generation_timed_out` | Isamaru, Hound of Konda | no | 99 | true | null | null |
| Kinnan prompt-only | 200 | 12.652 ms | `ai_generation_timed_out` | Isamaru, Hound of Konda | no | 99 | true | null | null |

O baseline confirma compatibilidade legacy, mas tambem confirma que consumidores
mobile precisam enviar `commander_name` quando o usuario escolhe um comandante
especifico.

## App/backend contract findings

- Nao houve drift obrigatorio de shape: o runtime retornou os campos
  app-facing ja documentados (`generated_deck`, `validation`, `diagnostics`,
  `warnings`, `cache`, `timings` quando disponiveis).
- `diagnostics.reference_profile_used`, `reference_card_stats_used`,
  `on_theme_candidate_count`, `unresolved_reference_cards` e `package_keys`
  foram suficientes para a previa/app medir se o profile foi realmente usado.
- O retorno de Chulane como `"Chulane, Teller of Tales // Chulane, Teller of
  Tales"` e consumivel quando normalizado pela primeira face, mas pode gerar
  falso negativo se o app fizer comparacao textual exata.
- O baseline prova que app antigo que omite `commander_name` continua recebendo
  resposta valida, mas nao recebe as garantias de profile/stats/preservacao do
  comandante.

## Legalidade e identidade de cor

- 12/12 probes principais foram validos para Commander.
- 12/12 preservaram o commander escolhido.
- 12/12 retornaram 99 cartas no main.
- 12/12 tiveram `unresolved_reference_cards=0`.
- Nenhum bucket sanitizado indicou violacao de identidade de cor.
- Nenhum 422 foi observado; por isso nao houve buckets de invalid_cards 422 a
  extrair.

## Follow-up Chulane `invalid_cards_count=1`

**Resultado:** non-blocking. O nome exato da carta invalida original nao esta
recuperavel nos artefatos versionados porque o runtime Batch A persistiu apenas
resumos sanitizados, por desenho, sem decklist/payload completo. A nova amostra
publica de Chulane retornou `HTTP 200`, `validation.is_valid=true`,
`main_quantity=99`, `stats.invalid_cards=0`, `validation.invalid_cards=[]` e
`warnings.invalid_cards=[]`.

Evidencia sanitizada:

| Checagem | Resultado |
| --- | --- |
| Nome sanitizado original | `not_recorded_in_sanitized_artifact` |
| Bucket classificado | `validator_repaired_warning_or_isolated_hallucination` |
| `/cards/resolve` Chulane | `200`, `source=local`, match prefix para `Chulane, Teller of Tales // Chulane, Teller of Tales` |
| Pacotes esperados Chulane | `35/35` resolvidos via `/cards/resolve/batch`, `0` unresolved, `0` ambiguous |
| Nova amostra publica Chulane | `invalid_cards=0`, commander preservado, main `99`, profile/stats ativos |

Classificacao por causa:

| Hipotese | Status | Evidencia |
| --- | --- | --- |
| Nome inexistente/alucinado | Provavel para a amostra original, mas nao reproduzido | Validator permite deck valido removendo sugestao invalida e reparando tamanho; nova amostra nao trouxe invalido. |
| Split face | Descartado como blocker | Chulane resolve localmente por prefix para o nome double-faced armazenado. |
| Acento/pontuacao | Nao provado | Nenhuma entrada invalida foi preservada no artefato; pacotes esperados resolvem 35/35. |
| Legalidade | Nao provado | `validation.is_valid=true`, off-id aproximado `0`, sem 422. |
| Print ausente no DB | Descartado para profile | Pacotes esperados resolvem 35/35 no backend publico. |
| Query `/cards`/`/cards/resolve` | Descartado para Chulane/profile | Resolve publico retorna 200 para comandante e pacote esperado. |
| Warning reparado pelo validator | Classificacao operacional | Contador original ficou em `invalid_cards_count=1`, mas o deck final foi valido e a nova amostra retornou 0 invalidos. |

Decisao: nao alterar codigo nem profile neste stage. A anomalia nao bloqueia os
profiles ja aprovados. O risco remanescente e de observabilidade: se for
necessario diagnosticar nomes invalidos em producao sem vazar decklists, adicionar
bucket sanitizado/hash do nome invalido em telemetry segura ou em artefato QA
explicitamente sanitizado.

## Sentry/logging findings

- Sentry nao foi observado diretamente pelo runtime publico.
- Erros/avisos de contrato vistos nos baselines (`ai_generation_timed_out`) foram
  estruturados e nao vazaram tokens, prompts completos, secrets ou decklists.
- Recomendacao: taggear fallback timeout, profile/stats usados e
  `invalid_cards_count>0 && validation.is_valid=true` em telemetry/Sentry para
  facilitar triagem sem payload sensivel.

## Blockers

Nenhum blocker ativo. O deploy estava no SHA esperado, auth funcionou com QA
descartavel, e `/ai/generate` respondeu 200 para os 8 commanders do Batch A.

## Smallest next fixes

1. Normalizar `commander_returned` para faces duplas no diagnostic/contract ou
   documentar explicitamente que consumidores devem comparar a primeira face.
2. Garantir que a tela de gerar deck sempre envie `commander_name` quando o
   usuario selecionar/digitar comandante, pois prompt-only nao ativa Anchor 30.
3. Adicionar tags de observabilidade para timeout/fallback e diagnostics de
   Commander Reference sem registrar prompt/decklist.
4. Se `invalid_cards_count>0 && validation.is_valid=true` reaparecer, registrar
   apenas bucket sanitizado/hash do nome invalido em QA telemetry para permitir
   reproducao sem persistir decklist.

## Comandos executados

```bash
git status --short --branch
git fetch origin master --quiet
git pull --ff-only --quiet
git log -1 --oneline
curl/urllib GET https://evolution-cartinhas.8ktevp.easypanel.host/health
POST /auth/register com usuario QA descartavel sanitizado
POST /ai/generate para 12 probes principais com commander_name exato
POST /ai/generate para 2 baselines sem commander_name
POST /ai/generate Chulane follow-up publico com resumo sanitizado
POST /cards/resolve Chulane no backend publico
POST /cards/resolve/batch para 35 cartas dos pacotes esperados Chulane
git diff --check
scan simples de secrets nos arquivos alterados
```

## Validacoes finais

- `git diff --check`: executado no fechamento desta auditoria.
- Scan simples de secrets: executado apenas sobre arquivos alterados.
- Analyze/test de codigo: nao aplicavel porque a auditoria alterou apenas
  documentacao e nao mudou `lib`, `routes`, `bin` ou `test`.
