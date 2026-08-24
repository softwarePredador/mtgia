# Onda 06 — Battle independente

Status operacional: `PARKED · CAPABILITIES_OFF · NOT_BETA_CORE_DEPENDENCY`

Battle usa programa, capacidade, workers, receipts e release próprios. Ele não
divide o lifecycle de IA advisory nem bloqueia a beta core enquanto batch,
Live e Coach permanecerem comprovadamente OFF.

## Fechamento P0 antes de qualquer abertura

| Ordem | ID | A task conterá | Fechamento ponta a ponta específico |
| ---: | --- | --- | --- |
| 1 | `BT-BAT-000` | ADR da topologia core 8 GB + workers externos | deploy model, trust boundary, capacity e rollback; nenhum engine co-residente como premissa |
| 2 | `BT-BAT-001` | replay/annotation owner-scoped | matriz A/B prova que possuir deck oponente não concede lista/read/annotate |
| 3 | `BT-BAT-002` | delete de conta ownership-safe | A/B preserva attempt/replay do outro owner; remove/anonymiza somente o permitido |
| 4 | `BT-BAT-003` | remoção do bypass síncrono | `/ai/simulate type=battle` nega ou enfileira; quota/body/admission únicos; crash não derruba API |
| 5 | `BT-BAT-004` | capability + reserva/settle/refund | API direta não contorna; retry não cobra 2×; worker/readiness usam a mesma policy OFF e processo supervisionado real |
| 6 | `BT-BAT-005` | API e worker separados | restart/pressão/drain do worker não afetam API; SHA/digest e heartbeat reais em readiness |
| 7 | `BT-BAT-006` | perfil `core_8gb` | reservas/limits medidos; swap/pressure bloqueiam promoção; engine excluída |
| 8 | `BT-BAT-007` | sidecars privados e pins/licença/SBOM | zero rota pública; service auth; XMage-first/Forge-gap; identidade de engine e patch reproduzível |
| 9 | `BT-BAT-008` | observabilidade multi-serviço | queue age, leases, restart, RSS/heap/GC, slots, DB/custo e alerta humano reconhecido |
| 10 | `BT-BAT-009` | envelope de custo/kill switches | tetos por capability bloqueiam novos jobs; custo job/minuto e refunds reconciliados |
| 11 | `BT-BAT-EVD-001` | subject deck exato | carta só do oponente nunca conta como exposição; Dart/Python em paridade |
| 12 | `BT-BAT-EVD-002` | amostra censurada | denominator nasce em attempts e inclui no-replay/timeout/error/gap; sample incompleto bloqueia claim |
| 13 | `BT-BAT-EVD-003` | receipt de comparação externa | job→attempt→replay→comparison→PG liga hashes, pins, subject, controls e decisão |
| 14 | `BT-BAT-EVD-004` | lane/natural sample atestados pelo servidor | request↔echo exatos; cliente não autodeclara natural/same-lane |
| 15 | `BT-BAT-010` | gate de promoção topology-aware | todos os P0, same-SHA first-party, pins, capacity, DR, receiver, budget, UI/smoke e rollback verdes |

## Escala horizontal posterior

| Ordem | ID | A task conterá | Fechamento ponta a ponta específico |
| ---: | --- | --- | --- |
| 16 | `BT-BAT-101` | perfis por workload | heap/CPU/headroom/slots/startup/custo medidos para API, orchestrator, XMage, Forge e Coach |
| 17 | `BT-BAT-102` | worker registry e scheduler | heartbeat TTL/fencing; stale remove slot; sem overbooking/starvation |
| 18 | `BT-BAT-103` | pool XMage 2+ | kill em claim/start/persist não duplica replay nem terminal |
| 19 | `BT-BAT-104` | pool Forge separado | só gap XMage válido; serial por processo; falha operacional é terminal honesto |
| 20 | `BT-BAT-105` | autoscaling bounded | min/max/cooldown/drain; queue age e budget; DB/capacity nunca excedidos |
| 21 | `BT-BAT-106` | API redundante | budgets de conexão por processo; worker saturado não esgota API |
| 22 | `BT-COACH-101` | afinidade runtime→shard+epoch | routing server-side; cliente não carrega afinidade; shard stale termina `process_lost` |
| 23 | `BT-COACH-102` | drain/rollout Coach | coortes 1/2/4/8+, sessão conclui ou falha honestamente, pool distinto |
| 24 | `BT-BAT-107` | capacity/retention | forecast de jobs/replays/evidence, vacuum, backup, export/delete |
| 25 | `BT-BAT-108` | game day | perda de API/worker/node/shard/PG sem duplicação, corrupção ou fallback silencioso |
| 26 | `BT-BAT-109` | promoção progressiva | soak/rollback 1→2→4→8+, utilização ≤75%, Coach em coorte separada |

`BT-BAT-EVD-005` e `BT-BAT-EVD-006` fecham linguagem/provenance antes da
experiência pública. Os P2 (`BT-BAT-201..204`, `BT-COACH-201`) só entram se
profiling/SLO/negócio fornecerem o trigger previsto no backlog; não são trabalho
antecipado.

Saída da onda: cada capability Battle pode ser promovida isoladamente. Nenhuma
promoção ocorre junto com a beta core por conveniência.
