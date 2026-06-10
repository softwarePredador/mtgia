# F3 — Plano de Quebra de Gargalhos

> Data: 2026-05-29
> Status: Em andamento

## Situação atual

| Arquivo | Linhas | Problema |
|---------|--------|----------|
| `server/lib/ai/optimize_runtime_support.dart` | 4028 | Gargalo principal — 121 funções/classes |
| `server/routes/ai/optimize/index.dart` | 3589 | Rota gigante — orquestração + helpers + response builders |
| `server/lib/ai/optimize_complete_support.dart` | 1562 | Grande mas mais focado |
| `server/lib/ai/optimization_quality_gate.dart` | 577 | OK |
| `server/lib/ai/candidate_quality_data_support.dart` | 634 | OK |
| **Total** | **~6800** | Muito concentrado em poucos arquivos |

## Quebra planejada

### 1. `optimize_filler_loader_support.dart` (NOVO — ~1300 linhas)
Extrair de `optimize_runtime_support.dart`:
- `loadBasicLandIds`
- `loadIdentitySafeNonBasicLandFillers`
- `loadDeterministicSlotFillers`
- `loadMetaInsightFillers`
- `loadBroadCommanderNonLandFillers`
- `loadGuaranteedNonBasicFillers`
- `loadCompetitiveNonLandFillers`
- `loadEmergencyNonBasicFillers`
- `loadIdentitySafeNonLandFillers`
- `loadPreferredNameFillers`
- `findSynergyReplacements`
- `_filterCandidatesByBracketPolicy`
- Funções auxiliares: `landProducesCommanderColors`, `landFixesCommanderColors`, `resolvedCardIdentity`, `resolvedCardIdentityFromParts`, `recommendedLandCountForOptimizeArchetype`
- Structural recovery: `isOptimizeStructuralRecoveryScenario`, `computeOptimizeStructuralRecoverySwapTarget`, `buildStructuralRecoveryFunctionalNeeds`, `buildRoleTargetProfile`, `buildSlotNeedsForDeck`

### 2. `optimize_response_support.dart` (NOVO — ~200 linhas) ✅ CRIADO
Extrair de `routes/ai/optimize/index.dart`:
- `buildSemanticV2OptimizeRejectedBody`
- `buildOptimizeBracketPolicyDiagnostics`
- `attachOptimizeBracketPolicyDiagnostics`
- `buildOptimizeResponse`
- `respondWithOptimizeTelemetry`

### 3. `optimize_runtime_support.dart` (REDUZIDO — ~2400 linhas)
Manter:
- Funções de orquestração de alto nível
- `normalizeOptimizeReasoning`, `normalizeOptimizePayload`, `resolveOptimizeMode`
- `OptimizeIntensityConfig`, `shouldUseAsyncOptimizeExecutor`
- `parseOptimizeSuggestions`, `isBasicLandName`, `isBasicLandTypeLine`, `maxCopiesForFormat`
- `basicLandNamesForIdentity`, `basicLandNameForColor`
- `inferFunctionalRole`, `inferOptimizeFunctionalNeed`, `matchesFunctionalNeed`
- `scoreOptimizeReplacementCandidate`
- `AggressiveCandidateQualitySignal`
- Funções de cache/preferências: `loadOptimizeCache`, `saveOptimizeCache`, `loadUserAiPreferences`, etc.
- `dedupeCandidatesByName`, `shouldKeepCommanderFillerCandidate`, `commanderFillerQualityScore`
- `extractTopCardNamesFromProfile`, `extractAverageDeckSeedNamesFromProfile`
- `safeToDouble`

### 4. `routes/ai/optimize/index.dart` (REDUZIDO — ~2000 linhas)
Manter:
- `onRequest` handler (orquestração principal)
- `assessDeckOptimizationState`
- `deriveOptimizeOutcomeCode`
- Imports dos submódulos

## Validação

Após cada extração:
1. `dart analyze` — 0 erros
2. `dart test test/optimization_validator_test.dart` — todos passando
3. `dart test` completo — 610+ testes passando

## Progresso

- [x] F3b: `optimize_response_support.dart` criado
- [ ] F3a: `optimize_filler_loader_support.dart` criado
- [ ] F3c: `optimize_runtime_support.dart` reduzido
- [ ] F3d: `optimize/index.dart` reduzido
- [ ] F3e: Validação completa
