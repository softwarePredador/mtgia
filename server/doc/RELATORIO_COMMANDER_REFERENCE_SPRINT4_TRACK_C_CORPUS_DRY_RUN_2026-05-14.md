# Commander Reference Sprint 4 Track C — Corpus Dry-Run - 2026-05-14

## Verdict

**PASS_WITH_RISKS / NO-APPLY nesta rodada.**

Foram preparados artifacts offline separados para os quatro candidatos indicados
pelo orquestrador e executado `dry-run` DB-backed do runner
`commander_reference_deck_corpus.dart` sem `--apply`. O resultado final ficou
estruturalmente limpo para todos os candidatos: comandante resolvido, comandante
fora das 99, `main_quantity=99`, `unresolved=0`, `off_color=0`, singleton limpo
e `db_mutations=false`.

O risco residual e de produto/pipeline: esta etapa prova apenas corpus local
validavel, nao profile/card_stats/public proof/readiness. Portanto a recomendacao
e **nao aplicar automaticamente** nesta rodada; aplicar depois somente com
aprovacao explicita do orquestrador e sequencia de profile/card_stats/readiness.

## Escopo e seguranca

- Branch alvo: `master`.
- HEAD local inspecionado: `b60fc6f45a0d2bcf85c6a9d7b86cb84aa0892cbc`.
- Scanner, camera e OCR fora do escopo.
- Nao houve `--apply`.
- `db_mutations=false` em todos os summaries finais.
- Nao houve commit.
- `server/manual-de-instrucao.md`, tracker Sprint 3 e
  `server/doc/API_CONTRACTS_AND_DATA_MAP.md` nao foram alterados.
- Este relatorio nao copia decklists completas, tokens, JWT, Sentry DSN,
  `DATABASE_URL`, `OPENAI_API_KEY`, e-mail QA completo ou payload sensivel.

## Fontes lidas / inspecionadas antes dos comandos

- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `server/manual-de-instrucao.md`
- `server/doc/COMMANDER_REFERENCE_SPRINT3_TRACKER_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_C_FINAL_2026-05-14.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_DATA_QUALITY_AUDIT_2026-05-14.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_PIPELINE_GAP_AUDIT_2026-05-14.md`
- `server/bin/commander_reference_deck_corpus.dart`
- `server/lib/ai/commander_reference_deck_corpus_support.dart`
- `server/lib/ai/commander_reference_profile_support.dart`
- `server/lib/ai/commander_reference_card_stats_support.dart`
- `server/lib/ai/commander_reference_readiness_support.dart`

## Comandos executados

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git --no-pager status --short --branch
find server/test/artifacts -path '*corpus.json' | head -40
python3 ... # inspecao local de formatos de corpus existentes
python3 ... # probe baixo volume de endpoints EDHREC average-decks por candidato
python3 ... # criacao dos corpus.json e source_summary_sanitized.json por comandante

cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_sprint4_candidates_2026-05-14/feather_the_redeemed/corpus.json \
  --dry-run \
  --artifact-dir=test/artifacts/commander_reference_sprint4_candidates_2026-05-14/feather_the_redeemed/dry_run
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_sprint4_candidates_2026-05-14/ghave_guru_of_spores/corpus.json \
  --dry-run \
  --artifact-dir=test/artifacts/commander_reference_sprint4_candidates_2026-05-14/ghave_guru_of_spores/dry_run
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_sprint4_candidates_2026-05-14/jodah_the_unifier/corpus.json \
  --dry-run \
  --artifact-dir=test/artifacts/commander_reference_sprint4_candidates_2026-05-14/jodah_the_unifier/dry_run
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_sprint4_candidates_2026-05-14/miirym_sentinel_wyrm/corpus.json \
  --dry-run \
  --artifact-dir=test/artifacts/commander_reference_sprint4_candidates_2026-05-14/miirym_sentinel_wyrm/dry_run

python3 ... # refinamento de Feather/Ghave apos dry-run inicial com unresolved local
dart run bin/commander_reference_deck_corpus.dart ... feather_the_redeemed ... --dry-run
dart run bin/commander_reference_deck_corpus.dart ... ghave_guru_of_spores ... --dry-run
python3 ... # coleta de metricas finais dos summaries
git --no-pager rev-parse HEAD
git --no-pager status --short --branch
```

Observacao: a URL/credenciais de banco foram usadas apenas pelo runner local via
configuracao existente e nao foram impressas neste relatorio.

## Artifacts criados

Base:
`server/test/artifacts/commander_reference_sprint4_candidates_2026-05-14/`

| Commander | Artifacts |
| --- | --- |
| `Feather, the Redeemed` | `feather_the_redeemed/source_summary_sanitized.json`, `feather_the_redeemed/dry_run/feather_the_redeemed_dry_run_summary.json` |
| `Ghave, Guru of Spores` | `ghave_guru_of_spores/source_summary_sanitized.json`, `ghave_guru_of_spores/dry_run/ghave_guru_of_spores_dry_run_summary.json` |
| `Jodah, the Unifier` | `jodah_the_unifier/source_summary_sanitized.json`, `jodah_the_unifier/dry_run/jodah_the_unifier_dry_run_summary.json` |
| `Miirym, Sentinel Wyrm` | `miirym_sentinel_wyrm/source_summary_sanitized.json`, `miirym_sentinel_wyrm/dry_run/miirym_sentinel_wyrm_dry_run_summary.json` |

Os `corpus.json` brutos foram gerados localmente apenas para alimentar o runner
de dry-run e foram excluidos do conjunto versionavel porque contem listas
completas. A evidencia persistida para commit fica limitada aos summaries
sanitizados e aos summaries de dry-run.

## Matriz final por comandante

| Commander | Dry-run | Decks aceitos | Commander/main | unresolved | off_color | singleton | db_mutations |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `Feather, the Redeemed` | PASS | 4/4 | `1/99` em 4/4 | 0 | 0 | `{}` em 4/4 | false |
| `Ghave, Guru of Spores` | PASS | 5/5 | `1/99` em 5/5 | 0 | 0 | `{}` em 5/5 | false |
| `Jodah, the Unifier` | PASS | 5/5 | `1/99` em 5/5 | 0 | 0 | `{}` em 5/5 | false |
| `Miirym, Sentinel Wyrm` | PASS | 5/5 | `1/99` em 5/5 | 0 | 0 | `{}` em 5/5 | false |

## Refinamentos e bloqueios encontrados

- `Feather, the Redeemed`: o primeiro corpus com fontes default/heroic/
  spellslinger/cantrips/budget ficou `PASS_WITH_RISKS` porque cartas recentes
  ainda nao resolviam localmente. O corpus final removeu essas fontes bloqueadas
  e manteve apenas fontes que passaram no DB-backed dry-run.
- `Ghave, Guru of Spores`: o primeiro corpus rejeitou fontes com carta localmente
  nao resolvida. O corpus final substituiu essas fontes por variantes aceitas.
- `Jodah, the Unifier`: dry-run final PASS, mas a auditoria anterior marcou o
  profile local como legado/nao utilizavel para Commander Reference forte; isso
  nao bloqueia corpus dry-run, mas bloqueia promocao sem profile/card_stats novos.
- `Miirym, Sentinel Wyrm`: dry-run final PASS; profile/card_stats/readiness/public
  proof ainda nao foram provados nesta etapa.

## Recomendacao de apply/no-apply

**NO-APPLY agora.**

Os quatro corpora finais estao estruturalmente aptos para uma proxima etapa de
apply controlado, mas Track C solicitou apenas preparacao offline e dry-run sem
mutacao. Antes de aplicar/promover qualquer candidato:

1. obter aprovacao explicita do orquestrador para `--apply`;
2. confirmar politica de artifact/raw corpus para evitar crescimento de decklists
   brutas versionadas;
3. preparar/aplicar profile e card_stats quando ausentes ou legados;
4. executar readiness sem runtime summary;
5. so depois executar public proof 5/5 e scorecard com runtime summary.
