# Onda 02 — Deck revision, ledger, receipt e undo

Objetivo: construir a base transacional do Deckbuilder antes de ampliar IA. A
ordem é deliberada: revisão/ledger → artifact assinado → recuperação/isolamento
→ mutações compostas → readiness única.

| Ordem | ID | A task conterá | Fechamento ponta a ponta específico |
| ---: | --- | --- | --- |
| 1 | `DCK-P0-01` | revisão otimista, ledger imutável e undo universal | todos os mutators usam expected revision/If-Match; duas escritas concorrentes dão 1 sucesso + 1 typed 409; retry não duplica; commit+ledger são atômicos; undo recusa HEAD novo |
| 2 | `DCK-P0-02` | `DeckReviewArtifact v1` único | preview e commit usam owner, deck, revision, input/constraints hash, HMAC e expiração; tamper, outro usuário, stale e expired falham sem DML |
| 3 | `DCK-P0-06` | soft-delete, lixeira, restore e purge governado | DELETE marca sem apagar cards; todas as leituras omitem; restore preserva revisão/privacidade; purge tem janela, audit e restore de backup |
| 4 | `DCK-P0-07` | epoch de sessão/conta no app | A→logout→B limpa jobs/history/caches; resposta tardia A nunca sobrescreve B; restart e forced logout cobertos |
| 5 | `DCK-P0-03` | import em deck existente em duas fases | parse/resolve/diff/validate sem delete; confirmação usa artifact/revision; erro preserva original; stale 409; undo restaura exatamente |
| 6 | `DCK-P1-04` | readiness estrita única por revisão | backend e app resolvem a mesma legalidade/estrutura; ausência de dado não vira legal; swap 1→1 invalida cache/readiness |

## Follow-up do ciclo, após os seis P0

| Ordem | ID | A task conterá | Fechamento ponta a ponta específico |
| ---: | --- | --- | --- |
| 7 | `DCK-P1-01` | draft privado e publicação posterior | criação vazia invisível; publicar revalida a revisão strict atual |
| 8 | `DCK-P1-02` | assinatura completa de import-new | comandante/partner/background e campos materiais invalidam preview; parcial só vira draft explícito |
| 9 | `DCK-P1-03` | edição/remoção incremental | sem replace-all client-side; revision, conflito amigável e undo preservam trabalho concorrente |
| 10 | `DCK-P1-13` | cache app owner+deck+revision | open/resume reconcilia servidor; resposta antiga e cache de outro owner são descartados |

`DCK-P1-11`, o E2E do ciclo completo, fica PARKED até Analyze/Optimize e
Generate fecharem suas dependências. Ele encerra a Onda 04, quando o fluxo já
existe de ponta a ponta.

## Contrato de dados desta onda

- PostgreSQL e o serviço de regras são a verdade; estado local é cache.
- A migration nasce somente depois do baseline `BT-DB-001` e deve preservar
  payloads existentes.
- O ledger é append-only. Undo cria nova revisão; nunca apaga história.
- O receipt atômico identifica owner, deck, revisão anterior/nova, operação,
  artifact/input hash, idempotency key e resultado.
- Deck usa identidade jogável; printing só entra onde a cópia física importa.

Saída da onda: qualquer IA pode propor, mas nenhuma mudança entra no deck sem o
mesmo artifact, revalidação, revisão, ledger e receipt.
