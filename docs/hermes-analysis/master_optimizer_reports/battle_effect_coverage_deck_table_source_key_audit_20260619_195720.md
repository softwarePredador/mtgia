# Battle Effect Coverage Deck Table Source-Key Audit - 2026-06-19 19:57Z

## Escopo

Auditoria documental sobre o `effect_coverage.md` gerado pelo latest
`battle-strategy-audit`, com foco na consistencia entre a tabela humana
`Deck Coverage` e os dados estruturados em `effect_coverage.json`.

Nao houve alteracao de PostgreSQL, swaps, runtime battle ou regras de carta.

## Fontes

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage.md`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py`

Latest real usado:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_193733`
- `timestamp_utc=2026-06-19T19:37:33Z`
- `battle_replay_final_status=review_required`
- `mandatory_gate_divergences=["forensic_audit=review_required"]`

## Resultado

O JSON estruturado usa chaves atuais de fonte:

- `battle_rule_curated=724`
- `battle_rule_needs_review_generated=34`
- `effect_map=100`
- `focused_template_ready=33`
- `handcrafted=2`
- `tag=18`
- `type_land=377`

Porem a tabela humana `Deck Coverage` ainda renderiza colunas antigas:

- `Battle Manual` lendo `battle_rule_manual`
- `Battle Generated` lendo `battle_rule_generated`
- `Generated` lendo `generated`
- `Type Creature` lendo `type_creature`
- `Unknown` lendo `unknown`

No codigo atual, a renderizacao usa:

- `totals.get("battle_rule_manual", 0)`
- `totals.get("battle_rule_generated", 0)`

Essas chaves nao aparecem em `deck_totals` do latest. Resultado: o Markdown
mostra `0` em `Battle Manual` e `Battle Generated` para todos os decks, mesmo
quando o JSON tem cobertura por `battle_rule_curated` e
`battle_rule_needs_review_generated`.

## Divergencias por deck

| Deck | Markdown Battle Manual | Markdown Battle Generated | JSON battle_rule_curated | JSON battle_rule_needs_review_generated |
| --- | ---: | ---: | ---: | ---: |
| Akiri, Line-Slinger #30 (real) | 0 | 0 | 59 | 1 |
| Etali, Primal Conqueror #105 (real) | 0 | 0 | 60 | 2 |
| Gwen Stacy #65 (real) | 0 | 0 | 63 | 2 |
| Ishai, Ojutai Dragonspeaker #28 (real) | 0 | 0 | 60 | 3 |
| Kenrith, the Returned King #113 (real) | 0 | 0 | 63 | 3 |
| Kinnan, Bonder Prodigy #37 (real) | 0 | 0 | 60 | 1 |
| Kraum, Ludevic's Opus #50 (real) | 0 | 0 | 64 | 2 |
| Lorehold target deck | 0 | 0 | 67 | 0 |
| Lumra, Bellow of the Woods #49 (real) | 0 | 0 | 33 | 9 |
| Magda, Brazen Outlaw #71 (real) | 0 | 0 | 37 | 2 |
| Sisay, Weatherlight Captain #31 (real) | 0 | 0 | 67 | 0 |
| Urza, Lord High Artificer #87 (real) | 0 | 0 | 56 | 1 |
| Yorion, Sky Nomad #38 (real) | 0 | 0 | 35 | 8 |

Total ocultado no nivel humano por essas duas colunas:

- `battle_rule_curated + battle_rule_needs_review_generated = 758`

## Risco

Um leitor futuro pode concluir pelo `effect_coverage.md` que nenhum deck tem
cobertura de regras battle manuais/geradas, apesar do JSON mostrar centenas de
instancias `battle_rule_curated` e dezenas `battle_rule_needs_review_generated`.

Isso afeta principalmente:

- priorizacao de templates e regras;
- leitura de `needs_review`;
- resposta sobre "todos os templates de acoes de cartas";
- handoff para Codex/automacao que use o Markdown humano em vez do JSON.

## Ajustes recomendados

1. Atualizar `render_markdown(...)` em
   `battle_effect_coverage_audit.py` para renderizar as chaves atuais:
   `battle_rule_curated` e `battle_rule_needs_review_generated`.
2. Remover ou renomear colunas historicas que hoje sempre zeram:
   `Battle Manual`, `Battle Generated`, `Generated`, `Type Creature` e
   `Unknown`, ou deixar claro que so aparecem quando a chave existe no JSON.
3. Preferir colunas dinamicas a partir de `source_totals`/`deck_totals` para
   evitar novo drift de nomes.
4. Adicionar teste de fixture garantindo que a tabela `Deck Coverage` reconcilia
   com `effect_coverage.json.deck_totals` e nao perde fontes nao nulas.
5. Enquanto nao corrigir, handoffs devem usar `effect_coverage.json` para
   contagens por deck e tratar a tabela Markdown como apresentacao incompleta.

## Criterio de fechamento

- A tabela `Deck Coverage` mostra `battle_rule_curated=724` e
  `battle_rule_needs_review_generated=34` reconciliados por deck, ou renderiza
  dinamicamente todas as fontes presentes em `deck_totals`.
- Existe teste que falha quando uma fonte nao nula do JSON e omitida ou
  renomeada para coluna zerada no Markdown.
- Handoffs deixam de usar `Battle Manual=0` / `Battle Generated=0` como prova
  de ausencia de regra battle por deck.

## Validacoes executadas

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_residual_audit.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_unknown_template_backlog_audit.py` - PASS
- `git diff --check -- docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_deck_table_source_key_audit_20260619_195720.md` - PASS
- ASCII check do novo relatorio - PASS
