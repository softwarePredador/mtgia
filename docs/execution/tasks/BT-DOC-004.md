# Ficha de execução — `BT-DOC-004`

> Ledger de abertura não autoritativo. ID, estado, dependência, entrega e aceite
> continuam resolvidos no backlog mestre/registry.

## Autoridade

- Task ID: `BT-DOC-004`
- Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md`
- Registry schema: `1`
- Registry `generated_from.sha256`:
  `5109f0e0e5585c2c6ce3655514d2f8a5f38331105f6a6471ee9069e520d25864`
- Project logic baseline de abertura:
  `be3bf02dba40befead607ba4f34a55595e1322ef9dc1a7bccc6396b1ccac9cee`
- Dependência `BT-DOC-001`: `PASS`
- Estado canônico: `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`

## Identidade da abertura

- Owner: `/root`
- Início UTC: `2026-08-24T19:43:25Z`
- Branch: `codex/free-beta-release-candidate-2026-07-17`
- Git SHA baseline anterior ao commit de abertura:
  `c6e2725af0995e01dcf675f20e3a8b608b84d555`
- Commit de abertura: closeout posterior a `c6e2725af`; SHA comunicado no
  handoff para evitar autorreferência
- Autorização usada neste checkpoint: somente abrir a ficha e mover a fila;
  nenhuma implementação de `BT-DOC-004`, push, deploy ou mutação live

## Resultado esperado

Fechar o registry machine-readable e o ledger operacional para que tasks,
dependências, DAG, lifecycle documental, rotas/consumers e contratos de receipt
sejam reproduzíveis, validados e ligados ao digest sem criar uma segunda fonte
de prioridade.

## Escopo previsto

- reconciliar parser, schema e projeção backlog → registry;
- provar IDs únicos, dependências resolvidas, DAG acíclica e ausência de
  placeholder/definição fora da tabela;
- provar que fila e packets são ledger sem autoridade de prioridade;
- validar lifecycle, rotas/consumers, receipt bindings e digest do registry;
- cobrir positivos e negativos determinísticos e emitir receipt próprio.

Fora do escopo: mudar prioridade/aceite fora da linha canônica, implementar
feature, abrir capability, alterar schema/live data, criar PR, fazer push,
deploy ou promoção.

## Plano de prova

1. baseline reproduzível do registry e de todos os guards atuais;
2. negativos para duplicidade, dependência ausente, ciclo, placeholder,
   definição fora da tabela, histórico ativo e receipt sem binding;
3. consumidores/entrypoints reconciliados com rotas geradas;
4. digest inicial/final estável e gerados sem drift;
5. secret scan, `diff --check`, retenção e auditoria independente.

## Checkpoint de abertura

- A task foi apenas promovida ao slot `NOW`; implementação não iniciada.
- WIP permanece `1`; nenhuma outra task funcional está aberta.
- O fechamento de `BT-DOC-001` não autoriza push, PR, deploy ou live mutation.

## Fechamento

- Resultado: `OPENED_NOT_IMPLEMENTED`
- Gate-eligible: `false`
- Bloqueios: nenhum para iniciar a auditoria focal em uma rodada posterior
- Commit final: `pending`
