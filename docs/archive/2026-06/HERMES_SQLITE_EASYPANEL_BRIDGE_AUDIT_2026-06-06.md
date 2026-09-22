# Hermes SQLite x EasyPanel Postgres Bridge Audit

Data: 2026-06-06

## Veredito

O banco real do aplicativo e o banco Hermes/SQLite nao estao ligados como um runtime unico.

- **EasyPanel/Postgres** e a fonte de verdade do app real.
- **Hermes/SQLite** e um laboratorio de aprendizado, simulacao e validacao.
- A ponte atual e parcial e orientada por scripts: alguns dados agregados podem ir do Hermes para o Postgres, e alguns sinais do Postgres podem alimentar o Hermes, mas nao existe sincronizacao automatica completa de cartas/decks.

## Evidencia do banco real

Backend publico verificado:

- `GET /health`: healthy, production.
- `GET /health/ready`: ready, database healthy.
- `cards_data.card_count`: 33795.

Postgres real auditado por consulta somente leitura via configuracao local do backend:

| Tabela | Linhas |
| --- | ---: |
| `cards` | 33795 |
| `deck_cards` | 50826 |
| `decks` | 1325 |
| `meta_decks` | 653 |
| `external_commander_meta_candidates` | 10 |
| `commander_reference_profiles` | 50 |
| `commander_reference_decks` | 121 |
| `commander_reference_deck_cards` | 10114 |
| `commander_reference_deck_analysis` | 27 |
| `card_role_scores` | 46335 |
| `theme_contextual_rules` | 27 |
| `analysis_sources` | 2 |

Qualidade da tabela `cards`:

| Campo | Cobertura |
| --- | ---: |
| total | 33795 |
| `mana_cost` conhecido | 31932 |
| `oracle_text` conhecido | 33435 |
| `color_identity` conhecido | 33795 |
| `colors` conhecido | 33795 |

Conclusao: o Postgres real ja possui a maior parte dos dados necessarios para alimentar simulacao mais realista.

## Evidencia do Hermes/SQLite

SQLite validado dentro do container Hermes:

`/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`

Tabelas relevantes existentes:

- `deck_cards`
- `learned_decks`
- `wincon_catalog`
- `card_oracle_data`
- `card_tags`
- `format_staples`
- `game_changers`
- `slot_benchmarks`
- `swap_benchmarks`
- `theme_detection_rules`

Schema observado em `deck_cards`:

```text
id, deck_id, card_name, quantity, functional_tag, tag_confidence, is_commander,
is_partner, cmc, type_line, oracle_text
```

Saude de `deck_cards`:

| Campo | Valor |
| --- | ---: |
| total | 543 |
| `oracle_text` conhecido | 436 |
| `type_line` conhecido | 543 |
| `cmc` conhecido | 543 |

Schema observado em `learned_decks`:

```text
id, source, source_url, commander, deck_name, archetype, card_list, card_count,
wincon_primary, wincon_backup, budget_level, notes, created_at
```

Amostra de item em `learned_decks.card_list`:

```json
{"name":"Krenko, Mob Boss","cmc":4.0,"type_line":"Legendary Creature - Goblin Warrior","role":"commander"}
```

Conclusao: o Hermes sabe nome, custo convertido, tipo e papel de varias cartas, mas nao recebe de forma consistente `mana_cost`, `colors`, `color_identity`, `power`, `toughness` e `keywords`.

## Como os mundos se interligam hoje

### Real app -> Postgres

O app e o backend real usam Postgres via:

- `server/lib/database.dart`
- `server/routes/_middleware.dart`

As rotas e servicos de geracao/otimizacao consultam `cards`, `deck_cards`, `card_role_scores`, `commander_reference_*`, `meta_decks` e tabelas auxiliares.

### Postgres -> Hermes

Fluxo existente e parcial:

- Scripts Hermes conseguem ler o Postgres quando recebem variaveis de ambiente corretas.
- `wincon_pipeline.py` pode consumir sinais como `card_role_scores`.
- Esse caminho e aprendizado local, nao runtime do aplicativo.

### Hermes -> Postgres

Fluxo existente e parcial:

- `import_knowledge.py` importa conhecimento agregado como perfis, temas e fontes.
- `export_hermes_learned_deck.py` exporta decks aprendidos para JSON.
- A aplicacao no Postgres precisa passar por importadores controlados, dry-run e validacao. Nao deve haver escrita direta em tabelas reais de decks de usuarios.

## Lacuna principal

O motor de batalha ja pode aceitar informacoes mais ricas, mas o alimentador do Hermes ainda nao entrega esses campos de forma confiavel.

Campos faltantes no SQLite atual:

- `mana_cost`
- `colors`
- `color_identity`
- `power`
- `toughness`
- `keywords`
- `scryfall_id` ou chave estavel de resolucao

Sem esses dados, qualquer melhoria de mana colorida, trample, deathtouch, first strike e combate por atributos reais fica limitada a heuristicas.

## Arquitetura recomendada

1. Manter o Postgres/EasyPanel como fonte de verdade.
2. Criar um snapshot somente leitura do Postgres para o Hermes.
3. Enriquecer o SQLite Hermes com uma tabela local de cache, sem alterar producao:

```sql
CREATE TABLE IF NOT EXISTS card_oracle_cache (
  normalized_name TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  mana_cost TEXT,
  colors_json TEXT,
  color_identity_json TEXT,
  type_line TEXT,
  oracle_text TEXT,
  cmc REAL,
  power TEXT,
  toughness TEXT,
  keywords_json TEXT,
  scryfall_id TEXT,
  updated_at TEXT NOT NULL
);
```

4. Atualizar os loaders de batalha para resolver cada carta por `card_oracle_cache` antes de aplicar fallback.
5. Rodar simulacoes e validadores usando dados enriquecidos.
6. Promover apenas artefatos aprovados para Postgres por scripts com `--dry-run` e `--apply`.

## Regras de seguranca para agentes

- Nunca imprimir string de conexao, senha, JWT, token, `DATABASE_URL`, `OPENAI_API_KEY` ou DSN.
- Toda consulta Postgres de auditoria deve ser read-only por padrao.
- Toda escrita Postgres deve ter dry-run, diff/preview, limite de linhas e relatorio sanitizado.
- Hermes pode aprender livremente no SQLite, mas nao deve escrever direto em `decks`, `deck_cards` ou dados de usuario no Postgres.
- Dados promovidos para producao devem entrar em tabelas de referencia/metadados, nao em colecoes reais de usuarios.

## Proximo passo tecnico

Implementar um script de sincronizacao read-only:

```text
sync_pg_card_metadata_to_hermes.py
```

Responsabilidades:

- Conectar ao Postgres por ambiente sem expor credenciais.
- Ler `cards` por nomes presentes em `deck_cards` e `learned_decks.card_list`.
- Preencher `card_oracle_cache` no SQLite.
- Gerar relatorio com resolvidos, nao resolvidos, campos vazios e cobertura por campo.
- Nao modificar o Postgres.

Depois disso, ajustar o motor Hermes para usar:

1. `card_oracle_cache`
2. `deck_cards`/`learned_decks`
3. fallback heuristico apenas quando nao houver metadata real

Esse e o ponto correto antes de evoluir mana colorida real, multiplos bloqueadores, trample, deathtouch, first strike e regras similares.

## Implementacao aplicada

Status: aplicada localmente na branch Hermes em 2026-06-06.

Arquivos:

- `docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_card_metadata_to_hermes.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v8.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- `docs/hermes-analysis/manaloom-knowledge/card_oracle_cache_report_2026-06-06.json`

O sincronizador:

- Le nomes em `deck_cards` e `learned_decks.card_list`.
- Consulta `cards` no Postgres real por nome exato e front-face de cartas `Front // Back`.
- Cria/atualiza `card_oracle_cache` apenas no SQLite Hermes.
- Suporta `--dry-run`, `--limit` e `--report`.
- Descobre dinamicamente as colunas existentes em `cards`.
- Usa `psycopg2` quando disponivel e possui fallback via `psql`.

Resultado do sync completo:

| Metrica | Valor |
| --- | ---: |
| nomes unicos pedidos | 1241 |
| cards encontrados no Postgres | 1425 |
| aliases gravados no SQLite | 1260 |
| nao resolvidos | 18 |
| `mana_cost` preenchido | 1173 |
| `oracle_text` preenchido | 1423 |
| `colors` preenchido | 990 |
| `color_identity` preenchido | 1157 |
| keywords derivadas | 281 |
| `power` preenchido | 0 |
| `toughness` preenchido | 0 |

Observacao historica: na primeira rodada, o Postgres real consultado nao expunha
`power`, `toughness` e `keywords` como colunas em `cards`. Isso foi corrigido
na mesma data pelo backfill de combat metadata descrito abaixo.

Validacoes executadas:

```text
python -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_card_metadata_to_hermes.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v8.py
python docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py
```

Resultado: todos os testes do `test_battle_analyst_v10_3.py` passaram, incluindo mana colorida, multiplos bloqueadores, trample, deathtouch, first strike e double strike/trample.

Smoke de cache confirmado:

- `Sol Ring`: `mana_cost={1}`, `cmc=1`, `type_line=Artifact`.
- `Krenko, Mob Boss`: `mana_cost={2}{R}{R}`, `cmc=4`, `type_line=Legendary Creature - Goblin Warrior`.
- `Swords to Plowshares`: `mana_cost={W}`, `cmc=1`, `type_line=Instant`.

## Proxima evolucao restante

Resolvido em 2026-06-06:

- `power`
- `toughness`
- `keywords`

Arquivos adicionados/alterados para isso:

- `server/bin/migrate.dart`
- `server/bin/sync_cards.dart`
- `server/bin/backfill_card_combat_metadata.py`
- `server/database_setup.sql`
- `server/doc/BACKFILL_CARD_COMBAT_METADATA_2026-06-06.json`

Migração aplicada no Postgres real:

```text
018_add_card_combat_metadata
```

Backfill real aplicado a partir de `AtomicCards.json`:

| Metrica | Valor |
| --- | ---: |
| rows parseadas | 34128 |
| rows com `power` | 18892 |
| rows com `toughness` | 18892 |
| rows com `keywords` | 16620 |
| rows atualizadas no Postgres | 33524 |
| `cards.power` antes/depois | 0 -> 18537 |
| `cards.toughness` antes/depois | 0 -> 18537 |
| `cards.keywords` antes/depois | 0 -> 16271 |

Depois do backfill, o sync Hermes foi reexecutado e passou a detectar:

- `power`
- `toughness`
- `keywords`

Nova cobertura no `card_oracle_cache` Hermes para o corpus atual:

| Campo | Valor |
| --- | ---: |
| `power` | 443 |
| `toughness` | 443 |
| `keywords` | 564 |

Smoke confirmado:

- `Krenko, Mob Boss`: `mana_cost={2}{R}{R}`, `power=3`, `toughness=3`.
- `Swords to Plowshares`: sem P/T, como esperado para instant.

Evolução futura opcional, nao bloqueante:

- `layout`
- `loyalty`
- `subtypes`
- `supertypes`
