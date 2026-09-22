# BrewTact — fila operacional corrente

Lifecycle: `CURRENT_CONTEXT · DERIVED_QUEUE · NO_PRIORITY_AUTHORITY`

- Atualizada em: `2026-09-22` (estado observado após `d15beb05b` e decisões do dono de 2026-09-22 sobre as 55 recomendações de `docs/status/DECISOES_PENDENTES_2026-09-22.md`)
- Branch de partida: `codex/free-beta-release-candidate-2026-07-17`
- SHA baseline na abertura de `BT-SCP-001`:
  `d9f7a59cd87d032df3d076c35ffbdb17e41525a6`
- Upstream observado na abertura: `c1bd186633a479f62eae0ba4db6eb29463e94419`
- Divergência observada em 2026-09-22: `ahead_by=0`, `behind_by=0`, `PUSHED`
  (todos os commits até `d15beb05b` estão no origin)
- Observado em UTC: `2026-08-24T21:14:27Z`
- Backlog/registry SHA-256 de abertura:
  `0ce0be74f84bd5e8eb25568601a4ce47f46a24dd6766dba67393caadd8f62abd`
- Project logic baseline na abertura de `BT-SCP-001`:
  `bf7704ee33c99009bc878962409654df0af63d244c1b52c10eccc7aa674c80e0`
- Backlog/registry SHA-256 corrente (árvore de trabalho de 2026-09-22, sem commit):
  `dd1fe8ff0a41a10b680350ff197a4dfa32e3c25fe2acda6a5410be4ed109216f`
  (227 tasks após a correção documental de 2026-09-22; em HEAD `d15beb05b` era
  `333b6c0b…` com 220 tasks e 402 arestas, valor de `f6f791098`)
- Project logic digest em HEAD `d15beb05b`: `556ba631…`. O digest da árvore de trabalho
  não é copiado aqui, porque este arquivo entra no próprio digest: ver
  `project_logic_manifest.json > source_digest_sha256`.
- WIP máximo: `1`
- Exceção de contenção fail-closed do NOW: `BT-SCP-001` — o gate amplo depende de BT-UIEV-001 (evidência de UI), ainda aberto, e do receipt same-SHA de BT-WEB-003 (bump feito em 2026-09-22); o manifesto segue fail-closed com 29/29 capabilities off enquanto eles fecham
- Writers em 2026-09-21: quatro sessões paralelas (ver
  `docs/PONTO_DE_RETOMADA_COORDENACAO_2026-09-21.md`). Só a frente A serviu ao
  slot NOW; as demais produziram `docs/design`, `docs/flows` e a correção não
  commitada do marketplace, fora de qualquer ID. Exceção ao WIP-1 registrada
  aqui, não autorizada por este documento.

Esta fila é derivada. Em qualquer divergência, prevalecem a decisão corrente, o
backlog mestre e o registry gerado.

## Slot atual

| Slot | ID | Ficha | Objetivo de coordenação |
| --- | --- | --- | --- |
| `NOW` | `BT-SCP-001` | `docs/execution/tasks/BT-SCP-001.md` | Provar o manifesto server-authoritative, default-deny e same-SHA sem abrir nenhuma capability. |

Nenhum outro ID pode receber implementação enquanto este slot estiver aberto.
Auditorias paralelas servem apenas ao mesmo ID.

Exceções ocorridas (não retroativamente autorizadas): `a2d044618` (gate
deck-quality, sem ID), `f6f791098` (Jogar contra IA, BT-PLAY-* não movidos),
BT-CI-001 (`d83e9b1e1`) e BT-UIEV-001 (`b397f477b`, `9a9ba66de`, `d08c18717`)
— os dois últimos ganharam linha no backlog em árvore de trabalho de 2026-09-22, ainda sem commit.

## Horizonte imediato, em ordem

Por decisão do dono de 2026-09-22 (D-02), o trabalho corre em duas raias,
separadas pela fronteira do digest de UI, com WIP-1 em cada uma. O gerador ainda
aceita um só slot `NOW`; a raia do app abre quando `BT-UIEV-001` fechar e o
`BT-GOV-002` mudar o contrato da fila. Até lá, só a raia de servidor tem slot.

### Raia de servidor, banco e gates (slot `NOW` atual)

| Ordem | ID | Por que vem aqui |
| ---: | --- | --- |
| 1 | `BT-SCP-001` | fechar com o classificador de escopo (D-03), as correções de UI da contenção social, de trade e do scanner (D-04) e a prova de mecanismo (D-05) |
| 1a | `BT-WEB-003` | bump feito em 2026-09-22 (D-01): `npm audit` com 0 vulnerabilidades; falta o receipt same-SHA |
| 1b | `BT-UIEV-001` | recaptura em lote (23/23 e `latest.json`) depois das correções da D-04 |
| 2 | `BT-GOV-002` | fila com duas raias (D-02); abre a raia do app |
| 3 | `BT-REL-000` | item 0: pôr a linha de base contida no ar; cada passo em produção com aprovação do dono na hora |
| 4 | `BT-AUTH-003` | buraco do login que denuncia contas (D-19, D-21) |
| 5 | `BT-AUTH-004` | buracos da exportação e da exclusão (D-19, D-20) |
| 6 | `BT-AUTH-007` | trocar a senha trunca o usuário; alcançável hoje |
| 7 | `BT-AUTH-010` | import sem e-mail verificado (assimetria de gate, D-53) |
| 8 | `BT-DB-001` | baseline PostgreSQL fresco; cabeça da corrente mais longa |
| 9 | `BT-DB-004` | só migrations alteram schema (D-48) |
| 10 | `DCK-P0-06` | lixeira e invalidação do `/reports/:id` de deck apagado (D-19, D-30) |
| 11 | `BT-OFFER-001` | prova uma única oferta pública, sem comércio ou paywall |
| 12 | `BT-GATE-001` | SKIP inventariado, nunca silêncio (D-17) |
| 13 | `BT-GATE-002` | receipts fortes por SHA/digest/target (D-17) |
| 14 | `BT-CAP-001` | leitura SSH somente leitura do host, autorizada (D-14) |
| 15 | `BT-DR-001` | backup e restore; bucket e chave `age` com o dono (D-12) |
| 16 | `BT-KPI-001` | telemetria sem decklist (D-47) |
| 17 | `BT-OBS-001` | SLOs e alertas de API, banco, jobs e catálogo (D-47, D-51) |

### Raia do app (abre depois de `BT-UIEV-001` e `BT-GOV-002`)

| Ordem | ID | Por que vem aqui |
| ---: | --- | --- |
| 1 | `BT-UX-KIT-001` | kit de primitivas visuais com as decisões da D-44 (D-06) |
| 2 | `BT-UX-ERR-001` | erro cru na tela (D-53) |
| 3 | `BT-NAV-02` | expulsão do usuário no refresh de capabilities (D-53) |
| 4 | `BT-NAV-03` | onboarding sem saída (D-53) |
| 5 | `LC-P0-01` | contador de vida isolado por conta, primeira coorte (D-07) |

Analyze/Optimize e suas P0 AI ficam para a segunda onda (D-07).

Ao concluir cada ID, a fila é reavaliada contra o registry. Uma dependência que
continue sem `PASS` impede a promoção do próximo ID afetado.

`BT-WEB-003` e `BT-UIEV-001` são dependências declaradas do `NOW` (ver marcador de
contenção acima): fazem parte do fechamento de `BT-SCP-001`, não furam o WIP-1.

Decidido em 2026-09-22 (D-06): banco e kit andam juntos, cada um na sua raia. `BT-DB-001`
e `BT-DB-004` estão na corrente mais longa com folga zero e não tocam no digest de UI;
`BT-UX-KIT-001` abre a raia do app.

Trabalho fora desta árvore, triado em 2026-09-22 (D-52): o classificador do cleanroom entrou
na branch (D-03); `manaloom-bt-ux-fix-001` e `manaloom-ui-home-wave-01` ficam como worktrees
locais com backup em `refs/backup/2026-09-22/`, sem remoto enquanto o `pre-push` não passar
(`docs/status/ESTADO_DO_PROJETO_2026-09-22.md` §7). Nada disso é implementação autorizada por
esta fila.

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

Com a decisão de 2026-09-22 (D-07), a onda 4 (Analyze e Optimize) passa para
depois da primeira coorte: a onda 8 fecha a primeira coorte com o núcleo e o
contador de vida.

## Estado operacional conhecido

- A consolidação planejada em 2026-09-09 landou em 2026-09-18 como
  `f6f791098` (313 arquivos, `--no-verify`). Em 2026-09-21: 22/23 manifests de
  `latest.json` no digest `8bba809c` (430/439 PNGs); falta `play-vs-ai-web-real`
  (corrida de handoff em `manaloom_play_vs_ai_e2e.sh`) e reescrever
  `latest.json`. Gate amplo: `full` termina `EXIT=1` em `npm audit` (`next`
  15.5.21 → 15.5.25; `sharp`) e nunca chega a
  ui-audit/custom-lint/patrol-smoke/dependency-audit. 16 dos 19 commits desde
  2026-09-18 declaram `--no-verify`. Em 2026-09-22 o bump foi feito
  (`BT-WEB-003`) e o `npm audit` do site zerou; o `full` ainda não rodou de novo.
- Os registros de abertura e de agosto abaixo são históricos, não uma nova
  observação de Git, runtime ou produção em setembro.
- Na abertura de `BT-SCP-001`, a branch local estava um commit à frente do
  upstream. Essa é uma observação Git local, não PR, deploy ou release.
- A validação pública read-only observou produção no SHA
  `a6ee09c8f16cf17c2867de4b089e5e65b3527254`:
  `SERVER_BEHIND`; `/capabilities` ainda retornava `404` e readiness anunciava
  migration `057`. Reobservado em 2026-09-22 19:49 UTC: o mesmo SHA, com IA e
  worker de Battle saudáveis (`docs/qa/execution/2026-09-22/prod-readonly-estrutura-e-contagens.md`).
- Em 2026-09-22 o dono decidiu pôr a linha de base contida no ar (`BT-REL-000`)
  depois do `BT-SCP-001`. Isso não é autorização de deploy agora: cada passo em
  produção pede a aprovação dele na hora da execução. Divergência live continua
  sendo observação, não ação.
- `BT-GOV-001` fechou em `PASS` local no commit
  `fd0397a5a97742bcb5127c7b2d08d80aca4bf738`; o gate `full` passou, e a
  evidência UI daquela rodada contém 456 capturas no digest `d517adb65b…`, incluindo
  54 checkpoints no Samsung SM-A135M físico, todos revisados.
- `BT-DOC-001` fechou em `PASS` local no commit
  `c6e2725af0995e01dcf675f20e3a8b608b84d555`, digest de implementação
  `be3bf02dba40…`, após auditoria independente `GO`; implementação e fechamento
  já são ancestrais do upstream observado, sem deploy.
- `BT-DOC-004` fechou em `PASS` local no commit
  `d9f7a59cd87d032df3d076c35ffbdb17e41525a6`, digest de implementação
  `bf7704ee33c9…`, gate `full` e auditoria independente `GO`; implementação
  `d9f7a59cd` já está no upstream; nenhum deploy ocorreu.
- `BT-UX-PROOF-001` fica na onda final porque novas mudanças app-facing
  invalidariam capturas feitas agora.
- A implementação contida de `BT-SCP-001` já produziu um `PASS` focal de Jogar
  contra IA em build Web real, API/PostgreSQL loopback e XMage pinado, registrado
  em `docs/qa/execution/2026-08-25/play-vs-ai-real-xmage-e2e.md`. Isso reduz
  risco técnico, mas não abre um segundo slot `NOW`, não move `BT-PLAY-*` e não
  libera capability/release.
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

Estado em 2026-09-22: passos 5 (hashes) e 6 (arquivar fichas fechadas)
pendentes desde `f6f791098`.
