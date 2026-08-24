# BrewTact — fila operacional corrente

Lifecycle: `CURRENT_CONTEXT · DERIVED_QUEUE · NO_PRIORITY_AUTHORITY`

- Atualizada em: `2026-08-24`
- Branch de partida: `codex/free-beta-release-candidate-2026-07-17`
- SHA baseline na abertura de `BT-DOC-004`:
  `c6e2725af0995e01dcf675f20e3a8b608b84d555`
- Upstream observado na abertura: `b2d3fc04f823f1c58434349a0cf0b48d74919862`
- Divergência observada: `ahead_by=4`, `behind_by=0`, `NOT_PUSHED`
- Observado em UTC: `2026-08-24T19:43:25Z`
- Backlog/registry SHA-256 de abertura:
  `5109f0e0e5585c2c6ce3655514d2f8a5f38331105f6a6471ee9069e520d25864`
- Project logic baseline na abertura de `BT-DOC-004`:
  `be3bf02dba40befead607ba4f34a55595e1322ef9dc1a7bccc6396b1ccac9cee`
- WIP máximo: `1`
- Exceção de contenção fail-closed do NOW: `none`
- Limite de subagentes nesta execução: `3`, sem descendentes, por solicitação
  do usuário

Esta fila é derivada. Em qualquer divergência, prevalecem a decisão corrente, o
backlog mestre e o registry gerado.

## Slot atual

| Slot | ID | Ficha | Objetivo de coordenação |
| --- | --- | --- | --- |
| `NOW` | `BT-DOC-004` | `docs/execution/tasks/BT-DOC-004.md` | Fechar o registry/ledger operacional, sua DAG, lifecycle, consumers, receipts e guards sem iniciar outra frente funcional. |

Nenhum outro ID pode receber implementação enquanto este slot estiver aberto.
Auditorias paralelas servem apenas ao mesmo ID.

## Horizonte imediato, em ordem

| Ordem | ID | Por que vem aqui |
| ---: | --- | --- |
| 1 | `BT-DOC-004` | fecha o registry/ledger operacional e seus guards |
| 2 | `BT-SCP-001` | prova default-deny server-side e a matriz 29/29 OFF |
| 3 | `BT-OFFER-001` | prova uma única oferta pública, sem comércio ou paywall |
| 4 | `BT-GATE-001` | garante que `SKIP/PARTIAL` não pareça sucesso |
| 5 | `BT-GATE-002` | fecha receipts fortes e duráveis por SHA/digest/target |
| 6 | `BT-DB-001` | produz o baseline PostgreSQL fresco exigido antes do ledger de deck |
| 7 | `BT-DB-004` | prova que somente migrations alteram schema |
| 8 | `BT-DB-005` | classifica relações suplementares consumidas pela IA |
| 9 | `BT-CAP-001` | mede capacidade real antes de abrir runtimes caros |
| 10 | `BT-DR-001` | prova backup/restore antes de mutações estruturais futuras |
| 11 | `BT-KPI-001` | define telemetria sem decklist/UGC |
| 12 | `BT-OBS-001` | conecta SLO, alerta, owner e runbook |

Ao concluir cada ID, a fila é reavaliada contra o registry. Uma dependência que
continue sem `PASS` impede a promoção do próximo ID afetado.

## Ondas depois do horizonte

1. [Verdade e evidência](waves/00-truth-and-evidence.md)
2. [Segurança, dados e contenção](waves/01-platform-safety.md)
3. [Deck revision, ledger, receipt e undo](waves/02-deck-foundation.md)
4. [Analyze e Optimize advisory](waves/03-analyze-optimize.md)
5. [Generate e Rebuild allowlisted](waves/04-generate-rebuild.md)
6. [Learning promocional com receipts](waves/05-learning.md)
7. [Battle independente](waves/06-battle-independent.md)
8. [Fechamento da beta Web/Android](waves/07-beta-release.md)

A ordem funcional preserva a decisão solicitada: primeiro a fundação de
Deckbuilder e seu ledger/receipt; depois Analyze/Optimize e a infraestrutura de
jobs/custo; então Generate/Rebuild; por fim Learning. Battle não é dependência
do core enquanto suas capabilities permanecerem comprovadamente OFF.

## Estado operacional conhecido

- Na abertura, a branch local estava três commits à frente do upstream. Essa é
  uma observação Git local, não publicação, PR, deploy ou release.
- A validação pública read-only observou produção no SHA
  `a6ee09c8f16cf17c2867de4b089e5e65b3527254`:
  `SERVER_BEHIND`; `/capabilities` ainda retornava `404` e readiness anunciava
  migration `057`.
- Não existe autorização de deploy. Divergência live é observação, não ação.
- `BT-GOV-001` fechou em `PASS` local no commit
  `fd0397a5a97742bcb5127c7b2d08d80aca4bf738`; o gate `full` passou, e a
  evidência UI corrente contém 456 capturas no digest `d517adb65b…`, incluindo
  54 checkpoints no Samsung SM-A135M físico, todos revisados.
- `BT-DOC-001` fechou em `PASS` local no commit
  `c6e2725af0995e01dcf675f20e3a8b608b84d555`, digest de implementação
  `be3bf02dba40…`, após auditoria independente `GO`; nenhum push ou deploy foi
  executado.
- `BT-UX-PROOF-001` fica na onda final porque novas mudanças app-facing
  invalidariam capturas feitas agora.
- Parecer jurídico, expansão social/comercial e iOS continuam fora desta fila
  funcional até seus bloqueios/decisões próprios.

## Como mover o slot

1. finalizar a ficha e os receipts do ID `NOW`;
2. obter auditoria independente quando aplicável;
3. atualizar somente a linha canônica do backlog, com evidência;
4. executar `project_logic --write` e `--check`;
5. atualizar hashes deste documento;
6. remover/arquivar a ficha concluída e criar a ficha do próximo ID elegível;
7. fazer commit atômico antes de iniciar implementação do ID seguinte.
