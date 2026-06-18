# Cron Efficiency Revalidation — 2026-06-17

> Status: operacional para triagem.
> Escopo: revalidar, uma a uma, as crons Hermes/ManaLoom sob o critério de
> valor real para o produto, risco de ruído e consumo de token desnecessário.

## Critério desta revisão

Cada cron foi classificada por cinco eixos:

- **Função real**: o que de fato entrega para o produto.
- **Dependência de provider**: se consome LLM/token ou é script-only.
- **Valor atual**: `alto`, `médio`, `baixo` ou `nenhum`.
- **Eficiência atual**: se roda apenas quando faz sentido ou se tende a gastar
  execução/token sem ganho proporcional.
- **Decisão recomendada**: `manter`, `manter com cadência menor`, `manual`,
  `migrar para worker determinístico` ou `desligar`.

## Fonte usada

Esta revisão cruza:

- `docs/hermes-analysis/README.md`
- `docs/hermes-analysis/HERMES_E2E_SYSTEM_CONTRACT_2026-06-07.md`
- `docs/hermes-analysis/HERMES_CRON_PIPELINE_ORDER_2026-06-07.md`
- `docs/hermes-analysis/HERMES_CRON_VALUE_AND_MIGRATION_AUDIT_2026-06-11.md`
- `docs/hermes-analysis/HERMES_RUNTIME_CRON_ALIGNMENT_2026-06-11.md`
- `server/bin/manaloom_ops_daemon.py`

Quando há conflito entre snapshots antigos e o runtime migrado, prevalece o
modelo atual do `manaloom-ops` e a triagem mais nova do README canônico.

## Estado estrutural atual

Hoje existem dois grupos distintos:

### 1. Worker determinístico já migrado

Executa sem provider e sem custo de token:

- `pull_learning_events`
- `auto_sync_learned_decks`
- `auto_promote_learned_decks`
- `master_optimizer_preflight`
- `hermes_mana_base_validator`
- `hermes_cron_governor_report`

Esses seis jobs rodam no `manaloom-ops` e são os mais próximos do que deve
continuar existindo após a aposentadoria do Hermes AWS.

### 2. Jobs Hermes research/provider

Dependem de provider ou de contexto de laboratório:

- `manaloom-hermes-normal-audit`
- `manaloom-hermes-weekly-parallel-audit`
- `manaloom-commander-knowledge-deep`
- `manaloom-gamechanger-research`
- `manaloom-tag-accuracy-reporter`
- `manaloom-knowledge-import`
- `manaloom-code-structure-auditor`
- `manaloom-logic-coherence-auditor`
- `manaloom-knowledge-synthesis`
- `mtg-rules-auditor`
- históricos Lorehold/optimizer manuais

Estes são os principais candidatos a corte, redução de cadência ou conversão
para script determinístico.

## Revalidação cron por cron

### A. Núcleo operacional do produto

| Cron | Provider | Função real | Valor atual | Eficiência atual | Decisão |
|---|---|---|---|---|---|
| `pull_learning_events` | não | puxa eventos reais do backend para o loop de aprendizado | alto | boa, mas `*/30` ainda é agressivo para volume normal | manter; preferir `0 */1` ou `0 */2` |
| `auto_sync_learned_decks` | não | sincroniza learned decks aprovados para consumo real | alto | boa; já tem guardrail para ignorar decks inválidos | manter |
| `auto_promote_learned_decks` | não | promove only-safe learned decks | alto | boa; 6h é conservador e barato | manter |
| `master_optimizer_preflight` | não | sincroniza metadados, regras e readiness do optimizer | alto | boa, mas 1h pode ser mais do que o necessário fora de janela de trabalho | manter |
| `hermes_mana_base_validator` | não | detecta decks inválidos, seeds ruins e regressões de mana | médio/alto | boa; 6h já é barata | manter |
| `hermes_cron_governor_report` | não | observabilidade da frota | médio | boa; 12h é suficiente | manter |

#### Leitura

Esse bloco agrega de verdade. Ele não queima token e melhora diretamente:

- ingestão de aprendizado;
- disponibilidade de learned decks;
- integridade do optimizer;
- sanidade de decks;
- saúde operacional.

Se fosse preciso preservar apenas o essencial, este bloco ficaria inteiro.

### B. Jobs úteis, mas não para alta frequência

| Cron | Provider | Função real | Valor atual | Eficiência atual | Decisão |
|---|---|---|---|---|---|
| `manaloom-knowledge-import` | sim/histórico híbrido | consolida achados Hermes em conhecimento intermediário | médio | valor existe, mas pode rodar sem novidade e produzir ruído | manter com cadência menor ou converter para script ingest |
| `manaloom-commander-knowledge-deep` | sim | minera padrões por comandante | médio | útil, mas não precisa rodar várias vezes ao dia enquanto corpus não muda tanto | manter com cadência baixa ou on-demand |
| `manaloom-knowledge-synthesis` | sim | transforma achados em tasks acionáveis | alto, se houver triagem | tende a desperdiçar token quando o upstream não trouxe nada novo | manter com cadência baixa e condicionada a delta |
| `mtg-rules-auditor` | sim | detecta gaps de regra e cobertura de battle | alto | útil, mas caro para rodar cedo demais sem lote novo de replays | manter com cadência baixa ou por trigger |
| `manaloom-gamechanger-research` | sim | pesquisa gaps de category/ranking/gamechanger | médio | corpus já estava majoritariamente coberto; recorrência alta vira ruído | manter baixa cadência ou manual |

#### Leitura

Essas crons ainda agregam, mas não no ritmo histórico. O problema delas não é
existência; é **cadência sem gatilho de novidade**.

A regra correta para esse grupo é:

- só rodar quando houve mudança material em dados, replay, learned decks,
  semantic tags ou regras;
- ou então em baixa cadência para inspeção periódica.

### C. Jobs de baixo valor recorrente

| Cron | Provider | Função real | Valor atual | Eficiência atual | Decisão |
|---|---|---|---|---|---|
| `manaloom-hermes-normal-audit` | sim | auditoria genérica pós-mudança | baixo | duplica o report-only que o Codex já aciona após push | manter pausada |
| `manaloom-hermes-weekly-parallel-audit` | sim | auditoria ampla paralela | baixo | historicamente gerou ruído, conflito de docs e custo alto | manter pausada |
| `manaloom-code-structure-auditor` | sim | varredura estrutural ampla | baixo como cron | útil manualmente, ruim como recorrência | manual apenas |
| `manaloom-logic-coherence-auditor` | sim | coerência ampla docs/código/fluxo | médio como ferramenta, baixo como cron | bom para rodadas dirigidas, ruim para loop solto | manual apenas |
| `manaloom-tag-accuracy-reporter` | sim | mede qualidade de tags | alto como necessidade, baixo como cron agent | a necessidade é real, mas a implementação atual não é econômica | converter para script determinístico antes de reativar |
| `manaloom-flutter-ui-auditor` | none/legacy | tentava validar UI em Linux | nenhum recorrente | não prova runtime iOS/Android e gera sinal fraco | desligar como cron |

#### Leitura

Aqui está a maior fonte de desperdício potencial de token.

Esses jobs:

- ou duplicam fluxo já coberto por Codex;
- ou tentam automatizar algo que precisa de triagem humana;
- ou geram documentação ampla demais para o valor entregue;
- ou medem algo válido com uma implementação cara/inadequada.

### D. Jobs históricos/legados que não devem voltar

| Cron | Situação | Decisão |
|---|---|---|
| `manaloom-manager-watchdog` | legado, substituído pelo governor report-only | desligado definitivo |
| `lorehold-knowncards-generator` | substituído pelo fluxo atual | manter desligado |
| `lorehold-universal-optimizer` | risco de auto-apply legado | desligado definitivo |
| `manaloom-master-optimizer-slot-scan` | pesado, útil só em janela controlada | manual |
| `manaloom-master-optimizer-end-to-end` | pipeline de prova completa, caro | manual |
| `manaloom-master-optimizer-loop` | one-shot vencido | desligado |
| `lorehold-*` scout/validator/oracle/wincon antigos | laboratório antigo superado por learned decks + optimizer atual | não reativar sem redesenho |

## Onde ainda existe gasto desnecessário potencial

### 1. Cadência sem gatilho

As crons provider ainda dependentes tendem a rodar por relógio, não por
novidade real. Isso é o principal desperdício.

Melhor estratégia:

- disparar por evento quando possível;
- ou registrar `last_input_hash` / `last_data_fingerprint`;
- e retornar `SILENT` sem chamar provider quando nada relevante mudou.

### 2. Auditoria ampla demais

Jobs como `normal-audit`, `weekly-parallel-audit`, `code-structure-auditor` e
`logic-coherence-auditor` têm escopo grande demais para uma recorrência barata.

Esses casos devem virar:

- execução manual;
- ou report-only pós-push;
- ou script determinístico com escopo estreito.

### 3. Falta de promotion path determinístico

`tag-accuracy-reporter`, `commander-knowledge-deep` e `gamechanger-research`
produzem achados úteis, mas ainda não foram suficientemente convertidos em:

- scorecards determinísticos;
- métricas persistidas no servidor;
- ou suites de teste.

Enquanto isso não ocorrer, o custo por insight segue maior do que o ideal.

## Recomendação final de frota

### Manter habilitado agora

- `pull_learning_events`
- `auto_sync_learned_decks`
- `auto_promote_learned_decks`
- `master_optimizer_preflight`
- `hermes_mana_base_validator`
- `hermes_cron_governor_report`

### Manter apenas se houver budget e necessidade real

- `manaloom-knowledge-import`
- `manaloom-commander-knowledge-deep`
- `manaloom-knowledge-synthesis`
- `mtg-rules-auditor`
- `manaloom-gamechanger-research`

### Deixar manual/on-demand

- `manaloom-code-structure-auditor`
- `manaloom-logic-coherence-auditor`
- `manaloom-master-optimizer-slot-scan`
- `manaloom-master-optimizer-end-to-end`

### Manter pausado/desligado

- `manaloom-hermes-normal-audit`
- `manaloom-hermes-weekly-parallel-audit`
- `manaloom-manager-watchdog`
- `manaloom-tag-accuracy-reporter` até virar script/server job
- `manaloom-flutter-ui-auditor`
- legados `lorehold-*`

## Próximos cortes/otimizações recomendados

1. Reduzir `pull_learning_events` de `*/30` para `0 */1` ou `0 */2`, salvo se o
   volume real justificar meia hora.
2. Condicionar `knowledge-synthesis` a delta material de achados, não só tempo.
3. Transformar `tag-accuracy-reporter` em scorecard determinístico.
4. Transformar `mtg-rules-auditor` em suíte/golden scenarios incremental.
5. Não reativar auditorias amplas automáticas enquanto o Codex já faz report-only
   pós-push.

## Conclusão

A maior parte do valor real já está no bloco determinístico migrado para
`manaloom-ops`.

O que ainda consome token e continua defensável é pequeno:

- `knowledge-import`
- `commander-knowledge-deep`
- `knowledge-synthesis`
- `mtg-rules-auditor`
- `gamechanger-research`

Todo o restante ou:

- já foi corretamente substituído;
- deve ficar manual;
- ou não justifica mais rodar como cron recorrente.
