# BrewTact — fila operacional corrente

Lifecycle: `CURRENT_CONTEXT · DERIVED_QUEUE · NO_PRIORITY_AUTHORITY`

- Atualizada em: `2026-08-14`
- Branch de partida: `codex/free-beta-release-candidate-2026-07-17`
- SHA de partida: `b2d3fc04f823f1c58434349a0cf0b48d74919862`
- Backlog/registry SHA-256: `9f7d05f128c94655e41254872516322dea13da28b11613c93e3540d5dc39f142`
- Project logic source digest: `f3628ca3199dce784820a3dc63c9a6d7312a229098ce0ee5fc17a93f3d7e400a`
- WIP máximo: `1`
- Limite de subagentes: `15`

Esta fila é derivada. Em qualquer divergência, prevalecem a decisão corrente, o
backlog mestre e o registry gerado.

## Slot atual

| Slot | ID | Ficha | Objetivo de coordenação |
| --- | --- | --- | --- |
| `NOW` | `BT-GOV-001` | `docs/execution/tasks/BT-GOV-001.md` | Fechar a verdade corrente da beta gratuita/all-OFF com evidência ligada à revisão antes de ampliar trabalho funcional. |

Nenhum outro ID pode receber implementação enquanto este slot estiver aberto.
Auditorias paralelas servem apenas ao mesmo ID.

## Horizonte imediato, em ordem

| Ordem | ID | Por que vem aqui |
| ---: | --- | --- |
| 1 | `BT-GOV-001` | ancora a decisão que todas as promoções precisam obedecer |
| 2 | `BT-DOC-001` | elimina precedência ambígua entre documentos correntes e históricos |
| 3 | `BT-DOC-004` | fecha o registry/ledger operacional e seus guards |
| 4 | `BT-SCP-001` | prova default-deny server-side e a matriz 29/29 OFF |
| 5 | `BT-OFFER-001` | prova uma única oferta pública, sem comércio ou paywall |
| 6 | `BT-GATE-001` | garante que `SKIP/PARTIAL` não pareça sucesso |
| 7 | `BT-GATE-002` | fecha receipts fortes e duráveis por SHA/digest/target |
| 8 | `BT-DB-001` | produz o baseline PostgreSQL fresco exigido antes do ledger de deck |
| 9 | `BT-DB-004` | prova que somente migrations alteram schema |
| 10 | `BT-DB-005` | classifica relações suplementares consumidas pela IA |
| 11 | `BT-CAP-001` | mede capacidade real antes de abrir runtimes caros |
| 12 | `BT-DR-001` | prova backup/restore antes de mutações estruturais futuras |
| 13 | `BT-KPI-001` | define telemetria sem decklist/UGC |
| 14 | `BT-OBS-001` | conecta SLO, alerta, owner e runbook |

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
- A evidência UI corrente está stale no digest novo. Neste checkpoint somente
  `emulator-5554` está conectado; o Samsung físico exigido está ausente e as 54
  capturas ainda precisam ser executadas, abertas e revisadas. Isso não é
  `PASS`.
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
