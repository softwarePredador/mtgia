# ManaLoom — Crons do Aprendizado & Pendências de Lógica

Documento único com (1) a validação/esquema das crons que alimentam o
aprendizado (recommendations/optimize/análises) e (2) o backlog de lacunas de
lógica ainda **não** implementadas. Gerado durante a auditoria de coerência
das crons; a parte de implementação de lógica está apenas DOCUMENTADA aqui.

Data: 2026-06-02

---

## 1. Crons — estado e correções

### 1.1 Crons que JÁ existiam (mantidas)

| Script | Alvo | Cadência sugerida | Função |
|--------|------|-------------------|--------|
| `bin/cron_sync_cards.sh` | `sync_cards.dart` | diária | Sync incremental de cartas (Scryfall) |
| `bin/cron_sync_prices.sh` | `sync_prices.dart` | diária | Preços via Scryfall (limit/stale-hours) |
| `bin/cron_sync_prices_mtgjson.sh` | `sync_prices_mtgjson_fast.dart` | diária (04:00) | Preços via MTGJSON (bulk + UPDATE join) |
| `bin/cron_cleanup_optimize_telemetry.sh` | `cleanup_optimize_telemetry.dart` | diária/semanal | Limpeza de telemetria do optimize |

### 1.2 Crons CRIADAS nesta auditoria (lacuna de coerência do aprendizado)

Toda a camada nova de aprendizado (Fases 2A/2B/2C) estava **sem cron** —
populada apenas por execução manual. Sem agendamento, o sinal fica defasado ou
inerte. Wrappers criados seguindo o padrão dos cron `*.sh` existentes:

| Script novo | Alvo | Cadência | Por quê |
|-------------|------|----------|---------|
| `bin/cron_snapshot_edhrec.sh` | `snapshot_edhrec.dart` | **diária (05:00)** | **CRÍTICO.** A tendência rising/falling/stable (`edhrec_trend_service.getCardTrends`) é série temporal: sem snapshot diário NUNCA há histórico e o sinal fica permanentemente "stable" (morto p/ recommendations). Incremental/idempotente. |
| `bin/cron_sync_combos.sh` | `sync_combos.dart` | semanal (seg 03:30) | `card_combos`/`combo_cards` consumidos em weakness-analysis (combos completos + near-miss). Base muda devagar; download pesado com cache 24h. |
| `bin/cron_sync_rulings.sh` | `sync_rulings.dart` | semanal (ter 03:30) | `card_rulings` (GET /cards/{id}/rulings). Cadência baixa (lançamentos/erratas). |
| `bin/cron_snapshot_price_history.sh` | `snapshot_price_history.dart` | diária (04:30) | Snapshot de preço do dia para `price_history`. Deve rodar **após** o sync de preços (04:00). |
| `bin/cron_sync_staples.sh` | `sync_staples.dart ALL` | semanal (seg 03:00) | `format_staples` alimenta pool de candidatos do optimize/completion. |

### 1.3 Crontab recomendado (consolidado)

```cron
# -- Diario --------------------------------------------------
0  3 * * *  /app/bin/cron_sync_cards.sh                >> /var/log/mtg_cards.log         2>&1
0  4 * * *  /app/bin/cron_sync_prices_mtgjson.sh       >> /var/log/mtg_prices.log        2>&1
30 4 * * *  /app/bin/cron_snapshot_price_history.sh    >> /var/log/mtg_price_history.log 2>&1
0  5 * * *  /app/bin/cron_snapshot_edhrec.sh           >> /var/log/mtg_edhrec.log        2>&1

# -- Semanal -------------------------------------------------
0  3 * * 1  /app/bin/cron_sync_staples.sh              >> /var/log/mtg_staples.log       2>&1
30 3 * * 1  /app/bin/cron_sync_combos.sh               >> /var/log/mtg_combos.log        2>&1
30 3 * * 2  /app/bin/cron_sync_rulings.sh              >> /var/log/mtg_rulings.log       2>&1
0  6 * * 0  /app/bin/cron_cleanup_optimize_telemetry.sh                                  >> /var/log/mtg_cleanup.log 2>&1
```

Ordenação intencional: preços (04:00) -> snapshot de preço (04:30) -> EDHREC (05:00).
Dentro do container (Easypanel/Docker), prefixar cada linha com
`docker exec -w /app <container> ` ou rodar o crontab DENTRO do container.

### 1.4 Pipelines de aprendizado que NÃO viraram cron (decisão consciente)

Estes recomputam/aplicam dados de aprendizado e têm modo `--dry-run`/`--apply`
+ artifacts de auditoria. **Não** foram agendados para auto-`--apply` porque
mudam sinais de scoring e devem passar por revisão. Recomenda-se rodar
**manualmente** (ou cron com revisão de artifact) após ingestão de novas cartas/meta:

- `bin/semantic_layer_v2_backfill.dart --apply` — backfill de `card_semantic_tags_v2` / `card_function_tags` (após `sync_cards` trazer cartas novas).
- `bin/candidate_quality_data_foundation.dart --apply` — fundação de qualidade de candidatos.
- `bin/candidate_quality_meta_signals.dart --apply` — sinais de meta para candidatos.
- `bin/ml_extract_features.dart` — extração de features (sob demanda, p/ treino).
- Pipeline de meta (`run_external_commander_meta_pipeline.dart`, `extract_meta_insights.dart`, etc.) — sob demanda.

> Cadência sugerida (se for automatizar com revisão): semanal, **após** o
> `sync_cards`/`sync_staples`, com inspeção dos artifacts antes de `--apply`.

---

## 2. Pendências de lógica (NÃO implementadas — backlog)

Itens identificados na auditoria de completude das lógicas/APIs. Apenas
documentados aqui; implementação pendente de priorização.

### P-A. Reconciliar combo heurístico <-> tabela real `card_combos`
- **Onde:** `lib/ai/optimization_functional_roles.dart` (`_knownComboPieceNames`,
  `_looksLikeComboPiece` -> papel `combo_piece`); `lib/ai/functional_card_tags.dart`
  (tag `combo_piece` heurística, confiança 0.72); `lib/ai/deck_advanced_analysis.dart`
  (`roles.contains('combo_piece') || oracleText.contains('infinite')`).
- **Problema:** a detecção heurística de `combo_piece` roda em paralelo à fonte
  real (`card_combos`/`combo_cards`, via `CommanderSpellbookService.findDeckCombos`,
  já usada em weakness-analysis). Heurística pode gerar falsos positivos/negativos.
- **Proposta:** elevar confiança quando a carta aparece em `combo_cards`;
  rebaixar `combo_piece` heurístico quando não houver combo real conhecido.
- **Risco:** toca scoring -> exige teste de regressão (similar ao contraste P1.a).

### P-B. Substituir `inferFunctionalRole` (heurístico, role único) por tags persistidas
- **Onde:** engine determinístico do optimize usa `inferFunctionalRole`
  (heurístico, devolve 1 papel) em vez do resolver multi-tag
  `resolveCardFunctionalRoles` (functional_tags -> semantic_v2 -> heurística).
- **Problema:** inconsistência com o restante do pipeline (validator/gate já
  usam a fonte única após P1.a/P1.b).
- **Risco:** mudança de scoring no caminho determinístico; validar com os
  testes de optimize e amostras reais antes de ativar.

### P-C. Tabelas write-only sem consumidor (anti-órfã)
Escritas mas nunca lidas — ou dar consumidor, ou descontinuar:
- `commander_reference_decks`
- `deck_matchups`
- `deck_weakness_reports`
- `ml_prompt_feedback`

### P-D. Fases 4-7 (lacunas de lógica restantes)
- Definição ainda aberta. `PLANO_CORRECAO.md` não existe mais no repo; o único
  plano correlato é `docs/hermes-analysis/F3_GARGALLO_PLAN.md` (refactor, não
  lógica). Necessário consolidar o escopo das fases 4-7 antes de executar.

---

## 3. Já concluído (contexto)

- **Fase 2A** combos (`card_combos`/`combo_cards`) — populado e consumido.
- **Fase 2B** rulings (`card_rulings`) + rota pública — populado.
- **Fase 2C** snapshots EDHREC + tendências — implementado (agora com cron diário).
- **Fase 3** análises avançadas (`deck_advanced_analysis.dart`) + integridade de
  swaps (`optimize_swap_integrity.dart`).
- **P1 drift do pipeline semântico** — resolvido:
  - P1.b: `optimizationFunctionalRolesForCard` delega à fonte única.
  - P1.a: SQL de additions e o quality gate agora consomem `functional_tags`
    persistidos (helper `functionalTagsSelectSql`, parser
    `_persistedFunctionalTagsForGate`, teste de contraste).
