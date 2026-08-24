# Ficha de execução — `BT-GOV-001`

> Ledger não autoritativo. A linha do backlog/registry define a task.

## Autoridade

- Task ID: `BT-GOV-001`
- Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md`
- Registry schema: `1`
- Registry `generated_from.sha256` de fechamento: `baed1f2b2ccd0cbc9620fa073d13311d5a8354513d2222a324881ca70d003016`
- Project logic source digest de fechamento: `44ab0563e6703bad2d1a8a47128d318d88401c050fb98b07d38a3b2a299ab042`
- Decisão corrente: `docs/status/CURRENT_PRODUCT_DECISION.md`

## Identidade da execução

- Owner: `/root`
- Início UTC: `2026-08-13T20:44:50Z`
- Fim UTC: `2026-08-24T16:26:57Z`
- Branch: `codex/free-beta-release-candidate-2026-07-17`
- Git SHA inicial: `b2d3fc04f823f1c58434349a0cf0b48d74919862`
- Git SHA final da implementação: `fd0397a5a97742bcb5127c7b2d08d80aca4bf738`
- Fonte estável: `true`; implementação commitada localmente e sem push
- Classes: `LOCAL_CODE`, `RELEASE_READ_ONLY`
- Autorização máxima: `live-read-only`

## Resultado desta execução

Fechar uma decisão única e verificável para a beta gratuita controlada: marca
BrewTact, Web/Android, 29 capabilities OFF, cadastro OFF, zero comércio e zero
abertura implícita de IA, Learning, Battle, social ou trade.

### Dentro do escopo

- reconciliar decisão, backlog, policy de capabilities, Web pública, app,
  backend, ops e metadata de release;
- provar ausência de promessa Free/Pro/checkout conflitante;
- provar que `implementation_status`, `release_capability` e
  `live_verified_as_of` continuam independentes;
- registrar a relação exata entre SHA candidato e SHA observado em produção.

### Fora do escopo

- habilitar qualquer capability;
- criar contas, gravar PostgreSQL live, migrar ou fazer deploy;
- declarar produção atualizada quando o servidor estiver em outra SHA;
- encerrar tasks de implementação apenas porque a capability está OFF.

## Capabilities

- Antes: `29/29 OFF` no candidato local.
- Depois pretendido: `29/29 OFF`; esta task fecha verdade/consistência, não
  promove função.
- Falha fechada: chave ausente, extra, inválida ou digest divergente deve ser
  rejeitada antes de PostgreSQL e de qualquer provider.

## Baseline e contratos

- SHA candidato publicado: `b2d3fc04f823f1c58434349a0cf0b48d74919862`.
- Produção observada: `a6ee09c8f16cf17c2867de4b089e5e65b3527254`.
- Relação observada: `SERVER_BEHIND`.
- Policy digest candidato observado na rodada anterior:
  `ace782b3969a9ba5a2691f5ca3d97360927919739cd16c796d7b36e8124d754d`;
  deve ser recalculado do blob da revisão final, nunca hardcoded em gate.
- Contratos: decisão corrente, backlog mestre, contrato E2E/release, contrato
  de capabilities, contrato de Web pública e scripts de release/ops.

## Plano de execução

1. inventariar todas as declarações públicas de produto/oferta/capability;
2. comparar policy commitada, parsers app/backend/ops e middleware fail-closed;
3. executar contratos focados e gates agregados aplicáveis;
4. validar Web pública e ausência de CTA/rota proibida;
5. regenerar project logic e revisar o registry/lifecycle;
6. fazer validação pública read-only pós-push sem deploy;
7. anexar receipts duráveis, auditoria independente e atualizar o estado
   canônico somente se todas as cláusulas fecharem.

## Plano de prova

- Positivo: policy exata 29/29 OFF aceita por app/backend/ops.
- Negativo: chave ausente/extra, valor ON, digest misto, API direta e deep link
  são negados.
- Integração: policy → middleware → `/capabilities` → health/readiness → app e
  Web pública.
- Persistência: negação ocorre antes de PostgreSQL; zero DML.
- Release read-only: branch remota, SHA, request-id, `/health`, `/ready` e
  `/capabilities` classificados sem mutação.
- Rollback: somente revert da revisão documental/policy; nenhum estado live é
  tocado nesta execução.

## Gates previstos

| Gate | Resultado necessário |
| --- | --- |
| project logic write/check | `PASS` sem drift |
| capabilities + release ops contracts | `PASS` |
| Web pública contract | `PASS` |
| app/backend full e schema descartável aplicável | `PASS` |
| secret scan e diff check | `PASS` |
| auditoria independente | `GO` |
| validação pública | observação exata; `SERVER_BEHIND` não vira falso `PASS` |

## Gates executados

| Gate | Resultado |
| --- | --- |
| project logic | `PASS`; digest da implementação `f3628ca3…`, 9 artefatos gerados pela ferramenta |
| determinístico + release | `PASS`; 124 auditorias e 32 contratos |
| backend/app/Web | `PASS`; backend completo, 1.564 testes app e build/smoke Web real |
| PostgreSQL descartável | `PASS`; 79 tabelas, 6 views, 98 FKs e 58 migrations |
| contracts especializados | `PASS`; Web pública, ops/worker, engine 96/96 e capabilities |
| Deck/IA/Learning | `PASS_CODE_ONLY`; nenhum runtime/promotion live |
| UI automatizada | `PASS_AUTOMATED`; 59 testes |
| UI runtime/visual | `PASS`; 26 manifests, 456 capturas no digest `d517adb6…`, incluindo 54 checkpoints no Samsung SM-A135M físico |
| secret scan | `PASS`; gitleaks 8.30.1, zero credencial live literal |

### Checkpoint de continuação — 2026-08-24

- O pacote organizacional WIP-1 fechou separadamente no commit `675f7a2f5`;
  a implementação e a evidência de `BT-GOV-001` fecharam no commit
  `fd0397a5a97742bcb5127c7b2d08d80aca4bf738`. Ambos usaram hooks normais,
  sem `--no-verify`.
- O Gradle lock residual de `url_launcher_android` foi regenerado com
  `:app:dependencies --write-locks`; `:app:checkProfileAarMetadata`, build
  profile e instalação no Samsung passaram.
- A fixture autenticada usou somente PostgreSQL loopback descartável; o
  cleanup confirmou zero banco e zero listeners restantes e removeu as
  credenciais temporárias. Nenhum PostgreSQL live, Hermes ou SQLite foi escrito.
- Os quatro perfis P0, Battle Live e os Packs 02–08 produziram 26 manifests e
  456 capturas no digest UI
  `d517adb65beaa0a759a6ce5304779d21698850bd9212c6e5536b1615d5a11cee`.
  As 42 pranchas auxiliares foram abertas integralmente e depois movidas para a
  Lixeira; o aggregate oficial registra hashes dos manifests revisados.
- `PASS_AUTOMATED`, `PASS_RUNTIME` e `PASS_VISUAL_REVIEWED` passaram; TalkBack
  humano, teclado Web real e hardware smoke continuam gates separados de
  release e não receberam crédito nesta task.
- O gate `full` passou: 124 auditorias determinísticas, 32 contratos de
  release, backend completo, 1.564 testes Flutter com um skip de ambiente,
  Web pública, UI audit, custom lint, Patrol 9/9, dependências e PostgreSQL/tbls
  descartável com 79 tabelas, 6 views, 98 FKs e 58 migrations.
- Nenhum push, deploy, migration live, abertura de capability ou promoção de
  deck/regra foi executado.

Receipt durável:
`docs/qa/execution/2026-08-14/BT-GOV-001.md`.

## Fechamento

- Resultado E2E estrito local: `PASS`
- Gate-eligible: `true` para fechamento local; não autoriza release/deploy
- Release identity: `SERVER_BEHIND` na última observação
- Bloqueios locais da task: nenhum. Produção continua `SERVER_BEHIND` na última
  observação read-only e isso não é convertido em prova same-SHA.
- Auditoria: `GO` de fontes, evidência e separação atômica; follow-ups visuais
  P1/P2 permanecem não bloqueantes no aggregate UI.
- Veredito da execução: `PASS`
- Commit de implementação: `fd0397a5a97742bcb5127c7b2d08d80aca4bf738`
- Próximo ID: `BT-DOC-001`
