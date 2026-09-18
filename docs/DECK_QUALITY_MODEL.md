# BrewTact — modelo de qualidade de deck gerado — 2026-09-18

Status: `MECHANISM_MAPPED · SOURCE_VERIFIED_AGAINST_CODE · DB_FIGURES_FROM_2026-08-03_BACKUP · NOT_RATIFIED`

Este documento responde uma pergunta que nenhum outro documento do repositório
responde: **o que decide a qualidade de um deck Commander gerado pela IA.**

O mapa existente cobre topologia, contenção e governança.
`docs/BREWTACT_DECKBUILDER_AI_CURRENT_FLOW_2026-08-12.md` descreve o que cada
jornada faz e o que está guardado; `docs/status/CURRENT_PRODUCT_DECISION.md`
decide escopo. Nenhum dos dois desce à camada de mecanismo: os termos
`referenceProfile`, `usage_count`, `commander_reference_profiles` e
`optimize_filler_loader_support` têm **zero ocorrências** em `docs/generated/`
e em `docs/project_logic_contracts.json`. É essa lacuna que este documento
preenche.

Toda afirmação aqui foi verificada contra o código. Números de banco vêm do
backup local `backups/manaloom-postgres/manaloom-postgres-20260803T141713Z.dump`
(2026-08-03) e estão marcados como tal — **não são leitura de produção**. O que
não pôde ser verificado está na seção "O que não sabemos", com o comando para
fechar cada ponto.

Este documento não autoriza mutação, deploy, abertura de capability nem
promoção. Ele descreve mecanismo.

---

## 1. A resposta curta

Hoje, o que decide quais cartas entram num deck gerado é, em ordem:

1. **Se o comandante tem perfil de referência.** Essa única condição
   (`server/routes/ai/generate/index.dart:136`) separa dois caminhos de
   qualidade radicalmente diferentes.
2. **Sem perfil — a memória do LLM.** Nenhum conjunto de candidatos é injetado
   no prompt. O modelo escolhe as cartas que conhece.
3. **Nos caminhos determinísticos — um contador de popularidade de 189 dias
   atrás, derivado de um corpus que é 39% não-Commander.**

O terceiro ponto é o mais consequente e o menos conhecido. A seção 4 o detalha.

---

## 2. A bifurcação da geração

```
POST /ai/generate
  │
  ├─ capability ai_generate_rebuild desligada ──────► 404 capability_unavailable
  │                                (release_capability_policy.dart:425-430)
  │
  └─ loadUsableCommanderReferenceProfile(commander)      (index.dart:136)
       │
       ├─ perfil existe ─────────► CAMINHO A — guiado
       │                           • comandante forçado
       │                           • filtro de identidade + refill
       │                           • avaliação contra stats de referência
       │                           • reparo estrutural repõe cartas do banco
       │
       └─ perfil ausente ────────► CAMINHO B — não guiado
            │
            ├─ archetype stats disponíveis  (commander_reference_card_stats_support.dart:663-786)
            │     → entram apenas como PROSA no prompt (index.dart:553-558)
            │       e em `diagnostics`; nunca no construtor determinístico
            │
            └─ nada disponível → prompt estático (index.dart:559)
                  → gates só REPROVAM; sem perfil o reparo não roda
                    (o reparo está dentro de `if (referenceProfile != null)`, index.dart:1056)
                  → em produção, `allowsMockFallbacks == false` → 422
```

**Correção de um erro comum:** o multiplicador `* 0.72` do fallback de
arquétipo (`commander_reference_card_stats_support.dart:767`) **não seleciona
carta nenhuma**. Ele pondera um score que só alimenta texto de prompt e
diagnóstico. Quem lê o código rápido conclui que há um mecanismo de
transplante de cartas entre comandantes; não há.

### Garantias por caminho

| Caminho | Vale | Não vale |
| --- | --- | --- |
| A — com perfil | comandante forçado, identidade de cor, avaliação vs. stats, reparo estrutural | score de sinergia carta a carta (não existe em caminho nenhum) |
| B — com archetype stats | legalidade, bracket, gate estrutural, identidade de cor | nenhuma evidência de carta entra na seleção |
| B — sem nada | legalidade, bracket, gate estrutural | nenhum reparo possível; 422 em produção |

---

## 3. Perfis de referência — o que são e quantos existem

### Esquema

Criado na migração `034` (`server/bin/migrate.dart:1059-1186`), **não** em
`server/database_setup.sql`:

- `commander_reference_profiles`: `commander_name` (PK), `source`,
  `deck_count`, `profile_json` (JSONB), `updated_at`
- `commander_reference_card_stats`: 14 colunas, PK
  `(commander_name_normalized, card_name_normalized, package_key)`

### O que um perfil contém

14 chaves de topo, das quais **6 nunca são lidas por código de produção**:
`commander_relevance`, `source_refs`, `source_limit_notes`, `updated_at`,
`themes[].confidence`, `themes[].notes`.

`role_targets` — o campo que descreve a composição alvo do deck — entra
**apenas como prosa no prompt** (`commander_reference_profile_support.dart:543`).
Não há verificação posterior de que o deck gerado respeitou os alvos.

`deck_count` é gravado como `0` fixo no upsert
(`commander_reference_profile_support.dart:640-647`), e
`commanderReferenceConfidenceFromDeckCount` nunca é aplicada a perfil
persistido. A confiança declarada no JSON é curada à mão, não derivada.

### Cobertura — e por que o número é incerto

| Fonte | Alegação | Situação |
| --- | --- | --- |
| Built-ins no código | 2 (Lorehold, Kaalia) | `commander_reference_profile_support.dart:47,57` — certos |
| Lote Strixhaven | 10 JSONs em `docs/qa/commander_reference_profiles_secrets_of_strixhaven_2026-05-11/` | README diz **"no database apply was run"** |
| `API_CONTRACTS_AND_DATA_MAP.md:224` | lote 1 + lote 2 + "Anchor 30 batches A-C" persistidos (~42) | JSONs dos lotes 2 e Anchor-30 **foram apagados da árvore** no commit `8cab6400b` |

As duas últimas linhas são mutuamente inconsistentes e **não podem ser
resolvidas sem consultar o banco**. Ver seção 7.

Para escala: o cache local tem **615 criaturas lendárias**. Se a cobertura
real for 2, praticamente todo deck gerado hoje cai no Caminho B.

### Como um perfil nasce

Só por CLI manual — `server/bin/commander_reference_profile.dart:76` e um
segundo CLI específico de Lorehold. **Nenhuma rota, cron ou job escreve nessas
tabelas.** Não existe caminho automatizado de criação de perfil, e é por isso
que a cobertura não cresce.

---

## 4. O pool de candidatos e a chave que o ordena

Este é o mecanismo menos documentado e o de maior impacto.

### A query

`server/lib/ai/optimize_filler_loader_support.dart:1263-1320`, função
`loadCompetitiveNonLandFillers`:

```sql
WHERE (cl.status = 'legal' OR cl.status = 'restricted' OR cl.status IS NULL)
  AND NOT (type_line ~* 'land')
  AND c.oracle_text IS NOT NULL
  AND c.color_identity <@ @identity::text[]
ORDER BY sub.pop_score DESC, LOWER(sub.name) ASC
LIMIT 600
```

Parâmetros: **`identity` e `legality_format`. Só.**

**O comandante não entra na query.** Dois comandantes de mesma identidade de
cor recebem exatamente a mesma lista de 600 candidatos.

`compareCandidates` (`:516-533`) desempata por: penalidade de intenção de slot
→ nome preferido → ordem do SQL → alfabético. **Não há termo de sinergia em
nenhum ponto.**

### `pop_score` = `card_meta_insights.usage_count`

Esta coluna ordena tudo. Medida diretamente no backup de 2026-08-03:

| Fato | Valor |
| --- | --- |
| Linhas em `card_meta_insights` | 33.274 |
| `max(last_updated_at)` | **2026-03-13** (189 dias antes de 2026-09-18) |
| Distribuição | min 1 · mediana 5 · p90 22 · p99 50 · máx 471 |
| Fronteira do `LIMIT 600` | 600º e 601º valem ambos 50, dentro de um empate de 574 cartas |

As 15 cartas mais bem rankeadas:

```
471  Island          153  Thoughtseize      132  Plains
399  Mountain        153  Flooded Strand    130  Ancient Tomb
223  Force of Will   142  Polluted Delta    128  Misty Rainforest
219  Forest          136  Wasteland         126  Stock Up
204  Swamp           135  Steam Vents
```

**Force of Will, Thoughtseize, Wasteland, Steam Vents, Polluted Delta** são
staples de Legacy, Vintage, Modern e Pioneer — não de Commander.

### Por que cartas de outros formatos rankeiam no topo

`server/bin/extract_meta_insights.dart:133-165` lê a tabela `meta_decks`
**inteira, sem filtro de formato.** Composição do corpus, medida no mesmo
backup (653 decks):

| Formato | Decks | Fatia |
| --- | --- | --- |
| cEDH | 223 | 34,2% |
| EDH | 162 | 24,8% |
| Standard | 46 | 7,0% |
| Pioneer | 46 | 7,0% |
| Vintage | 44 | 6,7% |
| Modern | 41 | 6,3% |
| Pauper | 40 | 6,1% |
| Legacy | 40 | 6,1% |

**~39% do sinal que ordena candidatos de Commander vem de decks que não são
Commander.**

### O contador nunca decai

`extract_meta_insights.dart:838`:

```sql
usage_count = card_meta_insights.usage_count + @usage
```

Acumulação pura. Rodar o extractor duas vezes dobra os valores. Carta que saiu
do meta nunca perde posição. O único reset é `TRUNCATE` sob `--full` (`:25, :92`).

Consequência observável no backup: **29.593 nomes armazenados não existem no
`meta_decks` atual** — os valores gravados divergiram do corpus. A causa não é
determinável pelo repositório e **não deve ser afirmada**.

### Resumo brutal

O sinal que decide qual carta entra num deck Commander gerado é um contador de
popularidade **desatualizado em 189 dias**, **acumulado sem decaimento**,
**derivado 39% de formatos errados**, **cego ao comandante**, e cuja fronteira
de corte cai no meio de um empate de 574 cartas resolvido por ordem alfabética.

---

## 5. Quem escreve o dado — e se está alcançável hoje

Este inventário não existia em lugar nenhum.

| Tabela | Quem escreve | Alcançável hoje? |
| --- | --- | --- |
| `cards` | `sync_cards.dart`, `sync_cards_full_fast.py`, migrações, algumas rotas | **Não** — `cron_sync_cards.sh` não está registrado no daemon; rotas exigem `catalog_private` (off) |
| `card_legalities` | `sync_card_legalities_from_scryfall.py`, `sync_cards.dart` | **Não** — job registrado, mas exige `catalog_private` (off) **e** `..._APPLY=1`, que o daemon força a `"0"` |
| `card_meta_insights` | `extract_meta_insights.dart:828` | **Não — e nunca foi agendado.** Zero referências em cron, script ou daemon |
| `commander_reference_profiles` | 2 CLIs manuais | **Não** — sem rota, cron ou job |
| `commander_reference_card_stats` | idem | **Não** |
| `commander_card_usage` | `upsertCommanderCardUsage` | **Não** — exige `MANALOOM_ENABLE_PRODUCT_LEARNING_WRITES=1`; `.env.example:63` = `0` |
| `commander_learned_decks` | `upsertCommanderLearnedDeck` | **Não — a função não tem nenhum chamador.** É código morto; o CLI correspondente lança `StateError` antes de tocar o banco |
| `deck_learning_events` | `recordUserCreatedDeckLearning`, via `POST /decks` | **Não** — rota exige `decks_private` (off) + flag de learning |

### Os três cadeados independentes

1. **Política de release.** As 29 capabilities estão `allowed=false`
   (`server/config/release_capabilities.json`). `_jobs_for_release_policy`
   (`manaloom_ops_daemon.py:736`) filtra os 16 jobs; sobra **um**,
   `hermes_cron_governor_report`, que tem tupla de capability vazia e **não
   escreve em PostgreSQL**.
2. **Flags forçadas.** `manaloom_ops_daemon.py:241-250` sobrescreve 8 flags de
   apply para `"0"` depois de carregar o `.env`. Abrir uma capability não basta.
3. **Guarda de learning.** `shouldWriteProductLearning`
   (`e2e_validation_policy.dart:21-36`) é fail-closed por padrão.

**Conclusão mecânica: nenhum job agendado escreve em PostgreSQL hoje.** Toda
linha que alimenta a qualidade do deck é pré-existente, ou foi escrita por CLI
manual, ou por rota — e as rotas relevantes também estão desligadas.

Última escrita real comprovada: `2026-06-29T20:41:39Z`, em
`commander_learned_decks`, registrada no único artefato com `"mode": "apply"`
do repositório.

---

## 6. Frescor de cada entrada

Medido em 2026-09-18. Valores de banco vêm do backup de 2026-08-03 e são, para
entradas sem job ativo, **limites inferiores**.

| Entrada | Fonte oficial | Última checagem | Dias | Checagem automática? |
| --- | --- | --- | --- | --- |
| `card_meta_insights.usage_count` | corpus interno `meta_decks` | 2026-03-13 | **189** | **Nenhuma** |
| `meta_decks` (corpus) | importações externas | 2026-06-01 | 109 | Nenhuma |
| `commander_game_changers.json` | anúncio WotC | 2026-07-14 | **66** | Gate roda a cada commit, mas **nunca compara com a WotC** |
| ↳ o anúncio citado | magic.wizards.com | 2026-02-09 | 221 | Não |
| `server/magicrules.txt` | Comprehensive Rules | 2026-06-19 | 91 | `sync_rules.dart --check` existe e compara upstream de verdade, mas não está em cron nem CI |
| `cards` (MTGJSON) | MTGJSON 5.3.0+20260605 | 2026-06-06 | 104 | `cron_sync_cards.sh` existe, não registrado |
| `card_legalities` | Scryfall | 2026-06-06 | 104 | Job registrado mas dry-run por padrão |
| `edhrec_card_snapshots` | EDHREC | 2026-06-02 | 108 | `cron_snapshot_edhrec.sh` existe, não registrado |

O padrão é consistente: **os fetchers existem e são bons; o relógio não existe.**
Oito scripts de sync vivem como receita de crontab em comentário, nunca
registrados em `manaloom_ops_daemon.py`.

---

## 7. O que não sabemos — e como fechar

Nada abaixo deve ser afirmado sem verificação. Os comandos são read-only.

**7.1 Cobertura real de perfis de referência.** A inconsistência da seção 3
(README diz "não aplicado" vs. `API_CONTRACTS` diz "~42 persistidos") só
fecha lendo o banco. Consulta canônica já existe no repo —
`commander_reference_readiness_cli_support.dart:1-12`
(`activeUsableCommanderReferenceProfilesSql`):

```bash
psql "$DATABASE_URL" -c "select commander_name, source, updated_at from commander_reference_profiles order by updated_at desc;"
```

**7.2 Estado de produção depois de 2026-08-03.** Todo número de banco aqui vem
do backup. Produção pode estar melhor (jobs rodados à mão) ou igual.

**7.3 Causa da divergência de `usage_count`.** 29.593 nomes gravados não estão
no corpus atual. Corpus substituído sem `--full`, pipeline anterior com parsing
diferente, ou execuções parciais repetidas — indistinguíveis daqui.

**7.4 Se existe revisão das Comprehensive Rules posterior a 2026-06-19.**
Exige buscar upstream.

**7.5 Variáveis de runtime.** `ENVIRONMENT`, `OPENAI_PROFILE`,
`OPENAI_MODEL_GENERATE` e as flags de learning não estão no repositório, então
não é possível afirmar qual ramo da seção 2 executa em produção.

---

## 8. Onde intervir, em ordem de retorno

Derivado do que está acima, não de preferência.

1. **Filtrar `meta_decks` por formato Commander** em
   `extract_meta_insights.dart`. Remove ~39% de ruído do sinal que ordena todo
   o pool. É um `WHERE`.
2. **Tornar `usage_count` idempotente com decaimento.** Hoje o valor é função
   de quantas vezes o extractor rodou, não do meta.
3. **Colocar o comandante na query do pool** e adicionar termo de sinergia.
   É o maior ganho de qualidade por esforço, e só é verificável depois de (1) e
   (2), porque senão o sinal continua sujo.
4. **Automatizar a criação de perfis de referência.** Enquanto for CLI manual,
   a cobertura não cresce e o Caminho B continua sendo o caso normal.
5. **Registrar os 8 scripts de sync no daemon** sob `catalog_private` — lane
   separada da de learning, que está bloqueada por schema e por privacidade.

Medição: `scripts/quality_gate.sh deck-quality` pontua consistência de mana de
forma determinística sobre decks reais, com baseline de tolerância zero. Ele
**não** mede potência de deck — ver
`server/test/ai/deck_quality_report_limits_test.dart`, que fixa um deck de 36
Forest + 64 criaturas baunilha pontuando 84, empatado com o melhor deck real do
fixture. Serve para detectar regressão, não para declarar qualidade.

---

## 9. Procedência

Verificado por leitura de código em `354983a1e`/`a2d044618`, branch
`codex/free-beta-release-candidate-2026-07-17`, em 2026-09-18. Números de banco
extraídos com `pg_restore` (PostgreSQL 17) do backup local de 2026-08-03;
nenhum acesso a produção foi feito.

Este documento ainda **não** está em `canonical_documents` de
`docs/project_logic_contracts.json`. Registrá-lo é uma linha, e é decisão de
governança do dono.
