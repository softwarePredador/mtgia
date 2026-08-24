# Onda 03 — Analyze e Optimize advisory

Objetivo: entregar diagnóstico e sugestões revisáveis sobre a fundação do deck,
sem score absoluto, apply implícito ou learning acidental.

## Semântica e contrato do advisory

| Ordem | ID | A task conterá | Fechamento ponta a ponta específico |
| ---: | --- | --- | --- |
| 1 | `DCK-P1-06` | separação Legalidade × Estrutura × Evidência | API/DTO/UI/copy e testes impedem heurística/Battle de aparecer como regra ou superioridade |
| 2 | `BT-AI-003` | Analyze por revision com artifact persistido | model/prompt/schema/as-of/source/confidence; mutação invalida; OCC não grava sobre revisão nova; mock/provenance chega ao app |
| 3 | `BT-AI-004` | constraint contract único | budget, collection, must-keep, avoid e identidade Commander sobrevivem request→job→cache→preview→HMAC→commit e são rechecados |
| 4 | `BT-AI-007` | linguagem honesta | zero “seguro/curado/equilibrado” sem prova; Hermes some da copy; heurística e evidência ficam rotuladas |
| 5 | `BT-AI-012` | preview não vira aceite | eventos distinguem preview/apply; logs/provider/Sentry pseudonimizados; retention/export/delete verificados |
| 6 | `BT-AI-013` | cache Optimize tenant-safe | SHA-256 e chave user+deck+signature; colisão/cross-tenant/tamper não lê nem sobrescreve |
| 7 | `DCK-P1-07` | applies Optimize convergem no ledger | bulk/replace/seleção parcial usam um service; floors/HMAC/revision; apply/rollback/retry retornam receipt coerente; `can_apply` independe de learning |
| 8 | `DCK-P1-12` | Partner/Background de primeira classe | identidade canônica entra em validation, fingerprint, cache, Analyze, Optimize, import e receipts; legado ambíguo fica em quarentena |
| 9 | `BT-AI-027` | decisão da lane ML legada | schema real ou remoção integral; nenhum catch mascara tabela ausente como inteligência vazia |
| 10 | `BT-AI-028` | grão consistente de sinais | score/bracket/budget/source/freshness vêm da mesma observação/version; fixtures multi-source impedem `MAX` cruzado |

`BT-AI-008` permanece `WAITING_EXTERNAL`: provider não abre publicamente sem
disclosure, minimização e parecer aplicáveis. A alternativa determinística pode
ser trabalhada sem converter esse bloqueio em aceite jurídico.

## Executor, custo e escala

| Ordem | ID | A task conterá | Fechamento ponta a ponta específico |
| ---: | --- | --- | --- |
| 11 | `BT-AI-021` | executor durável comum | payload canônico, claim/lease/fencing/heartbeat/tentativas; crash/restart/segunda réplica retomam uma única execução |
| 12 | `BT-AI-023` | ledger de custo separado de entitlement | reservation→job→outbox→settlement/refund; cache/422/timeout policy; tokens/USD reconciliados |
| 13 | `BT-AI-022` | cancelamento físico e fences | cancel/timeout aborta provider/self-call; depois do terminal não há cache, result, preference ou cobrança residual |
| 14 | `BT-AI-024` | admission control e budgets | filas user/global/lane bounded, `Retry-After`, RAM/pool/socket/cache limits e LRU por bytes/entries |
| 15 | `BT-AI-025` | worker horizontal com identidade de serviço | zero bearer do usuário; job token curto; duas réplicas preservam quota/tenant e não multiplicam limiter |
| 16 | `BT-AI-015` | lookup/reserva/enqueue/settlement idempotente | idempotency key precede reserva; retry não debita; fingerprint divergente 409/zero; reservation_id fica no job |
| 17 | `BT-AI-031` | router efetivo Optimize/Complete | modo/policy/tamanho dão decisão explícita; exatamente um job; parity de quota/gates por modo |
| 18 | `BT-AI-026` | lifecycle consolidado | remove stores/maps duplicados; crash, hard-cap concorrente, cancel e settlement entram no gate obrigatório |

## Prova transversal

- corpus determinístico e provider fake para sucesso, timeout, invalid JSON,
  resposta parcial, cancel e retry;
- PostgreSQL descartável para revision/artifact/jobs/cost ledger;
- nenhum provider em gate determinístico e nenhuma escrita live;
- UI mostra fonte, freshness, limitações, preview e decisão humana;
- apply passa pelo mesmo serviço da Onda 02 e produz receipt atômico;
- Learning permanece OFF e zero read/write é provado.

Saída da onda: Analyze/Optimize podem se tornar candidatos a beta consultiva;
abrir a capability ainda exige receipt, UI final e release same-SHA.
