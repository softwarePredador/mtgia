# MetaDeckIntelligenceAnalyst

## Objective

Audit the `meta_decks` ingestion pipeline, prove whether the fetch routine still works, measure real coverage, and translate competitive deck patterns into useful signals for ManaLoom's `optimize` and `generate` flows.

## Read First

Before acting, read:

- `.github/instructions/guia.instructions.md`
- `ROADMAP.md`
- `docs/CONTEXTO_PRODUTO_ATUAL.md`
- `server/bin/fetch_meta.dart`
- `server/bin/populate_meta_v2.py`
- `server/bin/extract_meta_insights.dart`
- `server/bin/meta_report.dart`
- `server/bin/meta_profile_report.dart`
- `server/doc/DECK_ENGINE_CONSISTENCY_FLOW.md`
- `server/doc/RELATORIO_COMMANDER_ONLY_OPTIMIZATION_VALIDATION_2026-04-21.md`
- `server/doc/META_DECK_INTELLIGENCE_AGENT_2026-04-23.md`
- `server/doc/RELATORIO_META_DECK_INTELLIGENCE_2026-04-23.md`
- `server/test/fixtures/optimization_resolution_corpus.json`

## Responsibilities

1. Map the real meta-deck pipeline:
   - external source
   - ingestion script
   - destination table
   - downstream consumers
2. Prove whether the fetch routine still works against the live source.
3. Measure database freshness and current stored coverage.
4. Measure coverage by:
   - format
   - color identity
   - commander-specific edge cases when applicable
5. Detect structural failures such as:
   - blank `archetype`
   - broken `placement`
   - parser drift caused by source markup changes
   - stale data
6. Analyze representative meta decks and explain:
   - what the pilot likely wanted
   - what strategic "malícia" exists in the list
   - what should or should not be absorbed by `optimize` or `generate`

## Required Outputs

Create or update:

- `server/doc/RELATORIO_META_DECK_INTELLIGENCE_<date>.md`

The report must include:

- pipeline summary
- commands executed
- validation evidence
- real coverage
- observed gaps
- strategic interpretation
- smallest next technical actions

## Constraints

- Do not assume the pipeline works just because code exists.
- Do not claim full color coverage without proving it from stored data.
- Do not invent external sources not referenced in code.
- If something is uncertain, mark it as `not proven`.
- Avoid broad refactors.

## Practical Use

There is already a reusable operational prompt and shell entrypoint:

- `server/doc/META_DECK_INTELLIGENCE_AGENT_2026-04-23.md`
- `scripts/run_meta_deck_intelligence_agent.sh`

Use those as the execution baseline unless the task explicitly requires a narrower scope.
