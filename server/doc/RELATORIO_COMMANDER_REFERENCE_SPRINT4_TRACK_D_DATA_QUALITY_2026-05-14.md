# Commander Reference Sprint 4 Track D Data Quality - 2026-05-14

## Verdict

**PASS_WITH_RISKS** para Track D data quality.

Os 4 comandantes preselecionados resolvem em `cards` com identidade de cor
coerente e os artifacts locais de corpus Sprint 4 passam dry-run sem
unresolved/off-color/singleton. Porem, nenhum corpus esta aplicado no DB
(`commander_reference_decks=0` e `commander_reference_deck_analysis=0` para os
4). `Feather` e `Miirym` ja tem profile Commander Reference + card_stats
resolvidos; `Ghave` nao tem profile/card_stats; `Jodah` tem apenas profile
legado `edhrec`, nao shape Commander Reference utilizavel.

## Tabela por candidato

| Candidato | Card em `cards` / CI | Profile DB | Card stats DB | Corpus artifact | Corpus DB / analysis | Duplicidade | Readiness antes de runtime |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Feather, the Redeemed` | Resolvido; CI DB `WR`, esperado `RW` | 1 profile `aggregate_reference_profile_v1`, confidence `high`, 5 packages | 31/31 resolvidos, unresolved 0, off-color 0, 5 packages | dry-run PASS, 4/4 decks aceitos, unresolved 0, off-color 0 | 0 decks / 0 analysis | source_url/source_key/hash dup 0 | Quase pronto no dado-base; falta aplicar corpus e gerar/provar readiness/public proof |
| `Ghave, Guru of Spores` | Resolvido; CI DB `WBG`, esperado `BGW` | 0 | 0 | dry-run PASS, 5/5 decks aceitos, unresolved 0, off-color 0 | 0 decks / 0 analysis | dup 0 | Bloqueado por falta de profile + card_stats + apply corpus |
| `Jodah, the Unifier` | Resolvido; CI DB `WUBRG`, esperado `BGRUW` | 1 profile legado `edhrec`, sem `confidence`/`expected_packages` utilizaveis | 0 | dry-run PASS, 5/5 decks aceitos, unresolved 0, off-color 0 | 0 decks / 0 analysis | dup 0 | Bloqueado; substituir/adicionar profile Commander Reference real + card_stats antes de apply |
| `Miirym, Sentinel Wyrm` | Resolvido; CI DB `URG`, esperado `GRU` | 1 profile `aggregate_reference_profile_v1`, confidence `high`, 5 packages | 33/33 resolvidos, unresolved 0, off-color 0, 5 packages | dry-run PASS, 5/5 decks aceitos, unresolved 0, off-color 0 | 0 decks / 0 analysis | dup 0 | Quase pronto no dado-base; falta aplicar corpus e gerar/provar readiness/public proof |

## Bloqueios de dados

1. **Nenhum dos 4 tem corpus aplicado no DB**:
   - `commander_reference_decks`: 0 para todos.
   - `commander_reference_deck_analysis`: 0 para todos.
2. **Ghave**: falta profile Commander Reference e card_stats.
3. **Jodah**: profile existente e legado `source=edhrec`; nao deve ser tratado
   como guidance forte.
4. **Runtime/public proof ainda nao aplicavel** ate corpus ser aplicado com
   idempotencia, scorecard read-only sair de blockers e public proof 5/5
   confirmar `profile/stats/corpus_used`.

## Risco de cards recentes ausentes

Nos artifacts atuais de dry-run Sprint 4, todos os 4 candidatos tem:

- unresolved 0;
- off-color 0;
- singleton limpo;
- comandante resolvido.

Portanto, **nao ha risco atual provado de cards recentes ausentes no corpus
aceito**. O risco permanece apenas operacional para futuros refreshes de fontes,
especialmente Jodah e Miirym por dependerem de pools recentes/variaveis.

## Readiness esperado antes de runtime

Ordem recomendada:

1. **Feather, the Redeemed**
   - Ja tem profile + stats resolvidos.
   - Corpus dry-run PASS.
   - Proximo passo: apply corpus + idempotencia + scorecard.
2. **Miirym, Sentinel Wyrm**
   - Ja tem profile + stats resolvidos.
   - Corpus dry-run PASS.
   - Proximo passo igual Feather.
3. **Ghave, Guru of Spores**
   - Corpus dry-run PASS, mas falta profile/stats.
   - Proximo passo: criar/aplicar profile + card_stats; depois apply corpus.
4. **Jodah, the Unifier**
   - Corpus dry-run PASS, mas profile legado nao utilizavel e stats ausentes.
   - Proximo passo: novo profile Commander Reference + card_stats; revisar risco
     de cinco cores antes de runtime.

## Comandos read-only executados

- Leitura de docs:
  - `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
  - `server/manual-de-instrucao.md`
  - `server/doc/COMMANDER_REFERENCE_SPRINT3_TRACKER_2026-05-13.md`
  - `server/doc/RELATORIO_COMMANDER_REFERENCE_DATA_QUALITY_AUDIT_2026-05-14.md`
  - `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_C_FINAL_2026-05-14.md`
- SELECTs via `psql` usando URL local sem imprimir valor:
  - schema das tabelas Commander Reference;
  - resolucao dos comandantes em `cards`;
  - profiles/card_stats;
  - corpus/deck_analysis DB;
  - duplicidade por `source_url`, `source_deck_key`, `deck_hash`.
- Leitura de artifacts locais:
  - `server/test/artifacts/commander_reference_sprint4_candidates_2026-05-14/**/source_summary_sanitized.json`
  - `server/test/artifacts/commander_reference_sprint4_candidates_2026-05-14/**/dry_run/*_dry_run_summary.json`
- `git status --short --branch`

## DB changes

Nenhuma. Apenas SELECTs.

## Code/doc changes

Nenhum codigo foi alterado.

## Recomendacao de backfill

1. Aplicar primeiro corpus de `Feather` e `Miirym` com dry-run pre-apply, apply,
   idempotencia e scorecard.
2. Para `Ghave`, criar profile/card_stats resolvidos antes de apply corpus.
3. Para `Jodah`, substituir o profile legado por shape Commander Reference
   aditivo e so entao aplicar stats/corpus.
4. So executar runtime/public proof apos scorecard local sem blockers.
