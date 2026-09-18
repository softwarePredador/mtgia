# Proposta de reordenação da fila por fan-out — 2026-09-18

Status: `PROPOSAL · NOT_MERGED · NO_AUTHORITY`

Este documento **não** reordena nada. `docs/execution/CURRENT_QUEUE.md` é a
fila vigente e continua sendo. Esta é uma proposta de ordem para o horizonte,
derivada do grafo de dependências, para ser aplicada **quando o slot `NOW`
avançar** — não agora.

Nada aqui muda prioridade, estado, dependência ou aceite: isso é do backlog
mestre. A fila só ordena.

Fonte: `docs/generated/TASK_REGISTRY.json` — 220 tasks, 402 arestas,
medido em 2026-09-18.

---

## 1. O problema: a fila não está ordenada por quanto cada ID destrava

Fan-out transitivo = quantos outros IDs deixam de estar bloqueados quando
aquele fecha. É a medida de quanto trabalho um item libera.

| # | ID | Destrava | Prioridade | Estado | Deps abertas |
| --- | --- | ---: | --- | --- | ---: |
| 1 | `BT-DB-001` | **102** | P0 CORE | `TODO` | **0** |
| 2 | `DCK-P0-01` | 77 | P0 CORE | `TODO` | 1 |
| 3 | `BT-SCP-001` | 68 | P0 CORE | `IN_PROGRESS_CONTAINED` | 0 |
| 4 | `DCK-P0-02` | 51 | P0 CORE | `TODO` | 1 |
| 5 | `BT-AUTH-003` | 41 | P0 CORE | `TODO` | **0** |
| 6 | `BT-AUTH-004` | 40 | P0 CORE | `TODO` | 1 |
| 7 | `BT-PRIV-002` | 38 | P0 CORE | `TODO` | — |
| 8 | `BT-ART-01` | 33 | P0 CORE | `TODO` | — |
| 9 | `BT-CAT-01` | 29 | P0 CORE | `TODO` | — |
| 10 | `BT-BAT-003` | 26 | P0 BATTLE | `TODO` | — |

O horizonte atual da fila (`BT-SCP-001`, `BT-OFFER-001`, `BT-GATE-001`,
`BT-GATE-002`, …) é coerente com a tese de "provar o default-deny primeiro",
mas **nenhum dos três maiores liberadores está nele**.

`BT-DB-001` é o caso mais nítido: *"auditar schema real fresh contra baseline
058 antes de desenhar próximo DDL"*. **Zero dependências, é auditoria
read-only, e destrava 102 dos 220 IDs** — quase metade do backlog. Está
parada em `TODO`.

A razão estrutural é simples: quase todo DDL e todo contrato de dado a
jusante precisa saber o schema real antes de ser desenhado. Enquanto essa
auditoria não existe, 102 IDs não podem sequer ser especificados com
segurança.

---

## 2. Ordem proposta para o horizonte

Aplicável **depois** que `BT-SCP-001` fechar com receipt.

| Ordem | ID | Destrava | Por que aqui |
| ---: | --- | ---: | --- |
| 1 | `BT-SCP-001` | 68 | **já é o NOW** — não interromper; fecha default-deny e é pré-requisito dos gates |
| 2 | `BT-CI-001` *(proposto)* | — | acaba com o `--no-verify`; sem gates confiáveis nada a seguir é verificável |
| 3 | `BT-DB-001` | **102** | maior liberador do backlog, sem dependência, read-only |
| 4 | `BT-AUTH-003` | 41 | segundo maior sem dependência; segurança de recuperação de conta |
| 5 | `DCK-P0-01` | 77 | abre assim que `BT-DB-001` fechar |
| 6 | `BT-AUTH-004` | 40 | abre assim que `BT-AUTH-003` fechar |
| 7 | `DCK-P0-02` | 51 | abre assim que `DCK-P0-01` fechar |

Os itens de governança do horizonte atual (`BT-OFFER-001`, `BT-GATE-001`,
`BT-GATE-002`) não somem — descem, porque destravam menos e porque
`BT-SCP-001` já cobre a tese central de default-deny.

---

## 3. Uma correção sobre paralelismo

Circulou nesta sessão a ideia de que auditoria read-only poderia correr em
paralelo ao slot `NOW`, por não mutar produto. **Isso contraria a fila
vigente**, que diz textualmente:

> Nenhum outro ID pode receber implementação enquanto este slot estiver
> aberto. Auditorias paralelas servem apenas ao mesmo ID.

Ou seja: enquanto `BT-SCP-001` está aberto, nem mesmo a auditoria do
`BT-DB-001` pode começar. A regra é mais estrita do que "não mutar" — ela
amarra até investigação ao ID aberto.

Isso é decisão de governança, não defeito. Mas tem consequência: com WIP-1
estrito e um único writer, a vazão é estruturalmente limitada, e a ordem da
fila passa a ser a única alavanca disponível. É exatamente por isso que
ordená-la por fan-out importa.

---

## 4. Vazão observada

| | |
| --- | --- |
| Receipts emitidos | 2026-08-14, 08-24 (×2), 08-25, 09-18 |
| IDs em `PASS` | **3** de 220 |
| IDs vivos (excluídos 33 `DEFERRED_BY_SCOPE`) | 187 |
| Janela | ~5 semanas |

≈ **0,6 fechamento por semana**. Nesse ritmo o backlog vivo não fecha em anos.

Duas leituras, ambas verdadeiras:

1. Os 3 fechados foram tarefas de governança grandes, não itens pequenos.
2. O trabalho de "Jogar contra IA" — ADR, E2E real contra XMage, sanitizador,
   bootstrap de sidecar, 143 arquivos de teste, evidência visual — **não
   fechou ficha nenhuma**. `BT-PLAY-001/002` seguem abertos.

Isso sugere que o gargalo **não é execução, é fechamento**. Está sendo
produzido trabalho que não vira `PASS` com receipt. Se for isso, o ganho maior
não é acelerar a produção — é converter o que já existe.

**Ação sugerida antes de pegar item novo:** revisar `BT-PLAY-001/002` contra
os critérios de aceite e, se já estiverem satisfeitos, fechá-los. Isso
converte trabalho feito em vazão medida sem produzir nada novo.

---

## 5. Cadência proposta

Sprint clássico não encaixa em WIP-1 com um único writer — comprometer-se com
um lote contradiz a regra de uma tarefa por vez. O que encaixa é cadência de
**revisão**, não de lote:

| Ritual | Quando | Produz |
| --- | --- | --- |
| Reordenar por fan-out | início do ciclo | a fila ordenada por quanto cada ID libera |
| Ler o estado dos gates | início do ciclo | quais portões estão verdes; nenhum bypass novo sem registro |
| Fechar com receipt | ao fim de cada ficha | já é a regra vigente |
| Delta das engines | quinzenal | possível agora que a árvore está limpa |

O quarto item só voltou a ser possível em 2026-09-18: a auditoria de drift
pulava com `dirty_worktree` em 6 dos 8 relatórios anteriores. Ver
`docs/MAPA_OPERACIONAL_DO_PROJETO.md` §4.3.

---

## 6. O que travar enquanto isso

| Travar | Motivo |
| --- | --- |
| Matriz de capabilities `all-off` | é o que mantém o resto seguro; abrir antes dos gates funcionarem remove a rede |
| Pins de XMage e Forge | 718 e 753 commits atrás do upstream; mover é projeto próprio, não manutenção |
| Escopo de feature | 220 IDs, 3 fechados; nada novo antes dos gates |
| WIP-1 | mantém |
| Árvore limpa | tem custo operacional comprovado — bloqueia a auditoria de drift |

---

## Procedência

Fan-out calculado por alcance transitivo sobre `depends_on` em
`docs/generated/TASK_REGISTRY.json`, excluindo `PASS` e `DEFERRED_BY_SCOPE`.
Vazão medida por receipts em `docs/qa/execution/`. Nenhum acesso a produção.
