# BrewTact — fila operacional corrente

Lifecycle: `CURRENT_CONTEXT · DERIVED_QUEUE · NO_PRIORITY_AUTHORITY`

- Atualizada em: `2026-08-24`
- Branch de partida: `codex/free-beta-release-candidate-2026-07-17`
- SHA de partida: `fd0397a5a97742bcb5127c7b2d08d80aca4bf738`
- Backlog/registry SHA-256: `baed1f2b2ccd0cbc9620fa073d13311d5a8354513d2222a324881ca70d003016`
- Project logic source digest: `44ab0563e6703bad2d1a8a47128d318d88401c050fb98b07d38a3b2a299ab042`
- WIP máximo: `1`
- Limite de subagentes: `15`

Esta fila é derivada. Em qualquer divergência, prevalecem a decisão corrente, o
backlog mestre e o registry gerado.

## Slot atual

| Slot | ID | Ficha | Objetivo de coordenação |
| --- | --- | --- | --- |
| `NOW` | `BT-DOC-001` | `docs/execution/tasks/BT-DOC-001.md` | Eliminar precedência ambígua entre documentos correntes e históricos sem iniciar outra frente funcional. |

Nenhum outro ID pode receber implementação enquanto este slot estiver aberto.
Auditorias paralelas servem apenas ao mesmo ID.

## Horizonte imediato, em ordem

| Ordem | ID | Por que vem aqui |
| ---: | --- | --- |
| 1 | `BT-DOC-001` | elimina precedência ambígua entre documentos correntes e históricos |
| 2 | `BT-DOC-004` | fecha o registry/ledger operacional e seus guards |
| 3 | `BT-SCP-001` | prova default-deny server-side e a matriz 29/29 OFF |
| 4 | `BT-OFFER-001` | prova uma única oferta pública, sem comércio ou paywall |
| 5 | `BT-GATE-001` | garante que `SKIP/PARTIAL` não pareça sucesso |
| 6 | `BT-GATE-002` | fecha receipts fortes e duráveis por SHA/digest/target |
| 7 | `BT-DB-001` | produz o baseline PostgreSQL fresco exigido antes do ledger de deck |
| 8 | `BT-DB-004` | prova que somente migrations alteram schema |
| 9 | `BT-DB-005` | classifica relações suplementares consumidas pela IA |
| 10 | `BT-CAP-001` | mede capacidade real antes de abrir runtimes caros |
| 11 | `BT-DR-001` | prova backup/restore antes de mutações estruturais futuras |
| 12 | `BT-KPI-001` | define telemetria sem decklist/UGC |
| 13 | `BT-OBS-001` | conecta SLO, alerta, owner e runbook |

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

- A branch candidata foi publicada no SHA de partida acima.
- A validação pública read-only observou produção no SHA
  `a6ee09c8f16cf17c2867de4b089e5e65b3527254`:
  `SERVER_BEHIND`; `/capabilities` ainda retornava `404` e readiness anunciava
  migration `057`.
- Não existe autorização de deploy. Divergência live é observação, não ação.
- `BT-GOV-001` fechou em `PASS` local no commit
  `fd0397a5a97742bcb5127c7b2d08d80aca4bf738`; o gate `full` passou, e a
  evidência UI corrente contém 456 capturas no digest `d517adb65b…`, incluindo
  54 checkpoints no Samsung SM-A135M físico, todos revisados.
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
