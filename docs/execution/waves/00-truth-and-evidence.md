# Onda 00 — verdade executável e evidência

Objetivo: transformar a base all-OFF já commitada em contratos e receipts
duráveis, sem confundir contenção com conclusão funcional.

| Ordem | ID | A task conterá | Fechamento ponta a ponta específico |
| ---: | --- | --- | --- |
| 1 | `BT-GOV-001` | decisão única de produto, plataforma, oferta e módulos fechados | decisão ↔ policy ↔ Web/app/backend/ops ↔ release identity; auditoria e observação live read-only |
| 2 | `BT-DOC-001` | lifecycle inequívoco de documentos ativos, históricos e Hermes | inventário sem autoridade histórica; links/commands seguros; registry regenerado sem fonte antiga ativa |
| 3 | `BT-DOC-004` | registry, DAG, lifecycle, rotas/consumers, receipts e execução WIP 1 | IDs únicos, dependências resolvidas/aciclicas, queue não autoritativa e digest ligado ao registry |
| 4 | `BT-SCP-001` | manifesto server-authoritative default-deny | policy 29/29 OFF, parsers exatos, middleware antes de PG/provider, app só mostra permitido, mixed digest falha |
| 5 | `BT-OFFER-001` | beta gratuita única, sem Pro/checkout/paywall | Web, app, backend e contratos sem promessa divergente; endpoints comerciais negados |
| 6 | `BT-GATE-001` | semântica estrita de PASS/FAIL/BLOCKED/PARTIAL | corpus omite runtime/PG/device e prova exit codes; `SKIP/PARTIAL` nunca gate-eligible |
| 7 | `BT-GATE-002` | receipt forte por SHA, digests, target, schema e checks | start/end estáveis, artifacts hasheados, evidence durável, tamper/stale/um-check forjado rejeitados |

`BT-GATE-003` e `BT-GATE-005` usam esta fundação, mas só fecham na Onda 07,
depois de as jornadas e receipts que eles compõem estarem estáveis. Antecipar
seu `PASS` produziria rastreabilidade incompleta.

Saída da onda: uma revisão local pode dizer exatamente o que está implementado,
contido, provado ou pendente. Ela ainda não autoriza capability ON nem deploy.
