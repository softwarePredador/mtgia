# Data And Cron Health Audit — 2026-06-16

> Escopo: validar se os dados do ManaLoom estao sendo preenchidos corretamente
> e se as crons locais/Hermes AWS estao melhorando os dados necessarios em cada
> etapa. Esta auditoria e read-only, exceto pela criacao idempotente da tabela
> SQLite `deck_promotions` durante dry-run remoto do auto-promote.

## Resumo executivo

- Deploy publico esta saudavel e alinhado ao `master`:
  `93f5ac26c9824e18430ac97584665037eb1b682f`.
- PostgreSQL esta coerente para seguir: `25/25` migracoes aplicadas, `72`
  relacoes publicas e as quatro views criticas presentes.
- As views agregadas estao cumprindo o papel anti-fanout:
  `deck_cards -> card_intelligence_snapshot` gerou `0` linhas extras.
- O risco real continua sendo join direto de deck com fonte multi-linha:
  `deck_cards -> card_battle_rules` teria `448` linhas extras em `35.992`
  deck-card rows.
- Candidate Quality esta melhorando a base: o dry-run escaneou `33.839` cartas,
  planejou `54.417` role scores e usou `4.183` cartas com sinal EDHREC.
- Meta signals tambem agregam valor e foram aplicados em janela controlada:
  `385` meta decks escaneados, `363` com identidade resolvida, `2.796`
  commander signal rows aplicadas e `1.173` role score rows aplicados.
- Hermes AWS esta operacional com `25` jobs cadastrados e `13` habilitados.
  `12/13` jobs habilitados estavam `ok`; o unico erro observado
  (`manaloom-auto-promote-learned`) foi revalidado por dry-run e nao quebrou.
- O auto-promote esta funcional, mas atualmente promove `0` decks porque
  encontrou `56` candidatos sem target deck correspondente no SQLite Hermes.
- Crons locais do macOS estao carregadas (`battle-strategy`, `card-semantics`,
  `structure`, `weekend-learning`), mas `weekend-learning` tem logs antigos com
  erro de `timeout`; o script atual ja possui fallback portavel.

## Fontes e comandos usados

- `dart run bin/migrate.dart --status`
- `curl https://evolution-cartinhas.8ktevp.easypanel.host/health`
- `dart run bin/audit_data_model_links.dart`
- `dart run bin/candidate_quality_data_foundation.dart --dry-run`
- `dart run bin/candidate_quality_meta_signals.dart --dry-run`
- Logs locais em `/Users/desenvolvimentomobile/.manaloom-agents/logs`
- SSH read-only no Hermes AWS para `/opt/data/cron/jobs.json`
- Dry-run remoto: `HERMES_AUTO_PROMOTE_DRY_RUN=1 python3 /opt/data/scripts/auto_promote_learned_decks.py`

Artefatos gerados nesta rodada:

- `server/test/artifacts/data_model_health_2026-06-16/data_model_links.json`
- `server/test/artifacts/data_model_health_2026-06-16/data_model_links.md`
- `server/test/artifacts/data_model_health_2026-06-16/candidate_quality_meta_signals/`
- `server/test/artifacts/data_model_health_2026-06-16/candidate_quality_meta_signals_apply/`
- `server/test/artifacts/data_model_health_2026-06-16/candidate_quality_meta_signals_post_apply/`

## Estado PostgreSQL

### Migracoes e deploy

- Migracoes: `25` totais, `25` executadas, `0` pendentes.
- Health publico: `healthy`.
- Git SHA publico: `93f5ac26c9824e18430ac97584665037eb1b682f`.

### Row counts criticos

| Tabela | Linhas | Diagnostico |
|---|---:|---|
| `users` | 1.083 | Base viva, crescendo. |
| `cards` | 34.329 | Catalogo base. |
| `sets` | 951 | Catalogo de sets preenchido. |
| `card_legalities` | 324.538 | Forte para Commander/legalidade. |
| `card_localized_names` | 251.107 | Forte para import PT/outros idiomas. |
| `card_function_tags` | 112.563 | Multi-tag correto e util para analise/optimize. |
| `card_role_scores` | 46.598 | Base de ranking por papel ja materializada. |
| `card_semantic_tags_v2` | 24.181 | Sinal semantico parcial, ainda complementar. |
| `card_battle_rules` | 3.158 | Regras criticas, nao cobertura global. |
| `decks` | 1.337 | Decks de produto. |
| `deck_cards` | 50.841 | Linhas de deck persistidas. |
| `commander_learned_decks` | 61 | Learned decks backend-owned. |
| `deck_learning_events` | 107 | Eventos de aprendizado. |
| `commander_card_usage` | 912 | Ainda pequeno e parcialmente name-based. |
| `commander_card_synergy` | 7.796 | Sinal util para aprendizado/optimize. |
| `meta_decks` | 653 | Corpus externo/metagame. |
| `ai_logs` | 1.102 | Telemetria AI preenchida. |
| `ai_generate_jobs` | 4 | Baixo volume. |
| `ai_optimize_jobs` | 0 | Sem jobs pendentes/ativos no momento da auditoria. |
| `ml_prompt_feedback` | 3 | Muito pouco para aprendizado estatistico. |

## Views e anti-fanout

Views criticas presentes e compiladas em rollback:

| View | Linhas | Status |
|---|---:|---|
| `card_identity_bridge` | 305.905 | OK |
| `card_intelligence_snapshot` | 34.329 | OK |
| `commander_learning_snapshot` | 106 | OK |
| `optimize_candidate_quality_summary` | 34.329 | OK |

Fanout validado:

| Join | Rows | Distintos | Extra | Diagnostico |
|---|---:|---:|---:|---|
| `deck_cards -> card_intelligence_snapshot` | 50.841 | 50.841 | 0 | Correto. |
| `deck_cards -> card_battle_rules` direto | 36.440 | 35.992 | 448 | Proibido para fluxos de deck. |

Leitura correta:

- `cards_with_multiple_battle_rules = 10` e
  `cards_with_multiple_function_tags = 22.675` nao sao erro.
- O erro seria transformar cada funcao/regra em linha de deck.
- Consumidores de deck devem passar por snapshot/agregacao por `card_id`.

## Candidate Quality e sinais semanticos

### Foundation dry-run

| Metrica | Valor |
|---|---:|
| Cartas escaneadas | 33.839 |
| Cartas com sinal EDHREC | 4.183 |
| Tags planejadas | 69.158 |
| Role scores planejados | 54.417 |
| Synergy rows planejadas | 5.000 |
| Penalty rows planejadas | 481 |
| Cobertura de function tags | 74,086% |

Stale antes de apply:

| Fonte | Rows stale |
|---|---:|
| `card_function_tags` | 69 |
| `card_role_scores` | 3.263 |
| `commander_card_synergy` | 195 |
| `optimize_rejection_penalties` | 0 |

Diagnostico:

- A cron/foundation esta agregando dados reais.
- O apply controlado foi feito somente para `candidate_quality_meta_signals`,
  porque o stale era pequeno e source-isolado.
- `candidate_quality_data_foundation --apply` ainda nao deve rodar sem revisar
  o prune stale, porque ha `3.263` role scores antigos para remover/substituir.

### Meta signals apply controlado

| Metrica | Valor |
|---|---:|
| Meta decks escaneados | 385 |
| Candidatos externos confiaveis escaneados | 9 |
| Decks com identidade resolvida | 363 |
| Decks com identidade desconhecida | 31 |
| Commander signal rows aplicadas | 2.796 |
| Role score rows aplicados | 1.173 |
| Stale `commander_card_synergy` removido | 14 |
| Stale `card_role_scores` removido | 14 |

Efeito no banco:

| Tabela | Antes | Depois |
|---|---:|---:|
| `commander_card_synergy` | 7.179 | 7.796 |
| `card_role_scores` | 46.335 | 46.598 |

Dry-run pos-apply:

| Fonte | Rows stale |
|---|---:|
| `commander_card_synergy` | 0 |
| `card_role_scores` | 0 |

Guardrails confirmados:

- Dry-run e o default.
- Apply exige `--apply` explicito.
- Linhas so entram com `source=aggressive_meta_signal_v1`.
- Candidatos precisam respeitar legalidade Commander e subset de identidade de
  cor.
- Identidade desconhecida e reportada, nao persistida.
- Sinais sao advisory candidate pools, nunca swaps forcados.

Gap real:

- Resolver os `31` commander labels desconhecidos antes de tratar esses sinais
  como cobertura completa. Exemplos reportados: `Kefka, Court Mage`,
  `Ral, Monsoon Mage`, `Terra, Magical Adept`, `Brigid, Clachan's Heart` e
  `Etali, Primal Conqueror`.

## Hermes AWS

Estado vivo:

- Container: `hermes_agent` ativo ha 8 dias.
- Jobs cadastrados: `25`.
- Jobs habilitados: `13`.
- Jobs pausados: `12`.

Crons habilitadas observadas:

| Cron | Cadencia | Ultimo status | Valor real |
|---|---:|---|---|
| `manaloom-master-watchdog` | 30m | ok | Detecta push/alteracao em `master`. |
| `manaloom-pull-learning-events` | 30m | ok | Alimenta aprendizado com eventos reais. |
| `lorehold-knowncards-validator` | 30m | ok | Valida knowledge/battle do Lorehold. |
| `manaloom-master-optimizer-preflight` | 60m | ok | Preflight antes de optimizer. |
| `manaloom-knowledge-import` | 120m | ok | Importa conhecimento Hermes. |
| `manaloom-auto-sync-learned-decks` | 120m | ok | Sincroniza learned decks aprovados. |
| `manaloom-auto-promote-learned` | 360m | erro antigo; dry-run atual ok | Promove decks elegiveis, mas hoje nao encontrou target deck. |
| `manaloom-commander-knowledge-deep` | 360m | ok | Extrai padroes por comandante. |
| `manaloom-knowledge-synthesis` | 360m | ok | Converte achados em tarefas triaveis. |
| `manaloom-gamechanger-research` | 720m | ok | Pesquisa gaps de categorias especiais. |
| `manaloom-mana-base-validator` | 720m | ok | Valida base de mana de corpus/decks. |
| `mtg-rules-auditor` | 720m | ok | Guardrail de regras MTG. |
| `manaloom-cron-governor-report` | 720m | ok | Saude da frota de crons. |

### Auto-promote learned decks

Achado:

- `jobs.json` ainda carregava erro antigo:
  `sqlite3.OperationalError: no such table: deck_promotions`.

Revalidacao:

- Dry-run remoto rodou com sucesso.
- `deck_promotions_exists = true`.
- `deck_promotions_rows = 0`.
- Resultado: `promoted=0 skipped=56 unverified=0`.
- Todos os skips observados foram `no_target_deck`.

Conclusao:

- A falha de schema esta corrigida no runtime atual.
- O job ainda nao melhora dados de produto nesta rodada porque nao ha target
  deck correspondente no SQLite Hermes para os 56 candidatos.
- Proximo ajuste util e sincronizar/materializar target decks esperados antes do
  auto-promote, ou alterar a politica para promover somente quando o backend
  tiver alvo explicito.

## Crons locais do macOS

LaunchAgents carregados:

- `com.manaloom.battle-strategy-audit`
- `com.manaloom.battle-strategy-nightly`
- `com.manaloom.card-semantics-audit`
- `com.manaloom.structure-audit`
- `com.manaloom.weekend-learning`

### Battle strategy audit

Ultima rodada analisada:

- Seeds: `16/16`.
- Decisoes: `2.276`.
- Eventos: `17.324`.
- High/critical action findings: `0`.
- Strategy blockers: `0`.
- Strategy findings: `5 medium`.

Codigos restantes:

- `board_wipe_without_timing_justification`: 1.
- `forced_keep_after_bad_mulligan`: 2.
- `wheel_opponent_refill_risk`: 2.

Diagnostico:

- A cron esta melhorando confianca do battle por replay.
- O problema restante e estrategia de decisao, nao legalidade basica.

### Card semantics audit

Resultado recente:

- Confirmou que optimize/validator/quality gate ja carregam ou preservam
  `functional_tags` e `semantic_tags_v2`.
- Mantem riscos reais para fallbacks por nome, prompts runtime, advisory routes,
  replacement ranking, candidate-quality foundation e analysis auxiliares.

Diagnostico:

- A cron agrega valor como auditoria documental/semantica.
- Nao deve aplicar mudanca automatica; achados seguem para triagem.

### Structure audit

Resultado recente:

- Auditor textual: `205` arquivos backend, `196` classes, `0` imports quebrados.
- Mantem candidatos app de baixo risco sem uso runtime confirmado:
  `LifeCounterScreen`, `DeckCard`, `DeckProgressChip`, `LotusPresentationMode`.

Diagnostico:

- Agrega para limpeza controlada, mas nao melhora diretamente dados de IA/battle.

### Weekend learning

Logs antigos:

- Varios erros `timeout: command not found`.

Estado atual:

- O script possui wrapper `run_with_timeout` com fallback para `timeout`,
  `gtimeout` ou watchdog manual.
- Dry-run de 2026-06-16 passou.

Diagnostico:

- Nao ha evidencia de aprendizado completo recente produzido por este job no
  macOS; ele ainda deve ser tratado como auditoria complementar, nao como fonte
  de dados de produto.

## Diagnostico por etapa do produto

| Etapa | Dados preenchidos? | Cron melhora? | Status |
|---|---|---|---|
| Catalogo/cartas | Sim: `cards`, `sets`, `legalities`, `localized_names`. | Sim, por sync/backfills controlados. | Forte. |
| Import localizado | Sim: `card_localized_names` forte. | Indireto. | Forte, ainda ha lacuna de cobertura. |
| Deck save/import | Sim: `decks`, `deck_cards`, validadores. | Nao depende de cron. | Forte. |
| Deck analysis | Sim: `card_intelligence_snapshot`, tags e scores. | Sim: candidate quality. | Forte se usar snapshot. |
| Optimize/generate | Parcial: tags/scores existem, feedback ainda pequeno. | Sim, meta-signal ja aplicado; foundation maior segue pendente. | Bom, mas medir scorecard pos-apply. |
| Learned decks | Parcial: PG tem 61, SQLite tem corpus maior. | Sim, mas auto-promote nao promove sem target deck. | Util, com gap operacional. |
| Battle simulator | Parcial: battle rules 9,16% global, alta precisao em cartas criticas. | Sim: strategy audit e rules auditor. | Bom para replay controlado, nao judge engine completo. |
| Decision trace/statistics | Parcial. | Sim via auditorias recentes. | Ainda precisa mais amostra e metricas com/sem carta. |
| UX/layout | Fora do banco. | Crons locais ajudam como auditoria, nao como runtime proof. | Separado de dados. |

## O que precisa ser corrigido agora

### P0 — Manter joins multi-linha atras de snapshot

Motivo: join direto com `card_battle_rules` multiplica linhas.

Acao:

- Continuar usando `card_intelligence_snapshot` e
  `optimize_candidate_quality_summary`.
- Qualquer novo consumidor deve provar `extra_rows=0` em fanout check.

### P1 — Medir scorecard pos-apply de meta signals

Motivo: `candidate_quality_meta_signals --apply` foi executado e precisa ser
medido contra optimize/generate antes de qualquer novo apply maior.

Acao:

- Rodar scorecard optimize/generate focado em Commander.
- Confirmar que os novos `aggressive_meta_signal_v1` rows melhoram candidatos
  sem aumentar false positives.

### P1 — Planejar apply controlado de candidate quality foundation

Motivo: dry-run mostra ganho real, mas ha stale prune significativo.

Acao:

- Revisar amostra das `3.263` `card_role_scores` stale.
- Rodar `candidate_quality_data_foundation --apply` somente com janela e
  rollback/log.

### P1 — Resolver target deck do auto-promote

Motivo: `auto-promote` esta funcional, mas `56` candidatos foram ignorados por
`no_target_deck`.

Acao:

- Decidir se o auto-promote deve:
  1. materializar target decks no SQLite Hermes antes da promocao; ou
  2. promover somente learned decks com target deck backend explicito; ou
  3. virar report-only ate o backend job existir.

Recomendacao: usar a opcao 2 para estabilidade.

### P1 — Fechar identidades desconhecidas do meta-signal

Motivo: `31` meta decks com commander identity desconhecida nao persistem sinais.

Acao:

- Resolver DFC/novos nomes via `card_identity_bridge`, Scryfall/MTGJSON sync ou
  mapping conservador.
- Nao forcar sinais sem identidade resolvida.

### P2 — Ampliar metricas de decision impact

Motivo: battle/optimizer ainda nao devem confiar em WR bruto.

Acao:

- Adicionar com/sem carta vista, carta castada, delta contra baseline,
  sample_size, baseline_hash e arquétipo de oponente nos relatórios Hermes.

### P2 — Separar crons que alimentam dados de crons que so auditam

Motivo: nem toda cron melhora dados do produto diretamente.

Acao:

- Marcar como data-producing: `pull-learning-events`,
  `auto-sync-learned-decks`, `auto-promote-learned`, `knowledge-import`,
  `master-optimizer-preflight`.
- Marcar como report-only: `battle-strategy-audit`, `structure-audit`,
  `card-semantics-audit`, `knowledge-synthesis`, `rules-auditor`.

## Conclusao

Os dados principais estao sendo preenchidos corretamente e as camadas novas de
agregacao estao protegendo contra o principal bug de modelo: fanout por fontes
multi-linha. As crons estao melhorando o projeto em duas frentes:

1. Alimentacao real de dados: learning events, learned decks, candidate quality,
   meta signals e preflight.
2. Auditoria/qualidade: battle strategy, semantics, structure e rules.

O sistema ainda nao esta em estado "autoaprendizado 100% fechado". O apply
controlado de meta signals foi concluido, mas os bloqueios reais restantes sao:
medir scorecard pos-apply, aplicar a foundation maior com rollback controlado,
resolver target decks do auto-promote e substituir WR bruto por metricas de
impacto por decisao/carta.
