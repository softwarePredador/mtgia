# Battle Recent Forensic Functional Tag Blocker Audit - 2026-06-19 20:27Z

## Escopo

Auditoria documental do blocker forensic observado no run completo
`20260619_202217`. Nao houve alteracao de PostgreSQL, swaps, runtime battle,
wrapper, regras de carta ou commit.

## Fontes

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_202217/seed_63202036/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_202217/seed_63202036/forensic_audit.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_202217/seed_63202036/action_critic.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_202217/seed_63202036/strategy_audit.json`

## Run usado

- Run real: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_202217`
- `timestamp_utc=2026-06-19T20:22:17Z`
- `battle_replay_final_status=blocked`
- `mandatory_gate_divergences=["forensic_audit=blocked"]`
- `action_findings=0`
- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_strategy_blockers=[]`
- `seeds_with_high_or_critical_forensic_findings=["63202036"]`

Observacao: depois da coleta, o run `20260619_202628` virou o latest completo e
passou todos os mandatory gates. Este relatorio permanece como evidencia de um
blocker real observado em seed recente, nao como status latest atual.

## Resultado

A seed `63202036` bloqueia o forensic gate:

| Campo | Valor |
| --- | ---: |
| `forensic_rule_findings` | 4 |
| `critical` | 0 |
| `high` | 1 |
| `medium` | 1 |
| `low` | 2 |
| `card_id_missing_unaccepted` | 2 |
| `semantic_hash_missing_unaccepted` | 2 |
| `rule_logical_key_missing_unaccepted` | 0 |
| `by_source.functional_tags_json` | 2 |
| `by_status.heuristic` | 2 |

Findings principais:

| Severity | Seed | Turn | Event | Card | Effect | Finding |
| --- | --- | ---: | --- | --- | --- | --- |
| high | `63202036` | 9 | `spell_resolved` | `Neoform` | `tutor` | Game event depended on heuristic source `functional_tags_json`. |
| medium | `63202036` | 9 | `spell_cast` | `Neoform` | `tutor` | Game event depended on heuristic source `functional_tags_json`. |
| low | `63202036` | 9 | `spell_cast` | `Neoform` | `tutor` | Runtime effect `tutor` differs from registry effect `draw_cards`. |
| low | `63202036` | 9 | `spell_resolved` | `Neoform` | `tutor` | Runtime effect `tutor` differs from registry effect `draw_cards`. |

Lineage unaccepted samples:

- `Neoform` `spell_cast` missing `card_id`, source `functional_tags_json`
- `Neoform` `spell_cast` missing `semantic_hash`, source `functional_tags_json`
- `Neoform` `spell_resolved` missing `card_id`, source `functional_tags_json`
- `Neoform` `spell_resolved` missing `semantic_hash`, source `functional_tags_json`

## Cruzamento com action e strategy

Na mesma seed:

- `action_critic` passa: `findings=0`, `verdict_counts={"ok":419}`.
- `strategy_audit` passa como `high_confidence_replay`, com
  `verdict=usable_for_strategy_learning`.

Isso reforca a necessidade de usar o final status e todos os mandatory gates: a
seed parece limpa para action e strategy, mas nao e learning-grade porque o
forensic gate bloqueia.

## Leitura operacional

Este blocker e a mesma classe raiz de `BV-067`: evento de carta executado por
fallback heuristico `functional_tags_json`, sem identidade PostgreSQL/card
lineage suficiente, e sem regra `card_battle_rules` verified/active que possa
ser tratada como comportamento card-specific confiavel.

A diferenca operacional deste run e a severidade: antes o register
documentava o caminho como `review_required` por findings medium; agora o latest
tem `forensic_audit=blocked` por finding high em `Neoform`.

## Ajustes recomendados

1. Promover `Neoform` para uma regra `card_battle_rules` verified/active com
   comportamento e lineage revisados, ou bloquear/rebaixar esse caminho para
   non-learning ate existir regra.
2. Impedir que `functional_tags_json` gere `spell_cast`/`spell_resolved`
   learning-grade sem `card_id`, `semantic_hash` e regra card-specific.
3. Atualizar o summary para expor cards afetados por `functional_tags_json` e
   separar `forensic blocked` de `action/strategy clean`.
4. Adicionar fixture de regressao para uma seed em que action/strategy passam,
   mas forensic bloqueia por `functional_tags_json`, impedindo aprendizado.

## Criterio de fechamento

- Latest sem `forensic_audit=blocked` ou `review_required` por
  `functional_tags_json`;
- zero samples unaccepted de `functional_tags_json` sem `card_id` ou
  `semantic_hash`;
- `Neoform` resolvido por regra battle verified/active, waiver formal ou caminho
  explicitamente non-learning.

## Validacoes executadas

- Parse de `summary.json` do latest `20260619_202217`.
- Parse de `seed_63202036/forensic_audit.json`.
- Leitura de `seed_63202036/forensic_audit.md`.
- Parse de `seed_63202036/action_critic.json`.
- Parse de `seed_63202036/strategy_audit.json`.
