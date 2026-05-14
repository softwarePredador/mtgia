# Commander Reference Pipeline Gap Audit - 2026-05-14

## Resultado

**PASS_WITH_RISKS / NO-GO para expandir diretamente para 50 comandantes.**

O fluxo atual de Commander Reference em `POST /ai/generate` ja prova valor real:
o caminho com profile/card stats/corpus forte para Lorehold ficou deterministico,
valido, rapido e app-consumivel. A prova publica Lorehold v5 registrou `5/5`
HTTP 200, `5/5` validacao, comandante preservado, `main_quantity=99`,
profile/stats/corpus usados, fallback `0/5`, timeout fallback `0/5`,
off-color `0`, overlap medio `36.0`, core coverage `26/26` e p95 `1648ms`.

Mesmo assim, a expansao para 50 ainda tem gaps de pipeline: tratamento de 429 no
backend OpenAI, cache key do caminho archetype, scorecard sem cobertura de
diversidade/compliance/iPhone/rate-limit, classifier de roles ainda heuristico,
dedupe fraco de corpus, artifacts com decklists brutas e prova app iPhone
ausente.

## Commits inspecionados

| Item | Valor |
| --- | --- |
| Branch alvo | `master` |
| HEAD local auditado | `37fc1bca3f42fcbb1baacb18bcae9483b9edeb05` |
| `origin/master` no inicio da auditoria | `5216c9e2cd5380e727b5e53d2cb2df8ab7b5c4a7` |
| Estado local | `master` ahead de `origin/master` por commits doc-only preexistentes |
| Prova publica Lorehold v5 citada | `d1e1b18474fd558211cbff16f1fa92192de06417` |
| Lote C/app runtime citado | `c182df4`, `ef2df98` em relatorios existentes |

## Fontes lidas

- `.github/instructions/guia.instructions.md`
- `server/routes/ai/generate/index.dart`
- `server/lib/ai/commander_reference_profile_support.dart`
- `server/lib/ai/commander_reference_card_stats_support.dart`
- `server/lib/ai/commander_reference_deck_corpus_support.dart`
- `server/lib/ai/commander_reference_generate_fallback_support.dart`
- `server/lib/ai/commander_reference_readiness_support.dart`
- `server/lib/ai_generate_performance_support.dart`
- `server/lib/openai_runtime_config.dart`
- `server/bin/commander_reference_profile.dart`
- `server/bin/commander_reference_deck_corpus.dart`
- `server/bin/commander_reference_readiness_scorecard.dart`
- `server/test/commander_reference_*_test.dart`
- `server/test/ai_generate_performance_support_test.dart`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- relatorios Commander Reference recentes em `server/doc/`
- handoffs mobile em `app/doc/runtime_flow_handoffs/`
- `app/lib/features/decks/providers/deck_provider_support_generation.dart`
- `app/lib/features/decks/screens/deck_generate_screen.dart`
- testes app de generate em `app/test/features/decks`

## Comandos executados

```bash
git --no-pager status --short --branch
git --no-pager log -1 --oneline
git --no-pager log --oneline --decorate -8
find server/lib server/bin server/test server/doc app/doc -path '*commander_reference*' -o -path '*COMMANDER_REFERENCE*'
grep/sed/python3 para inspecionar cache, 429, artifacts e summaries sanitizados

cd server
dart analyze lib/ai routes/ai/generate bin/commander_reference_deck_corpus.dart bin/commander_reference_profile.dart bin/commander_reference_readiness_scorecard.dart test/commander_reference_card_stats_support_test.dart test/commander_reference_deck_corpus_support_test.dart test/commander_reference_readiness_support_test.dart test/ai_generate_performance_support_test.dart
dart test test/commander_reference_card_stats_support_test.dart test/commander_reference_deck_corpus_support_test.dart test/commander_reference_readiness_support_test.dart test/ai_generate_performance_support_test.dart
```

Resumo: `dart analyze` focado **PASS**; testes focados **PASS**, `39/39`.

## Matriz de caminhos atuais de `/ai/generate`

| Caminho | Condicao | Resultado/risco |
| --- | --- | --- |
| Async app default | App envia `async=true`; backend cria job e executor interno chama a rota sync | App poll lida com 429 de job polling com backoff; falhas 4xx/5xx do executor viram job failed. |
| Exact profile + corpus forte | `commander_name` com profile usavel e `shouldUseCompactCommanderReferenceCorpusPrompt=true` | Usa fast path deterministico antes da OpenAI. Excelente latencia, mas aumenta risco de baixa variacao/overfit. |
| Exact profile sem fast path | Profile usavel, stats/corpus opcionais, sem corpus forte | Monta prompt com profile/stats/corpus e chama OpenAI; valida/repara depois. |
| Archetype reuse | Sem exact profile; stats compativeis por cor/prompt/theme | Injeta guidance lower-confidence; cache version hoje nao inclui policy de prompt. |
| Sem `OPENAI_API_KEY` | Chave ausente | Fallback deterministico/mock com warning `openai_api_key_missing`, cache curto. |
| Timeout OpenAI | `TimeoutException` | Fallback deterministico validado; se valido, cache 120s; se invalido, 422. |
| OpenAI 401 dev/staging | `shouldUseFallbackForInvalidApiKey=true` | Fallback deterministico dev-safe. |
| OpenAI 429/5xx | `response.statusCode != 200` e nao 401 dev/staging | Retorna `apiError(status, 'OpenAI API Error: ${response.body}')`; sem fallback sanitizado para 429. |
| AI output invalido | Validacao falha apos parse | Tenta fallback deterministico; se valido, retorna reparado com `ai_generation_repaired_by_fallback`. |
| Legacy sem comandante | App antigo ou campo comandante vazio | Continua compativel; pode cair em fallback generico e nao usa diagnostics Commander Reference. |

## Timing e qualidade provados

| Evidencia | Resultado |
| --- | --- |
| Lorehold v5 com `commander_name` | `5/5` validos, corpus/profile/stats `5/5`, fallback `0/5`, p50 `980ms`, p95 `1648ms`, max `1764ms`. |
| Lorehold baseline sem `commander_name` | `5/5` validos, comandante Lorehold `0/5`, fallback `5/5`, p95 `12747ms`. |
| Sprint 3 A+B | 8 comandantes promovidos com public proof 5/5 e scorecard final `100/ready_for_mini_batch`; app runtime real parcial em Android. |
| Sprint 3 C | Brago promovido; Purphoros/Veyran/Balan bloqueados corretamente no scorecard apesar de public/app validity parcial. |
| App runtime | Android fisico provou preview/save/details/validate para lotes recentes; iPhone 15 segue nao provado para o batch representativo. |

## App/backend contract findings

- O app envia `commander_name` no async e no fallback sync, preservando backward
  compatibility para apps antigos que omitem o campo.
- O app usa `generated_deck` e `validation` como fonte de verdade, remove o
  comandante das 99 antes de salvar e insere o comandante com `is_commander=true`.
- Diagnostics Commander Reference sao apenas logados no app
  (`reference_profile_used`, `reference_card_stats_used`, `on_theme_candidate_count`,
  `unresolved_reference_cards`); nao sao assertados no runtime app para todos os
  promovidos.
- O polling mobile tem tratamento especifico para 429 em `/ai/generate/jobs/:id`,
  mas isso nao cobre 429 recebido pelo backend ao chamar OpenAI dentro do job.
- `API_CONTRACTS_AND_DATA_MAP.md` ainda documenta trechos de Commander Deck
  Corpus como `v3`, enquanto o codigo/testes usam `reference_deck_corpus_v4`.

## Findings P0-P3

### P0 - Nenhum bug P0 comprovado no caminho promovido atual

Nao ha evidencia de quebra imediata em legalidade Commander, identidade de cor,
singleton, comandante fora das 99 ou consumo app para os caminhos ja promovidos.
Os testes focados passaram e os public proofs recentes sustentam o estado atual.

### P1 - OpenAI 429/5xx nao tem fallback/sanitizacao equivalente a timeout

**Evidencia:** em `server/routes/ai/generate/index.dart`, status OpenAI diferente
de 200 so recebe fallback especial para 401 de chave invalida em ambiente nao
prod. 429/5xx retornam `OpenAI API Error: ${response.body}`.

**Impacto:** em expansao para 50 comandantes, batches podem bater rate limit. O
Lote B ja preservou attempts rate-limited em artifacts, e a estrategia mobile
tambem registra risco de 429 publico. Hoje o app trata 429 de polling, mas nao
evita que o executor interno falhe quando a OpenAI responde 429.

**Patch sugerido, nao aplicado:** ramo para `response.statusCode == 429` com
warning `openai_rate_limited_deterministic_fallback`; usar fallback
deterministico validado quando possivel e retornar erro externo sanitizado quando
o fallback nao validar.

### P1 - Corpus bruto/decklists em artifacts aumentam risco de compliance

**Evidencia:** existem varios `server/test/artifacts/**/corpus.json` e
`*_edhrec_*_corpus.json` com arrays `decks[].cards` completos. A geracao consome
agregados sanitizados, mas o repo ainda versiona corpus bruto usado na preparacao.

**Impacto:** antes de 50 comandantes, multiplicar raw decklists no repositorio
aumenta risco de copiar listas publicas ou manter material que deveria ficar em
storage operacional/controlado.

**Recomendacao:** commitar apenas agregados sanitizados, hashes, source keys,
contadores e summaries; mover raw corpus para storage interno ou regeneracao
local auditada. Adicionar check que bloqueie artifacts publicos com `cards[]`
completos.

### P1 - Cache key do caminho archetype nao inclui policy version de prompt

**Evidencia:** exact profile monta cache version com
`_aiGenerateReferencePromptPolicyVersion`, profile, stats e corpus. Quando nao ha
exact profile, `_buildReferenceGenerateCacheVersion` retorna apenas
`archetype_reference_v1:*` derivado dos stats.

**Impacto:** mudancas futuras em `buildCommanderReferenceArchetypeStatsPrompt`
podem reutilizar cache antigo se os stats nao mudarem.

**Patch sugerido, nao aplicado:** incluir `_aiGenerateReferencePromptPolicyVersion`
tambem no cache material do archetype path e cobrir com teste de cache key.

### P1 - Fast path deterministico pode mascarar falta de variacao

**Evidencia:** o fast path reference-guided primario para corpus forte explica a
queda de p95 para `1648ms` e overlap/core coverage altos. Isso e bom para
latencia e legalidade, mas a prova atual tambem mostra listas muito aderentes ao
mesmo core.

**Impacto:** o scorecard pode declarar readiness por aderencia ao corpus, sem
medir diversidade controlada, variacao entre runs, curva/roles em relacao ao
profile ou sinais de "lista quase clonada".

**Recomendacao:** definir explicitamente quando o produto aceita deck
deterministico e adicionar metricas de variation score/role-balance antes de
subir para 50.

### P2 - Scorecard nao cobre todos os blockers de expansao

**Evidencia:** `CommanderReferenceReadinessScorecard` cobre resolucao do
comandante, profile, stats, corpus, deterministic deck, main 99 e public runtime
gate. Ele nao cobre rate-limit/backoff, raw decklist artifact absent, iPhone
runtime, diversity/variation, doc/API contract drift, dedupe de corpus ou risco
de copiar decklists.

**Impacto:** um comandante pode ficar `ready_for_mini_batch` com lacunas
operacionais/compliance ainda abertas.

**Recomendacao:** adicionar gates opcionais ou checklist externo para
`rate_limit_backoff_proven`, `raw_decklist_artifact_absent`,
`mobile_runtime_level`, `variation_score`, `cache_policy_version_covered` e
`api_contract_current`.

### P2 - Classificador de roles ainda e heuristico e parcialmente Lorehold-centric

**Evidencia:** o classifier em `commander_reference_deck_corpus_support.dart`
usa nomes e padroes de oracle/type_line com regras especificas de Lorehold
(`miracle_topdeck`, `big_spell_payoff`, `ritual_treasure`, etc.) e fallback
`other`. O relatorio Roles v2 reconhece o risco e ainda registra `other=13.00`
apos melhoria.

**Impacto:** para 50 comandantes, roles de archetypes nao-Lorehold podem ser
classificados errado e contaminar core/theme/support packages.

**Recomendacao:** criar fixtures por archetype/cor antes de aplicar corpus e
separar taxonomia generica de overrides por comandante/arquetipo.

### P2 - Dedupe de corpus depende de `source_deck_key`

**Evidencia:** `commander_reference_decks` usa `source_deck_key` como primary key
e o upsert conflita apenas nesse campo; `deck_hash` e `source_url` sao
persistidos, mas nao usados como guardrail unico.

**Impacto:** o mesmo deck pode entrar mais de uma vez com outra key, inflando
`deck_count`, top cards e core package.

**Recomendacao:** detectar duplicatas por commander + canonical `source_url` e/ou
`deck_hash` no runner antes de `--apply`.

### P2 - API docs estao parcialmente defasados para corpus guidance

**Evidencia:** `API_CONTRACTS_AND_DATA_MAP.md` ainda cita Commander Deck Corpus
`v3` e cache `reference_deck_corpus_v3:*`, enquanto o codigo usa
`commanderReferenceDeckCorpusPromptPolicyVersion = reference_deck_corpus_v4` e
testes esperam v4.

**Impacto:** consumidores e agentes podem validar contra o contrato errado.

**Recomendacao:** atualizar o doc de contrato junto do proximo patch de backend,
sem mudar response shape.

### P2 - Runtime app ainda nao prova iPhone 15 nem diagnostics completos

**Evidencia:** handoffs recentes provam Android fisico e registram iPhone 15
descoberto, mas nao usado por blocker historico de scanner/MLImage. A estrategia
mobile lista os 5 representantes recomendados e marca iPhone como ausente.

**Impacto:** expansao backend pode passar e ainda falhar em UX/runtime iOS,
polling, preview ou save.

**Recomendacao:** antes de 50, rodar batch representativo no iPhone 15 para
Atraxa, Korvold, Brago, Krenko e Urza, com asserts estruturais e diagnostics
quando possivel.

### P3 - Observabilidade existe, mas alguns erros ainda ficam pouco acionaveis

**Evidencia:** a rota captura excecoes em Sentry via `captureRouteException`, mas
usa `print('[ERROR] Failed to generate deck: $error')` no catch principal e
retorna o body bruto da OpenAI em `apiError` para status nao 200.

**Impacto:** nao ha segredo comprovado exposto, mas mensagens externas/logs podem
ficar ruidosos e pouco categorizados para 429/provider failures.

**Recomendacao:** trocar `print` por logger estruturado, sanitizar provider body
e adicionar tags como `ai_generate_openai_status`, `commander_reference_path` e
`fallback_reason`.

## Blockers antes de 50 comandantes

1. Definir politica para remover/evitar raw decklists em artifacts versionados.
2. Tratar 429/5xx da OpenAI com fallback validado ou erro sanitizado.
3. Versionar cache do archetype path com prompt policy.
4. Atualizar scorecard/checklist com diversity, compliance, rate-limit e iPhone.
5. Criar dedupe de corpus por hash/URL canonical.
6. Parametrizar/provar runtime iPhone 15 representativo.
7. Atualizar `API_CONTRACTS_AND_DATA_MAP.md` de `v3` para `v4` no corpus guidance.

## Menores proximos fixes

| Prioridade | Fix sugerido | Escopo |
| --- | --- | --- |
| P1 | Adicionar fallback/sanitizacao para OpenAI 429 em `/ai/generate` | Pequeno patch backend + teste unitario/route-level |
| P1 | Incluir prompt policy version no cache archetype | Pequeno patch backend + teste de cache key |
| P1 | Bloquear novo artifact com `decks[].cards[]` completo em public proof | Script/check ou convencao de artifact |
| P2 | Atualizar API contracts v3->v4 para corpus guidance | Doc-only |
| P2 | Adicionar duplicate warning por `deck_hash`/`source_url` no runner | Backend/bin + teste |
| P2 | Criar scorecard/checklist de readiness para 50 | Suporte/readiness + teste |
| P2 | Rodar batch iPhone 15 representativo | App integration evidence |

## Decisao recomendada

Manter os promovidos atuais como **PASS_WITH_RISKS** e usar Brago/Lorehold como
baseline de qualidade. Nao expandir para 50 comandantes ate fechar os P1 e
transformar os P2 de scorecard/runtime/compliance em gates explicitos ou
checklist operacional obrigatorio.
