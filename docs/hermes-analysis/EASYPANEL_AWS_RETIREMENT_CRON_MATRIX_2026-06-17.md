# EasyPanel AWS Retirement Cron Matrix — 2026-06-17

## Objetivo

Fechar a matriz final de cutover para desligar a AWS sem manter crons
duplicadas, jobs zumbis ou fonte de verdade ambígua.

Regra operacional:

- `manaloom-ops` fica com tudo que é determinístico, backend-owned e relevante
  para o produto.
- `hermes-lab` fica com chat, docs branch e research provider-gated.
- jobs Lorehold legadas e validadores antigos não entram no caminho crítico do
  produto.

## Matriz final

| Job histórico | Estado final | Destino canônico | Motivo |
| --- | --- | --- | --- |
| `pull_learning_events` / `manaloom-pull-learning-events` | manter | `manaloom-ops` | ingere eventos reais do backend e alimenta aprendizado seguro |
| `auto_sync_learned_decks` / `manaloom-auto-sync-learned-decks` | manter | `manaloom-ops` | materializa learned decks aprovados para consumo real |
| `auto_promote_learned_decks` / `manaloom-auto-promote-learned` | manter | `manaloom-ops` | promoção segura/idempotente sem provider |
| `master_optimizer_preflight` / `manaloom-master-optimizer-preflight` | manter | `manaloom-ops` | garante snapshot/meta/rules/readiness do optimizer |
| `manaloom_knowledge_import` / `manaloom-knowledge-import` | migrar e manter | `manaloom-ops` | importa conhecimento curado do repositório para tabelas PG usadas pelo backend |
| `hermes_mana_base_validator` / `manaloom-mana-base-validator` | manter | `manaloom-ops` | valida integridade de mana e seeds sem provider |
| `hermes_cron_governor_report` / `manaloom-cron-governor-report` | manter | `manaloom-ops` | observabilidade determinística da frota ativa |
| `manaloom-docs-branch-sync` | manter | `hermes-lab` | garante que auditorias na branch docs não leiam código stale |
| `manaloom-commander-knowledge-deep` | manter gated | `hermes-lab` | research pontual, dependente de delta e provider |
| `manaloom-gamechanger-research` | manter gated | `hermes-lab` | research pontual, dependente de delta e provider |
| `manaloom-knowledge-synthesis` | manter gated | `hermes-lab` | transforma achados em tasks, mas só quando há delta real |
| `mtg-rules-auditor` | manter gated | `hermes-lab` | auditoria de regras/battle, não runtime de produto |
| `manaloom-hermes-normal-audit` | pausado | `hermes-lab` manual/report-only | duplicava o pós-push controlado pelo Codex |
| `manaloom-hermes-weekly-parallel-audit` | pausado | `hermes-lab` manual | amplo demais para recorrência econômica |
| `manaloom-tag-accuracy-reporter` | pausado | backlog determinístico | necessidade real, implementação agent ainda ineficiente |
| `manaloom-code-structure-auditor` | pausado | manual | auditoria ampla, sem valor recorrente |
| `manaloom-logic-coherence-auditor` | pausado | manual | boa para rodadas dirigidas, ruim em loop |
| `manaloom-master-optimizer-slot-scan` | pausado | manual | job pesado de prova controlada |
| `manaloom-master-optimizer-end-to-end` | pausado | manual | job pesado de prova controlada |
| `manaloom-manager-watchdog` | remover | nenhum | já substituído |
| `manaloom-master-watchdog` | remover | nenhum | dependência operacional antiga da AWS; hoje o cutover usa deploy controlado + governor |
| `manaloom-flutter-ui-auditor` | remover | nenhum | Linux Hermes não prova runtime real mobile |
| `manaloom-master-optimizer-loop` | remover | nenhum | one-shot legado |
| `lorehold-knowncards-validator` | remover do cron | nenhum runtime crítico | battle atual usa `card_battle_rules` + `known_cards_canonical_snapshot`, não esse cron legado |
| `lorehold-knowncards-generator` | remover | nenhum | superado pelo snapshot canônico |
| família `lorehold-*` antiga (`deck-scout`, `deck-validator`, `oracle`, `mulligan`, `wincon-*`) | remover | nenhum cron ativo | laboratório antigo substituído por learned decks, preflight, battle audit e research gated |

## Decisão sobre `known_cards`

`known_cards_generated.json` não é mais fonte principal do runtime de battle.
O caminho atual é:

1. `card_battle_rules` no PostgreSQL;
2. cache SQLite `battle_card_rules`;
3. `known_cards_canonical_snapshot.json` como fallback degradado;
4. heurísticas/`unknown` auditável.

Consequência prática:

- `lorehold-knowncards-validator` deixa de ser requisito para produção;
- ele pode continuar existindo como ferramenta de laboratório, mas não como job
  necessária para desligar a AWS.

## Decisão sobre `knowledge-import`

`knowledge-import` continua valioso porque popula/atualiza:

- `theme_contextual_rules`;
- `commander_reference_profiles`;
- `card_deck_profiles`;
- `analysis_sources`.

Essas tabelas são PostgreSQL/backend-owned e já têm consumidores reais no
backend. Por isso o job foi promovido para o worker determinístico
`manaloom-ops`, usando `run_import.py` em modo `apply`.

## Critério para desligar a AWS

A AWS pode ser aposentada quando:

1. `manaloom-ops` estiver rodando com:
   - `pull_learning_events`
   - `auto_sync_learned_decks`
   - `auto_promote_learned_decks`
   - `master_optimizer_preflight`
   - `manaloom_knowledge_import`
   - `hermes_mana_base_validator`
   - `hermes_cron_governor_report`
2. `hermes-lab` no Easy estiver saudável, com bootstrap report válido e só a
   frota reduzida de research/docs.
3. nenhum job legado crítico da AWS continuar sendo a única fonte de atualização
   de dados do produto.
