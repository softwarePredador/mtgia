# Estado Real do Banco de Dados — halder (PostgreSQL 17.10)

> Host: 143.198.230.247:5433
> Data: 2026-05-27

## Resumo: 55 tabelas, muitas com dados, mas conhecimento de IA está VAZIO

### Tabelas com DADOS (já populadas)

| Tabela | Registros | Conteúdo |
|:-------|:----------|:---------|
| `archetype_patterns` | 69 | Padrões por arquétipo (aggro, control, combo, etc) com core_cards, flex_options, win_conditions |
| `synergy_packages` | 113 | Pacotes de sinergia |
| `commander_reference_decks` | 121 | Decks de referência |
| `commander_reference_deck_cards` | 10.114 | Cartas dos decks de referência |
| `commander_card_synergy` | 7.179 | Sinergias de carta-comandante |
| `card_function_tags` | 112.563 | Multi-tag funcional (draw, removal, ramp, etc) |
| `card_semantic_tags_v2` | 24.181 | Tags semânticas v2 |
| `card_role_scores` | 46.335 | Scores de papel funcional |
| `card_meta_insights` | 33.274 | Insights de meta |
| `format_staples` | 748 | Staples por formato/arquétipo |
| `meta_decks` | 650 | Decks do meta (torneios) |
| `ml_learning_state` | 1 | Estado de ML |

### Tabelas de ANÁLISE/IA (CRÍTICAS) — TODAS VAZIAS ou SEM DADOS ÚTEIS

| Tabela | Registros | Status |
|:-------|:----------|:-------|
| `commander_reference_profiles` | 48 | ✅ Linhas existem, mas `deck_count = 0` e `profile_json` VAZIO para quase todos |
| `commander_reference_card_stats` | ? | Não verificado |
| `commander_reference_deck_analysis` | ? | Não verificado |

### O Que Isso Significa

O banco tem dados brutos (cartas, decks, tags) mas **não tem conhecimento contextual processado**:

1. **`commander_reference_profiles`**: 48 perfis criados mas VAZIOS. Os crons de análise (scout, validator) produzem markdowns no `docs/hermes-analysis/` mas não preenchem esta tabela.

2. **`card_function_tags`**: 112K registros de multi-tag, mas são tags GENERICAS (draw, removal, ramp). Não tem tag CONTEXTO — "esta carta funciona como ramp NESTE commander porque...". Os tags não tem `deck_id` nem `commander_id` — são globais.

3. **`archetype_patterns`**: 69 padrões, mas sem dados reais de meta (sample_size = 2-3, last_analyzed_at = 2026-02-12). Desatualizados.

4. **`format_staples`**: 748 registros, mas sem contexto de comandante. Uma carta pode ser staple genérica mas péssima para um comandante específico.

5. **Falta tabela para card_deck_profiles** — Não existe tabela que diga "neste deck, esta carta tem função X com importância Y".

## O Que Precisa Ser Feito

### 1. Preencher `commander_reference_profiles` com dados reais

Os crons (knowledge-deep, scout, validator) já analisam 10+ comandantes. Esses dados precisam ser escritos no banco, não só em markdown.

**Dados que crons produzem (em markdown) mas não salvam no banco:**
- Perfil de tema (spellslinger, tribal, etc)
- Métricas validadas (lands, ramp, draw, removal)
- Funções essenciais por comandante
- Anti-patterns
- Core cards
- Win conditions

**Acao:** Criar script de import que lê os markdowns do `docs/hermes-analysis/` e popula `commander_reference_profiles.profile_json`.

### 2. Adicionar tabela `card_deck_profiles`

Nova tabela para armazenar função contextual de cada carta em cada análise de deck:

```sql
CREATE TABLE card_deck_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_name TEXT NOT NULL,
  commander_name TEXT,
  deck_id UUID REFERENCES decks(id),
  generic_tag TEXT,  -- tag genérica (draw, removal, etc)
  contextual_function TEXT,  -- função NESTE deck
  importance TEXT,  -- essencial, alta, media, baixa, removivel
  reason TEXT,  -- explicação do porquê
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### 3. Adicionar tabela `theme_contextual_rules`

Para armazenar regras de validação por tema, baseadas no THEMES.md validado:

```sql
CREATE TABLE theme_contextual_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  theme TEXT NOT NULL,  -- spellslinger, tribal_goblins, landfall, etc
  function TEXT NOT NULL,  -- ramp, draw, removal, etc
  min_count INTEGER,
  max_count INTEGER,
  priority TEXT,  -- essential, high, medium, low
  conditions JSONB,  -- condições contextuais
  UNIQUE(theme, function)
);
```

### 4. Pipeline de Import (Markdown → PostgreSQL)

Script que roda periodicamente e:
1. Lê `THEMES.md` → popula `theme_contextual_rules`
2. Lê `decks/*/edhrec-avg.md` → popula `commander_reference_profiles`
3. Lê `SCOUT_LOG.md` / `VALIDATOR_LOG.md` → popula `card_deck_profiles`
4. Lê perfis EDHREC → popula `archetype_patterns` com dados atualizados

### 5. Atualizar `card_function_tags` com contexto

Adicionar colunas `deck_id` e `contextual_note` à tabela existente, ou criar tabela relacionada `card_function_contextual`.

## Dados que Já Existem e Podem Ser Usados Imediatamente

- **48 commander_reference_profiles** — linhas existem, só falta preencher profile_json
- **69 archetype_patterns** — podem ser atualizados com dados reais do THEMES.md
- **112K card_function_tags** — base sólida, falta adicionar contexto
- **33K card_meta_insights** — dados de meta que podem alimentar os perfis
