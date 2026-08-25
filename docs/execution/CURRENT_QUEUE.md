# BrewTact — fila operacional corrente

Lifecycle: `CURRENT_CONTEXT · DERIVED_QUEUE · NO_PRIORITY_AUTHORITY`

- Atualizada em: `2026-08-25`
- Branch de partida: `codex/free-beta-release-candidate-2026-07-17`
- SHA baseline na abertura de `BT-SCP-001`:
  `d9f7a59cd87d032df3d076c35ffbdb17e41525a6`
- Upstream observado na abertura: `c1bd186633a479f62eae0ba4db6eb29463e94419`
- Divergência observada: `ahead_by=1`, `behind_by=0`, `NOT_PUSHED`
- Observado em UTC: `2026-08-24T21:14:27Z`
- Backlog/registry SHA-256 de abertura:
  `0ce0be74f84bd5e8eb25568601a4ce47f46a24dd6766dba67393caadd8f62abd`
- Project logic baseline na abertura de `BT-SCP-001`:
  `bf7704ee33c99009bc878962409654df0af63d244c1b52c10eccc7aa674c80e0`
- WIP máximo: `1`
- Exceção de contenção fail-closed do NOW: `none`
- Limite de subagentes nesta execução: `3`, sem descendentes, por solicitação
  do usuário

Esta fila é derivada. Em qualquer divergência, prevalecem a decisão corrente, o
backlog mestre e o registry gerado.

## Slot atual

| Slot | ID | Ficha | Objetivo de coordenação |
| --- | --- | --- | --- |
| `NOW` | `BT-SCP-001` | `docs/execution/tasks/BT-SCP-001.md` | Provar o manifesto server-authoritative, default-deny e same-SHA sem abrir nenhuma capability. |

Nenhum outro ID pode receber implementação enquanto este slot estiver aberto.
Auditorias paralelas servem apenas ao mesmo ID.

## Horizonte imediato, em ordem

| Ordem | ID | Por que vem aqui |
| ---: | --- | --- |
| 1 | `BT-SCP-001` | prova default-deny server-side e a matriz 29/29 OFF |
| 2 | `BT-OFFER-001` | prova uma única oferta pública, sem comércio ou paywall |
| 3 | `BT-GATE-001` | garante que `SKIP/PARTIAL` não pareça sucesso |
| 4 | `BT-GATE-002` | fecha receipts fortes e duráveis por SHA/digest/target |
| 5 | `BT-DB-001` | produz o baseline PostgreSQL fresco exigido antes do ledger de deck |
| 6 | `BT-DB-004` | prova que somente migrations alteram schema |
| 7 | `BT-DB-005` | classifica relações suplementares consumidas pela IA |
| 8 | `BT-CAP-001` | mede capacidade real antes de abrir runtimes caros |
| 9 | `BT-DR-001` | prova backup/restore antes de mutações estruturais futuras |
| 10 | `BT-KPI-001` | define telemetria sem decklist/UGC |
| 11 | `BT-OBS-001` | conecta SLO, alerta, owner e runbook |

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

- Na abertura de `BT-SCP-001`, a branch local estava um commit à frente do
  upstream. Essa é uma observação Git local, não PR, deploy ou release.
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
  `be3bf02dba40…`, após auditoria independente `GO`; implementação e fechamento
  já são ancestrais do upstream observado, sem deploy.
- `BT-DOC-004` fechou em `PASS` local no commit
  `d9f7a59cd87d032df3d076c35ffbdb17e41525a6`, digest de implementação
  `bf7704ee33c9…`, gate `full` e auditoria independente `GO`; push desta
  implementação ainda está pendente neste snapshot, e nenhum deploy ocorreu.
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
