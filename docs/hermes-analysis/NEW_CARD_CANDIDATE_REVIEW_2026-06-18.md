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
- `server/bin/manaloom_card_data_gap_review.py`
- `server/bin/manaloom_card_data_gap_review.sh`
- `server/bin/manaloom_battle_rule_review_queue.py`
- `server/bin/manaloom_battle_rule_review_queue.sh`
- `server/bin/manaloom_battle_rule_focused_evidence.py`
- `server/bin/manaloom_battle_rule_focused_evidence.sh`
- `server/bin/manaloom_battle_rule_promotion_gate.py`
- `server/bin/manaloom_battle_rule_promotion_gate.sh`
- `server/bin/sync_card_legalities_from_scryfall.py`
- `server/bin/manaloom_ops_daemon.py`
- `server/test/manaloom_new_card_candidate_review_test.py`
- `server/test/manaloom_review_queue_consumers_test.py`
- `server/test/sync_card_legalities_from_scryfall_test.py`

## Cron

Job registrado:

```text
name=manaloom_new_card_candidate_review
schedule=35 */6 * * *
env override=MANALOOM_NEW_CARD_CANDIDATE_REVIEW_CRON
```

Consumers registrados:

```text
name=manaloom_sync_card_legalities_from_scryfall
schedule=30 */6 * * *
env override=MANALOOM_SYNC_CARD_LEGALITIES_CRON

name=manaloom_card_data_gap_review
schedule=50 */6 * * *
env override=MANALOOM_CARD_DATA_GAP_REVIEW_CRON

name=manaloom_battle_rule_review_queue
schedule=55 */6 * * *
env override=MANALOOM_BATTLE_RULE_REVIEW_QUEUE_CRON

name=manaloom_battle_rule_focused_evidence
schedule=56 */6 * * *
env override=MANALOOM_BATTLE_RULE_FOCUSED_EVIDENCE_CRON

name=manaloom_battle_rule_promotion_gate
schedule=58 */6 * * *
env override=MANALOOM_BATTLE_RULE_PROMOTION_GATE_CRON
```

Wrapper:

```bash
./server/bin/manaloom_new_card_candidate_review.sh
./server/bin/sync_card_legalities_from_scryfall.sh
./server/bin/manaloom_battle_rule_focused_evidence.sh
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

## Escopos De Varredura

O runner agora aceita escopo explícito:

```bash
./server/bin/manaloom_new_card_candidate_review.sh --scope sets
./server/bin/manaloom_new_card_candidate_review.sh --scope lookback
./server/bin/manaloom_new_card_candidate_review.sh --scope full --card-limit 0
```

Contrato por escopo:

- `sets`: avalia apenas os sets configurados em
  `MANALOOM_NEW_CARD_REVIEW_SETS`; é o modo barato para cartas recém-chegadas.
- `lookback`: ignora `--sets` e avalia cartas recentes pela janela
  `--lookback-days`; é útil quando o catálogo foi sincronizado sem lista de set
  explícita.
- `full`: ignora `--sets`/lookback e avalia o corpus disponível, respeitando
  `--card-limit`; use `--card-limit 0` somente em janela controlada.

Esse modo `full` é o caminho para revalidar cartas antigas com a mesma régua das
cartas novas, sem criar exceções em código e sem promover regras
automaticamente.

## Saída

Por rodada:

- `latest_summary.json`
- `latest_reviews.json`
- `latest_report.md`
- `latest_commanders/<commander>.json`
- `latest_commanders/<commander>.md`
- diretório por `run_id`

No SQLite:

- `new_card_candidate_review_runs`
- `new_card_candidate_reviews`
- `new_card_battle_rule_review_queue`
- `new_card_candidate_review_checkpoints`
- `new_card_candidate_commander_snapshots`
- `new_card_data_gap_review_runs`
- `new_card_data_gap_review_items`
- `new_card_battle_rule_review_runs`
- `new_card_battle_rule_review_drafts`
- `new_card_battle_rule_focused_evidence_runs`
- `new_card_battle_rule_focused_evidence_items`
- `new_card_battle_rule_promotion_gate_runs`
- `new_card_battle_rule_promotion_gate_items`

Essas tabelas são cache/evidência operacional. Não são fonte final do produto.

## Pipeline Automático Seguro

Fluxo atual:

```text
manaloom_new_card_candidate_review
  -> decision=needs_data
      -> manaloom_card_data_gap_review
  -> decision=needs_rule_review
      -> manaloom_battle_rule_review_queue
          -> manaloom_battle_rule_focused_evidence
              -> manaloom_battle_rule_promotion_gate
```

`manaloom_card_data_gap_review` agrega ocorrências `needs_data` por carta e
gera ações recomendadas, por exemplo:

- `refresh_commander_legality`;
- `refresh_card_legalities`;
- `refresh_oracle_text`;
- `resolve_oracle_id`;
- `defer_battle_rule_until_data_complete`.

`manaloom_battle_rule_review_queue` agrega a fila
`new_card_battle_rule_review_queue` por carta e gera drafts:

- `proposed_status=needs_review`;
- `draft_rule_key`;
- famílias de efeito inferidas por roles e `oracle_text`;
- riscos;
- cenário de teste sugerido.

Opcionalmente, `manaloom_battle_rule_review_queue` pode anexar uma revisão
OpenAI/LLM ao draft quando `MANALOOM_BATTLE_RULE_LLM_REVIEW=1` ou
`--llm-review` for usado. Esse modo:

- usa `OPENAI_API_KEY` somente se a variável existir no ambiente do processo;
- fica desligado por padrão em `manaloom-ops`;
- nunca altera `proposed_status=needs_review`;
- nunca escreve em PostgreSQL;
- nunca promove regra para `verified`;
- nunca libera comportamento duro no battle;
- serve apenas para resumir riscos, fontes oficiais necessárias e cenários de
  teste sugeridos.

`needs_data` não usa LLM. Falta de oracle, legalidade, identidade ou catálogo
deve ser resolvida por sync determinístico com PostgreSQL/Scryfall/MTGJSON.

Esses drafts **não** são escritos em `card_battle_rules`, não viram
`verified`, e não executam comportamento duro no battle. A promoção ainda exige
fonte oficial/ruling, teste focado, replay/auditoria e ausência de finding
crítico.

`manaloom_battle_rule_focused_evidence` consome os drafts e gera evidência
somente para templates pequenos, rastreáveis e suportados por teste focado.
No primeiro slice, o único template automático suportado é:

```text
oracle_text_excerpt == "Counter target spell."
effect_families inclui counterspell_stack_interaction
proposed_status == needs_review
```

Para esse template, o job executa um cenário in-process no
`battle_analyst_v9.py`: um jogador anuncia `Approach of the Second Sun`, o
oponente responde com a carta draftada como counterspell, o stack resolve, e o
auditor de replay/decision trace precisa fechar sem findings críticos/high.

Saídas:

- `latest_evidence.json`;
- `focused_artifacts/<draft_rule_key>/focused_test.json`;
- `focused_artifacts/<draft_rule_key>/replay_audit.json`;
- `focused_artifacts/<draft_rule_key>/replay_events.jsonl`;
- `focused_artifacts/<draft_rule_key>/decision_trace.jsonl`.

Complexidades como sacrifício de criatura para dano, extra combat/flashback ou
trigger de ataque/tutor continuam bloqueadas até existir template focado
proprio. Esse bloqueio é proposital: o job prova uma regra pequena por vez e
nao promove comportamento duro automaticamente.

`manaloom_battle_rule_promotion_gate` consome os drafts e decide apenas se cada
um continua bloqueado ou se está elegível para **promoção manual**. Por padrão,
sem arquivo de evidência explícito, o gate bloqueia por:

- falta de revisão de fonte oficial;
- falta de teste focado;
- falta de replay/auditoria;
- findings críticos/high;
- oracle/rule payload insuficiente.

Mesmo quando retorna `eligible_for_manual_verified_promotion`, o gate continua
report-only:

- não escreve em PostgreSQL;
- não muda `card_battle_rules`;
- não muda `proposed_status`;
- não libera comportamento duro no battle;
- exige revisão humana ou etapa posterior explicitamente aprovada.

Formato esperado para evidência opcional:

```json
{
  "by_draft_rule_key": {
    "card_name__role__draft_v1": {
      "official_source_reviewed": true,
      "official_sources": ["Scryfall oracle text"],
      "focused_test_passed": true,
      "focused_test_refs": ["server/test/..."],
      "replay_audit_passed": true,
      "replay_audit_refs": ["server/test/artifacts/..."],
      "critical_findings": 0,
      "high_findings": 0
    }
  }
}
```

## Relatório Por Comandante

Cada rodada grava um snapshot por comandante com:

- decisões agregadas;
- cobertura de dados e rule status;
- top candidatos `test`/`backlog`/`needs_rule_review`;
- riscos e razões por carta;
- contrato de segurança `no_pg_writes`, `no_auto_apply`,
  `verified_promotion_required`.

Lorehold continua sendo controle padrão, mas o mesmo formato vale para qualquer
comandante descoberto via `commander_learned_decks`, `commander_card_usage` ou
`--force-commander`. O relatório correto para iniciar melhoria de deck é o
snapshot por comandante, não a fila bruta SQLite.

## Próximo Gate Para Melhorias De Deck

Antes de usar candidatos no optimize/generate:

1. Rodar `--scope full` em janela controlada para reclassificar cartas antigas.
2. Rodar `manaloom_card_data_gap_review` e zerar `needs_data` material.
3. Rodar `manaloom_battle_rule_review_queue` para candidatos
   `needs_rule_review`.
4. Rodar `manaloom_battle_rule_promotion_gate` para provar que cada draft ainda
   está bloqueado ou elegível para promoção manual.
5. Promover para `card_battle_rules`/`card_function_tags` somente após fonte
   oficial, teste focado e replay/auditoria.
6. Usar o relatório por comandante para escolher candidatos de scorecard; não
   aplicar swap automático.

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
  server/bin/manaloom_card_data_gap_review.py \
  server/bin/manaloom_battle_rule_review_queue.py \
  server/bin/manaloom_ops_daemon.py \
  server/test/manaloom_new_card_candidate_review_test.py \
  server/test/manaloom_review_queue_consumers_test.py

bash -n \
  server/bin/manaloom_new_card_candidate_review.sh \
  server/bin/manaloom_card_data_gap_review.sh \
  server/bin/manaloom_battle_rule_review_queue.sh

python3 server/test/manaloom_new_card_candidate_review_test.py
python3 server/test/manaloom_review_queue_consumers_test.py
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

Rodada de massa atualizada com 30 comandantes e 166 cartas (`msh,msc,mar`):

```json
{
  "candidate_review": {
    "review_count": 4980,
    "decisions": {
      "backlog": 48,
      "ignore": 2877,
      "needs_data": 2006,
      "needs_rule_review": 49
    },
    "hermes_wake_reasons": ["rule_review_threshold"]
  },
  "card_data_gap_review": {
    "gap_rows": 2006,
    "unique_cards": 150,
    "decisions": {"needs_legality_sync": 150}
  },
  "battle_rule_review_queue": {
    "queue_rows": 49,
    "draft_count": 5,
    "confidence_counts": {"low": 5}
  }
}
```

Leitura correta dessa rodada:

- o principal bloqueio de dados em Marvel nao é oracle text ausente no payload
  atual, e sim legalidade Commander não preenchida/confirmada para 150 cartas;
- a fila de battle rule reduziu 49 ocorrências por comandante para 5 cartas
  únicas em draft;
- exemplos de drafts: `Iron Man, Titan of Innovation`, `Black Panther,
  Wakandan King`, `Storm, Force of Nature`, `Counterspell`, `Seize the Day`;
- `Seize the Day` agora gera família `extra_combat_phase` e
  `graveyard_recast_replacement`, mas permanece `needs_review`.

## Fechamento Do Gap De Legalidade

Em 2026-06-18 foi criado e executado um sincronizador focado para resolver
`needs_legality_sync` sem acoplar isso a LLM ou Hermes:

```bash
python3 server/bin/sync_card_legalities_from_scryfall.py \
  --sets msh,msc,mar

python3 server/bin/sync_card_legalities_from_scryfall.py \
  --sets msh,msc,mar \
  --apply
```

Contrato:

- dry-run por padrão;
- `--apply` explícito para persistir;
- no EasyPanel `manaloom-ops`, o reconciliador define
  `MANALOOM_SYNC_CARD_LEGALITIES_APPLY=1` para a cron controlada;
- usa Scryfall Collection API por `oracle_id`;
- escreve somente `card_legalities`;
- não altera `cards`, decks, tags, battle rules ou qualquer contrato app-facing;
- PostgreSQL/backend continua como fonte de verdade.

Resultado aplicado no PostgreSQL:

```json
{
  "candidate_cards": 150,
  "oracle_ids_requested": 150,
  "oracle_ids_found": 150,
  "oracle_ids_not_found": 0,
  "legality_rows_ready": 3300,
  "legality_rows_upserted": 3300,
  "commander_statuses": {
    "legal": 1,
    "not_legal": 149
  }
}
```

Cobertura pós-sync:

```text
mar: 17/17 com legalidade Commander, 17 jogáveis
msc: 22/22 com legalidade Commander, 22 not_legal
msh: 127/127 com legalidade Commander, 127 not_legal
```

Rerun limpo do pipeline após o sync:

```json
{
  "candidate_review": {
    "cards_scanned": 166,
    "commanders_scanned": 30,
    "decisions": {
      "backlog": 48,
      "ignore": 4866,
      "needs_rule_review": 66
    }
  },
  "card_data_gap_review": {
    "gap_rows": 0,
    "unique_cards": 0,
    "decisions": {}
  },
  "battle_rule_review_queue": {
    "queue_rows": 66,
    "draft_count": 6,
    "confidence_counts": {
      "low": 6
    }
  }
}
```

Leitura correta: `needs_data` foi fechado para esta massa. O trabalho restante
é revisar `needs_rule_review`; isso deve continuar como draft/auditoria até
haver fonte oficial, teste focado e replay sem finding crítico.

## Rodada De Evidência Focada — 2026-06-18

Rodada local report-only contra os sets `msh,msc,mar`, limitada a 8
comandantes e 250 cartas, validou o novo trecho
`candidate -> data_gap -> battle_queue -> focused_evidence -> promotion_gate`.

Resumo:

```json
{
  "candidate_review": {
    "cards_scanned": 166,
    "commanders_scanned": 8,
    "review_count": 1328,
    "decisions": {
      "backlog": 9,
      "ignore": 1308,
      "needs_rule_review": 11
    }
  },
  "card_data_gap_review": {
    "gap_rows": 0,
    "unique_cards": 0
  },
  "battle_rule_review_queue": {
    "queue_rows": 11,
    "draft_count": 4
  },
  "focused_evidence": {
    "evaluated_count": 4,
    "evidence_count": 1
  },
  "promotion_gate": {
    "eligible_count": 1,
    "blocked_count": 3
  }
}
```

Resultado por draft:

- `Counterspell`: elegível para `eligible_for_manual_verified_promotion` com
  evidência focada de stack/counterspell e replay/decision audit sem finding
  crítico/high. Continua sem write automático em PostgreSQL.
- `Goblin Bombardment`: bloqueado; precisa template focado para habilidade
  ativada com sacrifício de criatura e dano alvo.
- `Iron Man, Titan of Innovation`: bloqueado; envolve trigger de ataque,
  artifact count, treasure e tutor, exigindo executor contextual próprio.
- `Seize the Day`: bloqueado; envolve extra combat e flashback/recast do
  cemitério, exigindo cenário focado dedicado.

O wrapper `manaloom_battle_rule_promotion_gate.sh` passou a consumir
automaticamente
`$MANALOOM_OPS_ARTIFACT_DIR/battle_rule_focused_evidence/latest_evidence.json`
quando o arquivo existir e `MANALOOM_BATTLE_RULE_PROMOTION_EVIDENCE_FILE` não
estiver definido. Isso mantém o gate report-only, mas evita rodadas falsas sem
evidência quando o job anterior já produziu prova focada.

## Próximos Passos

1. Rodar a rotina no `manaloom-ops` após deploy e verificar
   `latest_report.md`.
2. Se `needs_data` reaparecer em novos sets, rodar primeiro
   `sync_card_legalities_from_scryfall.py` em dry-run e aplicar somente quando
   o resumo fechar `not_found=0` ou a exceção estiver documentada.
3. Rodar `manaloom_card_data_gap_review` após cada candidate review e usar a
   saída para priorizar sync de legalidades/dados.
4. Rodar `manaloom_battle_rule_review_queue` após cada candidate review e usar
   os drafts para criar testes/regra, sem promoção automática.
5. Rodar `manaloom_battle_rule_focused_evidence` antes do gate; apenas drafts
   com template focado suportado devem gerar evidência automática.
6. Se surgirem candidatos `test`, rodar scorecard/battle específico antes de
   qualquer recomendação para geração ou optimize.
7. Promover regra para `card_battle_rules` apenas depois de fonte confiável,
   teste focado e replay/auditoria sem finding crítico.
