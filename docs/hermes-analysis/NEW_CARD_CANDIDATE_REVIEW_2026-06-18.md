# New Card Candidate Review — Rotina Geral De Autoaprendizado

Data: 2026-06-18

## Status

Implementado como rotina determinística `manaloom_new_card_candidate_review`,
executada pelo `manaloom-ops`.

Contrato:

- **Sem LLM**.
- **Sem auto-apply**.
- **Sem alteração em decks**.
- **Sem writes em PostgreSQL**.
- PostgreSQL/backend continua como fonte de verdade.
- SQLite do `manaloom-ops` guarda apenas histórico operacional, fila de revisão
  e checkpoint.
- Lorehold é caso de controle, não escopo exclusivo.

## Arquivos

- `server/bin/manaloom_new_card_candidate_review.py`
- `server/bin/manaloom_new_card_candidate_review.sh`
- `server/bin/manaloom_ops_daemon.py`
- `server/test/manaloom_new_card_candidate_review_test.py`

## Cron

Job registrado:

```text
name=manaloom_new_card_candidate_review
schedule=35 */6 * * *
env override=MANALOOM_NEW_CARD_CANDIDATE_REVIEW_CRON
```

Wrapper:

```bash
./server/bin/manaloom_new_card_candidate_review.sh
```

Artefatos padrão no EasyPanel/manaloom-ops:

```text
/data/manaloom-ops/artifacts/new_card_candidate_review/
```

SQLite operacional:

```text
/data/manaloom-ops/knowledge.db
```

## Entrada

Fonte preferencial:

- `card_intelligence_snapshot`

Fallback:

- `cards`
- `card_legalities`
- heurística local de papel funcional a partir de `oracle_text` e `type_line`

Comandantes-alvo:

- `commander_learned_decks` ativos;
- `commander_card_usage` com uso suficiente;
- comandantes forçados via `--force-commander`;
- `Lorehold, the Historian` como controle padrão, a menos que
  `--no-lorehold-control` seja usado.

Sets padrão da primeira rotina:

```text
msh,msc,mar
```

Isso cobre o controle operacional de cartas Marvel, mas o job aceita qualquer
lista de sets via `--sets` ou `MANALOOM_NEW_CARD_REVIEW_SETS`.

## Saída

Por rodada:

- `latest_summary.json`
- `latest_reviews.json`
- `latest_report.md`
- diretório por `run_id`

No SQLite:

- `new_card_candidate_review_runs`
- `new_card_candidate_reviews`
- `new_card_battle_rule_review_queue`
- `new_card_candidate_review_checkpoints`

Essas tabelas são cache/evidência operacional. Não são fonte final do produto.

## Decisões

Cada carta/comandante recebe uma decisão:

- `test`: candidata plausível para scorecard futuro.
- `backlog`: sinal plausível, mas insuficiente para teste agora.
- `needs_rule_review`: candidata depende de regra battle ausente ou ainda não
  confiável.
- `needs_data`: falta oracle, legalidade Commander ou dado mínimo.
- `already_present`: já existe no deck/perfil pelo `oracle_id` ou nome.
- `ignore`: fora de identidade, não Commander legal ou irrelevante.

## Regras De Segurança

- Carta fora da identidade do comandante vira `ignore`.
- Carta já presente vira `already_present`.
- Carta sem oracle/legalidade vira `needs_data`.
- Carta com papel forte e sem regra battle confiável vira
  `needs_rule_review`.
- Múltiplos papéis são preservados como arrays; o pipeline não colapsa carta
  multi-função para um único papel.
- `card_battle_rules` é consumida via `card_intelligence_snapshot`, que agrega
  por `card_id`, evitando fanout.

## Quando Acordar Hermes Lab

`manaloom-ops` continua barato e determinístico. O `hermes-lab` só precisa ser
acionado quando o relatório indicar:

- novos candidatos `test`;
- muitas cartas `needs_rule_review`;
- divergência material entre tags, regras battle e candidate quality.

O script já expõe:

```json
{
  "hermes_lab_should_wake": true,
  "hermes_wake_reasons": []
}
```

## Validação Executada

```bash
python3 -m py_compile \
  server/bin/manaloom_new_card_candidate_review.py \
  server/bin/manaloom_ops_daemon.py \
  server/test/manaloom_new_card_candidate_review_test.py

bash -n server/bin/manaloom_new_card_candidate_review.sh

python3 server/test/manaloom_new_card_candidate_review_test.py
```

Dry-run real read-only contra PostgreSQL configurado:

```bash
MANALOOM_OPS_ARTIFACT_DIR="$(mktemp -d)/artifacts" \
MANALOOM_KNOWLEDGE_DB="$(mktemp -d)/knowledge.db" \
python3 server/bin/manaloom_new_card_candidate_review.py \
  --sets msh,msc,mar \
  --commander-limit 8 \
  --card-limit 120
```

Resultado observado:

```json
{
  "cards_scanned": 120,
  "commanders_scanned": 8,
  "decisions": {
    "ignore": 657,
    "needs_data": 303
  },
  "hermes_lab_should_wake": false
}
```

Interpretação: o catálogo recente já é visível, mas parte relevante ainda
precisa de dados completos de legalidade/oracle/tags antes de virar candidato
real. Isso é uma pendência de dados, não motivo para aplicar swap automático.

## Próximos Passos

1. Rodar a rotina no `manaloom-ops` após deploy e verificar
   `latest_report.md`.
2. Se o volume de `needs_data` em `msh/msc/mar` continuar alto, priorizar sync
   de legalidades/oracle/tags desses sets.
3. Se surgirem candidatos `test`, rodar scorecard/battle específico antes de
   qualquer recomendação para geração ou optimize.
4. Se surgirem muitos `needs_rule_review`, criar lote de revisão em
   `card_battle_rules` no PostgreSQL e sincronizar para Hermes SQLite.
