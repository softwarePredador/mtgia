# Information Bank Diagnostic — 2026-06-15

## Resumo

Este diagnóstico avaliou o banco de informações do ManaLoom a partir de três
fontes reais:

- PostgreSQL de produção/staging configurado no backend, sem expor credenciais.
- SQLite Hermes local em
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`.
- Código consumidor em `server/routes`, `server/lib`, `server/bin` e scripts
  Hermes.

Objetivo: identificar o que já agrega ao produto, o que é laboratório útil, o
que está redundante/write-only e quais agregações faltam para melhorar geração
de decks, otimização, análise, importação localizada, mercado e battle.

Escopo inicial: diagnóstico analítico. A atualização posterior de 2026-06-15
adicionou um primeiro slice backend-only: a view
`card_intelligence_snapshot`, sem mudar API pública, app Flutter ou payloads
mobile.

## Snapshot de cobertura PostgreSQL

| Fonte | Linhas | Entidades cobertas | Cobertura sobre `cards` | Diagnóstico |
|---|---:|---:|---:|---|
| `cards` | 34.329 | 34.329 cartas | 100% | Base principal do produto. |
| `card_legalities` | 324.538 | 32.075 cartas | 93,43% | Forte para legalidade/Commander. Ainda há cartas sem legalidade explícita. |
| `price_history` | 3.679.275 | 31.518 cartas | 91,81% | Forte para mercado e preço; precisa agregados leves para UI/IA. |
| `card_localized_names` | 251.107 | 29.104 cartas | 84,78% | Muito relevante para import PT/idiomas. Ainda há lacuna de localização. |
| `card_function_tags` | 112.563 | 25.363 cartas | 73,88% | Agrega diretamente para análise/optimize/weakness. Multi-tag é correto. |
| `card_semantic_tags_v2` | 24.181 | 24.181 cartas | 70,44% | Útil para explicabilidade e shadow/gate semântico; ainda incompleto. |
| `card_battle_rules` | 3.158 | 3.146 cartas | 9,16% | Alta precisão para cartas críticas, mas não é cobertura global. |
| `commander_reference_deck_cards` | 10.114 | 2.126 cartas | 6,19% | Corpus Commander especializado, não base geral de cartas. |

Outras granularidades importantes:

- `card_rulings`: 73.858 rulings para 18.992 `oracle_id`; não usa `card_id`.
- `commander_learned_decks`: 61 learned decks no PostgreSQL.
- `commander_card_usage`: 912 linhas / 676 nomes normalizados; ainda é
  name-based.
- `decks`: 1.337 decks, sendo 1.308 Commander.

## Snapshot SQLite Hermes

| Tabela SQLite | Linhas | Papel |
|---|---:|---|
| `battle_card_rules` | 3.158 | Espelho operacional das regras de battle. |
| `deck_cards` | 100 | Snapshot de um deck alvo com `functional_tags_json`, `semantic_tags_v2_json`, `battle_rules_json`, `deck_hash`, `semantics_hash`, `ruleset_hash`. |
| `learned_decks` | 120 | Corpus local/laboratorial de decks aprendidos. |
| `user_learning_events` | 51 | Eventos importados do PG para aprendizado. |
| `optimizer_quality_reviews` | 123 | Revisões de qualidade do optimizer. |
| `slot_benchmarks` | 115 | Benchmarks de slot. |
| `optimizer_baseline_runs` | 5 | Baselines aprovados, 864 jogos agregados. |

Leitura correta:

- SQLite Hermes está adequado como cache/laboratório.
- Não deve virar fonte final do produto.
- A sincronização PG -> Hermes já preserva hashes semânticos para o deck alvo.
- Há divergência esperada entre `commander_learned_decks` do PG e
  `learned_decks` do SQLite; isso precisa ficar documentado como corpus local,
  não conflito.

## O que realmente agrega hoje

### 1. Catálogo de cartas, legalidade e localização

Agrega diretamente:

- Busca de cartas.
- Importação por nomes localizados.
- Validação Commander.
- Construção/otimização com identidade de cor e singleton.

Ponto forte:

- `card_localized_names` cobre 84,78% das cartas e já resolve o problema de
  import em português/outros idiomas melhor do que depender de nome inglês.

Gap:

- Falta uma visão/materialização única de resolução:
  `printed_name -> card_id -> oracle_id -> canonical_name -> legality`.
- `card_rulings` usa `oracle_id`, enquanto a maior parte do produto usa
  `card_id`; isso precisa de join padronizado para auditorias/rules.

### 2. Tags funcionais

Agrega diretamente:

- Aba Análise.
- Optimize.
- Weakness/recommendations.
- Balanceamento de ramp/draw/removal/wipes/protection.

Ponto forte:

- 112.563 tags para 25.363 cartas.
- Multi-tag é desejável: carta de Magic normalmente tem múltiplas funções.
- Exemplos fortes: `draw`, `removal`, `ramp`, `protection`, `board_wipe`,
  `tutor`, `wincon`.

Gap:

- Ainda há ~26% das cartas sem `card_function_tags`.
- O produto precisa consumir agregação por `card_id`, nunca `JOIN` que multiplica
  linhas de deck sem controle.
- Tags derivadas de battle rules só devem entrar quando `trusted` e
  `traceable`.

### 3. Semantic v2

Agrega diretamente:

- Explicabilidade.
- Score de candidate quality.
- Shadow/gate futuro para optimize/generate.

Ponto forte:

- 70,44% de cobertura.
- Fonte única atual: `deterministic_semantic_v2`.
- Confiança média observada: 0,822.

Gap:

- Ainda deve operar como sinal complementar, não enforcement global duro.
- Falta agregação de regressão por comandante/arquetipo: a tag ser correta em
  geral não prova que é boa no deck específico.

### 4. Battle rules

Agrega para:

- Battle/Hermes simulator.
- Forensic/decision audit.
- Derivação conservadora de tags futuras.

Estado:

- 1.691 regras verificadas (`manual` + `curated`).
- 1.467 regras `generated/needs_review`.
- 10 cartas têm múltiplas regras; máximo observado: 3 regras por carta.

Leitura correta:

- Múltiplas regras por carta são corretas no domínio de Magic.
- O erro a evitar é fazer `JOIN` direto em `card_battle_rules` e multiplicar
  cartas no deck.
- A agregação correta é por `card_id`, preservando lista/JSON de regras.

Gap:

- Cobertura global é só 9,16%; usar para cartas críticas e replays, não para
  avaliação universal de deck.
- `needs_review` não deve executar comportamento duro.

### 5. Learned decks e Commander Reference

Agrega para:

- Botão "Usar deck aprendido".
- Fallback determinístico por comandante.
- Construção/otimização com referência real de Commander.

Estado:

- PG: 61 `commander_learned_decks`.
- SQLite: 120 `learned_decks`, todos com 100 cartas no top 20 por comandante.
- `commander_reference_deck_cards`: 10.114 linhas e 0 unresolved.

Gap:

- Learned deck deve continuar single-commander até existir corpus seguro para
  Partner/Background.
- `commander_card_usage` ainda é name-based; precisa bridge para `card_id` e
  confidence.
- O produto deve esconder metadata Hermes para usuário normal.

### 6. Telemetria de IA/optimize

Agrega para:

- Debug de `/ai/optimize`.
- Fallback telemetry.
- Prompt feedback.
- Candidate quality.

Estado:

- `optimization_analysis_logs`: 792 linhas.
- `ai_optimize_fallback_telemetry`: 198 linhas.
- `ml_prompt_feedback`: 3 linhas.
- `optimize_rejection_penalties`: 371 linhas.
- `card_role_scores`: 46.335 linhas.

Gap:

- Há coleta, mas o loop ainda não parece totalmente fechado para seleção
  automática de prompt/modelo.
- `ml_prompt_feedback` ainda tem pouca amostra para aprendizado estatístico.
- Falta scorecard consolidado por versão de prompt, comandante e outcome.

### 7. Mercado/preço

Agrega para:

- Valor de carta/deck.
- Marketplace.
- Tendência de mercado.

Estado:

- `price_history`: ~3,68M linhas.
- `card_meta_insights`: 33.274 linhas.

Gap:

- Para app/IA, consultar histórico bruto é pesado.
- Falta materialização explícita de `latest_price`, `price_delta_7d`,
  `price_delta_30d`, liquidez e confidence.

## O que está parcialmente agregado ou write-only

| Tabela | Estado | Diagnóstico |
|---|---|---|
| `battle_simulations` | Poucas linhas; lida por extração ML e rota simulate | Útil, mas não substitui replays Hermes. Precisa link com `baseline_id/hash`. |
| `deck_matchups` | Escreve/lê em simulate-matchup | Útil se virar matriz por comandante/arquetipo; hoje é pouco populada. |
| `deck_weakness_reports` | Escreve/lê em weakness-analysis | Útil para produto, mas precisa fechar ciclo com actions/tarefas resolvidas. |
| `ml_prompt_feedback` | Pouca amostra | Coleta existe; ainda insuficiente para decisão automática. |
| `commander_reference_decks` raw | Persistido como corpus | Produto deve ler agregados, não raw decklists diretamente. |
| `card_deck_profiles` | Import Hermes/manual | Útil como proteção CORE por deck; precisa origem e freshness claros. |

## Principais gaps de agregação

### P0 — Identidade canônica entre bases

Problema:

- Algumas tabelas usam `card_id`, outras `oracle_id`, outras nome normalizado.
- Isso aumenta risco de duplicação, fanout e aprendizado divergente.

Ação recomendada:

- Criar camada/visão canônica `card_identity_bridge`:
  `card_id`, `oracle_id`, `scryfall_id`, `canonical_name`,
  `normalized_name`, aliases/localized names.
- Padronizar todos os syncs Hermes para gravar `card_id` quando possível e
  manter nome apenas como fallback auditável.

Validação:

- Nenhum sync pode gerar `deck_cards` duplicado por fanout.
- `commander_card_usage` deve reportar taxa de resolução `normalized_name ->
  card_id`.

### P0 — Agregado único de inteligência de carta

Problema:

- Dados úteis estão espalhados: legalidade, preço, function tags, semantic v2,
  battle rules, rulings, usage, meta insights.

Ação recomendada:

- Criar visão/materialized view `card_intelligence_snapshot`:
  - `card_id`;
  - legalidades por formato;
  - localized names;
  - function tags agregadas;
  - semantic v2;
  - battle rules verificadas agregadas;
  - price latest/deltas;
  - commander usage/meta score;
  - freshness/hash.

Regra:

- `battle_rules` entram como lista agregada; nunca join 1:N direto no deck.
- `needs_review` entra como telemetry, não comportamento duro.

### P1 — Scorecard de aprendizado por comandante

Problema:

- Existe deck aprendido, usage, reference corpus e battle evidence, mas ainda
  falta painel único por comandante.

Ação recomendada:

- Criar `commander_learning_snapshot` com:
  - decks aprendidos ativos;
  - quantidade de eventos treináveis;
  - cartas core;
  - role distribution;
  - wincons;
  - cards rejeitadas;
  - baseline/replay status;
  - confidence por fonte.

Uso:

- Backend decide; Hermes propõe.
- App só consome status resumido e deck revisado.

### P1 — Métrica estatística estilo 17Lands, Commander-safe

Problema:

- WR bruto de battle/Lorehold não deve virar verdade.

Ação recomendada:

- Agregar por carta/swap:
  - `seen_in_hand_wr`;
  - `cast_wr`;
  - `without_seen_wr`;
  - `delta_vs_baseline`;
  - `sample_size`;
  - `opponent_archetype`;
  - `baseline_hash`;
  - `decision_trace_confidence`.

Regra:

- Sem sample mínimo e replay limpo, não promover swap.

### P1 — Closure loop de optimize/prompt

Problema:

- Telemetria existe, mas ainda falta transformar em seleção/avaliação de prompt.

Ação recomendada:

- Scorecard por `prompt_version`, `commander`, `archetype`:
  - taxa de fallback;
  - cards aceitas/rejeitadas;
  - qualidade pós-validate;
  - bloqueios semantic v2;
  - tempo/erro.

### P2 — Preço/market agregados

Problema:

- `price_history` é volumoso e forte, mas bruto demais para app/IA.

Ação recomendada:

- Criar snapshot diário por carta:
  `latest_price`, `foil_price`, `delta_7d`, `delta_30d`,
  `volatility`, `last_seen`.

### P2 — Rulings para battle/card-specific

Problema:

- `card_rulings` está por `oracle_id`; battle usa `card_id`/nome.

Ação recomendada:

- Criar agregação `card_rules_text_snapshot` juntando `cards.oracle_id` com
  rulings, sem duplicar cartas.

## Classificação final

| Área | Valor atual | Falta para virar melhor produto |
|---|---|---|
| Catálogo/Busca/Import | Alto | Completar aliases/localized e bridge de identidade. |
| Legalidade Commander | Alto | Cobrir cartas sem legalidade explícita e manter tests guardião. |
| Function tags | Alto | Melhorar cobertura e sempre consumir agregado por `card_id`. |
| Semantic v2 | Médio/alto | Ampliar cobertura e manter shadow/gate gradual. |
| Battle rules | Médio, crítico para Hermes | Usar só agregado/trusted; aumentar cobertura por cartas vistas em replay. |
| Learned decks | Alto para comandantes suportados | Scorecard por comandante e single-commander até corpus Partner. |
| Telemetria AI/optimize | Médio | Fechar loop por prompt/outcome. |
| Mercado/preço | Alto | Materializar snapshots leves. |
| Social/trades/messages | Produto ativo | Fora do foco de IA, mas precisa continuar com contadores/stale-state. |

## Próximo slice recomendado

Implementado em 2026-06-15:

1. Criada a view `card_intelligence_snapshot` em
   `server/lib/ai/candidate_quality_data_support.dart`.
2. A view agrega por `card_id` antes de juntar com `cards`, preservando:
   - múltiplas `card_function_tags`;
   - múltiplos `card_role_scores`;
   - múltiplos sinais `commander_card_synergy`;
   - múltiplas entradas `card_semantic_tags_v2`;
   - múltiplas `card_battle_rules`;
   - legalidades e rulings por `oracle_id`.
3. Os scripts `candidate_quality_data_foundation.dart`,
   `semantic_layer_v2_backfill.dart` e `candidate_quality_meta_signals.dart`
   passam a garantir a view junto da fundação de candidate quality.
4. Teste focado garante que a view não faz `LEFT JOIN` direto em fontes
   multi-linha como `card_battle_rules`, `card_function_tags` e
   `card_semantic_tags_v2`.
5. Criada a view `card_identity_bridge` em
   `server/lib/import_card_lookup_service.dart`, garantida junto da tabela
   `card_localized_names`. Ela expõe aliases canônicos/localizados com
   `card_id`, `oracle_id`, `scryfall_id`, nome canônico, lookup normalizado,
   idioma, source e prioridade de match.
6. Consumidores app-facing seguros passaram a usar `card_intelligence_snapshot`
   quando disponível, com fallback para o caminho antigo:
   - `POST /decks/:id/ai-analysis`;
   - `POST /decks/:id/recommendations`;
   - `POST /ai/weakness-analysis`.

Validação executada neste slice:

- SQL real de `card_identity_bridge` e `card_intelligence_snapshot` compilou em
  PostgreSQL dentro de transação com `ROLLBACK`.
- `card_identity_bridge` retornou `305.905` linhas de identidade/alias no banco
  atual; `card_intelligence_snapshot` retornou `34.329` cartas.
- Testes focados:
  `import_list_service_test.dart`, `candidate_quality_data_support_test.dart` e
  `experimental_deck_ai_authorization_source_test.dart`.

Ainda pendente:

1. Fazer o snapshot alimentar os loaders profundos do optimize candidate
   context, além dos endpoints já migrados.
2. Usar `card_identity_bridge` em `commander_card_usage` e syncs Hermes para
   reportar taxa de resolução `normalized_name -> card_id`.
3. Ampliar testes de fanout com banco temporário:
   - carta com múltiplas `card_function_tags`;
   - carta com múltiplas `card_battle_rules`;
   - deck não pode multiplicar linhas.
4. Criar agregados opcionais para fontes não garantidas em todos os ambientes:
   - `price_history`;
   - `commander_reference_deck_cards`.
5. Depois criar `commander_learning_snapshot`.

## Triagem Hermes pós-slice

Após `git fetch --all --prune`, a branch `origin/codex/hermes-analysis-docs`
foi lida até `1c0f9b86` (`docs: audit estrutura postgresql-tables-not-used
2026-06-15`). Achados incorporados:

- `server/doc/API_CONTRACTS_AND_DATA_MAP.md` e `server/manual-de-instrucao.md`
  ainda descreviam `deck_matchups` e `deck_weakness_reports` como write-only.
  A fonte atual mostra leitura pelas próprias rotas; os textos foram corrigidos
  para histórico/cache operacional.

Achados não incorporados neste slice:

- `ml_prompt_feedback` sem chamador foi rejeitado como stale neste checkout:
  `/ai/optimize` chama `recordOptimizeMlFeedback(...)`, que chama
  `MLKnowledgeService.recordFeedback(...)`.
- Refatores grandes de `optimize_runtime_support.dart`,
  `routes/ai/optimize/index.dart` e ciclos app/engine permanecem pendentes,
  mas fora do primeiro slice seguro de agregação/identidade.

## Comandos usados

```bash
psql ... pg_stat_user_tables
psql ... coverage queries por card_id/oracle_id/nome normalizado
sqlite3 docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db ".tables"
python3 scanners locais para consumo SELECT/INSERT/UPDATE/DELETE/DDL
```

Credenciais, tokens, DSNs e connection strings completas não foram documentados.
