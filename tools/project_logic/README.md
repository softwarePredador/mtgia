# ManaLoom project logic generator

Extrator determinístico que usa `package:analyzer` para indexar a estrutura Dart e
combina o resultado com rotas, migrations, SQL, dependências, scripts, testes e o
contrato humano em `docs/project_logic_contracts.json`.

```bash
./scripts/manaloom_project_logic.sh --write
./scripts/manaloom_project_logic.sh --check
./scripts/quality_gate.sh project-logic
```

O primeiro comando atualiza o manifesto e os documentos derivados. O segundo
falha quando qualquer artefato está ausente ou diferente. O gate também executa
os testes do gerador e `dart doc --dry-run` sem tolerar warnings.

O gerador descreve estrutura; decisões e intenção continuam nos ADRs. Não capture
valores de ambiente, credenciais ou DSNs no manifesto.

Entradas humanas ativas também participam do digest: `AGENTS.md`, README raiz,
`docs/README.md`, documentos correntes declarados pelo lifecycle e todas as
instruções/perfis `.github`. Perfis de agente precisam herdar
`MANALOOM_AGENT_POLICY_V1`, permanecer user-invoked e não podem reintroduzir
autoridade histórica, ferramentas de subagente ou mutação GitHub implícita.
Documentos classificados como `historical_evidence` continuam versionados, mas
não entram no digest de fontes ativas.

O `TASK_REGISTRY.json` schema `2` também valida o ledger operacional derivado.
O schema `2` substitui os nomes ambíguos `producers`/`consumers` pelos campos
flow-granulares abaixo. A fila deve
declarar WIP `1`, conter exatamente um slot `NOW` e apontar para
`docs/execution/tasks/<TASK-ID>.md`; o ID da ficha deve coincidir com uma task
canônica. Dependências do `NOW` devem estar `PASS`; a única exceção exige
estado canônico `IN_PROGRESS_CONTAINED`, Task ID e motivo fail-closed
estruturados na fila. Fila e ficha não possuem autoridade sobre prioridade,
estado, dependências, entrega, aceite ou mutação live.

Bindings de rota têm granularidade por entrypoint somente para `sources`,
`surfaces` e `methods`. Os campos `flow_producers` e `flow_consumers` são a
implementação declarada do fluxo e não alegam um call graph por rota. A
rastreabilidade completa de chamadas continua sendo um gate separado.

O parser de tasks falha fechado para IDs duplicados, dependências inválidas ou
cíclicas, placeholders em entrega/aceite e definições inequívocas fora das
tabelas canônicas. O receipt `project_logic_manifest_v1` deve vincular
explicitamente `source_digest_sha256`.
