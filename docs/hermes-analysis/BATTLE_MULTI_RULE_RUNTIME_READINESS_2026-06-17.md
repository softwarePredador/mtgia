# Battle Multi-Rule Runtime Readiness — 2026-06-17

## Objetivo

Responder com evidência atualizada se já faz sentido "simplesmente executar
múltiplas regras por nome" no battle runtime, ou se isso ainda abriria
ambiguidade entre spell resolution, activated ability, trigger, static layer e
anotações de custo.

## Fontes usadas

- Runtime real:
  [battle_analyst_v9.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py)
- Registry SQLite:
  [battle_rule_registry.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py)
- Auto-promotion guardrail:
  [auto_promote_battle_rules.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/bin/auto_promote_battle_rules.py)
- Auditor novo:
  [audit_multi_rule_runtime_readiness.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/audit_multi_rule_runtime_readiness.py)
- Artefatos gerados:
  [multi_rule_runtime_readiness_2026-06-17.json](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/multi_rule_runtime_readiness_2026-06-17.json)
  [multi_rule_runtime_readiness_2026-06-17_pg.json](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/multi_rule_runtime_readiness_2026-06-17_pg.json)

## Comandos executados

```bash
python3 -m py_compile \
  docs/hermes-analysis/manaloom-knowledge/scripts/audit_multi_rule_runtime_readiness.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_audit_multi_rule_runtime_readiness.py

python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_audit_multi_rule_runtime_readiness.py

python3 docs/hermes-analysis/manaloom-knowledge/scripts/audit_multi_rule_runtime_readiness.py \
  --db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --output docs/hermes-analysis/master_optimizer_reports/multi_rule_runtime_readiness_2026-06-17.json

python3 docs/hermes-analysis/manaloom-knowledge/scripts/audit_multi_rule_runtime_readiness.py \
  --pg \
  --output docs/hermes-analysis/master_optimizer_reports/multi_rule_runtime_readiness_2026-06-17_pg.json
```

## Resultado factual

### PostgreSQL (fonte de verdade)

- `total_active_rule_names = 3158`
- `multi_rule_card_count = 0`
- `multi_rule_rule_count = 0`
- distribuição ativa:
  - `verified / auto = 1691`
  - `needs_review / review_only = 1467`
- consulta complementar:
  - `active_multi = 0`
  - `any_multi = 0`

Leitura correta:

- a infraestrutura para múltiplas regras por carta existe;
- o runtime já sabe:
  - compor resoluções seguras;
  - fundir anotações de custo seguras;
  - bloquear activated/trigger/static quando faltam executores específicos;
- porém o corpus canônico atual do PostgreSQL ainda **não contém nenhum nome
  com mais de uma regra persistida**.

Isso muda a leitura do gap:

- o problema atual **não** é "o runtime falha em dezenas de multi-rules vivas";
- o problema atual é "a arquitetura foi preparada, mas o corpus ainda não
  materializa multi-rule row-level no PG".

### SQLite local (`knowledge.db`)

- o arquivo local continha `3159` rows, mas estava com drift de schema:
  faltava `execution_status`;
- o auditor foi corrigido para chamar `ensure_battle_card_rules()` antes da
  leitura e auto-migrar a tabela local para o schema esperado;
- depois da auto-migração, o SQLite local também reportou
  `multi_rule_card_count = 0`.

Leitura correta:

- o `knowledge.db` versionado local não era confiável para medir multi-rule
  antes da migração;
- agora o auditor não depende mais desse detalhe e sempre normaliza o schema
  local antes de medir.

## O que isso prova

1. Não existe hoje evidência de produção de que "executar tudo pelo nome" seja
   necessário ou seguro.
2. O runtime atual já está no ponto certo de maturidade:
   - preserva regras múltiplas;
   - explica por que não executou a secundária;
   - evita promoção cega por `normalized_name`;
   - só compõe o subconjunto seguro.
3. Abrir enforcement forte agora, sem corpus row-level real, seria engenharia no
   escuro.

## O que ainda falta para multi-rule real

### P1 — materializar multi-rule real no PostgreSQL

Antes de abrir execução mais forte, o PG precisa passar a conter casos reais de:

- `spell_resolution + activated_ability`
- `spell_resolution + safe_cost_annotation`
- `spell_resolution + trigger_sidecar`
- `spell_resolution + static_sidecar`

Sem isso, a lógica fica exercitada só por fixture/unit test.

### P1 — separar "várias informações na mesma linha" de "várias linhas reais"

Hoje vários casos ainda cabem corretamente em **uma linha** com metadata
embutida:

- `Natural Order`: tutor + `requires_sacrifice_green_creature`
- `Mox Diamond`: mana source + `requires_discard_land`
- `Dismember`: remoção + custo alternativo/vida

Esses casos não exigem multi-row só porque têm mais de um aspecto.

Multi-row só deve nascer quando houver escopos realmente distintos de execução,
como:

- spell cast / resolution
- activated ability
- triggered ability
- static layer / replacement

### P1 — adicionar escopo explícito de execução

O próximo slice correto não é "executar tudo pelo nome". É persistir um recorte
mais explícito por regra, por exemplo:

- `selection_scope`
  - `spell_resolution`
  - `activated_ability`
  - `trigger_resolution`
  - `static_layer`
  - `cost_annotation`
- `executor_family`
  - `resolution`
  - `activated`
  - `trigger`
  - `state_based`
  - `annotation`

Com isso, o runtime passa a selecionar por ação/janela, não por nome.

## Conclusão operacional

Pergunta: "se o correto é ter múltiplas regras executáveis por nome, por que não
implementou logo?"

Resposta técnica:

- porque hoje o banco canônico não tem nenhum caso multi-rule ativo;
- porque vários casos de "multi-função" ainda são melhor modelados como uma
  linha única com metadata segura;
- porque o que falta não é apenas `if len(rules) > 1: execute all`, e sim uma
  matriz explícita de escopo/executor para não misturar spell, trigger,
  activated e static.

Estado correto hoje:

- infra multi-rule: pronta;
- explainability multi-rule: pronta;
- promotion cega por nome: bloqueada;
- corpus PG multi-rule real: ainda não exercitado.

Próximo passo correto:

1. escolher 3-5 cartas reais que precisem de multi-row de verdade;
2. persistir essas rows no PG com escopos distintos;
3. reexecutar este auditor;
4. só então abrir executor adicional por escopo.
