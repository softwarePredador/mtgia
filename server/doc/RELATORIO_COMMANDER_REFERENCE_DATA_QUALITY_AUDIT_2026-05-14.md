# Commander Reference Data Quality Audit - 2026-05-14

## Resultado

**PASS_WITH_RISKS.**

Os 20 comandantes promovidos estao coerentes com os scorecards publicos e com os
dados DB-backed necessarios para Commander Reference: corpus aceito, card stats
resolvidos, sem unresolved, sem off-color/off-identity, sem violacao singleton e
com deck deterministico de 99 cartas no main quando o scorecard e executado em
modo read-only.

O risco encontrado e restrito a qualidade de inventario/agregacao: `Korvold,
Fae-Cursed King` tem tres `source_url` repetidas entre o corpus Sprint 2 e o retry
Sprint 3 Lote B, com `source_deck_key` diferentes. Isso nao enfraquece legalidade
nem identidade de cor, mas faz a contagem bruta de decks de Korvold ser 8 enquanto
`commander_reference_deck_analysis` expoe 4 decks aceitos da rodada mais recente.
Nao foi feita nenhuma mutacao de banco.

## Escopo auditado

### Promovidos

| Grupo | Commanders |
| --- | --- |
| Mini-batch inicial | `Lorehold, the Historian`, `Prosper, Tome-Bound`, `Aesi, Tyrant of Gyre Strait`, `Edgar Markov`, `Dina, Essence Brewer`, `Zimone, Infinite Analyst` |
| Sprint 2 | `Kinnan, Bonder Prodigy`, `Muldrotha, the Gravetide`, `Yuriko, the Tiger's Shadow`, `Winota, Joiner of Forces`, `Atraxa, Praetors' Voice` |
| Sprint 3 A+B | `Krenko, Mob Boss`, `Light-Paws, Emperor's Voice`, `Niv-Mizzet, Parun`, `Teysa Karlov`, `Meren of Clan Nel Toth`, `Korvold, Fae-Cursed King`, `Sythis, Harvest's Hand`, `Urza, Lord High Artificer` |
| Sprint 3 C | `Brago, King Eternal` |

Total promovido auditado: **20**.

### Candidatos futuros / bloqueados conferidos

`Purphoros, God of the Forge`, `Veyran, Voice of Duality`, `Balan, Wandering
Knight`, `Jodah, the Unifier`, `Ghave, Guru of Spores` e `Feather, the Redeemed`.

## Fontes lidas

- `server/bin/commander_reference_deck_corpus.dart`
- `server/bin/commander_reference_readiness_scorecard.dart`
- `server/bin/commander_reference_profile.dart`
- `server/lib/ai/commander_reference_deck_corpus_support.dart`
- `server/lib/ai/commander_reference_readiness_support.dart`
- `server/lib/ai/commander_reference_card_stats_support.dart`
- `server/lib/ai/commander_reference_profile_support.dart`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_MINI_BATCH_COVERAGE_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT2_FINAL_2026-05-13.md`
- `server/doc/COMMANDER_REFERENCE_SPRINT3_TRACKER_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_AB_CONSOLIDATION_2026-05-14.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_C_FINAL_2026-05-14.md`
- Artifacts `readiness_public`, `public_proof`, `corpus.json`, `apply` e `dry_run`
  dos lotes auditados.

## Comandos executados

Todos os comandos abaixo foram read-only ou leitura de artifacts locais. A URL do
banco foi lida da variavel local sem ser impressa.

```bash
cd server
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -P pager=off -At -F '|' <<'SQL'
-- SELECTs em commander_reference_profiles/card_stats/decks/deck_cards/deck_analysis.
SQL

dart run bin/commander_reference_readiness_scorecard.dart \
  --commanders="Lorehold, the Historian;Prosper, Tome-Bound;Aesi, Tyrant of Gyre Strait;Edgar Markov;Dina, Essence Brewer;Zimone, Infinite Analyst;Kinnan, Bonder Prodigy;Muldrotha, the Gravetide;Yuriko, the Tiger's Shadow;Winota, Joiner of Forces;Atraxa, Praetors' Voice;Krenko, Mob Boss;Light-Paws, Emperor's Voice;Niv-Mizzet, Parun;Teysa Karlov;Meren of Clan Nel Toth;Korvold, Fae-Cursed King;Sythis, Harvest's Hand;Urza, Lord High Artificer;Brago, King Eternal;Purphoros, God of the Forge;Veyran, Voice of Duality;Balan, Wandering Knight" \
  --artifact-dir="/Users/desenvolvimentomobile/.copilot/session-state/a175cd57-0e4f-4edb-b43a-1174ef3774d8/files/commander_reference_audit_scorecard_2026-05-14"

python3 - <<'PY'
# leitura local de readiness/public_proof/corpus artifacts para comparar scorecards,
# duplicidade de source_url e blockers documentados
PY
```

## Contagens DB-backed

| Tabela | Linhas |
| --- | ---: |
| `commander_reference_profiles` | 47 |
| `commander_reference_card_stats` | 1.523 |
| `commander_reference_decks` | 102 |
| `commander_reference_deck_cards` | 8.461 |
| `commander_reference_deck_analysis` | 23 |

### Agregado dos 20 promovidos

| Sinal | Resultado |
| --- | ---: |
| Promovidos presentes no banco | 20/20 |
| Promovidos com corpus | 20/20 |
| Decks em `commander_reference_decks` | 89 |
| Decks aceitos | 89 |
| `unresolved_count` em decks | 0 |
| `off_color_count` em decks | 0 |
| `commander_quantity <> 1` | 0 |
| `main_quantity <> 99` | 0 |
| Singleton violations | 0 |
| Card stats dos promovidos | 684 |
| Card stats unresolved | 0 |
| Linhas em `commander_reference_deck_analysis` | 20 |
| Soma `accepted_deck_count` em analysis | 85 |

A diferenca `89` decks aceitos vs `85` em `deck_analysis` vem de Korvold: o banco
mantem 8 decks historicos aceitos, mas a linha de analysis atual sumariza 4 decks
da rodada Sprint 3 Lote B.

## Validacoes de integridade

| Checagem | Resultado |
| --- | --- |
| `LOWER/source_deck_key` duplicado em `commander_reference_decks` | 0 duplicatas exatas |
| `source_url` duplicado por comandante | 3 duplicatas logicas, todas Korvold |
| `commander_reference_deck_cards.unresolved OR off_color` | 0 |
| Card stats fora da identidade do profile | 0 |
| Card stats `unresolved=false` sem `card_id` ou `unresolved=true` com `card_id` | 0 |
| Card stats mais antigos que o profile correspondente | 0 |
| `commander_reference_deck_analysis` mais antigo que decks do mesmo comandante | 0 |
| Artifacts de corpus com `source_url` repetida | 3 duplicatas logicas, todas Korvold Sprint2 vs Sprint3 B |

## Duplicidade Korvold

Duplicatas logicas por `commander_name + source_url`:

| URL | Chaves |
| --- | --- |
| `https://edhrec.com/average-decks/korvold-fae-cursed-king` | `edhrec_korvold_default_average`, `edhrec_korvold_fae_cursed_king_default_average_sprint3_lot_b_2026_05_14` |
| `https://edhrec.com/average-decks/korvold-fae-cursed-king/sacrifice` | `edhrec_korvold_sacrifice_average`, `edhrec_korvold_fae_cursed_king_sacrifice_average_sprint3_lot_b_2026_05_14` |
| `https://edhrec.com/average-decks/korvold-fae-cursed-king/treasure` | `edhrec_korvold_treasure_average`, `edhrec_korvold_fae_cursed_king_treasure_average_sprint3_lot_b_2026_05_14` |

Dry-run de candidatos a cleanup, mantendo a versao mais recente por URL:

| `source_deck_key` candidato | `deck_card_rows` |
| --- | ---: |
| `edhrec_korvold_default_average` | 91 |
| `edhrec_korvold_sacrifice_average` | 94 |
| `edhrec_korvold_treasure_average` | 88 |

Total potencial se um cleanup for aprovado depois: 3 decks e 273 linhas em
`commander_reference_deck_cards`. **Nao aplicar automaticamente**: o dry-run deve
ser revisado porque a duplicidade tambem serve como historico da promocao
Sprint2 -> retry Sprint3 B.

Comando dry-run recomendado:

```sql
WITH ranked AS (
  SELECT
    d.*,
    row_number() OVER (
      PARTITION BY commander_name, source_url
      ORDER BY updated_at DESC, source_deck_key DESC
    ) AS keep_rank
  FROM commander_reference_decks d
  WHERE source_url IS NOT NULL
    AND source_url <> ''
),
candidates AS (
  SELECT
    r.commander_name,
    r.source_url,
    r.source_deck_key,
    r.updated_at,
    count(c.*) AS deck_card_rows
  FROM ranked r
  LEFT JOIN commander_reference_deck_cards c USING (source_deck_key)
  WHERE keep_rank > 1
  GROUP BY r.commander_name, r.source_url, r.source_deck_key, r.updated_at
)
SELECT *
FROM candidates
ORDER BY commander_name, source_url;
```

## `commander_reference_deck_analysis`

O unico mismatch contra a contagem bruta de decks e Korvold:

| Commander | `analysis_deck_count` | `actual_deck_count` | `analysis_accepted` | `actual_accepted` |
| --- | ---: | ---: | ---: | ---: |
| `Korvold, Fae-Cursed King` | 4 | 8 | 4 | 8 |

Isso e explicado pelo upsert atual: `commander_reference_deck_analysis` usa a chave
`(commander_name_normalized, source)`, mas o `source` de analysis e fixo como
`commander_reference_deck_corpus_v1`; uma reaplicacao posterior para o mesmo
comandante sobrescreve a summary anterior. O runtime usa a linha mais recente e
Korvold passou no scorecard Sprint 3 B com score 100, mas a tabela nao deve ser
lida como inventario historico cumulativo.

## Scorecards e artifacts

Scorecards publicos lidos:

- Os 6 promovidos do mini-batch inicial terminaram com `score=100`,
  `ready_for_mini_batch`, `expansion_ready=true` e blockers/warnings vazios.
- Os 5 promovidos do Sprint 2 terminaram com `score=100`,
  `ready_for_mini_batch`; o artifact antigo de Korvold Sprint 2 ficou
  `PASS_WITH_RISKS`, mas foi supersedido pelo retry Sprint 3 B.
- Os 8 promovidos Sprint 3 A+B terminaram com `score=100`,
  `ready_for_mini_batch`.
- Brago terminou com `score=100`, `ready_for_mini_batch`.
- Purphoros, Veyran e Balan ficaram corretamente `blocked`, com
  `profile_used=0`, `stats_used=0`, `corpus_used=0` na public proof, apesar de
  `http_200=5`, `validation_ok=5`, comandante preservado 5/5, main 99 5/5,
  invalid 0 e off-identity 0.

Scorecard DB-backed sem `--runtime-summary` executado nesta auditoria:

- 20 promovidos retornaram `score=98`, `profile_ready_needs_proof`, apenas por
  `public_runtime_proof_missing`; isso e esperado porque a execucao foi read-only
  local sem anexar os summaries publicos por comandante.
- Purphoros, Veyran e Balan retornaram `score=25`, `blocked`, com blockers de
  profile/card_stats/deterministic deck ausentes.

## Candidatos futuros

| Commander | Profile | Reference confidence | Corpus | Card stats | Estado |
| --- | ---: | --- | ---: | ---: | --- |
| `Purphoros, God of the Forge` | 0 | false | 5/5 aceitos | 0 | Bloqueado corretamente; tem corpus limpo, falta profile/card_stats/deterministic |
| `Veyran, Voice of Duality` | 0 | false | 4/4 aceitos | 0 | Bloqueado corretamente; tem corpus limpo, falta profile/card_stats/deterministic |
| `Balan, Wandering Knight` | 0 | false | 4/4 aceitos | 0 | Bloqueado corretamente; tem corpus limpo, falta profile/card_stats/deterministic |
| `Feather, the Redeemed` | 1 | true | 0 | 31 | Tem profile/card_stats, falta corpus/public proof |
| `Jodah, the Unifier` | 1 | false | 0 | 0 | Existe apenas profile legado `edhrec`, sem shape Commander Reference utilizavel |
| `Ghave, Guru of Spores` | 0 | false | 0 | 0 | Sem dados locais provados nesta auditoria |

Tambem existem 5 profiles legados `source=edhrec` sem `confidence` nem
`expected_packages` no shape Commander Reference: `Jodah, the Unifier`, `Kaalia of
the Vast`, `Kozilek, the Great Distortion`, `Wilhelt, the Rotcleaver` e `Wilson,
Refined Grizzly`. Eles nao devem ser tratados como guidance forte.

## DB changes

Nenhuma mudanca de banco foi aplicada. Esta auditoria executou somente `SELECT`,
scorecard read-only e leitura de JSON local.

## Code changes

Nenhum codigo foi alterado. Este commit adiciona apenas este relatorio.

## Recomendacao

1. Nao aplicar cleanup agora. Primeiro decidir se Korvold deve preservar historico
   Sprint2+Sprint3 ou se o inventario deve manter somente a fonte mais recente por
   `commander_name + source_url`.
2. Se a decisao for limpar, rodar o SQL dry-run acima, registrar pre/post counts e
   so entao preparar um comando idempotente em transacao, seguido de regeneracao de
   `commander_reference_deck_analysis`.
3. Para Purphoros, Veyran ou Balan, o menor patch seguro e de dados reference:
   criar/aplicar profile e card_stats resolvidos via dry-run primeiro, reexecutar
   scorecard sem runtime ate sair de `blocked`, repetir public proof 5/5 e so
   promover se profile/stats/corpus ficarem 5/5 com invalid/off-identity 0.
4. Para Feather, o proximo gate e corpus dry-run DB-backed; para Jodah/Ghave, nao
   ha dados suficientes para promocao.
