# Onda 07 — experiência core e fechamento da beta Web/Android

Objetivo: fechar catálogo/coleção, UX, runtime e release somente depois dos
contratos de Deck/IA estarem estáveis. Isso evita recapturar uma matriz UI que a
task seguinte invalidaria.

## Catálogo e coleção confiáveis

| Ordem | ID | A task conterá | Fechamento ponta a ponta específico |
| ---: | --- | --- | --- |
| 1 | `BT-CAT-02` | cards/resolve/printings read-only | após `BT-CAT-01` da Onda 04: zero DML/upstream por leitura; `sync=true` rejeitado; app nunca envia |
| 2 | `BT-SCN-00` | Scanner fora do candidato | depois de `BT-CAT-02`: sem CTA/deep link/câmera/capability; API direta não aciona sync |
| 3 | `BT-CAT-03` | cache/freshness/rate/observabilidade | limiter-down fail-closed no caro; alerta se leitura causar DML/upstream |
| 4 | `BT-ART-01` | arte/provenance da beta gratuita | exact printing first, full-card contain, reference label, host/cache/rate, zero proxy/crop/paywall |
| 5 | `BT-COL-01` | progresso no grão correto | oracle versus printing conforme ADR; numerador/denominador coerentes e ≤100% |
| 6 | `BT-COL-02` | wishlist tipada | `this_printing` versus `any_playable_printing`; matching/copy/deck-missing coerentes |
| 7 | `BT-COL-03` | finish válido por printing | combinações impossíveis rejeitadas no backend e fluxo de correção explícito |
| 8 | `BT-OFF-01` | fronteira online/cache/stale | cada queda de rede é honesta, não perde draft e não aplica mutação em cache |
| 9 | `BT-IMP-02` | CSV/file pela fila de revisão | malformed/large/encoding/injection; nenhum arquivo aplica direto |
| 10 | `BT-DOC-COL-01` | status canônico de coleção/Scanner | manifesto gerado distingue implemented, flag OFF e hardware não provado |

Scanner continua fora do candidato; `BT-SCN-01..03` não recebem crédito por
essa onda.

## UX image-led do deck

| Ordem | ID | A task conterá | Fechamento ponta a ponta específico |
| ---: | --- | --- | --- |
| 11 | `BT-UX-IMG-001` | componente de carta compartilhado | 63:88, contain, exact-first, fallback rotulado, nome sem imagem, sem layout shift |
| 12 | `BT-UX-FIX-001` | fixtures reais e patológicas | 100 cartas, DFC, nomes longos, sem imagem, offline, moedas e densidade extrema |
| 13 | `BT-UX-DECK-001` | um readiness e um CTA | um bloqueio principal, sem mensagens concorrentes, ligado à revision strict |
| 14 | `BT-UX-DECK-002` | hero do comandante/deck | mobile/desktop, carta inteira, formato/cores/100 cartas e sem repetição |
| 15 | `BT-UX-DECK-003` | diagnóstico visual | barras/curva/até 3 recomendações, valor e takeaway, lista acessível, sem score enganoso |
| 16 | `BT-UX-DECK-004` | layout responsivo | mobile real, inspector desktop 320–360 px, 320 CSS px e 200% sem overflow |
| 17 | `BT-UX-SWAP-001` | par visual SAI→ENTRA | imagens integrais, impressão/estado, motivo/função/impacto e texto equivalente |
| 18 | `BT-UX-SWAP-002` | review responsivo | uma coluna mobile, duas desktop, lazy image e resumo sticky |
| 19 | `BT-UX-SWAP-003` | progressive disclosure | ação→motivos/cartas→método, no máximo duas expansões |
| 20 | `BT-UX-A11Y-001` | semântica e acesso | contraste, 48 dp, reflow, dados alternativos, TalkBack e teclado reais |
| 21 | `BT-UX-RES-001` | pesquisa comparativa | rodadas/segmentos definidos, decisão GO/ITERATE/STOP e achados versionados |

## Life Counter: incluir ou provar fora do escopo

Se entrar no candidato, executar em ordem `LC-P0-01`, `LC-P0-02`, `LC-P0-03`
e `LC-P0-04`: namespace por usuário, lifecycle de conta, flush fail-closed e
documentação honesta. A prova inclui A→logout→B, restart, token expiry, erro de
flush e runtime Android físico. Caso contrário, a capability e todas as rotas
ficam inacessíveis e o estado canônico permanece `DEFERRED_BY_SCOPE`.

## Fechamento técnico e release

| Ordem | ID | A task conterá | Fechamento ponta a ponta específico |
| ---: | --- | --- | --- |
| 22 | `BT-WEB-001` | landing coerente com escopo real | zero promessa de Pro/social/Battle/Scanner/Generate/Learning quando OFF; metadata e screenshots correntes |
| 23 | `BT-CAP-002` | reservations/limits reais | preflight antes de mutação; rollback restaura image/env/resources/deploy |
| 24 | `BT-REL-001` | promoção full-stack transacional | backend/Web/Flutter/ops convergem; falha pré-receipt é visível e rollback comprovado |
| 25 | `BT-REL-002` | same-SHA/digest por superfície | SHA completo, product/surface/policy; app compara matriz embutida; mixed identity falha fechado |
| 26 | `BT-GATE-003` | Deck/IA/Learning no full/release | cada slice roda uma vez; local é code-only; release exige receipt PG/runtime aplicável |
| 27 | `BT-GATE-005` | rastreabilidade final por jornada | Generate/save, Analyze, Optimize/apply, Rebuild, Learning, privacy, jobs e Battle ligam código→teste→gate |
| 28 | `BT-UX-PROOF-001` | evidência UI final | automated + runtime + todas as 402 Web e 54 Android físico abertas/revisadas no digest final; sem reutilizar stale |
| 29 | `BT-REL-003` | candidato congelado | quick/full/schema/e2e/release/security no commit; gates resolvem todos os P0 aplicáveis |
| 30 | `BT-QA-001` | homologação Web + Samsung físico | TalkBack, teclado, permissões, offline, erros, journeys negativas e capturas finalizadas |
| 31 | `BT-DEC-001` | decisão owner GO/NO-GO | escopo, riscos aceitos, rollout, monitor, rollback e assinaturas explícitas |

## Fronteira live

- Commit e push não fazem deploy.
- A validação pós-push é GET/read-only.
- Produção em SHA anterior é `SERVER_BEHIND`, com os dois SHAs registrados.
- Deploy, migration ou capability ON exigem autorização separada.
- Após deploy autorizado, `/health`, `/ready` e `/capabilities` precisam
  concordar exatamente com SHA, schema e policy do candidato.
- A matriz Android só fecha em aparelho físico atestado; Samsung conectado sem
  captura/revisão não é PASS.

Saída da onda: candidato controlado Web/Android elegível para decisão humana.
Social, trade, monetização, Scanner, Learning geral e Battle permanecem em
programas/releases próprios.
