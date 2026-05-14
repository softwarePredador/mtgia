# Commander Reference Sprint 4 Track B Pipeline Audit - 2026-05-14

## Verdict

**PASS_WITH_RISKS / NO-GO para expansao ampla do Sprint 4 sem antes fechar P1.**

O pipeline `POST /ai/generate` + Commander Reference ja tem evidencia forte para
comandantes promovidos, especialmente caminhos exact profile/card_stats/corpus e
fast path deterministico. Porem, para destravar Sprint 4 com seguranca, ainda ha
riscos operacionais/compliance relevantes: fallback/sanitizacao para OpenAI
`429/5xx`, cache key do archetype path sem prompt policy, scorecard/checklist
incompleto para diversidade/compliance/rate-limit/iPhone/dedupe, drift documental
`v3 -> v4`, raw decklists em artifacts, classifier de roles heuristico e dedupe
de corpus fraco por `source_deck_key`.

Nao foi identificado shape change app-facing necessario. Recomenda-se manter
`/ai/generate` compativel e tratar os proximos fixes como backend/doc/test-only.

## Escopo e fontes lidas

- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `server/manual-de-instrucao.md`
- `server/doc/COMMANDER_REFERENCE_SPRINT2_TRACKER_2026-05-13.md`
- `server/doc/COMMANDER_REFERENCE_SPRINT3_TRACKER_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_PIPELINE_GAP_AUDIT_2026-05-14.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_DATA_QUALITY_AUDIT_2026-05-14.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_C_FINAL_2026-05-14.md`
- `server/routes/ai/generate/index.dart`
- `server/lib/ai/commander_reference_deck_corpus_support.dart`
- `server/lib/ai/commander_reference_generate_fallback_support.dart`
- `server/lib/ai/commander_reference_readiness_support.dart`
- `server/lib/ai_generate_performance_support.dart`
- `server/bin/commander_reference_deck_corpus.dart`
- `server/test/commander_reference_deck_corpus_support_test.dart`

## Estado git auditado

- Branch: `master`
- HEAD local: `b60fc6f docs: audit commander reference pipeline gaps`
- Estado: `master...origin/master [ahead 5]`
- Nenhum codigo alterado nesta auditoria.

## Findings priorizados

### P0 - Nenhum P0 runtime imediato comprovado nos comandantes ja promovidos

Nao ha evidencia de quebra atual em legalidade Commander, color identity,
singleton, comandante preservado ou consumo app nos promovidos. Os relatorios
recentes sustentam que os gates bloquearam corretamente Purphoros/Veyran/Balan
e promoveram Brago apenas quando profile/stats/corpus estavam ativos.

**Decisao:** nao expandir Sprint 4 em massa; seguir com fixes P1 antes de novos
lotes grandes.

### P1 - OpenAI `429/5xx` ainda retorna erro bruto e nao usa fallback deterministico validado

Em `server/routes/ai/generate/index.dart`, `TimeoutException` usa fallback
deterministico validado; `401` invalido em dev/staging tambem pode cair em
fallback. Porem status OpenAI nao-200 fora desse caso retorna:

```dart
apiError(response.statusCode, 'OpenAI API Error: ${response.body}')
```

Riscos:

- `429` em lote publico ja ocorreu nos proofs.
- Async job pode falhar mesmo se fallback deterministico conseguiria manter deck
  legal.
- Body de provider pode ser ruidoso/sensivel; deve ser sanitizado.

**Patch proposal, nao aplicado:**

- Criar helper para status transitorios: `429`, `500`, `502`, `503`, `504`.
- Para esses status, tentar `_buildMockGenerateResponse` com `warningCode`
  sanitizado, por exemplo `openai_rate_limited_deterministic_fallback` ou
  `openai_provider_unavailable_deterministic_fallback`.
- Retornar `200` com fallback se `validation.is_valid=true`.
- Se fallback falhar, retornar erro sanitizado sem `response.body` bruto.
- Logar apenas status/categoria, nao payload provider.

### P1 - Cache key do archetype reuse nao inclui prompt policy version

Em `_buildReferenceGenerateCacheVersion`, exact profile inclui
`_aiGenerateReferencePromptPolicyVersion`, profile, stats e corpus. Quando
`referenceProfile == null`, o archetype path retorna apenas versao derivada de
card stats, renomeada para `archetype_reference_v1:*`.

Risco: mudancas em `buildCommanderReferenceArchetypeStatsPrompt` podem
reaproveitar cache antigo se stats nao mudarem.

**Patch proposal, nao aplicado:**

- Incluir `_aiGenerateReferencePromptPolicyVersion` no material de cache do
  archetype path.
- Idealmente versionar como `archetype_reference_v2:<prompt_policy>:<stats_hash>`.
- Cobrir sync e async `_resolveReferenceGenerateCacheVersion`.

### P1 - Raw decklists persistidas em artifacts versionados

Ha multiplos artifacts `server/test/artifacts/**/corpus.json` e `*_corpus.json`
com `decks[].cards[]` completos.

Risco:

- A geracao runtime usa agregados, mas o repositorio acumula decklists brutas.
- Para Sprint 4/50 comandantes, isso amplia risco compliance/copyright/overfit.

**Patch proposal, nao aplicado:**

- Definir politica: versionar somente summaries/agregados sanitizados.
- Raw corpus deve ficar fora de git ou ser regeneravel localmente.
- Adicionar check que bloqueia artifacts novos com `decks[].cards[]` completo em
  paths publicos.
- Manter em docs apenas contadores, hashes, source keys e indicadores de
  integridade.

### P2 - Scorecard/readiness nao cobre diversidade, compliance, rate-limit, iPhone e dedupe

`CommanderReferenceReadinessScorecard` cobre commander card, profile, stats,
corpus, deterministic deck e runtime public gate. Nao cobre ainda:

- `rate_limit_backoff_proven`
- `raw_decklist_artifact_absent`
- `cache_policy_version_covered`
- `corpus_dedupe_clean`
- `diversity/variation score`
- `mobile_runtime_level`, especialmente iPhone 15
- `api_contract_current`

**Patch proposal, nao aplicado:**

- Criar checklist externo obrigatorio ou campos opcionais no scorecard.
- Nao mudar shape app-facing; scorecard e operacional.
- Para Sprint 4, exigir checklist PASS mesmo quando scorecard tecnico der 100.

### P2 - API map esta defasado: corpus guidance documentado como v3, codigo/testes usam v4

`API_CONTRACTS_AND_DATA_MAP.md` ainda cita:

- `Commander Deck Corpus v3`
- `reference_deck_corpus_v3:*`

Codigo atual:

- `commanderReferenceDeckCorpusPromptPolicyVersion = reference_deck_corpus_v4`
- testes esperam `reference_deck_corpus_v4`

**Patch proposal, nao aplicado:**

- Atualizar doc de contrato `v3 -> v4`.
- Sem alterar response shape.
- Explicitar que diagnostics continuam opcionais.

### P2 - Dedupe de corpus depende principalmente de `source_deck_key`

O runner faz upsert por `source_deck_key`. Auditoria de dados encontrou
duplicidade logica em Korvold por `commander_name + source_url` com chaves
diferentes.

Risco: mesmo deck pode inflar `deck_count`, `top_cards`, core/theme/support
packages e readiness.

**Patch proposal, nao aplicado:**

- Antes de `--apply`, detectar duplicatas por `commander_name_normalized +
  canonical source_url` e `commander_name_normalized + deck_hash`.
- Falhar apply ou registrar blocker/warning explicito.
- Adicionar dry-run de duplicatas sem mutar banco.

### P2 - Classifier de roles ainda e heuristico e parcialmente Lorehold-centric

`classifyCommanderReferenceDeckCardRole` contem regras uteis, mas muitas estao
calibradas para Lorehold/topdeck/big spells. Para Sprint 4, novos arquetipos
podem cair em `other` ou em roles errados.

**Patch proposal, nao aplicado:**

- Separar taxonomia generica de overrides por arquetipo/comandante.
- Criar fixtures minimas por familias: tokens, aristocrats, Voltron, blink,
  spellslinger, graveyard, artifacts, enchantress, typal.
- Medir `other_ratio` e bloquear corpus quando `other` ficar alto demais sem
  justificativa.

### P3 - Observabilidade e sanitizacao de erros podem melhorar

Ha `print('[ERROR] ...')` no catch principal e body bruto da OpenAI em erro
nao-200.

**Patch proposal, nao aplicado:**

- Trocar prints por logger estruturado.
- Tags sugeridas: `ai_generate_openai_status`, `commander_reference_path`,
  `fallback_reason`, `provider_error_category`.
- Nunca logar token, prompt completo, response body provider bruto ou decklist
  completa.

## Patch proposals sem aplicar

1. **OpenAI 429/5xx fallback/sanitizacao**: adicionar helper de status
   transitorio em `server/routes/ai/generate/index.dart`, reusar fallback
   deterministico, retornar fallback validado com warning opcional e erro externo
   sanitizado se fallback invalido.
2. **Cache key archetype com prompt policy**: incluir
   `_aiGenerateReferencePromptPolicyVersion` no branch `referenceProfile == null`
   de `server/routes/ai/generate/index.dart` e cobrir com teste de cache version.
3. **Scorecard/checklist Sprint 4**: preferir checklist operacional separado, ou
   campos opcionais em `server/lib/ai/commander_reference_readiness_support.dart`,
   para diversity, compliance, rate-limit, iPhone, dedupe e API doc current.
4. **Dedupe de corpus**: adicionar analise read-only de duplicate source URL/hash
   antes do apply em `server/bin/commander_reference_deck_corpus.dart` e suporte.
5. **Artifact compliance**: bloquear novos `corpus.json` com `decks[].cards[]`
   completos em git; preferir summaries sanitizados.
6. **API map v3 -> v4**: doc-only, sem shape change.

## Testes necessarios antes de promover Sprint 4

Minimo backend:

```bash
cd server
dart analyze lib routes test
dart test test/commander_reference_deck_corpus_support_test.dart \
  test/commander_reference_profile_support_test.dart \
  test/commander_reference_card_stats_support_test.dart \
  test/commander_reference_readiness_support_test.dart \
  test/ai_generate_performance_support_test.dart -r expanded
```

Novos testes recomendados:

- OpenAI `429` retorna fallback validado ou erro sanitizado.
- OpenAI `500/503/504` idem.
- Provider body bruto nao aparece em response.
- Archetype cache version muda quando prompt policy muda.
- Corpus runner detecta duplicate `source_url`/`deck_hash`.
- Checklist bloqueia raw decklist artifact.
- Scorecard/checklist falha quando falta iPhone proof/rate-limit
  proof/compliance.

Provas live antes de expansao:

- 5 probes com `commander_name` para baseline promovido forte.
- 5 probes baseline sem `commander_name`.
- Batch pequeno com backoff explicito para evitar `429`.
- iPhone 15 Simulator ou classificacao `not_proven` se ainda bloqueado.

## Contratos app-facing impactados

**Esperado: nenhum shape change.**

`POST /ai/generate` deve continuar preservando:

- sync `200/422`: `generated_deck`, `validation`, `cards`, `commander`, `stats`,
  `warnings`, `errors`, `is_mock`, `diagnostics?`, `cache?`, `timings?`
- async `202`: `job_id`, `status`, `message`, `poll_url`,
  `poll_interval_ms`, `total_stages`, `cache`, `timings`
- diagnostics Commander Reference opcionais
- app usando `generated_deck` + `validation` como fonte de verdade

Possivel mudanca comportamental sem shape change:

- `429/5xx` da OpenAI pode virar `200` com fallback validado e warning
  sanitizado, em vez de erro bruto.
- Isso e compativel se `validation.is_valid=true` e warnings forem opcionais.

## Criterio de promocao Sprint 4

Sprint 4 so deve avancar para expansao controlada quando:

1. OpenAI `429/5xx` tiver fallback validado ou erro sanitizado comprovado.
2. Archetype cache version incluir prompt policy.
3. API map estiver alinhado com `reference_deck_corpus_v4`.
4. Nenhum novo artifact versionado carregar raw decklists completas.
5. Dedupe por `source_url`/`deck_hash` estiver no runner ou em checklist blocking.
6. Scorecard/checklist cobrir diversity, compliance, rate-limit, iPhone e dedupe.
7. Public proof 5/5 por comandante mantiver HTTP 200, validacao, comandante
   preservado, `main_quantity=99`, profile/stats/corpus usados quando promovido
   como Commander Reference, invalid/off-identity 0 e fallback/timeout dentro do
   orcamento documentado.
8. iPhone 15 proof executado para batch representativo ou marcado explicitamente
   `not_proven` com risco aceito.

## Riscos

| Risco | Impacto | Mitigacao |
| --- | --- | --- |
| Expandir sem tratar `429/5xx` | Falhas em lote/async jobs | Fallback validado + backoff + sanitizacao |
| Raw decklists em git | Compliance/copyright/overfit | Versionar apenas agregados/hashes/summaries |
| Cache stale no archetype path | Prompt antigo reaproveitado | Incluir prompt policy na cache key |
| Scorecard 100 com lacunas operacionais | Promocao falsa | Checklist Sprint 4 blocking |
| Dedupe fraco | Core package inflado | Guardrail por URL/hash |
| Classifier errado fora de Lorehold | Guidance off-theme | Fixtures por arquetipo e `other_ratio` gate |
| iPhone nao provado | Regressao mobile nao detectada | Prova iPhone 15 ou `not_proven` explicito |
| API map defasado | Agentes/consumidores validam versao errada | Atualizar doc v3 -> v4 sem shape change |

## Proxima acao tecnica recomendada

Aplicar primeiro o menor patch backend/test para OpenAI `429/5xx`
fallback/sanitizacao e cache archetype prompt policy. Em seguida, atualizar API
map v4 e introduzir checklist Sprint 4 como gate operacional antes de qualquer
novo lote grande.
